# run_demo_simulation_v8.py (Add Solution Feedback Message)
import os
import datetime as dt
import random
import json
import time
import uuid
from typing import Optional, List, Dict, Any
import traceback
from dotenv import load_dotenv
from supabase import create_client, Client
import requests

# --- ⚠️ 중요 설정 ⚠️ ---
DEMO_USER_ID = "0a04939b-6560-4793-b52f-f5f59a30c5b9"
API_BASE_URL = "http://127.0.0.1:8000"
# --- Fallback Texts --- (앱 코드에서 가져옴)
ASK_VIDEO_FEEDBACK = "이번 영상은 어떠셨나요?" # AppTextStrings.askVideoFeedback
FOLLOWUP_VIDEO_ENDED = "어때요? 좀 좋아진 것 같아요?😊" # Default message for video end
# -------------------------

# .env 파일 로드
load_dotenv(); SUPABASE_URL = os.getenv("SUPABASE_URL"); SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
if not SUPABASE_URL or not SUPABASE_KEY: raise EnvironmentError("Supabase URL/KEY 누락"); exit()

# Supabase 클라이언트 초기화
try: supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY); print("✅ Supabase 클라이언트에 연결.")
except Exception as e: print(f"❌ Supabase 연결 실패: {e}"); exit()

# --- 상수 및 채팅 예시 ---
CLUSTER_TO_ICON = { "neg_low": "crying", "neg_high": "angry", "adhd": "shocked", "sleep": "sleeping", "positive": "smile", "default": "default"}
CHAT_EXAMPLES = {
    "neg_low": ["아무것도 하고 싶지가 않고 그냥 침대에만 누워 있고 싶어. 하루 종일 피곤해.", "회사 일도 손에 안 잡히고, 예전엔 즐겁던 것도 이제는 다 재미없어.", {"type": "image", "key": "crying"}],
    "neg_high": ["내일 발표 생각만 하면 가슴이 두근거리고 긴장돼서 미치겠어.", "사소한 일에도 짜증이 확 올라와.", {"type": "image", "key": "angry"}],
    "adhd": ["할게 너무많아서 정신이 없다.", "보고서를 쓰려고 앉았는데 집중이 안 돼.", {"type": "image", "key": "shocked"}],
    "sleep": ["어제도 새벽 세 시가 넘도록 뒤척이다가 겨우 잠들었어.", "주말마다 12시간씩 자는데도 계속 피곤해.", {"type": "image", "key": "sleeping"}],
    "positive": ["오늘 오랜만에 친구들이랑 수다 떨고 나니까 마음이 한결 가벼워졌어.", "운동 끝내고 나니까 상쾌하고 자신감도 좀 생긴 것 같아.", {"type": "image", "key": "smile"}]
}
ADHD_TASK_DESCRIPTION = "곧 이사가서 집을 정리해야하는데 뭐부터 해야할지 전혀 모륵겠음. 집도 처분해야하고 짐도 싸야하고 근데 또 앱개발도 해야하고 친구들도 만나야함 ㅠ 할거개많음 건강보험도 정리해야해"
EMOJI_KEY_TO_ASSET = { "angry": "assets/images/emojis/angry.png", "crying": "assets/images/emojis/crying.png", "shocked": "assets/images/emojis/shocked.png", "sleeping": "assets/images/emojis/sleeping.png", "smile": "assets/images/emojis/smile.png", "default": "assets/images/emojis/default.png"}

