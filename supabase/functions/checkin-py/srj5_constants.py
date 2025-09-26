# srj5_constants.py
# 0924변경:
# 1. META_WEIGHTS에서 'context' 제거
# 2. Flutter에 있던 SOLUTION_ID_LIBRARY를 백엔드로 이동
# 3. 온보딩 질문과 클러스터 가중치 매핑 수정 (사용자 정보 변경에 따라)

CLUSTERS = ["neg_low", "neg_high", "adhd_high", "sleep", "positive"]
EMOJI_ONLY_SCORE_CAP = 0.5

# --- Scoring Weights & Parameters ---

# ❤️ 텍스트 분석, 온보딩, 이모지를 각각 독립된 요소로 보고, Renormalization!!!!
# e.g. 최종 점수 = (텍스트 * 0.6) + (온보딩 * 0.2) + (이모지 * 0.2)
FINAL_FUSION_WEIGHTS = {
    "text": 0.6,
    "onboarding": 0.2,
    "icon": 0.2
}

# ❤️ 텍스트가 없을 때 사용할 가중치 
FINAL_FUSION_WEIGHTS_NO_TEXT = {
    "onboarding": 0.8, 
    "icon": 0.2
}
# ---
DSM_WEIGHTS = {"neg_low": 0.90, "neg_high": 0.80, "adhd_high": 0.70, "sleep": 0.60, "positive": 1.00}
DSM_BETA = {"neg_low": 0.15, "neg_high": 0.15, "adhd_high": 0.10, "sleep": 0.10, "positive": 0.10}

W_RULE = 0.6
W_LLM = 0.4

META_WEIGHTS = {
    # "icon": 0.30, # icon 가산점 --> 가중치로 할거라 alpha로 대체
    # ♥ 추가: icon_alpha를 아래 두 가지로 세분화함.
    "icon_only_alpha": 0.1,    # 이모지만 눌렀을 때 적용될 가중치 (정보의 신뢰도 원칙)
    "icon_with_text_alpha": 0.2, # 텍스트와 함께 있을 때 적용될 가중치

    # "intensity_self": 0.20, # 자기가 슬라이드 하도록 하려고 했었음
    # "time": 0.10, # 시간적 맥락 조절: 야간(수면 관련), 월요일 오전(우울/불안 ↑), 생체리듬 구간 등
    # "text": 0.15, # 텍스트 신뢰도 계산 지금은 안함(텍스트 길이·문장수·키워드 정합성)
    # "pattern": 0.05 # 개인 히스토리(최근 n일 패턴) 기반 보정
}

SEVERITY_LOW_MAX = 0.30
SEVERITY_MED_MAX = 0.60
RULE_SKIP_LLM = 0.70

PCA_PROXY = {
    "pc1": {"neg_low": 0.60, "neg_high": 0.50, "sleep": 0.20, "positive": -0.60, "adhd_high": 0.10},
    "pc2": {"neg_high": 0.70, "adhd_high": 0.40, "sleep": -0.50, "neg_low": 0.10, "positive": -0.05}
}

# --- Safety Check Keywords ---

SAFETY_LEMMAS = [
    "죽다", "자살하다", "뛰어내리다", "투신하다", "목매달다",
    "자해하다", "유서", "극단적이다", "죽이다", "해치다",
]
SAFETY_LEMMA_COMBOS = [
    {"살다", "싫다"},  # "살기 싫다"
    {"목숨", "끊다"},  # "목숨을 끊다"
    {"생", "마감하다"}, # "생을 마감하다"
]

