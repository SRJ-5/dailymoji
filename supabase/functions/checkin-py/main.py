# main.py
from __future__ import annotations

import asyncio
import datetime as dt
import json
import os
import re
import traceback
import random
from typing import Optional, List, Dict, Any, Tuple
import uuid
from localization import DEFAULT_LANG, get_translation, translations

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import JSONResponse
import numpy as np
from pydantic import BaseModel
from supabase import create_client, Client

from ai_moderator import moderate_text
from llm_prompts import (
    REPORT_SUMMARY_PROMPT, WEEKLY_REPORT_SUMMARY_PROMPT_STANDARD, WEEKLY_REPORT_SUMMARY_PROMPT_NEURO,
    call_llm, get_adhd_breakdown_prompt, get_system_prompt, TRIAGE_SYSTEM_PROMPT, FRIENDLY_SYSTEM_PROMPT
)
from rule_based import rule_scoring
from srj5_constants import (
    ASSESSMENT_SCORE_CAP, CLUSTER_TO_DISPLAY_NAME, CLUSTERS, DEEP_DIVE_MAX_SCORES, EMOJI_ONLY_SCORE_CAP, FINAL_FUSION_WEIGHTS_NO_ICON, ICON_TO_CLUSTER, ONBOARDING_MAPPING,
    FINAL_FUSION_WEIGHTS, FINAL_FUSION_WEIGHTS_NO_TEXT,
    W_LLM, W_RULE, 
    SAFETY_LEMMAS, SAFETY_LEMMA_COMBOS, SAFETY_REGEX, SAFETY_FIGURATIVE
)


try:
    from kiwipiepy import Kiwi
    _kiwi = Kiwi()
except ImportError:
    _kiwi = None
    print(get_translation("log_error_kiwi_not_installed", DEFAULT_LANG))


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
    print(get_translation("log_startup_success", DEFAULT_LANG))

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

# --- 데이터 모델 (분리된 구조에 맞게 수정) ---


# 이전 대화 기록(history)을 받기 위한 모델 수정
class HistoryItem(BaseModel):
    sender: str
    content: str

# /analyze 엔드포인트의 입력 모델
class AnalyzeRequest(BaseModel):
    user_id: str
    text: str
    icon: Optional[str] = None
    language_code: Optional[str] = 'ko'
    timestamp: Optional[str] = None
    onboarding: Optional[Dict[str, Any]] = None
    character_personality: Optional[str] = None
    history: Optional[List[HistoryItem]] = None 
    # ADHD 분기 로직 처리를 위한 상태 정보
    adhd_context: Optional[Dict[str, Any]] = None


# /solutions/propose 엔드포인트의 입력 모델
class SolutionRequest(BaseModel):
    user_id: str
    session_id: str
    top_cluster: str
    language_code: str = 'ko'

      
class FeedbackRequest(BaseModel):
    user_id: str
    solution_id: str
    session_id: Optional[str] = None
    solution_type: str
    feedback: str
    language_code: Optional[str] = 'ko'


class BackfillRequest(BaseModel):
    start_date: str  # "YYYY-MM-DD" 형식
    end_date: str    # "YYYY-MM-DD" 형식
    user_id: Optional[str] = None  # 특정 사용자 ID (선택사항)
    language_code: Optional[str] = 'ko'


# /assessment/submit 엔드포인트의 입력 모델
class AssessmentSubmitRequest(BaseModel):
    user_id: str
    cluster: str  # "neg_low", "neg_high" 등 평가한 클러스터
    responses: Dict[str, int] # {"NGL_01": 3, "NGL_02": 2, ...} 형태의 답변
    language_code: Optional[str] = 'ko'
class DailyReportRequest(BaseModel):
    user_id: str
    date: str
    language_code: str = 'ko'

class WeeklyReportRequest(BaseModel):
    user_id: str
    language_code: Optional[str] = 'ko'

# Flutter의 PresetIds와 동일한 구조
class PresetIds:
    FRIENDLY_REPLY = "FRIENDLY_REPLY"
    SOLUTION_PROPOSAL = "SOLUTION_PROPOSAL"
    SAFETY_CRISIS_MODAL = "SAFETY_CRISIS_MODAL"
    EMOJI_REACTION = "EMOJI_REACTION"
    ADHD_PRE_SOLUTION_QUESTION = "ADHD_PRE_SOLUTION_QUESTION"
    ADHD_AWAITING_TASK_DESCRIPTION = "ADHD_AWAITING_TASK_DESCRIPTION"
    ADHD_TASK_BREAKDOWN = "ADHD_TASK_BREAKDOWN"



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

def is_safety_text(text: str, llm_json:  Optional[dict], debug_log: dict) -> Tuple[bool, dict]:
    """
    점수 체계 및 안전 모드 설명: 이 함수는 사용자의 텍스트에서 자해/자살 위험을 다단계로 분석합니다.
    - 1단계: "졸려 죽겠다"와 같이 명백히 안전한 비유적 표현을 먼저 걸러냅니다.
    - 2단계: Kiwi 형태소 분석('죽다', '자살' 등)과 LLM의 의도 분석('self_harm' 플래그)으로 위험 신호를 탐지합니다.
    - "다 때려치우고 싶다"와 같은 문장은 명시적인 자해 단어가 없어 1, 2단계를 통과할 수 있지만,
      LLM이 문장의 절망적인 뉘앙스를 'self_harm: possible'로 판단하면 안전 장치가 발동될 수 있습니다.
      이러한 오탐지는 모델의 보수적인 안전 설계 때문이며, 지속적인 프롬프트 튜닝이 필요합니다.
    """

    # 1단계: 비유적/관용적 표현 우선 필터링 ("졸려 죽겠다" 등)
    # SAFETY_FIGURATIVE에 매치되면, 위험하지 않은 것으로 간주하고 즉시 종료
    figurative_matches = [m.group(0) for pat in SAFETY_FIGURATIVE for m in re.finditer(pat, text, flags=re.IGNORECASE)]
    if figurative_matches:
        debug_log["safety"] = {
            "triggered": False,
            "reason": get_translation("log_safety_figurative", DEFAULT_LANG),
            "matches": figurative_matches
        }
        return False, {}

    # 2단계: Kiwi 형태소 분석 및 LLM 의도 분석
    kiwi_lemma_hits = []
    if _kiwi:
        try:
            tokens = _kiwi.tokenize(text)
            lemmas_in_text = {t.lemma for t in tokens}
            hits = {t.lemma for t in tokens if t.lemma in SAFETY_LEMMAS}
            for combo in SAFETY_LEMMA_COMBOS:
                if combo.issubset(lemmas_in_text):
                    hits.update(combo)
            kiwi_lemma_hits = list(hits)
        except Exception as e:
            print(f"Kiwi safety check error: {e}")

    safety_llm_flag = (llm_json or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}
    
    # Kiwi 또는 LLM 중 하나라도 위험 신호를 감지하면 안전장치 발동
    triggered = bool(kiwi_lemma_hits) or safety_llm_flag

    debug_log["safety"] = {
        "kiwi_lemma_hits": kiwi_lemma_hits,
        "llm_intent_flag": safety_llm_flag,
        "triggered": triggered
    }

    if triggered:
        # 위기 상황에 맞는 극단적인 점수 부여
        crisis_scores = {"neg_low": 0.95, "neg_high": 0.0, "adhd": 0.0, "sleep": 0.0, "positive": 0.0}
        return True, crisis_scores

    return False, {}



# ======================================================================
# === 핵심 로직: 스코어링 및 융합 (Scoring & Fusion) ===
# ======================================================================

def calculate_final_scores(
    text_scores: dict,
    assessment_scores: dict,
    icon_scores: dict,
    has_icon: bool
) -> Tuple[dict, dict]:
    """텍스트, 마음 점검, 아이콘 점수를 중앙에서 융합합니다."""
    if not has_icon:
        # CASE 1: 텍스트만 입력 시 -> 아이콘 가중치를 비례 배분
        w = FINAL_FUSION_WEIGHTS_NO_ICON
        weights_used = {"text": w['text'], "assessment": w['assessment'], "icon": 0.0}
        final_scores = {c: clip01(
            text_scores.get(c, 0.0) * w['text'] +
            assessment_scores.get(c, 0.0) * w['assessment']
        ) for c in CLUSTERS}
    else:
        # CASE 2: 텍스트 + 아이콘 입력 시 -> 모든 가중치 그대로 사용
        w = FINAL_FUSION_WEIGHTS
        weights_used = {"text": w['text'], "assessment": w['assessment'], "icon": w['icon']}
        final_scores = {c: clip01(
            text_scores.get(c, 0.0) * w['text'] +
            assessment_scores.get(c, 0.0) * w['assessment'] +
            icon_scores.get(c, 0.0) * w['icon']
        ) for c in CLUSTERS}

    return final_scores, weights_used

def calculate_text_scores(text: str, llm_json: Optional[dict]) -> dict:
    """Rule-based 점수와 LLM 점수를 융합하여 텍스트 기반 최종 점수를 계산합니다."""
    rule_scores, _, _ = rule_scoring(text)
    
    text_if = {c: 0.0 for c in CLUSTERS}
    if llm_json and not llm_json.get("error"):
        I, F = llm_json.get("intensity", {}), llm_json.get("frequency", {})
        for c in CLUSTERS:
            In = clip01((I.get(c, 0.0) or 0.0) / 3.0)
            Fn = clip01((F.get(c, 0.0) or 0.0) / 3.0)
            text_if[c] = clip01(0.6 * In + 0.4 * Fn + 0.1 * rule_scores.get(c, 0.0))
    
    fused_scores = {c: clip01(W_RULE * rule_scores.get(c, 0.0) + W_LLM * text_if.get(c, 0.0)) for c in CLUSTERS}
    return fused_scores

# ======================================================================
# === 헬퍼 함수 (Helpers) ===
# ======================================================================

def _format_scores_for_print(scores: dict) -> str:
    """점수 딕셔너리를 소수점 2자리까지 예쁘게 출력하기 위한 함수"""
    if not isinstance(scores, dict):
        return str(scores)
    return json.dumps({k: round(v, 2) if isinstance(v, float) else v for k, v in scores.items()})

def clip01(x: float) -> float: return max(0.0, min(1.0, float(x)))

def g_score(final_scores: dict) -> float:
    w = {"neg_high": 1.0, "neg_low": 0.9, "sleep": 0.7, "adhd": 0.6, "positive": -0.3}
    g = sum(final_scores.get(k, 0.0) * w.get(k, 0.0) for k in CLUSTERS)
    return round(clip01((g + 1.0) / 2.0), 3)

