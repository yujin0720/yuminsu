
import 'package:flutter/material.dart';
import 'password_check_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'timer_provider.dart';
import 'package:intl/intl.dart';


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

  void refreshActualStudyTimeFromOutside() async {
    print("마이페이지 새로고침 호출됨");
    await fetchUserProfile();         // 서버에서 계획 시간 다시 불러오기
    setState(() {});                  // UI 다시 그림
  }

  DateTime selectedWeek = DateTime.now();

  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];

  DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

DateTime _dateOfDayInSelectedWeek(String day) {
  final idx = days.indexOf(day); // 0~6
  return _mondayOf(selectedWeek).add(Duration(days: idx));
}

String _fmtMinutes(int minutes) {
  if (minutes <= 0) return '-';
  final h = minutes ~/ 60, m = minutes % 60;
  if (h > 0 && m > 0) return '${h}h ${m}m';
  if (h > 0) return '${h}h';
  return '${m}m';
}

DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);
bool _isFutureDate(DateTime d) => _strip(d).isAfter(_strip(DateTime.now()));


  Map<String, String> weeklyStudyTime = {
    '월': '',
    '화': '',
    '수': '',
    '목': '',
    '금': '',
    '토': '',
    '일': '',
  };


  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await fetchUserProfile();      // 계획된 공부시간
      await Provider.of<TimerProvider>(context, listen: false).loadWeeklyStudyFromServer(); // 실제 공부시간
    });
  }


  /// ✅ 로그아웃 함수
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

@override
Widget build(BuildContext context) {
  return Container(
    color: const Color(0xFFF2F4F8), // 기존 배경 유지
    child: SingleChildScrollView(
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
        // ── 회원정보 헤더
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.start, // 헤더 텍스트와 위쪽 정렬
  children: [
    const Text('회원정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Column(
      crossAxisAlignment: CrossAxisAlignment.end, // 오른쪽 정렬
      children: [
        // 회원정보 수정 (위)
        TextButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PasswordCheckPage()),
            );
            if (result == true) await fetchUserProfile();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            foregroundColor: Colors.blue,
          ),
          child: const Text('회원정보 수정 ＞', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 2),
        // 로그아웃 (아래)
        TextButton(
          onPressed: _logout,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            foregroundColor: Colors.redAccent,
          ),
          child: const Text('로그아웃 ＞', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  ],
),
             

        const SizedBox(height: 8),

        

        // ── 기본 정보
        _buildInfoRow('이름', name),
        _buildInfoRow('아이디', loginId),
        _buildInfoRow('비밀번호', password),
        _buildInfoRow('이메일', email),
        _buildInfoRow('연락처', phone),

      

        // ── 구분선
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        const Text('이번주 공부시간', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        // ── 이번주(설정된) 공부시간 표
        Table(
          border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade300)),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: days.map((day) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(day, textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
            TableRow(
              children: days.map((day) {
                final raw = weeklyStudyTime[day];
                final minutes = int.tryParse(raw?.replaceAll('분', '') ?? '');
                final text = (minutes == null || minutes == 0)
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
      ],
    ),
  );
}


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(value.isNotEmpty ? value : '-',
                style: const TextStyle(fontWeight: FontWeight.w500)),
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
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('실제 공부시간', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),

        // ── 주차 이동 (표 위)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () async {
                setState(() => selectedWeek = selectedWeek.subtract(const Duration(days: 7)));
                final offset = _calculateWeekOffsetFromToday(selectedWeek);
                await Provider.of<TimerProvider>(context, listen: false)
                    .loadWeeklyStudyFromServer(weekOffset: offset);
              },
              child: const Text('＜ 이전주'),
            ),
            Builder(builder: (_) {
              final monday = _mondayOf(selectedWeek);
              final mondayText = '${monday.year}년 ${monday.month}월 ${monday.day}일 기준';
              return Text(mondayText, style: const TextStyle(fontWeight: FontWeight.bold));
            }),
            TextButton(
              onPressed: () async {
                setState(() => selectedWeek = selectedWeek.add(const Duration(days: 7)));
                final offset = _calculateWeekOffsetFromToday(selectedWeek);
                await Provider.of<TimerProvider>(context, listen: false)
                    .loadWeeklyStudyFromServer(weekOffset: offset);
              },
              child: const Text('다음주 ＞'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── 예쁜 그리드
        Consumer<TimerProvider>(
          builder: (context, timerProvider, child) {
            // null → 0으로 안전 처리 (계산용), 표시만 '-'로
            final totalMinutes = days.fold<int>(0, (sum, d) {
              final cellDate = _dateOfDayInSelectedWeek(d);
              if (_isFutureDate(cellDate)) return sum; // 미래 날짜는 합계 제외
              final minutes = (timerProvider.weeklyStudy[d] ?? Duration.zero).inMinutes;
              return sum + minutes;
            });


            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 요일 헤더
                Row(
                  children: days.map((d) => Expanded(
                    child: Center(
                      child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                // 값 칩들
                Row(
                  children: days.map((d) {
                    final cellDate = _dateOfDayInSelectedWeek(d);
                    final isToday = _strip(cellDate) == _strip(DateTime.now());
                    final isFuture = _isFutureDate(cellDate);

                    final minutes = (timerProvider.weeklyStudy[d] ?? Duration.zero).inMinutes;
                    // 미래 날짜면 항상 '-' 표시
                    final text = isFuture ? '-' : _fmtMinutes(minutes);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.blue.withOpacity(0.08) : const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday ? Colors.blue.shade200 : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),
                // 주간 합계
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5FF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text('합계: ${_fmtMinutes(totalMinutes)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            );
          },
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
  final startOfSelectedWeek = selected.subtract(Duration(days: selected.weekday - 1));

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
        print('프로필 불러오기 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('예외 발생: $e');
    }
  }
}
typedef MyPageState = _MyPageState;