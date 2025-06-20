import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAiChatService {
  static final OpenAiChatService _instance = OpenAiChatService._internal();
  bool _isInitialized = false;

  factory OpenAiChatService() {
    return _instance;
  }

  OpenAiChatService._internal();

  void _initializeIfNeeded() {
    if (!_isInitialized) {
      OpenAI.apiKey = dotenv.env['OPENAI_API_KEY']!;
      _isInitialized = true;
    }
  }

  Future<String> getResponseFromGpt(String? summary,
      List<Map<String, dynamic>> recentMessages, String userMessage) async {
    _initializeIfNeeded();

    final systemContent =
        "You are a helpful and friendly conversational AI. Your persona is defined by the user. If a summary of the past conversation is provided, use it as context. Past conversation: ${summary ?? 'No summary yet.'}";

    final messages = [
      OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(systemContent)
        ],
        role: OpenAIChatMessageRole.system,
      ),
      ...recentMessages.map((msg) {
        return OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
                msg['content'])
          ],
          role: msg['role'] == 'user'
              ? OpenAIChatMessageRole.user
              : OpenAIChatMessageRole.assistant,
        );
      }).toList(),
      OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage)
        ],
        role: OpenAIChatMessageRole.user,
      ),
    ];

    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4o-mini",
        messages: messages,
      );
      return chatCompletion.choices.first.message.content?.first.text ??
          "Sorry, I couldn't process that.";
    } catch (e) {
      debugPrint("Error getting response from GPT: $e");
      return "An error occurred while contacting the AI: $e";
    }
  }

  Future<String> summarizeConversation(String? currentSummary,
      List<Map<String, dynamic>> messagesToSummarize) async {
    _initializeIfNeeded();

    final prompt = """
Summarize the following conversation.
Current summary:
${currentSummary ?? "None"}

Recent messages to add to summary:
${messagesToSummarize.map((m) => "${m['role']}: ${m['content']}").join('\n')}

New, concise summary:
""";

    try {
      final response = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );
      return response.choices.first.message.content?.first.text ??
          "Failed to summarize.";
    } catch (e) {
      debugPrint("Error summarizing conversation: $e");
      return "Error in summary: $e";
    }
  }
}