def pick_profile(final_scores: dict, llm: Optional[dict]) -> int: # surveys 파라미터 제거
    if (llm or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}: return 1
    if max(final_scores.get("neg_low", 0), final_scores.get("neg_high", 0)) > 0.85: return 1
    # if (surveys and (surveys.get("phq9", 0) >= 10 or surveys.get("gad7", 0) >= 10)) or max(final_scores.values()) > 0.60: return 2
    if max(final_scores.values()) > 0.60: return 2 # surveys 필드 제거
    if max(final_scores.values()) > 0.30: return 3
    return 0

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

# ======================================================================
# === DB 관련 헬퍼 함수 ===
# ======================================================================
async def get_user_info(user_id: str, lang_code: str = 'ko') -> Tuple[str, str]:
    """사용자 닉네임과 캐릭터 이름을 DB에서 조회합니다."""
    default_user = get_translation("default_user_name", lang_code) # localization.py에 추가 필요
    default_char = get_translation("default_char_name", lang_code) # localization.py에 추가 필요

    if not supabase:
        return default_user, default_char
    
    try:
        res = await run_in_threadpool(
            supabase.table("user_profiles")
            .select("user_nick_nm, character_nm")
            .eq("id", user_id).single().execute
        )
        if res.data:
            user_nick = res.data.get("user_nick_nm") or default_user
            char_name = res.data.get("character_nm") or default_char
            return user_nick, char_name
        else:
             # 사용자가 DB에 있지만 이름이 없는 경우 (거의 없음)
             return default_user, default_char
    except Exception as e: 
        print(get_translation("log_error_fetch_user_info", DEFAULT_LANG, user_id=user_id, error=str(e)))
        return default_user, default_char


# 모든 멘트 조회를 통합 관리하는 함수
async def get_mention_from_db(mention_type: str, language_code: str, **kwargs) -> str:
    """DB에서 지정된 타입과 조건에 맞는 캐릭터 멘트를 랜덤으로 가져옵니다."""
    print(f"--- ✅ get_mention_from_db (type: {mention_type}, lang: {language_code}) ✅ ---")

    default_keys = {
        "analysis": "default_analysis_message",
        "reaction": "default_reaction_message",
        "propose": "default_propose_message",
        "home": "default_home_message",
        "followup_user_closed": "default_followup_user_closed",
        "followup_video_ended": "default_followup_video_ended",
        "decline_solution": "default_decline_solution",
        "adhd_question": "adhd_ask_task"
    }
    default_key = default_keys.get(mention_type, "...")

    # .format()에 사용될 인자들을 미리 준비합니다.
    format_args = kwargs.get("format_kwargs", kwargs)

    default_message = get_translation(default_key, language_code, **(format_args or {}))

    def _safe_format(text: str) -> str:
        """KeyError 없이 안전하게 문자열을 포맷팅하는 내부 함수"""
        try:
            # format_args가 None일 경우를 대비해 빈 dict으로 처리
            return text.format(**(format_args or {}))
        except KeyError as e:
            print(get_translation("log_warn_missing_format_key", DEFAULT_LANG, key=str(e), lang=language_code, text=text))
            try:
                placeholders = re.findall(r'\{([^}]+)\}', text)
                safe_kwargs = {**{p: f"{{{p}}}" for p in placeholders}, **(format_args or {})}
                return text.format(**safe_kwargs)
            except:
                return text # Final fallback

    if not supabase:
        return default_message


    # if not supabase: return default_message.format(**kwargs) if kwargs else default_message
    try:
        query = supabase.table("character_mentions").select("text").eq("mention_type", mention_type).eq("language_code", language_code)
        
        valid_filter_keys = ["personality", "cluster", "level", "solution_variant"]
        for key, value in kwargs.items():
            if key in valid_filter_keys and value:
                query = query.eq(key, value)

        response = await run_in_threadpool(query.execute)
        scripts = [row['text'] for row in response.data]
        
        if not scripts:
            print(get_translation("log_warn_no_mention_found", DEFAULT_LANG, mention_type=mention_type, lang=language_code, filters=kwargs))
            return default_message # Return already formatted default
        
        selected_script = random.choice(scripts)
        # DB에서 가져온 멘트도 안전하게 포맷팅
        return _safe_format(selected_script)

    except Exception as e:
        print(get_translation("log_error_get_mention", DEFAULT_LANG, error=str(e)))
        return default_message


# # 수치를 주기보다는, 심각도 3단계에 따라 메시지 해석해주는게 달라짐(수치형x, 대화형o)
# async def get_analysis_message(
#     scores: dict, 
#     personality: Optional[str], 
#     language_code: str
# ) -> str:
#     if not scores: return "당신의 마음을 더 들여다보고 있어요."
#     top_cluster = max(scores, key=scores.get)
#     score_val = scores[top_cluster]
    
#     level = "low"
#     if score_val > 0.7: level = "high"
#     elif score_val > 0.4: level = "mid"
    
#     return await get_mention_from_db(
#         mention_type="analysis",
#         personality=personality,
#         language_code=language_code,
#         cluster=top_cluster,
#         level=level,
#         default_message="오늘 당신의 마음은 특별한 색을 띠고 있네요.",
#         format_kwargs={"emotion": top_cluster, "score": int(score_val * 100)}
#     )
    


async def save_analysis_to_supabase(
    payload: AnalyzeRequest, profile: int, g: float,
    intervention: dict, debug_log: dict, final_scores: dict,
    lang_code: str = 'ko'
) -> Optional[str]:
    """분석 결과를 Supabase에 저장합니다."""
    if not supabase: return None
    try:
        user_id = payload.user_id

        # 세션을 저장하기 전, user_profiles에 해당 유저가 있는지 확인하고 없으면 생성
        profile_query = supabase.table("user_profiles").select("id").eq("id", user_id)
        profile_response = await run_in_threadpool(profile_query.execute)
        
        if not profile_response.data:
            print(get_translation("error_user_profile_not_found_creating", lang_code, user_id=user_id))            
            insert_query = supabase.table("user_profiles").insert({
                "id": user_id, 
                "user_nick_nm": get_translation("default_user_name", lang_code)
            })
            await run_in_threadpool(insert_query.execute)


        session_row = {
            "user_id": user_id, "text": payload.text, "icon": payload.icon,
            "profile": int(profile), "g_score": float(g),
            "intervention": json.dumps(intervention, ensure_ascii=False),
            "debug_log": json.dumps(debug_log, ensure_ascii=False),
            "summary": (debug_log.get("llm") or {}).get("summary", ""),
        }
        
        session_insert_query = supabase.table("sessions").insert(session_row)
        response = await run_in_threadpool(session_insert_query.execute)
        
        session_data = response.data[0] if response.data else {}
        new_session_id = session_data.get('id')

        if not new_session_id:
            print(get_translation("error_failed_to_save_session", lang_code))
            return None
        
        print(get_translation("log_session_saved", lang_code, session_id=new_session_id))

        if final_scores:
            score_rows = [
                {"session_id": new_session_id, "user_id": payload.user_id, "cluster": c, "score": v}
                for c, v in final_scores.items()
            ]
            if score_rows:
                for row in score_rows:
                    row["session_text"] = payload.text
                
                # .execute를 분리
                scores_insert_query = supabase.table("cluster_scores").insert(score_rows)
                await run_in_threadpool(scores_insert_query.execute)
        
        return new_session_id
    except Exception as e:
        print(get_translation("error_supabase_save_failed", lang_code, error=str(e)))
        traceback.print_exc()
        return None


# RIN: ADHD 질문에 대한 사용자 답변을 처리하는 함수
async def _handle_adhd_response(payload: AnalyzeRequest, debug_log: dict, lang_code: str = 'ko'):
    user_response = payload.text
    adhd_context = payload.adhd_context or {}
    current_step = adhd_context.get("step")
    user_nick_nm, _ = await get_user_info(payload.user_id, lang_code) 

    # --- 시나리오 1: "있어!" / "없어!" 버튼을 눌렀을 때 ---
    if current_step == "awaiting_choice":
        # "있어!" / "없어!" 버튼에 대한 응답 처리
        if "adhd_has_task" in user_response:
            # 다음 단계: 할 일이 무엇인지 물어보기
            question_text = await get_mention_from_db(
                mention_type="adhd_ask_task",
                language_code=lang_code,
                personality=payload.character_personality,
                format_kwargs={"user_nick_nm": user_nick_nm}
            )
            return {
                "intervention": {
                    "preset_id": PresetIds.ADHD_AWAITING_TASK_DESCRIPTION,
                    "text": question_text,
                    "adhd_context": {"step": "awaiting_task_description"}
                }
            }
        else: # "adhd_no_task"
         # "없어!"를 누른 경우 -> 호흡 및 집중력 훈련 마음 관리 팁 제안
            
            # 1. '집중력 훈련' 마음 관리 팁을 DB에서 찾습니다.
            focus_solution_query = supabase.table("solutions").select("solution_id, solution_type").eq("cluster", "adhd").eq("solution_variant", "focus_training").limit(1)
            focus_solution_res = await run_in_threadpool(focus_solution_query.execute)
            focus_solution_data = focus_solution_res.data[0] if focus_solution_res.data else {}

            # 2. '호흡' 마음 관리 팁 - 프론트엔드 라우팅을 위해서!
            breathing_solution_data = {
            "solution_id": "breathing_default", 
            "solution_type": "breathing"
            }
            
              # 3. 제안 멘트를 가져옵니다.
            proposal_text = await get_mention_from_db(
                "propose", 
                lang_code,
                cluster="adhd", 
                personality=payload.character_personality,
                format_kwargs={"user_nick_nm": user_nick_nm}
            )     

            # 마음 관리 팁 제안 시점에 session 생성
            intervention_for_db = { "preset_id": PresetIds.SOLUTION_PROPOSAL, "proposal_text": proposal_text}
            session_id = await save_analysis_to_supabase(payload, 0, 0.5, intervention_for_db, debug_log, {}, lang_code)
        

            return {
                "intervention": {
                    "preset_id": PresetIds.SOLUTION_PROPOSAL,
                    "proposal_text": proposal_text,
                    "options": [
                         { "label": get_translation("label_breathing", lang_code), # 🥑 Use get_translation
                           "action": "accept_solution", "solution_id": breathing_solution_data.get("solution_id"), "solution_type": "breathing" },
                         { "label": get_translation("label_focus_training", lang_code), # 🥑 Needs key "label_focus_training"
                           "action": "accept_solution", "solution_id": focus_solution_data.get("solution_id"), "solution_type": focus_solution_data.get("solution_type") },
                    ],
                    "session_id": session_id
                }
            }

        
            # --- 시나리오 2: 사용자가 할 일을 입력했을 때 ---
    elif current_step == "awaiting_task_description":
        # 사용자가 입력한 할 일 내용을 받아 처리
        user_nick_nm, _ = await get_user_info(payload.user_id, lang_code)
        
        # 성격에 맞는 프롬프트 템플릿을 가져옵니다.
        prompt_template = get_adhd_breakdown_prompt(payload.character_personality)
        
        # 가져온 템플릿에 변수를 채워 최종 프롬프트를 완성합니다.
        final_prompt = prompt_template.format(user_nick_nm=user_nick_nm, user_message=user_response)
        
        breakdown_result = await call_llm(
            system_prompt=final_prompt, # 완성된 프롬프트를 system_prompt로 사용
            user_content="", # user_content는 비워두기
            openai_key=OPENAI_KEY, 
            lang_code=lang_code,
            expect_json=True
        )
        
        coaching_text = breakdown_result.get("coaching_text", get_translation("adhd_fallback_coaching", lang_code))
        mission_text = breakdown_result.get("mission_text", get_translation("adhd_fallback_mission", lang_code))

         # 뽀모도로 마음 관리 팁 정보 조회
        solution_query = supabase.table("solutions").select("solution_id, solution_type").eq("cluster", "adhd").eq("solution_variant", "pomodoro").limit(1)
        solution_res = await run_in_threadpool(solution_query.execute)
        solution_data = solution_res.data[0] if solution_res.data else {}

        # DB에 저장할 intervention 객체 먼저 생성
        intervention_for_db = { 
            "preset_id": PresetIds.ADHD_TASK_BREAKDOWN, 
            "coaching_text": coaching_text, 
            "mission_text": mission_text 
        }

        # 뽀모도로 제안 시점에 session 생성
        session_id = await save_analysis_to_supabase(payload, 0, 0.5, intervention_for_db, debug_log, {}, lang_code)

        # intervention 객체 안에 options와 session_id를 포함시켜 한번에 반환합니다.
        intervention_for_client = intervention_for_db.copy()
        intervention_for_client["options"] = [
            {
                "label": get_translation("label_pomodoro_mission", lang_code),
                "action": "accept_solution",
                "solution_id": solution_data.get("solution_id"),
                "solution_type": solution_data.get("solution_type")
            }
        ]
        intervention_for_client["session_id"] = session_id

        return { "intervention": intervention_for_client }

