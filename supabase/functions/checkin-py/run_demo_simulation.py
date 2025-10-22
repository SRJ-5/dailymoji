# run_demo_simulation.py
import os
import datetime as dt
import random
import json
import time
from dotenv import load_dotenv
from supabase import create_client, Client
import requests 

# --- ⚠️ 중요 설정 ⚠️ ---
# 1. Apple 리뷰어에게 제공할 데모 계정의 Supabase User ID
# (예: "123e4567-e89b-12d3-a456-426614174000")
DEMO_USER_ID = "0a04939b-6560-4793-b52f-f5f59a30c5b9" 

# 2. 현재 실행 중인 main.py 서버의 주소
API_BASE_URL = "http://127.0.0.1:8000"
# -------------------------

# .env 파일에서 Supabase 환경 변수 로드 (DB 업데이트용)
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") # ‼️ service_role 키여야 합니다 ‼️

if not SUPABASE_URL or not SUPABASE_KEY:
    raise EnvironmentError("SUPABASE_URL 또는 SUPABASE_KEY가 .env 파일에 설정되지 않았습니다.")
if DEMO_USER_ID == "YOUR_DEMO_USER_ID_HERE":
    raise ValueError("스크립트 상단의 `DEMO_USER_ID`를 실제 데모 계정 ID로 변경해주세요.")

# Supabase 클라이언트 초기화 (타임스탬프 업데이트용)
try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("✅ Supabase 클라이언트에 연결되었습니다.")
except Exception as e:
    print(f"❌ Supabase 연결 실패: {e}")
    exit()

# --- main.py에서 가져온 상수 ---
CLUSTER_TO_ICON = {
    "neg_low": "crying",
    "neg_high": "angry",
    "adhd": "shocked",
    "sleep": "sleeping",
    "positive": "smile",
}

# --- 채팅 예시 데이터 ---
# (ADHD 예시를 "할일 너무 많음"으로 변경)
CHAT_EXAMPLES = {
    "neg_low": [
        "아무것도 하고 싶지가 않고 그냥 침대에만 누워 있고 싶어. 하루 종일 피곤해.",
        "회사 일도 손에 안 잡히고, 예전엔 즐겁던 것도 이제는 다 재미없어.",
        "요즘 무기력하고 아무것도 하기 싫어.",
    ],
    "neg_high": [
        "내일 발표 생각만 하면 가슴이 두근거리고 긴장돼서 미치겠어.",
        "사소한 일에도 짜증이 확 올라와. 주변 사람들한테 괜히 화내고 후회해.",
        "회사 가기 싫다… 요즘 스트레스 너무 받아서 자꾸 예민해지는 것 같아.",
    ],
    "adhd_high": [
        "할게 너무많아서 정신이 없다. 다 집중이 안됨",
        "보고서를 쓰려고 앉았는데 10분도 못 가서 딴생각만 하고 집중이 안 돼.",
        "회의 중에 집중이 안 되고 자꾸 딴짓해. 할 일 미루다가 마감 직전."
    ],
    "sleep": [
        "어제도 새벽 세 시가 넘도록 뒤척이다가 겨우 잠들었어. 오늘 개피곤하다",
        "주말마다 12시간씩 자는데도 계속 피곤해.",
        "요즘 잠을 거의 못자고 낮에도 졸려서 아무 의욕도 없고 그냥 꾸벅꾸벅 조는 병든닭같아.",
    ],
    "positive": [
        "오늘 오랜만에 친구들이랑 수다 떨고 나니까 마음이 한결 가벼워졌어.",
        "운동 끝내고 나니까 상쾌하고 자신감도 좀 생긴 것 같아.",
        "아까 개웃긴 일 있었음ㅋㅋㅋ"
    ]
}

