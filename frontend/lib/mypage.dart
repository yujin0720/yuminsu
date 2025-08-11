import 'package:flutter/material.dart';
import 'password_check_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'timer_provider.dart';
import 'package:intl/intl.dart';
import 'study_type_page.dart';

import 'open_notifications.dart';
import 'notification_service.dart'; // 공용 알림 서비스(배지/목록/읽음)

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String name = '';
  String loginId = '';
  String email = '';
  String phone = '';
  String password = '********';

  DateTime selectedWeek = DateTime.now();
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];

  Map<String, String> weeklyStudyTime = {
    '월': '',
    '화': '',
    '수': '',
    '목': '',
    '금': '',
    '토': '',
    '일': '',
  };

  // ── 알림 팝오버 상태(홈과 동일 UX) ────────────────────────────────
  final LayerLink _bellLink = LayerLink();
  OverlayEntry? _notifOverlay;
  bool _isPopoverOpen = false;

  void _removeNotifPopover() {
    _notifOverlay?.remove();
    _notifOverlay = null;
  }

  void _toggleNotifPopover() {
    if (_isPopoverOpen) {
      _removeNotifPopover();
      setState(() => _isPopoverOpen = false);
      return;
    }
    _notifOverlay = _buildNotifPopover();
    Overlay.of(context).insert(_notifOverlay!);
    setState(() => _isPopoverOpen = true);

    // 열 때 최신화
    NotificationService.instance.fetchNotifications();
  }

  OverlayEntry _buildNotifPopover() {
    return OverlayEntry(
      builder:
          (_) => Stack(
            children: [
              // 바깥 클릭 시 닫기
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _removeNotifPopover();
                    setState(() => _isPopoverOpen = false);
                  },
                ),
              ),
              // 아이콘 기준 팝오버
              CompositedTransformFollower(
                link: _bellLink,
                showWhenUnlinked: false,
                offset: const Offset(-340, 44), // 위치 미세조정 가능
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 360,
                    maxHeight: 560,
                  ),
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: _MyPageNotificationsPopoverBody(
                      hostContext: context, // ✅ 페이지 컨텍스트 전달
                      onClose: (bool refresh) async {
                        _removeNotifPopover();
                        setState(() => _isPopoverOpen = false);
                        if (refresh) {
                          await NotificationService.instance.fetchUnreadCount();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }
  // ─────────────────────────────────────────────────────────

  void refreshActualStudyTimeFromOutside() async {
    await fetchUserProfile();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await fetchUserProfile(); // 계획된 공부시간
      await Provider.of<TimerProvider>(
        context,
        listen: false,
      ).loadWeeklyStudyFromServer(); // 실제 공부시간
    });

    // 알림 배지 초기 동기화
    NotificationService.instance.fetchUnreadCount();
  }

  /// 로그아웃
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text('마이 페이지', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          // 🔔 팝오버 + 배지
          Stack(
            clipBehavior: Clip.none,
            children: [
              CompositedTransformTarget(
                link: _bellLink,
                child: ValueListenableBuilder<int>(
                  valueListenable: NotificationService.instance.unreadCount,
                  builder: (_, count, __) {
                    final hasUnread = count > 0;
                    return IconButton(
                      tooltip: '알림',
                      icon: Icon(
                        hasUnread
                            ? Icons
                                .notifications // 꽉 찬 종
                            : Icons.notifications_none, // 테두리 종
                        color: Colors.black,
                      ),
                      onPressed: _toggleNotifPopover,
                    );
                  },
                ),
              ),
              // 배지
              Positioned(
                right: 6,
                top: 6,
                child: ValueListenableBuilder<int>(
                  valueListenable: NotificationService.instance.unreadCount,
                  builder: (_, count, __) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildStudyTimeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '회원정보',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordCheckPage(),
                    ),
                  );
                  if (result == true) {
                    await fetchUserProfile();
                  }
                },
                child: const Text(
                  '회원정보 수정 ＞',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('이름', name),
          _buildInfoRow('아이디', loginId),
          _buildInfoRow('비밀번호', password),
          _buildInfoRow('이메일', email),
          _buildInfoRow('연락처', phone),

          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('로그아웃'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTimeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 주차 이동
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () async {
                  setState(() {
                    selectedWeek = selectedWeek.subtract(
                      const Duration(days: 7),
                    );
                  });
                  final offset = _calculateWeekOffsetFromToday(selectedWeek);
                  await Provider.of<TimerProvider>(
                    context,
                    listen: false,
                  ).loadWeeklyStudyFromServer(weekOffset: offset);
                },
                child: const Text('＜ 이전주'),
              ),
              Builder(
                builder: (_) {
                  final monday = selectedWeek.subtract(
                    Duration(days: selectedWeek.weekday - 1),
                  );
                  return Text(
                    '${monday.year}년 ${monday.month}월 ${monday.day}일 기준',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    selectedWeek = selectedWeek.add(const Duration(days: 7));
                  });
                  final offset = _calculateWeekOffsetFromToday(selectedWeek);
                  await Provider.of<TimerProvider>(
                    context,
                    listen: false,
                  ).loadWeeklyStudyFromServer(weekOffset: offset);
                },
                child: const Text('다음주 ＞'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            '이번주 공부시간',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 목표 공부시간
          Table(
            border: TableBorder.symmetric(
              inside: BorderSide(color: Colors.grey.shade300),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children:
                    days
                        .map(
                          (day) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              TableRow(
                children:
                    days.map((day) {
                      final raw = weeklyStudyTime[day];
                      final minutes = int.tryParse(
                        raw?.replaceAll('분', '') ?? '',
                      );
                      final text =
                          (minutes == null || minutes == 0)
                              ? '-'
                              : formatMinutes(minutes);
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(text, textAlign: TextAlign.center),
                      );
                    }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            '실제 공부시간',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // 실제 공부시간
          Consumer<TimerProvider>(
            builder: (_, timerProvider, __) {
              final studyMap = timerProvider.weeklyStudy;
              return Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: Colors.grey.shade300),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children:
                        days
                            .map(
                              (day) => Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  TableRow(
                    children:
                        days.map((day) {
                          final duration = studyMap[day] ?? Duration.zero;
                          final minutes = duration.inMinutes;
                          final text =
                              (minutes == 0)
                                  ? '-'
                                  : '${minutes ~/ 60}h ${minutes % 60}m';
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(text, textAlign: TextAlign.center),
                          );
                        }).toList(),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudyTypePage()),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('학습 유형 분석하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  int _calculateWeekOffsetFromToday(DateTime selected) {
    final today = DateTime.now();
    final startOfTodayWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfSelectedWeek = selected.subtract(
      Duration(days: selected.weekday - 1),
    );
    return startOfSelectedWeek.difference(startOfTodayWeek).inDays ~/ 7;
  }

  Future<void> fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:8000/user/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        setState(() {
          name = data['profile']?['name'] ?? '';
          email = data['profile']?['email'] ?? '';
          loginId = data['login_id'] ?? '';
          phone = data['phone'] ?? '';
          weeklyStudyTime = {
            '월': '${data['study_time_mon'] ?? 0}분',
            '화': '${data['study_time_tue'] ?? 0}분',
            '수': '${data['study_time_wed'] ?? 0}분',
            '목': '${data['study_time_thu'] ?? 0}분',
            '금': '${data['study_time_fri'] ?? 0}분',
            '토': '${data['study_time_sat'] ?? 0}분',
            '일': '${data['study_time_sun'] ?? 0}분',
          };
        });
      } else {
        // ignore: avoid_print
        print('프로필 불러오기 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('예외 발생: $e');
    }
  }
}

typedef MyPageState = _MyPageState;

/// ─────────────────────────────────────────────────────────────
/// 팝오버 본문 (마이페이지) — 전체보기 시 호스트 컨텍스트 사용
/// ─────────────────────────────────────────────────────────────
class _MyPageNotificationsPopoverBody extends StatelessWidget {
  final void Function(bool refresh) onClose;
  final BuildContext hostContext; // 페이지 컨텍스트

  const _MyPageNotificationsPopoverBody({
    super.key,
    required this.onClose,
    required this.hostContext,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppNotification>>(
      future: NotificationService.instance.fetchNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 360,
            height: 520,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            width: 360,
            height: 520,
            child: Center(child: Text('불러오기 실패: ${snapshot.error}')),
          );
        }

        final list = (snapshot.data ?? <AppNotification>[]);
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순

        return SizedBox(
          width: 360,
          height: 520,
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Text(
                      '알림',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        await NotificationService.instance.markAllAsRead();
                        onClose(true);
                      },
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('모두 읽음'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 목록
              Expanded(
                child:
                    list.isEmpty
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('알림이 없어요.'),
                          ),
                        )
                        : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final n = list[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              leading: Icon(
                                n.isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications,
                                color:
                                    n.isRead
                                        ? Colors.grey
                                        : const Color(0xFF004377),
                              ),
                              title: Text(
                                n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight:
                                      n.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                n.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing:
                                  n.isRead
                                      ? null
                                      : const Icon(
                                        Icons.brightness_1,
                                        size: 8,
                                        color: Colors.redAccent,
                                      ),
                              onTap: () async {
                                if (!n.isRead) {
                                  await NotificationService.instance.markAsRead(
                                    n.id,
                                  );
                                }
                                onClose(true); // 닫으면서 배지 갱신
                              },
                            );
                          },
                        ),
              ),

              // 하단 "전체 보기" — 팝오버 닫힌 다음 프레임에 페이지 컨텍스트로 이동
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                    left: 8,
                    top: 6,
                    bottom: 8,
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      onClose(false); // 먼저 팝오버 닫기
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        await openNotifications(hostContext);
                        await NotificationService.instance.fetchUnreadCount();
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('전체 보기'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
