# srj5_constants.py

CLUSTERS = ["neg_low", "neg_high", "adhd", "sleep", "positive"]


# ❤️ 1. 텍스트가 포함된 경우 사용할 기본 가중치
# e.g. 최종 점수 = (텍스트 * 0.5) + (온보딩 * 0.2) + (이모지 * 0.3)
FINAL_FUSION_WEIGHTS = {
    "text": 0.60, # 사용자의 순간의 감정
    "assessment": 0.25, # 사용자의 안정된 임상적 상태
    "icon": 0.15 # 보조적인 감정 신호
}

# ❤️ 2. 텍스트가 없이 이모지만 입력된 경우 사용할 가중치 
FINAL_FUSION_WEIGHTS_NO_TEXT = {
    "assessment": 0.2, 
    "icon": 0.8 # text 가중치 0.5 + icon 가중치 0.3
}
# ❤️ 이모지만 입력 시 적용될 점수 상한선 (안전장치)
# 이모지는 저비용 입력이므로, 그 영향력을 0.5점으로 제한하는 EMOJI_ONLY_SCORE_CAP은 점수가 과도하게 변하는 것을 막는 매우 중요한 안전장치입니다.
EMOJI_ONLY_SCORE_CAP = 0.5

# assessment_score가 최종 점수 계산에 미치는 영향력을 제한하기 위한 상한선
ASSESSMENT_SCORE_CAP = 0.7

# 3. 텍스트는 있지만 아이콘이 없을 때를 위한 가중치 (비례 배분)
FINAL_FUSION_WEIGHTS_NO_ICON = {
    "text": 0.80, # text + icon
    "assessment": 0.20  # assessment + icon
}

# --- Scoring Weights & Parameters ---
# ❤️ Rule-based와 LLM 텍스트 분석 결과를 융합할 때의 가중치
# 나중에 앱 운영 데이터가 쌓이고 LLM의 성능에 대한 확신이 들었을 때, 점진적으로 LLM의 비중을 50%까지 높여보는 것을 고려할 수 있습니다.
W_RULE = 0.5 #Rule-based (60%->50%): 명확한 키워드("너무 우울해")를 빠르고 정확하게 잡아내는 장점이 있습니다. 예측 가능성이 높아 안정적입니다.
W_LLM = 0.5 #LLM (40%->50%): 직접적인 단어는 없지만 미묘한 뉘앙스("요즘은 웃는 게 웃는 게 아닌 것 같아")를 파악하는 데 강점이 있습니다.

# ❤️ 이모지-클러스터 매핑
ICON_TO_CLUSTER = {
    "angry": "neg_high",
    "crying": "neg_low",
    "shocked": "adhd",
    "sleeping": "sleep",
    "smile": "positive",
    "default": "neutral"
}


# --- Safety Check Keywords ---
SAFETY_REGEX = [
    r"죽고\s*싶", r"살고\s*싶지", r"살기\s*싫", r"자살", r"뛰어\s*내리", r"투신", 
    r"목을\s*매달", r"목숨(?:을)?\s*끊", r"생을\s*마감", r"죽어버리", r"끝내버리"
]

SAFETY_FIGURATIVE = [
    r"(배고파|배불러|졸려|피곤해|더워|추워|힘들|아파)\s*죽",
    r"(좋아|웃겨|귀여워|보고싶어|궁금해)\s*죽",
]

SAFETY_LEMMAS = [
    "죽다", "자살하다", "뛰어내리다", "투신하다", "목매달다",
    "자해하다", "유서", "극단적이다", "죽이다", "해치다",     
    "사망하다", "숨지다", "자학하다", "유언", "칼", "흉기"
]
SAFETY_LEMMA_COMBOS = [
    {"살다", "싫다"},  # "살기 싫다"
    {"목숨", "끊다"},  # "목숨을 끊다"
    {"생", "마감하다"}, # "생을 마감하다"
    {"극단적", "선택"},  # "극단적 선택"
    {"나쁜", "생각"},    # "나쁜 생각 했어"
    {"몸", "상하다"},    # "몸을 상하게 하다"
    {"세상", "떠나다"},  # "세상을 떠나다"
]

# --- Onboarding Survey to Cluster Mapping ---
# 각 질문(q1~q9)이 어떤 감정 클러스터에 얼마나 영향을 주는지 정의
ONBOARDING_MAPPING = {
    "q1": [{"cluster": "neg_low", "w": 0.80}, {"cluster": "sleep", "w": 0.10}, {"cluster": "positive", "w": -0.10}],
    "q2": [{"cluster": "neg_low", "w": 0.85}, {"cluster": "adhd", "w": 0.05}, {"cluster": "positive", "w": -0.10}],
    "q3": [{"cluster": "neg_high", "w": 0.90}, {"cluster": "sleep", "w": 0.10}],
    "q4": [{"cluster": "neg_high", "w": 0.85}, {"cluster": "neg_low", "w": 0.05}, {"cluster": "sleep", "w": 0.10}],
    "q5": [{"cluster": "neg_high", "w": 0.60}, {"cluster": "neg_low", "w": 0.25}, {"cluster": "adhd", "w": 0.15}],
    "q6": [{"cluster": "sleep", "w": 0.90}, {"cluster": "neg_low", "w": 0.10}],
    "q7": [{"cluster": "positive", "w": 0.80}, {"cluster": "neg_low", "w": 0.20}],
    "q8": [{"cluster": "neg_low", "w": 0.80}, {"cluster": "sleep", "w": 0.20}],
    "q9": [{"cluster": "adhd", "w": 0.85}, {"cluster": "neg_low", "w": 0.15}],
}

# 심층 분석 문항 별 최대 점수 (정규화에 사용)
DEEP_DIVE_MAX_SCORES = {
    "neg_low": 24,  # 8문항 * 3점
    "neg_high": 18, # 6문항 * 3점
    "adhd": 18,# 6문항 * 3점
    "sleep": 15,    # 5문항 * 3점
    "positive": 15  # 5문항 * 3점
}


# 사용자에게 보여줄 이름
CLUSTER_TO_DISPLAY_NAME = {
    "neg_high": "불안/분노",
    "neg_low": "우울/무기력",
    "adhd": "집중력 저하",
    "sleep": "불규칙한 수면",
    "positive": "평온/회복"
}

