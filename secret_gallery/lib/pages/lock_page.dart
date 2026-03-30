import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'album_list_page.dart';

class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final _auth = AuthService();
  final _controller = TextEditingController();
  bool _isSettingMode = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkPasswordExists();
  }

  Future<void> _checkPasswordExists() async {
    final hasPassword = await _auth.hasAppPassword();
    if (!hasPassword) {
      setState(() => _isSettingMode = true);
    }
  }

  Future<void> _onSubmit() async {
    final input = _controller.text.trim();

    if (input.isEmpty) return;

    if (_isSettingMode) {
      await _auth.setAppPassword(input);
      _navigateToAlbumList();
    } else {
      final ok = await _auth.checkAppPassword(input);
      if (ok) {
        _navigateToAlbumList();
      } else {
        setState(() => _errorMessage = '비밀번호가 틀렸습니다.');
        _controller.clear();
      }
    }
  }

  void _navigateToAlbumList() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AlbumListPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 72, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                _isSettingMode ? '새 비밀번호를 설정하세요' : '비밀번호를 입력하세요',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
                onSubmitted: (_) => _onSubmit(),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_isSettingMode ? '설정' : '잠금 해제'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
