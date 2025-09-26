# main.py
# 이거 엔드포인트 분석/솔루션 두개로 나눈버전!!
# 0926 로직 변경: 케이스 1-텍스트만 입력 / 케이스2-이모지만 입력 / 케이스 3-텍스트+이모지 같이 입력


from __future__ import annotations

import datetime as dt
import json
import os
import re
import traceback
import random
from typing import Optional, List, Dict, Any, Tuple
import uuid

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from supabase import create_client, Client


from llm_prompts import call_llm, TRIAGE_SYSTEM_PROMPT, ANALYSIS_SYSTEM_PROMPT, FRIENDLY_SYSTEM_PROMPT
from rule_based import rule_scoring
from srj5_constants import (
    CLUSTERS, DSM_BETA, ICON_TO_CLUSTER, META_WEIGHTS, ONBOARDING_MAPPING,
    W_LLM, W_RULE, SOLUTION_ID_LIBRARY, ANALYSIS_MESSAGE_LIBRARY, SOLUTION_PROPOSAL_SCRIPTS,
    SAFETY_LEMMAS, SAFETY_LEMMA_COMBOS, PCA_PROXY, SOLUTION_DETAILS_LIBRARY
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

    # RIN ♥ : 이모지 아이콘 점수 가중치 
    if payload.icon:
        # 아이콘 보정 방식을 "가산" → "가중치 융합"으로 변경
        #  - 기존: s[selected] += META_WEIGHTS["icon"]
        #  - 변경: s = (1 - alpha) * s + alpha * prior(icon-onehot)
        
        selected_cluster = ICON_TO_CLUSTER.get(payload.icon.lower())
        # 'default' 이모지는 감정 분석에 영향을 주지 않음
        if selected_cluster == "neutral": # ♥ 추가: 디폴트 이모지인 경우 감정 가중치 미적용
            return s
        
        alpha = META_WEIGHTS.get("icon_alpha", 0.2) 
        for c in s.keys():
            prior = 1.0 if c == selected_cluster else 0.0
            s[c] = clip01((1.0 - alpha) * s[c] + alpha * prior)
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


async def save_analysis_to_supabase(
        payload: AnalyzeRequest, profile: int, g: float,
        intervention: dict, debug_log: dict,
        final_scores: dict) -> Optional[str]:
    if not supabase: 
        print("RIN: 🚨 Supabase client not initialized.")
        return None
    try:
        user_id = payload.user_id
        
        # 세션을 저장하기 전, user_profiles에 해당 유저가 있는지 확인하고 없으면 생성
        profile_response = await run_in_threadpool(
            supabase.table("user_profiles").select("id").eq("id", user_id).execute
        )
        if not profile_response.data:
            print(f"RIN: ⚠️ [Backend] User profile for {user_id} not found. Creating one.")
            await run_in_threadpool(
                supabase.table("user_profiles").insert({"id": user_id, "user_nick_nm": "New User"}).execute
            )



        session_row = {
            "user_id": payload.user_id,
            "text": payload.text,
            "profile": int(profile), # profile은 정수(1,2,3)
            "g_score": float(g), # g_score은 float
            "intervention": json.dumps(intervention, ensure_ascii=False),
            "debug_log": json.dumps(debug_log, ensure_ascii=False),
            "icon": payload.icon,
         }
        print(f"RIN: ✅ Saving session to Supabase for user: {payload.user_id}")

        response = await run_in_threadpool(
                    supabase.table("sessions").insert(session_row).execute
                )        
        
        if not response.data or not response.data[0].get('id'):
            print("RIN: 🚨 ERROR: Failed to insert session, no data returned.")
            return None
        
        # new_session_id = response.data[0]['id']
        # 여기서 오류나서 계속 멈춘듯? .get()를 사용하여 id에 좀더 안전하게 접근하기!
        new_session_id = response.data[0].get('id')


        if not new_session_id:
            print("RIN: 🚨 ERROR: Session ID is null in the returned data.")
            return None
                
        print(f"RIN: ✅ Session saved successfully. session_id: {new_session_id}")


        if final_scores:
            score_rows = [{"session_id": new_session_id, "user_id": user_id, "cluster": c, "score": v} for c, v in final_scores.items()]
            if score_rows:
                await run_in_threadpool(supabase.table("cluster_scores").insert(score_rows).execute)

        return new_session_id
    
    except Exception as e:
        print(f"RIN: 🚨 Supabase 저장 실패: {e}")
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
        # RIN ♥ : save_analysis_to_supabase 호출 위치 변경하느라 주석 처리!
        # DB 저장을 먼저 시도해서 session_id를 확보
        session_id = await save_analysis_to_supabase(payload, 0, 0.5, {}, debug_log, {})
        # DB 저장이 실패하면 임시 ID를 생성
        if not session_id:
            session_id = f"temp_{uuid.uuid4()}"
            print(f"⚠️ WARNING: DB 저장 실패. 임시 세션 ID 발급: {session_id}")
        
        # RIN ♥ : CASE 2 - 'icon'이 있고 'text'가 비어있을 때 (이모지 단독 입력)
        # --- UX Flow 1: EMOJI_ONLY -> 공감/질문으로 응답 (0924 슬랙논의 2번 로직)---
        if payload.icon and not text:
            debug_log["mode"] = "EMOJI_REACTION"

        #  이모지에 따른 top_cluster 매핑 - 솔루션 제안을 위해 이모지 only도 클러스터 저장!
            top_cluster = ICON_TO_CLUSTER.get(payload.icon.lower(), "neg_low")
            # RIN ♥ : 1) 디폴트 이모지는 분석하지 않음 
            #  ui에서 막아놓긴 할건데, 혹시 모르니까 일단 구현 
            if top_cluster == "neutral": 
                intervention = {
                    "preset_id": PresetIds.EMOJI_REACTION, 
                    "text": "오늘은 기분이 어떠신가요?",
                    "top_cluster": "neutral"
                }
                session_id = await save_analysis_to_supabase(
                    payload, profile=0, g=0.5,
                    intervention=intervention,
                    debug_log=debug_log,
                    final_scores={}
                )
                if session_id:
                    intervention['session_id'] = session_id
                return {
                    "session_id": session_id,
                    "final_scores": {},  
                    "g_score": 0.5,
                    "profile": 0,
                    "intervention": intervention
                }

            #  이모지 단독도 "baseline + 아이콘 prior(가중 융합)"으로 스코어링
            #  - 기존: top_cluster=0.3 고정
            #  - 변경: baseline 계산 후 meta_adjust로 동일한 아이콘 보정 로직 적용
            baseline_scores = calculate_baseline_scores(payload.onboarding or {})  # [ADDED]
            final_scores = meta_adjust(baseline_scores, payload)                   # [ADDED]
            g = g_score(final_scores)                                             # [ADDED]
            profile = pick_profile(final_scores, None)   

            # Supabase에서 해당 이모지 키를 가진 스크립트들을 모두 가져옴
            response = await run_in_threadpool(
                supabase.table("reaction_scripts").select("script").eq("emotion_key", payload.icon.lower()).execute
            )
            
            scripts = [row['script'] for row in response.data]
            
            # 만약 스크립트가 있다면 그 중 하나를 랜덤으로 선택, 없다면 기본 메시지 사용
            reaction_text = random.choice(scripts) if scripts else "지금 기분이 어떠신가요?"

            intervention = {
                "preset_id": PresetIds.EMOJI_REACTION, 
                "empathy_text": reaction_text,
                "top_cluster": top_cluster # 솔루션 제안을 위해 클러스터 정보 전달
            }

            # session_id = await save_analysis_to_supabase(payload, 0, 0.5, intervention, debug_log, {})
            
            # g_score/score 저장을 baseline+prior 기반으로 저장
            session_id = await save_analysis_to_supabase(
                payload, profile=profile, g=g,
                intervention=intervention,
                debug_log=debug_log,
                final_scores=final_scores
            )

            # return {"session_id": session_id, "intervention": intervention}
            if session_id:
                intervention['session_id'] = session_id

            return {
                "session_id": session_id,
                "final_scores": final_scores,  
                "g_score": g,
                "profile": profile,
                "intervention": intervention
            }

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
                # 텍스트가 짧고 (15자 미만) 룰 스코어가 낮을 때만 칭긔칭긔 모드 진입
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
        
        # 4-2. Meta Adjust(아이콘 보정 적용됨) 
        # RIN ♥ : payload.icon이 있으면 meta_adjust에서 가중치 융합 적용 (텍스트+이모지 케이스)
        adjusted_scores = meta_adjust(fused_scores, payload)
        debug_log["scores"] = {"llm_detail": text_if, "rule": rule_scores, "fused": fused_scores, "final": adjusted_scores}
        
        # 4-3. 최종 결과 생성 
        g = g_score(adjusted_scores)
        profile = pick_profile(adjusted_scores, llm_json)
        top_cluster = max(adjusted_scores, key=adjusted_scores.get, default="neg_low")
        
        # LLM으로부터 공감 메시지와 분석 메시지를 각각 가져옴
        empathy_text = (llm_json or {}).get("empathy_response", "마음을 살피는 중이에요...")
        analysis_text = get_analysis_message(adjusted_scores, top_cluster)
        
        
        # 4-4. Intervention 객체 생성 및 반환 
        intervention = {
            "preset_id": PresetIds.SOLUTION_PROPOSAL,
            "empathy_text": empathy_text, # 공감 텍스트 추가
            "analysis_text": analysis_text,
            "top_cluster": top_cluster
        }
        
        session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, adjusted_scores)
        
        if session_id:
            intervention['session_id'] = session_id


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
        
        solution_data = None

        
        # 3. 일단 수퍼베이스 안되니까 나중에 올리고, 지금은 하드코딩된거로!(3-2)
        # 3-1. Supabase에서 먼저 조회 시도
        if supabase:
            try:
                print(f"RIN: ✅ Supabase에서 솔루션 조회 시도: {solution_id}")
                response = await run_in_threadpool(
                    supabase.table("solutions").select("text, url, startAt, endAt").eq("solution_id", solution_id).maybe_single().execute
                )
                if response.data:
                    solution_data = response.data
                    print("RIN: ✅ Supabase에서 솔루션 조회 성공.")
            except Exception as e:
                print(f"RIN: ⚠️ Supabase 조회 중 에러 발생 (하드코딩 데이터로 대체): {e}")
                # 에러가 발생해도 solution_data는 None으로 유지되어 아래 fallback 로직이 실행됨

        # 3-2. Supabase 조회가 실패했거나 데이터가 없으면, 하드코딩된 데이터 사용
        if not solution_data:
            print(f"RIN: ⚠️ Supabase 데이터 없음. 하드코딩된 솔루션으로 대체: {solution_id}")
            solution_data = SOLUTION_DETAILS_LIBRARY.get(solution_id)

        
        # 4. 최종 제안 텍스트 조합 및 로그 저장
        final_text = proposal_script + (solution_data.get('text') if solution_data and solution_data.get('text') else "")
        # interventions_log 테이블에 저장 시도, 실패 시 로컬 파일에 기록
        log_entry = {
            "timestamp": dt.datetime.now().isoformat(),
            "session_id": payload.session_id,
            "type": "propose",
            "solution_id": solution_id
        }
        
        try:
            # Supabase 클라이언트가 있고, 임시 ID가 아닐 때만 DB에 저장 시도
            if supabase and not payload.session_id.startswith("temp_"):
                print(f"RIN: ✅ Supabase에 솔루션 제안 로그 저장 시도...")
                await run_in_threadpool(
                    supabase.table("interventions_log").insert(log_entry).execute
                )
                print(f"RIN: ✅ Supabase에 로그 저장 성공.")
            else:
                # Supabase가 없거나 임시 ID인 경우 파일에 기록
                raise Exception("Supabase client not available or temp session ID.")
        except Exception as e:
            # DB 저장에 실패하면 로컬 파일에 기록
            print(f"RIN: ⚠️ Supabase 로그 저장 실패. 로컬 파일에 기록합니다. 이유: {e}")
            with open("interventions_log.txt", "a", encoding="utf-8") as f:
                f.write(json.dumps(log_entry) + "\n")

        
        content = { "proposal_text": final_text, "solution_id": solution_id, "solution_details": solution_data }
        return JSONResponse(content=content)    
  
    except Exception as e:
        tb = traceback.format_exc()
        print(f"❌ Propose Solution Error: {e}\n{tb}")
        raise HTTPException(status_code=500, detail={"error": str(e), "trace": tb})



