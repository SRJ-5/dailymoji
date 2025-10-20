# backfill_summaries.py 
# 지금까지의 데이터들 일회성으로 요약문 다 만들어서 저장하는 일회용 코드

import asyncio
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
import os
from supabase import create_client, Client
import json
import httpx
import numpy as np
import argparse

try:
    from llm_prompts import REPORT_SUMMARY_PROMPT, WEEKLY_REPORT_SUMMARY_PROMPT_STANDARD, WEEKLY_REPORT_SUMMARY_PROMPT_NEURO
    from srj5_constants import CLUSTERS, CLUSTER_TO_DISPLAY_NAME
except ImportError:
    print("오류: llm_prompts.py 또는 srj5_constants.py 파일을 찾을 수 없습니다.")
    print("이 스크립트와 동일한 폴더에 해당 파일들이 있는지 확인해주세요.")
    exit()

# --- 설정값 ---
# 날짜 범위 설정 (YYYY-MM-DD 형식)
START_DATE = "2024-01-01"  # 시작 날짜
END_DATE = "2024-12-31"    # 끝 날짜
API_CALL_DELAY = 1

# --- 핵심 함수들 (독립 실행용) ---
async def call_llm(system_prompt: str, user_content: str, openai_key: str) -> dict:
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={"Authorization": f"Bearer {openai_key}"},
                json={ "model": "gpt-4o-mini", "messages": [{"role": "system", "content": system_prompt}, {"role": "user", "content": user_content}], "temperature": 0.0, "response_format": {"type": "json_object"} },
                timeout=45.0,
            )
            data = resp.json()
            if "error" in data:
                print(f"    LLM API Error: {data['error']}")
                return {"error": data['error']}
            content = data["choices"][0]["message"]["content"]
            return json.loads(content)
        except Exception as e:
            print(f"    LLM call failed: {e}")
            return {"error": str(e)}

async def get_user_info(supabase: Client, user_id: str) -> tuple[str, str]:
    try:
        res = supabase.table("user_profiles").select("user_nick_nm").eq("id", user_id).single().execute()
        if res.data: return res.data.get("user_nick_nm", "사용자"), "모지"
    except Exception: pass
    return "사용자", "모지"

async def get_mention_from_db(supabase: Client, mention_type: str, **kwargs) -> str:
    return "긍정적인 조언 텍스트 예시입니다."

async def create_daily_summary(supabase: Client, openai_key: str, user_id: str, date_str: str):
    print(f"  - Daily summary for {date_str}...")
    try:
        start_day, end_day = f"{date_str}T00:00:00+00:00", f"{date_str}T23:59:59+00:00"
        sess_res = supabase.table("sessions").select("id, summary, g_score").eq("user_id", user_id).gte("created_at", start_day).lte("created_at", end_day).execute()
        if not sess_res.data: return
        top_sess = max(sess_res.data, key=lambda x: x.get('g_score', 0.0))
        top_sid, top_summary = top_sess['id'], top_sess.get('summary', "...")
        score_res = supabase.table("cluster_scores").select("cluster, score").eq("session_id", top_sid).execute()
        if not score_res.data: return
        top_entry = max(score_res.data, key=lambda x: x['score'])
        top_c, top_score = top_entry['cluster'], int(top_entry['score'] * 100)
        nick, _ = await get_user_info(supabase, user_id)
        a_text = await get_mention_from_db(supabase, "analysis", cluster=top_c, level="high")
        llm_ctx = {"user_nick_nm": nick, "top_cluster_display_name": CLUSTER_TO_DISPLAY_NAME.get(top_c, ""), "top_score_today": top_score, "user_dialogue_summary": top_summary, "cluster_advice": a_text}
        summary_json = await call_llm(REPORT_SUMMARY_PROMPT, json.dumps(llm_ctx, ensure_ascii=False), openai_key)
        if summary_json and "daily_summary" in summary_json:
            s_data = {"user_id": user_id, "date": date_str, "summary_text": summary_json["daily_summary"], "top_cluster": top_c, "top_score": top_score}
            supabase.table("daily_summaries").upsert(s_data, on_conflict="user_id,date").execute()
            print(f"    Success: Daily summary saved for {date_str}.")
    except Exception as e:
        print(f"    ERROR during daily summary: {e}")

