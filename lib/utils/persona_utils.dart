import 'dart:convert';
import 'package:crypto/crypto.dart';

class PersonaUtils {
  // PersonaId 생성 (Hash 기반)
  static String generateId(String name, List<String> tags, String greeting) {
    final input = {
      'name': name,
      'tags': tags..sort(),
      'greeting': greeting
    };

    final inputString = jsonEncode(input);
    final bytes = utf8.encode(inputString);
    final digest = sha256.convert(bytes);

    return "persona_${digest.toString().substring(0, 16)}";
  }
}
