import 'dart:async';
import 'package:flutter/material.dart';
import '../services/file_service.dart';
import 'write_page.dart';
import 'detail_page.dart';
import 'calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FileService _fileService = FileService();
  final TextEditingController _searchController = TextEditingController();

  List<DiaryEntry> _diaryList = [];
  List<DiaryEntry> _filteredList = [];

  bool _isSearching = false;
  bool _isMultiSelect = false;
  bool _isSearchLoading = false;

  Set<String> _selectedPaths = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadDiaries() async {
    final list = await _fileService.getDiaryEntries();
    if (mounted) {
      setState(() {
        _diaryList = list;
        _filteredList = _isSearching && _searchController.text.isNotEmpty
            ? _filteredList
            : list;
      });
    }
  }

  // ─── 검색 ───────────────────────────────────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _filteredList = _diaryList;
        _isSearchLoading = false;
      });
      return;
    }
    setState(() => _isSearchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _fileService.searchEntries(query);
      if (mounted) {
        setState(() {
          _filteredList = results;
          _isSearchLoading = false;
        });
      }
    });
  }

  void _startSearch() => setState(() {
        _isSearching = true;
        _isMultiSelect = false;
        _selectedPaths.clear();
      });

  void _stopSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _isSearchLoading = false;
      _filteredList = _diaryList;
    });
  }

  // ─── 다중 선택 ───────────────────────────────────────────
  void _startMultiSelect() => setState(() {
        _isMultiSelect = true;
        _isSearching = false;
        _searchController.clear();
        _filteredList = _diaryList;
        _selectedPaths.clear();
      });

  void _stopMultiSelect() {
    setState(() {
      _isMultiSelect = false;
      _selectedPaths.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedPaths.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('선택 삭제'),
        content: Text('${_selectedPaths.length}개의 일기를 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _fileService.deleteMultiple(_selectedPaths.toList());
      _stopMultiSelect();
      _loadDiaries();
    }
  }

  // ─── 단일 삭제 ──────────────────────────────────────────
  Future<void> _deleteSingle(String path) async {
    await _fileService.deleteDiary(path);
    await _loadDiaries();
  }

  // ─── 빌드 ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: _isMultiSelect
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WritePage()),
                );
                _loadDiaries();
              },
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              child: const Icon(Icons.edit),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.amber,
      foregroundColor: Colors.black,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '날짜(예: 2026-03) 또는 내용으로 검색...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.black45),
              ),
              style: const TextStyle(color: Colors.black, fontSize: 16),
              onChanged: _onSearchChanged,
            )
          : const Text('내 일기장'),
      actions: [
        if (_isMultiSelect) ...[
          if (_selectedPaths.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '선택 삭제 (${_selectedPaths.length})',
              onPressed: _deleteSelected,
            ),
          TextButton(
            onPressed: _stopMultiSelect,
            child: const Text('취소', style: TextStyle(color: Colors.black)),
          ),
        ] else ...[
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? '검색 닫기' : '검색',
            onPressed: _isSearching ? _stopSearch : _startSearch,
          ),
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            tooltip: '선택 삭제 모드',
            onPressed: _startMultiSelect,
          ),
        ],
      ],
    );
  }

  // ─── Drawer ──────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.menu_book, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text('내 일기장',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('달력으로 보기'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarPage()),
              );
              _loadDiaries();
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('전체 일기'),
            onTap: () {
              Navigator.pop(context);
              _stopSearch();
              _stopMultiSelect();
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('일기 검색'),
            onTap: () {
              Navigator.pop(context);
              _startSearch();
            },
          ),
          ListTile(
            leading: const Icon(Icons.checklist_rounded),
            title: const Text('선택 삭제'),
            onTap: () {
              Navigator.pop(context);
              _startMultiSelect();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('새 일기 쓰기'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WritePage()),
              );
              _loadDiaries();
            },
          ),
        ],
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    if (_filteredList.isEmpty) {
      return Center(
        child: Text(
          _isSearching && _searchController.text.isNotEmpty
              ? '검색 결과가 없습니다.'
              : '작성된 일기가 없습니다.\n+ 버튼을 눌러 첫 일기를 써보세요!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return _isMultiSelect ? _buildMultiSelectList() : _buildNormalList();
  }

  // ─── 일반 목록 (Dismissible 스와이프 삭제) ──────────────
  Widget _buildNormalList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final entry = _filteredList[index];
        final date = entry.date;
        final time = entry.time;

        return Dismissible(
          key: Key(entry.path),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: Colors.white, size: 28),
                SizedBox(height: 4),
                Text('삭제', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          confirmDismiss: (_) => showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('일기 삭제'),
              content: Text('[$date] 일기를 삭제하시겠습니까?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('취소')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('삭제',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
          onDismissed: (_) => _deleteSingle(entry.path),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade100,
                child: const Icon(Icons.book, color: Colors.amber),
              ),
              title: Text(
                entry.title.isNotEmpty ? entry.title : date,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                '$date${time.isNotEmpty ? "  $time" : ""}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailPage(
                        path: entry.path, date: entry.date, time: entry.time),
                  ),
                );
                _loadDiaries();
              },
            ),
          ),
        );
      },
    );
  }

  // ─── 다중 선택 목록 ─────────────────────────────────────
  Widget _buildMultiSelectList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              Text(
                _selectedPaths.isEmpty
                    ? '삭제할 일기를 선택하세요'
                    : '${_selectedPaths.length}개 선택됨',
                style: TextStyle(
                    color: _selectedPaths.isEmpty
                        ? Colors.grey
                        : Colors.amber.shade800,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedPaths.length == _filteredList.length) {
                      _selectedPaths.clear();
                    } else {
                      _selectedPaths =
                          _filteredList.map((e) => e.path).toSet();
                    }
                  });
                },
                child: Text(
                  _selectedPaths.length == _filteredList.length
                      ? '전체 해제'
                      : '전체 선택',
                  style: const TextStyle(color: Colors.amber),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _filteredList.length,
            itemBuilder: (context, index) {
              final entry = _filteredList[index];
              final isSelected = _selectedPaths.contains(entry.path);

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: isSelected
                      ? const BorderSide(color: Colors.amber, width: 2)
                      : BorderSide(color: Colors.grey.shade300),
                ),
                color: isSelected ? Colors.amber.shade50 : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedPaths.remove(entry.path);
                      } else {
                        _selectedPaths.add(entry.path);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.amber : Colors.grey,
                          size: 26,
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.book, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title.isNotEmpty
                                    ? entry.title
                                    : entry.date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              Text(
                                '${entry.date}${entry.time.isNotEmpty ? "  ${entry.time}" : ""}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedPaths.isNotEmpty)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_forever),
                  label: Text('${_selectedPaths.length}개 일기 삭제'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
