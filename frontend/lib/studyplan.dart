import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
// [MOD] 서버 알림 생성 호출 위해 추가
import 'notification_service.dart'; // [MOD]

class StudyPlanPage extends StatefulWidget {
  const StudyPlanPage({super.key});

  @override
  State<StudyPlanPage> createState() => _StudyPlanPageState();
}

class _StudyPlanPageState extends State<StudyPlanPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> subjects = [];
  bool isNewSubject = true;

  final TextEditingController fieldController = TextEditingController();
  final TextEditingController testNameController = TextEditingController();
  final TextEditingController materialNameController = TextEditingController();
  final TextEditingController customTypeController = TextEditingController();

  final List<Map<String, dynamic>> timeOptions = [
    {'label': '5분', 'value': 5},
    {'label': '10분', 'value': 10},
    {'label': '15분', 'value': 15},
    {'label': '30분', 'value': 30},
    {'label': '45분', 'value': 45},
    {'label': '1시간', 'value': 60},
    {'label': '1시간 10분', 'value': 70},
    {'label': '1시간 20분', 'value': 80},
    {'label': '1시간 30분', 'value': 90},
    {'label': '1시간 40분', 'value': 100},
    {'label': '1시간 50분', 'value': 110},
    {'label': '2시간', 'value': 120},
  ];
  int selectedTime = 60;

  DateTime? testDate;
  DateTime _focusedTestDay = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;
  DateTime _focusedStudyDay = DateTime.now();

  String selectedType = '책';
  int repeatCount = 1;
  List<Map<String, dynamic>> studyMaterials = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://localhost:8000/subject/list'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      if (!mounted) return;

      setState(() {
        subjects = data.cast<Map<String, dynamic>>();
        _tabController.dispose();
        _tabController = TabController(
          length: subjects.length + 1,
          vsync: this,
        );
      });
    }
  }

  Future<void> _loadRowPlans(int subjectId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://localhost:8000/row-plan/by-subject/$subjectId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      print("불러온 자료 개수: ${data.length}");

      setState(() {
        studyMaterials =
            data
                .map(
                  (e) => {
                    'row_plan_name': e['row_plan_name'],
                    'type': e['type'],
                    'repetition': e['repetition'],
                    'plan_time': e['plan_time'],
                  },
                )
                .toList();
      });
    }
  }

  Future<int?> saveDataToDB() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return null;

    int? subjectId;

    if (isNewSubject) {
      final subjectResponse = await http.post(
        Uri.parse('http://localhost:8000/subject/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'field': fieldController.text,
          'test_name': testNameController.text,
          'test_date': testDate?.toIso8601String(),
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        }),
      );

      if (subjectResponse.statusCode != 200) {
        print('❌ subject 생성 실패: ${subjectResponse.body}');
        return null;
      }

      subjectId = jsonDecode(subjectResponse.body)['subject_id'];
      print('✅ 새 과목 등록 완료 → subject_id: $subjectId');
    } else {
      final existing = subjects.firstWhere(
        (s) => s['test_name'] == testNameController.text,
        orElse: () => {},
      );

      if (existing.isEmpty || existing['subject_id'] == null) {
        print('❗ 기존 과목 정보 없음 → 삭제 생략');
        return null;
      }

      subjectId = existing['subject_id'];
      print('🟡 기존 과목 ID: $subjectId');

      // Plan 삭제
      await http.delete(
        Uri.parse('http://localhost:8000/plan/by-subject/$subjectId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // RowPlan 삭제
      await http.delete(
        Uri.parse('http://localhost:8000/row-plan/by-subject/$subjectId'),
        headers: {'Authorization': 'Bearer $token'},
      );
    }

    // row_plan 등록
    for (int i = 0; i < studyMaterials.length; i++) {
      final material = studyMaterials[i];
      await http.post(
        Uri.parse('http://localhost:8000/row-plan/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subject_id': subjectId,
          'row_plan_name': material['row_plan_name'],
          'type': material['type'],
          'repetition': material['repetition'],
          'ranking': i + 1,
          'plan_time': material['plan_time'],
        }),
      );
    }

    return subjectId;
  }

  // [MOD] 오늘 날짜 yyyy-MM-dd
  String _today() => DateTime.now().toIso8601String().split('T').first;

  // [MOD] 계획명에 맞춰 자연스러운 동사 선택(유지하되 본문은 고정 문구로 출력 예정)
  String _pickVerb({String? planName, String? type}) {
    final n = (planName ?? '').toLowerCase();
    final t = (type ?? '').toLowerCase();

    bool hasAny(List<String> keys) =>
        keys.any((k) => n.contains(k) || t.contains(k));

    if (hasAny(['인강', '강의', 'lecture', '강의자료', 'video'])) return '시청';
    if (hasAny(['문제', '모의고사', '기출', '문풀', '퀴즈', 'problem'])) return '풀이';
    if (hasAny(['정리', '요약', '노트', 'note', 'review'])) return '정리';
    if (hasAny(['책', '교재', 'pdf', '자료', 'reading'])) return '읽기';
    return '학습';
  }

  // [MOD] 오늘자 해당 과목의 할당 계획을 불러와 "제목/본문" 구성
  Future<Map<String, String>?> _composeTodaySubjectNotification(
    int subjectId,
    String subjectName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return null;

    final uri = Uri.parse(
      'http://localhost:8000/plan/by-date-with-subject?date=${_today()}',
    );

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return null;

    final List data = json.decode(utf8.decode(res.bodyBytes));

    // subject_id 있으면 그걸로 필터, 없으면 subject/subject_name 텍스트로 필터
    final filtered =
        data.where((e) {
          final m = e as Map<String, dynamic>;
          final sid = m['subject_id'] ?? m['subjectId'];
          if (sid != null) return sid == subjectId;
          final sname = (m['subject'] ?? m['subject_name'] ?? '').toString();
          return sname == subjectName;
        }).toList();

    if (filtered.isEmpty) return null;

    // 표시할 제목(과목 포함)
    final title = '오늘 학습 계획 · $subjectName';

    // 계획명 리스트
    final names =
        filtered
            .map((m) => (m['plan_name'] ?? m['title'] ?? '무제').toString())
            .toList();

    // (동사 선택은 유지하지만 본문은 고정 표현으로 출력)
    final first = filtered.first as Map<String, dynamic>;
    final _ = _pickVerb(
      planName: (first['plan_name'] ?? first['title'] ?? '').toString(),
      type: (first['type'] ?? '').toString(),
    );

    String chunk;
    if (names.length == 1) {
      chunk = names.first;
    } else if (names.length == 2) {
      chunk = '${names[0]} · ${names[1]}';
    } else {
      chunk = '${names[0]} · ${names[1]} 외 ${names.length - 2}건';
    }

    // 🔴 여기만 변경: 문구를 "강의자료 학습하는 날이에요!"로 고정
    final body = '오늘은 $chunk 학습하는 날이에요!';

    return {'title': title, 'body': body};
  }

  Future<void> saveAndRunAIAndMove() async {
    final subjectId = await saveDataToDB();
    if (subjectId == null || !context.mounted) {
      print("❌ subjectId 없음 → AI 실행 취소");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            title: Text('AI 실행 중'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AI가 계획을 생성하는 중입니다...'),
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ],
            ),
          ),
    );

    final response = await http.post(
      Uri.parse('http://localhost:8000/plan/schedule?subject_id=$subjectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    Navigator.of(context).pop();

    if (response.statusCode == 200 && context.mounted) {
      // [MOD] 오늘자 해당 과목 계획으로 자연스러운 알림 생성
      try {
        final subjectName = testNameController.text.trim();
        final info = await _composeTodaySubjectNotification(
          subjectId,
          subjectName,
        );
        if (info != null) {
          await NotificationService.instance.createNotification(
            title: info['title']!, // "오늘 학습 계획 · 과목명"
            body: info['body']!, // "오늘은 XXX 강의자료 학습하는 날이에요!"
          );
          await NotificationService.instance.fetchUnreadCount();
        } else {
          debugPrint('오늘 해당 과목 할당 없음 → 알림 생략');
        }
      } catch (e) {
        debugPrint('계획 생성 알림 처리 오류: $e');
      }

      Navigator.pushReplacementNamed(context, '/home');
    } else if (context.mounted) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('실패'),
              content: Text('AI 계획 생성 실패: ${response.body}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> deleteAllStudyData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('http://localhost:8000/subject/delete-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        studyMaterials.clear();
      });
    }
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: subjects.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('학습 계획 입력'),
          bottom:
              subjects.isNotEmpty
                  ? TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.black,
                    indicatorColor: Colors.transparent,
                    onTap: (index) async {
                      print("🔥 Tab 클릭됨: index = $index");

                      if (index == subjects.length) {
                        setState(() {
                          isNewSubject = true;
                          fieldController.clear();
                          testNameController.clear();
                          testDate = null;
                          startDate = null;
                          endDate = null;
                          studyMaterials.clear();
                        });
                      } else {
                        final subject = subjects[index];
                        fieldController.text = subject['field'] ?? '';
                        testNameController.text = subject['test_name'] ?? '';
                        testDate = DateTime.tryParse(
                          subject['test_date'] ?? '',
                        );
                        startDate = DateTime.tryParse(
                          subject['start_date'] ?? '',
                        );
                        endDate = DateTime.tryParse(subject['end_date'] ?? '');

                        setState(() {
                          isNewSubject = false;
                          _focusedTestDay = testDate ?? DateTime.now();
                          _focusedStudyDay = startDate ?? DateTime.now();
                        });

                        await _loadRowPlans(subject['subject_id']);
                      }
                    },
                    tabs: [
                      ...subjects.map((subj) => Tab(text: subj['test_name'])),
                      const Tab(icon: Icon(Icons.add)),
                    ],
                  )
                  : null,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '시험 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: fieldController,
                        decoration: const InputDecoration(labelText: '시험 분야'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: testNameController,
                        decoration: const InputDecoration(labelText: '시험 이름'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '시험 날짜 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TableCalendar(
                        firstDay: DateTime.utc(2023, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedTestDay,
                        selectedDayPredicate: (day) => isSameDay(testDate, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            testDate = selectedDay;
                            _focusedTestDay = focusedDay;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        rowHeight: 38,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '공부 기간 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TableCalendar(
                        firstDay: DateTime.utc(2023, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedStudyDay,
                        rangeStartDay: startDate,
                        rangeEndDay: endDate,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _focusedStudyDay = focusedDay;
                            if (startDate != null &&
                                endDate == null &&
                                selectedDay.isAfter(startDate!)) {
                              endDate = selectedDay;
                            } else {
                              startDate = selectedDay;
                              endDate = null;
                            }
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedStudyDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          rangeHighlightColor: Colors.blue.shade200,
                          withinRangeTextStyle: const TextStyle(
                            color: Colors.white,
                          ),
                          rangeStartDecoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        rowHeight: 38,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '학습 자료 추가',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📚 자료명 텍스트필드
                          TextField(
                            controller: materialNameController,
                            decoration: const InputDecoration(
                              labelText: '자료명과 범위',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 드롭다운들 한 줄
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 자료 유형
                                _buildDropdownContainer(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedType,
                                      items:
                                          ['책', '인강', '직접입력']
                                              .map(
                                                (type) => DropdownMenuItem(
                                                  value: type,
                                                  child: Text(type),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (value) => setState(
                                            () => selectedType = value!,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 직접입력
                                if (selectedType == '직접입력')
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      controller: customTypeController,
                                      decoration: const InputDecoration(
                                        labelText: '유형 입력',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),

                                if (selectedType != '직접입력')
                                  const SizedBox(width: 12),

                                // 반복 횟수
                                _buildDropdownContainer(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: repeatCount,
                                      items: List.generate(
                                        10,
                                        (i) => DropdownMenuItem(
                                          value: i + 1,
                                          child: Text('${i + 1}회'),
                                        ),
                                      ),
                                      onChanged:
                                          (val) => setState(
                                            () => repeatCount = val!,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 예상 시간
                                _buildDropdownContainer(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: selectedTime,
                                      items:
                                          timeOptions.map((opt) {
                                            return DropdownMenuItem<int>(
                                              value: opt['value'] as int,
                                              child: Text(opt['label']),
                                            );
                                          }).toList(),
                                      onChanged:
                                          (val) => setState(
                                            () => selectedTime = val!,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 🔘 자료추가 버튼
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                final type =
                                    selectedType == '직접입력'
                                        ? customTypeController.text
                                        : selectedType;
                                setState(() {
                                  studyMaterials.add({
                                    'row_plan_name':
                                        materialNameController.text,
                                    'type': type,
                                    'repetition': repeatCount,
                                    'plan_time': selectedTime,
                                  });
                                  materialNameController.clear();
                                  customTypeController.clear();
                                  selectedType = '책';
                                  repeatCount = 1;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 13,
                                ),
                                backgroundColor: const Color(0xFF004377),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                '자료추가',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (studyMaterials.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '추가된 자료 목록',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 300,
                          child: ReorderableListView(
                            buildDefaultDragHandles: true,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item = studyMaterials.removeAt(oldIndex);
                                studyMaterials.insert(newIndex, item);
                              });
                            },
                            children:
                                studyMaterials.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Card(
                                    key: ValueKey(
                                      '$index-${item['row_plan_name']}',
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        '${index + 1}. ${item['row_plan_name']}',
                                      ),
                                      subtitle: Text(
                                        '유형: ${item['type']}, 반복: ${item['repetition']}회, 시간: ${item['plan_time']}분',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              final TextEditingController
                                              nameCtrl = TextEditingController(
                                                text: item['row_plan_name'],
                                              );
                                              final TextEditingController
                                              customTypeCtrl =
                                                  TextEditingController(
                                                    text:
                                                        (!['책', '인강'].contains(
                                                              item['type'],
                                                            ))
                                                            ? item['type']
                                                            : '',
                                                  );
                                              String tempType =
                                                  [
                                                        '책',
                                                        '인강',
                                                      ].contains(item['type'])
                                                      ? item['type']
                                                      : '직접입력';
                                              int tempRepeat =
                                                  item['repetition'];
                                              int tempTime = item['plan_time'];

                                              showDialog(
                                                context: context,
                                                builder: (_) {
                                                  return AlertDialog(
                                                    title: const Text('자료 수정'),
                                                    content: StatefulBuilder(
                                                      builder: (
                                                        context,
                                                        setModalState,
                                                      ) {
                                                        return Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            TextField(
                                                              controller:
                                                                  nameCtrl,
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        '자료명',
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Row(
                                                              children: [
                                                                DropdownButton<
                                                                  String
                                                                >(
                                                                  value:
                                                                      tempType,
                                                                  items:
                                                                      [
                                                                            '책',
                                                                            '인강',
                                                                            '직접입력',
                                                                          ]
                                                                          .map(
                                                                            (
                                                                              t,
                                                                            ) => DropdownMenuItem(
                                                                              value:
                                                                                  t,
                                                                              child: Text(
                                                                                t,
                                                                              ),
                                                                            ),
                                                                          )
                                                                          .toList(),
                                                                  onChanged: (
                                                                    val,
                                                                  ) {
                                                                    setModalState(
                                                                      () {
                                                                        tempType =
                                                                            val!;
                                                                      },
                                                                    );
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                if (tempType ==
                                                                    '직접입력')
                                                                  Expanded(
                                                                    child: TextField(
                                                                      controller:
                                                                          customTypeCtrl,
                                                                      decoration: const InputDecoration(
                                                                        labelText:
                                                                            '유형 입력',
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Row(
                                                              children: [
                                                                const Text(
                                                                  '반복:',
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                DropdownButton<
                                                                  int
                                                                >(
                                                                  value:
                                                                      tempRepeat,
                                                                  items: List.generate(
                                                                    10,
                                                                    (
                                                                      i,
                                                                    ) => DropdownMenuItem(
                                                                      value:
                                                                          i + 1,
                                                                      child: Text(
                                                                        '${i + 1}회',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  onChanged:
                                                                      (
                                                                        val,
                                                                      ) => setModalState(
                                                                        () =>
                                                                            tempRepeat =
                                                                                val!,
                                                                      ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 24,
                                                                ),
                                                                const Text(
                                                                  '시간:',
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                DropdownButton<
                                                                  int
                                                                >(
                                                                  value:
                                                                      tempTime,
                                                                  items:
                                                                      timeOptions.map((
                                                                        opt,
                                                                      ) {
                                                                        return DropdownMenuItem<
                                                                          int
                                                                        >(
                                                                          value:
                                                                              opt['value']
                                                                                  as int,
                                                                          child: Text(
                                                                            opt['label'],
                                                                          ),
                                                                        );
                                                                      }).toList(),
                                                                  onChanged:
                                                                      (
                                                                        val,
                                                                      ) => setModalState(
                                                                        () =>
                                                                            tempTime =
                                                                                val!,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text('취소'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            studyMaterials[index] = {
                                                              'row_plan_name':
                                                                  nameCtrl.text,
                                                              'type':
                                                                  tempType ==
                                                                          '직접입력'
                                                                      ? customTypeCtrl
                                                                          .text
                                                                      : tempType,
                                                              'repetition':
                                                                  tempRepeat,
                                                              'plan_time':
                                                                  tempTime,
                                                            };
                                                          });
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                        child: const Text(
                                                          '수정 완료',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              setState(() {
                                                studyMaterials.removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: saveAndRunAIAndMove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 31,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(
                          color: Color(0xFF004377),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      '저장하기',
                      style: TextStyle(fontSize: 16, color: Color(0xFF004377)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: deleteAllStudyData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 31,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(
                          color: Color(0xFFB00020),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: const Text(
                      '삭제하기',
                      style: TextStyle(fontSize: 16, color: Color(0xFFB00020)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
