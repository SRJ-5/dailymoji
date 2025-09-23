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
    CLUSTERS, DSM_BETA, DSM_WEIGHTS, META_WEIGHTS, ONBOARDING_MAPPING,
    SEVERITY_LOW_MAX, SEVERITY_MED_MAX, W_LLM, W_RULE, SOLUTION_ID_LIBRARY,
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
    intensity: Optional[float] = None
    contexts: Optional[List[str]] = None
    timestamp: Optional[str] = None
    surveys: Optional[Dict[str, Any]] = None
    onboarding: Optional[Dict[str, Any]] = None
    action: Optional[Dict[str, Any]] = None

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

def is_safety_text(text: str, llm_json: dict | None, debug_log: dict) -> Tuple[bool, dict]:
    kiwi_lemma_hits = _kiwi_detect_safety_lemmas(text)
    safety_llm_flag = (llm_json or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}
    triggered = (bool(kiwi_lemma_hits) or safety_llm_flag) and not bool(_find_regex_matches(text, SAFETY_FIGURATIVE))
    debug_log["safety"] = {"regex_matches": _find_regex_matches(text, SAFETY_REGEX), "figurative_matches": _find_regex_matches(text, SAFETY_FIGURATIVE), "kiwi_lemma_hits": kiwi_lemma_hits, "llm_intent_flag": safety_llm_flag, "triggered": triggered}
    if triggered:
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
    if not onboarding_scores: return {}
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
    if payload.icon and payload.icon.lower() in CLUSTERS:
        s[payload.icon.lower()] = clip01(s[payload.icon.lower()] + META_WEIGHTS["icon"] * 0.2)
    if payload.intensity is not None:
        inten = clip01(payload.intensity / 10.0)
        for c in ["neg_low", "neg_high", "sleep", "adhd_high"]:
            s[c] = clip01(s[c] + inten * META_WEIGHTS["intensity_self"] * 0.2)
    if any(ctx in ["night", "밤"] for ctx in (payload.contexts or [])) or _is_night(payload.timestamp):
        s["sleep"] = clip01(s["sleep"] + META_WEIGHTS["time"] * 0.2)
    return s

def dsm_calibrate(scores: dict, surveys: dict | None) -> dict:
    s = scores.copy()
    if not surveys: return s
    for c, v in scores.items():
        z = 0.0
        if c == "neg_low" and "phq9" in surveys: z = (surveys["phq9"] - 10) / 10.0
        elif c == "neg_high" and "gad7" in surveys: z = (surveys["gad7"] - 10) / 10.0
        elif c == "sleep" and "psqi" in surveys: z = (surveys["psqi"] - 10) / 10.0
        elif c == "adhd_high" and "asrs" in surveys: z = (surveys["asrs"] - 12) / 8.0
        elif c == "positive" and "rses" in surveys: z = (surveys["rses"] - 20) / 10.0
        if z != 0.0:
            s[c] = clip01(v + DSM_BETA.get(c, 0.1) * z)
    return s

def pick_profile(final_scores: dict, llm: dict | None, surveys: dict | None) -> int:
    if (llm or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}: return 1
    if max(final_scores.get("neg_low", 0), final_scores.get("neg_high", 0)) > 0.85: return 1
    if (surveys and (surveys.get("phq9", 0) >= 10 or surveys.get("gad7", 0) >= 10)) or max(final_scores.values()) > 0.60: return 2
    if max(final_scores.values()) > 0.30: return 3
    return 0

def pca_proxy(final_scores: dict) -> dict:
    pc1 = sum(final_scores.get(k, 0.0) * w for k, w in PCA_PROXY["pc1"].items())
    pc2 = sum(final_scores.get(k, 0.0) * w for k, w in PCA_PROXY["pc2"].items())
    return {"pc1": round(max(-1.0, min(1.0, pc1)), 3), "pc2": round(clip01((pc2 + 1.0) / 2.0), 3)}

async def generate_friendly_reply(text: str) -> str:
    llm_response = await call_llm(system_prompt=FRIENDLY_SYSTEM_PROMPT, user_content=text, openai_key=OPENAI_KEY, model="gpt-4o-mini", temperature=0.7, expect_json=False)
    return str(llm_response).strip()