# --- Onboarding Survey to Cluster Mapping ---
# 각 질문(q1~q9)이 어떤 감정 클러스터에 얼마나 영향을 주는지 정의
ONBOARDING_MAPPING = {
    "q1": [{"cluster": "neg_low", "w": 0.80}, {"cluster": "sleep", "w": 0.10}, {"cluster": "positive", "w": -0.10}],
    "q2": [{"cluster": "neg_low", "w": 0.85}, {"cluster": "adhd_high", "w": 0.05}, {"cluster": "positive", "w": -0.10}],
    "q3": [{"cluster": "neg_high", "w": 0.90}, {"cluster": "sleep", "w": 0.10}],
    "q4": [{"cluster": "neg_high", "w": 0.85}, {"cluster": "neg_low", "w": 0.05}, {"cluster": "sleep", "w": 0.10}],
    "q5": [{"cluster": "neg_high", "w": 0.60}, {"cluster": "neg_low", "w": 0.25}, {"cluster": "adhd_high", "w": 0.15}],
    "q6": [{"cluster": "sleep", "w": 0.90}, {"cluster": "neg_low", "w": 0.10}],
    "q7": [{"cluster": "positive", "w": 0.80}, {"cluster": "neg_low", "w": 0.20}],
    "q8": [{"cluster": "neg_low", "w": 0.80}, {"cluster": "sleep", "w": 0.20}],
    "q9": [{"cluster": "adhd_high", "w": 0.85}, {"cluster": "neg_low", "w": 0.15}],
}


ICON_TO_CLUSTER = {
    "angry": "neg_high",
    "crying": "neg_low",
    "shocked": "adhd_high",
    "sleeping": "sleep",
    "smile": "positive",
    "default": "neutral" 
}




# --- Solution Libraries ---
# Supabase로 이전될 데이터. 백엔드에서 랜덤 선택을 위해 유지.
SOLUTION_ID_LIBRARY = {
    "neg_low": ["neg_low_beach_01", "neg_low_turtle_01", "neg_low_snow_01"],
    "neg_high": ["neg_high_cityview_01", "neg_high_campfire_01", "neg_high_heartbeat_01"],
    "adhd_high": ["adhd_high_space_01", "adhd_high_pomodoro_01", "adhd_high_training_01"],
    "sleep": ["sleep_forest_01", "sleep_onsen_01", "sleep_plane_01"],
    "positive": ["positive_forest_01", "positive_beach_01", "positive_cafe_01"]
}

# 솔루션 제안 멘트 라이브러리 (Supabase로 이전될 데이터)
SOLUTION_PROPOSAL_SCRIPTS = {
    "neg_low": [
        "[솔루션 추천]\n지금은 기분이 바닥에 붙어있는 것 같아요. ",
        "[솔루션 추천]\n이럴 땐 좁은 방 안에만 머물러 있는 느낌이 강해져요. ",
        "[솔루션 추천]\n작은 공간에 갇힌 듯한 느낌을 깨는 것이 중요해요. "
    ],
    "neg_high": [
        "[솔루션 추천]\n지금은 뇌의 경보 시스템이 과도하게 울리고 있어요. ",
        "[솔루션 추천]\n불안과 분노가 치밀어 오를 땐, ",
        "[솔루션 추천]\n몸의 긴장을 풀기엔 "
    ],
    "adhd_high": [
        "[솔루션 추천]\n집중이 자꾸 흩어질 땐 ",
        "[솔루션 추천]\n주의가 산만해질 땐 주변 맥락을 정리하는 게 좋아요. ",
        "[솔루션 추천]\n산만할 때는 복잡한 자극 대신, "
    ],
    "sleep": ["[솔루션 추천]\n수면 회로가 불안정할 때는 ", "[솔루션 추천]\n깊이 잠들기 힘들 땐 ", "[솔루션 추천]\n깨어있는 몸을 진정시키기 위해, "],
    "positive": [
        "[솔루션 추천]\n지금 좋은 감정을 더 크게 키워보면 좋아요. ",
        "[솔루션 추천]\n긍정적인 순간은 공간 기억과 함께 묶으면 더 오래갑니다. ",
        "[솔루션 추천]\n좋은 기분은 "
    ]
}

