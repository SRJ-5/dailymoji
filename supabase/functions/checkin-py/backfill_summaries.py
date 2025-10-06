# backfill_summaries.py
import asyncio
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
import os
from supabase import create_client, Client

# ⭐️ main.py에서 요약 생성 함수들을 가져옵니다.
from main import create_and_save_summary_for_user, create_and_save_weekly_summary_for_user

async def main():
    load_dotenv()
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

    if not SUPABASE_URL or not SUPABASE_KEY:
        print("Supabase URL 또는 Key를 .env 파일에 설정해주세요.")
        return

    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # ⭐️ 요약을 생성할 기간 설정 (예: 최근 30일)
    days_to_backfill = 30
    
    # ⭐️ 모든 사용자 ID 가져오기
    response = supabase.table('user_profiles').select('id').execute()
    if not response.data:
        print("사용자가 없습니다.")
        return
        
    user_ids = [user['id'] for user in response.data]
    print(f"총 {len(user_ids)}명의 사용자에 대해 과거 {days_to_backfill}일치 요약을 생성합니다.")

    # ⭐️ 각 사용자의 각 날짜에 대해 요약 생성 함수 호출
    today = datetime.now(timezone.utc)
    for user_id in user_ids:
        print(f"\n--- {user_id} 사용자의 요약 생성 시작 ---")
        for i in range(1, days_to_backfill + 1):
            target_date = today - timedelta(days=i)
            date_str = target_date.strftime('%Y-%m-%d')
            
            # main.py의 함수들을 직접 호출
            await create_and_save_summary_for_user(user_id, date_str)
            await create_and_save_weekly_summary_for_user(user_id, date_str)
            
            # API 호출 제한을 피하기 위해 약간의 딜레이 추가
            await asyncio.sleep(1) 
    
    print("\n모든 과거 데이터 요약 생성이 완료되었습니다.")

if __name__ == "__main__":
    # main.py의 startup/shutdown 이벤트가 없으므로 직접 supabase 클라이언트를 함수 내에서 초기화
    # 또한, main.py의 함수들이 async이므로 asyncio로 실행
    asyncio.run(main())