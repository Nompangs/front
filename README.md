# Momenti(모멘티): 모든 사물이 친구가 되는 공간

## 🎥 [시연 영상](https://youtu.be/1reVGoPDxw4?feature=shared) | 🌐 [홈페이지](https://momenti.netlify.app/)

![Momenti(모멘티)](https://github.com/user-attachments/assets/516e44af-6893-4839-9f69-53ebdb936c5b)

---

<h2 class="code-line" data-line-start=0 data-line-end=1 ><a id="__0"></a>팀원 소개</h2>

![team_nompangs](https://github.com/user-attachments/assets/fae9e303-419f-4598-ad7f-34a798bccc55)

<a href="https://github.com/blueberrycrumble"><img src="https://img.shields.io/badge/이혜승-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/Jsgithubchannel"><img src="https://img.shields.io/badge/홍지수-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/HWKKK"><img src="https://img.shields.io/badge/김해원-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/haepada"><img src="https://img.shields.io/badge/전승아-181717?style=for-the-badge&logo=github&logoColor=white"/></a>

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
