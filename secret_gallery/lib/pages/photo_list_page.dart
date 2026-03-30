import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../models/album.dart';
import '../models/photo.dart';
import '../services/db_service.dart';
import '../services/file_service.dart';
import 'gallery_picker_page.dart';
import 'photo_detail_page.dart';

enum _SortType { custom, newest, oldest, titleAZ, titleZA }

class PhotoListPage extends StatefulWidget {
  final Album album;

  const PhotoListPage({super.key, required this.album});

  @override
  State<PhotoListPage> createState() => _PhotoListPageState();
}

class _PhotoListPageState extends State<PhotoListPage> {
  final _db = DbService();
  final _fileService = FileService();
  List<Photo> _photos = [];

  // ─── Sort ────────────────────────────────────────────
  _SortType _sortType = _SortType.newest;
  bool _customSortSelectMode = false;
  final _reorderScrollController = ScrollController();
  bool get _showSelectAppBar => _selectedIds.isNotEmpty || _customSortSelectMode;

  List<Photo> get _displayedPhotos {
    final list = List<Photo>.from(_photos);
    switch (_sortType) {
      case _SortType.custom:
        break; // DB에서 sort_order ASC로 이미 정렬됨
      case _SortType.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortType.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortType.titleAZ:
        list.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
      case _SortType.titleZA:
        list.sort((a, b) => (b.title ?? '').compareTo(a.title ?? ''));
    }
    return list;
  }

