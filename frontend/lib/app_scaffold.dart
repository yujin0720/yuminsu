// app_scaffold.dart
import 'package:flutter/material.dart';
import 'global_drawer.dart';
import 'submain.dart';
import 'timer.dart';
import 'folder_home_page.dart';
import 'mypage.dart';
import 'main.dart' show HomePage; // HomePage가 main.dart에 있으니 이렇게 임포트

enum AppTab { home, plan, timer, folder, my }

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  AppTab _currentTab = AppTab.home;

  void _setCurrentTab(AppTab t) => setState(() => _currentTab = t);

  Widget _buildBody() {
    switch (_currentTab) {
      case AppTab.home:   return const HomePage();
      case AppTab.plan:   return const SubMainPage();
      case AppTab.timer:  return const TimerPage();
      case AppTab.folder: return FolderHomePage();
      case AppTab.my:     return const MyPage();
    }
  }

// ▼ 여기에 추가 ( _buildBody() 밑 )
String _titleForTab(AppTab t) {
  switch (t) {
    case AppTab.home:   return '홈';
    case AppTab.plan:   return 'AI 학습플래너';
    case AppTab.timer:  return '타이머';
    case AppTab.folder: return '폴더';
    case AppTab.my:     return '마이 페이지';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForTab(_currentTab)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF004377)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF004377),
          fontSize: 20,
          fontWeight: FontWeight.normal,
        ),
        // 자동 햄버거가 환경에 따라 안 뜨는 경우 대비용(확실하게)
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      drawerEnableOpenDragGesture: true, // 가장자리 스와이프 열기 허용
      drawer: GlobalDrawer(
        onTapTab: _setCurrentTab,
        currentTab: _currentTab,
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.index,
        onTap: (i) => _setCurrentTab(AppTab.values[i]),
        type: BottomNavigationBarType.fixed,
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