async def create_weekly_summary(supabase: Client, openai_key: str, user_id: str, date_str: str):
    print(f"  - Weekly summary for {date_str}...")
    try:
        today_dt = datetime.strptime(date_str, '%Y-%m-%d')
        is_sunday = today_dt.weekday() == 6
        system_prompt = WEEKLY_REPORT_SUMMARY_PROMPT_NEURO if is_sunday else WEEKLY_REPORT_SUMMARY_PROMPT_STANDARD
        
        today = today_dt.replace(tzinfo=timezone.utc)
        start_date, end_date = today - timedelta(days=13), today + timedelta(days=1)

        sessions_res = supabase.table("sessions").select("id, created_at, g_score").eq("user_id", user_id).gte("created_at", start_date.isoformat()).lt("created_at", end_date.isoformat()).execute()
        if not sessions_res.data: return

        session_ids = [s['id'] for s in sessions_res.data]
        scores_res = supabase.table("cluster_scores").select("session_id, created_at, cluster, score").in_("session_id", session_ids).execute()

        sessions_with_scores = []
        scores_by_session_id = {sid: [] for sid in session_ids}
        for score in scores_res.data:
            scores_by_session_id.setdefault(score['session_id'], []).append(score)

        for session in sessions_res.data:
            session['cluster_scores'] = scores_by_session_id.get(session['id'], [])
            sessions_with_scores.append(session)
        
        daily_data = {}
        for i in range(14):
            day_key = (start_date + timedelta(days=i)).strftime('%Y-%m-%d')
            daily_data[day_key] = {'g_scores': [], 'clusters': {c: [] for c in CLUSTERS}}
        
        for session in sessions_with_scores:
            created_at_str = session['created_at'].split('+')[0]
            # ⭐️ [수정] 타임스탬프 형식 오류를 해결하기 위한 try-except 구문
            try:
                day = datetime.strptime(created_at_str, "%Y-%m-%dT%H:%M:%S.%f").strftime('%Y-%m-%d')
            except ValueError:
                day = datetime.strptime(created_at_str, "%Y-%m-%dT%H:%M:%S").strftime('%Y-%m-%d')
            
            if day in daily_data:
                if session['g_score'] is not None: daily_data[day]['g_scores'].append(session['g_score'])
                for score_data in session.get('cluster_scores', []):
                    if score_data['cluster'] in daily_data[day]['clusters']:
                        daily_data[day]['clusters'][score_data['cluster']].append(score_data['score'])
        
        g_scores = [np.mean(day['g_scores']) for day in daily_data.values() if day['g_scores']]
        cluster_stats = {}
        all_scores = []
        for c in CLUSTERS:
            daily_avgs = [np.mean(day['clusters'][c]) for day in daily_data.values() if day['clusters'][c]]
            if not daily_avgs: cluster_stats[c] = {"avg": 0, "std": 0, "trend": "stable"}; continue
            all_scores.extend([(c, s) for s in daily_avgs])
            x = np.arange(len(daily_avgs)); slope = np.polyfit(x, daily_avgs, 1)[0] if len(daily_avgs) > 1 else 0
            trend = "increasing" if slope > 0.05 else "decreasing" if slope < -0.05 else "stable"
            cluster_stats[c] = {"avg": int(np.mean(daily_avgs) * 100), "std": int(np.std(daily_avgs) * 100), "trend": trend}
        
        correlations = []
        if cluster_stats['sleep']['avg'] > 40 and cluster_stats['neg_low']['avg'] > 40: correlations.append("수면 문제와 우울/무기력감이 함께 높게 나타나는 경향이 있습니다.")
        if cluster_stats['neg_high']['avg'] > 40 and cluster_stats['sleep']['avg'] > 40: correlations.append("불안/긴장감이 높은 날, 수면 문제도 함께 증가하는 패턴이 보입니다.")
        if cluster_stats['neg_low']['trend'] == 'decreasing' and cluster_stats['positive']['trend'] == 'increasing': correlations.append("회복탄력성이 강화되고 있습니다. 우울감이 줄어들면서 긍정적 감정이 채워지고 있습니다.")
        
        dominant_clusters = list(set([item[0] for item in sorted(all_scores, key=lambda item: item[1], reverse=True)[:2]]))
        trend_data = {"g_score_stats": {"avg": int(np.mean(g_scores)*100) if g_scores else 0, "std": int(np.std(g_scores)*100) if g_scores else 0}, "cluster_stats": cluster_stats, "dominant_clusters": dominant_clusters, "correlations": correlations}
        
        nick, _ = await get_user_info(supabase, user_id)
        llm_ctx = { "user_nick_nm": nick, "trend_data": trend_data }
        summary_json = await call_llm(system_prompt, json.dumps(llm_ctx, ensure_ascii=False), openai_key)
        
        if summary_json and "error" not in summary_json:
            s_data = { "user_id": user_id, "summary_date": date_str, **summary_json }
            supabase.table("weekly_summaries").upsert(s_data, on_conflict="user_id,summary_date").execute()
            print(f"    Success: Weekly summary saved for {date_str}.")
    except Exception as e:
        print(f"    ERROR weekly summary: {e}")

