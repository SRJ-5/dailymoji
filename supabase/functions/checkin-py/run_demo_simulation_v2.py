# run_demo_simulation_v3.py (ADHD 로직 포함)
import os
import datetime as dt
import random
import json
import time
import uuid
from typing import Optional, List, Dict, Any # 👈 typing 임포트 추가
from dotenv import load_dotenv
from supabase import create_client, Client
import requests

# --- ⚠️ 중요 설정 ⚠️ ---
# 1. Apple 리뷰어에게 제공할 데모 계정의 Supabase User ID
DEMO_USER_ID = "0a04939b-6560-4793-b52f-f5f59a30c5b9" # 👈 사용자 ID 확인

# 2. 현재 실행 중인 main.py 서버의 주소
API_BASE_URL = "http://127.0.0.1:8000"
# -------------------------

# .env 파일 로드
load_dotenv()
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") # ‼️ service_role 키

if not SUPABASE_URL or not SUPABASE_KEY:
    raise EnvironmentError("SUPABASE_URL 또는 SUPABASE_KEY가 .env 파일에 설정되지 않았습니다.")

# Supabase 클라이언트 초기화
try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("✅ Supabase 클라이언트에 연결되었습니다.")
except Exception as e:
    print(f"❌ Supabase 연결 실패: {e}")
    exit()

# --- 상수 및 채팅 예시 ---
CLUSTER_TO_ICON = {
    "neg_low": "crying",
    "neg_high": "angry",
    "adhd": "shocked",
    "sleep": "sleeping",
    "positive": "smile",
}

CHAT_EXAMPLES = {
    "neg_low": ["아무것도 하고 싶지가 않고 그냥 침대에만 누워 있고 싶어. 하루 종일 피곤해.", "회사 일도 손에 안 잡히고, 예전엔 즐겁던 것도 이제는 다 재미없어.", "요즘 무기력하고 아무것도 하기 싫어.",],
    "neg_high": ["내일 발표 생각만 하면 가슴이 두근거리고 긴장돼서 미치겠어.", "사소한 일에도 짜증이 확 올라와. 주변 사람들한테 괜히 화내고 후회해.", "회사 가기 싫다… 요즘 스트레스 너무 받아서 자꾸 예민해지는 것 같아.",],
    "adhd_high": ["할게 너무많아서 정신이 없다. 다 집중이 안됨", "보고서를 쓰려고 앉았는데 10분도 못 가서 딴생각만 하고 집중이 안 돼.", "회의 중에 집중이 안 되고 자꾸 딴짓해. 할 일 미루다가 마감 직전."],
    "sleep": ["어제도 새벽 세 시가 넘도록 뒤척이다가 겨우 잠들었어. 오늘 개피곤하다", "주말마다 12시간씩 자는데도 계속 피곤해.", "요즘 잠을 거의 못자고 낮에도 졸려서 아무 의욕도 없고 그냥 꾸벅꾸벅 조는 병든닭같아.",],
    "positive": ["오늘 오랜만에 친구들이랑 수다 떨고 나니까 마음이 한결 가벼워졌어.", "운동 끝내고 나니까 상쾌하고 자신감도 좀 생긴 것 같아.", "아까 개웃긴 일 있었음ㅋㅋㅋ"]
}
# ADHD 3단계에서 사용할 할 일 텍스트
ADHD_TASK_DESCRIPTION = "곧 이사가서 집을 정리해야하는데 뭐부터 해야할지 전혀 모륵겠음. 집도 처분해야하고 짐도 싸야하고 근데 또 앱개발도 해야하고 친구들도 만나야함 ㅠ 할거개많음 건강보험도 정리해야해"