# ---------- API Endpoints (분리된 구조) ----------


# ======================================================================
# === /analyze 엔드포인트 처리 로직 (분리된 함수들) ===
# ======================================================================

async def _handle_moderation(text: str, lang_code: str = 'ko') -> bool:
    """OpenAI Moderation API를 호출하여 유해 콘텐츠를 확인하고 차단 여부를 반환합니다."""
    is_flagged, categories = await moderate_text(text, OPENAI_KEY, lang_code)
    if not is_flagged:
        return False

    allowed_categories = {'self-harm', 'self-harm/intent', 'self-harm/instructions', 'hate', 'harassment', 'violence'}
    should_block = any(cat not in allowed_categories and triggered for cat, triggered in categories.items())
    
    if should_block:
        print(get_translation("log_moderation_blocked", DEFAULT_LANG, text=text, categories=categories))
    else:
        print(get_translation("log_moderation_passed", DEFAULT_LANG, text=text, categories=categories))
    
    return should_block

async def _handle_emoji_only_case(payload: AnalyzeRequest, debug_log: dict, lang_code: str = 'ko'):
    """아이콘만 입력된 경우를 처리합니다."""
    debug_log["mode"] = "EMOJI_REACTION"
    print(f"\n--- 🧐 EMOJI-ONLY ANALYSIS (Lang: {lang_code}) ---")

    selected_cluster = ICON_TO_CLUSTER.get(payload.icon.lower(), "neg_low")
    
    if selected_cluster == "neutral":
        intervention = {"preset_id": PresetIds.EMOJI_REACTION, "text": get_translation("neutral_emoji_response", lang_code), "top_cluster": "neutral"}        
        session_id = await save_analysis_to_supabase(payload, 0, 0.5, intervention, debug_log, {}, lang_code)

        return {"session_id": session_id, "intervention": intervention}
    
    assessment_scores = calculate_baseline_scores(payload.onboarding) # 이모지만 있을 땐 온보딩 점수 사용
    icon_scores = {c: 1.0 if c == selected_cluster else 0.0 for c in CLUSTERS}
   
    w = FINAL_FUSION_WEIGHTS_NO_TEXT
    fused_scores = {c: clip01(assessment_scores.get(c, 0.0) * w['assessment'] + icon_scores.get(c, 0.0) * w['icon']) for c in CLUSTERS}
    
    # 점수 상한선(Cap) 적용
    final_scores = fused_scores.copy()
    if selected_cluster in final_scores:
        final_scores[selected_cluster] = min(final_scores[selected_cluster], EMOJI_ONLY_SCORE_CAP)
   
    g, profile = g_score(final_scores), pick_profile(final_scores, None)
    
    user_nick_nm, _ = await get_user_info(payload.user_id, lang_code)
    reaction_text = await get_mention_from_db("reaction", lang_code, personality=payload.character_personality, cluster=selected_cluster, user_nick_nm=user_nick_nm)
    intervention = {"preset_id": PresetIds.EMOJI_REACTION, "top_cluster": selected_cluster, "empathy_text": reaction_text}
    session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, final_scores, lang_code)
    return {"session_id": session_id, "final_scores": final_scores, "g_score": g, "profile": profile, "intervention": intervention}


async def _handle_friendly_mode(payload: AnalyzeRequest, debug_log: dict, lang_code: str = 'ko') -> dict:
    """Triage 결과가 '친구 모드'일 경우를 처리합니다."""
    debug_log["mode"] = "FRIENDLY"
    print(f"\n--- 👋 FRIENDLY MODE (Lang: {lang_code}): '{payload.text}' ---")

    user_nick_nm, character_nm = await get_user_info(payload.user_id, lang_code)
    system_prompt = get_system_prompt(
        mode='FRIENDLY', personality=payload.character_personality, language_code=lang_code,
        user_nick_nm=user_nick_nm, character_nm=character_nm
    )
    # 이전 대화 기억: 친구 모드에서도 대화 기록을 user_content에 포함
    history_str = "\n".join([f"{h.sender}: {h.content}" for h in payload.history]) if payload.history else ""
    user_content = f"Previous conversation:\n{history_str}\n\nCurrent message: {payload.text}"

    llm_response = await call_llm(system_prompt, user_content, OPENAI_KEY, lang_code=lang_code, expect_json=False)

    # LLM 호출 결과를 바로 사용하지 않고, 에러인지 먼저 확인합니다.
    final_text = llm_response if not (isinstance(llm_response, dict) and 'error' in llm_response) else get_translation("default_llm_friendly_fallback", lang_code)
    intervention = {"preset_id": PresetIds.FRIENDLY_REPLY, "text": final_text}
    
    session_id = await save_analysis_to_supabase(payload, 0, 0.5, intervention, debug_log, {}, lang_code)    
    return {"session_id": session_id, "intervention": intervention}


async def _run_analysis_pipeline(payload: AnalyzeRequest, debug_log: dict, lang_code: str = 'ko') -> dict: 
    """Triage 결과가 '분석 모드'일 경우의 전체 파이프라인을 실행합니다."""
    debug_log["mode"] = "ANALYSIS"
    print(f"\n--- 🧐 ANALYSIS MODE (Lang: {lang_code}): '{payload.text}' ---")

     # 1. 사용자의 최신 평가 점수(assessment_scores)를 DB에서 가져옵니다.
    #    이 점수는 온보딩으로 시작해서, 심층 분석을 할 때마다 업데이트됩니다.
    user_nick_nm, character_nm = await get_user_info(payload.user_id, lang_code)    
   
    profile_res = await run_in_threadpool(
        supabase.table("user_profiles")
        .select("latest_assessment_scores")
        .eq("id", payload.user_id).single().execute
    )
    
    assessment_scores = (profile_res.data or {}).get("latest_assessment_scores", {})
    if not assessment_scores or not isinstance(assessment_scores, dict):
        # 최신 평가 점수가 없으면(예: 첫 사용자), 온보딩 점수를 대신 사용합니다.
        print(get_translation("log_warn_no_assessment_scores", DEFAULT_LANG))
        assessment_scores = calculate_baseline_scores(payload.onboarding)
    # assessment_scores에 상한선(Cap)을 적용
    for cluster in assessment_scores:
        assessment_scores[cluster] = min(assessment_scores.get(cluster, 0.0), ASSESSMENT_SCORE_CAP)

    # --------------------------------------------------------------------------
    # 2. 시스템 프롬프트 준비 
    system_prompt = get_system_prompt(
        mode='ANALYSIS', personality=payload.character_personality, language_code=lang_code,
        user_nick_nm=user_nick_nm, character_nm=character_nm
    )

   # 이전 대화 기억: 분석 모드에서도 LLM 호출 시 history를 포함
    history_for_llm = [h.dict() for h in payload.history] if payload.history else []
    llm_payload = {"user_message": payload.text, "baseline_scores": assessment_scores, "history": history_for_llm}
   
    # 2. LLM 호출 및 2차 안전 장치
    llm_json = await call_llm(system_prompt, json.dumps(llm_payload, ensure_ascii=False), OPENAI_KEY, lang_code=lang_code)
    debug_log["llm"] = llm_json

    is_crisis, crisis_scores = is_safety_text(payload.text, llm_json, debug_log)
    if is_crisis:
        print(get_translation("log_safety_triggered_2nd", DEFAULT_LANG, text=payload.text))
        g, profile, top_cluster = g_score(crisis_scores), 1, "neg_low"
        intervention = {
            "preset_id": PresetIds.SAFETY_CRISIS_MODAL,
            "analysis_text": get_translation("safety_crisis_text", lang_code), # 🥑 Use translation
            "cluster": top_cluster,
            "solution_id": f"{top_cluster}_crisis_01"
        }        
        session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, crisis_scores, lang_code)
        return {"session_id": session_id, "final_scores": crisis_scores, "g_score": g, "profile": profile, "intervention": intervention}


    # 3. 모든 점수 계산 및 융합
    text_scores = calculate_text_scores(payload.text, llm_json)
    
    has_icon = payload.icon and ICON_TO_CLUSTER.get(payload.icon.lower()) != "neutral"
    icon_scores = {c: 0.0 for c in CLUSTERS}
    if has_icon:
        icon_scores[ICON_TO_CLUSTER.get(payload.icon.lower())] = 1.0


    final_scores, weights_used = calculate_final_scores(text_scores, assessment_scores, icon_scores, has_icon)
    debug_log["scores"] = {"weights_used": weights_used, "assessment_base": assessment_scores, "text": text_scores, "icon": icon_scores, "final": final_scores}
    print(f"Scores -> Assessment Base: {_format_scores_for_print(assessment_scores)}, Text: {_format_scores_for_print(text_scores)}, Icon: {_format_scores_for_print(icon_scores)}")
    print(f"Weights: {_format_scores_for_print(weights_used)} -> Final Scores: {_format_scores_for_print(final_scores)}")


    # 4. 최종 결과 생성
    g, profile = g_score(final_scores), pick_profile(final_scores, llm_json)
    top_cluster = max(final_scores, key=final_scores.get, default="neg_low")
    print(f"G-Score: {g:.2f}, Profile: {profile}")
    
    empathy_text = (llm_json or {}).get("empathy_response", get_translation("default_empathy_fallback", lang_code))
    score_val = final_scores[top_cluster]
    level = "high" if score_val > 0.7 else "mid" if score_val > 0.4 else "low"
 
    cluster_display_name = get_translation(f"cluster_{top_cluster}", lang_code)

    # 'analysis' 타입의 멘트를 DB에서 가져옴
    analysis_text = await get_mention_from_db(
        "analysis", 
        lang_code,
        personality=payload.character_personality, 
        cluster=top_cluster, 
        level=level, 
        format_kwargs={"emotion": cluster_display_name, "user_nick_nm": user_nick_nm}
    )
    
    # intervention 객체 생성 및 DB 저장
    intervention = {
        "preset_id": PresetIds.SOLUTION_PROPOSAL, 
        "top_cluster": top_cluster, 
        "empathy_text": empathy_text, 
        "analysis_text": analysis_text
    }

    session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, final_scores, lang_code)
    
    # --- 저장 후 최종 반환 객체 구성 ---
    analysis_result = {
        "session_id": session_id,
        "final_scores": final_scores,
        "g_score": g,
        "profile": profile,
        "intervention": intervention # 일단 기본 intervention 할당
    }
    # intervention 객체에 session_id 추가 (ADHD 분기에서도 사용 가능하도록)
    analysis_result["intervention"]["session_id"] = session_id


    # --- 🥑 ADHD 분기 로직 (세션 저장 *후*, 최종 반환 *전*) ---
    if top_cluster == "adhd":
        print(get_translation("log_adhd_detected", lang_code)) # 로그 번역 사용

        question_text_template = await get_mention_from_db(
            mention_type="adhd_question",
            language_code=lang_code,
            personality=payload.character_personality,
            format_kwargs={"user_nick_nm": user_nick_nm}
        )

        # 공감 멘트가 있으면 질문 앞에 붙여줌
        final_question_text = f"{empathy_text} {question_text_template}".strip()

        # analysis_result의 intervention 내용을 ADHD 질문 형태로 *덮어쓰기*
        analysis_result["intervention"] = {
            "preset_id": PresetIds.ADHD_PRE_SOLUTION_QUESTION,
            "text": final_question_text,
            "options": [
                {"label": get_translation("label_adhd_has_task", lang_code), "action": "adhd_has_task"},
                {"label": get_translation("label_adhd_no_task", lang_code), "action": "adhd_no_task"}
            ],
            "adhd_context": { "step": "awaiting_choice" },
            "session_id": session_id # session_id는 유지
        }
        # top_cluster, empathy_text, analysis_text는 ADHD 질문 시나리오에서는 제거

    # --- 최종 결과 반환 ---
    return analysis_result


