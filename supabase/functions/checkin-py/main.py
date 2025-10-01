# main.py
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


from llm_prompts import call_llm, get_system_prompt, TRIAGE_SYSTEM_PROMPT, FRIENDLY_SYSTEM_PROMPT 
from rule_based import rule_scoring
from srj5_constants import (
    CLUSTERS, EMOJI_ONLY_SCORE_CAP, ICON_TO_CLUSTER, ONBOARDING_MAPPING,
    FINAL_FUSION_WEIGHTS, FINAL_FUSION_WEIGHTS_NO_TEXT,
    W_LLM, W_RULE, 
    SAFETY_LEMMAS, SAFETY_LEMMA_COMBOS, SAFETY_REGEX, SAFETY_FIGURATIVE
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
    language_code: Optional[str] = 'ko'
    timestamp: Optional[str] = None
    onboarding: Optional[Dict[str, Any]] = None
    character_personality: Optional[str] = None


# /solutions/propose 엔드포인트의 입력 모델
class SolutionRequest(BaseModel):
    user_id: str
    session_id: str
    top_cluster: str
    language_code: Optional[str] = 'ko'


# Flutter의 PresetIds와 동일한 구조
class PresetIds:
    FRIENDLY_REPLY = "FRIENDLY_REPLY"
    SOLUTION_PROPOSAL = "SOLUTION_PROPOSAL"
    SAFETY_CRISIS_MODAL = "SAFETY_CRISIS_MODAL"
    EMOJI_REACTION = "EMOJI_REACTION"

# ======================================================================
# === kiwi를 사용하는 안전 장치 ===
# ======================================================================

# --- 안전 장치 로직 ---

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
        return True, {"neg_low": 0.95, "neg_high": 0.0, "adhd": 0.0, "sleep": 0.0, "positive": 0.0}
    
    return False, {}


# ======================================================================
# === 헬퍼함수들 ===
# ======================================================================
# DEBUG LOG: 보기 편한 로그 출력을 위한 헬퍼 함수 추가
def _format_scores_for_print(scores: dict) -> str:
    """점수 딕셔너리를 소수점 2자리까지 예쁘게 출력하기 위한 함수"""
    if not isinstance(scores, dict):
        return str(scores)
    return json.dumps({k: round(v, 2) if isinstance(v, float) else v for k, v in scores.items()}, indent=2)

def clip01(x: float) -> float: return max(0.0, min(1.0, float(x)))

def g_score(final_scores: dict) -> float:
    w = {"neg_high": 1.0, "neg_low": 0.9, "sleep": 0.7, "adhd": 0.6, "positive": -0.3}
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


def pick_profile(final_scores: dict, llm: dict | None) -> int: # surveys 파라미터 제거
    if (llm or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}: return 1
    if max(final_scores.get("neg_low", 0), final_scores.get("neg_high", 0)) > 0.85: return 1
    # if (surveys and (surveys.get("phq9", 0) >= 10 or surveys.get("gad7", 0) >= 10)) or max(final_scores.values()) > 0.60: return 2
    if max(final_scores.values()) > 0.60: return 2 # surveys 필드 제거
    if max(final_scores.values()) > 0.30: return 3
    return 0


# 👀 모든 멘트 조회를 통합 관리하는 새로운 헬퍼 함수
async def get_mention_from_db(
    mention_type: str,
    personality: Optional[str],
    language_code: str,
    cluster: str,
    level: Optional[str] = None,
    default_message: str = "...",
    format_kwargs: Optional[Dict] = None
) -> str:
    if not supabase: return default_message
    try:
        query = supabase.table("character_mentions").select("text")
        query = query.eq("mention_type", mention_type)
        query = query.eq("language_code", language_code)
        
        if personality: query = query.eq("personality", personality)
        if cluster: query = query.eq("cluster", cluster)
        if level: query = query.eq("level", level)
        
        response = await run_in_threadpool(query.execute)
        scripts = [row['text'] for row in response.data]
        
        if not scripts: return default_message
        
        selected_script = random.choice(scripts)

        if format_kwargs:
            for key, value in format_kwargs.items():
                selected_script = selected_script.replace(f"{{{key}}}", str(value))
        
        return selected_script
    except Exception as e:
        print(f"❌ get_mention_from_db Error: {e}")
        return default_message


# 수치를 주기보다는, 심각도 3단계에 따라 메시지 해석해주는게 달라짐(수치형x, 대화형o)
async def get_analysis_message(
    scores: dict, 
    personality: Optional[str], 
    language_code: str
) -> str:
    if not scores: return "당신의 마음을 더 들여다보고 있어요."
    top_cluster = max(scores, key=scores.get)
    score_val = scores[top_cluster]
    
    level = "low"
    if score_val > 0.7: level = "high"
    elif score_val > 0.4: level = "mid"
    
    return await get_mention_from_db(
        mention_type="analysis",
        personality=personality,
        language_code=language_code,
        cluster=top_cluster,
        level=level,
        default_message="오늘 당신의 마음은 특별한 색을 띠고 있네요.",
        format_kwargs={"emotion": top_cluster, "score": int(score_val * 100)}
    )
    


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

    # 🤩 RIN: 사용자 닉네임과 캐릭터 이름을 미리 조회해둡니다.
    user_nick_nm = "사용자"
    character_nm = "모지"
    try:
        if supabase:
            user_profile_res = await run_in_threadpool(
                supabase.table("user_profiles")
                .select("user_nick_nm, character_nm")
                .eq("id", payload.user_id)
                .single()
                .execute
            )
            if user_profile_res.data:
                user_nick_nm = user_profile_res.data.get("user_nick_nm", user_nick_nm)
                character_nm = user_profile_res.data.get("character_nm", character_nm)
    except Exception:
        pass # 조회 실패 시 기본값 사용

    try:
        # RIN 🌸 CASE 2 - 이모지만 입력된 경우
        if payload.icon and not text:
            debug_log["mode"] = "EMOJI_REACTION"
            top_cluster = ICON_TO_CLUSTER.get(payload.icon.lower(), "neg_low")

            if top_cluster == "neutral": 
            # RIN ♥ : 디폴트 이모지는 분석하지 않음 
            #  ui에서 막아놓긴 할건데, 혹시 모르니까 일단 구현 
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
            pass
            print("\n--- 🧐 EMOJI-ONLY ANALYSIS DEBUG 🧐 ---")


            # 1. 온보딩 점수 계산
            onboarding_scores = calculate_baseline_scores(payload.onboarding or {})  
            print(f"Onboarding Scores: {_format_scores_for_print(onboarding_scores)}")

            # 2. 이모지 점수 생성
            icon_prior = {c: 0.0 for c in CLUSTERS}
            selected_cluster = ICON_TO_CLUSTER.get(payload.icon.lower())
            if selected_cluster in icon_prior:
                icon_prior[selected_cluster] = 1.0

            # 3. 온보딩 0.2 + 이모지 0.8 가중치를 사용하여 1차 융합
            w = FINAL_FUSION_WEIGHTS_NO_TEXT
            final_scores = {c: clip01(
                onboarding_scores.get(c, 0.0) * w['onboarding'] +
                icon_prior.get(c, 0.0) * w['icon']
            ) for c in CLUSTERS}
            print(f"Final Scores (after fusion): {_format_scores_for_print(final_scores)}")

            # 4. 점수 상한선(Cap) 적용 로직 
            # 온보딩+이모지 점수는 최대 0.5가 되도록 
            capped_scores = final_scores.copy()
            if selected_cluster in capped_scores:
                # original_score 변수를 capped_scores에서 가져오도록 수정하여 NameError 해결
                original_score = capped_scores[selected_cluster]
                capped_scores[selected_cluster] = min(original_score, EMOJI_ONLY_SCORE_CAP)
            
                print(f"Score Capping Applied for '{selected_cluster}': {original_score:.4f} -> {capped_scores[selected_cluster]:.4f}")

            # 5. 최종 점수(g_score)
            g = g_score(capped_scores)   
            profile = pick_profile(capped_scores, None)


            print(f"Final Scores (after capping): {_format_scores_for_print(capped_scores)}")
            print(f"G-Score: {g:.2f}")
            print(f"Profile: {profile}")
            print("------❤️-------------❤️-----------❤️-------\n")   

            # --- EMOJI_ONLY - DB 저장 및 반환 로직---
            # Supabase에서 해당 이모지 키를 가진 스크립트들을 모두 가져옴
            reaction_text = "기분을 알려주셔서 감사해요!"
            # reaction_scripts 대신 character_mentions 조회
            reaction_text = await get_mention_from_db(
                mention_type="reaction",
                personality=payload.character_personality,
                language_code=payload.language_code,
                cluster=ICON_TO_CLUSTER.get(payload.icon.lower(), "common"),
                default_message="어떤 일 때문에 그렇게 느끼셨나요?",
                format_kwargs={"user_nick_nm": user_nick_nm}
            )

            intervention = {
                "preset_id": PresetIds.EMOJI_REACTION, 
                "empathy_text": reaction_text,
                "top_cluster": top_cluster
            }

            # g_score/score 저장을 baseline+prior 기반으로 저장
            session_id = await save_analysis_to_supabase(
                payload, profile=profile, g=g,
                intervention=intervention,
                debug_log=debug_log,
                final_scores=capped_scores
            )

            if session_id:
                intervention['session_id'] = session_id

            return {
                "session_id": session_id,
                "final_scores": capped_scores,  
                "g_score": g,
                "profile": profile,
                "intervention": intervention
            }
        pass


        # --- 텍스트가 포함된 모든 경우 ---


    # <<<<<<<     안전장치    >>>>>>>>
        # --- 파이프라인 1: 1차 안전 장치 (LLM 없이) ---
        is_safe, safety_scores = is_safety_text(text, None, debug_log)
        if is_safe:
            print(f"🚨 1차 안전 장치 발동: '{text}'")
            profile, g = 1, g_score(safety_scores)
            top_cluster = "neg_low"
            intervention = {"preset_id": PresetIds.SAFETY_CRISIS_MODAL, "analysis_text": "많이 힘드시군요. 지금 도움이 필요할 수 있어요.", "solution_id": f"{top_cluster}_crisis_01", "cluster": top_cluster}
            session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, safety_scores)
            return {"session_id": session_id, "intervention": intervention}
        pass

        # --- 파이프라인 2: Triage (친구 모드 / 분석 모드 분기) ---
        # 1차 필터: 텍스트가 매우 짧고, 규칙 기반 점수가 거의 없는 경우 LLM 호출 없이 바로 'FRIENDLY'로 판단
        rule_scores, _, _ = rule_scoring(text)
        
        # 조건: 텍스트 길이가 10자 미만이고, 모든 규칙 기반 점수가 0.1 미만일 때
        is_simple_text = len(text) < 10 and max(rule_scores.values() or [0.0]) < 0.1

        if is_simple_text:
            triage_mode = 'FRIENDLY'
            debug_log["triage_decision"] = "Rule-based filter: Simple text"
        else:
        # 2차 판단: 1차 필터를 통과한 경우에만 LLM으로 사용자의 메시지가 분석이 필요한 내용인지, 단순 대화인지 먼저 판단!!
            triage_mode = await call_llm(
                system_prompt=TRIAGE_SYSTEM_PROMPT,
                user_content=text,
                openai_key=OPENAI_KEY,
                expect_json=False # 'ANALYSIS' OR 'FRIENDLY'
            )

            debug_log["triage_mode"] = triage_mode
            # Triage 결과에 따라 분기
            if triage_mode == 'FRIENDLY':
                debug_log["mode"] = "FRIENDLY"
                print(f"\n--- 👋 FRIENDLY MODE DEBUG ---")
                print(f"Input text: '{text}' -> Classified as FRIENDLY")
                print("------❤️-------------❤️-----------❤️-------\n")
            

                # 🤩 RIN: 친구 모드에서도 캐릭터 성향을 반영한 프롬프트 사용하기
                system_prompt = get_system_prompt(
                    mode='FRIENDLY',
                    personality=payload.character_personality,
                    language_code=payload.language_code,
                    user_nick_nm=user_nick_nm,
                    character_nm=character_nm
                )           
                friendly_text = await call_llm(system_prompt, text, OPENAI_KEY, expect_json=False)

                intervention = {"preset_id": PresetIds.FRIENDLY_REPLY, "text": friendly_text}
                # 친근한 대화도 세션을 남길 수 있음 (스코어는 비어있음)
                session_id = await save_analysis_to_supabase(payload, 0, 0.5, intervention, debug_log, {})
                return {"session_id": session_id, "intervention": intervention}

            else: # triage_mode == 'ANALYSIS' 또는 예외 발생 시 기본값
                # --- 파이프라인 3: 분석 모드 ---
                debug_log["mode"] = "ANALYSIS"
                print("\n--- 🧐 TEXT ANALYSIS DEBUG 🧐 ---")

                # 3-1. 온보딩 점수(Baseline) 계산
                onboarding_scores = calculate_baseline_scores(payload.onboarding or {})
                print(f"1. Onboarding Scores:\n{_format_scores_for_print(onboarding_scores)}")

                # 3-2. 텍스트 분석 점수(fused_scores) 계산 (LLM, Rule-based 포함)
                # rule_scores, _, _ = rule_scoring(text)
                # 🤩 RIN: 분석 모드에서도 캐릭터 성향을 반영한 프롬프트 사용하기
                system_prompt = get_system_prompt(
                    mode='ANALYSIS',
                    personality=payload.character_personality,
                    language_code=payload.language_code,
                    user_nick_nm=user_nick_nm,
                    character_nm=character_nm
                )      
                llm_payload = payload.dict()
                llm_payload["baseline_scores"] = onboarding_scores
                llm_json = await call_llm(system_prompt, json.dumps(llm_payload, ensure_ascii=False), OPENAI_KEY)
                debug_log["llm"] = llm_json
                
                # --- 파이프라인 3.5: 2차 안전 장치 (LLM 결과 기반) - 점수 계산 전 실행 ---
                is_safe_llm, crisis_scores_llm = is_safety_text(text, llm_json, debug_log)
                if is_safe_llm:
                    print(f"🚨 2차 안전 장치 발동: '{text}'")
                    # 안전 모드 발동 시에는 위기 점수를 그대로 사용하고 DB에 저장
                    profile, g = 1, g_score(crisis_scores_llm)
                    top_cluster = "neg_low"
                    intervention = {
                        "preset_id": PresetIds.SAFETY_CRISIS_MODAL,
                        "analysis_text": "많이 힘드시군요. 지금 도움이 필요할 수 있어요.",
                        "solution_id": f"{top_cluster}_crisis_01",
                        "cluster": top_cluster
                    }
                    # 이 경우, 실제 계산된 점수가 아닌 위기 점수(crisis_scores_llm)를 저장
                    session_id = await save_analysis_to_supabase(
                        payload, profile=profile, g=g, intervention=intervention,
                        debug_log=debug_log, final_scores=crisis_scores_llm
                    )
                    # 반환값도 위기 점수 기준으로 생성
                    return {
                        "session_id": session_id,
                        "final_scores": crisis_scores_llm,
                        "g_score": g,
                        "profile": profile,
                        "intervention": intervention
                    }

                # === 안전장치 모두 통과 시 ===
                # --- 파이프라인 4: 전체 스코어링 로직 ---
                # 4-1. 텍스트 분석 점수(fused_scores) 계산 
                rule_scores, _, _ = rule_scoring(text)
                text_if = {c: 0.0 for c in CLUSTERS}
                if llm_json and not llm_json.get("error"):
                    I, F = llm_json.get("intensity", {}), llm_json.get("frequency", {})
                    for c in CLUSTERS:
                        In = clip01((I.get(c, 0.0) or 0.0) / 3.0)
                        Fn = clip01((F.get(c, 0.0) or 0.0) / 3.0)
                        text_if[c] = clip01(0.6 * In + 0.4 * Fn + 0.1 * rule_scores.get(c, 0.0))
                
                fused_scores = {c: clip01(W_RULE * rule_scores.get(c, 0.0) + W_LLM * text_if.get(c, 0.0)) for c in CLUSTERS}
                print(f"2a. Rule-Based Scores:\n{_format_scores_for_print(rule_scores)}")
                print(f"2b. LLM-based Scores (I/F fusion):\n{_format_scores_for_print(text_if)}")
                print(f"2c. Fused Text Scores (Rule + LLM):\n{_format_scores_for_print(fused_scores)}")

                # 4-2. 이모지 점수(icon_prior) 생성
                icon_prior = {c: 0.0 for c in CLUSTERS}
                has_icon = payload.icon and ICON_TO_CLUSTER.get(payload.icon.lower()) != "neutral"
                if has_icon:
                    selected_cluster = ICON_TO_CLUSTER.get(payload.icon.lower())
                    icon_prior[selected_cluster] = 1.0        
                print(f"3. Icon Prior Scores:\n{_format_scores_for_print(icon_prior)}")

                
                # --- 가중치 재조정 로직 ---

                # 4-3. FINAL_FUSION_WEIGHTS를 사용하여 최종 점수 융합 (가중치 재조정 포함)
                w = FINAL_FUSION_WEIGHTS

                if not has_icon:
                # RIN 🌸 CASE 1: 텍스트만 입력 시 (icon 없음) -> icon 가중치를 text와 onboarding에 비례 배분
                    w_text = w['text'] + w['icon'] * (w['text'] / (w['text'] + w['onboarding']))
                    w_onboarding = w['onboarding'] + w['icon'] * (w['onboarding'] / (w['text'] + w['onboarding']))
                    w_icon = 0.0
                else:
                # RIN 🌸 CASE 3: 텍스트 + 이모지 입력 시 -> 모든 가중치 그대로 사용
                    w_text, w_onboarding, w_icon = w['text'], w['onboarding'], w['icon']

                weights_used = {"text": w_text, "onboarding": w_onboarding, "icon": w_icon}
                print(f"4. Final Fusion Weights:\n{_format_scores_for_print(weights_used)}")

                adjusted_scores = {c: clip01(
                    fused_scores.get(c, 0.0) * w_text +
                    onboarding_scores.get(c, 0.0) * w_onboarding +
                    icon_prior.get(c, 0.0) * w_icon
                ) for c in CLUSTERS}
                print(f"5. Final Adjusted Scores (after fusion):\n{_format_scores_for_print(adjusted_scores)}")

                debug_log["scores"] = {
                    "weights_used": {"text": w_text, "onboarding": w_onboarding, "icon": w_icon},
                    "1_onboarding_scores": onboarding_scores,
                    "2_text_fused_scores": fused_scores,
                    "3_icon_prior": icon_prior,
                    "4_final_adjusted_scores": adjusted_scores
                }
                
                # 5. 최종 결과 생성
                g = g_score(adjusted_scores)
                profile = pick_profile(adjusted_scores, llm_json)
                top_cluster = max(adjusted_scores, key=adjusted_scores.get, default="neg_low")
                
                print(f"G-Score: {g:.2f}")
                print(f"Profile: {profile}")
                print("------❤️-------------❤️-----------❤️-------\n")


                debug_log["scores"] = {
                    "weights_used": {"text": w_text, "onboarding": w_onboarding, "icon": w_icon},
                    "final_adjusted_scores": adjusted_scores
                }

                # LLM으로부터 공감 메시지와 분석 메시지를 각각 가져옴
                empathy_text = (llm_json or {}).get("empathy_response", "마음을 살피는 중이에요...")
                # 🤩 RIN: get_analysis_message 호출 시 캐릭터 성향을 넘겨주고 DB에서 맞는 멘트 가져옴
                analysis_text = await get_analysis_message(
                    adjusted_scores, 
                    payload.character_personality,
                    payload.language_code
                )
                                
                
                # 4-4. Intervention 객체 생성 및 반환 
                intervention = {
                    "preset_id": PresetIds.SOLUTION_PROPOSAL,
                    "empathy_text": empathy_text, 
                    "analysis_text": analysis_text,
                    "top_cluster": top_cluster
                }
                
                session_id = await save_analysis_to_supabase(
                    payload, profile=profile, g=g, intervention=intervention,
                    debug_log=debug_log, final_scores=adjusted_scores
                )
                
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
        pass

