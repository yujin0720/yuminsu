import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_store.dart';

class AuthApi {
  // 에뮬레이터면 10.0.2.2, 실기기/시뮬레이터는 환경에 맞게 바꾸세요.
  static const String base = 'http://10.0.2.2:8000';

  /// 로그인 후 access_token을 저장하고 토큰 문자열을 반환합니다.
  static Future<String> login({
    required String idOrEmail,
    required String password,
  }) async {
    // ⚠️ 아래 body 키는 프로젝트에 맞게 바꾸세요.
    // Swagger에서 /auth/login 요청 스키마가 'email'인지 'username'인지 확인!
    final body = jsonEncode({
      'email': idOrEmail, // ← API가 username을 쓰면 'username'으로 변경
      'password': password,
    });

    final uri = Uri.parse('$base/auth/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception('Login failed: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> data = jsonDecode(res.body);
    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('No access_token in response');
    }

    await TokenStore.save(token); // ✅ 토큰 저장
    return token;
  }
}
