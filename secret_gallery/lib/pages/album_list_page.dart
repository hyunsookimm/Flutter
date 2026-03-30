import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';

import '../models/album.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import 'photo_list_page.dart';
import 'settings_page.dart';

enum _SortType { custom, newest, oldest, nameAZ, nameZA }

class AlbumListPage extends StatefulWidget {
  const AlbumListPage({super.key});

  @override
  State<AlbumListPage> createState() => _AlbumListPageState();
}

class _AlbumListPageState extends State<AlbumListPage> {
  final _db = DbService();
  List<Album> _albums = [];

  // ─── Multi-select ─────────────────────────────────────────────
  final Set<int> _selectedIds = {};
  final Map<int, GlobalKey> _itemKeys = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  // ─── Search ───────────────────────────────────────────────────
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ─── Sort ─────────────────────────────────────────────────────
  _SortType _sortType = _SortType.newest;
  final _reorderScrollController = ScrollController();
  bool _customSortSelectMode = false;
  bool get _showSelectAppBar => _selectedIds.isNotEmpty || _customSortSelectMode;

  List<Album> get _displayedAlbums {
    var list = _searchQuery.isEmpty
        ? List<Album>.from(_albums)
        : _albums
            .where((a) =>
                a.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    switch (_sortType) {
      case _SortType.custom:
        break; // DB에서 sort_order ASC로 이미 정렬됨
      case _SortType.newest:
        list.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      case _SortType.oldest:
        list.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      case _SortType.nameAZ:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _SortType.nameZA:
        list.sort((a, b) => b.name.compareTo(a.name));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reorderScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    final albums = await _db.getAlbums();
    setState(() => _albums = albums);
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _toggleSelect(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
    });
  }

  void _clearSelection() => setState(() {
    _selectedIds.clear();
    _customSortSelectMode = false;
  });

  /// 드래그 중 포인터 아래의 앨범을 선택에 추가한다.
  void _selectAtPos(Offset globalPos) {
    for (final entry in _itemKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(globalPos) && !_selectedIds.contains(entry.key)) {
        setState(() => _selectedIds.add(entry.key));
        HapticFeedback.selectionClick();
        break;
      }
    }
  }