# ======================================================================
# ===          솔루션 엔드포인트         ===
# ======================================================================
   

@app.post("/solutions/propose")
async def propose_solution(payload: SolutionRequest): 
    """분석 결과(top_cluster)를 바탕으로 사용자에게 맞는 솔루션을 제안하는 로직"""
    if not supabase: raise HTTPException(status_code=500, detail="Supabase client not initialized")
        
    try:
        user_id = payload.user_id
        session_id = payload.session_id
        top_cluster = payload.top_cluster
        language_code = payload.language_code

        # 1. 사용자 프로필 조회 - '캐릭터 성향'과 '닉네임' 가져옴
        user_nick_nm = "사용자"
        personality = None
        try:
            user_profile_res = await run_in_threadpool(
                supabase.table("user_profiles").select("user_nick_nm, character_personality").eq("id", user_id).single().execute
            )
            if user_profile_res.data:
                user_nick_nm = user_profile_res.data.get("user_nick_nm", "친구")
                personality = user_profile_res.data.get("character_personality")
        except Exception as e:
            print(f"⚠️ User profile fetch failed for {user_id}, using defaults. Error: {e}")


        # 2. 제안 멘트와 솔루션 ID를 랜덤으로 선택

        # proposal_scripts 테이블에서 랜덤으로 제안 멘트 가져오기
        proposal_script = await get_mention_from_db(
            mention_type="propose",
            personality=personality,
            language_code=language_code,
            cluster=top_cluster,
            default_message="이런 활동은 어떠세요?",
            format_kwargs={"user_nick_nm": user_nick_nm}
        )
            
        # 3. solutions 테이블에서 해당 클러스터의 솔루션 ID 목록 가져오기
        solutions_response = await run_in_threadpool(
            supabase.table("solutions").select("solution_id, text, url, start_at, end_at, context").eq("cluster", top_cluster).execute
        )
        available_solutions = solutions_response.data
        
        if not available_solutions:
            return {"proposal_text": "지금은 제안해드릴만한 특별한 활동이 없네요. 대신, 편안하게 대화를 이어갈까요?", "solution_id": None}        
               
        # 4. 가져온 솔루션 목록 중 하나를 랜덤으로 선택
        solution_data = random.choice(available_solutions)
        solution_id = solution_data.get("solution_id")

        # 솔루션 ID가 없는 경우에 대한 예외 처리 
        if not solution_id:
            return {
                "proposal_text": "지금은 제안해드릴만한 특별한 활동이 없네요. 대신, 편안하게 대화를 이어갈까요?", 
                "solution_id": None,
                "solution_details": None
            }
        
       # 5. 최종 제안 텍스트를 조합 (멘트 + 솔루션 자체 텍스트)
        final_text = proposal_script
        if solution_data and solution_data.get('text'):
            # 멘트와 솔루션 텍스트 사이에 자연스러운 공백 추가
            final_text = f"{proposal_script} {solution_data['text']}"


        # 4. 제안 이력을 로그로 저장
        log_entry = {
            "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            "session_id": session_id,
            "user_id": user_id,
            "type": "propose",
            "solution_id": solution_id
        }
        
        try:
            # Supabase 클라이언트가 있고, 임시 ID가 아닐 때만 DB에 저장 시도
            if supabase and not session_id.startswith("temp_"):
                # 3. Supabase에 로그 삽입
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

        
        content = { 
            "proposal_text": final_text, 
            "solution_id": solution_id, 
            "solution_details": solution_data 
        }
        return JSONResponse(content=content)    
    
    except Exception as e:
        tb = traceback.format_exc()
        print(f"❌ Propose Solution Error: {e}\n{tb}")
        raise HTTPException(status_code=500, detail={"error": str(e), "trace": tb})


