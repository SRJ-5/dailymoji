from __future__ import annotations

import datetime as dt
import json
import os
import traceback
from typing import Optional, List, Dict, Any

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client

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
BIND_HOST = os.getenv("BIND_HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", "8000"))

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")  # 서비스 키 사용
supabase = None
if SUPABASE_URL and SUPABASE_KEY:
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# ---------- FastAPI ----------
app = FastAPI(title="SRJ-5 PoC API")
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


# ---------- LLM ----------
SYSTEM_PROMPT = """
You are a clinical-grade SRJ-5 emotion analysis assistant.
Return STRICT JSON ONLY matching this schema. No prose.

SCHEMA:
{'schema_version':'srj5-v1',
 'text_cluster_scores':{'neg_low':0..1,'neg_high':0..1,'adhd_high':0..1,'sleep':0..1,'positive':0..1},
 'intensity':{'neg_low':0..3,'neg_high':0..3,'adhd_high':0..3,'sleep':0..3,'positive':0..3},
 'frequency':{'neg_low':0..3,'neg_high':0..3,'adhd_high':0..3,'sleep':0..3,'positive':0..3},
 'evidence_spans':{'neg_low':[str],'neg_high':[str],'adhd_high':[str],'sleep':[str],'positive':[str]},
 'dsm_hits':{'neg_low':[str],'neg_high':[str],'adhd_high':[str],'sleep':[str],'positive':[str]},
 'intent':{'self_harm':'none|possible|likely','other_harm':'none|possible|likely'},
 'irony_or_negation': bool,
 'valence_hint': -1.0..1.0,
 'arousal_hint': 0.0..1.0,
 'confidence': 0.0..1.0}

RULES:
A) Evidence & Gating
- evidence_spans MUST copy exact words/phrases from the input text.
- If evidence_spans is empty → corresponding cluster score MUST be <= 0.2.
- For sleep: evidence must include keywords like '잠','수면','불면','깼다' to allow score > 0.2.

B) Cluster Priorities
- neg_low: If words like '우울','무기력','번아웃' appear → neg_low must dominate over neg_high.
- neg_high: Only score high if explicit anger/anxiety/fear words are present.
- adhd_high: Score >0 only if ADHD/산만/집중 안됨/충동 words appear.
- sleep: Score >0 only if sleep-related keywords exist.
- positive: Only if explicit positive words appear. Exclude irony/sarcasm.

C) DSM Hits
- dsm_hits must only contain predefined survey codes:
  PHQ9_Q1..9, GAD7_Q1..7, PSQI_Q1..7, ASRS_Q1..6, RSES_Q1..10.
- Do NOT output disorder names like 'MDD' or 'GAD'.

STRICT:
- Do NOT invent evidence.
- Do NOT assign nonzero scores without matching evidence.
- Do NOT output anything besides the JSON object.
"""

# # 위 프롬프트 짧은 버전(토큰 최소화 버전)
# """
# You are an SRJ-5 clinical emotion analysis assistant. 
# Return STRICT JSON ONLY following this schema (no prose):

# {'schema_version':'srj5-v1',
#  'text_cluster_scores':{'neg_low':0..1,'neg_high':0..1,'adhd_high':0..1,'sleep':0..1,'positive':0..1},
#  'intensity':{'neg_low':0..3,'neg_high':0..3,'adhd_high':0..3,'sleep':0..3,'positive':0..3},
#  'frequency':{'neg_low':0..3,'neg_high':0..3,'adhd_high':0..3,'sleep':0..3,'positive':0..3},
#  'evidence_spans':{'neg_low':[str],'neg_high':[str],'adhd_high':[str],'sleep':[str],'positive':[str]},
#  'dsm_hits':{'neg_low':[str],'neg_high':[str],'adhd_high':[str],'sleep':[str],'positive':[str]},
#  'intent':{'self_harm':'none|possible|likely','other_harm':'none|possible|likely'},
#  'irony_or_negation': bool,
#  'valence_hint': -1.0..1.0,
#  'arousal_hint': 0.0..1.0,
#  'confidence': 0.0..1.0}

# Rules:
# - evidence_spans must copy exact input words; if empty → score ≤ 0.2. 
# - Sleep >0.2 requires sleep keywords.
# - neg_low has priority if 우울/무기력/번아웃 appear, even if neg_high present.
# - adhd_high/sleep/positive require explicit keywords, else 0.0.
# - positive ignores irony.
# - dsm_hits must use only PHQ9/GAD7/PSQI/ASRS/RSES item codes.
# """


async def call_llm(user_payload: dict) -> dict:
    if not OPENAI_KEY:
        return {}
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {OPENAI_KEY}"},
            json={
                "model": "gpt-4o-mini",
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": json.dumps(user_payload, ensure_ascii=False)},
                ],
                "temperature": 0.0,
                "max_tokens": 700,
            },
            timeout=30.0,
        )
        data = resp.json()
        try:
            content = data["choices"][0]["message"]["content"]
            return json.loads(content)
        except Exception:
            return {"error": "invalid_json", "raw": data}


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


# ---------- API ----------
@app.post("/checkin")
async def checkin(payload: Checkin):
    try:
        text = payload.text or ""
        debug_log={}

        # 1) Rule
        rule_scores, rule_evidence, debug_log_rule = rule_scoring(text)
        rule_max = max(rule_scores.values() or [0.0])
        debug_log["rule_scores"] = rule_scores
        debug_log["rule_evidence"] = rule_evidence
        debug_log["rule_debug"] = debug_log_rule  # 강조어/슬랭 기록

        # 2) LLM
        llm_json=None
        if rule_max < RULE_SKIP_LLM:
            llm_json=await call_llm(payload.dict())
        debug_log["llm"]=llm_json

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

        # 6) Safety
        if any(term in text for term in SAFETY_TERMS):
            profile=1; intervention={"cluster":"neg_low","severity":"high","preset_id":"safety_crisis_modal_v1","priority":1000,"safety_check":True}
            debug_log["safety_override"]=True

        # 7) G-score
        g=g_score(final_scores); debug_log["g_score"]=g

        # ---------- Supabase 저장 ----------
        if supabase:
            try:
                session_row={
                    "created_at":dt.datetime.utcnow().isoformat(),
                    "text":text,
                    "profile":profile,
                    "g_score":g,
                    "intervention":json.dumps(intervention),
                    "debug_log":json.dumps(debug_log),
                }
                supabase.table("sessions").insert(session_row).execute()

                for c,v in final_scores.items():
                    supabase.table("cluster_scores").insert({
                        "created_at":dt.datetime.utcnow().isoformat(),
                        "cluster":c,"score":v,"session_text":text[:100],
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


if __name__=="__main__":
    import uvicorn
    uvicorn.run(app,host=BIND_HOST,port=PORT,reload=True)