# --- Helper 함수 정의 ---
def _get_bot_response_text(intervention: dict) -> Optional[str]:
    preset_id = intervention.get("preset_id")
    if preset_id == "FRIENDLY_REPLY": return intervention.get("text")
    if preset_id == "EMOJI_REACTION": return intervention.get("empathy_text")
    if preset_id in ["ADHD_PRE_SOLUTION_QUESTION", "ADHD_AWAITING_TASK_DESCRIPTION"]: return intervention.get("text")
    if preset_id == "ADHD_TASK_BREAKDOWN": return intervention.get("coaching_text")
    if preset_id == "SOLUTION_PROPOSAL":
        if "proposal_text" in intervention: return intervention.get("proposal_text")
        empathy = intervention.get("empathy_text", ""); analysis = intervention.get("analysis_text", "")
        if empathy or analysis: return f"{empathy} {analysis}".strip()
    if preset_id == "SAFETY_CRISIS_MODAL": return intervention.get("analysis_text")
    print(f"⚠️ 알 수 없는 intervention 구조 (텍스트 추출 실패): {intervention}"); return None

# ⭐ 수정: solution_id_for_feedback 파라미터 추가
def _insert_message(message_id: str, user_id: str, sender: str, content: str, msg_type: str = "normal", session_id: Optional[str] = None, proposal: Optional[Any] = None, image_path: Optional[str] = None, sol_id_feedback: Optional[str] = None) -> bool:
    try:
        data_to_insert = {"id": message_id, "user_id": user_id, "sender": sender, "content": content, "type": msg_type, "session_id": session_id, "image_asset_path": image_path, "solution_id_for_feedback": sol_id_feedback} # 👈 추가
        if proposal is not None: data_to_insert["proposal"] = json.dumps(proposal, ensure_ascii=False) if isinstance(proposal, dict) else proposal
        supabase.table("messages").insert(data_to_insert).execute()
        return True
    except Exception as e:
        if 'violates check constraint "type_check"' in str(e): print(f"    ❌ DB Error: 'messages' 테이블 'type' 컬럼에 '{msg_type}' 값 허용 안됨.")
        elif 'value too long' in str(e): print(f"    ❌ DB Error: '{content[:30]}...' 내용 컬럼 크기 초과.")
        else: print(f"    ❌ 메시지 저장 실패 (ID: ...{message_id[-6:]}): {e}")
        return False

def _update_message_session_id(msg_id: str, session_id: str) -> bool:
    if not msg_id or not session_id: return False
    try:
        result = supabase.table("messages").update({"session_id": session_id}).eq("id", msg_id).execute()
        return bool(result.data)
    except Exception as e: print(f"    ❌ 사용자 메시지 <-> 세션 ID 연결 예외: {e}"); return False

def _update_timestamps(iso_timestamp: str, msg_ids: List[str] = [], session_id: Optional[str] = None) -> bool:
    success = True; updated_msg_count, updated_sess_count, updated_score_count = 0, 0, 0
    if msg_ids:
        try: result = supabase.table("messages").update({"created_at": iso_timestamp}).in_("id", msg_ids).execute(); updated_msg_count = len(result.data) if result.data else 0
        except Exception as e_bulk:
            print(f"    ⚠️ 메시지 Bulk 업데이트 실패 ({e_bulk}), 개별 재시도...")
            success = False
            for msg_id in msg_ids:
                try: result = supabase.table("messages").update({"created_at": iso_timestamp}).eq("id", msg_id).execute(); updated_msg_count += len(result.data) if result.data else 0; success = True
                except Exception as e_single: print(f"    ❌ 메시지 {msg_id[-6:]} 업데이트 실패: {e_single}"); success = False
    if session_id:
        try:
            result_sess = supabase.table("sessions").update({"created_at": iso_timestamp}).eq("id", session_id).execute(); updated_sess_count = len(result_sess.data) if result_sess.data else 0
            if updated_sess_count == 0: print(f"    ❌ 세션 ...{session_id[-6:]} 업데이트 실패"); success = False
            result_score = supabase.table("cluster_scores").update({"created_at": iso_timestamp}).eq("session_id", session_id).execute(); updated_score_count = len(result_score.data) if result_score.data else 0
        except Exception as e_sess: print(f"    ❌ 세션/점수 ...{session_id[-6:]} 업데이트 예외: {e_sess}"); success = False
    log_msg = f"    🕒 타임스탬프 업데이트: "
    if msg_ids: log_msg += f"메시지 {updated_msg_count}/{len(msg_ids)}개 "
    if session_id: log_msg += f"세션 {updated_sess_count}/1개 점수 {updated_score_count}개"
    if not success: log_msg += " (⚠️ 실패 포함!)"
    print(log_msg)
    return success