# ======================================================================
# ===          홈화면 대사 엔드포인트         ===
# ======================================================================
# 🤩 RIN: 홈 대사들을 성향별로 불러오도록 변경
@app.get("/dialogue/home")
async def get_home_dialogue(
    personality: Optional[str] = None, 
    user_nick_nm: Optional[str] = "친구",
    language_code: Optional[str] = 'ko',
    emotion: Optional[str] = None 
):
    """홈 화면에 표시할 대사를 반환합니다."""
    if emotion:
        # 이모지가 선택된 경우: 'reaction' 멘트를 가져옵니다.
        mention_type = "reaction"
        cluster = ICON_TO_CLUSTER.get(emotion.lower(), "common")
    else:
        # 이모지가 없는 초기 상태: 'home' 멘트를 가져옵니다.
        mention_type = "home"
        cluster = "common"

    dialogue_text = await get_mention_from_db(
        mention_type=mention_type,
        personality=personality,
        language_code=language_code,
        cluster=cluster,
        default_message=f"안녕, {user_nick_nm}! 오늘 기분은 어때?",
        format_kwargs={"user_nick_nm": user_nick_nm}
    )
    
    return {"dialogue": dialogue_text}
    
# ======================================================================
# ===  솔루션 완료 후 후속 질문을 위한 엔드포인트   ===
# ======================================================================
@app.get("/dialogue/solution-followup")
async def get_solution_followup_dialogue(
    reason: str, # 'user_closed' 또는 'video_ended'
    personality: Optional[str] = None, 
    user_nick_nm: Optional[str] = "친구",
    language_code: Optional[str] = 'ko'
):
    """솔루션이 끝난 후의 상황(reason)과 캐릭터 성향에 맞는 후속 질문을 반환합니다."""
    
    # 이유(reason)에 따라 DB에서 조회할 mention_type을 결정합니다.
    if reason == 'user_closed':
        mention_type = "followup_user_closed"
    else: # 'video_ended' 또는 기타
        mention_type = "followup_video_ended"

    # get_mention_from_db 헬퍼 함수를 사용하여 멘트를 가져옵니다.
    dialogue_text = await get_mention_from_db(
        mention_type=mention_type,
        personality=personality,
        language_code=language_code,
        cluster="common", 
        default_message="어때요? 좀 좋아진 것 같아요?😊",
        format_kwargs={"user_nick_nm": user_nick_nm}
    )
    
    return {"dialogue": dialogue_text}


