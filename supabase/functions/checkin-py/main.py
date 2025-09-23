# main.py
# 0924 변경:
# 1. 실수로 생략되었던 is_safety_text 및 kiwi 활용 로직을 완벽하게 복원.
# 2. Checkin 모델에서 contexts 제거.
# 3. 홈에서 선택한 이모지를 처리하는 로직 추가.
# 4. 수치 점수를 사용자 친화적 문구로 변환하는 기능 추가.
# 5. 솔루션 제안 시, 제안 멘트와 솔루션 상세 정보를 함께 반환하도록 수정.
# 6. Supabase 저장 로직 강화 (리포트를 위한 cluster_scores 저장).

from __future__ import annotations

import datetime as dt
import json
import os
import re
import traceback
import random
from typing import Optional, List, Dict, Any, Tuple

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client

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
BIND_HOST = os.getenv("BIND_HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8000"))
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY) if SUPABASE_URL and SUPABASE_KEY else None

# --- FastAPI 앱 초기화 ---
app = FastAPI(title="DailyMoji API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

# --- 데이터 모델 ---
class Checkin(BaseModel):
    user_id: str
    text: str
    icon: Optional[str] = None
    timestamp: Optional[str] = None
    onboarding: Optional[Dict[str, Any]] = None
    action: Optional[Dict[str, Any]] = None

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

def _is_night(ts: Optional[str]) -> bool:
    try:
        if not ts: return False
        hour = dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).hour
        return hour >= 22 or hour < 7
    except Exception: return False

def g_score(final_scores: dict) -> float:
    w = {"neg_high": 1.0, "neg_low": 0.9, "sleep": 0.7, "adhd_high": 0.6, "positive": -0.3}
    g = sum(final_scores.get(k, 0.0) * w.get(k, 0.0) for k in CLUSTERS)
    return round(clip01((g + 1.0) / 2.0), 3)

def calculate_baseline_scores(onboarding_scores: Dict[str, int]) -> Dict[str, float]:
    if not onboarding_scores: return {c: 0.0 for c in CLUSTERS} # 온보딩 스코어가 없으면 모두 0으로 초기화
    baseline = {c: 0.0 for c in CLUSTERS}
    for q_key, score in onboarding_scores.items():
        processed_score = 3 - score if q_key == 'q7' else score
        if q_key in ONBOARDING_MAPPING:
            normalized_score = processed_score / 3.0
            for mapping in ONBOARDING_MAPPING[q_key]:
                baseline[mapping["cluster"]] += normalized_score * mapping["w"]
    for c in CLUSTERS:
        baseline[c] = clip01(baseline[c]) if c == 'positive' else max(-1.0, min(1.0, baseline[c]))
    return baseline


def meta_adjust(base_scores: dict, payload: Checkin) -> dict:
    s = base_scores.copy()

    # 이모지 아이콘 점수 가중치 
    if payload.icon and payload.icon.lower() in CLUSTERS:
        # 이모지 선택 시 70%, 온보딩 30%를 백엔드에서 결합
        # 여기서 base_scores는 이미 LLM과 Rule 기반 점수가 융합된 상태.
        # 기존 점수(LLM+Rule)에 이모지 점수를 '추가'하는 방식이 아닌,
        # '재계산' 또는 '강력한 보정' 개념으로 접근.
        # -> 백엔드에서 icon 파라미터가 들어왔을 때, 해당 클러스터에 가중치 부여.

        # 클러스터 매핑 (이모지 파일명과 백엔드 클러스터 매핑)
        icon_to_cluster = {
            "angry": "neg_high",
            "crying": "neg_low",
            "shocked": "adhd_high",
            "sleeping": "sleep",
            "smile": "positive",
        }
        
        selected_cluster = icon_to_cluster.get(payload.icon.lower())
        if selected_cluster:
            # 선택된 이모지 클러스터에 70% 가중치 (기존 점수와 합산)
            s[selected_cluster] = clip01(s[selected_cluster] + 0.7) 
            # 다른 클러스터는 상대적으로 낮춤 (혹은 변화 없음)
            
    # if any(ctx in ["night", "밤"] for ctx in (payload.contexts or [])) or _is_night(payload.timestamp):
    if _is_night(payload.timestamp): # contexts 필드 제거
        s["sleep"] = clip01(s["sleep"] + META_WEIGHTS["time"] * 0.2)
    return s