# ======================================================================
# ===          홈화면 대사 엔드포인트         ===
# ======================================================================
   
@app.get("/dialogue/home")
async def get_home_dialogue(emotion: Optional[str] = None):
    """홈 화면에 표시할 대사를 반환합니다. emotion 파라미터 유무에 따라 다른 대사를 선택합니다."""
    if not supabase:
        raise HTTPException(status_code=500, detail="Supabase client not initialized")
    
    try:
        # 이모지가 선택되었다면 해당 감정 키로, 아니라면 'default' 키로 조회
        emotion_key = emotion.lower() if emotion else "default"
        
        response = await run_in_threadpool(
            supabase.table("reaction_scripts").select("script").eq("emotion_key", emotion_key).execute
        )
        
        scripts = [row['script'] for row in response.data]
        
        if not scripts:
            # 만약 DB에 해당 키의 대사가 없다면 비상용 기본 메시지 반환
            fallback_script = "안녕! 오늘 기분은 어때?"
            return {"dialogue": fallback_script}

        # 조회된 대사 중 하나를 랜덤으로 선택하여 반환
        return {"dialogue": random.choice(scripts)}
        
    except Exception as e:
        tb = traceback.format_exc()
        raise HTTPException(status_code=500, detail={"error": str(e), "trace": tb})
    




    #  -------------------------------------------------------------------
    
# ======================================================================
# ===          하드코딩된거 쓸 때만!!!         ===
# ======================================================================

    # SolutionPage에서 영상을 로드하기 위한 새로운 API 엔드포인트
@app.get("/solutions/{solution_id}")
async def get_solution_details(solution_id: str):
    """solution_id를 받아서 하드코딩된 솔루션 상세 정보를 반환합니다."""
    print(f"RIN: ✅ 솔루션 상세 정보 요청 받음: {solution_id}")
    
    # srj5_constants.py에 있는 라이브러리에서 solution_id로 데이터를 찾습니다.
    solution_data = SOLUTION_DETAILS_LIBRARY.get(solution_id)
    
    # 만약 데이터가 없다면 404 에러를 반환합니다.
    if not solution_data:
        print(f"RIN: ❌ 해당 솔루션을 찾을 수 없음: {solution_id}")
        raise HTTPException(status_code=404, detail="Solution not found")
    
    # 데이터가 있다면 JSON 형태로 반환합니다.
    print(f"RIN: ✅ 솔루션 정보 반환: {solution_data}")
    return solution_data