# 🥑 DailyMoji – AI 기반 감정 관리 앱

> **“당신의 하루는 어떤 이모지였나요?”**  
> 단순한 감정 기록을 넘어, 부정적인 감정의 고리를 끊고  
> 관리를 통해 긍정적인 변화로 이어지는 놀라운 경험을 시작해 보세요!
<div align="center">
<img width="500" alt="커버 이미지_데일리모지" src="https://github.com/user-attachments/assets/b5e0d425-7163-41a8-859f-4d6fee61e266" />
<img width="500" alt="Thank you QR" src="https://github.com/user-attachments/assets/8ed73a76-ed4b-49f4-a4cb-1535133d661a" />
</div>

---

## 🧩 프로젝트 개요

현대인이라면 누구나 스트레스, 불안, 번아웃을 경험합니다.  
하지만 감정을 다루는 방법은 여전히 어렵고, 복잡하며, 부담스럽게 느껴집니다.  

**DailyMoji(데일리모지)** 는 이러한 문제의식에서 출발했습니다.  
감정을 단순히 기록하는 앱이 아닌,  
AI를 통해 감정을 분석하고 즉시 실행 가능한 **마음 관리 팁**을 제공하는 앱입니다.

> “감정을 문제로 보지 말고, 신호로 바라보자.”

DailyMoji는 사용자의 감정 상태를 뇌 과학적으로 분석하여  
호흡, 영상, 행동 미션 등 **마음 관리 팁**을 실시간으로 제안합니다.  
감정을 인식하고 조절하는 과정을 돕는 **AI 기반 멘탈 케어 파트너**입니다.

---

## 🎯 주요 타깃 사용자

✅ 스트레스, 불안, 번아웃을 겪는 직장인 및 학생  
✅ 자신의 감정을 이해하고 체계적으로 관리하고 싶은 사람  
✅ 심리 상담은 부담스럽지만 가벼운 멘탈 케어 솔루션이 필요한 사람  
✅ 자기 성장과 감정 관리에 관심이 많은 사람  

---

## 🧠 주요 기능

<div align="center">
<img width="1920" height="1080" alt="데일리모지0" src="https://github.com/user-attachments/assets/8442375e-9d08-4c7f-b8af-c385f4df19d8" />
<img width="1920" height="1080" alt="데일리모지1" src="https://github.com/user-attachments/assets/9986304c-e36a-4c67-9c67-6fa8190c0d61" />
<img width="1920" height="1080" alt="데일리모지2" src="https://github.com/user-attachments/assets/ff449773-31df-4ce7-9e99-d7e1938e07e3" />
<img width="1920" height="1080" alt="데일리모지3" src="https://github.com/user-attachments/assets/e28fcfdb-21a8-4649-b24b-faad350ae6c9" />
</div>

### 1️⃣ 감정 기록 및 분석
- 하루의 감정을 **이모지 한 개로 표현**
- “짜증 나요”, “무기력해요” 등 텍스트 입력 시 AI가 **정서 점수화**
- 부정·긍정 클러스터 기반으로 감정 상태 분류

### 2️⃣ AI 감정 코칭
- **GPT + FastAPI + Supabase 연동**으로 실시간 감정 대화
- 뇌인지과학 기반의 감정 분석 엔진을 통해 개인별 감정 패턴 해석
- 대화 내용에 따라 즉각적으로 아래 세 가지 관리 팁 제시:
  - 🫁 **호흡 팁**: 심박 안정 중심의 호흡법 제공  
  - 🎬 **영상 팁**: ASMR, 심리 안정 영상을 추천  
  - ✅ **행동 미션**: 뽀모도로 기반의 행동 코칭 제공

### 3️⃣ 감정 리포트
- **모지 차트(Moji Chart)** 로 감정 변화를 시각화  
- 최근 2주간의 감정 흐름을 **요약 리포트**로 제공  
- 하루 중 가장 두드러진 감정을 달력 형태로 표시  
- 감정 리포트를 통해 **객관적인 자기 감정 인식** 가능

### 4️⃣ 온보딩 & 캐릭터 설정
- 첫 실행 시 간단한 감정 검사로 현재 상태 파악  
- 사용자만의 도우미 캐릭터 선택 (햄보카도 🥑 / 캐로리 🥕)  
- 이름을 직접 정하고 맞춤 대화 경험 시작  
- 온보딩 중 3장짜리 가이드 화면으로 앱 목적 명확화  

### 5️⃣ 튜토리얼 & UX 개선
- 첫 진입 시 주요 기능과 이동 동선을 시각적으로 안내  
- 사용성 테스트 결과를 반영하여 UI 흐름을 단순화  
- 감정 선택 → 대화 → 솔루션 → 리포트로 자연스럽게 이어지는 구조

---

## ⚙️ 기술 스택

| 구분 | 기술 |
|------|------|
| **Architecture** | Clean Architecture |
| **Design Pattern** | Repository Pattern, Provider Pattern |
| **State Management** | Riverpod |
| **Frontend** | Flutter, GoRouter, ScreenUtil |
| **Backend** | FastAPI (Python), Supabase |
| **Database** | Supabase (Auth, Storage, Realtime DB) |
| **AI/ML** | OpenAI GPT, Kiwi (한국어 NLP) |
| **Auth** | Google Sign-In, Apple Sign-In |
| **Network** | REST API, HTTP |
| **Async Task** | Future, Async/Await |
| **UI/UX** | Figma, Shimmer, flutter_svg |
| **Media/Chart** | WebView, FL Chart, Table Calendar |
| **Deployment** | Render, Docker |
| **Platform** | Android, iOS |