# ======================================================================
# ===  솔루션 완료 후 후속 질문을 위한 엔드포인트   ===
# ======================================================================

# 솔루션 제안을 거절했을 때의 멘트를 성향별로 주기 위해 추가
@app.get("/dialogue/decline-solution")
async def get_decline_solution_dialogue(
    personality: Optional[str] = None, 
    user_nick_nm: Optional[str] = "친구",
    language_code: Optional[str] = 'ko'
):
    """솔루션 제안을 거절하고 대화를 이어가고 싶어할 때의 반응 멘트를 반환합니다."""
    
    dialogue_text = await get_mention_from_db(
        mention_type="decline_solution",
        personality=personality,
        language_code=language_code,
        cluster="common",
        default_message="알겠습니다. 그럼요. 저에게 편안하게 털어놓으세요. 귀 기울여 듣고 있을게요.",
        format_kwargs={"user_nick_nm": user_nick_nm}
    )
    
    return {"dialogue": dialogue_text}


# ======================================================================
# ===          솔루션 영상 엔드포인트         ===
# ======================================================================

    # SolutionPage에서 영상 로드
    # 하드코딩된 SOLUTION_DETAILS_LIBRARY를 DB 조회로 대체했음!!
@app.get("/solutions/{solution_id}")
async def get_solution_details(solution_id: str):
    print(f"RIN: ✅ 솔루션 상세 정보 요청 받음: {solution_id}")
    
    if not supabase:
        raise HTTPException(status_code=500, detail="Supabase client not initialized")
    
    try:
        # solutions 테이블에서 필요한 데이터를 조회
        response = await run_in_threadpool(
            supabase.table("solutions")
            .select("url, start_at, end_at")
            .eq("solution_id", solution_id)
            .single()
            .execute
        )
        
        solution_data = response.data
        
        if not solution_data:
            raise HTTPException(status_code=404, detail="Solution not found")

        # 유튜브 불러올때 startAt, endAt (camelCase)를 기대하므로 키를 변환해줌
        # supabase는 snake_case로 저장해야 한다고 함.
        response_data = {
            'url': solution_data.get('url'),
            'startAt': solution_data.get('start_at'),
            'endAt': solution_data.get('end_at')
        }
        
        print(f"RIN: ✅ 솔루션 정보 반환: {response_data}")
        return response_data
        
    except Exception as e:
        print(f"RIN: ❌ 해당 솔루션을 찾을 수 없음: {solution_id}, 에러: {e}")
        raise HTTPException(status_code=404, detail="Solution not found")
    

# ======================================================================
# ===     리포트 요약 엔드포인트     ===
# ======================================================================