  Future<void> _deleteSelected() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('앨범 삭제'),
        content: Text('선택한 ${_selectedIds.length}개의 앨범을 삭제할까요?\n앨범 안의 모든 사진도 함께 삭제됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      for (final id in List.from(_selectedIds)) {
        await _db.deleteAlbum(id);
      }
      _clearSelection();
      _loadAlbums();
    }
  }

  void _showCreateAlbumDialog() {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSecret = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('앨범 만들기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '앨범 이름'),
              ),
              Row(
                children: [
                  const Text('비밀 앨범'),
                  Switch(
                    value: isSecret,
                    onChanged: (v) => setDialogState(() => isSecret = v),
                  ),
                ],
              ),
              if (isSecret)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '앨범 비밀번호'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final album = Album(
                  name: name,
                  type: isSecret ? 'secret' : 'normal',
                  password: isSecret ? passwordController.text.trim() : null,
                );

                await _db.insertAlbum(album);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadAlbums();
              },
              child: const Text('만들기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAlbum(Album album) async {
    if (album.type == 'secret') {
      final confirmed = await _showPasswordDialog(album.password);
      if (!confirmed) return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PhotoListPage(album: album)),
    );
    _loadAlbums();
  }

  Future<bool> _showPasswordDialog(String? correctPassword) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('비밀 앨범'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: '비밀번호를 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                ctx, AuthService().checkAlbumPassword(correctPassword, ctrl.text.trim())),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (ok != true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('비밀번호가 틀렸습니다.')));
    }
    return ok == true;
  }

  PopupMenuItem<_SortType> _sortMenuItem(
      _SortType value, String label, IconData icon) {
    final selected = _sortType == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: selected ? Colors.blueAccent : Colors.white70),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: selected ? Colors.blueAccent : Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // ─── 앨범 카드 공통 위젯 ─────────────────────────────────────
  Widget _buildAlbumCard(Album album, {bool reorderMode = false}) {
    final id = album.id!;
    final isSelected = _selectedIds.contains(id);
    return GestureDetector(
      key: ValueKey<String>('album_$id'),
      onTap: reorderMode
          ? () => _openAlbum(album)
          : (_showSelectAppBar ? () => _toggleSelect(id) : () => _openAlbum(album)),
      onLongPress: reorderMode ? null : () => _toggleSelect(id),
      child: AnimatedContainer(
        key: reorderMode ? null : _itemKeys.putIfAbsent(id, () => GlobalKey()),
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected && !reorderMode
              ? Colors.blue.withOpacity(0.25)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected && !reorderMode
                ? Colors.blueAccent
                : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  album.type == 'secret'
                      ? Icons.lock
                      : Icons.photo_album_rounded,
                  size: 52,
                  color: album.type == 'secret'
                      ? Colors.amber
                      : Colors.blue[300],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    album.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  album.type == 'secret' ? '비밀 앨범' : '일반 앨범',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            if (isSelected && !reorderMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
            if (reorderMode)
              const Positioned(
                top: 8,
                right: 8,
                child:
                    Icon(Icons.drag_handle, color: Colors.white38, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalGrid() {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: (e) {
        if (_isSelecting) _selectAtPos(e.position);
      },
      child: GridView.builder(
        physics: _isSelecting
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: _displayedAlbums.length,
        itemBuilder: (_, index) => _buildAlbumCard(_displayedAlbums[index]),
      ),
    );
  }

  Widget _buildReorderableGrid() {
    final children =
        _albums.map((a) => _buildAlbumCard(a, reorderMode: true)).toList();
    return ReorderableBuilder<Album>(
      scrollController: _reorderScrollController,
      children: children,
      onReorder: (reorderCallback) {
        setState(() {
          _albums = reorderCallback(_albums);
        });
        _db.updateAlbumSortOrders(_albums.map((a) => a.id!).toList());
      },
      builder: (updatedChildren) {
        return GridView(
          controller: _reorderScrollController,
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          children: updatedChildren,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showSelectAppBar && !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_showSelectAppBar) _clearSelection();
          if (_isSearching) _stopSearch();
        }
      },
      child: Scaffold(
        appBar: _showSelectAppBar
            ? AppBar(
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
                leading: IconButton(
                    icon: const Icon(Icons.close), onPressed: _clearSelection),
                title: Text('${_selectedIds.length}개 선택됨'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: '선택 삭제',
                    onPressed: _deleteSelected,
                  ),
                ],
              )
            : AppBar(
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        decoration: const InputDecoration(
                          hintText: '앨범 이름 검색...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      )
                    : const Text('시크릿 갤러리'),
                centerTitle: !_isSearching,
                backgroundColor: Colors.grey[900],
                foregroundColor: Colors.white,
                leading: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _stopSearch,
                      )
                    : null,
                actions: _isSearching
                    ? [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ]
                    : [
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: '검색',
                          onPressed: _startSearch,
                        ),
                        PopupMenuButton<_SortType>(
                          icon: const Icon(Icons.sort),
                          tooltip: '정렬',
                          color: Colors.grey[850],
                          onSelected: (v) => setState(() => _sortType = v),
                          itemBuilder: (_) => [
                            _sortMenuItem(_SortType.custom, '직접 정렬',
                                Icons.touch_app),
                            _sortMenuItem(_SortType.newest, '최신순',
                                Icons.schedule),
                            _sortMenuItem(_SortType.oldest, '오래된순',
                                Icons.history),
                            _sortMenuItem(
                                _SortType.nameAZ, '이름 ㄱ→ㅎ', Icons.sort_by_alpha),
                            _sortMenuItem(
                                _SortType.nameZA, '이름 ㅎ→ㄱ', Icons.sort_by_alpha),
                          ],
                        ),
                        if (_sortType == _SortType.custom)
                          IconButton(
                            icon: const Icon(Icons.checklist),
                            tooltip: '선택 삭제',
                            onPressed: () =>
                                setState(() => _customSortSelectMode = true),
                          ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          tooltip: '설정',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsPage()),
                          ),
                        ),
                      ],
              ),
        backgroundColor: Colors.grey[850],
        body: _albums.isEmpty
            ? const Center(
                child: Text(
                  '앨범이 없습니다.\n+ 버튼으로 앨범을 만들어보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
            : _displayedAlbums.isEmpty
                ? const Center(
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : (_sortType == _SortType.custom && !_isSearching && !_showSelectAppBar)
                    ? _buildReorderableGrid()
                    : _buildNormalGrid(),
        floatingActionButton: _isSelecting
            ? null
            : FloatingActionButton(
                onPressed: _showCreateAlbumDialog,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