def dsm_calibrate(scores: dict) -> dict:
    # 현재는 survey 데이터가 없으므로 비활성화
    return scores

def pick_profile(final_scores: dict, llm: dict | None) -> int: # surveys 파라미터 제거
    if (llm or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}: return 1
    if max(final_scores.get("neg_low", 0), final_scores.get("neg_high", 0)) > 0.85: return 1
    # if (surveys and (surveys.get("phq9", 0) >= 10 or surveys.get("gad7", 0) >= 10)) or max(final_scores.values()) > 0.60: return 2
    if max(final_scores.values()) > 0.60: return 2 # surveys 필드 제거
    if max(final_scores.values()) > 0.30: return 3
    return 0

def pca_proxy(final_scores: dict) -> dict:
    pc1 = sum(final_scores.get(k, 0.0) * w for k, w in PCA_PROXY["pc1"].items())
    pc2 = sum(final_scores.get(k, 0.0) * w for k, w in PCA_PROXY["pc2"].items())
    return {"pc1": round(max(-1.0, min(1.0, pc1)), 3), "pc2": round(clip01((pc2 + 1.0) / 2.0), 3)}

async def generate_friendly_reply(text: str) -> str:
    llm_response = await call_llm(system_prompt=FRIENDLY_SYSTEM_PROMPT, user_content=text, openai_key=OPENAI_KEY, model="gpt-4o-mini", temperature=0.7, expect_json=False)
    return str(llm_response).strip()


# 수치를 주기보다는, 심각도 3단계에 따라 메시지 해석해주는게 달라짐
def get_analysis_message(scores: dict) -> str:
    if not scores: return "당신의 마음을 더 들여다보고 있어요."
    top_cluster = max(scores, key=scores.get)
    score_val = scores[top_cluster]
    
    level = "low"
    if score_val > 0.7: level = "high"
    elif score_val > 0.4: level = "mid"
    
    return ANALYSIS_MESSAGE_LIBRARY.get(top_cluster, {}).get(level, "오늘 당신의 마음은 특별한 색을 띠고 있네요.")


async def get_solution_proposal(top_cluster: str) -> Dict[str, Any]:
    proposal_script = random.choice(SOLUTION_PROPOSAL_SCRIPTS.get(top_cluster, [""]))
    solution_id = random.choice(SOLUTION_ID_LIBRARY.get(top_cluster, [None]))
    
    if not solution_id:
        return {"proposal_text": "지금은 제안해드릴만한 특별한 활동이 없네요. 대신, 편안하게 대화를 이어갈까요?", "solution_id": None, "solution_data": None}

    solution_data = None
    if supabase and solution_id:
        try:
            # Supabase는 비동기 호출을 지원하지 않는다네..
            response = supabase.table("solutions").select("*").eq("solution_id", solution_id).maybe_single().execute()
            solution_data = response.data
        except Exception as e:
            print(f"Supabase solution fetch error: {e}")

    final_text = proposal_script
    if solution_data and solution_data.get('text'):
        final_text += solution_data.get('text')
        
    return {"proposal_text": final_text, "solution_id": solution_id, "solution_data": solution_data}



async def save_to_supabase(payload: Checkin, profile: int, g: float, intervention: dict, debug_log: dict, final_scores: dict) -> Optional[str]:
    if not supabase: return None
    try:
        session_row = { "user_id": payload.user_id, "text": payload.text, "profile": profile, "g_score": g, "intervention": json.dumps(intervention, ensure_ascii=False), "debug_log": json.dumps(debug_log, ensure_ascii=False), "icon": payload.icon }
        response = supabase.table("sessions").insert(session_row).execute()
        new_session_id = response.data[0]['id']

        if final_scores:
            score_rows = [{"session_id": new_session_id, "user_id": payload.user_id, "cluster": c, "score": v} for c, v in final_scores.items()]
            if score_rows:
                supabase.table("cluster_scores").insert(score_rows).execute()
        
        return new_session_id
    except Exception as e:
        print(f"Supabase 저장 실패: {e}")
        traceback.print_exc()
        return None

