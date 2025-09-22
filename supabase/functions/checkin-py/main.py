from __future__ import annotations

import datetime as dt
import json
import os
import re
import traceback
from typing import Optional, List, Dict, Any, Union

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client

# LLM 호출 함수와 시스템 프롬프트를 분리해서 관리하기 편하게 만듭니다.
from llm_prompts import (
    call_llm,
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
    META_WEIGHTS, PCA_PROXY, RULE_SKIP_LLM,
    SAFETY_TERMS, SEVERITY_LOW_MAX, SEVERITY_MED_MAX,
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
    text: str
    icon: Optional[str] = None
    intensity: Optional[float] = None
    contexts: Optional[List[str]] = None
    timestamp: Optional[str] = None
    surveys: Optional[Dict[str, Any]] = None
    onboarding: Optional[Dict[str, Any]] = None


# ---------- Safety: Regex + Kiwi + LLM intent 결합 ----------
# 1) 자살 암시/의사 표현 정규식(다양한 변형 포함)
SAFETY_REGEX = [
    r"죽고\s*싶(?:다|어|다\.)",              # 죽고싶다/죽고 싶어
    r"살고\s*싶지\s*않(?:다|아)",           # 살고 싶지 않다
    r"자살\s*(?:하고\s*싶|충동|생각)",       # 자살 하고 싶/충동/생각
    r"목숨(?:을)?\s*(?:끊|버리|포기)\s*하고?\s*싶(?:다|어)?",
    r"생을\s*마감하(?:고|고\s*싶|고싶)",
    r"죽어버리(?:고)?\s*싶(?:다|어)?",
    r"끝내버리(?:고)?\s*싶(?:다|어)?",
    r"살기\s*싫(?:다|어)",
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

def is_safety_text(text: str, llm_json: dict | None, debug_log: dict) -> bool:
    # 1) 정규식 탐지
    regex_hits = _find_regex_matches(text, SAFETY_REGEX)
    figurative_hits = _find_regex_matches(text, SAFETY_FIGURATIVE)

    # 2) Kiwi 형태소 조합(옵션)
    kiwi_combo = _kiwi_has_selfharm_combo(text)
    kiwi_tokens = _kiwi_tokens(text)

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
    return triggered


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
 # --- 1단계: 안전 장치 최우선 검사 ---
        # (LLM 없이, 정규식과 Kiwi 분석만으로 1차 검사)
        if is_safety_text(text, None, debug_log):
            print(f"🚨 안전 모드 실행: '{text}'")
            debug_log["mode"] = "SAFETY_CRISIS"
            return {
                "session_id": None, "input": payload.dict(), "final_scores": {}, "g_score": 1.0, "profile": 1,
                "intervention": {
                    "preset_id": "SAFETY_CRISIS_MODAL",
                    "text": "많이 힘든 마음이 느껴져요. 혼자 끙끙 앓지 말고, 이야기할 곳이 필요하다면 꼭 연락해보세요."
                },
                "debug_log": debug_log,
            }

        # --- 2단계: 모드 결정 (친구 모드 or 분석 모드) ---
        rule_scores, _, _ = rule_scoring(text)
        max_rule_score = max(rule_scores.values() or [0.0])
        # (감정 점수가 0.1보다 크거나) AND (글자 길이가 4보다 크면) -> 분석 모드
        is_emotional_text = max_rule_score > 0.1 and len(text) > 4 

        if not is_emotional_text:
            # --- 3-A. "친구 모드"로 작동 ---
            debug_log["mode"] = "FRIENDLY_REPLY"
            print(f"💬 친구 모드 실행: '{text}'")
            friendly_text = await generate_friendly_reply(text)
            return {
                "session_id": None, "input": payload.dict(), "final_scores": {}, "g_score": 0.0, "profile": 0,
                "intervention": {"preset_id": "FRIENDLY_REPLY", "text": friendly_text},
                "debug_log": debug_log,
            }
        
        # --- 3-B. "코치(분석) 모드"로 작동 ---
        debug_log["mode"] = "ANALYSIS"
        print(f"✨ 분석 모드 실행: '{text}'")
        
        # 기존의 분석 파이프라인 시작
        # 1) Rule
        rule_scores, rule_evidence, debug_log_rule = rule_scoring(text)
        rule_max = max(rule_scores.values() or [0.0])
        debug_log["rule_scores"] = rule_scores
        debug_log["rule_evidence"] = rule_evidence
        debug_log["rule_debug"] = debug_log_rule  # 강조어/슬랭 기록 -- 여기서 ignored 토큰 확인 가능

        # 2) LLM
        # 수정된 코드
        llm_json = await call_llm(
            system_prompt=ANALYSIS_SYSTEM_PROMPT, 
            user_content=json.dumps(payload.dict(), ensure_ascii=False),
            openai_key=OPENAI_KEY, # 여기서 키전달
        )
        debug_log["llm"] = llm_json

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
        meta_adj=meta_adjust(fused,payload); debug_log["meta"]=meta_adj
        cal=dsm_calibrate(meta_adj,payload.surveys); debug_log["calibrated"]=cal
        final_scores=cal; debug_log["final_scores"]=final_scores

        # 5) PCA / Profile / Intervention
        pca=pca_proxy(final_scores); debug_log["pca"]=pca
        profile=pick_profile(final_scores,llm_json,payload.surveys); debug_log["profile"]=profile
        intervention=map_intervention(profile,final_scores,_is_night(payload.timestamp),llm_json)
        debug_log["intervention"]=intervention

        # 6) Safety (강화 버전: Regex/Ko-morph + LLM intent 결합)
        if is_safety_text(text, llm_json, debug_log):
            profile = 1
            intervention = {
                "cluster": "neg_low",
                "severity": "high",
                "preset_id": "safety_crisis_modal_v1",
                "priority": 1000,
                "safety_check": True,
            }
            debug_log["safety_override_applied"] = True

        # 7) G-score
        g=g_score(final_scores); debug_log["g_score"]=g

        # ---------- Supabase 저장 ----------
        new_session_id = None
        if supabase:
            try:
                session_row={
                    "created_at":dt.datetime.utcnow().isoformat(),
                    "text":text,
                    "profile":profile,
                    "g_score":g,
                    "intervention":json.dumps(intervention),
                    "debug_log":json.dumps(debug_log, ensure_ascii=False),
                }
                response = supabase.table("sessions").insert(session_row).execute()
                new_session_id = response.data[0]['id']

                if final_scores: # final_scores가 있을 때만 cluster_scores 저장
                    for c,v in final_scores.items():
                        supabase.table("cluster_scores").insert({
                            "created_at":dt.datetime.utcnow().isoformat(),
                            "cluster":c,"score":v,"session_text":text[:100],
                            "user_id": payload.user_id 
                        }).execute()
            except Exception as e:
                print("Supabase 저장 실패:",e)

        # --- 최종 응답 ---
        return {
            "input": payload.dict(),
            "final_scores": final_scores,
            "g_score": g,
            "profile": profile,
            "intervention": intervention,
            "debug_log": debug_log,
        }

    except Exception as e:
        tb = traceback.format_exc()
        print("❌ Checkin Error:", e)
        print(tb)
        return {"error": str(e), "trace": tb}

# 이 부분은 Dockerfile의 CMD가 처리하므로 삭제 가능.
# if __name__=="__main__":
#     import uvicorn
#     uvicorn.run(app,host=BIND_HOST,port=PORT,reload=True)
