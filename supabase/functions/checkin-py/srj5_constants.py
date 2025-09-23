# srj5_constants.py

CLUSTERS = ["neg_low", "neg_high", "adhd_high", "sleep", "positive"]

DSM_WEIGHTS = {
    "neg_low": 0.90,
    "neg_high": 0.80,
    "adhd_high": 0.70,
    "sleep": 0.60,
    "positive": 1.00,
}

DSM_BETA = {
    "neg_low": 0.15,
    "neg_high": 0.15,
    "adhd_high": 0.10,
    "sleep": 0.10,
    "positive": 0.10,
}

W_RULE = 0.6
W_LLM  = 0.4

META_WEIGHTS = {
    "icon": 0.30,
    "intensity_self": 0.20,
    "context": 0.20,
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

SAFETY_LEMMAS = [
    "죽다", 
    "자살하다", 
    "뛰어내리다", 
    "투신하다", 
    "목매달다",
    "자해하다",
    "유서",
    "극단적이다",
    "죽이다",
    "해치다",
]

# 함께 등장했을 때 위험한 '어근' 조합 목록
SAFETY_LEMMA_COMBOS = [
    {"살다", "싫다"},    # "살기 싫다"
    {"목숨", "끊다"},    # "목숨을 끊다"
    {"생", "마감하다"},  # "생을 마감하다"
]

INTERVENTIONS = [
    {"cluster":"neg_high","severity":"high","preset_id":"negHigh_high_ground_180_v1","priority":100,"safety_check":True},
    {"cluster":"neg_high","severity":"medium","preset_id":"negHigh_med_breath_180_v1","priority":80,"safety_check":False},
    {"cluster":"neg_low","severity":"high","preset_id":"negLow_high_activation_120_v1","priority":90,"safety_check":False},
    {"cluster":"sleep","severity":"high","preset_id":"sleep_high_hygiene_900_v1","priority":85,"safety_check":False},
    {"cluster":"positive","severity":"any","preset_id":"pos_low_note_60_v1","priority":50,"safety_check":False},
]

# --- 온보딩 설문 문항과 클러스터 가중치 매핑!!! ---
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

# --- 솔루션 ID를 클러스터별로 그룹화한 라이브러리 추가 ---
SOLUTION_ID_LIBRARY = {
    "neg_low": [
        "neg_low_beach_01",
        "neg_low_turtle_01",
        "neg_low_snow_01"
    ],
    "neg_high": [
        "neg_high_cityview_01",
        "neg_high_campfire_01",
        "neg_high_heartbeat_01"
    ],
    "adhd_high": [
        "adhd_high_space_01",   
        "adhd_high_pomodoro_01",
        "adhd_high_training_01"
    ],
    "sleep": [
        "sleep_forest_01",
        "sleep_onsen_01",
        "sleep_plane_01"
    ],
    "positive": [
        "positive_forest_01",
        "positive_beach_01",
        "positive_cafe_01"
    ]
}


