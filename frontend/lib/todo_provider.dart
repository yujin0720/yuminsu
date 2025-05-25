import 'package:flutter/material.dart';

class TodoProvider with ChangeNotifier {
  Map<String, List<String>> weeklyTodos = {
    'A 과목': ['1주차 시청하기'],
    'B 과목': ['1주차 시청하기', '2주차 시청하기'],
  };

  Map<String, List<bool>> todoChecked = {
    'A 과목': [false],
    'B 과목': [false, false],
  };

  // 할 일 텍스트 수정
  void updateTodo(String subject, int index, String newText) {
    if (weeklyTodos.containsKey(subject) && index < weeklyTodos[subject]!.length) {
      weeklyTodos[subject]![index] = newText;
      notifyListeners();
    }
  }

  // 체크 상태 토글
  void toggleCheck(String subject, int index, bool? value) {
    if (todoChecked.containsKey(subject) && index < todoChecked[subject]!.length) {
      todoChecked[subject]![index] = value ?? false;
      notifyListeners();
    }
  }

  // TODO: 오늘 할 일 리스트도 추가하고 싶으면 여기에 넣을 수 있음
}