# ---------- API Endpoint ----------
@app.post("/checkin")
async def checkin(payload: Checkin):
    text = (payload.text or "").strip()
    debug_log: Dict[str, Any] = {"input": payload.dict()}
    try:
        # --- 파이프라인 0: 사전 처리 (솔루션 수락 등) ---
        if payload.action and payload.action.get("type") == "accept_solution":
            return {"intervention": {"preset_id": "SOLUTION_PROVIDED", "solution_id": payload.action.get("solution_id")}}

        # --- 특별 케이스: 홈에서 이모지만 선택하고 들어온 경우 ---
        if payload.icon and not payload.text:
            debug_log["mode"] = "EMOJI_ONLY_ANALYSIS"
            baseline_scores = calculate_baseline_scores(payload.onboarding)
            
            final_scores = {c: baseline_scores.get(c, 0.0) * 0.3 for c in CLUSTERS}
            emoji_cluster_map = {
                "angry": "neg_high", "crying": "neg_low", "shocked": "adhd_high",
                "sleeping": "sleep", "smile": "positive"
            }
            emoji_cluster = emoji_cluster_map.get(payload.icon)
            if emoji_cluster:
                final_scores[emoji_cluster] = final_scores.get(emoji_cluster, 0.0) + 0.7
            
            final_scores = {c: clip01(v) for c, v in final_scores.items()}
            
            g = g_score(final_scores)
            profile = pick_profile(final_scores, None)
            analysis_text = get_analysis_message(final_scores)
            top_cluster = max(final_scores, key=final_scores.get, default="neg_low")
            solution_info = await get_solution_proposal(top_cluster)
            
            intervention = { "preset_id": "SOLUTION_PROPOSAL", "analysis_text": analysis_text, **solution_info }
            
            session_id = await save_to_supabase(payload, profile, g, intervention, debug_log, final_scores)
            return {"session_id": session_id, "final_scores": final_scores, "g_score": g, "profile": profile, "intervention": intervention, "debug_log": debug_log}



