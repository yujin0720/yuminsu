import 'package:flutter/material.dart';
import 'password_check_page.dart';
import 'package:provider/provider.dart';
import 'timer_provider.dart';



class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // 나중에 백엔드에서 받아올 회원 정보 변수
  String name = '';           // 예: '유민수'
  String loginId = '';        // 예: 'yuminsu'
  String email = '';          // 예: 'yuminsu@gmail.com'
  String phone = '';          // 예: '010-1234-5678'
  String password = '********';  // 실제 비밀번호는 안 보여주고 '*******' 표시

  // 나중에 백엔드에서 받아올 주간 공부시간 변수
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];

  Map<String, String> weeklyStudyTime = {
    '월': '', // 예: '7h 38m'
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
    // 📡 여기에 나중에 fetchUserProfile() 및 fetchWeeklyStudyTime() 추가
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('마이 페이지', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildStudyTimeTable(),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 제목 + 수정 버튼을 한 줄에 정렬
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('회원정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PasswordCheckPage()),
                  );
                },
                child: const Text('회원정보 수정 ＞', style: TextStyle(fontSize: 16, color: Colors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('이름', name),
          _buildInfoRow('아이디', loginId),
          _buildInfoRow('비밀번호', password.isNotEmpty ? '*******' : ''),
          _buildInfoRow('이메일', email),
          _buildInfoRow('연락처', phone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(value.isNotEmpty ? value : '-', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStudyTimeTable() {
    final timerProvider = Provider.of<TimerProvider>(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('이번주 공부시간', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Table(
            border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
            children: [
              TableRow(
                children: days
                    .map((day) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
              TableRow(
                children: days.map((day) {
                  final duration = timerProvider.weeklyStudy[day] ?? Duration.zero;
                  final text = duration == Duration.zero
                      ? '-'
                      : '${duration.inHours}h ${duration.inMinutes % 60}m';
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: Text(text),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
