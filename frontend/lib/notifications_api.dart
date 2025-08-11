// lib/services/notifications_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ❗에뮬레이터면 10.0.2.2, 실기기면 PC IP로 바꿔줘.
const String baseUrl = "http://10.0.2.2:8000";

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('accessToken');
}

Future<void> markNotificationRead(int id) async {
  final token = await _getToken();
  if (token == null) throw Exception("no token");

  final res = await http.put(
    Uri.parse("$baseUrl/notifications/read"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "ids": [id],
    }),
  );
  if (res.statusCode != 200) {
    throw Exception("읽음 처리 실패: ${res.statusCode} ${res.body}");
  }
}

Future<void> markAllNotificationsRead() async {
  final token = await _getToken();
  if (token == null) throw Exception("no token");

  final res = await http.put(
    Uri.parse("$baseUrl/notifications/read-all"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode != 200) {
    throw Exception("모두 읽음 실패: ${res.statusCode} ${res.body}");
  }
}
