# main.py
# 이거 엔드포인트 분석/솔루션 두개로 나눈버전!!

from __future__ import annotations

import datetime as dt
import json
import os
import re
import traceback
import random
from typing import Optional, List, Dict, Any, Tuple

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel
from supabase import create_client, Client


from llm_prompts import call_llm, TRIAGE_SYSTEM_PROMPT, ANALYSIS_SYSTEM_PROMPT, FRIENDLY_SYSTEM_PROMPT
from rule_based import rule_scoring
from srj5_constants import (
    CLUSTERS, DSM_BETA, META_WEIGHTS, ONBOARDING_MAPPING,
    W_LLM, W_RULE, SOLUTION_ID_LIBRARY, ANALYSIS_MESSAGE_LIBRARY, SOLUTION_PROPOSAL_SCRIPTS,
    SAFETY_LEMMAS, SAFETY_LEMMA_COMBOS, PCA_PROXY
)

try:
    from kiwipiepy import Kiwi
    _kiwi = Kiwi()
except Exception:
    _kiwi = None

# --- 환경설정 ---
load_dotenv()
OPENAI_KEY = os.getenv("OPENAI_API_KEY")
# BIND_HOST = os.getenv("BIND_HOST", "0.0.0.0")
# PORT = int(os.getenv("PORT", "8000"))
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")


# Supabase 클라이언트를 전역 변수로 선언
supabase: Optional[Client] = None

# --- FastAPI 앱 초기화 및 이벤트 핸들러 ---
app = FastAPI(title="DailyMoji API v2 (Separated Logic)")

# supabase 클라이언트 초기화
@app.on_event("startup")
def startup_event():
    global supabase
    if SUPABASE_URL and SUPABASE_KEY:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("✅ FastAPI server started and Supabase client initialized.")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

# --- 데이터 모델 (분리된 구조에 맞게 수정) ---

# /analyze 엔드포인트의 입력 모델
class AnalyzeRequest(BaseModel):
    user_id: str
    text: str
    icon: Optional[str] = None
    timestamp: Optional[str] = None
    onboarding: Optional[Dict[str, Any]] = None


# /solutions/propose 엔드포인트의 입력 모델
class SolutionRequest(BaseModel):
    user_id: str
    session_id: str
    top_cluster: str

# Flutter의 PresetIds와 동일한 구조
class PresetIds:
    FRIENDLY_REPLY = "FRIENDLY_REPLY"
    SOLUTION_PROPOSAL = "SOLUTION_PROPOSAL"
    SAFETY_CRISIS_MODAL = "SAFETY_CRISIS_MODAL"
    EMOJI_REACTION = "EMOJI_REACTION"

# ======================================================================
# === kiwi를 사용하는 안전 장치 및 Helper 함수들 ===
# ======================================================================

# --- 안전 장치 로직 ---
SAFETY_REGEX = [r"죽고\s*싶", r"살고\s*싶지", r"살기\s*싫", r"자살", r"뛰어\s*내리", r"투신", r"목을\s*매달", r"목숨(?:을)?\s*끊", r"생을\s*마감", r"죽어버리", r"끝내버리"]
SAFETY_FIGURATIVE = [r"죽을\s*만큼", r"죽겠다\s*ㅋ", r"개\s*맛있"]

def _find_regex_matches(text: str, patterns: List[str]) -> List[str]:
    return [m.group(0) for pat in patterns for m in re.finditer(pat, text, flags=re.IGNORECASE)]

def _kiwi_detect_safety_lemmas(text: str) -> List[str]:
    if not _kiwi: return []
    try:
        tokens = _kiwi.tokenize(text)
        all_lemmas_in_text = {t.lemma for t in tokens}
        hits = {token.lemma for token in tokens if token.lemma in SAFETY_LEMMAS}
        for combo in SAFETY_LEMMA_COMBOS:
            if combo.issubset(all_lemmas_in_text):
                hits.update(combo)
        return list(hits)
    except Exception as e:
        print(f"Kiwi safety check error: {e}")
        return []