---

## 🧩 기술적 의사결정

### 🔹 Riverpod
Provider보다 구조적이고 테스트에 용이한 상태관리 방식.  
`Notifier`, `AsyncNotifier`, `StreamNotifier`를 활용해  
비동기 데이터 흐름을 명확하게 분리하고 코드 재사용성을 높였습니다.

### 🔹 FastAPI + Supabase
- FastAPI로 AI 분석 API를 구성하고, Supabase를 통해 인증/데이터 연동  
- Supabase의 실시간 구독(Realtime) 기능을 활용하여 **즉각적인 채팅 반응성** 확보  
- Supabase Storage를 통한 이미지/파일 관리 및 백엔드 허브 역할 수행

### 🔹 Firebase Messaging
푸시 알림을 통한 사용자 피드백,  
알림 기반 감정 회상 리마인더 기능 실험 중

### 🔹 UI/UX 개선 기술
- **Shimmer 효과**: 로딩 대기 중 Skeleton UI 적용  
- **flutter_svg**: SVG 아이콘으로 해상도 독립적인 인터페이스 구성  
- **ScreenUtil**: 기기별 반응형 레이아웃 지원

---

## 💡 트러블슈팅 사례

| 문제 | 원인 | 해결 |
|------|------|------|
| **AI 후속 응답이 오지 않음** | `GoRouter` 이동 시 ViewModel 상태 초기화 | `extra` 데이터를 통해 이전 상태 전달 로직 추가 |
| **Apple 로그인 실패 (Supabase)** | Bundle ID / Service ID 혼동 | Apple Developer Console 설정 정리 및 JWT 직접 생성 |
| **Supabase 쿼리 속도 저하** | `user_id`, `created_at` 인덱스 미적용 | 인덱스 추가로 조회 성능 3배 향상 |
| **pip 명령어 인식 불가 (Windows)** | PATH 미등록 문제 | `python -m pip install` 명령으로 대체 설치 |
| **iOS 인증서 연동 오류** | Team ID / Key ID 혼동 | Apple Developer Portal에서 명확히 구분 후 재등록 |

> 💬 개발 과정에서 가장 크게 배운 점  
> "개발은 코드를 짜는 일이 아니라, 시스템 전체를 이해하고  
> 끈기 있게 원인을 추적하는 과정"임을 실감했습니다.

---

## 🚀 향후 계획

### 🧭 대화 시작 돕기 (Suggested Prompts)
사용자가 대화를 시작하기 어려워하지 않도록  
상황별 **추천 문장 자동 제시 기능** 추가 예정

### 🌐 다국어(Localization)
한국어뿐 아니라 영어 인터페이스 지원  
기기 언어 자동 감지 및 앱 내 언어 전환 기능 추가

### 🧾 주간 감정 리포트 (Weekly Report)
한 주간의 감정 변화를 뇌과학적 관점에서 해석한  
**AI 기반 주간 리포트 발행 기능** 준비 중

### 🧠 감정 인식 모델 고도화
OpenAI + Kiwi를 통한 하이브리드 감정 분석 엔진 개선  
더 높은 정밀도의 감정 클러스터링 적용 예정

---

## 👥 팀 구성

| 이름 | 역할 | Contact |
|---------|------|---------|
| [임기환](https://github.com/Kihwan-dev/) (팀장) | 앱 구조 총괄 / 전체 아키텍처 설계 / 채팅페이지 & 마이페이지 UI 및 기능 개발 / Supabase 데이터베이스 설계 / 서버 배포 및 운영 관리 / 푸시 알림 / Supabase Cron Job / GitHub 환경 구축 / 다국어 대응 시스템 설계 | rlrkf2420@gmail.com |
| [김현수](https://github.com/hyun471) (부팀장) | Google/Apple 소셜 로그인 UI 구성 및 기능 개발 / 로그아웃, 회원 탈퇴 UI 및 기능 개발 / 온보딩 화면 UI 구성 및 기능 개발 / 가이드 화면 UI 구성 및 기능 개발 / 마음 알기 화면 UI 구성 및 기능 개발, 이용약관 화면 UI 구성 / 알림 설정(FCM 및 Supabase Cron Job) / Font/Image 스타일화 / 클린 아키텍처 설계 | khs101ttl@gmail.com |
| [정소린](https://github.com/So2ln) (팀원) | 백엔드 개발 및 연결 / LLM 연결 / SRJ-5(감정분석) 시스템 개발 | kristyso2ln@gmail.com |
| [조민우](https://github.com/wackyturtle) (팀원) | 클린 아키텍처 기반 데이터 관리 / 홈 페이지 UI구현 / 리포트 페이지 UI구현 / 솔루션 페이지 UI구현 / fl_chart, table_calendar를 통한 시각적 데이터 표현 / Firebase Messaging(FCM)구현 / supabase CronJob을 통한 스케줄링 | wcytutl01@gmail.com |
| 이빛나 (디자이너) | 콘텐츠 기획 / 리포트 구성 및 UX 플로우 | lbn9019@naver.com |

---

> **"감정은 사라지는 것이 아니라, 관리되는 것이다."**  
> 데일리모지와 함께 매일의 감정을 기록하고, 이해하고, 회복하세요. 💚
