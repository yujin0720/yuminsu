import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'submain.dart';
import 'studyplan.dart';
import 'login_page.dart';
import 'folder_home_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
// import 'todo_provider_main.dart';
import 'todo_provider.dart';
import 'mypage.dart';
import 'timer.dart';
import 'timer_provider.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ 알림함 화면 import (UI만)
import 'notifications_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: const StudyApp(),
    ),
  );
}

class StudyApp extends StatelessWidget {
  const StudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/folder': (context) => FolderHomePage(),
        '/home': (context) => const PageViewContainer(),
        '/studyplan': (context) => const StudyPlanPage(),
        '/submain': (context) => const SubMainPage(),
        '/mypage': (context) => const MyPage(),
        '/timer': (context) => const TimerPage(),
        '/login': (context) => const LoginPage(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        fontFamily: GoogleFonts.notoSansKr().fontFamily,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primaryColor: const Color(0xFF004377),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF004377),
          secondary: const Color(0xFF004377),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF7BA7C4);
            }
            return const Color(0xFFB0BEC5);
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
          side: const BorderSide(color: Color(0xFFB0BEC5), width: 1.5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF004377),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFF004377)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF004377), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF004377)),
          ),
        ),
      ),
    );
  }
}

class PageViewContainer extends StatefulWidget {
  const PageViewContainer({super.key});

  @override
  State<PageViewContainer> createState() => _PageViewContainerState();
}

class _PageViewContainerState extends State<PageViewContainer> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SubMainPage(),
    TimerPage(),
    FolderHomePage(),
    MyPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF004377),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 24),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: '계획'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '타이머'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: '폴더'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