# 분석 결과에 대한 대화형 문구 - 수치화 대신 제공 
ANALYSIS_MESSAGE_LIBRARY = {
    "neg_low": {
        "high": "[우울/무기력 점수가 높아요!] \n평소보다 훨씬 많이 우울해 보여요.",# 지금 바로 기분 전환이 필요해요!",
        "mid": "[우울/무기력 수치가 상승했어요!] \n평소보다 조금 지쳐 보이는군요.",# 잠시 쉬어가도 괜찮아요.",
        "low": "[우울/무기력이 조금 있어요!] \n마음이 조금 가라앉아 있네요.",# 무슨 일 있었나요?"
    },
    "neg_high": {
        "high": "[불안/분노 점수가 높아요!] \n마음속에 큰 폭풍이 몰아치는 것 같아요.",#  제가 옆에 있을게요.",
        "mid": "[불안/분노 수치가 상승했어요!] \n조금 예민하고 날카로워진 것 같아요.",# 잠시 심호흡을 해볼까요?",
        "low": "[불안/분노가 조금 있어요!] \n약간의 불안감이 느껴져요.",#  무엇이 당신을 불편하게 하나요?"
    },
    "adhd_high": {
        "high": "[주의 집중이 많이 어려운 상황이네요!] \n생각이 많아 집중이 어려운 상태인 것 같아요.",#  하나씩 차근차근 해봐요.",
        "mid": "[주의 집중력이 저하되었어요!] \n주의가 조금 흩어져 있네요.",#  잠시 주변을 정리해보는 건 어때요?",
        "low": "[주의 집중이 좀 어려운 상황이네요!] \n마음이 살짝 붕 떠 있는 느낌이 들어요."
    },
    "sleep": {
        "high": "[수면 불편 점수가 매우 높아요!] \n많이 피곤해 보여요.",#  오늘은 꼭 숙면을 취할 수 있기를 바라요.",
        "mid": "[수면 불편 점수가 저하되었어요!] \n어젯밤 잠을 설친 것 같군요.",#  괜찮아요?",
        "low": "[수면 문제가 있어요!] \n조금 졸려 보이네요.",#  편안한 밤을 보냈나요?"
    },
    "positive": {
        "high": "[행복지수가 높아요!] \n정말 좋은 일이 있었나 봐요! 얼굴에 웃음꽃이 피었어요. 😊",
        "mid": "기분이 좋아 보여요. 당신의 하루가 즐거움으로 가득했으면 좋겠어요.",
        "low": "마음이 편안해 보여요. 안정적인 하루를 보내고 있군요."
    }
}

