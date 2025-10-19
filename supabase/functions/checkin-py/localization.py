import re

translations = {
    'ko': {
        # --- General Errors / Fallbacks ---
        "error_openai_key_not_found": "OpenAI API 키를 찾을 수 없습니다.",
        "error_llm_parsing_failed": "LLM 응답을 JSON으로 파싱하는데 실패했습니다.",
        "error_llm_call_failed": "LLM 호출에 실패했습니다: {error}",
        "error_moderation_api_failed": "Moderation API 호출 실패: {error}",
        "error_supabase_init": "Supabase 클라이언트를 초기화하지 못했습니다.",
        "error_inappropriate_content": "부적절한 콘텐츠가 감지되었습니다.",
        "error_solution_not_found": "마음 관리 팁 정보를 찾을 수 없습니다.",
        "error_loading_summary": "요약을 불러오는 중 오류가 발생했습니다.",
        "error_invalid_cluster": "잘못된 클러스터입니다: {cluster}",
        "error_occurred": "오류가 발생했습니다: {error}",

        "default_user_name": "사용자",
        "default_char_name": "버디",
        "default_analysis_message": "오늘 당신의 마음은 특별한 색을 띠고 있네요.",
        "default_reaction_message": "어떤 일 때문에 그렇게 느끼셨나요?",
        "default_propose_message": "이런 활동은 어떠세요?",
        "default_home_message": "안녕, {user_nick_nm}! 오늘 기분은 어때?",
        "default_followup_user_closed": "괜찮아요. 대화를 이어나갈까요?",
        "default_followup_video_ended": "어때요? 좀 좋아진 것 같아요?😊",
        "default_decline_solution": "알겠습니다. 편안하게 털어놓으세요.",
        "default_empathy_fallback": "마음을 살피는 중이에요...",
        "default_llm_friendly_fallback": "음... 지금은 잠시 생각할 시간이 필요해요!🥹",
        "default_sleep_tip": "규칙적인 수면 습관을 가져보세요.",
        "default_action_mission": "잠시 자리에서 일어나 굳은 몸을 풀어보는 건 어때요?",
        "placeholder_summary_no_data": "해당 날짜의 요약 기록이 아직 생성되지 않았어요.",
        "placeholder_weekly_summary_no_data": "아직 2주 리포트를 만들기에 기록이 조금 부족해요. 3일 이상 꾸준히 기록해주시면 더 자세한 리포트를 받아보실 수 있어요!",
        "placeholder_weekly_summary_error": "리포트를 불러오는 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
        "placeholder_no_dialogue": "특별한 대화는 없었어요.",
        "no_solution_proposal": "지금은 제안해드릴 특별한 활동이 없네요.",
        "no_solution_proposal_talk": "지금 제안해드릴 만한 맞춤 활동이 없네요. 대화를 더 나눠볼까요?",
        "neutral_emoji_response": "오늘은 기분이 어떠신가요?",
        "safety_crisis_text": "정말 많이 힘드셨던 것 같아요.\n지금은 혼자 버티기보다 전문가와 이야기하는 것이 가장 안전하고 도움이 될 수 있습니다.\n\n저는 전문적인 위기 개입을 직접 제공하지 않지만, 바로 도움을 받을 수 있는 곳으로 안내해드릴 수 있어요.\n\n연결해드릴까요?",
        "summary_not_found": "요약을 찾을 수 없습니다.",

        # --- Success / Info Messages ---
        "assessment_success": "마음 점검 결과가 성공적으로 제출되었습니다.",
        "feedback_success": "피드백이 성공적으로 제출되었습니다.",
        "backfill_success": "백필 작업 요청 성공!",
        "backfill_complete": "서버가 요약 생성을 완료했습니다.",
        "backfill_timeout": "작업 시간 초과 (Timeout)",
        "backfill_timeout_info": "서버가 백그라운드에서 계속 실행 중일 수 있습니다. Supabase 'daily_summaries' 테이블을 확인해보세요.",
        "backfill_connection_error": "API 서버 연결 실패: {error}",
        "backfill_connection_info": "[터미널 1]에서 main.py 서버가 실행 중인지 확인하세요.",

        # --- UI Labels ---
        "label_breathing": "호흡하러 가기",
        "label_video": "영상 보러가기",
        "label_mission": "미션 하러가기",
        "label_tip": "마음 관리 팁 보기",
        "label_pomodoro_mission": "뽀모도로와 함께 미션하러 가기",
        "label_focus_training": "집중력 훈련하기",
        "label_adhd_has_task": "있어! 뭐부터 하면 좋을까?",
        "label_adhd_no_task": "없어! 집중력 훈련 할래",
        "label_get_help": "도움받기",
        "label_its_okay": "괜찮아요",

        # --- Server Logs (Internal - English OK, but translated for consistency) ---
        "log_error_kiwi_not_installed": "⚠️ kiwipiepy가 설치되지 않았습니다. 일부 안전 기능이 비활성화됩니다.",
        "log_startup_success": "✅ FastAPI 서버 시작 및 Supabase 클라이언트 초기화 완료.",
        "log_safety_figurative": "비유적 표현 감지됨",
        "log_error_fetch_user_info": "사용자 정보 조회 오류 (ID: {user_id}): {error}",
        "log_warn_missing_format_key": "⚠️ 번역 키 누락 '{key}' (언어: '{lang}'). 원본: '{text}'",
        "log_warn_no_mention_found": "⚠️ DB 멘션 없음 (Type: {mention_type}, Lang: {lang}, Filters: {filters}). 기본값 사용.",
        "log_error_get_mention": "❌ get_mention_from_db 오류: {error}",
        "log_error_keys_not_set": "오류: Supabase 또는 OpenAI 키가 설정되지 않았습니다.",
        "log_error_unhandled_exception": "🔥 처리되지 않은 예외 / {job_name}: {error}\n{trace}",
        "error_user_profile_not_found_creating": "⚠️ 사용자 프로필({user_id})을 찾을 수 없습니다. 새로 생성합니다.",
        "error_failed_to_save_session": "🚨 ERROR: 세션 저장 실패, ID가 반환되지 않음.",
        "error_supabase_save_failed": "🚨 Supabase 저장 실패: {error}",
        "log_session_saved": "✅ 세션 저장 성공. session_id: {session_id}",
        "adhd_ask_task": "혹시 지금 해야 할 일이 있는데 미루고 계신가요?", # Mention DB Key
        "adhd_fallback_coaching": "좋아요, 함께 시작해봐요!",
        "adhd_fallback_mission": "가장 작은 일부터 시작해보세요.",
        "log_moderation_blocked": "🚨 [차단됨] 부적절한 콘텐츠: '{text}', 카테고리: {categories}",
        "log_moderation_passed": "⚠️ [통과됨] 내부 안전 확인으로 위임: '{text}', 카테고리: {categories}",
        "log_warn_no_assessment_scores": "⚠️ 최신 평가 점수를 찾을 수 없음. 온보딩 점수를 기본값으로 사용.",
        "log_safety_triggered_1st": "🚨 1차 안전 장치 발동: '{text}'",
        "log_safety_triggered_2nd": "🚨 2차 안전 장치 발동: '{text}'",
        "log_warn_unexpected_triage": "⚠️ 예상치 못한 Triage 결과: {mode}. FRIENDLY로 기본 설정.",
        "log_adhd_detected": "🧠 ADHD 클러스터 감지됨. 해결 전 질문 흐름으로 전환.",
        "log_negative_tags_updated": "✅ 사용자 {user_id} negative_tags 업데이트됨: {tags}",
        "log_daily_summary_start": "----- [일일 요약 작업 시작] 사용자: {user_id}, 날짜: {date_str} -----",
        "log_daily_summary_no_scores": "정보: 사용자 {user_id}의 {date_str} 클러스터 점수 없음. 건너뜀.",
        "reason_difficult_moment": "이 감정은 하루 중 가장 힘들었던(종합 점수가 높았던) 순간의 주요 감정입니다.",
        "log_daily_summary_llm_fail": "경고: 사용자 {user_id}의 {date_str} 요약 생성 실패 (LLM).",
        "log_daily_summary_success": "성공: 사용자 {user_id}의 {date_str} 일일 요약 저장됨.",
        "log_daily_summary_end": "----- [작업 종료] 사용자: {user_id}, 날짜: {date_str} -----",
        "log_weekly_summary_start": "----- [주간 요약 작업 시작] 사용자: {user_id}, 날짜: {date_str} -----",
        "log_weekly_summary_sunday": "     정보: 일요일이므로 '뇌과학 리포트'를 생성합니다.",
        "log_weekly_summary_standard": "     정보: 일반 2주 리포트를 생성합니다.",
        "log_weekly_summary_no_session": "정보: 사용자 {user_id}의 주간 요약 데이터(세션) 없음. 건너뜀.",
        "log_weekly_summary_parse_error": "경고: 사용자 {user_id}의 날짜({date_str}) 파싱 불가. 오류: {error}",
        "log_weekly_summary_insufficient_data": "정보: 사용자 {user_id}의 주간 요약 데이터 부족 ({days_found}일/{days_required}일 필요). 건너뜀.",
        "corr_sleep_neglow": "수면의 질 저하와 우울/무기력감이 함께 높게 나타나는 경향이 있습니다. 이는 심리적 에너지를 소모시키는 요인이 될 수 있어, 두 감정의 관계를 함께 살펴보는 것이 도움이 될 수 있습니다.",
        "corr_neghigh_sleep": "불안/긴장감이 높은 날, 수면 문제도 함께 증가하는 패턴이 보입니다. 과도한 각성 상태가 편안한 휴식에 영향을 미칠 수 있으니, 불안/긴장과 수면의 연관성을 돌아보는 것이 도움이 될 수 있습니다.",
        "corr_adhd_neghigh": "집중력 저하 문제와 불안감이 모두 높은 수준으로 나타났습니다. 주의를 통제하려는 노력이 과도한 정신적 긴장으로 이어질 수 있는 패턴이 관찰됩니다. 집중력과 불안감 사이의 관계를 살펴보는 것이 도움이 될 수 있습니다.",
        "corr_neglow_positive": "우울/무기력감이 높은 시기에는 긍정적 감정을 느끼는 정도가 현저히 낮아지는 패턴이 뚜렷합니다. 이는 감정 회복을 위한 인지적 자원이 부족하다는 신호일 수 있습니다.",
        "corr_neghigh_positive": "불안/분노 감정이 높아질 때, 평온/회복 점수는 반대로 낮아지는 경향이 관찰됩니다. 이 두 감정 사이의 관계를 살펴보며 정서적 안정성을 위한 자신만의 방법을 찾아보는 것도 좋겠습니다.",
        "corr_trend_sleep_neglow": "매우 긍정적인 신호입니다! 최근 2주간 수면의 질이 개선되면서, 우울/무기력감 또한 함께 감소하는 선순환이 만들어지고 있습니다.",
        "corr_trend_neglow_positive": "회복탄력성이 강화되고 있습니다. 우울감이 점차 줄어들면서 그 자리를 긍정적이고 평온한 감정이 채워나가고 있는 모습이 인상적입니다.",
        "log_weekly_summary_llm_fail": "경고: 사용자 {user_id}의 주간 요약 생성 실패 (LLM).",
        "log_weekly_summary_success": "성공: 사용자 {user_id}의 {date_str} 주간 요약 저장됨.",
        "log_task_start": "{job_name} 작업 시작: {date_str}",
        "log_task_no_active_users": "어제 활동한 사용자 없음. 작업 종료.",
        "log_task_found_users": "{user_count}명의 활동 사용자 발견. 각 사용자 요약 생성 시작...",
        "log_task_complete": "{user_count}명 사용자에 대한 요약 생성 작업 완료.",
        "log_error_get_sleep_tip": "❌ get_sleep_tip 오류: {error}",
        "log_error_get_action_mission": "❌ get_action_mission 오류: {error}",

        # --- LLM Prompt Related (Internal Use) ---
        "llm_instruction_korean": "IMPORTANT: Your entire response MUST be in Korean.",
        "llm_instruction_english": "IMPORTANT: Your entire response MUST be in English."
    },
    'en': {
        # --- General Errors / Fallbacks ---
        "error_openai_key_not_found": "OpenAI API key not found.",
        "error_llm_parsing_failed": "Failed to parse LLM response as JSON.",
        "error_llm_call_failed": "LLM call failed: {error}",
        "error_moderation_api_failed": "Moderation API call failed: {error}",
        "error_supabase_init": "Supabase client not initialized.",
        "error_inappropriate_content": "Inappropriate content detected.",
        "error_solution_not_found": "Wellness activity details not found.",
        "error_loading_summary": "An error occurred while loading the summary.",
        "error_invalid_cluster": "Invalid cluster: {cluster}",
        "error_occurred": "An error occurred: {error}",

        "default_user_name": "User",
        "default_char_name": "Buddy",
        "default_analysis_message": "Your mind seems to have a special color today.",
        "default_reaction_message": "What's going on that made you feel this way?",
        "default_propose_message": "How about this activity?",
        "default_home_message": "Hi, {user_nick_nm}! How are you feeling today?",
        "default_followup_user_closed": "It's okay. Shall we continue our conversation?",
        "default_followup_video_ended": "How was it? Do you feel a bit better?😊",
        "default_decline_solution": "Alright. Feel free to talk to me comfortably.",
        "default_empathy_fallback": "I'm listening...",
        "default_llm_friendly_fallback": "Hmm... I need a moment to think!🥹",
        "default_sleep_tip": "Try to maintain a regular sleep schedule.",
        "default_action_mission": "How about getting up for a moment and stretching your stiff body?",
        "placeholder_summary_no_data": "Summary record for that date has not been generated yet.",
        "placeholder_weekly_summary_no_data": "There's not quite enough data yet to create the 2-week report. Keep recording for at least 3 days for a more detailed report!",
        "placeholder_weekly_summary_error": "An error occurred while loading the report. Please try again later.",
        "placeholder_no_dialogue": "No specific conversation was recorded.",
        "no_solution_proposal": "There are no specific activities to suggest right now.",
        "no_solution_proposal_talk": "There aren't any tailored activities to suggest right now. Shall we talk more?",
        "neutral_emoji_response": "How are you feeling today?",
        "safety_crisis_text": "It sounds like you've been going through a really tough time.\nRight now, talking to a professional might be the safest and most helpful step, rather than trying to endure it alone.\n\nWhile I can't provide direct crisis intervention, I can guide you to places where you can get help immediately.\n\nWould you like me to connect you?",
        "summary_not_found": "Could not find the summary.",

        # --- Success / Info Messages ---
        "assessment_success": "Assessment submitted successfully.",
        "feedback_success": "Feedback submitted successfully.",
        "backfill_success": "Backfill job requested successfully!",
        "backfill_complete": "Server has completed generating summaries.",
        "backfill_timeout": "Operation timed out (Timeout)",
        "backfill_timeout_info": "The server might still be running in the background. Check the Supabase 'daily_summaries' table.",
        "backfill_connection_error": "Failed to connect to API server: {error}",
        "backfill_connection_info": "Check if the main.py server is running in [Terminal 1].",

        # --- UI Labels ---
        "label_breathing": "Practice Breathing",
        "label_video": "Watch Video",
        "label_mission": "Do Mission",
        "label_tip": "View Wellness Activity",
        "label_pomodoro_mission": "Do Mission with Pomodoro",
        "label_focus_training": "Focus Training",
        "label_adhd_has_task": "Yes! What should I do first?",
        "label_adhd_no_task": "No! Let's do focus training",
        "label_get_help": "Get Support",
        "label_its_okay": "It's okay",

        # --- Server Logs (English) ---
        "log_error_kiwi_not_installed": "⚠️ kiwipiepy is not installed. Some safety features will be disabled.",
        "log_startup_success": "✅ FastAPI server started and Supabase client initialized.",
        "log_safety_figurative": "Figurative speech detected",
        "log_error_fetch_user_info": "Error fetching user info for {user_id}: {error}",
        "log_warn_missing_format_key": "⚠️ Missing key '{key}' for formatting string in lang '{lang}'. Original: '{text}'",
        "log_warn_no_mention_found": "⚠️ No specific mention found for {mention_type} (lang: {lang}, filters: {filters}). Using default.",
        "log_error_get_mention": "❌ get_mention_from_db Error: {error}",
        "log_error_keys_not_set": "Error: Supabase or OpenAI key not set.",
        "log_error_unhandled_exception": "🔥 UNHANDLED EXCEPTION in {job_name}: {error}\n{trace}",
        "error_user_profile_not_found_creating": "⚠️ User profile for {user_id} not found. Creating a new one.",
        "error_failed_to_save_session": "🚨 ERROR: Failed to save session, no ID returned.",
        "error_supabase_save_failed": "🚨 Supabase save failed: {error}",
        "log_session_saved": "✅ Session saved successfully. session_id: {session_id}",
        "adhd_ask_task": "Are you perhaps procrastinating on a task you need to do right now?", # Mention DB Key
        "adhd_fallback_coaching": "Alright, let's get started together!",
        "adhd_fallback_mission": "Let's start with the smallest thing first.",
        "log_moderation_blocked": "🚨 [BLOCKED] Inappropriate content: '{text}', Categories: {categories}",
        "log_moderation_passed": "⚠️ [PASSED] Delegating to internal safety check: '{text}', Categories: {categories}",
        "log_warn_no_assessment_scores": "⚠️ Latest assessment scores not found, using onboarding scores as baseline.",
        "log_safety_triggered_1st": "🚨 1st Safety Check Triggered: '{text}'",
        "log_safety_triggered_2nd": "🚨 2nd Safety Check Triggered: '{text}'",
        "log_warn_unexpected_triage": "⚠️ Unexpected triage result: {mode}. Defaulting to FRIENDLY.",
        "log_adhd_detected": "🧠 ADHD cluster detected. Switching to pre-solution question flow.",
        "log_negative_tags_updated": "✅ User {user_id} negative_tags updated: {tags}",
        "log_daily_summary_start": "----- [Daily Summary Job Start] User: {user_id}, Date: {date_str} -----",
        "log_daily_summary_no_scores": "Info: No cluster scores for user {user_id} on {date_str}. Skipping.",
        "reason_difficult_moment": "This emotion was the main feeling during the most difficult moment of the day (highest overall score).",
        "log_daily_summary_llm_fail": "Warning: LLM failed to generate summary for user {user_id} on {date_str}.",
        "log_daily_summary_success": "Success: Saved daily summary for user {user_id} on {date_str}.",
        "log_daily_summary_end": "----- [Job End] User: {user_id}, Date: {date_str} -----",
        "log_weekly_summary_start": "----- [Weekly Summary Job Start] User: {user_id}, Date: {date_str} -----",
        "log_weekly_summary_sunday": "     Info: Generating 'Neuroscience Report' for Sunday.",
        "log_weekly_summary_standard": "     Info: Generating standard 2-week report.",
        "log_weekly_summary_no_session": "Info: No session data found for weekly summary for user {user_id}. Skipping.",
        "log_weekly_summary_parse_error": "Warning: Could not parse date {date_str} for user {user_id}. Error: {error}",
        "log_weekly_summary_insufficient_data": "Info: Insufficient data ({days_found} days found, requires {days_required}) for weekly summary for user {user_id}. Skipping.",
        "corr_sleep_neglow": "A tendency for low mood/lethargy to be high when sleep quality is low is observed. This could be a factor draining psychological energy, so it might be helpful to look at the relationship between these two feelings.",
        "corr_neghigh_sleep": "A pattern of sleep problems increasing on days with high anxiety/tension is visible. An overly alert state might affect restful sleep, so exploring the link between anxiety and sleep could be beneficial.",
        "corr_adhd_neghigh": "Both focus difficulty and anxiety were observed at high levels. Efforts to control attention might be leading to excessive mental tension. Examining the relationship between focus and anxiety could be helpful.",
        "corr_neglow_positive": "A clear pattern is visible where feelings of positivity are significantly lower during periods of high low mood/lethargy. This could signal a lack of cognitive resources for emotional recovery.",
        "corr_neghigh_positive": "A tendency for calm/recovery scores to decrease when anxiety/anger feelings increase is observed. Reflecting on the relationship between these two feelings might help in finding your own ways to emotional stability.",
        "corr_trend_sleep_neglow": "A very positive sign! As sleep quality improved over the last 2 weeks, low mood/lethargy also decreased, creating a virtuous cycle.",
        "corr_trend_neglow_positive": "Resilience is strengthening. It's impressive to see positive and calm feelings filling the space as feelings of low mood gradually decrease.",
        "log_weekly_summary_llm_fail": "Warning: LLM failed to generate weekly summary for user {user_id}.",
        "log_weekly_summary_success": "Success: Saved weekly summary for user {user_id} on {date_str}.",
        "log_task_start": "Starting {job_name} task for date: {date_str}",
        "log_task_no_active_users": "No active users yesterday. Task finished.",
        "log_task_found_users": "Found {user_count} active users. Starting summary generation for each user...",
        "log_task_complete": "Summary generation task complete for {user_count} users.",
        "log_error_get_sleep_tip": "❌ get_sleep_tip Error: {error}",
        "log_error_get_action_mission": "❌ get_action_mission Error: {error}",

        # --- LLM Prompt Related (Internal Use) ---
        "llm_instruction_korean": "IMPORTANT: Your entire response MUST be in Korean.",
        "llm_instruction_english": "IMPORTANT: Your entire response MUST be in English."
    }
}

DEFAULT_LANG = 'ko'

def get_translation(key: str, lang_code: str = DEFAULT_LANG, **kwargs) -> str:
    """Retrieves a translated string for the given key and language code, performing formatting."""
    lang_code = lang_code if lang_code in translations else DEFAULT_LANG
    messages = translations.get(lang_code, translations[DEFAULT_LANG])
    message = messages.get(key, f"[{key}]") # Return key in brackets if not found

    try:
        # Use provided kwargs for formatting, otherwise empty dict
        return message.format(**(kwargs or {}))
    except KeyError as e:
        lang_to_log = lang_code or "undefined"
        print(get_translation("log_warn_missing_format_key", DEFAULT_LANG, key=str(e), lang=lang_to_log, text=message))
        # Attempt to format with missing keys replaced
        try:
            placeholders = re.findall(r'\{([^}]+)\}', message)
            safe_kwargs = {**{p: f"{{{p}}}" for p in placeholders}, **(kwargs or {})} # Fill missing with placeholder text
            return message.format(**safe_kwargs)
        except: # Final fallback
            return message # Return original if formatting still fails