def is_safety_text(text: str, llm_json: Optional[dict], debug_log: dict) -> Tuple[bool, dict]:
    kiwi_lemma_hits = _kiwi_detect_safety_lemmas(text)
    safety_llm_flag = (llm_json or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}
    
    # 은유적이거나 농담 표현이 없을 때만 안전 장치를 발동
    is_figurative = bool(_find_regex_matches(text, SAFETY_FIGURATIVE))
    triggered = (bool(kiwi_lemma_hits) or safety_llm_flag) and not is_figurative
    
    debug_log["safety"] = {
        "regex_matches": _find_regex_matches(text, SAFETY_REGEX),
        "figurative_matches": _find_regex_matches(text, SAFETY_FIGURATIVE),
        "kiwi_lemma_hits": kiwi_lemma_hits,
        "llm_intent_flag": safety_llm_flag,
        "triggered": triggered
    }
    
    if triggered:
        # 안전 장치가 발동하면, neg_low 점수를 극단적으로 높여 위기 상황임을 명시
        return True, {"neg_low": 0.95, "neg_high": 0.0, "adhd_high": 0.0, "sleep": 0.0, "positive": 0.0}
    
    return False, {}


# --- Helper 함수들 ---
def clip01(x: float) -> float: return max(0.0, min(1.0, float(x)))

# def _is_night(ts: Optional[str]) -> bool:
#     try:
#         if not ts: return False
#         hour = dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).hour
#         return hour >= 22 or hour < 7
#     except Exception: return False

def g_score(final_scores: dict) -> float:
    w = {"neg_high": 1.0, "neg_low": 0.9, "sleep": 0.7, "adhd_high": 0.6, "positive": -0.3}
    g = sum(final_scores.get(k, 0.0) * w.get(k, 0.0) for k in CLUSTERS)
    return round(clip01((g + 1.0) / 2.0), 3)

def calculate_baseline_scores(onboarding_scores: Optional[Dict[str, int]]) -> Dict[str, float]:
    if not onboarding_scores: return {c: 0.0 for c in CLUSTERS}
    baseline = {c: 0.0 for c in CLUSTERS}
    for q_key, score in onboarding_scores.items():
        processed_score = 3 - score if q_key == 'q7' else score
        if q_key in ONBOARDING_MAPPING:
            normalized_score = processed_score / 3.0
            for mapping in ONBOARDING_MAPPING[q_key]:
                baseline[mapping["cluster"]] += normalized_score * mapping["w"]
    for c in CLUSTERS:
        baseline[c] = clip01(baseline.get(c, 0.0))
    return baseline


def meta_adjust(base_scores: dict, payload: AnalyzeRequest) -> dict:
    s = base_scores.copy()

    # 이모지 아이콘 점수 가중치 
    if payload.icon:
        # 이모지 선택 시 70%, 온보딩 30%를 백엔드에서 결합
        # 여기서 base_scores는 이미 LLM과 Rule 기반 점수가 융합된 상태.
        # 기존 점수(LLM+Rule)에 이모지 점수를 '추가'하는 방식이 아닌,
        # '재계산' 또는 '강력한 보정' 개념으로 접근.
        # -> 백엔드에서 icon 파라미터가 들어왔을 때, 해당 클러스터에 가중치 부여.

        # 클러스터 매핑 
        icon_to_cluster = {
            "angry": "neg_high",
            "crying": "neg_low",
            "shocked": "adhd_high",
            "sleeping": "sleep",
            "smile": "positive",
        }
        
        selected_cluster = icon_to_cluster.get(payload.icon.lower())
        if selected_cluster:
            s[selected_cluster] = clip01(s.get(selected_cluster, 0.0) + META_WEIGHTS["icon"])
    return s           
            



# def dsm_calibrate(scores: dict) -> dict:
#     # 현재는 survey 데이터가 없으므로 비활성화
#     return scores

def pick_profile(final_scores: dict, llm: dict | None) -> int: # surveys 파라미터 제거
    if (llm or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}: return 1
    if max(final_scores.get("neg_low", 0), final_scores.get("neg_high", 0)) > 0.85: return 1
    # if (surveys and (surveys.get("phq9", 0) >= 10 or surveys.get("gad7", 0) >= 10)) or max(final_scores.values()) > 0.60: return 2
    if max(final_scores.values()) > 0.60: return 2 # surveys 필드 제거
    if max(final_scores.values()) > 0.30: return 3
    return 0