def main():
    """
    메인 실행 함수
    """
    print(f"--- 🚀 실제 분석 API 호출 시뮬레이션을 시작합니다 ---")
    print(f"대상 User ID: {DEMO_USER_ID}")
    print(f"호출할 서버: {API_BASE_URL}")

    # 서버가 실행 중인지 간단히 확인
    try:
        requests.get(API_BASE_URL, timeout=3)
        print(f"✅ API 서버({API_BASE_URL})에 연결되었습니다.")
    except requests.exceptions.ConnectionError:
        print(f"❌ API 서버({API_BASE_URL})에 연결할 수 없습니다.")
        print("    [터미널 1]에서 `uvicorn main:app --reload`를 실행했는지 확인해주세요.")
        return

    # --- 날짜 로직 (8월 10일 ~ 25일 중 12일) ---
    KST = dt.timezone(dt.timedelta(hours=9))
    START_DATE_KST = dt.datetime(2025, 10, 3, tzinfo=KST)
    END_DATE_KST = dt.datetime(2025, 10, 17, tzinfo=KST)
    target_data_days = 12
    
    total_days_in_range = (END_DATE_KST - START_DATE_KST).days + 1
    all_possible_dates = [START_DATE_KST + dt.timedelta(days=i) for i in range(total_days_in_range)]
    
    if len(all_possible_dates) < target_data_days:
        selected_dates = all_possible_dates
    else:
        selected_dates = random.sample(all_possible_dates, target_data_days)
    
    selected_dates.sort() 

    print(f"\n지정된 날짜 범위: {START_DATE_KST.strftime('%Y-%m-%d')} ~ {END_DATE_KST.strftime('%Y-%m-%d')}")
    print(f"총 {total_days_in_range}일 중 {len(selected_dates)}일을 랜덤으로 선택하여 데이터를 생성합니다.")
    print(f"선택된 날짜(KST): {[d.strftime('%m-%d') for d in selected_dates]}")
    # --- 날짜 로직 완료 ---

    start_time = time.time()
    total_sessions = 0
    
    for current_day_kst in selected_dates:
        
        num_chats_today = random.randint(1, 3)
        print(f"\n🗓  {current_day_kst.strftime('%Y-%m-%d')} (KST) - {num_chats_today}개의 채팅 생성...")
        
        for _ in range(num_chats_today):
            
            chosen_cluster = random.choice(list(CHAT_EXAMPLES.keys()))
            text = random.choice(CHAT_EXAMPLES[chosen_cluster])
            icon = CLUSTER_TO_ICON.get(chosen_cluster)
            
            # 첫 번째 대화의 시간 설정
            chat_time_kst_1 = current_day_kst.replace(
                hour=random.randint(9, 23),
                minute=random.randint(0, 59),
                second=random.randint(0, 59),
                microsecond=0
            )
            chat_time_utc_iso_1 = chat_time_kst_1.astimezone(dt.timezone.utc).isoformat()
            
            
            # --- 👇 ADHD 특별 처리 로직 👇 ---
            if chosen_cluster == "adhd_high":
                print(f"  🧠 [{chat_time_kst_1.strftime('%H:%M')}] ADHD 3-Step 시뮬레이션 시작: \"{text[:20]}...\"")
                
                try:
                    # --- 1단계: 최초 분석 (e.g., "할게 너무 많아") ---
                    # main.py는 이 채팅을 분석하고 점수와 함께 session_id_1을 생성,
                    # 그리고 adhd_context를 담아 응답
                    payload_1 = {"user_id": DEMO_USER_ID, "text": text, "icon": icon, "language_code": "ko"}
                    response_1 = requests.post(f"{API_BASE_URL}/analyze", json=payload_1, timeout=30)
                    response_data_1 = response_1.json()
                    session_id_1 = response_data_1.get("session_id")
                    intervention_1 = response_data_1.get("intervention", {})
                    adhd_context = intervention_1.get("adhd_context") # (step: "awaiting_choice")

                    if not session_id_1 or not adhd_context:
                        print(f"    ❌ 1단계 실패: 'session_id' 또는 'adhd_context' 없음. {response_data_1}")
                        continue

                    # 1단계 세션(점수 포함)의 타임스탬프를 과거로 업데이트
                    supabase.table("sessions").update({"created_at": chat_time_utc_iso_1}).eq("id", session_id_1).execute()
                    supabase.table("cluster_scores").update({"created_at": chat_time_utc_iso_1}).eq("session_id", session_id_1).execute()
                    print(f"    ✅ 1단계 성공 (Session: ...{session_id_1[-6:]}) -> 날짜 {chat_time_kst_1.strftime('%H:%M')}로 설정.")

                    time.sleep(random.uniform(1.0, 2.0)) # 봇 응답 시간 시뮬레이션

                    # --- 2단계: 사용자가 "있어!" 버튼 클릭 (adhd_has_task) ---
                    # main.py는 이 응답을 받고 session을 생성하지 *않고* 다음 질문(adhd_context_2)을 반환
                    payload_2 = {"user_id": DEMO_USER_ID, "text": "adhd_has_task", "adhd_context": adhd_context}
                    response_2 = requests.post(f"{API_BASE_URL}/analyze", json=payload_2, timeout=30)
                    response_data_2 = response_2.json()
                    intervention_2 = response_data_2.get("intervention", {})
                    adhd_context_2 = intervention_2.get("adhd_context") # (step: "awaiting_task_description")
                    
                    if not adhd_context_2:
                        print(f"    ❌ 2단계 실패: 'adhd_context' 없음. {response_data_2}")
                        continue
                    
                    print("    ✅ 2단계 성공: '있어!' 버튼 클릭 처리 완료.")
                    time.sleep(random.uniform(1.0, 2.0)) # 사용자 입력 시간 시뮬레이션

                    # --- 3단계: 사용자가 할 일 상세 내용 입력 (제공해주신 예시 사용) ---
                    # main.py는 이 텍스트로 LLM 호출(할 일 쪼개기) 후,
                    # *새로운* session_id_2 (마음 관리 팁 내용 포함)를 생성
                    task_text = "곧 이사가서 집을 정리해야하는데 뭐부터 해야할지 전혀 모륵겠음. 집도 처분해야하고 짐도 싸야하고 근데 또 앱개발도 해야하고 친구들도 만나야함 ㅠ 할거개많음 건강보험도 정리해야해"
                    chat_time_kst_2 = chat_time_kst_1 + dt.timedelta(minutes=2) # 2분 뒤 대화
                    chat_time_utc_iso_2 = chat_time_kst_2.astimezone(dt.timezone.utc).isoformat()

                    payload_3 = {"user_id": DEMO_USER_ID, "text": task_text, "adhd_context": adhd_context_2}
                    response_3 = requests.post(f"{API_BASE_URL}/analyze", json=payload_3, timeout=30)
                    response_data_3 = response_3.json()
                    session_id_2 = response_data_3.get("session_id") # (이게 2번째 세션 ID)

                    if not session_id_2:
                        print(f"    ❌ 3단계 실패: 'session_id' 없음. {response_data_3}")
                        continue
                    
                    # 3단계(마음 관리 팁) 세션의 타임스탬프를 2분 뒤로 업데이트
                    supabase.table("sessions").update({"created_at": chat_time_utc_iso_2}).eq("id", session_id_2).execute()
                    # (cluster_scores는 이 세션에 없음)
                    print(f"    ✅ 3단계 성공 (Session: ...{session_id_2[-6:]}) -> 날짜 {chat_time_kst_2.strftime('%H:%M')}로 설정.")
                    total_sessions += 2 # 이 대화로 총 2개의 세션이 생성됨
                
                except requests.exceptions.RequestException as e:
                    print(f"    ❌ ADHD 시뮬레이션 중 API 예외: {e}")
                except Exception as e:
                    print(f"    ❌ ADHD 시뮬레이션 중 DB 예외: {e}")

            # --- 👇 일반 클러스터 처리 로직 👇 ---
            else:
                payload = {"user_id": DEMO_USER_ID, "text": text, "icon": icon, "language_code": "ko"}
                try:
                    print(f"  - [{chat_time_kst_1.strftime('%H:%M')}] API 호출 중: \"{text[:20]}...\"")
                    response = requests.post(f"{API_BASE_URL}/analyze", json=payload, timeout=30)
                    
                    if response.status_code != 200:
                        print(f"    ❌ API 호출 실패 (HTTP {response.status_code}): {response.text}")
                        continue
                    
                    response_data = response.json()
                    session_id = response_data.get("session_id")
                    
                    if not session_id:
                        print(f"    ❌ API 응답에 'session_id'가 없습니다: {response_data}")
                        continue

                    supabase.table("sessions") \
                        .update({"created_at": chat_time_utc_iso_1}) \
                        .eq("id", session_id) \
                        .execute()
                        
                    supabase.table("cluster_scores") \
                        .update({"created_at": chat_time_utc_iso_1}) \
                        .eq("session_id", session_id) \
                        .execute()
                    
                    print(f"    ✅ 성공! (Session: ...{session_id[-6:]}) -> 날짜를 {chat_time_kst_1.strftime('%Y-%m-%d %H:%M')}로 덮어쓰기 완료.")
                    total_sessions += 1
                    
                    time.sleep(random.uniform(1.5, 3.0)) 

                except requests.exceptions.RequestException as e:
                    print(f"    ❌ API 호출 중 예외 발생: {e}")
                except Exception as e:
                    print(f"    ❌ DB 업데이트 중 예외 발생: {e}")

    end_time = time.time()
    print(f"\n--- 🚀 시뮬레이션 완료 ---")
    print(f"총 {total_sessions}개의 세션(ADHD 콤보 포함)을 실제 분석 로직을 통해 생성했습니다.")
    print(f"총 소요 시간: {end_time - start_time:.2f}초")


if __name__ == "__main__":
    main()