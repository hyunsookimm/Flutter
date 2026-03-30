import 'dart:io';

import 'package:flutter/material.dart';

import '../models/photo.dart';
import '../services/db_service.dart';
import '../services/share_service.dart';

class PhotoDetailPage extends StatefulWidget {
  final Photo photo;

  const PhotoDetailPage({super.key, required this.photo});

  @override
  State<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  final _db = DbService();
  final _shareService = ShareService();

  late final TextEditingController _titleController;
  late final TextEditingController _memoController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.photo.title ?? '');
    _memoController = TextEditingController(text: widget.photo.memo ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveMetadata() async {
    setState(() => _isSaving = true);
    await _db.updatePhotoMeta(
      widget.photo.id!,
      _titleController.text.trim(),
      _memoController.text.trim(),
    );
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장되었습니다.')),
      );
    }
  }

  Future<void> _sharePhoto() async {
    await _shareService.sharePhoto(widget.photo.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('사진 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePhoto,
            tooltip: '공유',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 뷰어
            Hero(
              tag: 'photo_${widget.photo.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.photo.path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 제목 입력
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '제목',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),

            const SizedBox(height: 16),

            // 메모 입력
            TextField(
              controller: _memoController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '메모',
                labelStyle: const TextStyle(color: Colors.white54),
                alignLabelWithHint: true,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),

            const SizedBox(height: 8),

            // 저장 날짜
            Text(
              '등록일: ${widget.photo.createdAt.substring(0, 10)}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),

            const SizedBox(height: 24),

            // 저장 버튼
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveMetadata,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