# ======================================================================
# ===          분석 엔드포인트         ===
# ======================================================================
 
@app.post("/analyze")
async def analyze_emotion(payload: AnalyzeRequest):
    """사용자의 텍스트와 아이콘을 받아 감정을 분석하고 스코어링 결과를 반환합니다."""
    text = (payload.text or "").strip()
    lang_code = payload.language_code if payload.language_code in translations else DEFAULT_LANG
    debug_log: Dict[str, Any] = {"input": payload.dict()}

    try:
        # --- 파이프라인 0: 유해 콘텐츠 검열 ---
        if await _handle_moderation(text, lang_code): 
            return JSONResponse(status_code=400, content={"error": get_translation("error_inappropriate_content", lang_code)})
       
        # --- ADHD Context Handling ---
        # ADHD 컨텍스트가 존재하면, 다른 모든 분석을 건너뛰고 ADHD 답변 처리 로직으로 바로 보냅니다.
        if payload.adhd_context and "step" in payload.adhd_context:
            return await _handle_adhd_response(payload, debug_log, lang_code)


        # --- 파이프라인 1: 🌸 CASE 2 - 이모지만 있는 경우 ---
        if payload.icon and not text:
            debug_log["mode"] = "EMOJI_REACTION"
            return await _handle_emoji_only_case(payload, debug_log, lang_code)

        # --- 파이프라인 2: 1차 안전 장치 (LLM 호출 전) ---
        is_crisis, crisis_scores = is_safety_text(text, None, debug_log)
        if is_crisis:
            print(get_translation("log_safety_triggered_1st", DEFAULT_LANG, text=text))
            g, profile, top_cluster = g_score(crisis_scores), 1, "neg_low"
            intervention = {
                "preset_id": PresetIds.SAFETY_CRISIS_MODAL,
                "analysis_text": get_translation("safety_crisis_text", lang_code), # 🥑 번역 사용
                "cluster": top_cluster,
                "solution_id": f"{top_cluster}_crisis_01"
            }
            session_id = await save_analysis_to_supabase(payload, profile, g, intervention, debug_log, crisis_scores, lang_code)
            intervention["session_id"] = session_id
            return {"session_id": session_id, "final_scores": crisis_scores, "g_score": g, "profile": profile, "intervention": intervention}
       
        # --- 파이프라인 3: Triage (친구 모드 / 분석 모드 분기) ---
        rule_scores, _, _ = rule_scoring(text)
        is_simple_text = len(text) < 10 and max(rule_scores.values() or [0.0]) < 0.1
        
        if is_simple_text:
            triage_mode = 'FRIENDLY'
            debug_log["triage_decision"] = "Rule-based: Simple text"
        else:
            triage_system_prompt = get_system_prompt(mode='TRIAGE', personality=None, language_code=lang_code)
            triage_mode = await call_llm(triage_system_prompt, text, OPENAI_KEY, lang_code=lang_code, expect_json=False)
            debug_log["triage_decision"] = f"LLM Triage: {triage_mode}"

        # --- 파이프라인 4: Triage 결과에 따른 분기 처리 ---
        if triage_mode == 'FRIENDLY':
            return await _handle_friendly_mode(payload, debug_log, lang_code)
        elif triage_mode == 'ANALYSIS':
            analysis_result = await _run_analysis_pipeline(payload, debug_log, lang_code)
            
            if not analysis_result or "error" in analysis_result:
                 # 에러 상황 처리 또는 기본 응답 반환 (예: 친구 모드 응답)
                 print(f"⚠️ Analysis pipeline failed or returned error. Result: {analysis_result}")
                 # 필요 시 에러 응답을 클라이언트에 전달하거나 기본 응답 반환
                 return await _handle_friendly_mode(payload, debug_log, lang_code) # 예시: 친구 모드로 대체

            # # --- ADHD 분기 로직 (이제 analysis_result 안에서 처리됨) ---
            # # _run_analysis_pipeline 함수 내부에서 ADHD 분기 처리가 완료되었으므로,
            # # 여기서는 analysis_result를 그대로 반환하면 됩니다.
            # intervention = analysis_result.get("intervention", {})
            # top_cluster = intervention.get("top_cluster")
            # empathy_text = intervention.get("empathy_text", "")
            # user_nick_nm, _ = await get_user_info(payload.user_id)
            
            
            # # 만약 분석 결과 top_cluster가 ADHD라면, 마음 관리 팁을 바로 제안하지 않고 질문을 던짐
            # if top_cluster == "adhd":
            #     print("🧠 ADHD cluster detected. Switching to pre-solution question flow.")
                
            #     question_text_template = await get_mention_from_db(
            #         mention_type="adhd_question", # Assuming key exists
            #         language_code=lang_code, # 🥑 Pass lang_code
            #         personality=payload.character_personality,
            #         format_kwargs={"user_nick_nm": user_nick_nm}
            #     )

            #     final_question_text = f"{empathy_text} {question_text_template}"

                
            #     # 프론트엔드로 질문과 다음 요청에 필요한 컨텍스트를 전달
            #     analysis_result["intervention"] = {
            #         "preset_id": PresetIds.ADHD_PRE_SOLUTION_QUESTION,
            #         "text": final_question_text.strip(), # 최종 조합된 텍스트
            #         "options": [
            #             {"label": "있어! 뭐부터 하면 좋을까?", "action": "adhd_has_task"},
            #             {"label": "없어! 집중력 훈련 할래", "action": "adhd_no_task"}
            #         ],
            #         "adhd_context": { "step": "awaiting_choice" }
            #     }

            return analysis_result
        
        else: # Handle unexpected triage result
            print(get_translation("log_warn_unexpected_triage", DEFAULT_LANG, mode=triage_mode))
            return await _handle_friendly_mode(payload, debug_log, lang_code)

    except Exception as e:
        tb = traceback.format_exc()
        job_name = "/analyze"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=tb))
        error_msg = get_translation("error_occurred", lang_code, error=str(e))
        raise HTTPException(status_code=500, detail={"error": error_msg, "trace": tb if os.getenv("DEBUG") else None})
    
# ======================================================================
# ===     심층 분석 (마음 점검) 결과 제출 엔드포인트     ===
# ======================================================================
@app.post("/assessment/submit")
async def submit_assessment(payload: AssessmentSubmitRequest):
    lang_code = payload.language_code if payload.language_code in translations else DEFAULT_LANG
    if not supabase: raise HTTPException(status_code=500, detail=get_translation("error_supabase_init", lang_code))
    try:
        total_score = sum(payload.responses.values())
        max_score = DEEP_DIVE_MAX_SCORES.get(payload.cluster)
        if not max_score: raise HTTPException(status_code=400, detail=get_translation("error_invalid_cluster", lang_code, cluster=payload.cluster))

        normalized_score = clip01(total_score / max_score)
        
        profile_res = await run_in_threadpool(supabase.table("user_profiles").select("latest_assessment_scores").eq("id", payload.user_id).single().execute)
        latest_scores = (profile_res.data or {}).get("latest_assessment_scores", {})
        if not isinstance(latest_scores, dict): latest_scores = {}
        
        latest_scores[payload.cluster] = normalized_score
        
        await run_in_threadpool(supabase.table("user_profiles").update({"latest_assessment_scores": latest_scores}).eq("id", payload.user_id).execute)
        
        history_row = {"user_id": payload.user_id, "assessment_type": f"deep_dive_{payload.cluster}", "scores": {payload.cluster: normalized_score}, "raw_responses": payload.responses}
        await run_in_threadpool(supabase.table("assessment_history").insert(history_row).execute)
        
        return {"message": get_translation("assessment_success", lang_code), "updated_scores": latest_scores}
    
    except Exception as e:
        tb = traceback.format_exc()
        job_name = "/assessment/submit"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=tb))
        raise HTTPException(status_code=500, detail={"error": get_translation("error_occurred", lang_code, error=str(e)), "trace": tb if os.getenv("DEBUG") else None})


