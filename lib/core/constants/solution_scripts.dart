// lib/core/constants/solution_scripts.dart

// 1. 과학적 설명 멘트 라이브러리
const Map<String, List<String>> kClusterSummaryScripts = {
  "neg_low": [
    "뇌의 보상 회로(Ventral Striatum)가 잠시 저활성화되어 의욕이 줄어든 것 같아요.",
    "전두엽(PFC)의 에너지 조절 기능이 떨어져 무기력감이 커진 것 같아요.",
    "DMN(Default Mode Network)이 과활성되면서 부정적 사고가 반복되고 있어요."
  ],
  "neg_high": [
    "편도체(Amygdala)가 예민하게 반응하면서 경보 시스템이 과활성된 상태예요.",
    "HPA axis가 항진되어 몸과 마음이 긴장 상태로 유지되고 있어요.",
    "Insula가 과도하게 활성화되어 불안·분노 신호를 크게 증폭시키고 있어요."
  ],
  "adhd_high": [
    "전전두엽(PFC)의 주의 조절 기능이 저하되어 집중 유지가 어렵네요.",
    "도파민 회로의 불균형으로 충동적 행동이 늘어난 상태예요.",
    "전두엽-선조체 회로가 약해져 계획과 실행이 매끄럽지 못한 것 같아요."
  ],
  "sleep": [
    "시상하부(Hypothalamus)의 수면-각성 조절 기능이 불안정해진 상태예요.",
    "HPA axis 과활성으로 뇌가 각성을 유지하려는 경향이 강해요.",
    "멜라토닌 분비 리듬이 흐트러져 숙면 진입이 어려워진 듯해요."
  ],
  "positive": [
    "전전두엽과 대상피질(PFC–ACC)이 활성화되어 회복력 있는 상태예요.",
    "보상 회로와 편도체 사이의 조절력이 강화되어 긍정 감정이 잘 유지되고 있어요.",
    "부교감신경(HRV↑)이 활성화되어 몸과 마음이 안정된 상태예요."
  ]
};

// 2. 솔루션 제안 멘트 라이브러리
const Map<String, List<String>> kSolutionProposalScripts = {
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
};

// 3. 최종 솔루션 정보 라이브러리
const Map<String, Map<String, String>> kSolutionsDb = {
  // neg_low
  "neg_low_beach_01": {
    "text": "지금은 속이 탁 트이는 바닷가로 잠시 자리를 옮겨볼까요?",
    "type": "video",
    "url": "https://youtu.be/n4Mdh3TEq_k?si=ZuJEn6CXJImRQ6nj",
    "startAt": "420", // 7분 = 420초
    "endAt": "540" // 9분 = 540초
  },
  "neg_low_turtle_01": {
    "text": "자유로이 헤엄치는 거북이를 따라가며, 깊은 바다 속으로 시선을 옮겨보세요.", //-> TODO: 이거 연결안됨
    "type": "video",
    "url": "https://youtu.be/9xQ6YlaYYHI?si=MuzNJcEO11iB_V0f",
    "startAt": "0",
    "endAt": "180"
  },
  "neg_low_snow_01": {
    "text": "하얀 눈 내리는 밤길을 걸으면서 고요한 소리에 마음을 맡겨보세요.",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=31RokLEvUhg",
    "startAt": "1290", // 21분 30초 = 1290초
    "endAt": "1440"
  },

  // neg_high
  "neg_high_cityview_01": {
    "text": "창밖 도시 불빛과 떨어지는 빗방울을 바라보며, 호흡을 가다듬어볼까요?",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=xg1gNlxto2M",
    "startAt": "0",
    "endAt": "120"
  },
  "neg_high_campfire_01": {
    "text": "강가의 모닥불처럼 감정을 흡수해줄 탁 트인 공간이 필요해요.",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=6nlEmH7eZLk",
    "startAt": "20",
    "endAt": "140"
  },
  "neg_high_heartbeat_01": {
    "text": "엄마 뱃속처럼 고요한 물속에서 심장소리에 집중하면, 뇌가 점차 안정된 리듬을 회복하게 돼요.",
    "type": "video",
    "url": "https://youtu.be/vuctJwSi2To?si=UYXDQJOIFD9G3cSa",
    "startAt": "8",
    "endAt": "129"
  },

  // adhd_high
  "adhd_high_space_01": {
    "text": "우주 공간처럼 자극이 최소화된 환경이 효과적이에요.",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=qRitf7c3-nQ",
    "startAt": "0",
    "endAt": "120"
  },
  "adhd_high_pomodoro_01": {
    "text": "딱 5분만, 가장 쉬운 일부터 시작해볼까요?",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=TA9SZawYm2k",
    "startAt": "0",
    "endAt": "120"
  },
  "adhd_high_training_01": {
    "text": "공의 움직임을 따라가보세요! 집중력이 켜질겁니다!",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=E7HOlJ_OhEo",
    "startAt": "0",
    "endAt": "120"
  },

  // sleep
  "sleep_forest_01": {
    "text": "잔잔한 숲 속 텐트 안에 누운 듯, 빗방울 소리에 몸을 맡겨보세요.",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=IdTRKv2jLo4",
    "startAt": "10",
    "endAt": "130"
  },
  "sleep_onsen_01": {
    "text": "온천의 따뜻한 품에서 물소리와 풀벌레 소리에 집중해보세요.",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=fz1f05GRSvA",
    "startAt": "20",
    "endAt": "140"
  },
  "sleep_plane_01": {
    "text": "포근한 기내 좌석에 기대듯, 엔진 소리에 안정을 맡겨보세요.",
    "type": "video",
    "url": "https://youtu.be/LuMBRy_gly4?si=9_XpJLlhRgXJhCQT",
    "startAt": "3540", // 59분 = 3540초
    "endAt": "3600"
  },

  // positive
  "positive_forest_01": {
    "text": "햇살 가득한 숲에 앉아 호흡하며 그 기분을 오래 저장해보세요.",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=su14Bo0-uMI&list=LL&index=4",
    "startAt": "0",
    "endAt": "120"
  },
  "positive_beach_01": {
    "text": "푸른 하늘과 흰 구름 아래에 있는 상상을 해보세요.",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=M_Q3YNlWfyA",
    "startAt": "0",
    "endAt": "120"
  },
  "positive_cafe_01": {
    "text": "재즈가 흐르는 카페와 같은 공간과 함께 할 때 뇌가 회복탄력성을 더 강하게 저장해요.",
    "type": "video",
    "url": "https://www.youtube.com/watch?v=NJuSStkIZBg",
    "startAt": "0",
    "endAt": "120"
  }
};