# --- Helper 함수: API 응답에서 봇 메시지 텍스트 추출 ---
def _get_bot_response_text(intervention: dict) -> Optional[str]:
    """API 응답(intervention)에서 실제 봇 메시지 텍스트를 추출합니다."""
    preset_id = intervention.get("preset_id")

    if preset_id == "FRIENDLY_REPLY": return intervention.get("text")
    if preset_id == "EMOJI_REACTION": return intervention.get("empathy_text")
    if preset_id == "ADHD_PRE_SOLUTION_QUESTION": return intervention.get("text")
    if preset_id == "ADHD_AWAITING_TASK_DESCRIPTION": return intervention.get("text")
    if preset_id == "ADHD_TASK_BREAKDOWN": return intervention.get("coaching_text") or intervention.get("mission_text")
    if preset_id == "SOLUTION_PROPOSAL":
        if "proposal_text" in intervention: return intervention.get("proposal_text")
        empathy = intervention.get("empathy_text", "")
        analysis = intervention.get("analysis_text", "")
        if empathy or analysis: return f"{empathy} {analysis}".strip()
    if preset_id == "SAFETY_CRISIS_MODAL": return intervention.get("analysis_text")

    print(f"⚠️ 알 수 없는 intervention 구조: {intervention}")
    return "..." # 추출 실패 시 기본 텍스트

# --- Helper 함수: DB에 메시지 저장 ---
def _insert_message(message_id: str, user_id: str, sender: str, content: str, msg_type: str, session_id: Optional[str] = None):
    """messages 테이블에 메시지 레코드를 삽입합니다."""
    try:
        supabase.table("messages").insert({
            "id": message_id, "user_id": user_id, "sender": sender,
            "content": content, "type": msg_type, "session_id": session_id
        }).execute()
        return True
    except Exception as e:
        print(f"    ❌ 메시지 저장 실패 (ID: ...{message_id[-6:]}): {e}")
        return False

# --- Helper 함수: 타임스탬프 업데이트 ---
def _update_timestamps(iso_timestamp: str, user_msg_id: Optional[str] = None, bot_msg_id: Optional[str] = None, session_id: Optional[str] = None):
    """관련 레코드들의 created_at을 업데이트합니다."""
    try:
        if user_msg_id:
            supabase.table("messages").update({"created_at": iso_timestamp}).eq("id", user_msg_id).execute()
        if bot_msg_id:
            supabase.table("messages").update({"created_at": iso_timestamp}).eq("id", bot_msg_id).execute()
        if session_id:
            supabase.table("sessions").update({"created_at": iso_timestamp}).eq("id", session_id).execute()
            supabase.table("cluster_scores").update({"created_at": iso_timestamp}).eq("session_id", session_id).execute()
        return True
    except Exception as e:
        print(f"    ❌ 타임스탬프 업데이트 실패: {e}")
        return False

