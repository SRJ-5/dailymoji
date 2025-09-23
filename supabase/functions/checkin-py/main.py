from __future__ import annotations

import datetime as dt
import json
import os
import re
import traceback
import random
from typing import Optional, List, Dict, Any, Union

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client

# LLM 호출 함수와 시스템 프롬프트를 분리해서 관리하기 편하게 만듭니다.
from llm_prompts import (
    call_llm,
    TRIAGE_SYSTEM_PROMPT,
    ANALYSIS_SYSTEM_PROMPT,
    FRIENDLY_SYSTEM_PROMPT
)

# 형태소 분석: 설치되어 있지 않으면 graceful fallback
try:
    from kiwipiepy import Kiwi
    _kiwi = Kiwi()
except Exception:
    _kiwi = None

from rule_based import rule_scoring
from srj5_constants import (
    CLUSTERS, DSM_BETA, DSM_WEIGHTS, INTERVENTIONS,
    META_WEIGHTS, PCA_PROXY, ONBOARDING_MAPPING,
    SEVERITY_LOW_MAX, SEVERITY_MED_MAX,
    W_LLM, W_RULE
)

# ---------- 환경설정 ----------
load_dotenv()
OPENAI_KEY = os.getenv("OPENAI_API_KEY")

# Docker 환경에서는 '0.0.0.0'을 사용해야 한다고 함.
BIND_HOST = os.getenv("BIND_HOST", "0.0.0.0") 
# BIND_HOST = os.getenv("BIND_HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", "8000"))

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")  # 서비스 키 사용
supabase = None
if SUPABASE_URL and SUPABASE_KEY:
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# ---------- FastAPI ----------
app = FastAPI(title="DailyMoji API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- 데이터 모델 ----------
class Checkin(BaseModel):
    user_id: str 
    text: str
    icon: Optional[str] = None
    intensity: Optional[float] = None
    contexts: Optional[List[str]] = None
    timestamp: Optional[str] = None
    surveys: Optional[Dict[str, Any]] = None
    onboarding: Optional[Dict[str, Any]] = None
    action: Optional[Dict[str, Any]] = None # Flutter로부터의 버튼 액션을 받기 위함


# ---------- Safety: Regex + Kiwi + LLM intent 결합 ----------
# 1) 자살 암시/의사 표현 정규식(다양한 변형 포함)
SAFETY_REGEX = [
    r"죽고\s*싶",                  # "죽고 싶다", "죽고 싶어" 등
    r"살고\s*싶지\s*(?:않|않아)",    # "살고 싶지 않다/않아"
    r"살기\s*싫",                  # "살기 싫다/싫어"
    r"자살\s*(?:하고\s*싶|충동|생각)",       # 자살 하고 싶/충동/생각
    r"목숨(?:을)?\s*(?:끊|버리|포기)\s*하고?\s*싶(?:다|어)?",
    r"생을\s*마감하(?:고|고\s*싶|고싶)",
    r"죽어버리(?:고)?\s*싶(?:다|어)?",
    r"끝내버리(?:고)?\s*싶(?:다|어)?",
]

# 2) 거짓양성(비유/농담/긍정문맥) 필터
SAFETY_FIGURATIVE = [
    r"죽을\s*만큼\s*(?:맛있|재밌|웃기|행복|좋)",
    r"죽겠다\s*ㅋㅋ",
    r"개\s*맛있",   # 문맥에 따라 다르지만 기본 차단
]

def _find_regex_matches(text: str, patterns: List[str]) -> List[str]:
    hits = []
    for pat in patterns:
        for m in re.finditer(pat, text, flags=re.IGNORECASE):
            hits.append(m.group(0))
    return hits

def _kiwi_tokens(text: str) -> List[str]:
    if not _kiwi:
        return []
    try:
        return [t.form for t in _kiwi.tokenize(text)]
    except Exception:
        return []

def _kiwi_has_selfharm_combo(text: str) -> bool:
    """
    죽/VV + 고 + 싶/VX 조합, 살/VV + 고 + 싶 + 지 않 조합 등 형태소 기반 탐지
    """
    if not _kiwi:
        return False
    try:
        tokens = _kiwi.tokenize(text)
        lemmas = [f"{t.tag}:{t.form}" for t in tokens]  # 디버깅용
        # 단순 패턴: '죽' 동사 + '싶' 보조/형태, 혹은 '살' + '싶' + '않'
        forms = [t.form for t in tokens]
        tags = [t.tag for t in tokens]

        # 죽-고-싶
        for i in range(len(forms) - 2):
            if ("죽" in forms[i] or "죽" in forms[i].rstrip("다")) and \
               (forms[i+1] in ["고", "고요"]) and \
               ("싶" in forms[i+2] or "싶" in forms[i+2].rstrip("다")):
                return True

        # 살-고-싶-지-않
        for i in range(len(forms) - 4):
            if ("살" in forms[i] or "살" in forms[i].rstrip("다")) and \
               (forms[i+1] in ["고", "고요"]) and \
               ("싶" in forms[i+2]) and \
               (forms[i+3] in ["지"]) and \
               ("않" in forms[i+4] or "아니" in forms[i+4]):
                return True

        return False
    except Exception:
        return False

def is_safety_text(text: str, llm_json: dict | None, debug_log: dict) -> (bool, dict):
    # 1) 정규식 탐지
    regex_hits = _find_regex_matches(text, SAFETY_REGEX)
    figurative_hits = _find_regex_matches(text, SAFETY_FIGURATIVE)

    # 2) Kiwi 형태소 조합(옵션)
    kiwi_combo = _kiwi_has_selfharm_combo(text)
    kiwi_tokens = _kiwi_tokens(text) #디버그용으로만 사용되므로 반환값에 영향이 현재 없음

    # 3) LLM intent
    safety_llm_flag = (llm_json or {}).get("intent", {}).get("self_harm") in {"possible", "likely"}

    # 4) 최종 판정: (정규식 or kiwi 조합 or LLM) AND (비유/농담 패턴이 없음)
    triggered = (bool(regex_hits) or kiwi_combo or safety_llm_flag) and not bool(figurative_hits)

    # --- 로그 남기기 ---
    debug_log["safety"] = {
        "regex_matches": regex_hits,
        "figurative_matches": figurative_hits,
        "kiwi_combo": kiwi_combo,
        "kiwi_tokens": kiwi_tokens[:50],  # 너무 길면 잘라서
        "llm_intent_flag": safety_llm_flag,
        "triggered": triggered,
    }

    if triggered:
            # 위험이 감지되면, neg_low에 0.95점의 강력한 기본 점수를 부여하여 반환
            # TODO: max_cluster로 0.95를 줄건지는 차후 생각해보기
            safety_scores = {"neg_low": 0.95, "neg_high": 0.0, "adhd_high": 0.0, "sleep": 0.0, "positive": 0.0}
            return (True, safety_scores)
        
    return (False, {})

# ---------- Helpers ----------
def clip01(x: float) -> float: return float(max(0.0, min(1.0, x)))

def severity_level(s: float) -> str:
    if s <= SEVERITY_LOW_MAX: return "low"
    if s <= SEVERITY_MED_MAX: return "medium"
    return "high"

def meta_adjust(base_scores: dict, payload: Checkin) -> dict:
    s = base_scores.copy()
    if payload.icon and payload.icon.lower() in CLUSTERS:
        s[payload.icon.lower()] = clip01(s[payload.icon.lower()] + META_WEIGHTS["icon"] * 0.2)
    if payload.intensity is not None:
        inten = clip01(payload.intensity / 10.0)
        for c in ["neg_low","neg_high","sleep","adhd_high"]:
            s[c] = clip01(s[c] + inten * META_WEIGHTS["intensity_self"] * 0.2)
    ctxs = [c.lower() for c in (payload.contexts or [])]
    if "night" in ctxs or _is_night(payload.timestamp):
        s["sleep"] = clip01(s["sleep"] + META_WEIGHTS["time"] * 0.2)
    return s

def _is_night(ts: Optional[str]) -> bool:
    try:
        if not ts: return False
        hour = dt.datetime.fromisoformat(ts.replace("Z","+00:00")).hour
        return hour >= 22 or hour < 7
    except Exception: return False

def dsm_calibrate(scores: dict, surveys: dict | None) -> dict:
    s = {}
    for c, v in scores.items():
        v = v * DSM_WEIGHTS.get(c, 1.0)
        if surveys:
            z = 0.0
            if c == "neg_low" and "phq9" in surveys: z = (surveys["phq9"] - 10) / 10.0
            if c == "neg_high" and "gad7" in surveys: z = (surveys["gad7"] - 10) / 10.0
            if c == "sleep" and "psqi" in surveys: z = (surveys["psqi"] - 10) / 10.0
            if c == "adhd_high" and "asrs" in surveys: z = (surveys["asrs"] - 12) / 8.0
            if c == "positive" and "rses" in surveys: z = (surveys["rses"] - 20) / 10.0
            v = clip01(v + DSM_BETA.get(c,0.1)*z)
        s[c] = clip01(v)
    return s

def pca_proxy(final_scores: dict) -> dict:
    pc1 = sum(final_scores.get(k,0.0) * w for k,w in PCA_PROXY["pc1"].items())
    pc2 = sum(final_scores.get(k,0.0) * w for k,w in PCA_PROXY["pc2"].items())
    return {"pc1": round(max(-1.0,min(1.0,pc1)),3),
            "pc2": round(clip01((pc2+1.0)/2.0),3)}

def pick_profile(final_scores: dict, llm: dict, surveys: dict | None) -> int:
    intent = (llm or {}).get("intent",{})
    if intent.get("self_harm") in {"possible","likely"}: return 1
    return (
        1 if max(final_scores.get("neg_low",0),final_scores.get("neg_high",0)) > 0.85 else
        2 if (surveys and ((surveys.get("phq9",0)>=10) or (surveys.get("gad7",0)>=10))) or
             max(final_scores.values()) > 0.60 else
        3 if max(final_scores.values()) > 0.30 else
        0
    )

def map_intervention(profile: int, final_scores: dict, is_night: bool, llm: dict|None) -> dict:
    top = max(final_scores.items(), key=lambda x:x[1])[0]
    sev = severity_level(final_scores[top])
    sleep_evidence = (llm or {}).get("evidence_spans",{}).get("sleep",[])
    if is_night and top=="neg_low" and sev in {"high","medium"} and sleep_evidence:
        top="sleep"; sev="medium" if sev=="high" else sev
    candidates=[r for r in INTERVENTIONS if r["cluster"]==top and (r["severity"] in {sev,"any"})]
    if not candidates: candidates=[r for r in INTERVENTIONS if r["cluster"]==top]
    if not candidates: candidates=[r for r in INTERVENTIONS]
    return sorted(candidates,key=lambda r:r["priority"],reverse=True)[0]

def g_score(final_scores: dict) -> float:
    w={"neg_high":1.0,"neg_low":0.9,"sleep":0.7,"adhd_high":0.6,"positive":-0.3}
    g=sum(final_scores.get(k,0.0)*w.get(k,0.0) for k in CLUSTERS)
    return round(clip01((g+1.0)/2.0),3)

# --- 베이스라인 점수 계산 함수 추가 ---
def calculate_baseline_scores(onboarding_scores: Dict[str, int]) -> Dict[str, float]:
    """온보딩 설문 점수를 바탕으로 클러스터별 베이스라인 점수를 계산합니다."""
    if not onboarding_scores:
        return {}
        
    baseline = {c: 0.0 for c in CLUSTERS}
    
    # 예시: onboarding_scores = {"q1": 2, "q2": 3, ...}
    for q_key, score in onboarding_scores.items():
        # --- q7(자존감) 역방향 처리 로직 ---
        processed_score = score
        if q_key == 'q7':
            processed_score = 3 - score # 자존감은 역방향 점수이므로 Flutter에서 (3 - 점수)로 계산해서 보내야 함!
            print(f"q7 점수 역방향 처리: {score} -> {processed_score}") # 디버깅용 로그

        if q_key in ONBOARDING_MAPPING:
            # 1. 점수 정규화 (0-3점 -> 0.0-1.0)
            normalized_score = processed_score / 3.0
            
            # 2. 해당 문항에 연결된 모든 클러스터에 가중치 적용하여 누적
            for mapping in ONBOARDING_MAPPING[q_key]:
                cluster = mapping["cluster"]
                weight = mapping["w"]
                baseline[cluster] += normalized_score * weight
    
    # 3. 최종 점수가 0.0 ~ 1.0 범위를 벗어나지 않도록 보정
    for c in CLUSTERS:
        if c == 'positive': # 긍정 점수는 음수가 될 수 없음
             baseline[c] = max(0.0, min(1.0, baseline[c]))
        else: # 그 외 클러스터는 -1.0 ~ 1.0 가능 (긍정의 역방향 가중치 때문에)
             baseline[c] = max(-1.0, min(1.0, baseline[c]))

    return baseline

# ---------- "친구 모드" 응답 생성 함수 ----------
async def generate_friendly_reply(text: str) -> str:
    # 친구 페르소나를 가진 프롬프트를 사용합니다.
    llm_response = await call_llm(
        system_prompt=FRIENDLY_SYSTEM_PROMPT,
        user_content=text,
        openai_key=OPENAI_KEY, # 여기서 키전달
        model="gpt-4o-mini",
        temperature=0.7 # 약간의 창의성을 부여
    )
    # LLM 응답에서 텍스트만 추출 (JSON이 아님)
    try:
        # 응답이 다양한 형태로 올 수 있으므로 안전하게 텍스트 추출
        if isinstance(llm_response, dict) and "choices" in llm_response:
             return llm_response["choices"][0]["message"]["content"].strip()
        return str(llm_response).strip() # 만약의 경우를 대비해 문자열로 변환
    except Exception:
        return "음... 방금 뭐라고 하셨죠? 다시 한번 말씀해주시겠어요? 🤔"


# ---------- API ----------
@app.post("/checkin")
async def checkin(payload: Checkin):
    text = (payload.text or "").strip()
    debug_log: Dict[str, Any] = {}


    try:
        # --- Flutter에서 보낸 액션이 있는지 먼저 확인하고 처리 (솔루션 수락 등) ---
        action_data = payload.dict().get("action")
        if action_data and action_data.get("type") == "accept_solution":
            solution_id = action_data.get("solution_id")
            
            # 백엔드는 Flutter가 솔루션 멘트와 영상을 가져올 수 있도록 필요한 ID만 전달
            return {
                "intervention": {
                    "preset_id": "SOLUTION_PROVIDED", # Flutter가 이 ID를 보고 멘트 가져옴
                    "solution_id": solution_id        # Flutter가 이 ID로 영상 정보 가져옴
                }
            }

        # --- 1단계: 안전 장치 최우선 검사 (LLM 없이, 정규식과 Kiwi 분석만으로 1차 검사) ---
        is_safe, safety_scores = is_safety_text(text, None, debug_log)

        if is_safe:
            print(f"🚨 1차 안전 장치 발동: '{text}'")
            debug_log["mode"] = "SAFETY_CRISIS"
            final_scores = safety_scores # is_safety_text가 반환한 강력한 점수를 최종 점수로 즉시 할당
            profile = 1 # 프로필과 개입을 위기 상황에 맞게 강제로 설정
            
            # 👇 1차 안전 개입 시에도 어떤 클러스터가 위험한지 신호 전달 (Flutter용)
            dominant_neg_cluster = "neg_low" if final_scores.get("neg_low", 0) >= final_scores.get("neg_high", 0) else "neg_high"
            
            # Flutter가 멘트 및 영상 정보를 가져갈 수 있도록 preset_id와 클러스터 정보를 전달합니다.
            intervention = {
                "preset_id": "SAFETY_CRISIS_MODAL", # Flutter에서 이 ID를 보고 멘트 가져옴
                "cluster": dominant_neg_cluster, # Flutter가 이 클러스터로 멘트 가져옴
                "solution_id": f"{dominant_neg_cluster}_crisis_01" # Flutter가 이 ID로 영상 가져옴
            }
            g = g_score(final_scores) # 최종 점수를 바탕으로 G-score를 계산

            # # 위기 상황도 데이터베이스에 기록하여 로그를 남김
            # new_session_id = None
            # if supabase:
            #     try:
            #         session_row = {
            #             "user_id": payload.user_id, 
            #             "text": text,
            #             "profile": profile,
            #             "g_score": g,
            #             "intervention": json.dumps(intervention),
            #             "debug_log": json.dumps(debug_log, ensure_ascii=False),
            #         }
            #         response = supabase.table("sessions").insert(session_row).execute()
            #         new_session_id = response.data[0]['id']
            #     except Exception as e:
            #         print(f"Supabase 위기 로그 저장 실패: {e}")

            # # 다른 분석을 모두 건너뛰고, 즉시 최종 응답을 반환
            # return {
            #     "session_id": new_session_id,
            #     "input": payload.dict(),
            #     "final_scores": final_scores,
            #     "g_score": g,
            #     "profile": profile,
            #     "intervention": intervention,
            #     "debug_log": debug_log,
            # }
        else: # --- (안전이 확인된 경우에만 아래의 하이브리드 분기 로직이 실행되도록!!) ---
            # --- 2단계: 하이브리드 분기 처리 시작 ---
            chosen_mode = "PENDING" # 초기 상태는 '보류'  
            rule_scores, rule_evidence, debug_log_rule = rule_scoring(text)
            max_rule_score = max(rule_scores.values() or [0.0])

            
            # 2-1. 규칙 기반으로 명백한 케이스 처리
            if max_rule_score >= 0.7: # "우울", "분노" 등 확실한 감정 단어
                chosen_mode = "ANALYSIS"
                debug_log["triage_reason"] = "High rule score"
            elif max_rule_score < 0.1 and len(text) < 10: # "하이", "ㅋㅋ" 등
                chosen_mode = "FRIENDLY"
                debug_log["triage_reason"] = "Low rule score and short text"
            
            # 2-2. 애매한 케이스는 LLM에게 판별 요청
            if chosen_mode == "PENDING":
                debug_log["triage_reason"] = "Ambiguous case, using LLM Triage"
                # 판별 전용 LLM 호출. temperature=0으로 하여 일관된 답변 유도
                triage_result = await call_llm(
                    system_prompt=TRIAGE_SYSTEM_PROMPT,
                    user_content=text,
                    openai_key=OPENAI_KEY,
                    temperature=0.0
                )
                chosen_mode = "ANALYSIS" if "ANALYSIS" in str(triage_result) else "FRIENDLY"
                debug_log["triage_reason"] = f"LLM Triage classified as {chosen_mode}"

            # --- 3단계: 결정된 모드 실행 ---
            if chosen_mode == "FRIENDLY":
                    # "친구 모드" 실행
                debug_log["mode"] = "FRIENDLY_REPLY"
                print(f"💬 친구 모드 실행: '{text}' (Reason: {debug_log.get('triage_reason')})")
                friendly_text = await generate_friendly_reply(text)
                final_scores = {} # 친구 모드는 점수가 필요 없으므로 초기화
                profile = 0
                g = 0.0
                intervention = {"preset_id": "FRIENDLY_REPLY", "text": friendly_text} # Flutter가 멘트 가져옴


            # --- 분석 모드  ---
            else:
                debug_log["mode"] = "ANALYSIS"
                print(f"🔬 분석 모드 실행: '{text}' (Reason: {debug_log.get('triage_reason')})")
                
                # 기존의 분석 파이프라인 시작
                # 1) Rule
                debug_log["rule_scores"] = rule_scores
                debug_log["rule_evidence"] = rule_evidence
                debug_log["rule_debug"] = debug_log_rule  # 강조어/슬랭 기록 -- 여기서 ignored 토큰 확인 가능

                # --- 1-1. 온보딩 점수로 베이스라인 계산 --- 
                onboarding_scores = payload.onboarding or {}
                baseline_scores = calculate_baseline_scores(onboarding_scores)
                debug_log["baseline_scores"] = baseline_scores

                # --- 1-2. LLM에 전달할 데이터에 베이스라인 추가 --- 
                llm_payload = payload.dict()
                llm_payload["baseline_scores"] = baseline_scores
            
                # 2) LLM
                # 수정된 코드
                llm_json = await call_llm(
                    system_prompt=ANALYSIS_SYSTEM_PROMPT, 
                    user_content=json.dumps(llm_payload, ensure_ascii=False),
                    openai_key=OPENAI_KEY, # 여기서 키전달
                )
                debug_log["llm"] = llm_json

                # 👇 Valence/Arousal 데이터 추출
                valence = None
                arousal = None
                if llm_json and not llm_json.get("error"):
                    valence = llm_json.get("valence")
                    arousal = llm_json.get("arousal")
                    debug_log["valence_arousal"] = {"valence": valence, "arousal": arousal}


                # 3) Fusion
                text_if={c:0.0 for c in CLUSTERS}
                if llm_json and not llm_json.get("error"):
                    I,F=llm_json.get("intensity",{}),llm_json.get("frequency",{})
                    for c in CLUSTERS:
                        In=clip01((I.get(c,0.0) or 0.0)/3.0)
                        Fn=clip01((F.get(c,0.0) or 0.0)/3.0)
                        b_lex=0.1*rule_scores.get(c,0.0)
                        text_if[c]=clip01(0.6*In+0.4*Fn+b_lex)
                fused={c:clip01(W_RULE*rule_scores.get(c,0.0)+W_LLM*text_if.get(c,0.0)) for c in CLUSTERS}
                debug_log["fused"]=fused

                # 4) Meta + DSM
                meta_adj = meta_adjust(fused, payload)
                final_scores = dsm_calibrate(meta_adj, payload.surveys) # dsm_calibrate 대신 meta_adj를 바로 사용함.

                # 5) PCA / Profile / Intervention
                # pca=pca_proxy(final_scores); debug_log["pca"]=pca
                profile=pick_profile(final_scores,llm_json,payload.surveys); debug_log["profile"]=profile

                # 👇 최종 Intervention 객체 생성 (일반 솔루션 제안용)
                top_cluster = max(final_scores, key=final_scores.get, default="neg_low")
                intervention = {
                    "preset_id": "SOLUTION_PROPOSAL", # Flutter에서 이 ID를 보고 멘트 가져옴
                    "top_cluster": top_cluster, # Flutter가 이 클러스터로 멘트 가져옴
                    "solution_id": f"{top_cluster}_breathing_01" # Flutter가 이 ID로 영상 가져옴
                }
            
                # 6) 🚨 2차 최종 Safety Override (LLM 분석 결과를 포함한 2차 확인)
                is_safe_after_llm, _ = is_safety_text(text, llm_json, debug_log)
                if is_safe_after_llm:
                    # --- 👇 LLM의 판단에 따라 위기 단계를 나눕니다. ---
                    harm_intent = (llm_json or {}).get("intent", {}).get("self_harm", "none")
                    dominant_neg_cluster = "neg_low" # 초기값, 아래에서 덮어씀

                    if final_scores.get("neg_low", 0) >= final_scores.get("neg_high", 0):
                        dominant_neg_cluster = "neg_low"
                    else:
                        dominant_neg_cluster = "neg_high"

                    # 1단계: 명백한 위기 ("likely")
                    if harm_intent == "likely":
                        print("🚨 1단계 안전 장치 발동: 강력한 Override 적용")
                        # 기존의 강력한 Override 로직을 그대로 사용
                        final_scores["neg_low"] = max(final_scores.get("neg_low", 0), 0.95)
                        profile = 1
                        intervention = {
                            "preset_id": "SAFETY_CRISIS_SELF_HARM",
                            "cluster": dominant_neg_cluster, 
                            "solution_id": f"{dominant_neg_cluster}_crisis_01"
                        }
                        debug_log["safety_override_applied"] = "Level 1: Likely"

                    # 2단계: 잠재적 위험 신호 ("possible")
                    elif harm_intent == "possible":
                        print("⚠️ 2단계 안전 장치 발동: 소프트한 개입 적용")
                        # 점수와 프로필은 그대로 두고, intervention만 확인형 메시지로 변경
                        intervention = {
                            "preset_id": "SAFETY_CHECK_IN", 
                            "cluster": dominant_neg_cluster, 
                            "solution_id": f"{dominant_neg_cluster}_checkin_01" 
                        }
                        debug_log["safety_override_applied"] = "Level 2: Possible"
                

                # 7) G-score (Safety Override로 점수가 변경되었을 수 있으므로, 최종적으로 다시 계산)
                g=g_score(final_scores); debug_log["g_score"]=g

            # ---------- Supabase 저장 ----------
            new_session_id = None
            if supabase:
                try:
                    session_row = {
                        "user_id": payload.user_id,
                        "text": text,
                        "profile": profile,
                        "g_score": g,
                        "intervention": json.dumps(intervention, ensure_ascii=False), # ensure_ascii=False 추가
                        "debug_log": json.dumps(debug_log, ensure_ascii=False),
                    }
                    response = supabase.table("sessions").insert(session_row).execute()
                    new_session_id = response.data[0]['id']

                    if final_scores: # final_scores가 있을 때만 cluster_scores 저장
                        for c,v in final_scores.items():
                            supabase.table("cluster_scores").insert({
                               "created_at": dt.datetime.utcnow().isoformat(),
                                "session_id": new_session_id, # session_id 추가
                                "user_id": payload.user_id,
                                "cluster": c,
                                "score": v,
                                "session_text": text[:100],
                            }).execute()
                except Exception as e:
                    print("Supabase 저장 실패:",e)
                    traceback.print_exc()

            # --- 최종 응답 ---
            return {
                "session_id": new_session_id,
                "input": payload.dict(),
                "final_scores": final_scores,
                "g_score": g,
                "profile": profile,
                "intervention": intervention, # 최종 확정된 intervention 전달
                "debug_log": debug_log,
            }

    except Exception as e:
        tb = traceback.format_exc()
        print("❌ Checkin Error:", e)
        print(tb)
        return {"error": str(e), "trace": tb}

