import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../services/file_service.dart';

class DetailPage extends StatefulWidget {
  final String path;
  final String date;
  final String time;

  const DetailPage({
    super.key,
    required this.path,
    required this.date,
    this.time = '',
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final FileService _fileService = FileService();
  String _title = '';
  String _content = '';
  bool _isLoading = true;
  bool _isEditing = false;
  late DateTime _selectedDate;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.tryParse(widget.date) ?? DateTime.now();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadContent();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final raw = await _fileService.readDiaryRaw(widget.path);
    final parsedTitle = _fileService.parseTitleFromRaw(raw);
    final parsedContent = _fileService.parseContentFromRaw(raw);
    setState(() {
      _title = parsedTitle;
      _content = parsedContent;
      _titleController.text = parsedTitle;
      _contentController.text = parsedContent;
      _isLoading = false;
    });
  }

  String get _selectedDateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final result = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        selectedDayHighlightColor: Colors.amber,
        okButton: const Text('확인', style: TextStyle(color: Colors.amber)),
        cancelButton: const Text('취소'),
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
      value: [_selectedDate],
    );
    if (result != null && result.isNotEmpty && result.first != null) {
      setState(() => _selectedDate = result.first!);
    }
  }

  Future<void> _saveEdit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요.')),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요.')),
      );
      return;
    }
    // 날짜가 변경된 경우 파일 이름도 변경
    if (_selectedDateStr != widget.date) {
      await _fileService.changeDiaryDate(
          widget.path, _selectedDateStr, title, content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정되었습니다!')),
        );
        Navigator.pop(context);
      }
      return;
    }
    await _fileService.saveDiaryToPath(widget.path, title, content);
    setState(() {
      _title = title;
      _content = content;
      _isEditing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정되었습니다!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLoading ? widget.date : (_title.isNotEmpty ? _title : widget.date),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_isEditing ? _selectedDateStr : widget.date}${widget.time.isNotEmpty ? "  ${widget.time}" : ""}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        actions: [
          if (!_isLoading)
            _isEditing
                ? IconButton(
                    onPressed: _saveEdit,
                    icon: const Icon(Icons.check),
                    tooltip: '저장',
                  )
                : IconButton(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit),
                    tooltip: '수정',
                  ),
        ],
      ),
      bottomSheet: !_isEditing ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isEditing ? _saveEdit : null,
              icon: !_isEditing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.edit_note, size: 22),
              label: const Text(
                '수정하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _isEditing
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: Column(
                    children: [
                      // 날짜 선택
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.amber, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  color: Colors.amber),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '날짜: $_selectedDateStr',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Text('변경',
                                  style: TextStyle(
                                      color: Colors.amber, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: '제목',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFFFFDE7),
                          prefixIcon: Icon(Icons.title, color: Colors.amber),
                        ),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText: '내용',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFFFFDE7),
                          ),
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_title.isNotEmpty) ...[
                        Text(
                          _title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24, thickness: 1),
                      ],
                      Text(
                        _content,
                        style: const TextStyle(fontSize: 16, height: 1.8),
                      ),
                    ],
                  ),
                ),
    );
  }
}
