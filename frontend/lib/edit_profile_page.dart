import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final TextEditingController newPwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  bool isEditingName = false;
  bool isEditingEmail = false;
  bool isEditingPhone = false;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final response = await http.get(Uri.parse('https://your.api.com/user/info'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phonenumber'] ?? '';
        });
      } else {
        print('사용자 정보 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('사용자 정보 요청 중 오류 발생: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('회원정보 수정', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInlineEditableRow(
              label: '이름',
              controller: nameController,
              isEditing: isEditingName,
              onEditToggle: () {
                setState(() => isEditingName = !isEditingName);
              },
              onSubmitted: (val) {
                setState(() => isEditingName = false);
              },
            ),
            _buildInlineEditableRow(
              label: '이메일',
              controller: emailController,
              isEditing: isEditingEmail,
              onEditToggle: () {
                setState(() => isEditingEmail = !isEditingEmail);
              },
              onSubmitted: (val) {
                setState(() => isEditingEmail = false);
              },
            ),
            _buildInlineEditableRow(
              label: '연락처',
              controller: phoneController,
              isEditing: isEditingPhone,
              onEditToggle: () {
                setState(() => isEditingPhone = !isEditingPhone);
              },
              onSubmitted: (val) {
                setState(() => isEditingPhone = false);
              },
            ),
            Divider(height: 40, color: Colors.grey.shade300),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(newPwController, '새로운 비밀번호를 입력하세요'),
            const SizedBox(height: 10),
            _buildPasswordField(confirmPwController, '새로운 비밀번호를 다시 입력하세요'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: 저장 API 호출 추가
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004377),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text('저장', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInlineEditableRow({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required Function(String) onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    autofocus: true,
                    onSubmitted: onSubmitted,
                    decoration: const InputDecoration(isDense: true),
                  )
                : Text(controller.text),
          ),
          TextButton(
            onPressed: onEditToggle,
            style: TextButton.styleFrom(
              side: const BorderSide(color: Color(0xFF004377)),
              minimumSize: const Size(48, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('수정', style: TextStyle(color: Color(0xFF004377))),
          )
        ],
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
