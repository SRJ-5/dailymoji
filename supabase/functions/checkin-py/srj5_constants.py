# srj5_constants.py
# 0924변경:
# 1. META_WEIGHTS에서 'context' 제거
# 2. Flutter에 있던 SOLUTION_ID_LIBRARY를 백엔드로 이동
# 3. 온보딩 질문과 클러스터 가중치 매핑 수정 (사용자 정보 변경에 따라)

CLUSTERS = ["neg_low", "neg_high", "adhd_high", "sleep", "positive"]

# --- Scoring Weights & Parameters ---

DSM_WEIGHTS = {"neg_low": 0.90, "neg_high": 0.80, "adhd_high": 0.70, "sleep": 0.60, "positive": 1.00}
DSM_BETA = {"neg_low": 0.15, "neg_high": 0.15, "adhd_high": 0.10, "sleep": 0.10, "positive": 0.10}

W_RULE = 0.6
W_LLM = 0.4

META_WEIGHTS = {
    "icon": 0.30,
    "intensity_self": 0.20,
    "time": 0.10,
    "text": 0.15,
    "pattern": 0.05
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
        "지금은 기분이 바닥에 붙어있는 것 같아요. ",
        "이럴 땐 좁은 방 안에만 머물러 있는 느낌이 강해져요. ",
        "작은 공간에 갇힌 듯한 느낌을 깨는 것이 중요해요. "
    ],
    "neg_high": [
        "지금은 뇌의 경보 시스템이 과도하게 울리고 있어요. ",
        "불안과 분노가 치밀어 오를 땐, ",
        "몸의 긴장을 풀기엔 "
    ],
    "adhd_high": [
        "집중이 자꾸 흩어질 땐 ",
        "주의가 산만해질 땐 주변 맥락을 정리하는 게 좋아요. ",
        "산만할 때는 복잡한 자극 대신, "
    ],
    "sleep": ["수면 회로가 불안정할 때는 ", "깊이 잠들기 힘들 땐 ", "깨어있는 몸을 진정시키기 위해, "],
    "positive": [
        "지금 좋은 감정을 더 크게 키워보면 좋아요. 🌸 ",
        "긍정적인 순간은 공간 기억과 함께 묶으면 더 오래갑니다. ",
        "좋은 기분은 "
    ]
}

# 분석 결과에 대한 대화형 문구 - 수치화 대신 제공 
ANALYSIS_MESSAGE_LIBRARY = {
    "neg_low": {
        "high": "평소보다 훨씬 많이 우울해 보여요. 지금 바로 기분 전환이 필요해요!",
        "mid": "조금 지쳐 보이는군요. 잠시 쉬어가도 괜찮아요.",
        "low": "마음이 조금 가라앉아 있네요. 무슨 일 있었나요?"
    },
    "neg_high": {
        "high": "마음속에 큰 폭풍이 몰아치는 것 같아요. 제가 옆에 있을게요.",
        "mid": "조금 예민하고 날카로워진 것 같아요. 잠시 심호흡을 해볼까요?",
        "low": "약간의 불안감이 느껴져요. 무엇이 당신을 불편하게 하나요?"
    },
    "adhd_high": {
        "high": "생각이 많아 집중이 어려운 상태인 것 같아요. 하나씩 차근차근 해봐요.",
        "mid": "주의가 조금 흩어져 있네요. 잠시 주변을 정리해보는 건 어때요?",
        "low": "마음이 살짝 붕 떠 있는 느낌이 들어요."
    },
    "sleep": {
        "high": "많이 피곤해 보여요. 오늘은 꼭 숙면을 취할 수 있기를 바라요.",
        "mid": "어젯밤 잠을 설친 것 같군요. 괜찮아요?",
        "low": "조금 졸려 보이네요. 편안한 밤을 보냈나요?"
    },
    "positive": {
        "high": "정말 좋은 일이 있었나 봐요! 얼굴에 웃음꽃이 피었어요. 😊",
        "mid": "기분이 좋아 보여요. 당신의 하루가 즐거움으로 가득했으면 좋겠어요.",
        "low": "마음이 편안해 보여요. 안정적인 하루를 보내고 있군요."
    }
}