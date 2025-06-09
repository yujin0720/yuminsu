# yuminsu

# 📚 iPlanner – AI 기반 개인 학습 플래너

**iPlanner**는 시험 일정과 학습 자료를 기반으로 AI가 자동으로 계획을 생성하고, 공부 시간을 기록하며, 필기 기능까지 제공하는 **개인 맞춤형 학습 관리 애플리케이션**입니다.  
백엔드는 **FastAPI**, 프론트엔드는 **Flutter**로 구성되어 있으며, 모바일과 웹 환경 모두에서 사용할 수 있도록 설계되었습니다.

---

## 🚀 주요 기능

- ✍️ **학습 자료 관리**  
  시험 분야, 시험 날짜, 공부 기간, 자료명(책, 인강 등)과 반복 횟수 입력

- 🤖 **AI 계획 생성**  
  입력한 기간과 학습량을 기반으로 AI가 자동으로 날짜별 학습 계획 배정

- 📅 **주간/일간 할 일 관리**  
  요일별 계획 확인 및 체크박스로 완료 처리, 달성률 계산

- ⏱️ **실시간 공부 시간 측정**  
  타이머 기능으로 실제 공부 시간 측정 및 누적 시간 저장

- 📝 **PDF 필기 기능**  
  펜/형광펜/지우개/라쏘 선택, 필기 저장, 썸네일 미리보기 등 제공

- 👤 **마이페이지**  
  사용자 정보 수정, 선호 공부 시간 설정, 주간 공부 통계 확인


## backend

FastAPI 기반의 서버 코드로, 사용자 인증, 공부 시간 저장, 계획 조회 등의 API 기능을 제공합니다.

- '.venv/' : 	가상 환경 폴더. 파이썬 패키지들이 설치되어 있으며, requirements.txt 기준으로 재생성함
- '__pycache__'	: 파이썬이 컴파일한 .pyc 캐시 파일
- 'alembic/' :	DB 마이그레이션 폴더
- 'models/':	SQLAlchemy 모델 정의 폴더
- 'routers/' :	API 엔드포인트를 모듈별로 정리한 FastAPI 라우터 파일
- 'schemas/' :	Pydantic 모델 정의 폴더
- 'services/' :	로직 분리용 서비스 계층입니다. 모델/라우터와 분리된 실제 처리 로직(예: AI 계획 생성 등)
- 'static/' :	정적 파일(CSS, JS, 이미지 등)이 위치할 수 있는 폴더
- 'utils/' :	유틸리티 함수나 공통 로직을 모아둔 폴더

## frontend

Flutter로 구현된 클라이언트 앱으로, 사용자 인터페이스를 통해 공부 시간 기록, 학습 계획 확인, 마이페이지 등을 제공합니다.

### 폴더 설명

- `android/`: 안드로이드 빌드를 위한 설정 파일 포함 (AndroidManifest.xml, build.gradle 등)
- `assets/`: 이미지, 아이콘, 폰트 등 앱에서 사용하는 정적 리소스 저장
- `ios/`: iOS 빌드를 위한 설정 파일 포함 (Info.plist 등)
- `lib/`: 앱의 핵심 로직과 UI가 구현된 Dart 코드가 위치  
  ㄴ `edit_profile_page.dart`: 사용자 이름, 이메일, 연락처 수정 및 비밀번호 변경 화면  
  ㄴ `folder_home_page.dart`: 필기 노트 목록을 폴더 형태로 관리하는 홈 화면  
  ㄴ `login_page.dart`: 로그인 화면 (ID, 비밀번호 입력 및 토큰 저장 처리 포함)   
  ㄴ `main.dart`: 앱 실행 진입점 및 라우팅 설정  
  ㄴ `mypage.dart`: 마이페이지 - 사용자 프로필, 주간 공부 시간, 실제 공부 시간 확인  
  ㄴ `note_list_page.dart`: 특정 폴더 내의 노트 리스트를 보여주는 화면  
  ㄴ `note_page.dart`: PDF 필기 기능 제공 - 하이라이트, 펜, 지우개, 썸네일 생성 등 포함  
  ㄴ `password_check_page.dart`: 개인 정보 접근 전 비밀번호 재확인 페이지  
  ㄴ `signup_page.dart`: 회원가입 화면 (생년월일, 전화번호, 비밀번호 등 입력)  
  ㄴ `splash_page.dart`: 앱 실행 시 첫 화면, 토큰 유무에 따라 자동 로그인 처리  
  ㄴ `study_result.dart`: 학습 완료 체크 화면 - 주차별 항목 체크 UI 제공  
  ㄴ `studyplan.dart`: 시험 날짜와 학습 자료를 설정하면 AI가 계획 자동 생성  
  ㄴ `submain.dart`: 주간 학습 계획 화면 (요일별 체크박스 및 계획 수정 UI)  
  ㄴ `timer.dart`: 공부 시간 측정용 타이머 UI 화면  
  ㄴ `timer_provider.dart`: 타이머 상태 관리, 누적 시간 계산, 서버 저장 및 불러오기 기능  
  ㄴ `todo_provider.dart`: 오늘/주간 할 일 상태 관리 및 서버 동기화 처리  

- `linux/`, `macos/`, `windows/`: 데스크탑 플랫폼용 빌드 관련 파일
- `test/`: 단위 테스트 코드
- `web/`: 웹 앱 빌드 설정 및 정적 리소스

### 파일 설명

- `.gitignore`: Git에 포함시키지 않을 파일 정의  
- `.metadata`: Flutter에서 내부적으로 사용하는 메타데이터  
- `README.md`: 프로젝트 설명 문서  
- `analysis_options.yaml`: Dart 분석기 설정  
- `pubspec.yaml`: 프로젝트 의존성 및 설정 정의  
- `pubspec.lock`: 실제로 설치된 의존성의 버전이 기록된 파일 (자동 생성)