# --- 백필 실행 함수 (날짜와 유저 매개변수 받는 버전) ---
async def run_backfill(start_date: str, end_date: str, user_id: str = None):
    dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
    load_dotenv(dotenv_path=dotenv_path)
    
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    OPENAI_KEY = os.getenv("OPENAI_API_KEY")

    if not all([SUPABASE_URL, SUPABASE_KEY, OPENAI_KEY]):
        print("오류: Supabase URL/Key 또는 OpenAI Key를 .env 파일에 올바르게 설정했는지 확인해주세요.")
        return

    # 날짜 유효성 검사
    try:
        start_dt = datetime.strptime(start_date, '%Y-%m-%d')
        end_dt = datetime.strptime(end_date, '%Y-%m-%d')
        if start_dt > end_dt:
            print("오류: 시작 날짜가 끝 날짜보다 늦습니다.")
            return {"error": "시작 날짜가 끝 날짜보다 늦습니다."}
    except ValueError as e:
        print(f"오류: 날짜 형식이 올바르지 않습니다. YYYY-MM-DD 형식으로 입력해주세요. {e}")
        return {"error": f"날짜 형식이 올바르지 않습니다: {e}"}

    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # user_id가 제공된 경우 해당 유저만 처리, 그렇지 않으면 모든 유저 처리
    if user_id:
        # 특정 유저가 존재하는지 확인
        response = supabase.table('user_profiles').select('id').eq('id', user_id).execute()
        if not response.data:
            print(f"오류: 사용자 ID '{user_id}'를 찾을 수 없습니다.")
            return {"error": f"사용자 ID '{user_id}'를 찾을 수 없습니다."}
        user_ids = [user_id]
        print(f"특정 사용자 {user_id[:8]}...에 대한 요약을 생성합니다.")
    else:
        response = supabase.table('user_profiles').select('id', count='exact').execute()
        if not response.data:
            print("사용자가 없습니다.")
            return {"error": "사용자가 없습니다."}
        user_ids = [user['id'] for user in response.data]
        print(f"모든 사용자({len(user_ids)}명)에 대한 요약을 생성합니다.")
    
    # 날짜 범위 계산
    current_date = start_dt
    total_days = (end_dt - start_dt).days + 1
    print(f"총 {len(user_ids)}명의 사용자에 대해 {start_date}부터 {end_date}까지 ({total_days}일) 요약을 생성합니다.")

    for user_id in user_ids:
        print(f"\n--- 사용자 {user_id[:8]}...의 요약 생성 시작 ---")
        current_date = start_dt  # 각 사용자마다 날짜 초기화
        
        while current_date <= end_dt:
            date_str = current_date.strftime('%Y-%m-%d')
            
            await create_daily_summary(supabase, OPENAI_KEY, user_id, date_str)
            await create_weekly_summary(supabase, OPENAI_KEY, user_id, date_str)
            
            current_date += timedelta(days=1)
            await asyncio.sleep(API_CALL_DELAY) 
    
    print("\n모든 과거 데이터 요약 생성이 완료되었습니다.")
    return {"success": True, "message": f"{start_date}부터 {end_date}까지의 요약 생성이 완료되었습니다.", "total_users": len(user_ids), "total_days": total_days}

# --- main 함수 (명령행 인자 지원) ---
async def main():
    parser = argparse.ArgumentParser(description='백필 서머리 생성 스크립트')
    parser.add_argument('--start-date', type=str, default=START_DATE, 
                       help='시작 날짜 (YYYY-MM-DD 형식, 기본값: 2024-01-01)')
    parser.add_argument('--end-date', type=str, default=END_DATE,
                       help='끝 날짜 (YYYY-MM-DD 형식, 기본값: 2024-12-31)')
    parser.add_argument('--user-id', type=str, default=None,
                       help='특정 사용자 ID (지정하지 않으면 모든 사용자 처리)')
    
    args = parser.parse_args()
    
    return await run_backfill(args.start_date, args.end_date, args.user_id)

if __name__ == "__main__":
    asyncio.run(main())