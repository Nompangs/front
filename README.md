# Momenti(모멘티): 모든 사물이 친구가 되는 공간

🎥 [시연 영상](https://youtu.be/1reVGoPDxw4?feature=shared) | 🌐 [홈페이지](https://momenti.netlify.app/)
---

## **프로젝트 비전: 차가운 기계를 따뜻한 친구로**

> 어린 시절, 장난감과 대화하던 기억이 있으신가요? 토이 스토리처럼 모든 사물이 살아 움직인다면 어떨까요?
>
> **Momenti**는 1인 가구 1000만 시대의 외로움이라는 문제에서 출발했습니다. 우리는 주변의 모든 사물에 QR 코드 하나로 고유한 '성격'과 '기억'을 부여하여, 사용자와 정서적 유대를 맺는 '성격 있는 IoT' 시대를 열고자 합니다.
>
> 기계적인 **명령과 실행**의 관계를, 마음을 나누는 **대화와 관계**로 전환하는 것. 그것이 Momenti가 꿈꾸는 미래입니다.

---

## 🌟 Key Features

| 측면             | 성격 없는 기존 IoT                               | **Momenti의 성격 있는 IoT** |
| ---------------- | ------------------------------------------------ | ----------------------------------------------------- |
| **상호작용** | 명령 → 실행                                      | **대화 → 관계**                   |
| **사용 패턴** | 필요할 때만 사용                                 | **습관적, 일상적 사용**         |
| **감정 반응** | 무감정, 기계적 반응                              | **공감, 위로, 격려**        |
| **기억** | 없음 (매번 리셋)                                 | **과거 대화 기억**을 통한 개인화된 경험               |
| **문제 해결** | 오류 메시지 표시                                 | **상황을 이해하며 도움**         |

---

<h2 class="code-line" data-line-start=0 data-line-end=1 ><a id="__0"></a>팀원 소개</h2>

![team_nompangs](https://github.com/user-attachments/assets/fae9e303-419f-4598-ad7f-34a798bccc55)

<a href="https://github.com/blueberrycrumble"><img src="https://img.shields.io/badge/이혜승-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/Jsgithubchannel"><img src="https://img.shields.io/badge/홍지수-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/HWKKK"><img src="https://img.shields.io/badge/김해원-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/haepada"><img src="https://img.shields.io/badge/전승아-181717?style=for-the-badge&logo=github&logoColor=white"/></a>

---

### 1. **AI 페르소나 생성: 세상에 단 하나뿐인 나만의 친구 만들기**
- **7단계 온보딩 플로우:** 사용자와의 상호작용(이름, 사진, 사용 기간, 목적 등)을 통해 사물의 기본 정보를 입력받습니다.
- **심리학 기반 80개 변수 시스템:** GPT-4V의 이미지 분석과 사용자 입력을 결합하여, Fiske의 모델에 기반한 80개의 세분화된 성격 변수를 생성합니다.
- **사용자 최종 조정:** AI가 제안한 핵심 성격(따뜻함, 외향성, 유능함)을 사용자가 슬라이더로 직접 미세 조정하여 페르소나를 완성합니다.

### 2. **실시간 음성 대화: 1.2초 만에 응답하는 AI**
- **End-to-End 음성 처리:** OpenAI Realtime API를 통해 사용자의 말을 즉시 텍스트로 변환하고, LLM을 거쳐 다시 음성으로 생성하는 전 과정을 평균 1.2초 내에 완료합니다.
- **성격 기반 음성 선택:** 생성된 페르소나의 성격에 가장 잘 맞는 음성을 8가지 목소리 중 자동으로 선택하여 대화의 몰입감을 극대화합니다.

### 3. **QR 코드 연동: 모든 사물을 스마트하게**
- **즉시 연결:** 사물에 부착된 QR 코드를 스캔하는 즉시 해당 페르소나를 불러와 1초 안에 대화를 시작할 수 있습니다.
- **공유 및 확장성:** 생성된 페르소나의 QR 코드를 공유하여 다른 사람도 나의 사물과 대화하게 하거나, B2B 마케팅, 전시 등 다양한 분야로 확장할 수 있습니다.

### 4. **지속적인 관계 형성**
- **기억 저장:** 모든 대화는 Firebase에 저장되어, AI가 과거의 대화를 기억하고 사용자와의 관계를 발전시켜 나갑니다. 어제의 대화를 기억하는 친구처럼, Momenti의 페르소나는 점점 더 사용자와 친밀한 관계를 형성합니다.

---

## 🛠️ Tech Stack & Architecture

최고의 사용자 경험을 위해 검증된 최신 기술들을 조합하여 구축되었습니다.

- **Frontend:** `Flutter`
- **Backend & DB:** `Firebase (Firestore, Authentication)`, `Node.js (QR Profile)`
- **AI & Voice:** `OpenAI (GPT-4V, Realtime API, STT/TTS)`

---

## 🚀 Getting Started

프로젝트를 로컬 환경에서 실행하는 방법입니다.

### **Prerequisites**

- Flutter SDK (3.19.0 이상 권장)
- Firebase Account
- OpenAI API Key

### **Installation & Setup**

1.  **리포지토리 클론**
    ```bash
    git clone [https://github.com/your-username/nompangs-front.git](https://github.com/your-username/nompangs-front.git)
    cd nompangs-front
    ```

2.  **Flutter 패키지 설치**
    ```bash
    flutter pub get
    ```

3.  **Firebase 설정**
    - `firebase.json` 파일을 참고하여 자신의 Firebase 프로젝트를 설정합니다.
    - Android: `android/app/google-services.json` 파일을 추가합니다.
    - iOS: `ios/Runner/GoogleService-Info.plist` 파일을 추가합니다.

4.  **환경 변수 설정**
    - 프로젝트 루트에 `.env` 파일을 생성하고 아래 내용을 채워주세요. (실제 프로젝트에서는 `lib/services/api_service.dart` 등에서 관리되는 방식을 확인하세요.)
    ```
    OPENAI_API_KEY="여러분의 OpenAI API 키"
    API_BASE_URL="백엔드 서버 URL (e.g., QR 프로필 관리)"
    ```

5.  **앱 실행**
    ```bash
    flutter run
    ```

---

## 📁 Project Structure

프로젝트는 기능별로 체계적으로 관리되며, 주요 디렉토리 구조는 다음과 같습니다.
