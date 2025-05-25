import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'todo_provider.dart';
import 'studyplan.dart';

class SubMainPage extends StatefulWidget {
  const SubMainPage({super.key});

  @override
  State<SubMainPage> createState() => _SubMainPageState();
}

class _SubMainPageState extends State<SubMainPage> {
  final Map<String, bool> isExpanded = {
    'A 과목': true,
    'B 과목': true,
  };

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...todoProvider.weeklyTodos.entries.map((entry) {
              final subject = entry.key;
              final todos = entry.value;
              final checked = todoProvider.todoChecked[subject]!;
              final expanded = isExpanded[subject] ?? true;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        isExpanded[subject] = !expanded;
                      });
                    },
                    icon: Icon(expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right),
                    label: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                  ),
                  if (expanded)
                    Container(
                      color: Colors.grey[300],
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: List.generate(todos.length, (i) {
                          return Row(
                            children: [
                              Checkbox(
                                value: checked[i],
                                onChanged: (value) {
                                  todoProvider.toggleCheck(subject, i, value);
                                },
                              ),
                              Expanded(child: Text(todos[i])),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Color(0xFF004377)),
                                onPressed: () async {
                                  final newText = await showDialog<String>(
                                    context: context,
                                    builder: (context) {
                                      final controller = TextEditingController(text: todos[i]);
                                      return AlertDialog(
                                        title: const Text('할 일 수정'),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(hintText: '새로운 할 일 입력'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('취소'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(controller.text),
                                            child: const Text('저장'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (newText != null && newText.isNotEmpty && newText != todos[i]) {
                                    todoProvider.updateTodo(subject, i, newText);
                                  }
                                },
                              ),
                            ],
                          );
                        }),
                      ),
                    )
                ],
              );
            }),
            const Spacer(),
            Column(
              children: [
                OutlinedButton(
                   onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StudyPlanPage()),
                      );
                    },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF004377),
                    side: const BorderSide(color: Color(0xFF004377), width: 2),
                    minimumSize: const Size(300, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text(
                    "AI 학습 계획 세우기!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF004377),
                        side: const BorderSide(color: Color(0xFF004377), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const Text(
                        '과목 세부 사항 수정 및 추가',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}