# ======================================================================
# ===          마음 관리 팁 제안 및 상세 정보 엔드포인트         ===
# ======================================================================
   

@app.post("/solutions/propose")
async def propose_solution(payload: SolutionRequest): 
    """
    분석 결과(top_cluster)에 맞는 클러스터별로 제안할 마음 관리 팁 타입 목록을 명확히 정의하고, 해당 타입의 마음 관리 팁만 찾아 
    사용자가 선택할 수 있는 옵션 목록과, 대표 제안 텍스트를 함께 반환합니다.
    neg_low, sleep: 호흡, 영상, 행동미션
    neg_high, positive: 호흡, 영상만
    adhd는 할거 있냐없냐 물어보고 있으면 뽀모도로, 없으면 호흡, 영상
    """    
    lang_code = payload.language_code if payload.language_code in translations else DEFAULT_LANG

    if not supabase: raise HTTPException(status_code=500, detail=get_translation("error_supabase_init", lang_code))

    try:
        user_nick_nm, _ = await get_user_info(payload.user_id, lang_code)
        top_cluster = payload.top_cluster

         # 0. 클러스터별로 제안할 마음 관리 팁 타입 목록을 정의해야함
        solution_types_by_cluster = {
            "neg_low": ["breathing", "video", "action"],
            "sleep": ["breathing", "video", "action"],
            "neg_high": ["breathing", "video"],
            "positive": ["breathing", "video"],
            # ADHD는 별도 흐름을 타므로 여기서는 기본값만 정의
            "adhd": ["breathing", "video"] 
        }
        
        # 현재 top_cluster에 해당하는 마음 관리 팁 타입 목록 가져오기
        target_solution_types = solution_types_by_cluster.get(top_cluster, ["video"])


        # 1. 사용자의 거부 태그 목록 가져오기
        profile_res = await run_in_threadpool(
            supabase.table("user_profiles")
            .select("negative_tags")
            .eq("id", payload.user_id)
            .single().execute
        )
        negative_tags = (profile_res.data or {}).get("negative_tags", [])

        # 2. 제안할 후보 마음 관리 팁 전체를 DB에서 가져오기
        all_candidates_res = await run_in_threadpool(
            supabase.table("solutions")
            .select("*")
            .eq("cluster", top_cluster)
            .execute
        )
        all_candidates = all_candidates_res.data
        
        if not all_candidates:
            return {"proposal_text": get_translation("no_solution_proposal", lang_code), "options": []}

        # # 3. 거부 태그가 포함된 마음 관리 팁은 후보에서 제외
        # if negative_tags:
        #     filtered_candidates = [
        #         sol for sol in all_candidates
        #         if not any(tag in (sol.get("tags") or []) for tag in negative_tags)
        #     ]
        # else:
        #     filtered_candidates = all_candidates

        # 3. 확률 기반으로 마음 관리 팁 필터링(1/3 확률로 나오도록!)
        probabilistically_filtered_candidates = []
        if negative_tags:
            for sol in all_candidates:
                solution_tags = set(sol.get("tags") or [])
                # 겹치는 태그가 있는지 확인
                if not solution_tags.isdisjoint(negative_tags):
                    # 겹치는 태그가 있다면, 1/3 확률로만 목록에 추가
                    if random.random() < (1/3):
                        probabilistically_filtered_candidates.append(sol)
                else:
                    # 겹치는 태그가 없다면, 무조건 목록에 추가
                    probabilistically_filtered_candidates.append(sol)
        else:
            # negative_tags가 없으면 모든 후보를 그대로 사용
            probabilistically_filtered_candidates = all_candidates
        
        # 필터링 후 후보군이 없으면 모든 후보를 다시 사용 (안전장치)
        if not probabilistically_filtered_candidates:
            probabilistically_filtered_candidates = all_candidates


        # 4. 각 마음 관리 팁 타입별로 대표 마음 관리 팁을 하나씩 랜덤 선택
        options = []
        labels = {
            "breathing": get_translation("label_breathing", lang_code),
            "video": get_translation("label_video", lang_code),
            "action": get_translation("label_mission", lang_code)
        }
        default_label = get_translation("label_tip", lang_code)

        # 텍스트 조합을 위해 첫 번째 마음 관리 팁의 설명을 저장할 변수
        first_solution_text = ""

        for sol_type in target_solution_types:

            # 'breathing' 타입은 DB 조회 없이 고정된 옵션을 추가합니다.
            if sol_type == 'breathing':
                options.append({
                    "label": labels.get(sol_type),
                    "action": "accept_solution",
                    "solution_id": "breathing_default",
                    "solution_type": "breathing"
                })
                continue

            # 'sleep' 클러스터의 'action' 타입은 수면위생 팁으로 연결합니다.
            elif top_cluster == 'sleep' and sol_type == 'action':
                options.append({
                    "label": labels.get(sol_type), 
                    "action": "accept_solution",
                    "solution_id": "sleep_hygiene_tip_random",
                    "solution_type": "action"
                })
                continue
            
            # 그 외 모든 경우는 DB에서 마음 관리 팁을 찾습니다.
            type_candidates = [s for s in probabilistically_filtered_candidates if s.get("solution_type") == sol_type]
            if type_candidates:
                chosen_solution = random.choice(type_candidates)
                
                # 4-1. 프론트엔드에 전달할 버튼 옵션 목록
                options.append({
                    "label": labels.get(sol_type, default_label),
                    "action": "accept_solution",
                    "solution_id": chosen_solution["solution_id"],
                    "solution_type": chosen_solution["solution_type"]
                })

                # 4-2. 첫 번째로 선택된 마음 관리 팁의 설명 텍스트 저장 
                if not first_solution_text:
                    first_solution_text = chosen_solution.get("text", "")

        if not options:
            return {"proposal_text": get_translation("no_solution_proposal_talk", lang_code), "options": []}
        
        # 5. 제안 멘트와 대표 마음 관리 팁 설명을 조합하여 최종 제안 텍스트 생성
        proposal_script = await get_mention_from_db(
            mention_type="propose",
            language_code=lang_code,
            cluster=top_cluster,
            format_kwargs={"user_nick_nm": user_nick_nm}
        )
        final_text = f"{proposal_script} {first_solution_text}".strip()
      
        # 6. 로그 저장 및 최종 결과 반환
        log_entry = {
            "session_id": payload.session_id, 
            "type": "propose", 
            "solution_id": f"multiple_options_{top_cluster}"
        }
        await run_in_threadpool(supabase.table("interventions_log").insert(log_entry).execute)

        return {"proposal_text": final_text, "options": options}

    except Exception as e:
        tb = traceback.format_exc()
        job_name = "/solutions/propose"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=tb))
        raise HTTPException(status_code=500, detail={"error": get_translation("error_occurred", lang_code, error=str(e)), "trace": tb if os.getenv("DEBUG") else None})
    
# ======================================================================
# ===          마음 관리 팁 영상 엔드포인트         ===
# ======================================================================

    # SolutionPage에서 영상 로드
    # 하드코딩된 SOLUTION_DETAILS_LIBRARY를 DB 조회로 대체했음!!
@app.get("/solutions/{solution_id}")
async def get_solution_details(solution_id: str, language_code: Optional[str] = 'ko'): 
    lang_code = language_code if language_code in translations else DEFAULT_LANG
    print(f"RIN: ✅ 마음 관리 팁 상세 정보 요청 받음: {solution_id}")
    
    if not supabase:
        raise HTTPException(status_code=500, detail=get_translation("error_supabase_init", lang_code))    
    try:
        # solutions 테이블에서 필요한 데이터를 조회
        response = await run_in_threadpool(
            supabase.table("solutions")
            .select("url, start_at, end_at, text") 
            .eq("solution_id", solution_id)
            .single()
            .execute
        )
        
        
        if not response.data:
            raise HTTPException(status_code=404, detail=get_translation("error_solution_not_found", lang_code))

        # 유튜브 불러올때 startAt, endAt (camelCase)를 기대하므로 키를 변환해줌
        # supabase는 snake_case로 저장해야 한다고 함.
        return {
            'url': response.data.get('url'), 
            'startAt': response.data.get('start_at'), 
            'endAt': response.data.get('end_at'),
            'text': response.data.get('text')
            }
        
    except Exception as e:
        print(get_translation("log_error_solution_not_found", DEFAULT_LANG, solution_id=solution_id, error=str(e)))
        raise HTTPException(status_code=404, detail=get_translation("error_solution_not_found", lang_code))
    

# ======================================================================
# ===          상황별 대사 제공 엔드포인트 (`/dialogue/*`)         ===
# ======================================================================
@app.get("/dialogue/home")
async def get_home_dialogue(
    personality: Optional[str] = None, 
    user_nick_nm: Optional[str] = None,
    language_code: Optional[str] = 'ko',
    emotion: Optional[str] = None 
):
    """홈 화면에 표시할 대사를 반환합니다."""
    lang_code = language_code if language_code in translations else DEFAULT_LANG
    user_name_to_use = user_nick_nm or get_translation("default_user_name", lang_code)

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
        language_code=lang_code,
        personality=personality,
        cluster=cluster,
        format_kwargs={"user_nick_nm": user_name_to_use}
    )
    
    return {"dialogue": dialogue_text}
    
#  마음 관리 팁 완료 후 후속 질문을 위한 엔드포인트  
@app.get("/dialogue/solution-followup")
async def get_solution_followup_dialogue(
    reason: str, # 'user_closed' 또는 'video_ended'
    personality: Optional[str] = None, 
    user_nick_nm: Optional[str] = None,
    language_code: Optional[str] = 'ko'
):
    """마음 관리 팁이 끝난 후의 상황(reason)과 캐릭터 성향에 맞는 후속 질문을 반환합니다."""
    
    lang_code = language_code if language_code in translations else DEFAULT_LANG
    user_name_to_use = user_nick_nm or get_translation("default_user_name", lang_code)

    # 이유(reason)에 따라 DB에서 조회할 mention_type을 결정합니다.
    if reason == 'user_closed':
        mention_type = "followup_user_closed"
    else: # 'video_ended' 또는 기타
        mention_type = "followup_video_ended"

    # get_mention_from_db 헬퍼 함수를 사용하여 멘트를 가져옵니다.
    dialogue_text = await get_mention_from_db(
        mention_type=mention_type,
        personality=personality,
        language_code=lang_code,
        cluster="common", 
        format_kwargs={"user_nick_nm": user_name_to_use}
    )
    
    return {"dialogue": dialogue_text}