def save_to_supabase(payload: Checkin, text: str, profile: int, g: float, intervention: dict, debug_log: dict, final_scores: dict):
    if not supabase: return None
    try:
        session_row = {"user_id": payload.user_id, "text": text, "profile": profile, "g_score": g, "intervention": json.dumps(intervention, ensure_ascii=False), "debug_log": json.dumps(debug_log, ensure_ascii=False)}
        response = supabase.table("sessions").insert(session_row).execute()
        new_session_id = response.data[0]['id']
        if final_scores:
            score_rows = [{"session_id": new_session_id, "user_id": payload.user_id, "cluster": c, "score": v, "session_text": text[:100]} for c, v in final_scores.items()]
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
        rule_scores, _, _ = rule_scoring(text)
        max_rule_score = max(rule_scores.values() or [0.0])
        if max_rule_score >= 0.7 or (max_rule_score >= 0.3 and len(text) >= 10):
            chosen_mode = "ANALYSIS"
        elif max_rule_score < 0.3 or len(text) < 10:
            chosen_mode = "FRIENDLY"
        else: # LLM Triage
            triage_result = await call_llm(system_prompt=TRIAGE_SYSTEM_PROMPT, user_content=text, openai_key=OPENAI_KEY, temperature=0.0, expect_json=False)
            chosen_mode = "ANALYSIS" if "ANALYSIS" in str(triage_result) else "FRIENDLY"
        
        if chosen_mode == "FRIENDLY":
            debug_log["mode"] = "FRIENDLY_REPLY"
            friendly_text = await generate_friendly_reply(text)
            final_scores, profile, g = {}, 0, 0.0
            intervention = {"preset_id": "FRIENDLY_REPLY", "text": friendly_text}
            new_session_id = save_to_supabase(payload, text, profile, g, intervention, debug_log, final_scores)
            return {"session_id": new_session_id, "input": payload.dict(), "final_scores": final_scores, "g_score": g, "profile": profile, "intervention": intervention, "debug_log": debug_log}

        # --- 파이프라인 3: 분석 모드 ---
        debug_log["mode"] = "ANALYSIS"
        
        llm_payload = payload.dict()
        llm_payload["baseline_scores"] = calculate_baseline_scores(payload.onboarding or {})
        llm_json = await call_llm(system_prompt=ANALYSIS_SYSTEM_PROMPT, user_content=json.dumps(llm_payload, ensure_ascii=False), openai_key=OPENAI_KEY)
        debug_log["llm"] = llm_json
        
        # --- 파이프라인 3.5: 2차 안전 장치 (LLM 결과 기반) ---
        is_safe_after_llm, crisis_scores = is_safety_text(text, llm_json, debug_log)
        if is_safe_after_llm:
            print("🚨 2차 안전 장치 발동 (LLM 기반)")
            final_scores, profile, g = crisis_scores, 1, g_score(crisis_scores)
            dominant_neg_cluster = "neg_low" if final_scores.get("neg_low", 0) >= final_scores.get("neg_high", 0) else "neg_high"
            harm_intent = (llm_json or {}).get("intent", {}).get("self_harm", "none")
            preset = "SAFETY_CRISIS_SELF_HARM" if harm_intent == 'likely' else "SAFETY_CHECK_IN"
            intervention = {"preset_id": preset, "cluster": dominant_neg_cluster, "solution_id": f"{dominant_neg_cluster}_crisis_01"}
            new_session_id = save_to_supabase(payload, text, profile, g, intervention, debug_log, final_scores)
            return {"session_id": new_session_id, "input": payload.dict(), "final_scores": final_scores, "g_score": g, "profile": profile, "intervention": intervention, "debug_log": debug_log}

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
        final_scores = dsm_calibrate(meta_scores, payload.surveys)
        
        # 4-3. Profile, G-Score, Intervention
        g = g_score(final_scores)
        profile = pick_profile(final_scores, llm_json, payload.surveys)
        debug_log.update({"g_score": g, "profile": profile, "pca": pca_proxy(final_scores)})

        top_cluster = max(final_scores, key=lambda k: final_scores[k], default="neg_low")
        possible_solutions = SOLUTION_ID_LIBRARY.get(top_cluster, [])
        solution_id = random.choice(possible_solutions) if possible_solutions else None
        intervention = {"preset_id": "SOLUTION_PROPOSAL", "top_cluster": top_cluster, "solution_id": solution_id}
        
        # --- 파이프라인 5: 최종 저장 및 반환 ---
        new_session_id = save_to_supabase(payload, text, profile, g, intervention, debug_log, final_scores)
        return {"session_id": new_session_id, "input": payload.dict(), "final_scores": final_scores, "g_score": g, "profile": profile, "intervention": intervention, "debug_log": debug_log}

    except Exception as e:
        tb = traceback.format_exc()
        print(f"❌ Checkin Error: {e}\n{tb}")
        return {"error": str(e), "trace": tb}