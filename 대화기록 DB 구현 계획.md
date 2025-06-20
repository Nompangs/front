### **최종 목표: '기억의 공백 없는' 대화 기억 기능 구현 (클라이언트 버전)**

**핵심 전략:** LLM(챗봇)이 응답을 생성할 때마다 **[가장 최신 요약본]**과 **[그 요약이 만들어진 직후부터 현재까지의 모든 대화 원문]**을 함께 참고하여, 정보 누락 없이 완벽한 맥락을 파악하게 하면서 장기적으로는 비용 효율성을 확보합니다.

**⚠️ 경고: 이 문서는 보안상 심각한 위험을 내포한 '클라이언트 직접 처리' 방식을 기준으로 작성되었습니다. 이 방식은 앱 내에 OpenAI API 키를 저장해야 하므로, 키 유출 시 심각한 금전적 피해로 이어질 수 있습니다. 이 방식은 사용자님의 명시적인 요구에 따라 작성된 것이며, **절대로 상용 서비스에는 권장되지 않습니다.** 안전한 구현을 위해서는 Firebase Blaze 요금제를 사용한 Cloud Functions 또는 다른 무료 백엔드 서비스를 이용해야 합니다.**

---

### **1. 데이터베이스 구조 설계 (Firebase Firestore)**

기존 `users`, `qr_profiles` 컬렉션과 조화롭게 동작하는 새로운 `conversations` 컬렉션을 설계합니다.

*   **`users` 컬렉션 (기존 유지)**
    *   **경로:** `users/{uid}`
    *   **역할:** 사용자 계정의 기본 정보 저장 (이메일, 이름 등)

*   **`qr_profiles` 컬렉션 (기존 유지)**
    *   **경로:** `qr_profiles/{uuid}`
    *   **역할:** 캐릭터(사물)의 모든 설정값(성격, 말투 등)을 저장하는 '캐릭터 설정집'

*   **`conversations` 컬렉션 (신규 생성)**
    *   **역할:** 특정 사용자와 특정 캐릭터 간의 모든 대화 내용과 요약본을 저장.
    *   **문서 ID:** `{uid}-{uuid}` (사용자 ID와 캐릭터 ID를 `-`로 조합하여 고유한 대화방 ID 생성. 두 ID를 알파벳순으로 정렬하여 항상 동일한 ID가 생성되도록 보장)
    *   **주요 필드:**
        *   `uid`: (String) 대화 참여 사용자의 고유 ID.
        *   `uuid`: (String) 대화 참여 캐릭터의 고유 ID.
        *   `summary`: (String) 이 대화의 내용을 압축한 최신 요약본.
        *   `summaryLastMessageTimestamp`: (Timestamp) **기억의 공백을 막는 핵심 필드.** 가장 마지막으로 요약에 포함된 메시지의 타임스탬프를 저장.
        *   `messageCount`: (Number) **클라이언트에서 요약 시점을 판단하는 핵심 트리거.**
        *   `lastMessageAt`: (Timestamp) 가장 최근 메시지의 타임스탬프 (채팅방 목록 정렬에 사용).
        *   `lastMessageText`: (String) 가장 최근 메시지의 텍스트 (채팅방 목록 미리보기에 사용).
    *   **하위 컬렉션: `messages`**
        *   **경로:** `conversations/{conversationId}/messages/{auto-generated-id}`
        *   **역할:** 실제 주고받은 모든 메시지를 시간 순으로 저장.
        *   **필드:** `text` (String), `sender` (String, 'user' 또는 'bot'), `timestamp` (Timestamp).

---

### **2. 구현 계획 (All in Client - Flutter)**

**전략:** 모든 요약 로직을 포함한 대화 관련 기능을 클라이언트 앱 내에서 직접 처리합니다. `ChatProvider`가 오케스트레이터 역할을 수행하며, `ConversationService`와 `OpenAiChatService`를 조율하여 기능을 완성합니다.

**A. 환경 설정**
*   **패키지:** `flutter_dotenv` 패키지를 사용하여 API 키를 관리합니다.
*   **`.env` 파일:** 프로젝트 루트에 `.env` 파일을 생성하고 `OPENAI_API_KEY=...` 형식으로 키를 저장합니다.
*   **`.gitignore`:** `.env` 파일이 Git 저장소에 포함되지 않도록 `.gitignore`에 반드시 추가합니다.
*   **`main.dart`:** 앱 시작 시 `dotenv.load()`를 호출하여 환경 변수를 로드합니다.

**B. `lib/services/openai_chat_service.dart` (수정)**
*   **역할:** OpenAI API와의 통신을 전담.
*   **수정/추가된 기능:**
    1.  `getResponseFromGpt(...)`: 기존의 GPT 응답 요청을 처리하는 비스트리밍 메서드.
    2.  **`summarizeConversation(currentSummary, messages)` (신규 핵심 기능):**
        *   `gpt-4o-mini` 모델을 사용하여 전달받은 이전 요약본과 최신 대화 목록을 바탕으로 새로운 요약본을 생성하고 문자열로 반환합니다.

**C. `lib/services/conversation_service.dart` (수정)**
*   **역할:** Firestore와의 모든 통신을 전담.
*   **수정/추가된 기능:**
    1.  `sendMessage(...)`: 메시지를 저장하고 `messageCount`를 1 증가시킵니다.
    2.  `getConversationContext(...)`: LLM에 보낼 '기억 데이터'(`요약본 + 후속 대화`)를 조회합니다.
    3.  `getMessagesStream(...)`: UI에 실시간 메시지 스트림을 제공합니다.
    4.  **`getConversationDocument(uuid)` (신규):** `messageCount`를 읽기 위해 `conversations` 문서를 통째로 가져옵니다.
    5.  **`updateSummary(uuid, summary)` (신규):** Firestore 문서의 `summary`와 `summaryLastMessageTimestamp` 필드를 업데이트합니다.

**D. `lib/providers/chat_provider.dart` (수정)**
*   **역할:** 상태 관리 및 서비스 오케스트레이션의 중심.
*   **수정 내용:**
    1.  `sendMessage(text)` 메서드 내에서 봇의 응답까지 성공적으로 저장한 후, `_triggerSummaryIfNeeded()`를 호출합니다.
    2.  **`_triggerSummaryIfNeeded()` (신규 핵심 로직):**
        *   `conversationService.getConversationDocument()`를 호출하여 `messageCount`를 가져옵니다.
        *   **`messageCount`가 10의 배수일 경우에만** 요약을 실행합니다.
        *   `conversationService.getConversationContext()`로 요약할 데이터를 가져옵니다.
        *   `openAiChatService.summarizeConversation()`을 호출하여 새로운 요약본을 받아옵니다.
        *   `conversationService.updateSummary()`를 호출하여 Firestore에 새로운 요약본을 저장합니다.

---

### **3. 향후 개선 및 고려사항 (Advanced Topics)**

**보안이 가장 시급한 개선 과제입니다.** 현재 구조는 프로토타이핑 단계에만 적합하며, 서비스 출시 전 반드시 아래 아키텍처 중 하나로 변경해야 합니다.

*   **Firebase Cloud Functions (Blaze 요금제):** 가장 간단하고 통합된 방식으로 서버 측 로직을 구현할 수 있습니다.
*   **무료 백엔드 서비스 (Cloudflare Workers 등):** Firebase 외 다른 서비스를 조합하여 완전 무료로 안전한 아키텍처를 구성할 수 있습니다.