# def pca_proxy(final_scores: dict) -> dict:
#     pc1 = sum(final_scores.get(k, 0.0) * w for k, w in PCA_PROXY["pc1"].items())
#     pc2 = sum(final_scores.get(k, 0.0) * w for k, w in PCA_PROXY["pc2"].items())
#     return {"pc1": round(max(-1.0, min(1.0, pc1)), 3), "pc2": round(clip01((pc2 + 1.0) / 2.0), 3)}

# def generate_friendly_reply(text: str) -> str:
#     llm_response = call_llm(system_prompt=FRIENDLY_SYSTEM_PROMPT, user_content=text, openai_key=OPENAI_KEY, model="gpt-4o-mini", temperature=0.7, expect_json=False)
#     return str(llm_response).strip()


# 수치를 주기보다는, 심각도 3단계에 따라 메시지 해석해주는게 달라짐(수치형x, 대화형o)
def get_analysis_message(scores: dict) -> str:
    if not scores: return "당신의 마음을 더 들여다보고 있어요."
    top_cluster = max(scores, key=scores.get)
    score_val = scores[top_cluster]
    
    level = "low"
    if score_val > 0.7: level = "high"
    elif score_val > 0.4: level = "mid"
    
    return ANALYSIS_MESSAGE_LIBRARY.get(top_cluster, {}).get(level, "오늘 당신의 마음은 특별한 색을 띠고 있네요.")


# def get_solution_proposal(top_cluster: str) -> Dict[str, Any]:
#     # 1. 멘트 라이브러리에서 랜덤으로 멘트 하나 선택
#     proposal_script = random.choice(SOLUTION_PROPOSAL_SCRIPTS.get(top_cluster, [""]))
#     # 2. 솔루션 ID 라이브러리에서 랜덤으로 ID 하나 선택
#     solution_id = random.choice(SOLUTION_ID_LIBRARY.get(top_cluster, [None]))
    
#     if not solution_id:
#         return {"proposal_text": "지금은 제안해드릴만한 특별한 활동이 없네요. 대신, 편안하게 대화를 이어갈까요?", "solution_id": None, "solution_data": None}

#     solution_data = None
#     if supabase and solution_id:
#         try:
#             # TODO: 나중에 비동기방식으로 호출하기
#             response = supabase.table("solutions").select("*").eq("solution_id", solution_id).maybe_single().execute()
#             solution_data = response.data
#         except Exception as e:
#             print(f"Supabase solution fetch error: {e}")

#     final_text = proposal_script
#     if solution_data and solution_data.get('text'):
#         final_text += solution_data.get('text')
        
#     return {"proposal_text": final_text, "solution_id": solution_id, "solution_data": solution_data}


async def save_analysis_to_supabase(payload: AnalyzeRequest, profile: int, g: float,
                              intervention: dict, debug_log: dict,
                              final_scores: dict) -> Optional[str]:
    if not supabase: 
        return None
    try:
        session_row = {
            "user_id": payload.user_id, "text": payload.text, "profile": profile,
            "g_score": g, "intervention": json.dumps(intervention, ensure_ascii=False),
            "debug_log": json.dumps(debug_log, ensure_ascii=False), "icon": payload.icon,
        }
        response = await run_in_threadpool(supabase.table("sessions").insert(session_row).execute)
        new_session_id = response.data[0]['id']

        if final_scores:
            score_rows = [
                {"session_id": new_session_id, "user_id": payload.user_id,
                 "cluster": c, "score": v}
                for c, v in final_scores.items()
            ]
            if score_rows:
                await run_in_threadpool(supabase.table("cluster_scores").insert(score_rows).execute)

        return new_session_id
    except Exception as e:
        print(f"Supabase 저장 실패: {e}")
        traceback.print_exc()
        return None


# ---------- API Endpoints (분리된 구조) ----------

# ======================================================================
# ===          분석 엔드포인트         ===
# ======================================================================
 