# 마음 관리 팁 제안을 거절했을 때의 멘트를 성향별로 주기 
@app.get("/dialogue/decline-solution")
async def get_decline_solution_dialogue(
    personality: Optional[str] = None, 
    user_nick_nm: Optional[str] = None,
    language_code: Optional[str] = 'ko'
):
    """마음 관리 팁 제안을 거절하고 대화를 이어가고 싶어할 때의 반응 멘트를 반환합니다."""
    
    lang_code = language_code if language_code in translations else DEFAULT_LANG
    user_name_to_use = user_nick_nm or get_translation("default_user_name", lang_code)
    
    dialogue_text = await get_mention_from_db(
        mention_type="decline_solution",
        personality=personality,
        language_code=lang_code,
        cluster="common",
        format_kwargs={"user_nick_nm": user_name_to_use}
    )
    
    return {"dialogue": dialogue_text}

# ======================================================================
# ===     리포트 요약 엔드포인트     ===
# ======================================================================



async def create_and_save_summary_for_user(user_id: str, date_str: str, lang_code: str = 'ko'): 
    """
    그날의 '최고점 감정'과 '가장 힘들었던 순간의 감정'을 모두 찾아 LLM에 전달하여 요약을 생성합니다.
    이 함수는 스케줄링된 작업(/tasks/generate-summaries)에 의해 호출됩니다.
    """
    print(get_translation("log_daily_summary_start", DEFAULT_LANG, user_id=user_id, date_str=date_str))
    
    # Supabase 또는 OpenAI 키가 설정되지 않은 경우 작업을 건너뜁니다.
    if not supabase or not OPENAI_KEY:
        print(get_translation("log_error_keys_not_set", DEFAULT_LANG))
        return

    try:
        start_of_day = f"{date_str}T00:00:00+00:00"
        end_of_day = f"{date_str}T23:59:59+00:00"

        # --- 1. '그날 가장 높았던 단일 감정' 찾기 (기준점 1) ---
        top_score_query = supabase.table("cluster_scores") \
            .select("cluster, score, sessions(summary)") \
            .eq("user_id", user_id) \
            .gte("created_at", start_of_day) \
            .lte("created_at", end_of_day) \
            .order("score", desc=True) \
            .limit(1)
        top_score_res = await run_in_threadpool(top_score_query.execute)

        if not top_score_res.data:
            print(get_translation("log_daily_summary_no_scores", DEFAULT_LANG, user_id=user_id, date_str=date_str))
            return

        top_score_entry = top_score_res.data[0]
        headline_cluster = top_score_entry['cluster']
        headline_score = int(top_score_entry['score'] * 100)
        headline_summary = (top_score_entry.get('sessions') or {}).get('summary', get_translation("placeholder_no_dialogue", lang_code)) 

        # --- 2. '가장 힘들었던 순간(g_score 최고점)의 감정' 찾기 (기준점 2) ---
        top_g_score_session_query = supabase.table("sessions") \
            .select("id, summary, g_score, cluster_scores(cluster, score)") \
            .eq("user_id", user_id) \
            .gte("created_at", start_of_day) \
            .lte("created_at", end_of_day) \
            .order("g_score", desc=True) \
            .limit(1)
        top_g_score_res = await run_in_threadpool(top_g_score_session_query.execute)
        
        difficult_moment_context = None
        if top_g_score_res.data:
            top_g_score_session = top_g_score_res.data[0]
            if top_g_score_session.get('cluster_scores'):
                # 해당 세션 내에서 가장 높았던 클러스터 찾기
                top_cluster_in_g_session = max(top_g_score_session['cluster_scores'], key=lambda x: x['score'])
                
                # '최고점 감정'과 '가장 힘들었던 순간의 감정'이 다를 경우에만 추가 정보 구성
                if top_cluster_in_g_session['cluster'] != headline_cluster:
                    cluster_name_display = get_translation(f"cluster_{top_cluster_in_g_session['cluster']}", lang_code)
                    difficult_moment_context = {
                    "cluster_name": cluster_name_display,
                    "score": int(top_cluster_in_g_session['score'] * 100),
                    "reason": get_translation("reason_difficult_moment", lang_code)
                    }

        # --- 3. LLM에 전달할 정보 구성 ---
        user_nick_nm, _ = await get_user_info(user_id, lang_code)
        llm_context = {
            "user_nick_nm": user_nick_nm,
            "headline_emotion": {
                "cluster_name": get_translation(f"cluster_{headline_cluster}", lang_code),
                "score": headline_score,
                "dialogue_summary": headline_summary
            },
            "difficult_moment": difficult_moment_context
        }
        
        recent_summaries_query = supabase.table("daily_summaries").select("summary_text").eq("user_id", user_id).order("date", desc=True).limit(5)
        recent_summaries_res = await run_in_threadpool(recent_summaries_query.execute)
        llm_context["previous_summaries"] = [s['summary_text'] for s in recent_summaries_res.data]

        # --- LLM 호출하여 요약문 생성 ---
        summary_json = await call_llm(
            system_prompt=REPORT_SUMMARY_PROMPT,
            user_content=json.dumps(llm_context, ensure_ascii=False),
            openai_key=OPENAI_KEY,
            lang_code=lang_code
        )
        
        daily_summary_text = summary_json.get("daily_summary")
        if not daily_summary_text:
            print(get_translation("log_daily_summary_llm_fail", DEFAULT_LANG, user_id=user_id, date_str=date_str))
            return


        # --- 8. 생성된 요약문을 `daily_summaries` 테이블에 저장 (Upsert) ---
        summary_data = {
            "user_id": user_id,
            "date": date_str,
            "summary_text": daily_summary_text,
            "top_cluster": headline_cluster,
            "top_score": headline_score 
        }
        await run_in_threadpool(supabase.table("daily_summaries").upsert(summary_data, on_conflict="user_id,date").execute)

        print(get_translation("log_daily_summary_success", DEFAULT_LANG, user_id=user_id, date_str=date_str))
    

    except Exception as e:
        job_name = "create_and_save_summary_for_user"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=traceback.format_exc()))
    finally:
        print(get_translation("log_daily_summary_end", DEFAULT_LANG, user_id=user_id, date_str=date_str))


