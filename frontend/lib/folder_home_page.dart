// folder_home_page.dart - AccessToken 적용 & 리팩토링 버전
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'note_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'env.dart';

class FolderHomePage extends StatefulWidget {
  const FolderHomePage({super.key});

  static const background = Color(0xFFFFFFFF);
  static const cobaltBlue = Color(0xFF004377);

  @override
  State<FolderHomePage> createState() => _FolderHomePageState();
}

class _FolderHomePageState extends State<FolderHomePage> {
  List<Map<String, dynamic>> folders = [];
  List<bool> isEditing = [];
  List<TextEditingController> controllers = [];

void _openChat() {
  final controller = TextEditingController();
  final scroll = ScrollController();
  final messages = <_ChatMsg>[
    _ChatMsg(role: 'assistant', text: '무엇을 도와드릴까요? PDF나 폴더 관련해서 물어보세요!'),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // 키보드
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            void send() {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              setModalState(() {
                messages.add(_ChatMsg(role: 'user', text: text));
                controller.clear();
              });
              // 🔧 추후 RAG 연동 위치
              Future.delayed(const Duration(milliseconds: 300), () {
                setModalState(() {
                  messages.add(_ChatMsg(role: 'assistant', text: '좋아요! (지금은 UI 데모 응답입니다)'));
                  scroll.animateTo(
                    scroll.position.maxScrollExtent + 120,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                });
              });
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        const Text('챗봇', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // 메시지 리스트
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final m = messages[i];
                        final isUser = m.role == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF004377) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  // 입력 영역
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: '메시지를 입력하세요…',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onSubmitted: (_) => send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: send,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}




  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> _fetchFolders() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/pdf/folders'),

        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          folders =
              data
                  .map((f) => {'id': f['folder_id'], 'name': f['name']})
                  .toList();
          controllers = List.generate(
            folders.length,
            (i) => TextEditingController(text: folders[i]['name']),
          );
          isEditing = List.filled(folders.length, false);
        });
      } else {
        debugPrint('폴더 목록 요청 실패: ${response.body}');
      }
    } catch (e) {
      debugPrint('폴더 목록 요청 예외: $e');
    }
  }

  Future<void> _createFolder() async {
    final folderName = _generateUniqueFolderName();
    final accessToken = await getAccessToken();
    if (accessToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/pdf/folders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'name': folderName}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchFolders();
        Future.delayed(const Duration(milliseconds: 50), () {
          setState(() {
            isEditing[folders.length - 1] = true;
          });
        });
      } else {
        debugPrint('폴더 생성 실패: ${response.body}');
      }
    } catch (e) {
      debugPrint('폴더 생성 예외: $e');
    }
  }

  Future<void> _renameFolder(int folderId, String newName) async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return;

    try {
      final response = await http.patch(
        Uri.parse('${Env.baseUrl}/pdf/folders/$folderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'name': newName}),
      );

      if (response.statusCode == 200) {
        await _fetchFolders();
      } else {
        debugPrint('이름 변경 실패: ${response.body}');
      }
    } catch (e) {
      debugPrint('이름 변경 예외: $e');
    }
  }

  Future<void> _deleteFolder(int folderId) async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${Env.baseUrl}/pdf/folders/$folderId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        await _fetchFolders();
      } else {
        debugPrint('삭제 실패: ${response.body}');
      }
    } catch (e) {
      debugPrint('삭제 예외: $e');
    }
  }

  String _generateUniqueFolderName() {
    String baseName = '새 폴더';
    String newName = baseName;
    int counter = 1;
    while (folders.any((f) => f['name'] == newName)) {
      newName = '$baseName ($counter)';
      counter++;
    }
    return newName;
  }

  void _enterFolder(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => NoteListPage(
              folderId: folders[index]['id'],
              folderName: folders[index]['name'],
            ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.create_new_folder,
                  color: FolderHomePage.cobaltBlue,
                ),
                title: const Text('폴더'),
                onTap: () {
                  Navigator.pop(context);
                  _createFolder();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.upload_file,
                  color: FolderHomePage.cobaltBlue,
                ),
                title: const Text('불러오기'),
                onTap: () {
                  Navigator.pop(context);
                  debugPrint('파일 불러오기 기능은 아직 구현되지 않았습니다.');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('폴더 삭제'),
            content: const Text('정말로 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteFolder(folders[index]['id']);
                },
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showFolderOptions(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('이름 변경'),
              onTap: () {
                Navigator.pop(context);
                setState(() => isEditing[index] = true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('삭제'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(index);
              },
            ),
          ],
        );
      },
    );
  }


@override
Widget build(BuildContext context) {
  return Container(
    color: const Color(0xFFFFFFFF), // 배경
    child: Stack(
      children: [
        // 본문 그리드
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
            children: List.generate(
              folders.length,
              (index) => _buildFolder(index),
            ),
          ),
        ),
        Positioned(
        right: 16,
        bottom: 88, // + 버튼보다 위로
        child: FloatingActionButton(
          heroTag: 'addFab', // ← 기존 + 버튼과 heroTag 다르게!
          backgroundColor: Colors.white,
          foregroundColor: FolderHomePage.cobaltBlue,
          elevation: 3,
          onPressed: _openChat, // ← 방금 만든 함수
          child: const Icon(Icons.chat_bubble_outline),
        ),
      ),

        // 우하단 플로팅 버튼
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: FolderHomePage.cobaltBlue,
            onPressed: () => _showAddOptions(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildFolder(int index) {
    return GestureDetector(
      onTap: () => _enterFolder(index),
      onLongPress: () => _showFolderOptions(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder, size: 48, color: FolderHomePage.cobaltBlue),
          const SizedBox(height: 8),
          isEditing[index]
              ? SizedBox(
                width: 80,
                height: 30,
                child: TextField(
                  controller: controllers[index],
                  autofocus: true,
                  onSubmitted: (value) {
                    _renameFolder(folders[index]['id'], value);
                    setState(() => isEditing[index] = false);
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              )
              : Text(
                folders[index]['name'],
                style: const TextStyle(color: FolderHomePage.cobaltBlue),
              ),
        ],
      ),
    );
  }
}

// ▼ 파일 하단(클래스 밖) 아무 곳에 간단한 메시지 모델 추가
class _ChatMsg {
  final String role; // 'user' or 'assistant'
  final String text;
  _ChatMsg({required this.role, required this.text});
}