# --- 메인 실행 함수 ---
def main():
    print(f"--- 🚀 실제 앱 흐름 모방 시뮬레이션 시작 (v3 - ADHD 로직 포함) ---")
    print(f"대상 User ID: {DEMO_USER_ID}")
    print(f"호출할 서버: {API_BASE_URL}")

    # 서버 연결 확인
    try:
        requests.get(API_BASE_URL, timeout=3)
        print(f"✅ API 서버({API_BASE_URL})에 연결되었습니다.")
    except requests.exceptions.ConnectionError:
        print(f"❌ API 서버({API_BASE_URL}) 연결 불가.")
        return

    # --- 날짜 설정 ---
    KST = dt.timezone(dt.timedelta(hours=9))
    START_DATE_KST = dt.datetime(2025, 10, 3, tzinfo=KST)
    END_DATE_KST = dt.datetime(2025, 10, 17, tzinfo=KST)
    target_data_days = 12
    total_days_in_range = (END_DATE_KST - START_DATE_KST).days + 1
    all_possible_dates = [START_DATE_KST + dt.timedelta(days=i) for i in range(total_days_in_range)]
    selected_dates = random.sample(all_possible_dates, min(target_data_days, len(all_possible_dates)))
    selected_dates.sort()
    print(f"\n지정된 날짜 범위: {START_DATE_KST.strftime('%Y-%m-%d')} ~ {END_DATE_KST.strftime('%Y-%m-%d')}")
    print(f"총 {total_days_in_range}일 중 {len(selected_dates)}일을 랜덤 선택하여 생성.")
    print(f"선택된 날짜(KST): {[d.strftime('%m-%d') for d in selected_dates]}")
    # --- 날짜 설정 완료 ---

    start_time = time.time()
    total_user_messages = 0
    total_bot_messages = 0
    total_sessions_created = 0

    for current_day_kst in selected_dates:
        num_chats_today = random.randint(1, 3)
        print(f"\n🗓  {current_day_kst.strftime('%Y-%m-%d')} (KST) - {num_chats_today}개의 대화 생성...")

        # 하루 내 대화 시간 관리를 위한 변수
        last_chat_time_kst = current_day_kst.replace(hour=9, minute=0, second=0, microsecond=0) # 오전 9시부터 시작

        for chat_idx in range(num_chats_today):
            # --- 대화 시간 설정 ---
            # 각 대화는 이전 대화보다 최소 10분 ~ 최대 3시간 뒤에 시작
            time_offset_minutes = random.randint(10, 180)
            chat_start_time_kst = last_chat_time_kst + dt.timedelta(minutes=time_offset_minutes)
            # 밤 11시 50분을 넘지 않도록 조정
            if chat_start_time_kst.hour >= 23 and chat_start_time_kst.minute > 50:
                 chat_start_time_kst = chat_start_time_kst.replace(hour=23, minute=random.randint(0,50))

            # --- 채팅 내용 선택 ---
            chosen_cluster = random.choice(list(CHAT_EXAMPLES.keys()))
            user_text_1 = random.choice(CHAT_EXAMPLES[chosen_cluster])
            icon_1 = CLUSTER_TO_ICON.get(chosen_cluster)

            # --- ADHD 특별 처리 ---
            if chosen_cluster == "adhd_high":
                print(f"  🧠 [{chat_start_time_kst.strftime('%H:%M')}] ADHD 3-Step 시뮬레이션 시작...")

                # --- 시간 설정 ---
                t_user_1 = chat_start_time_kst
                t_bot_1 = t_user_1 + dt.timedelta(seconds=random.randint(3, 7))
                t_user_2 = t_bot_1 + dt.timedelta(seconds=random.randint(5, 15)) # "예" 버튼 누르는 시간
                t_bot_2 = t_user_2 + dt.timedelta(seconds=random.randint(3, 7))
                t_user_3 = t_bot_2 + dt.timedelta(minutes=random.randint(1, 3)) # 할 일 입력 시간
                t_bot_3 = t_user_3 + dt.timedelta(seconds=random.randint(5, 10)) # LLM 호출 포함 시간

                # --- ID 생성 ---
                msg_id_user_1 = str(uuid.uuid4())
                msg_id_bot_1 = str(uuid.uuid4())
                msg_id_user_2 = str(uuid.uuid4())
                msg_id_bot_2 = str(uuid.uuid4())
                msg_id_user_3 = str(uuid.uuid4())
                msg_id_bot_3 = str(uuid.uuid4())

                session_id_1 = None
                session_id_2 = None # ADHD 3단계에서 생성되는 두 번째 세션

                try:
                    # --- 1단계: 최초 분석 요청 ---
                    print(f"    1) 👤({t_user_1.strftime('%H:%M')}) 사용자 입력: '{user_text_1[:20]}...'")
                    if not _insert_message(msg_id_user_1, DEMO_USER_ID, "user", user_text_1, "normal"): continue
                    total_user_messages += 1

                    payload_1 = {"user_id": DEMO_USER_ID, "text": user_text_1, "icon": icon_1, "language_code": "ko"}
                    response_1 = requests.post(f"{API_BASE_URL}/analyze", json=payload_1, timeout=30)
                    if response_1.status_code != 200: print(f"    ❌ API 1단계 실패: {response_1.text}"); continue
                    data_1 = response_1.json()
                    session_id_1 = data_1.get("session_id")
                    intervention_1 = data_1.get("intervention", {})
                    bot_text_1 = _get_bot_response_text(intervention_1)
                    adhd_context_1 = intervention_1.get("adhd_context")

                    if not bot_text_1 or not adhd_context_1: print(f"    ❌ API 1단계 응답 오류: {data_1}"); continue
                    print(f"    1) 🤖({t_bot_1.strftime('%H:%M')}) 봇 응답: '{bot_text_1[:20]}...' (세션: ...{session_id_1[-6:] if session_id_1 else '없음'})")
                    if not _insert_message(msg_id_bot_1, DEMO_USER_ID, "bot", bot_text_1, "normal", session_id_1): continue
                    total_bot_messages += 1
                    if session_id_1: total_sessions_created += 1

                    time.sleep(0.5)

                    # --- 2단계: "있어!" 버튼 클릭 시뮬레이션 ---
                    user_text_2 = "있어! 뭐부터 하면 좋을까?" # Flutter 라벨 텍스트 사용
                    print(f"    2) 👤({t_user_2.strftime('%H:%M')}) 사용자 입력: '{user_text_2}'")
                    if not _insert_message(msg_id_user_2, DEMO_USER_ID, "user", user_text_2, "normal"): continue
                    total_user_messages += 1

                    payload_2 = {"user_id": DEMO_USER_ID, "text": "adhd_has_task", "adhd_context": adhd_context_1}
                    response_2 = requests.post(f"{API_BASE_URL}/analyze", json=payload_2, timeout=30)
                    if response_2.status_code != 200: print(f"    ❌ API 2단계 실패: {response_2.text}"); continue
                    data_2 = response_2.json()
                    intervention_2 = data_2.get("intervention", {})
                    bot_text_2 = _get_bot_response_text(intervention_2)
                    adhd_context_2 = intervention_2.get("adhd_context")

                    if not bot_text_2 or not adhd_context_2: print(f"    ❌ API 2단계 응답 오류: {data_2}"); continue
                    print(f"    2) 🤖({t_bot_2.strftime('%H:%M')}) 봇 응답: '{bot_text_2[:20]}...'")
                    if not _insert_message(msg_id_bot_2, DEMO_USER_ID, "bot", bot_text_2, "normal"): continue
                    total_bot_messages += 1

                    time.sleep(0.5)

                    # --- 3단계: 할 일 상세 내용 입력 ---
                    user_text_3 = ADHD_TASK_DESCRIPTION
                    print(f"    3) 👤({t_user_3.strftime('%H:%M')}) 사용자 입력: '{user_text_3[:20]}...'")
                    if not _insert_message(msg_id_user_3, DEMO_USER_ID, "user", user_text_3, "normal"): continue
                    total_user_messages += 1

                    payload_3 = {"user_id": DEMO_USER_ID, "text": user_text_3, "adhd_context": adhd_context_2}
                    response_3 = requests.post(f"{API_BASE_URL}/analyze", json=payload_3, timeout=30)
                    if response_3.status_code != 200: print(f"    ❌ API 3단계 실패: {response_3.text}"); continue
                    data_3 = response_3.json()
                    session_id_2 = data_3.get("session_id")
                    intervention_3 = data_3.get("intervention", {})
                    bot_text_3 = _get_bot_response_text(intervention_3) # coaching_text 또는 mission_text

                    if not bot_text_3: print(f"    ❌ API 3단계 응답 오류: {data_3}"); continue
                    print(f"    3) 🤖({t_bot_3.strftime('%H:%M')}) 봇 응답: '{bot_text_3[:20]}...' (세션: ...{session_id_2[-6:] if session_id_2 else '없음'})")
                    if not _insert_message(msg_id_bot_3, DEMO_USER_ID, "bot", bot_text_3, "normal", session_id_2): continue
                    total_bot_messages += 1
                    if session_id_2: total_sessions_created += 1

                    # --- 타임스탬프 업데이트 ---
                    print(f"    🕒 타임스탬프 업데이트 중...")
                    _update_timestamps(t_user_1.astimezone(dt.timezone.utc).isoformat(), user_msg_id=msg_id_user_1, session_id=session_id_1)
                    _update_timestamps(t_bot_1.astimezone(dt.timezone.utc).isoformat(), bot_msg_id=msg_id_bot_1)
                    _update_timestamps(t_user_2.astimezone(dt.timezone.utc).isoformat(), user_msg_id=msg_id_user_2)
                    _update_timestamps(t_bot_2.astimezone(dt.timezone.utc).isoformat(), bot_msg_id=msg_id_bot_2)
                    _update_timestamps(t_user_3.astimezone(dt.timezone.utc).isoformat(), user_msg_id=msg_id_user_3, session_id=session_id_2) # 세션2는 사용자3 시점
                    _update_timestamps(t_bot_3.astimezone(dt.timezone.utc).isoformat(), bot_msg_id=msg_id_bot_3)

                    print(f"    ✅ ADHD 시뮬레이션 성공!")
                    last_chat_time_kst = t_bot_3 # 다음 대화 시작 시간 기준

                except requests.exceptions.RequestException as e: print(f"    ❌ ADHD 중 API 예외: {e}")
                except Exception as e: print(f"    ❌ ADHD 중 DB 예외: {e}")

            # --- 일반 클러스터 처리 ---
            else:
                print(f"  - [{chat_start_time_kst.strftime('%H:%M')}] 일반 대화 시작: '{user_text_1[:20]}...'")

                # --- 시간 설정 ---
                t_user_1 = chat_start_time_kst
                t_bot_1 = t_user_1 + dt.timedelta(seconds=random.randint(3, 7))

                # --- ID 생성 ---
                msg_id_user_1 = str(uuid.uuid4())
                msg_id_bot_1 = str(uuid.uuid4())
                session_id_1 = None

                try:
                    # 1. 사용자 메시지 저장
                    if not _insert_message(msg_id_user_1, DEMO_USER_ID, "user", user_text_1, "normal"): continue
                    total_user_messages += 1

                    # 2. API 호출
                    payload_1 = {"user_id": DEMO_USER_ID, "text": user_text_1, "icon": icon_1, "language_code": "ko"}
                    response_1 = requests.post(f"{API_BASE_URL}/analyze", json=payload_1, timeout=30)
                    if response_1.status_code != 200: print(f"    ❌ API 호출 실패: {response_1.text}"); continue
                    data_1 = response_1.json()
                    session_id_1 = data_1.get("session_id")
                    intervention_1 = data_1.get("intervention", {})
                    bot_text_1 = _get_bot_response_text(intervention_1)

                    if not bot_text_1: print(f"    ❌ API 응답 오류: {data_1}"); continue

                    # 3. 봇 메시지 저장
                    print(f"    🤖({t_bot_1.strftime('%H:%M')}) 봇 응답: '{bot_text_1[:20]}...' (세션: ...{session_id_1[-6:] if session_id_1 else '없음'})")
                    if not _insert_message(msg_id_bot_1, DEMO_USER_ID, "bot", bot_text_1, "normal", session_id_1): continue
                    total_bot_messages += 1
                    if session_id_1: total_sessions_created += 1

                    # 4. 타임스탬프 업데이트
                    print(f"    🕒 타임스탬프 업데이트 중...")
                    _update_timestamps(t_user_1.astimezone(dt.timezone.utc).isoformat(), user_msg_id=msg_id_user_1, session_id=session_id_1)
                    _update_timestamps(t_bot_1.astimezone(dt.timezone.utc).isoformat(), bot_msg_id=msg_id_bot_1)

                    print(f"    ✅ 일반 대화 성공!")
                    last_chat_time_kst = t_bot_1 # 다음 대화 시작 시간 기준

                except requests.exceptions.RequestException as e: print(f"    ❌ API 호출 중 예외: {e}")
                except Exception as e: print(f"    ❌ DB 작업 중 예외: {e}")

            time.sleep(random.uniform(0.5, 1.5)) # 다음 대화(또는 다음 날) 전 잠시 대기

    end_time = time.time()
    print(f"\n--- 🚀 시뮬레이션 완료 ---")
    print(f"총 사용자 메시지 {total_user_messages}개, 봇 메시지 {total_bot_messages}개를 생성했습니다.")
    print(f"총 {total_sessions_created}개의 세션이 생성되었습니다. (ADHD는 2개 세션 카운트)")
    print(f"총 소요 시간: {end_time - start_time:.2f}초")

if __name__ == "__main__":
    main()