# 2주 차트 요약 생성 함수
async def create_and_save_weekly_summary_for_user(user_id: str, date_str: str, lang_code: str = 'ko'):
    print(get_translation("log_weekly_summary_start", DEFAULT_LANG, user_id=user_id, date_str=date_str))
    if not supabase or not OPENAI_KEY:
        print(get_translation("log_error_keys_not_set", DEFAULT_LANG))
        return
    
    try:
        # 오늘 날짜를 datetime 객체로 변환하여 요일 확인
        today_dt = dt.datetime.strptime(date_str, '%Y-%m-%d')
        # (월요일=0, 화요일=1, ..., 일요일=6)
        is_sunday = today_dt.weekday() == 6

        # 요일에 따라 다른 프롬프트 선택
        if is_sunday:
            system_prompt = WEEKLY_REPORT_SUMMARY_PROMPT_NEURO
            print(get_translation("log_weekly_summary_sunday", DEFAULT_LANG))
        else:
            system_prompt = WEEKLY_REPORT_SUMMARY_PROMPT_STANDARD
            print(get_translation("log_weekly_summary_standard", DEFAULT_LANG))
            
        today = dt.datetime.strptime(date_str, '%Y-%m-%d').replace(tzinfo=dt.timezone.utc)
        start_date = today - dt.timedelta(days=13)
        end_date = today + dt.timedelta(days=1)

        # 14일간의 세션 및 클러스터 점수 데이터 한 번에 가져오기
        sessions_res = supabase.table("sessions").select("id, created_at, g_score").eq("user_id", user_id).gte("created_at", start_date.isoformat()).lt("created_at", end_date.isoformat()).execute()
        if not sessions_res.data:
            print(get_translation("log_weekly_summary_no_session", DEFAULT_LANG, user_id=user_id))
            return # 데이터 없으면 바로 종료
        
        # 기록이 있는 날짜 수 계산
        recorded_days = set()
        for session in sessions_res.data:
            try:
                # 타임존 정보 제거하고 날짜만 추출
                day_str = dt.datetime.fromisoformat(session['created_at'].split('+')[0]).strftime('%Y-%m-%d')
                recorded_days.add(day_str)
            except Exception as e:
                print(get_translation("log_weekly_summary_parse_error", DEFAULT_LANG, user_id=user_id, date_str=session['created_at'], error=str(e)))
                continue # 날짜 파싱 실패 시 해당 세션 건너뛰기

        MIN_DAYS_REQUIRED = 3 # 최소 필요 일수
        if len(recorded_days) < MIN_DAYS_REQUIRED:
            print(get_translation("log_weekly_summary_insufficient_data", DEFAULT_LANG, days_found=len(recorded_days), days_required=MIN_DAYS_REQUIRED, user_id=user_id))
            # 데이터 부족 시, DB에 placeholder 저장하지 않고 그냥 종료
            return
        # [수정 끝] 데이터가 충분할 때만 아래 로직 실행



        
        session_ids = [s['id'] for s in sessions_res.data]
        scores_res = supabase.table("cluster_scores").select("session_id, created_at, cluster, score").in_("session_id", session_ids).execute()
        
        sessions_with_scores = []
        scores_by_session_id = {sid: [] for sid in session_ids}
        for score in scores_res.data:
            scores_by_session_id.setdefault(score['session_id'], []).append(score)

        for session in sessions_res.data:
            session['cluster_scores'] = scores_by_session_id.get(session['id'], [])
            sessions_with_scores.append(session)

        if not sessions_with_scores:
            print(get_translation("log_weekly_summary_no_session", DEFAULT_LANG, user_id=user_id))
            return


 # --- 데이터 가공: 트렌드 분석 로직 시작 ---

        # 1. 일별 데이터 구조화
        daily_data = {}
        # 14일간의 모든 날짜 키를 미리 생성
        for i in range(14):
            day_key = (start_date + dt.timedelta(days=i)).strftime('%Y-%m-%d')
            daily_data[day_key] = {'g_scores': [], 'clusters': {c: [] for c in CLUSTERS}}
        for session in sessions_with_scores:
            created_at_str = session['created_at'].split('+')[0]
            try: day = dt.datetime.strptime(created_at_str, "%Y-%m-%dT%H:%M:%S.%f").strftime('%Y-%m-%d')
            except ValueError: day = dt.datetime.strptime(created_at_str, "%Y-%m-%dT%H:%M:%S").strftime('%Y-%m-%d')
            if day in daily_data:
                if session['g_score'] is not None: daily_data[day]['g_scores'].append(session['g_score'])
                for score_data in session.get('cluster_scores', []):
                    if score_data['cluster'] in daily_data[day]['clusters']: daily_data[day]['clusters'][score_data['cluster']].append(score_data['score'])
       
        # 2. 통계 지표 계산
        g_scores = [np.mean(day['g_scores']) for day in daily_data.values() if day['g_scores']]
        
        cluster_stats = {}
        all_scores = []
        for c in CLUSTERS:
            # 하루에 여러 기록이 있으면 평균을 내어 그날의 대표 점수로 사용
            daily_avgs = [np.mean(day['clusters'][c]) for day in daily_data.values() if day['clusters'][c]]
            
            if not daily_avgs: cluster_stats[c] = {"avg": 0, "std": 0, "trend": "stable"}; continue
            all_scores.extend([(c, s) for s in daily_avgs])
           
            # 추세 분석 (간단한 기울기 계산)
            x = np.arange(len(daily_avgs)); slope = np.polyfit(x, daily_avgs, 1)[0] if len(daily_avgs) > 1 else 0
            # 하루 평균 5점씩 점수가 상승/하락 하는 추세일 때 통계적으로 의미있는 변화로 침
            trend = "increasing" if slope > 0.05 else "decreasing" if slope < -0.05 else "stable"

            cluster_stats[c] = {
                "avg": int(np.mean(daily_avgs) * 100), 
                "std": int(np.std(daily_avgs) * 100), 
                "trend": trend
                }

        # 3. 주요 클러스터 및 상관관계 분석

        # 상관관계 분석 로직 (모든 클러스터 대상)
        correlations = []
            #  "해당 클러스터의 2주 평균 점수가 '낮음' 수준을 넘어, '중간' 수준 이상으로 꾸준히 나타났다"
        
        # [긍정적 상관관계: A가 높을 때 B도 높음]
        if cluster_stats['sleep']['avg'] > 40 and cluster_stats['neg_low']['avg'] > 40:
            correlations.append(get_translation("corr_sleep_neglow", lang_code))
        if cluster_stats['neg_high']['avg'] > 40 and cluster_stats['sleep']['avg'] > 40:
            correlations.append(get_translation("corr_neghigh_sleep", lang_code))
        if cluster_stats['adhd']['avg'] > 50 and cluster_stats['neg_high']['avg'] > 50:
            correlations.append(get_translation("corr_adhd_neghigh", lang_code))

        # [부정적/반비례 상관관계: A가 높을 때 B는 낮음]
        if cluster_stats['neg_low']['avg'] > 50 and cluster_stats['positive']['avg'] < 30:
            correlations.append(get_translation("corr_neglow_positive", lang_code))
        if cluster_stats['neg_high']['avg'] > 50 and cluster_stats['positive']['avg'] < 30:
            correlations.append(get_translation("corr_neghigh_positive", lang_code))

        # [추세 기반 반비례 상관관계: A가 개선될 때 B도 개선됨]
        if cluster_stats['sleep']['trend'] == 'decreasing' and cluster_stats['neg_low']['trend'] == 'decreasing':
            correlations.append(get_translation("corr_trend_sleep_neglow", lang_code))
        if cluster_stats['neg_low']['trend'] == 'decreasing' and cluster_stats['positive']['trend'] == 'increasing':
            correlations.append(get_translation("corr_trend_neglow_positive", lang_code))

        # 4. 주요 클러스터 식별
        # 지난 2주간 발생한 모든 감정 기록 중에서, 점수가 가장 높았던 순간 Top 2를 찾아내라
        dominant_clusters_keys = list(set([item[0] for item in sorted(all_scores, key=lambda item: item[1], reverse=True)[:2]]))        
        # 클러스터 이름 변환
        dominant_clusters_display = [get_translation(f"cluster_{c}", lang_code) for c in dominant_clusters_keys]
        # 최종 LLM 전달 데이터 구조
        trend_data = {
            "g_score_stats": {"avg": int(np.mean(g_scores)*100) if g_scores else 0, 
                              "std": int(np.std(g_scores)*100) if g_scores else 0}, 
            "cluster_stats": cluster_stats, 
            "dominant_clusters": dominant_clusters_display,
            "correlations": correlations
            }

        # 5. LLM 호출 및 결과 저장
        # 분석한 트렌드 llm에 넣기
        user_nick_nm, _ = await get_user_info(user_id, lang_code)
        llm_context = { "user_nick_nm": user_nick_nm, "trend_data": trend_data }
        summary_json = await call_llm(system_prompt, json.dumps(llm_context, ensure_ascii=False), OPENAI_KEY, lang_code=lang_code)

        if not summary_json or "error" in summary_json:
            print(get_translation("log_weekly_summary_llm_fail", DEFAULT_LANG, user_id=user_id))
            return
            
        summary_data = { "user_id": user_id, "summary_date": date_str, **summary_json }
        await run_in_threadpool(supabase.table("weekly_summaries").upsert(summary_data, on_conflict="user_id,summary_date").execute)
        print(get_translation("log_weekly_summary_success", DEFAULT_LANG, user_id=user_id, date_str=date_str))
    except Exception as e:
        job_name = "create_and_save_weekly_summary_for_user"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=traceback.format_exc()))



#  ------- daily_summaries 테이블에서 요약문 간단히 조회 ---------
# 모지 달력에서 특정 날짜를 탭했을 때, 해당 날짜의 '일일 요약문' 하나만 빠르게 가져오는 역할
@app.post("/report/summary")
async def get_daily_report_summary(request: DailyReportRequest):
    """미리 생성된 일일 요약문을 DB에서 조회합니다."""
    lang_code = request.language_code if request.language_code in translations else DEFAULT_LANG

    if not supabase:
        raise HTTPException(status_code=500, detail=get_translation("error_supabase_init", lang_code))

    try:
        query = supabase.table("daily_summaries").select("summary_text").eq("user_id", request.user_id).eq("date", request.date).limit(1)
        response = await run_in_threadpool(query.execute)

        if response.data:
            summary = response.data[0].get("summary_text", get_translation("summary_not_found", lang_code))
            return {"summary": summary}
        else:
            return {"summary": get_translation("placeholder_summary_no_data", lang_code)}

    except Exception as e:
        job_name = "/report/summary"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=traceback.format_exc()))
        raise HTTPException(status_code=500, detail=get_translation("error_loading_summary", lang_code))
    

# --- 2주 차트 요약문을 프론트엔드에 제공하는 API 엔드포인트 ---
# 모지 차트 페이지에 들어갔을 때, '2주 분석 리포트' 전체(종합, 클러스터별)를 가져오는 역할


@app.post("/report/weekly-summary")
async def get_weekly_report_summary(request: WeeklyReportRequest):
    lang_code = request.language_code if request.language_code in translations else DEFAULT_LANG
    if not supabase: raise HTTPException(500, get_translation("error_supabase_init", lang_code))

    # 기본 플레이스홀더 메시지 정의
    placeholder_no_data = get_translation("placeholder_weekly_summary_no_data", lang_code)
    placeholder_error = get_translation("placeholder_weekly_summary_error", lang_code)

    try:
        # Supabase 쿼리 객체 생성
        query = (
            supabase.table("weekly_summaries")
            .select("*")
            .eq("user_id", request.user_id)
            .order("summary_date", desc=True)
            .limit(1)
            .maybe_single()
        )

        # query 객체의 execute 메서드 자체를 전달 (괄호 없음!)
        response = await run_in_threadpool(query.execute)

        # response.data가 None이 아니고, 내용이 실제로 있는지 확인
        if response and response.data and response.data.get("overall_summary"):
            print(f"✅ Found weekly summary for user {request.user_id}")
            return response.data
        else:
            print(f"⚠️ No weekly summary data found for user {request.user_id}. Returning placeholder.")
            return {
                "overall_summary": placeholder_no_data,
                "neg_low_summary": placeholder_no_data,
                "neg_high_summary": placeholder_no_data,
                "adhd_summary": placeholder_no_data,
                "sleep_summary": placeholder_no_data,
                "positive_summary": placeholder_no_data
            }
    except Exception as e:
        job_name = "/report/weekly-summary"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=traceback.format_exc()))
        return {
            "overall_summary": placeholder_error,
            "neg_low_summary": placeholder_error,
            "neg_high_summary": placeholder_error,
            "adhd_summary": placeholder_error,
            "sleep_summary": placeholder_error,
            "positive_summary": placeholder_error
        }
    
# ======================================================================
# ===     백그라운드 스케줄링 작업용 엔드포인트     ===
# ======================================================================

@app.post("/tasks/generate-summaries")
async def handle_generate_summaries_task(language_code: Optional[str] = 'ko'): 
    """
    Supabase Cron Job에 의해 호출될 엔드포인트.
    어제 활동한 모든 사용자의 일일 요약을 생성합니다.
    """
    lang_code = language_code if language_code in translations else DEFAULT_LANG
    
    # 어제 날짜 계산 (UTC 기준)
    yesterday = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=1)
    yesterday_str = yesterday.strftime('%Y-%m-%d')
    
    start_of_yesterday = f"{yesterday_str}T00:00:00+00:00"
    end_of_yesterday = f"{yesterday_str}T23:59:59+00:00"

    print(get_translation("log_task_start", DEFAULT_LANG, job_name="Daily/Weekly Summaries", date_str=yesterday_str))

    # 어제 활동한 유저 ID 목록 가져오기 (중복 제거)
    active_users_query = supabase.table("sessions").select("user_id", count='exact') \
        .gte("created_at", start_of_yesterday) \
        .lte("created_at", end_of_yesterday)
    
    active_users_res = await run_in_threadpool(active_users_query.execute)
    # 어제 앱을 사용한 유저가 단 한 명도 없다면, 즉시 "어제 활동한 유저 없음" 메시지를 출력하고 작업을 종료
    if not active_users_res.data:
        message = get_translation("log_task_no_active_users", DEFAULT_LANG)
        print(message)
        return {"message": message}

    # 활동 유저가 있을 때만 아래 로직 실행
    user_ids = list(set([item['user_id'] for item in active_users_res.data]))
    
    print(get_translation("log_task_found_users", DEFAULT_LANG, user_count=len(user_ids)))

    # 각 유저에 대해 순차적으로 요약 생성 함수 호출
    profiles_res = await run_in_threadpool(supabase.table("user_profiles").select("id, language_code").in_("id", user_ids).execute)
    user_lang_map = {p['id']: p.get('language_code', DEFAULT_LANG) for p in profiles_res.data}

    for user_id in user_ids:
        user_lang = user_lang_map.get(user_id, DEFAULT_LANG) # 🥑 해당 유저의 언어 설정 사용
        await create_and_save_summary_for_user(user_id, yesterday_str, user_lang)
        await create_and_save_weekly_summary_for_user(user_id, yesterday_str, user_lang)

    message = get_translation("log_task_complete", DEFAULT_LANG, user_count=len(user_ids))
    print(message)
    return {"message": message}


