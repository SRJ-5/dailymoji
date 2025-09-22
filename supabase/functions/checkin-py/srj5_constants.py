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

SAFETY_TERMS = [
    "죽고 싶", "죽고싶", "죽고", "죽이고", "죽여", "자해", "끝내고", "사라지고", "해치고", "극단적", "유서", "고의로 다치", "살기싫"
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