# 나중에 Supabase 테이블이 준비되면 이 부분은 삭제
SOLUTION_DETAILS_LIBRARY = {
    # 우울/무기력 (neg_low)
    "neg_low_beach_01": {
        "text": "지금은 속이 탁 트이는 바닷가로 잠시 자리를 옮겨볼까요?",
        "url": "https://www.youtube.com/watch?v=n4Mdh3TEq_k", # &t=420 제거, startAt/endAt 필드로 제어
        "startAt": 420,  # 7:00
        "endAt": 540,     # 9:00
        "context": "바닷가"
    },
    "neg_low_turtle_01": {
        "text": "자유로이 헤엄치는 거북이를 따라가며, 깊은 바다 속으로 시선을 옮겨보세요.",
        "url": "https://www.youtube.com/watch?v=9xQ6YlaYYHI", # &t=... 제거
        "startAt": 0,
        "endAt": 180,
        "context": "바닷속"
    },
    "neg_low_snow_01": {
        "text": "하얀 눈 내리는 밤길을 걸으면서 고요한 소리에 마음을 맡겨보세요. 뇌가 새로운 공간을 감지하면서 기분이 조금씩 환기돼요.",
        "url": "https://www.youtube.com/watch?v=31RokLEvUhg",
        "startAt": 1290,  # 21:30
        "endAt": 1440,     # 24:00
        "context": "설산"
    },

    # 불안/분노 (neg_high)
    "neg_high_cityview_01": {
        "text": "창밖 도시 불빛과 떨어지는 빗방울을 바라보며, 호흡을 가다듬어볼까요?",
        "url": "https://www.youtube.com/watch?v=xg1gNlxto2M",
        "startAt": 0,
        "endAt": 120,
        "context": "도시 야경"
    },
    "neg_high_campfire_01": {
        "text": "강가의 모닥불처럼 감정을 흡수해줄 탁 트인 공간이 필요해요. 불빛이 물결에 흔들리듯, 한 호흡 한 호흡 긴장을 내려놓아보세요.",
        "url": "https://www.youtube.com/watch?v=6nlEmH7eZLk",
        "startAt": 20,
        "endAt": 140,
        "context": "모닥불"
    },
    "neg_high_heartbeat_01": {
        "text": "엄마 뱃속처럼 고요한 물속에서 심장소리에 집중하면, 뇌가 점차 안정된 리듬을 회복하게 돼요.",
        "url": "https://www.youtube.com/watch?v=vuctJwSi2To", # &t=... 제거
        "startAt": 8,
        "endAt": 129,
        "context": "고요한 물속"
    },

    # ADHD (adhd_high)
    "adhd_high_space_01": {
        "text": "우주 공간처럼 자극이 최소화된 환경이 효과적이에요. 숨을 고르며 별빛에 시선을 모아보세요.",
        "url": "https://www.youtube.com/watch?v=qRitf7c3-nQ",
        "startAt": 0,
        "endAt": 120,
        "context": "우주 공간"
    },
    "adhd_high_pomodoro_01": {
        "text": "딱 5분만, 가장 쉬운 일부터 시작해볼까요? 작은 출발이 집중을 열어줄 거예요.",
        "url": "https://www.youtube.com/watch?v=TA9SZawYm2k",
        "startAt": 0,
        "endAt": 120,
        "context": "책상 앞"
    },
    "adhd_high_training_01": {
        "text": "공의 움직임을 따라가보세요! 집중력이 켜졌습니다!",
        "url": "https://www.youtube.com/watch?v=E7HOlJ_OhEo",
        "startAt": 0,
        "endAt": 120,
        "context": "훈련 공간"
    },

    # 수면 (sleep)
    "sleep_forest_01": {
        "text": "잔잔한 숲 속에서 포근한 텐트 안에 누운 듯, 빗방울이 떨어지는 리듬에 맞춰 몸을 호흡해보세요.",
        "url": "https://www.youtube.com/watch?v=IdTRKv2jLo4",
        "startAt": 10,
        "endAt": 130,
        "context": "밤의 숲속"
    },
    "sleep_onsen_01": {
        "text": "온천의 따뜻한 품에서 보글보글 물소리와 풀벌레 소리에 집중해보세요. 잠 못 이루던 마음도 편안해질거예요.",
        "url": "https://www.youtube.com/watch?v=fz1f05GRSvA",
        "startAt": 20,
        "endAt": 140,
        "context": "온천"
    },
    "sleep_plane_01": {
        "text": "비행기에서 포근한 기내 좌석에 기대듯, 엔진 소리에 안정을 맡기고 천천히 숨을 쉬어보세요. 공간적 전환이 뇌의 각성을 낮춰줍니다.",
        "url": "https://www.youtube.com/watch?v=LuMBRy_gly4", # &t=... 제거
        "startAt": 3540,  # 59:00
        "endAt": 3600,     # 1:00:00
        "context": "비행기 안"
    },

    # 긍정 (positive)
    "positive_forest_01": {
        "text": "햇살 가득한 숲에 앉아 호흡하며 그 기분을 오래 저장해보세요.",
        "url": "https://www.youtube.com/watch?v=su14Bo0-uMI", # &list=LL&index=4 제거
        "startAt": 0,
        "endAt": 120,
        "context": "햇살 가득한 숲"
    },
    "positive_beach_01": {
        "text": "푸른 하늘과 흰 구름 아래에 있는 상상을 해보세요.",
        "url": "https://www.youtube.com/watch?v=M_Q3YNlWfyA",
        "startAt": 0,
        "endAt": 120,
        "context": "푸른 해변"
    },
    "positive_cafe_01": {
        "text": "재즈가 흐르는 카페와 같은 공간과 함께 할 때 뇌가 회복탄력성을 더 강하게 저장해요.",
        "url": "https://www.youtube.com/watch?v=NJuSStkIZBg",
        "startAt": 0,
        "endAt": 120,
        "context": "재즈 카페"
    }
}