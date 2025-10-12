from kiwipiepy import Kiwi

kiwi = Kiwi()

# 완전 hit 단어
CLUSTER_KEYWORDS = {
    "neg_low": ["우울", "무기력", "번아웃", "자살"],
    "neg_high": ["불안", "분노", "공포", "짜증", "공황"],
    "adhd": ["ADHD", "산만", "집중", "충동"],
    "sleep": ["수면", "불면증"],
    "positive": ["행복", "재밌음", "즐거움"],
}

# 일반 lexicon (다양한 유의어 및 구어체 포함)
LEXICON = {
    # 불안, 분노, 스트레스, 긴장, 공포 등 각성 수준이 높은 부정적 감정
    "neg_high": [
        "불안", "초조", "긴장", "걱정", "공포", "무섭", "두렵", "공황", "짜증", "분노", 
        "화나", "열받아", "빡쳐", "미치겠어", "답답해", "숨막혀", "심장 뛰어", "떨려",
        "스트레스", "압박감", "예민"
    ],
    # 우울, 무기력, 외로움, 슬픔 등 각성 수준이 낮은 부정적 감정
    "neg_low": [
        "우울", "무기력", "피곤", "지침", "탈진", "소진", "의욕 없", "재미없", "무의미", 
        "지쳐", "지치", "힘들", "힘드네", "힘드렁", "기운없어", "외로워", "슬퍼", 
        "눈물나", "버거워", "서러워", "비참"
    ],
    # 부주의, 충동성, 과잉행동 등
    "adhd": [
        "산만", "집중", "딴짓", "딴생각", "미루", "충동", "정리", "실수", "까먹", 
        "가만히", "안절부절", "질렀어", "정신없어"
    ],
    # 수면의 질과 관련된 모든 표현
    "sleep": [
        "잠", "불면", "깨", "뒤척", "과다수면", "졸려", "수면제", "피곤",
        "못잤어", "설쳤어", "새벽", "꿈꿨어", "가위"
    ],
    # 긍정적인 감정 및 상태
    "positive": [
        "감사", "행복", "기쁨", "편안", "자신", "회복", "좋아", "즐거움",
        "신나", "재밌어", "뿌듯", "설레", "기대돼", "고마워", "다행", "상쾌"
    ],
}

# 강조어 & 부정어
EMPHASIS_WORDS = ["너무", "진짜", "완전", "엄청", "매우", "ㅈㄴ", "졸라", "존나"]
NEGATION_WORDS = ["안", "않", "아니", "없", "못"]
SLANG_AMBIGUOUS = ["개"]

GLOBAL_BOOST = 1.05  # 강조어 있을 때 모든 hit에 적용
DIST_K = 0.3        # 거리 기반 보정 상수


def tokenize(text: str):
    return [t.form for t in kiwi.tokenize(text)]


def rule_scoring(text: str):
    scores = {c: 0.0 for c in LEXICON}
    evidence = {c: [] for c in LEXICON}
    ignored_tokens = []  # 잡담 로그

    # -------- 0) 전처리: 토큰화 및 강조어 위치 파악 --------
    tokens = tokenize(text)
    debug_info = {"emphasis": [], "negation": False, "slang": []}
    
    emphasis_idx = [i for i, t in enumerate(tokens) if t in EMPHASIS_WORDS]
    has_emphasis = bool(emphasis_idx)
    if has_emphasis:
        debug_info["emphasis"] = [tokens[i] for i in emphasis_idx]

    negation_present = any(neg in text for neg in NEGATION_WORDS)
    if negation_present:
        debug_info["negation"] = True

    slang_present = [t for t in tokens if t in SLANG_AMBIGUOUS]
    if slang_present:
        debug_info["slang"] = slang_present

    # -------- 1) Hard hit (가장 강력한 키워드 우선 확인) --------
    for i, tok in enumerate(tokens):
        for cluster, keywords in CLUSTER_KEYWORDS.items():
            if tok in keywords:
                scores = {c: (1.0 if c == cluster else 0.0) for c in scores}
                evidence[cluster].append(tok)
                return scores, evidence, debug_info

    # -------- 2) Lexicon 기반 (일반 키워드 확인) --------
    matched_keywords = {} # (키워드, 클러스터, 위치) 저장

    for i, token in enumerate(tokens):
        for cluster, words in LEXICON.items():
            if token in words:
                # '집중이 안돼' -> '집중'처럼 단일 토큰으로 매칭되는 경우
                if token not in matched_keywords:
                    matched_keywords[token] = {'cluster': cluster, 'index': i}

    for cluster, words in LEXICON.items():
        for keyword in words:
            if keyword in text:
                # '정신없어'처럼 원본 텍스트에 포함되지만 토큰화 시 분리될 수 있는 경우
                # 토큰 기반으로 이미 매칭된 단어는 건너뛰어 중복 계산 방지
                if keyword not in matched_keywords:
                    try:
                        # 원본 텍스트에서 위치를 찾아 가장 가까운 토큰 인덱스로 변환
                        keyword_start_index_in_text = text.find(keyword)
                        # 이 위치에 가장 가까운 토큰 인덱스를 찾음 (근사치)
                        token_index = 0 
                        temp_pos = 0
                        for j, t in enumerate(tokens):
                            if temp_pos >= keyword_start_index_in_text:
                                token_index = j
                                break
                            temp_pos += len(t) + 1 # 띄어쓰기 고려
                        
                        matched_keywords[keyword] = {'cluster': cluster, 'index': token_index}
                    except:
                        # 위치 계산 실패 시를 대비한 예외 처리
                        matched_keywords[keyword] = {'cluster': cluster, 'index': -1}


    # -------- 3) 점수 계산 (강조어 보정 로직 복원) --------
    for keyword, info in matched_keywords.items():
        cluster = info['cluster']
        token_index = info['index']
        
        score = 0.3  # 기본 점수 (이전 0.2에서 상향 조정하여 영향력 강화)
        boost = 1.0

        # 강조어 거리 보정 
        if has_emphasis and token_index != -1:
            boost *= GLOBAL_BOOST
            # 가장 가까운 강조어와의 거리를 계산하여 보너스 점수 부여
            nearest = min(abs(token_index - e_idx) for e_idx in emphasis_idx)
            boost *= 1.0 + (DIST_K / (nearest + 1))

        score *= boost
        scores[cluster] = max(scores[cluster], score)
        if keyword not in evidence[cluster]:
            evidence[cluster].append(keyword)

    # 3. 무시된 토큰(ignored_tokens)
    all_matched_tokens = set()
    for keyword in matched_keywords.keys():
        # 매칭된 키워드를 구성하는 토큰들을 집합에 추가
        all_matched_tokens.update(tokenize(keyword))

    ignored_tokens = []
    for token in tokens:
        # 매칭된 적 없고, 강조어도 아닌 토큰을 ignored로 분류
        if token not in all_matched_tokens and token not in EMPHASIS_WORDS:
            ignored_tokens.append(token)
    debug_info['ignored'] = ignored_tokens


    # -------- 4) 부정어 보정 --------
    if negation_present:
        scores["positive"] = 0.0
        evidence["positive"] = []

    # -------- 5) 증거 없는 score 제거 --------
    for c in list(scores.keys()):
        if not evidence[c]:
            scores[c] = 0.0

    return scores, evidence, debug_info