@app.post("/analyze")
async def analyze_emotion(payload: AnalyzeRequest):
    """사용자의 텍스트와 아이콘을 받아 감정을 분석하고 스코어링 결과를 반환합니다."""
    text = (payload.text or "").strip()
    debug_log: Dict[str, Any] = {"input": payload.dict()}
    try:
        # --- UX Flow 1: EMOJI_ONLY -> 공감/질문으로 응답 (0924 슬랙논의 2번 로직)---
        if payload.icon and not text:
            debug_log["mode"] = "EMOJI_REACTION"
            # Supabase에서 해당 이모지 키를 가진 스크립트들을 모두 가져옴
            response = await run_in_threadpool(
                supabase.table("reaction_scripts").select("script").eq("emotion_key", payload.icon.lower()).execute
            )
            
            scripts = [row['script'] for row in response.data]
            
            # 만약 스크립트가 있다면 그 중 하나를 랜덤으로 선택, 없다면 기본 메시지 사용
            reaction_text = random.choice(scripts) if scripts else "지금 기분이 어떠신지 알려주세요."

            intervention = {"preset_id": PresetIds.EMOJI_REACTION, "text": reaction_text}
            session_id = await save_analysis_to_supabase(payload, 0, 0.5, intervention, debug_log, {})
            
            return {"session_id": session_id, "intervention": intervention}



        # --- 텍스트 입력 케이스 ---

        # --- 파이프라인 1: 1차 안전 장치 (LLM 없이) ---
        is_safe, safety_scores = is_safety_text(text, None, debug_log)
        if is_safe:
            print(f"🚨 1차 안전 장치 발동: '{text}'")
            profile, g = 1, g_score(safety_scores)
            top_cluster = "neg_low"
            intervention = {"preset_id": PresetIds.SAFETY_CRISIS_MODAL, "analysis_text": "많이 힘드시군요. 지금 도움이 필요할 수 있어요.", "solution_id": f"{top_cluster}_crisis_01", "cluster": top_cluster}
            session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, safety_scores)
            return {"session_id": session_id, "intervention": intervention}

        # --- 파이프라인 2: Triage (친구 모드 / 분석 모드 분기) ---
        rule_scores, _, _ = rule_scoring(text)
        if max(rule_scores.values() or [0.0]) < 0.3 and len(text) < 15:
            debug_log["mode"] = "FRIENDLY"
            friendly_text = await call_llm(FRIENDLY_SYSTEM_PROMPT, text, OPENAI_KEY, expect_json=False)
            intervention = {"preset_id": PresetIds.FRIENDLY_REPLY, "text": friendly_text}
            # 친근한 대화도 세션을 남길 수 있음 (스코어는 비어있음)
            session_id = await save_analysis_to_supabase(payload, 0, 0.5, intervention, debug_log, {})
            return {"session_id": session_id, "intervention": intervention}

        # --- 파이프라인 3: 분석 모드 ---
        debug_log["mode"] = "ANALYSIS"
        llm_payload = payload.dict()
        llm_payload["baseline_scores"] = calculate_baseline_scores(payload.onboarding or {})
        llm_json = await call_llm(ANALYSIS_SYSTEM_PROMPT, json.dumps(llm_payload, ensure_ascii=False), OPENAI_KEY)
        debug_log["llm"] = llm_json
        
        # --- 파이프라인 3.5: 2차 안전 장치 (LLM 결과 기반) ---
        is_safe_llm, crisis_scores_llm = is_safety_text(text, llm_json, debug_log)
        if is_safe_llm:
            profile, g = 1, g_score(crisis_scores_llm)
            top_cluster = "neg_low"
            intervention = {
                "preset_id": PresetIds.SAFETY_CRISIS_MODAL,
                "analysis_text": "많이 힘드시군요. 지금 도움이 필요할 수 있어요.",
                "solution_id": f"{top_cluster}_crisis_01",
                "cluster": top_cluster
            }
            session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, crisis_scores_llm)
            return {"session_id": session_id, "intervention": intervention}


        # === 안전장치 모두 통과 시 ===
        # --- 파이프라인 4: 전체 스코어링 로직 ---
        # 4-1. Fusion 
        text_if = {c: 0.0 for c in CLUSTERS}
        if llm_json and not llm_json.get("error"):
            I, F = llm_json.get("intensity", {}), llm_json.get("frequency", {})
            for c in CLUSTERS:
                In = clip01((I.get(c, 0.0) or 0.0) / 3.0)
                Fn = clip01((F.get(c, 0.0) or 0.0) / 3.0)
                text_if[c] = clip01(0.6 * In + 0.4 * Fn + 0.1 * rule_scores.get(c, 0.0))
        
        fused_scores = {c: clip01(W_RULE * rule_scores.get(c, 0.0) + W_LLM * text_if.get(c, 0.0)) for c in CLUSTERS}
        
        # 4-2. Meta Adjust
        adjusted_scores = meta_adjust(fused_scores, payload)
        debug_log["scores"] = {"llm_detail": text_if, "rule": rule_scores, "fused": fused_scores, "final": adjusted_scores}
        
        # 4-3. 최종 결과 생성 
        g = g_score(adjusted_scores)
        profile = pick_profile(adjusted_scores, llm_json)
        top_cluster = max(adjusted_scores, key=adjusted_scores.get, default="neg_low")
        
        # LLM으로부터 공감 메시지와 분석 메시지를 각각 가져옴
        empathy_text = (llm_json or {}).get("empathy_response", "마음을 살피는 중이에요...")
        analysis_text = get_analysis_message(adjusted_scores)
    
        
        
        # 4-4. Intervention 객체 생성 및 반환 (API 응답 구조 수정함)
        intervention = {
            "preset_id": PresetIds.SOLUTION_PROPOSAL,
            "empathy_text": empathy_text, # 공감 텍스트 추가
            "analysis_text": analysis_text,
            "top_cluster": top_cluster
        }
        
        session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, adjusted_scores)
        
        return {
            "session_id": session_id,
            "final_scores": adjusted_scores,
            "g_score": g,
            "profile": profile,
            "intervention": intervention 
        }

    except Exception as e:
        tb = traceback.format_exc()
        raise HTTPException(status_code=500, detail={"error": str(e), "trace": tb})


