import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'mypage.dart';
import 'main.dart';
import 'package:provider/provider.dart';
import 'package:capstone_edu_app/study_session.dart';

class TimerProvider extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  List<Map<String, dynamic>> _studySessions = [];
  List<StudySession> _sessionList = [];
  List<StudySession> get sessionList => _sessionList;

  DateTime? _sessionStartTime;
  DateTime? _sessionEndTime;
  Duration _elapsed = Duration.zero;
  Duration _lastElapsed = Duration.zero;
  bool _hasPaused = false;

  Map<String, Duration> weeklyStudy = {
    '월': Duration.zero,
    '화': Duration.zero,
    '수': Duration.zero,
    '목': Duration.zero,
    '금': Duration.zero,
    '토': Duration.zero,
    '일': Duration.zero,
  };

  TimerProvider() {
    restoreTimerState();
  }

  bool get isRunning => _stopwatch.isRunning;
  Duration get elapsed => _elapsed;

  String get formattedTime {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void start() async {
    if (_stopwatch.isRunning) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toLocal();

    // ✅ 첫 시작일 때만 _lastElapsed 초기화
    if (!_hasPaused) {
      _lastElapsed = Duration.zero;
      _sessionStartTime = now;
      prefs.setString('sessionStart', now.toIso8601String());
      prefs.setInt('elapsedBefore', _lastElapsed.inMinutes);
      prefs.setString('sessionDate', now.toIso8601String().split('T')[0]);
    }

    _hasPaused = false;

    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed = _stopwatch.elapsed + _lastElapsed;
      notifyListeners();
    });

    notifyListeners();
  }

  void pause() {
    if (!_stopwatch.isRunning) return;

    _stopwatch.stop();
    _timer?.cancel();

    _lastElapsed += _stopwatch.elapsed;
    _elapsed = _lastElapsed;
    _stopwatch.reset();

    _hasPaused = true;
    notifyListeners();
  }

  void stopAndSave() async {
    final now = DateTime.now().toLocal();
    _sessionEndTime = now;

    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
      _lastElapsed += _stopwatch.elapsed;
    }

    final totalDuration =
        _hasPaused ? _elapsed : _stopwatch.elapsed + _lastElapsed;
    final sessionMinutes = (totalDuration.inSeconds / 60).round();

    if (totalDuration.inSeconds < 5) {
      reset();
      return;
    }

    final today = ['월', '화', '수', '목', '금', '토', '일'][now.weekday - 1];
    weeklyStudy[today] = (weeklyStudy[today] ?? Duration.zero) + totalDuration;

    _studySessions.add({
      'study_date': now.toIso8601String().split('T')[0],
      'total_minutes': sessionMinutes,
      'start_time': _sessionStartTime?.toIso8601String(),
      'end_time': _sessionEndTime?.toIso8601String(),
    });

    await saveStudySessionsToServer();
    await fetchSessionsByDate(now);

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('elapsedBefore', _lastElapsed.inMinutes);

    reset();
    notifyListeners();
  }

  void reset() {
    _stopwatch.reset();
    _elapsed = Duration.zero;
    _lastElapsed = Duration.zero;
    _hasPaused = false;
    notifyListeners();
  }

  Future<void> restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionDate = prefs.getString('sessionDate');
    final elapsedBefore = prefs.getInt('elapsedBefore') ?? 0;
    final todayStr = DateTime.now().toLocal().toIso8601String().split('T')[0];

    if (sessionDate != null && sessionDate != todayStr) {
      _studySessions.add({
        'study_date': sessionDate,
        'total_minutes': elapsedBefore,
        'start_time': DateTime.parse(sessionDate).toIso8601String(),
        'end_time': DateTime.parse(sessionDate).toIso8601String(),
      });

      await saveStudySessionsToServer();
      reset();
      prefs.remove('sessionStart');
      prefs.remove('sessionDate');
      prefs.remove('elapsedBefore');
    }
  }

  Future<void> saveStudySessionsToServer() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) return;

    for (var session in _studySessions) {
      await http.post(
        Uri.parse('http://localhost:8000/timer/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(session),
      );
    }
    _studySessions.clear();
  }

  Future<void> fetchSessionsByDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) return;

    final dateStr = date.toIso8601String().split('T')[0];

    final response = await http.get(
      Uri.parse('http://localhost:8000/timer/sessions/$dateStr'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      _sessionList = data.map((e) => StudySession.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> loadWeeklyStudyFromServer({int weekOffset = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) return;

    final url = Uri.parse(
      'http://localhost:8000/timer/weekly-by-day?week_offset=$weekOffset',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);

      final dayMap = {
        'mon': '월',
        'tue': '화',
        'wed': '수',
        'thu': '목',
        'fri': '금',
        'sat': '토',
        'sun': '일',
        '월': '월',
        '화': '화',
        '수': '수',
        '목': '목',
        '금': '금',
        '토': '토',
        '일': '일',
      };

      weeklyStudy.clear();
      for (final entry in data.entries) {
        final day = dayMap[entry.key.toLowerCase()];
        if (day != null) {
          weeklyStudy[day] = Duration(minutes: entry.value);
        }
      }
      notifyListeners();
    }
  }

  void removeSessionAt(int index) {
    final removed = _sessionList.removeAt(index);
    notifyListeners();
    deleteSessionFromServer(removed.id);
  }

  Future<void> deleteSessionFromServer(int timerId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) return;

    final response = await http.delete(
      Uri.parse('http://localhost:8000/timer/$timerId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      print('✅ 서버 세션 삭제 완료 (id=$timerId)');
    } else {
      print('❌ 서버 세션 삭제 실패: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