  // ─── Multi-select ─────────────────────────────────────────────
  final Set<int> _selectedIds = {};
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void dispose() {
    _reorderScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    final photos = await _db.getPhotos(widget.album.id!);
    setState(() => _photos = photos);
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

  /// 드래그 중 포인터 위치 아래의 사진을 선택에 추가한다.
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
        title: const Text('사진 삭제'),
        content: Text('선택한 ${_selectedIds.length}개의 사진을 삭제할까요?'),
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
      final toDelete = _photos.where((p) => _selectedIds.contains(p.id)).toList();
      for (final photo in toDelete) {
        await _db.deletePhoto(photo.id!);
        await _fileService.deleteImage(photo.path);
      }
      _clearSelection();
      _loadPhotos();
    }
  }

  Future<void> _shareSelected() async {
    final files = _photos
        .where((p) => _selectedIds.contains(p.id))
        .map((p) => XFile(p.path))
        .toList();
    if (files.isEmpty) return;
    await Share.shareXFiles(files);
  }

  Future<void> _addPhoto() async {
    // GalleryPickerPage 내부에서 photo_manager 권한 처리
    final result = await Navigator.push<List<AssetEntity>>(
      context,
      MaterialPageRoute(builder: (_) => const GalleryPickerPage()),
    );
    if (result == null || result.isEmpty) return;

    for (final asset in result) {
      final file = await asset.file;
      if (file == null) continue;
      final savedPath = await _fileService.saveImage(file.path);
      await _db.insertPhoto(Photo(
        albumId: widget.album.id!,
        path: savedPath,
        createdAt: DateTime.now().toIso8601String(),
      ));
    }
    _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showSelectAppBar,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _showSelectAppBar
            ? AppBar(
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
                leading: IconButton(
                    icon: const Icon(Icons.close), onPressed: _clearSelection),
                title: Text(_selectedIds.isEmpty
                    ? '사진 선택'
                    : '${_selectedIds.length}개 선택됨'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: '선택 공유',
                    onPressed: _shareSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: '선택 삭제',
                    onPressed: _deleteSelected,
                  ),
                ],
              )
            : AppBar(
                title: Text(widget.album.name),
                centerTitle: true,
                backgroundColor: Colors.grey[900],
                foregroundColor: Colors.white,
                actions: [
                  PopupMenuButton<_SortType>(
                    icon: const Icon(Icons.sort),
                    tooltip: '정렬',
                    color: Colors.grey[850],
                    onSelected: (v) => setState(() => _sortType = v),
                    itemBuilder: (_) => [
                      _sortMenuItem(_SortType.custom, '직접 정렬', Icons.touch_app),
                      _sortMenuItem(_SortType.newest, '최신순', Icons.schedule),
                      _sortMenuItem(_SortType.oldest, '오래된순', Icons.history),
                      _sortMenuItem(
                          _SortType.titleAZ, '제목 A→Z', Icons.sort_by_alpha),
                      _sortMenuItem(
                          _SortType.titleZA, '제목 Z→A', Icons.sort_by_alpha),
                    ],
                  ),
                  if (_sortType == _SortType.custom)
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      tooltip: '선택 삭제',
                      onPressed: () =>
                          setState(() => _customSortSelectMode = true),
                    ),
                  if (widget.album.type == 'secret')
                    IconButton(
                      icon: const Icon(Icons.lock_reset),
                      tooltip: '앨범 비밀번호 변경',
                      onPressed: _showChangeAlbumPasswordDialog,
                    ),
                ],
              ),
        backgroundColor: Colors.grey[850],
        body: _photos.isEmpty
            ? const Center(
                child: Text(
                  '사진이 없습니다.\n+ 버튼으로 사진을 추가해보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
            : (_sortType == _SortType.custom && !_showSelectAppBar)
                ? _buildReorderableGrid()
                : _buildNormalGrid(),
        floatingActionButton: _showSelectAppBar
            ? null
            : FloatingActionButton(
                onPressed: _addPhoto,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: const Icon(Icons.add_a_photo),
              ),
      ),
    );
  }

  PopupMenuItem<_SortType> _sortMenuItem(
      _SortType value, String label, IconData icon) {
    final selected = _sortType == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: selected ? Colors.blueAccent : Colors.white70),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: selected ? Colors.blueAccent : Colors.white,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(Photo photo, {bool reorderMode = false}) {
    final id = photo.id!;
    final isSelected = _selectedIds.contains(id);
    return GestureDetector(
      key: ValueKey<String>('photo_$id'),
      onTap: reorderMode
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PhotoDetailPage(photo: photo)),
              );
              _loadPhotos();
            }
          : (_showSelectAppBar
              ? () => _toggleSelect(id)
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PhotoDetailPage(photo: photo)),
                  );
                  _loadPhotos();
                }),
      onLongPress: reorderMode ? null : () => _toggleSelect(id),
      child: Stack(
        key: reorderMode ? null : _itemKeys.putIfAbsent(id, () => GlobalKey()),
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'photo_$id',
            child: Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[700],
                child: const Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
          ),
          if (isSelected && !reorderMode) ...[
            Container(color: Colors.blue.withOpacity(0.35)),
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.check_circle, color: Colors.white, size: 22),
            ),
          ],
          if (reorderMode)
            const Positioned(
              top: 4,
              right: 4,
              child:
                  Icon(Icons.drag_handle, color: Colors.white38, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildNormalGrid() {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: (e) {
        if (_showSelectAppBar) _selectAtPos(e.position);
      },
      child: GridView.builder(
        physics: _showSelectAppBar
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _displayedPhotos.length,
        itemBuilder: (_, index) => _buildPhotoCard(_displayedPhotos[index]),
      ),
    );
  }

  Widget _buildReorderableGrid() {
    final children =
        _photos.map((p) => _buildPhotoCard(p, reorderMode: true)).toList();
    return ReorderableBuilder<Photo>(
      scrollController: _reorderScrollController,
      children: children,
      onReorder: (reorderCallback) {
        setState(() {
          _photos = reorderCallback(_photos);
        });
        _db.updatePhotoSortOrders(_photos.map((p) => p.id!).toList());
      },
      builder: (updatedChildren) {
        return GridView(
          controller: _reorderScrollController,
          padding: const EdgeInsets.all(4),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          children: updatedChildren,
        );
      },
    );
  }

  Future<void> _showChangeAlbumPasswordDialog() async {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String errorMsg = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('앨범 비밀번호 변경',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pwField(newCtrl, '새 비밀번호'),
              const SizedBox(height: 12),
              _pwField(confirmCtrl, '새 비밀번호 확인'),
              if (errorMsg.isNotEmpty) ...
                [
                  const SizedBox(height: 10),
                  Text(errorMsg,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black),
              onPressed: () async {
                final newPw = newCtrl.text.trim();
                final confirm = confirmCtrl.text.trim();
                if (newPw.isEmpty) {
                  setDialogState(() => errorMsg = '새 비밀번호를 입력하세요.');
                  return;
                }
                if (newPw != confirm) {
                  setDialogState(
                      () => errorMsg = '비밀번호가 일치하지 않습니다.');
                  return;
                }
                await _db.updateAlbumPassword(widget.album.id!, newPw);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('앨범 비밀번호가 변경되었습니다.')),
                  );
                }
              },
              child: const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
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
    );
  }
}