# ======================================================================
# ===          솔루션 엔드포인트         ===
# ======================================================================
   

@app.post("/solutions/propose")
async def propose_solution(payload: SolutionRequest): 
    """분석 결과(top_cluster)를 바탕으로 사용자에게 맞는 솔루션을 제안하는 로직"""
    if not supabase:
        raise HTTPException(status_code=500, detail="Supabase client not initialized")
        
    try:
        # 1. 제안 멘트와 솔루션 ID를 랜덤으로 선택
        proposal_script = random.choice(SOLUTION_PROPOSAL_SCRIPTS.get(payload.top_cluster, [""]))
        solution_id = random.choice(SOLUTION_ID_LIBRARY.get(payload.top_cluster, [None]))
        
        # 2. 솔루션 ID가 없는 경우에 대한 예외 처리 
        if not solution_id:
            return {
                "proposal_text": "지금은 제안해드릴만한 특별한 활동이 없네요. 대신, 편안하게 대화를 이어갈까요?", 
                "solution_id": None,
                "solution_details": None
            }
        
        # 3. Supabase에서 솔루션 상세 정보 조회
        # 동기 함수를 비동기 컨텍스트에서 안전하게 실행
        response = await run_in_threadpool(
            supabase.table("solutions").select("text, url, startAt, endAt").eq("solution_id", solution_id).maybe_single().execute
        )
        solution_data = response.data


        
        # 4. 최종 제안 텍스트 조합 및 로그 저장
        final_text = proposal_script + (solution_data.get('text') if solution_data and solution_data.get('text') else "")
        # 로그 저장 역시 동기 함수이므로 run_in_threadpool 사용
        await run_in_threadpool(
            supabase.table("interventions_log").insert({"session_id": payload.session_id, "type": "propose", "solution_id": solution_id}).execute
        )
        
        return {
            "proposal_text": final_text, 
            "solution_id": solution_id, 
            "solution_details": solution_data
        }
  
    except Exception as e:
        tb = traceback.format_exc()
        print(f"❌ Propose Solution Error: {e}\n{tb}")
        raise HTTPException(status_code=500, detail={"error": str(e), "trace": tb})