# ======================================================================
# ===          일반 채팅 플로우         ===
# ======================================================================
        text = (payload.text or "").strip()

        # --- 파이프라인 1: 1차 안전 장치 (LLM 없이) ---
        is_safe, final_scores = is_safety_text(text, None, debug_log)
        if is_safe:
            print(f"🚨 1차 안전 장치 발동: '{text}'")
            profile, g = 1, g_score(final_scores)
            dominant_neg_cluster = "neg_low" if final_scores.get("neg_low", 0) >= final_scores.get("neg_high", 0) else "neg_high"
            intervention = {"preset_id": "SAFETY_CRISIS_MODAL", "cluster": dominant_neg_cluster, "solution_id": f"{dominant_neg_cluster}_crisis_01"}
            new_session_id = save_to_supabase(payload, text, profile, g, intervention, debug_log, final_scores)
            return {"session_id": new_session_id, "input": payload.dict(), "final_scores": final_scores, "g_score": g, "profile": profile, "intervention": intervention, "debug_log": debug_log}

        # --- 파이프라인 2: Triage (친구 모드 / 분석 모드 분기) ---
        # 홈에서 이모지 눌렀을 때 70% 점수, 온보딩 30% 점수 결합하여 스코어링.
        # -> 이것은 백엔드 analyzeEmotion 로직에서 처리되어야 함.
        # -> 일단 Triage 단계에서는 텍스트 기반으로 모드를 결정.
        rule_scores, _, _ = rule_scoring(text)
        max_rule_score = max(rule_scores.values() or [0.0])
        chosen_mode = "FRIENDLY"
        if max_rule_score >= 0.3 or len(text) >= 10:
            chosen_mode = "ANALYSIS"
        
        if chosen_mode == "FRIENDLY":
            debug_log["mode"] = "FRIENDLY_REPLY"
            friendly_text = await generate_friendly_reply(text)
            intervention = {"preset_id": "FRIENDLY_REPLY", "text": friendly_text}
            session_id = await save_to_supabase(payload, 0, 0.0, intervention, debug_log, {})
            return {"session_id": session_id, "intervention": intervention}

        # --- 파이프라인 3: 분석 모드 ---
        debug_log["mode"] = "ANALYSIS"
        llm_payload = payload.dict()
        llm_payload["baseline_scores"] = calculate_baseline_scores(payload.onboarding or {})
        llm_json = await call_llm(system_prompt=ANALYSIS_SYSTEM_PROMPT, user_content=json.dumps(llm_payload, ensure_ascii=False), openai_key=OPENAI_KEY)
        debug_log["llm"] = llm_json
        
        # --- 파이프라인 3.5: 2차 안전 장치 (LLM 결과 기반) ---
        is_safe_llm, crisis_scores_llm = is_safety_text(text, llm_json, debug_log)
        if is_safe_llm:
            print("🚨 2차 안전 장치 발동 (LLM 기반)")
            profile, g = 1, g_score(crisis_scores_llm)
            harm_intent = (llm_json or {}).get("intent", {}).get("self_harm", "none")
            preset = "SAFETY_CRISIS_SELF_HARM" if harm_intent == 'likely' else "SAFETY_CHECK_IN"
            intervention = {"preset_id": preset, "cluster": "neg_low", "solution_id": "neg_low_crisis_01"}
            session_id = await save_to_supabase(payload, profile, g, intervention, debug_log, crisis_scores_llm)
            return {"session_id": session_id, "final_scores": crisis_scores_llm, "g_score": g, "profile": profile, "intervention": intervention, "debug_log": debug_log}
         
        # --- 파이프라인 4: 전체 스코어링 로직 (모든 안전장치 통과 시) ---
        # 4-1. Fusion
        text_if = {c: 0.0 for c in CLUSTERS}
        if llm_json and not llm_json.get("error"):
            I, F = llm_json.get("intensity", {}), llm_json.get("frequency", {})
            for c in CLUSTERS:
                In = clip01((I.get(c, 0.0) or 0.0) / 3.0)
                Fn = clip01((F.get(c, 0.0) or 0.0) / 3.0)
                text_if[c] = clip01(0.6 * In + 0.4 * Fn + 0.1 * rule_scores.get(c, 0.0))
        
        fused_scores = {c: clip01(W_RULE * rule_scores.get(c, 0.0) + W_LLM * text_if.get(c, 0.0)) for c in CLUSTERS}
        debug_log["fused"] = fused_scores
        
        # 4-2. Meta & DSM Calibrate
        meta_scores = meta_adjust(fused_scores, payload)
        final_scores = dsm_calibrate(meta_scores)
        
        # 4-3. Profile, G-Score, Intervention
        g = g_score(final_scores)
        profile = pick_profile(final_scores, llm_json)
        analysis_text = get_analysis_message(final_scores)
        debug_log.update({"g_score": g, "profile": profile, "pca": pca_proxy(final_scores)})

        top_cluster = max(final_scores, key=final_scores.get, default="neg_low")
        solution_info = await get_solution_proposal(top_cluster)
        
        intervention = { "preset_id": "SOLUTION_PROPOSAL", "analysis_text": analysis_text, **solution_info }

        # --- 파이프라인 5: 최종 저장 및 반환 ---
        session_id = await save_to_supabase(payload, profile, g, intervention, debug_log, final_scores)
        return {"session_id": session_id, "final_scores": final_scores, "g_score": g, "profile": profile, "intervention": intervention, "debug_log": debug_log}

    except Exception as e:
        tb = traceback.format_exc()
        print(f"❌ Checkin Error: {e}\n{tb}")
        return {"error": str(e), "trace": tb}