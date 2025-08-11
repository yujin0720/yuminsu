// lib/notification_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 에뮬레이터/웹 동시 대응
final String _baseUrl =
    kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final isReadRaw = j['is_read'] ?? j['isRead'] ?? false;
    return AppNotification(
      id: (j['notification_id'] ?? j['id']) as int,
      title: (j['title'] ?? '').toString(),
      body:
          (j['body'] ?? j['message'] ?? '').toString(), // ← body/message 모두 대응
      createdAt:
          DateTime.tryParse((j['created_at'] ?? j['createdAt']).toString()) ??
          DateTime.now(),
      isRead: (isReadRaw == true || isReadRaw == 1), // ← 0/1, bool 모두 대응
    );
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// 상단 배지
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<Map<String, String>> _headers() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('accessToken') ?? '';
    if (token.isEmpty) {
      throw Exception('No JWT token');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// 알림 목록 조회
  Future<List<AppNotification>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await http.get(
      // 슬래시 붙여서 307 회피
      Uri.parse('$_baseUrl/notifications/?limit=$limit&offset=$offset'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('알림 조회 실패: ${res.statusCode} ${res.body}');
    }

    final raw = jsonDecode(utf8.decode(res.bodyBytes));
    final List<AppNotification> list;
    if (raw is List) {
      list =
          raw
              .whereType<Map>()
              .map((e) => AppNotification.fromJson(e.cast<String, dynamic>()))
              .toList();
    } else if (raw is Map && raw['results'] is List) {
      list =
          (raw['results'] as List)
              .whereType<Map>()
              .map((e) => AppNotification.fromJson(e.cast<String, dynamic>()))
              .toList();
    } else {
      list = const <AppNotification>[];
    }

    unreadCount.value = list.where((n) => !n.isRead).length;
    return list;
  }

  /// 미읽음 개수 조회 (/notifications/unread-count)
  Future<int> fetchUnreadCount() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/notifications/unread-count'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      // 실패하면 목록으로 보정
      await fetchNotifications();
      return unreadCount.value;
    }
    final data = json.decode(utf8.decode(res.bodyBytes));
    final c = (data is Map) ? (data['unread'] ?? data['count'] ?? 0) : 0;
    final cnt = c is int ? c : int.tryParse(c.toString()) ?? 0;
    unreadCount.value = cnt;
    return cnt;
  }

  /// 개별 읽음 처리 (백엔드: PUT /notifications/read  body: {"ids":[id]})
  Future<void> markAsRead(int id) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/notifications/read'),
      headers: await _headers(),
      body: jsonEncode({
        'ids': [id],
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('읽음 처리 실패: ${res.statusCode} ${res.body}');
    }
    // 서버 재조회 없이 배지 즉시 감소
    unreadCount.value = (unreadCount.value - 1).clamp(0, 9999);
  }

  /// 전체 읽음 처리 (백엔드: PUT /notifications/read-all)
  Future<void> markAllAsRead() async {
    final res = await http.put(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('전체 읽음 처리 실패: ${res.statusCode} ${res.body}');
    }
    unreadCount.value = 0;
  }
}
