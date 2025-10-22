# run_backfill.py
import requests
import time

API_BASE_URL = "http://127.0.0.1:8000"
BACKFILL_ENDPOINT = f"{API_BASE_URL}/jobs/backfill"

# 시뮬레이션으로 데이터를 생성한 날짜 범위
payload = {
    "start_date": "2025-10-01",
    "end_date": "2025-10-21"
}

print(f"🚀 {BACKFILL_ENDPOINT} 에 백필 작업을 요청합니다...")
print(f"   (범위: {payload['start_date']} ~ {payload['end_date']})")
print("\n   [터미널 1] (main.py)에서 요약 생성 로그가 올라오는지 확인하세요.")
print("   이 작업은 LLM을 여러 번 호출하므로 시간이 1~2분 정도 걸릴 수 있습니다...")

try:
    # 타임아웃을 5분(300초)으로 넉넉하게 설정
    response = requests.post(BACKFILL_ENDPOINT, json=payload, timeout=300) 
    
    if response.status_code == 200:
        print("\n✅ 백필 작업 요청 성공!")
        print("   서버가 요약 생성을 완료했습니다.")
        print(response.json())
    else:
        print(f"\n❌ 백필 작업 요청 실패 (HTTP {response.status_code})")
        print(response.text)
        
except requests.exceptions.Timeout:
    print("\n❌ 작업 시간 초과 (Timeout)")
    print("   서버가 백그라운드에서 계속 실행 중일 수 있습니다. Supabase 'daily_summaries' 테이블을 확인해보세요.")
except requests.exceptions.RequestException as e:
    print(f"\n❌ API 서버 연결 실패: {e}")
    print("   [터미널 1]에서 main.py 서버가 실행 중인지 확인하세요.")