# ======================================================================
# ===     심층 분석 결과 제출 엔드포인트     ===
# ======================================================================

@app.post("/assessment/submit")
async def submit_assessment(payload: AssessmentSubmitRequest):
    """주기적 심층 분석 결과를 받아 DB에 저장하고, 사용자의 최신 상태를 업데이트합니다."""
    lang_code = payload.language_code if payload.language_code in translations else DEFAULT_LANG

    if not supabase:
        raise HTTPException(status_code=500, detail=get_translation("error_supabase_init", lang_code))

    try:
        # 1. 제출된 답변으로 점수 계산 및 정규화
        total_score = sum(payload.responses.values())
        max_score = DEEP_DIVE_MAX_SCORES.get(payload.cluster)
        if not max_score:
            raise HTTPException(status_code=400, detail=get_translation("error_invalid_cluster", lang_code, cluster=payload.cluster))
        
        normalized_score = clip01(total_score / max_score)

        # 2. user_profiles 테이블에서 현재 최신 점수 불러오기
        profile_res = await run_in_threadpool(
            supabase.table("user_profiles")
            .select("latest_assessment_scores")
            .eq("id", payload.user_id).single().execute
        )
        
        latest_scores = (profile_res.data or {}).get("latest_assessment_scores", {})
        if not isinstance(latest_scores, dict): latest_scores = {}


        # 3. 이번에 평가한 클러스터 점수만 업데이트
        latest_scores[payload.cluster] = normalized_score
        
        # 4. 업데이트된 점수를 다시 user_profiles 테이블에 저장
        update_res = await run_in_threadpool(
            supabase.table("user_profiles")
            .update({"latest_assessment_scores": latest_scores})
            .eq("id", payload.user_id).execute
        )

        # assessment_history 테이블에 원본 기록 저장 (추후 상세 분석용)
        history_row = {
            "user_id": payload.user_id,
            "assessment_type": f"deep_dive_{payload.cluster}",
            "scores": {payload.cluster: normalized_score},
            "raw_responses": payload.responses,
        }
        await run_in_threadpool(supabase.table("assessment_history").insert(history_row).execute)

        return {"message": get_translation("assessment_success", lang_code), "updated_scores": latest_scores}

    except Exception as e:
        tb = traceback.format_exc()
        job_name = "/assessment/submit"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=tb))
        raise HTTPException(status_code=500, detail={"error": get_translation("error_occurred", lang_code, error=str(e)), "trace": tb if os.getenv("DEBUG") else None})    


# ======================================================================
# ===     수면위생 팁 제공 엔드포인트     ===
# ======================================================================

@app.get("/dialogue/sleep-tip")
async def get_sleep_tip(
    personality: Optional[str] = None,
    user_nick_nm: Optional[str] = None,
    language_code: Optional[str] = 'ko'
):
    # get_mention_from_db 대신 직접 쿼리 (별도 테이블이므로)
    lang_code = language_code if language_code in translations else DEFAULT_LANG
    user_name_to_use = user_nick_nm or get_translation("default_user_name", lang_code)
    default_tip = get_translation("default_sleep_tip", lang_code)

    """캐릭터 성향에 맞는 수면위생 팁을 랜덤으로 하나 반환합니다."""
    if not supabase:
        return {"tip": default_tip}
    try:
        query = supabase.table("sleep_hygiene_tips").select("text").eq("language_code", lang_code)
        if personality:
            query = query.eq("personality", personality)
        
        # SQL의 ORDER BY random() LIMIT 1과 유사한 효과
        response = await run_in_threadpool(query.execute)
        tips = [row['text'] for row in response.data]
        
        if not tips:
            # 해당 성격의 팁이 없으면 기본 팁 반환
            fallback_res = await run_in_threadpool(supabase.table("sleep_hygiene_tips").select("text").eq("language_code", lang_code).eq("personality", "prob_solver").execute)
            tips = [row['text'] for row in fallback_res.data]

        selected_tip = random.choice(tips) if tips else default_tip

        try:
            return {"tip": selected_tip.format(user_nick_nm=user_name_to_use)}
        except KeyError:
            return {"tip": selected_tip.replace("{user_nick_nm}", user_name_to_use)}
        
    except Exception as e:
        print(get_translation("log_error_get_sleep_tip", DEFAULT_LANG, error=str(e)))
        return {"tip": default_tip}


# ======================================================================
# ===     행동 활성화 미션 제공 엔드포인트     ===
# ======================================================================

@app.get("/dialogue/action-mission")
async def get_action_mission(
    personality: Optional[str] = None,
    user_nick_nm: Optional[str] = None,
    language_code: Optional[str] = 'ko'
):
    """우울(neg_low) 클러스터를 위한 행동 미션을 랜덤으로 하나 반환합니다."""

    lang_code = language_code if language_code in translations else DEFAULT_LANG
    user_name_to_use = user_nick_nm or get_translation("default_user_name", lang_code)
    default_mission = get_translation("default_action_mission", lang_code)

    if not supabase:
        return {"mission": default_mission}
    try:
        query = supabase.table("action_solutions").select("text").eq("language_code", lang_code)
        if personality:
            query = query.eq("personality", personality)
        
        response = await run_in_threadpool(query.execute)
        missions = [row['text'] for row in response.data]
        
        if not missions:
            fallback_res = await run_in_threadpool(supabase.table("action_solutions").select("text").eq("language_code", lang_code).eq("personality", "prob_solver").execute)
            missions = [row['text'] for row in fallback_res.data]

        selected_mission = random.choice(missions) if missions else default_mission
        
        try:
            return {"mission": selected_mission.format(user_nick_nm=user_name_to_use)}
        except KeyError:
            return {"mission": selected_mission.replace("{user_nick_nm}", user_name_to_use)}

    except Exception as e:
        print(get_translation("log_error_get_action_mission", DEFAULT_LANG, error=str(e)))
        return {"mission": default_mission}


# ======================================================================
# ===     피드백 처리 엔드포인트     ===
# ======================================================================

@app.post("/solutions/feedback")
async def handle_solution_feedback(payload: FeedbackRequest):
    """
    마음 관리 팁에 대한 사용자 피드백을 받아 처리하고,
    'not_helpful'인 경우 negative_tags를 업데이트합니다.
    """
    lang_code = payload.language_code if payload.language_code in translations else DEFAULT_LANG
    if not supabase:
        raise HTTPException(status_code=500, detail=get_translation("error_supabase_init", lang_code))

    try:
        # 1. 먼저 solution_feedback 테이블에 피드백 기록을 삽입합니다.
        feedback_insert_query = supabase.table("solution_feedback").insert({
            "user_id": payload.user_id,
            "solution_id": payload.solution_id,
            "session_id": payload.session_id,
            "solution_type": payload.solution_type,
            "feedback": payload.feedback
        })
        await run_in_threadpool(feedback_insert_query.execute)

        # 2. 만약 피드백이 'not_helpful'이라면, 태그 업데이트 로직을 실행합니다.
        if payload.feedback == 'not_helpful':
            # 2-1. 싫어요 누른 마음 관리 팁의 태그를 가져옵니다.
            solution_query = supabase.table("solutions").select("tags").eq("solution_id", payload.solution_id).single()
            solution_res = await run_in_threadpool(solution_query.execute)
            
            if solution_res.data and solution_res.data.get("tags"):
                solution_tags = solution_res.data["tags"]

                # 2-2. 사용자의 현재 negative_tags를 가져옵니다.
                profile_query = supabase.table("user_profiles").select("negative_tags").eq("id", payload.user_id).single()
                profile_res = await run_in_threadpool(profile_query.execute)
                
                current_tags = []
                if profile_res.data and profile_res.data.get("negative_tags"):
                    current_tags = profile_res.data["negative_tags"]

                # 2-3. 기존 태그와 새로운 태그를 합치고 중복을 제거합니다.
                updated_tags = list(set(current_tags) | set(solution_tags))
                
                # 2-4. user_profiles 테이블에 업데이트된 태그 목록을 저장합니다.
                update_query = supabase.table("user_profiles").update({"negative_tags": updated_tags}).eq("id", payload.user_id)
                await run_in_threadpool(update_query.execute)
                
                print(get_translation("log_negative_tags_updated", DEFAULT_LANG, user_id=payload.user_id, tags=updated_tags))

        return {"message": get_translation("feedback_success", lang_code)}

    except Exception as e:
        tb = traceback.format_exc()
        job_name = "/solutions/feedback"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=tb))
        raise HTTPException(status_code=500, detail={"error": get_translation("error_occurred", lang_code, error=str(e)), "trace": tb if os.getenv("DEBUG") else None})
    

# ======================================================================
# === 백필 수동 실행 ===
# ======================================================================
@app.post("/jobs/backfill")
async def run_backfill(payload: BackfillRequest):
    lang_code = payload.language_code if payload.language_code in translations else DEFAULT_LANG
    """
    지정된 날짜 범위에 대해 모든 사용자 또는 특정 사용자의 일일/주간 요약을 생성합니다.
    
    Args:
        payload: BackfillRequest
            - start_date: 시작 날짜 (YYYY-MM-DD 형식)
            - end_date: 끝 날짜 (YYYY-MM-DD 형식)
            - user_id: 특정 사용자 ID (선택사항, None이면 모든 사용자 처리)
    
    Returns:
        dict: 백필 작업 결과
    """
    try:
        from backfill_summaries import run_backfill as backfill_function
        print(get_translation("log_backfill_request", lang_code, endpoint="/jobs/backfill"))
        print(get_translation("log_backfill_range", lang_code, start_date=payload.start_date, end_date=payload.end_date))
        print(get_translation("log_backfill_check_logs", lang_code, main_py="main.py"))
        print(get_translation("log_backfill_wait", lang_code))
        
        # 백필 함수에도 lang_code 전달 (만약 지원한다면)
        result = await backfill_function(payload.start_date, payload.end_date, payload.user_id, lang_code)
        
        print(get_translation("backfill_complete", lang_code))
        return result
    except ImportError:
        raise HTTPException(status_code=404, detail="Backfill script not found.")
    except Exception as e:
        tb = traceback.format_exc()
        job_name = "/jobs/backfill"
        print(get_translation("log_error_unhandled_exception", DEFAULT_LANG, job_name=job_name, error=str(e), trace=tb))
        raise HTTPException(status_code=500, detail={"error": get_translation("error_occurred", lang_code, error=str(e)), "trace": tb if os.getenv("DEBUG") else None})
    

