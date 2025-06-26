<div align="center">
    
# Momenti(모멘티)
    
## 🎥 [시연 영상](https://youtu.be/1reVGoPDxw4?feature=shared) | 🌐 [홈페이지](https://momenti.netlify.app/)

</div>

![Momenti(모멘티)](https://github.com/user-attachments/assets/9e233750-30f4-461a-8f96-ba5e4e93d968)

## 🧑‍🧑‍🧒‍🧒 Team

![team_nompangs](https://github.com/user-attachments/assets/fae9e303-419f-4598-ad7f-34a798bccc55)

<a href="https://github.com/blueberrycrumble"><img src="https://img.shields.io/badge/이혜승-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/Jsgithubchannel"><img src="https://img.shields.io/badge/홍지수-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/HWKKK"><img src="https://img.shields.io/badge/김해원-181717?style=for-the-badge&logo=github&logoColor=white"/></a>
<a href="https://github.com/haepada"><img src="https://img.shields.io/badge/전승아-181717?style=for-the-badge&logo=github&logoColor=white"/></a>

<details>
<summary>📁 Project Structure</summary>

```
nompangs/front/
├── pubspec.yaml            # Dart/Flutter 패키지 의존성 및 프로젝트 설정 파일
├── firebase.json           # Firebase 프로젝트 설정 파일
├── docs/                   # 프로젝트 관련 문서
├── lib/                    # Flutter 애플리케이션의 핵심 소스 코드
│   ├── main.dart           # 애플리케이션의 시작점 (Entry Point)
│   ├── services/           # // 외부 서비스 연동 (API, DB, 인증 등)
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   └── realtime_chat_service.dart # // 실시간 채팅 서비스
│   ├── models/             # // 앱에서 사용하는 데이터 구조 (데이터 클래스)
│   │   ├── onboarding_state.dart
│   │   └── personality_profile.dart
│   ├── providers/          # // 앱의 상태(State)를 관리
│   │   ├── chat_provider.dart
│   │   └── onboarding_provider.dart
│   ├── screens/            # // 애플리케이션의 각 화면 UI
│   │   ├── auth/           # // 인증 (로그인, 회원가입) 관련 화면
│   │   ├── main/           # // 앱의 주요 기능 (홈, 채팅 등) 화면
│   │   └── onboarding/     # // 사용자 온보딩 프로세스 화면
│   ├── widgets/            # // 여러 화면에서 재사용되는 공통 UI 컴포넌트
│   │   ├── bottom_nav_bar.dart
│   │   └── personality_chart.dart
│   ├── helpers/            # // 딥링크 등 보조 기능을 담당하는 헬퍼 클래스
│   │   └── deeplink_helper.dart
│   ├── theme/              # // 앱의 전체적인 테마 (색상, 폰트 등) 설정
│   │   └── app_theme.dart
│   └── utils/              # // 프로젝트 전반에서 사용되는 유틸리티 함수
│       ├── colors.dart
│       └── persona_utils.dart
```
</details>

<details>
<summary>📖 Appendix</summary>
    
![Momenti_nompangs_aiffelthon_250624 (30)](https://github.com/user-attachments/assets/536c9dd1-4b47-4e7b-887e-9ee904ceb032)
![Momenti_nompangs_aiffelthon_250624 (31)](https://github.com/user-attachments/assets/eeebd79e-5833-4e85-b440-cb99aaa8fbcc)
![Momenti_nompangs_aiffelthon_250624 (32)](https://github.com/user-attachments/assets/47badf49-e403-48ad-9130-a3559ee125ad)
![Momenti_nompangs_aiffelthon_250624 (33)](https://github.com/user-attachments/assets/9e7689a9-72f1-4982-83cb-0f712e2e8d6b)
![Momenti_nompangs_aiffelthon_250624 (34)](https://github.com/user-attachments/assets/947b5a1c-0610-4e99-aa78-4da6e49a0960)

</details>

<details>
<summary>🚀 Getting Started</summary>

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
</details>