// 홈 화면 전용 알림 모델
class HomeNotificationItem {
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  HomeNotificationItem({
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  HomeNotificationItem copyWith({
    String? title,
    String? body,
    bool? read,
    DateTime? createdAt,
  }) {
    return HomeNotificationItem(
      title: title ?? this.title,
      body: body ?? this.body,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class HomePageState extends State<HomePage> {
  Map<String, List<Map<String, dynamic>>> subjectGroups = {};
  List<Map<String, dynamic>> todayTodos = [];
  Map<String, List<Map<String, dynamic>>> weeklyTodos = {};
  Map<String, List<bool>> todoChecked = {};
  Map<DateTime, List<String>> _events = {};
  Map<DateTime, List<Map<String, dynamic>>> _eventDataMap = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  int todayMinutes = 0;
  int weeklyMinutes = 0;
  Map<String, int> userStudyTime = {};

  final String baseUrl = 'http://localhost:8000';

  // --------- 알림(UI) 추가: 홈 전용 ---------
  int _unreadCount = 0;
  final List<HomeNotificationItem> _notifications = [];

  void _addNotification(String title, String body) {
    setState(() {
      _notifications.insert(
        0,
        HomeNotificationItem(
          title: title,
          body: body,
          read: false,
          createdAt: DateTime.now(),
        ),
      );
      _unreadCount++;
    });
  }

  Future<void> _openNotifications() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          // dynamic 리스트 받으니까 그대로 넘김
          items: _notifications,
        ),
      ),
    );

    if (result is NotificationsResult) {
      setState(() {
        for (final idx in result.readIndexes) {
          if (idx >= 0 && idx < _notifications.length) {
            _notifications[idx] = _notifications[idx].copyWith(read: true);
          }
        }
        _unreadCount = _notifications.where((e) => !e.read).length;
      });
    } else {
      setState(() {
        _unreadCount = _notifications.where((e) => !e.read).length;
      });
    }
  }
  // ---------------------------------------

  void _showAddPersonalScheduleDialog() {
    final TextEditingController titleController = TextEditingController();
    DateTime selectedDate = _focusedDay;
    Color selectedColor = Colors.blue;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('개인 일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '일정 이름'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('날짜:'),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  )
                ],
              ),
              Row(
                children: [
                  const Text('색상:'),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = Colors.purple;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitPersonalSchedule(
                  titleController.text,
                  selectedDate,
                  selectedColor,
                );
                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitPersonalSchedule(
      String title, DateTime date, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final res = await http.post(
      Uri.parse('$baseUrl/personal-schedule/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      await fetchCalendarEvents();
      await fetchTodayTodos();
      setState(() {});
    }
  }

  Future<void> refreshTodayStudyTime() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) return;

    final response = await http.get(
      Uri.parse('http://localhost:8000/timer/today'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        todayMinutes = data['today_minutes'];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAllData();

    Future.microtask(() {
      Provider.of<TodoProvider>(context, listen: false).fetchTodayTodosGrouped();
      Provider.of<TimerProvider>(context, listen: false).loadWeeklyStudyFromServer();
    });
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null || token.isEmpty) {
      return {
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchAllData() async {
    await fetchTodayTodos();
    await fetchWeeklyTodos();
    await fetchTimers();
    await fetchUserStudyTime();
    await fetchCalendarEvents();
    await refreshTodayStudyTime();
  }

  Future<void> fetchTodayTodos() async {
    final headers = await _headers();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final planRes = await http.get(Uri.parse('$baseUrl/plan/today?date=$today'), headers: headers);
    List<Map<String, dynamic>> plans = [];

    if (planRes.statusCode == 200) {
      final decoded = utf8.decode(planRes.bodyBytes);
      final List data = json.decode(decoded);
      plans = data.map((e) => e as Map<String, dynamic>).toList();
    }

    final personalRes = await http.get(Uri.parse('$baseUrl/personal-schedule/today'), headers: headers);
    List<Map<String, dynamic>> personals = [];

    if (personalRes.statusCode == 200) {
      final decoded = utf8.decode(personalRes.bodyBytes);
      final List data = json.decode(decoded);

      personals = data
          .map((e) => {
                'plan_name': e['title'],
                'plan_id': null,
                'complete': false,
                'plan_time': 0,
                'subject': '📌 개인 일정',
              })
          .toList();
    }

    final personalTodos = [...personals];
    final groupedPlans = <String, List<Map<String, dynamic>>>{};

    for (var plan in plans) {
      final subject = plan['subject'] ?? plan['subject_name'] ?? '기타';
      groupedPlans.putIfAbsent(subject, () => []).add(plan);
    }

    final all = [...personalTodos, ...plans];

    setState(() {
      todayTodos = all;
      subjectGroups = groupedPlans;
    });
  }

  Future<void> fetchWeeklyTodos() async {
    final headers = await _headers();
    final now = DateTime.now();
    final start = now;
    final end = now.add(const Duration(days: 6));
    final res = await http.get(
        Uri.parse(
            '$baseUrl/plan/weekly?start=${DateFormat('yyyy-MM-dd').format(start)}&end=${DateFormat('yyyy-MM-dd').format(end)}'),
        headers: headers);
    if (res.statusCode == 200) {
      final decoded = utf8.decode(res.bodyBytes);
      final List data = json.decode(decoded);
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var item in data) {
        final subject = item['subject'] ?? '기타';
        grouped.putIfAbsent(subject, () => []).add(item);
      }
      setState(() {
        weeklyTodos = grouped;
        todoChecked = {
          for (var entry in grouped.entries)
            entry.key: List<bool>.generate(entry.value.length,
                (i) => entry.value[i]['complete'] ?? false),
        };
      });
    }
  }

  Future<void> markComplete(int planId) async {
    final headers = await _headers();
    await http.patch(Uri.parse('$baseUrl/plan/$planId/complete'), headers: headers);
    await fetchWeeklyTodos();
    await fetchTodayTodos();
  }

  Future<void> toggleComplete(int planId, bool newValue) async {
    final headers = await _headers();

    final res = await http.patch(Uri.parse('$baseUrl/plan/$planId/complete'),
        headers: headers, body: json.encode({"complete": newValue}));

    if (res.statusCode == 200) {
      await Provider.of<TodoProvider>(
        navigatorKey.currentContext!,
        listen: false,
      ).fetchTodayTodosGrouped();

      await fetchTodayTodos();
      await fetchWeeklyTodos();
      await fetchCalendarEvents();
      setState(() {});
    }
  }

  Future<void> fetchTimers() async {
    final headers = await _headers();
    final todayRes = await http.get(Uri.parse('$baseUrl/timer/today'), headers: headers);
    final weeklyRes = await http.get(Uri.parse('$baseUrl/timer/weekly'), headers: headers);

    if (todayRes.statusCode == 200 && weeklyRes.statusCode == 200) {
      final todayDecoded = json.decode(utf8.decode(todayRes.bodyBytes));
      final weeklyDecoded = json.decode(utf8.decode(weeklyRes.bodyBytes));

      setState(() {
        todayMinutes = todayDecoded['today_minutes'] ?? 0;
        weeklyMinutes = weeklyDecoded['weekly_minutes'] ?? 0;
      });
    }
  }

  Future<void> fetchUserStudyTime() async {
    final headers = await _headers();
    final res = await http.get(Uri.parse('$baseUrl/user/study-time'), headers: headers);
    if (res.statusCode == 200) {
      final decoded = utf8.decode(res.bodyBytes);
      setState(() {
        userStudyTime = Map<String, int>.from(json.decode(decoded));
      });
    }
  }

  Future<void> fetchCalendarEvents() async {
    final headers = await _headers();
    final formatter = DateFormat('yyyy-MM-dd');

    final year = _focusedDay.year;
    final month = _focusedDay.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    final List<DateTime> allDatesInMonth =
        List.generate(lastDay.day, (i) => DateTime.utc(year, month, i + 1));

    Map<DateTime, List<String>> events = {};
    Map<DateTime, List<Map<String, dynamic>>> eventDataMap = {};

    for (var date in allDatesInMonth) {
      final formattedDate = formatter.format(date);
      final res = await http.get(
        Uri.parse('$baseUrl/plan/by-date-with-subject?date=$formattedDate'),
        headers: headers,
      );

      if (res.statusCode == 200) {
        final decoded = utf8.decode(res.bodyBytes);
        final List<dynamic> data = json.decode(decoded);
        final todos = data.cast<Map<String, dynamic>>();

        if (todos.isNotEmpty) {
          final dateKey = DateTime.utc(date.year, date.month, date.day);

          events[dateKey] = todos
              .map((e) => '${e['subject'] ?? '무제'}: ${e['plan_name'] ?? '무제'}')
              .toList();

          eventDataMap[dateKey] = todos;
        }
      }
    }

    setState(() {
      _events = events;
      _eventDataMap = eventDataMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Manager'),
        actions: [
          // 🔔 홈 상단 종 + 뱃지
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Color(0xFF004377)),
                onPressed: _openNotifications,
                tooltip: '알림',
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
            _buildTodoAndWeeklySection(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "📅 캘린더",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddPersonalScheduleDialog,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text(
                    "개인일정 추가",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTodoCard(
              title: ' ',
              child: _buildCalendar(),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullTodoPopup(BuildContext context, DateTime day,
      List<Map<String, dynamic>> initialTodos) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                List<Map<String, dynamic>> todos =
                    List<Map<String, dynamic>>.from(initialTodos);

                final Map<String, List<Map<String, dynamic>>> groupedTodos = {};
                for (var todo in todos) {
                  final subject = todo['subject'] ?? '기타';
                  groupedTodos.putIfAbsent(subject, () => []).add(todo);
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${day.month}월 ${day.day}일 할 일",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: groupedTodos.entries.map((entry) {
                            return ExpansionTile(
                              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                              children: entry.value.map((todo) {
                                final isComplete = todo['complete'] == true || todo['complete'] == 1;

                                return ListTile(
                                  leading: Checkbox(
                                    value: isComplete,
                                    onChanged: (val) async {
                                      if (val != null) {
                                        await toggleComplete(todo['plan_id'], val);
                                        await fetchTodayTodos();
                                        await fetchWeeklyTodos();
                                        await fetchCalendarEvents();

                                        todo['complete'] = val ? 1 : 0;
                                        setModalState(() {});
                                      }
                                    },
                                  ),
                                  title: Text(
                                    todo['plan_name'] ?? '무제',
                                    style: TextStyle(
                                      color: isComplete ? Colors.grey : Colors.black,
                                      decoration: isComplete ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDonutCard(String title, double percent, String valueText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: 48.0,
            lineWidth: 10.0,
            animation: true,
            percent: percent,
            center: Text(valueText, style: const TextStyle(fontSize: 14)),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: Colors.grey.shade300,
            progressColor: const Color(0xFF004377),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodoCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (title.isNotEmpty) const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStyledTodoTile(Map<String, dynamic> todo) {
    final isComplete = todo['complete'] == true || todo['complete'] == 1;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isComplete ? Colors.grey.shade200 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isComplete,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) async {
              if (val != null) {
                await toggleComplete(todo['plan_id'], val);
                await fetchTodayTodos();
                await fetchWeeklyTodos();
                await fetchCalendarEvents();
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              todo['plan_name'] ?? '무제',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: isComplete ? TextDecoration.lineThrough : null,
                color: isComplete ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoAndWeeklySection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildTodoCard(
                title: "오늘 할 일",
                child: Builder(
                  builder: (context) {
                    if (todayTodos.isEmpty && subjectGroups.isEmpty) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                          child: Text("오늘은 계획된 Todo가 없습니다!", style: TextStyle(fontSize: 14)),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...todayTodos
                            .where((todo) => todo['subject'] == '📌 개인 일정')
                            .map((todo) => _buildStyledTodoTile(todo)),
                        const SizedBox(height: 12),
                        ...subjectGroups.entries.map((entry) {
                          return ExpansionTile(
                            title: Text(entry.key),
                            children: entry.value.map((todo) => _buildStyledTodoTile(todo)).toList(),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildTodoCard(
                title: "주간 할 일",
                child: weeklyTodos.isEmpty
                    ? const SizedBox(
                        height: 100,
                        child: Center(
                          child: Text("이번 주에 계획된 Todo가 없습니다!", style: TextStyle(fontSize: 14)),
                        ),
                      )
                    : Column(
                        children: weeklyTodos.entries
                            .map(
                              (entry) => ExpansionTile(
                                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                children: entry.value.map((todo) => _buildStyledTodoTile(todo)).toList(),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Consumer<TimerProvider>(
            builder: (context, timer, _) {
              final today = ['월', '화', '수', '목', '금', '토', '일'][DateTime.now().weekday - 1];
              final todayStudyMin = timer.weeklyStudy[today]?.inMinutes ?? 0;
              final weeklyStudyMin =
                  timer.weeklyStudy.values.fold<int>(0, (sum, d) => sum + d.inMinutes);

              double calculatePercent(int value, int goal) => (value / goal).clamp(0.0, 1.0);

              String formatMinutes(int minutes) {
                final h = (minutes ~/ 60).toString();
                final m = (minutes % 60).toString().padLeft(2, '0');
                return '${h}H${m}M';
              }

              return _buildTodoCard(
                title: "학습 통계",
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    _buildDonutCard("오늘 공부 달성률", _calculateTodayPercent(),
                        "${(_calculateTodayPercent() * 100).toStringAsFixed(1)}%"),
                    _buildDonutCard("오늘 공부 시간", calculatePercent(todayStudyMin, 240),
                        formatMinutes(todayStudyMin)),
                    _buildDonutCard("주간 목표 달성률", _calculateWeeklyPercent(),
                        "${(_calculateWeeklyPercent() * 100).toStringAsFixed(1)}%"),
                    _buildDonutCard("이번주 공부 시간", calculatePercent(weeklyStudyMin, 1680),
                        formatMinutes(weeklyStudyMin)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _minutesToHourMin(int minutes) {
    final h = (minutes ~/ 60).toString();
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '${h}H${m}M';
  }

  double _calculateTodayPercent() {
    final totalPlannedTime =
        todayTodos.map((todo) => todo['plan_time'] ?? 0).fold<int>(0, (a, b) => a + (b as num).toInt());

    final completedTime = todayTodos
        .where((todo) => todo['complete'] == true || todo['complete'] == 1)
        .map((todo) => todo['plan_time'] ?? 0)
        .fold<int>(0, (a, b) => a + (b as num).toInt());

    if (totalPlannedTime == 0) return 0.0;
    return (completedTime / totalPlannedTime).clamp(0, 1).toDouble();
  }

  double _calculateWeeklyPercent() {
    int totalPlannedTime = 0;
    int completedTime = 0;

    bool isComplete(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

    for (var subject in weeklyTodos.entries) {
      for (var todo in subject.value) {
        final rawTime = todo['plan_time'] ?? 0;
        final int time = rawTime is num ? rawTime.toInt() : int.tryParse(rawTime.toString()) ?? 0;
        final complete = isComplete(todo['complete']);

        totalPlannedTime += time;
        if (complete) completedTime += time;
      }
    }

    if (totalPlannedTime == 0) return 0.0;
    return (completedTime / totalPlannedTime).clamp(0, 1).toDouble();
  }

  List<Map<String, dynamic>> getTodosForDay(DateTime day) {
    return todayTodos.where((todo) {
      final planDate = DateTime.parse(todo['plan_date']);
      return planDate.year == day.year &&
          planDate.month == day.month &&
          planDate.day == day.day;
    }).toList();
  }

  Widget _buildCalendarDay(DateTime day, {bool isToday = false}) {
    final dateKey = DateTime.utc(day.year, day.month, day.day);
    final events = _events[dateKey] ?? [];
    final isSelected = isSameDay(_selectedDay, day);
    final hasEvent = events.isNotEmpty;

    return GestureDetector(
      onTap: () {
        _showFullTodoPopup(context, day, _eventDataMap[dateKey] ?? []);
      },
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : null,
          border: isSelected
              ? Border.all(color: const Color(0xFF004377), width: 2)
              : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF004377)
                    : isToday
                        ? const Color(0xFF004377)
                        : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            if (hasEvent)
              Text(
                events.first.length > 10 ? '${events.first.substring(0, 9)}…' : events.first,
                style: const TextStyle(fontSize: 10, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            if (events.length > 1)
              Text(
                '+${events.length - 1}개 더보기',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          fetchCalendarEvents();
        },
        calendarFormat: CalendarFormat.month,
        rowHeight: 80,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
        ),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          final dateKey = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);

          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          _showFullTodoPopup(context, selectedDay, _eventDataMap[dateKey] ?? []);
        },
        eventLoader: (day) => _events[DateTime.utc(day.year, day.month, day.day)] ?? [],
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(
            color: Color(0xFF004377),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.rectangle,
          ),
          todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          selectedTextStyle: const TextStyle(color: Color(0xFF004377), fontWeight: FontWeight.bold),
          markersAlignment: Alignment.bottomCenter,
          markerDecoration: const BoxDecoration(color: Colors.transparent),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, _) => _buildCalendarDay(day),
          todayBuilder: (context, day, _) => _buildCalendarDay(day, isToday: true),
        ),
      ),
    );
  }
}