# --- 메인 실행 함수 ---
def main():
    print(f"--- 🚀 실제 앱 흐름 모방 시뮬레이션 시작 (v8 - Add Feedback Msg) ---")
    print(f"대상 User ID: {DEMO_USER_ID}"); print(f"호출할 서버: {API_BASE_URL}")
    try: requests.get(API_BASE_URL, timeout=3); print(f"✅ API 서버({API_BASE_URL}) 연결 성공.")
    except requests.exceptions.ConnectionError: print(f"❌ API 서버({API_BASE_URL}) 연결 불가."); return

    # --- 날짜 설정 ---
    KST = dt.timezone(dt.timedelta(hours=9)); START_DATE_KST = dt.datetime(2025, 10, 3, tzinfo=KST); END_DATE_KST = dt.datetime(2025, 10, 17, tzinfo=KST); target_data_days = 12
    total_days_in_range = (END_DATE_KST - START_DATE_KST).days + 1; all_possible_dates = [START_DATE_KST + dt.timedelta(days=i) for i in range(total_days_in_range)]
    selected_dates = random.sample(all_possible_dates, min(target_data_days, len(all_possible_dates))); selected_dates.sort()
    print(f"\n날짜 범위: {START_DATE_KST.strftime('%Y-%m-%d')} ~ {END_DATE_KST.strftime('%Y-%m-%d')} ({len(selected_dates)}/{total_days_in_range}일 생성)")
    print(f"선택된 날짜(KST): {[d.strftime('%m-%d') for d in selected_dates]}")
    # --- 날짜 설정 완료 ---

    start_time = time.time(); total_user_messages, total_bot_messages, total_sessions_created = 0, 0, 0

    for current_day_kst in selected_dates:
        num_chats_today = random.randint(1, 3); print(f"\n🗓  {current_day_kst.strftime('%Y-%m-%d')} (KST) - {num_chats_today}개 대화 생성...")
        last_chat_time_kst = current_day_kst.replace(hour=9, minute=0)

        for chat_idx in range(num_chats_today):
            time_offset_minutes = random.randint(10, 180); chat_start_time_kst = last_chat_time_kst + dt.timedelta(minutes=time_offset_minutes)
            if chat_start_time_kst.hour >= 23 and chat_start_time_kst.minute > 50: chat_start_time_kst = chat_start_time_kst.replace(hour=23, minute=random.randint(0,50))

            chosen_cluster = random.choice(list(CHAT_EXAMPLES.keys())); user_input = random.choice(CHAT_EXAMPLES[chosen_cluster])
            is_image_input = isinstance(user_input, dict) and user_input.get("type") == "image"; user_text_1 = "" if is_image_input else user_input
            icon_key = user_input.get("key") if is_image_input else CLUSTER_TO_ICON.get(chosen_cluster, "default")
            image_path = EMOJI_KEY_TO_ASSET.get(icon_key) if is_image_input else None

            t_user_1 = chat_start_time_kst; msg_id_user_1 = str(uuid.uuid4()); session_id_1, session_id_2 = None, None
            all_msg_ids_in_convo = [msg_id_user_1]; time_map = {msg_id_user_1: t_user_1}; bot_message_count = 0

            try:
                # 1. 사용자 메시지 저장
                print(f"  - [{t_user_1.strftime('%H:%M')}] 👤 사용자: '{user_text_1[:20] if not is_image_input else f'({icon_key} 이모지)'}...'")
                if not _insert_message(msg_id_user_1, DEMO_USER_ID, "user", user_text_1, msg_type="image" if is_image_input else "normal", image_path=image_path): continue
                total_user_messages += 1

                # 2. /analyze API 호출
                payload_1 = {"user_id": DEMO_USER_ID, "text": user_text_1, "icon": icon_key, "language_code": "ko"}
                response_1 = requests.post(f"{API_BASE_URL}/analyze", json=payload_1, timeout=30)
                if response_1.status_code != 200: print(f"    ❌ API /analyze 실패: {response_1.text}"); continue
                data_1 = response_1.json(); session_id_1 = data_1.get("session_id"); intervention_1 = data_1.get("intervention", {}); preset_id = intervention_1.get("preset_id")
                if session_id_1:
                    total_sessions_created += 1
                    if not _update_message_session_id(msg_id_user_1, session_id_1): print(f"    ⚠️ 사용자 메시지 ...{msg_id_user_1[-6:]} <-> 세션 ID 연결 실패!")

                current_bot_time = t_user_1 + dt.timedelta(seconds=random.randint(3, 7))

                # --- 3. API 응답 기반 봇 메시지 저장 ---

                # Case A: 단일 응답
                if preset_id in ["FRIENDLY_REPLY", "EMOJI_REACTION", "SAFETY_CRISIS_MODAL"]:
                    bot_text_1 = _get_bot_response_text(intervention_1)
                    if not bot_text_1: print(f"    ❌ 단일 응답 텍스트 추출 실패: {data_1}"); continue
                    print(f"    🤖({current_bot_time.strftime('%H:%M')}) 봇 (단일): '{bot_text_1[:20]}...'")
                    msg_type = "solution_proposal" if preset_id == "SAFETY_CRISIS_MODAL" else "normal"
                    proposal_data = intervention_1 if preset_id == "SAFETY_CRISIS_MODAL" else None
                    msg_id_bot = str(uuid.uuid4())
                    if _insert_message(msg_id_bot, DEMO_USER_ID, "bot", bot_text_1, msg_type=msg_type, session_id=session_id_1, proposal=proposal_data): total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot); time_map[msg_id_bot] = current_bot_time; bot_message_count += 1; last_chat_time_kst = current_bot_time
                    else: continue

                # Case B: 분석 후 마음 관리 팁 제안 (공감->분석->제안->[피드백])
                elif preset_id == "SOLUTION_PROPOSAL":
                    empathy_text = intervention_1.get("empathy_text"); analysis_text = intervention_1.get("analysis_text"); top_cluster = intervention_1.get("top_cluster")
                    if empathy_text:
                        msg_id_bot = str(uuid.uuid4()); print(f"    🤖({current_bot_time.strftime('%H:%M')}) 봇 (공감): '{empathy_text[:20]}...'")
                        if _insert_message(msg_id_bot, DEMO_USER_ID, "bot", empathy_text, session_id=session_id_1): total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot); time_map[msg_id_bot] = current_bot_time; bot_message_count += 1; current_bot_time += dt.timedelta(seconds=random.randint(1, 3))
                        else: continue
                    if analysis_text:
                        msg_id_bot = str(uuid.uuid4()); print(f"    🤖({current_bot_time.strftime('%H:%M')}) 봇 (분석): '{analysis_text[:20]}...'")
                        if _insert_message(msg_id_bot, DEMO_USER_ID, "bot", analysis_text, session_id=session_id_1): total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot); time_map[msg_id_bot] = current_bot_time; bot_message_count += 1; current_bot_time += dt.timedelta(seconds=random.randint(4, 8))
                        else: continue
                    if session_id_1 and top_cluster:
                        print(f"    📞 ({current_bot_time.strftime('%H:%M')}) API /solutions/propose 호출...")
                        payload_propose = {"user_id": DEMO_USER_ID, "session_id": session_id_1, "top_cluster": top_cluster}; response_propose = requests.post(f"{API_BASE_URL}/solutions/propose", json=payload_propose, timeout=30)
                        if response_propose.status_code == 200:
                            data_propose = response_propose.json(); proposal_text = data_propose.get("proposal_text"); proposal_options = data_propose.get("options")
                            if proposal_text and proposal_options:
                                msg_id_bot_prop = str(uuid.uuid4()); print(f"    🤖({current_bot_time.strftime('%H:%M')}) 봇 (제안): '{proposal_text[:20]}...'")
                                proposal_data_for_db = {"session_id": session_id_1, "options": proposal_options}
                                if _insert_message(msg_id_bot_prop, DEMO_USER_ID, "bot", proposal_text, msg_type="solution_proposal", session_id=session_id_1, proposal=proposal_data_for_db):
                                    total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot_prop); time_map[msg_id_bot_prop] = current_bot_time; bot_message_count += 1; last_chat_time_kst = current_bot_time
                                    # ⭐ [수정] 동영상 마음 관리 팁이 포함된 경우, 후속 메시지 및 피드백 요청 추가
                                    video_option = next((opt for opt in proposal_options if opt.get("solution_type") == "video"), None)
                                    if video_option:
                                        video_solution_id = video_option.get("solution_id")
                                        current_bot_time += dt.timedelta(seconds=random.randint(5, 10)) # 영상 본 후 시간 가정
                                        msg_id_bot_followup = str(uuid.uuid4()); print(f"    🤖({current_bot_time.strftime('%H:%M')}) 봇 (후속 질문): '{FOLLOWUP_VIDEO_ENDED[:20]}...'")
                                        if _insert_message(msg_id_bot_followup, DEMO_USER_ID, "bot", FOLLOWUP_VIDEO_ENDED, session_id=session_id_1): total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot_followup); time_map[msg_id_bot_followup] = current_bot_time; bot_message_count += 1
                                        else: continue # 후속 질문 실패 시 피드백도 건너뜀
                                        current_bot_time += dt.timedelta(seconds=random.randint(1, 3))
                                        msg_id_bot_feedback = str(uuid.uuid4()); print(f"    🤖({current_bot_time.strftime('%H:%M')}) 봇 (피드백 요청): '{ASK_VIDEO_FEEDBACK[:20]}...'")
                                        # Feedback 메시지 저장 시 proposal과 solution_id_for_feedback 설정
                                        feedback_proposal = {"session_id": session_id_1, "solution_id": video_solution_id, "solution_type": "video"}
                                        if _insert_message(msg_id_bot_feedback, DEMO_USER_ID, "bot", ASK_VIDEO_FEEDBACK, msg_type="solution_feedback", session_id=session_id_1, proposal=feedback_proposal, sol_id_feedback=video_solution_id): # 👈 수정
                                            total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot_feedback); time_map[msg_id_bot_feedback] = current_bot_time; bot_message_count += 1; last_chat_time_kst = current_bot_time
                                        else: last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1) # 피드백 실패 시 이전 메시지 시간
                                else: last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1) # 제안 저장 실패
                            else: print(f"    ⚠️ /propose 응답 형식 오류: {data_propose}"); last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)
                        else: print(f"    ❌ API /solutions/propose 실패: {response_propose.text}"); last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)
                    else: print(f"    ⚠️ /propose 호출 건너뜀"); last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)

                # Case C: ADHD 1단계 응답 (질문 + 버튼)
                elif preset_id == "ADHD_PRE_SOLUTION_QUESTION":
                    print(f"    🤖({current_bot_time.strftime('%H:%M')}) 봇 (ADHD 질문): '할 일이 있나요?'")
                    msg_id_bot_1 = str(uuid.uuid4())
                    if _insert_message(msg_id_bot_1, DEMO_USER_ID, "bot", "", msg_type="solution_proposal", session_id=session_id_1, proposal=intervention_1):
                        total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot_1); time_map[msg_id_bot_1] = current_bot_time; bot_message_count += 1
                        adhd_context_1 = intervention_1.get("adhd_context")
                        if adhd_context_1: # --- ADHD 2 & 3단계 ---
                            t_user_2 = current_bot_time + dt.timedelta(seconds=random.randint(5, 15)); user_text_2 = "있어! 뭐부터 하면 좋을까?"; msg_id_user_2 = str(uuid.uuid4())
                            print(f"    👤({t_user_2.strftime('%H:%M')}) 사용자: '{user_text_2}'")
                            if not _insert_message(msg_id_user_2, DEMO_USER_ID, "user", user_text_2, session_id=session_id_1): continue
                            total_user_messages += 1; all_msg_ids_in_convo.append(msg_id_user_2); time_map[msg_id_user_2] = t_user_2
                            t_bot_2 = t_user_2 + dt.timedelta(seconds=random.randint(3, 7))
                            payload_2 = {"user_id": DEMO_USER_ID, "text": "adhd_has_task", "adhd_context": adhd_context_1}; response_2 = requests.post(f"{API_BASE_URL}/analyze", json=payload_2, timeout=30)
                            if response_2.status_code == 200:
                                data_2 = response_2.json(); intervention_2 = data_2.get("intervention", {}); bot_text_2 = _get_bot_response_text(intervention_2); adhd_context_2 = intervention_2.get("adhd_context")
                                if bot_text_2 and adhd_context_2:
                                    msg_id_bot_2 = str(uuid.uuid4()); print(f"    🤖({t_bot_2.strftime('%H:%M')}) 봇: '{bot_text_2[:20]}...'")
                                    if _insert_message(msg_id_bot_2, DEMO_USER_ID, "bot", bot_text_2, session_id=session_id_1): total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot_2); time_map[msg_id_bot_2] = t_bot_2; bot_message_count += 1
                                    else: continue
                                    t_user_3 = t_bot_2 + dt.timedelta(minutes=random.randint(1, 3)); user_text_3 = ADHD_TASK_DESCRIPTION; msg_id_user_3 = str(uuid.uuid4())
                                    print(f"    👤({t_user_3.strftime('%H:%M')}) 사용자: '{user_text_3[:20]}...'")
                                    if not _insert_message(msg_id_user_3, DEMO_USER_ID, "user", user_text_3, session_id=session_id_1): continue # 아직 세션2 전이므로 세션1 연결 시도
                                    total_user_messages += 1; all_msg_ids_in_convo.append(msg_id_user_3); time_map[msg_id_user_3] = t_user_3
                                    t_bot_3a = t_user_3 + dt.timedelta(seconds=random.randint(5, 10)); t_bot_3b = t_bot_3a + dt.timedelta(seconds=random.randint(1, 3))
                                    payload_3 = {"user_id": DEMO_USER_ID, "text": user_text_3, "adhd_context": adhd_context_2}; response_3 = requests.post(f"{API_BASE_URL}/analyze", json=payload_3, timeout=30)
                                    if response_3.status_code == 200:
                                        data_3 = response_3.json(); session_id_2 = data_3.get("session_id"); intervention_3 = data_3.get("intervention", {})
                                        if session_id_2:
                                             total_sessions_created += 1
                                             if not _update_message_session_id(msg_id_user_3, session_id_2): print(f"    ⚠️ ADHD 3단계 사용자 메시지 <-> 세션 ID 2 연결 실패!")
                                        coaching_text = intervention_3.get("coaching_text"); mission_text = intervention_3.get("mission_text"); options_3 = intervention_3.get("options")
                                        if coaching_text:
                                            msg_id_bot_3a = str(uuid.uuid4()); print(f"    🤖({t_bot_3a.strftime('%H:%M')}) 봇 (코칭): '{coaching_text[:20]}...'")
                                            if _insert_message(msg_id_bot_3a, DEMO_USER_ID, "bot", coaching_text, session_id=session_id_2): total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot_3a); time_map[msg_id_bot_3a] = t_bot_3a; bot_message_count += 1
                                            else: continue
                                        if mission_text and options_3:
                                            msg_id_bot_3b = str(uuid.uuid4()); print(f"    🤖({t_bot_3b.strftime('%H:%M')}) 봇 (미션): '{mission_text[:20]}...'")
                                            proposal_data_3 = {"session_id": session_id_2, "options": options_3}
                                            # ⭐ 수정: ADHD 미션 메시지도 solution_proposal 타입
                                            if _insert_message(msg_id_bot_3b, DEMO_USER_ID, "bot", mission_text, msg_type="solution_proposal", session_id=session_id_2, proposal=proposal_data_3): total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot_3b); time_map[msg_id_bot_3b] = t_bot_3b; bot_message_count += 1; last_chat_time_kst = t_bot_3b
                                            else: last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)
                                        else: print(f"    ⚠️ ADHD 3단계 응답 형식 오류(미션/옵션): {data_3}"); last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)
                                    else: print(f"    ❌ API 3단계 실패: {response_3.text}"); last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)
                                else: print(f"    ⚠️ ADHD 2단계 응답 형식 오류: {data_2}"); last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)
                            else: print(f"    ❌ API 2단계 실패: {response_2.text}"); last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)
                        else: print(f"    ⚠️ ADHD 1단계 응답 컨텍스트 없음: {data_1}"); last_chat_time_kst = time_map.get(all_msg_ids_in_convo[-1], t_user_1)
                    else: continue # ADHD 1단계 봇 메시지 저장 실패

                # Case D: 기타 알 수 없는 Preset ID
                else:
                    print(f"    ❓ 처리되지 않은 Preset ID: {preset_id}")
                    bot_text_unknown = _get_bot_response_text(intervention_1) or "..."; msg_id_bot = str(uuid.uuid4())
                    print(f"    🤖({current_bot_time.strftime('%H:%M')}) 봇 (알수없음): '{bot_text_unknown[:20]}...'")
                    if _insert_message(msg_id_bot, DEMO_USER_ID, "bot", bot_text_unknown, session_id=session_id_1): total_bot_messages += 1; all_msg_ids_in_convo.append(msg_id_bot); time_map[msg_id_bot] = current_bot_time; bot_message_count += 1; last_chat_time_kst = current_bot_time
                    else: continue

                # --- 4. 타임스탬프 업데이트 ---
                if bot_message_count > 0:
                    update_success = True
                    # 생성된 모든 메시지 시간 업데이트 (time_map 사용)
                    for msg_id in all_msg_ids_in_convo:
                        if msg_id in time_map: update_success &= _update_timestamps(time_map[msg_id].astimezone(dt.timezone.utc).isoformat(), msg_ids=[msg_id])
                    # 세션 1 시간 업데이트 (사용자1 기준)
                    if session_id_1: update_success &= _update_timestamps(t_user_1.astimezone(dt.timezone.utc).isoformat(), session_id=session_id_1)
                    # 세션 2 시간 업데이트 (사용자3 기준)
                    if 'msg_id_user_3' in locals() and session_id_2 and msg_id_user_3 in time_map: update_success &= _update_timestamps(time_map[msg_id_user_3].astimezone(dt.timezone.utc).isoformat(), session_id=session_id_2)
                    if update_success: print(f"    ✅ 대화 흐름 완료!")
                    else: print(f"    ⚠️ 대화 흐름 완료 (타임스탬프 업데이트 일부 실패!)")
                else: print(f"    ⚠️ 봇 메시지 생성 실패로 타임스탬프 업데이트 건너뜀."); last_chat_time_kst = t_user_1

            except requests.exceptions.RequestException as e: print(f"    ❌ API 호출 중 예외: {e}")
            except Exception as e: print(f"    ❌ 처리 중 예외: {e}"); traceback.print_exc()
            time.sleep(random.uniform(0.5, 1.5))

    end_time = time.time()
    print(f"\n--- 🚀 시뮬레이션 완료 ---")
    print(f"총 사용자 메시지 {total_user_messages}개, 봇 메시지 {total_bot_messages}개를 생성했습니다.")
    print(f"총 {total_sessions_created}개의 세션이 생성되었습니다.")
    print(f"총 소요 시간: {end_time - start_time:.2f}초")

if __name__ == "__main__":
    main()