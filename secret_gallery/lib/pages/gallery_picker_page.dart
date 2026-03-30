import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

/// 기기 갤러리에서 여러 장을 탭으로 선택한 뒤 확인 버튼으로 반환하는 인앱 피커.
/// 반환값: 선택된 [AssetEntity] 목록 (취소 시 null)
class GalleryPickerPage extends StatefulWidget {
  const GalleryPickerPage({super.key});

  @override
  State<GalleryPickerPage> createState() => _GalleryPickerPageState();
}

class _GalleryPickerPageState extends State<GalleryPickerPage> {
  List<AssetEntity> _assets = [];
  final Set<AssetEntity> _selected = {};
  bool _loading = true;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    // permission_handler로 먼저 권한 확인 / 요청
    final bool granted = await _checkPermission();
    if (!granted) {
      setState(() {
        _denied = true;
        _loading = false;
      });
      return;
    }

    // photo_manager 내부 권한 검사 우회 (permission_handler가 이미 처리)
    PhotoManager.setIgnorePermissionCheck(true);
    await _loadAssetsInternal();
  }

  Future<bool> _checkPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
    // Android 14+ : READ_MEDIA_VISUAL_USER_SELECTED (limited = 선택 사진)
    final visual = await Permission.photos.request();
    if (visual.isGranted || visual.isLimited) return true;
    // Android 13 : READ_MEDIA_IMAGES
    final images = Permission.mediaLibrary;
    final imgStatus = await images.request();
    if (imgStatus.isGranted) return true;
    // Android 12 이하 : READ_EXTERNAL_STORAGE
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  Future<void> _loadAssetsInternal() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (paths.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // 모든 사진 앨범(첫 번째 경로 = 전체) 에서 가져오기
    final all = paths.first;
    final count = await all.assetCountAsync;
    final assets = await all.getAssetListRange(start: 0, end: count);

    setState(() {
      _assets = assets;
      _loading = false;
    });
  }

  void _toggle(AssetEntity asset) {
    setState(() {
      if (_selected.contains(asset)) _selected.remove(asset);
      else _selected.add(asset);
    });
  }

  void _confirm() => Navigator.pop(context, _selected.toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        title: Text(
          _selected.isEmpty ? '사진 선택' : '${_selected.length}장 선택됨',
        ),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _confirm,
            child: Text(
              '추가',
              style: TextStyle(
                color: _selected.isEmpty ? Colors.white38 : Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _denied
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 64, color: Colors.white38),
                      const SizedBox(height: 16),
                      const Text('갤러리 접근 권한이 없습니다.',
                          style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => PhotoManager.openSetting(),
                        child: const Text('설정 열기'),
                      ),
                    ],
                  ),
                )
              : _assets.isEmpty
                  ? const Center(
                      child: Text('사진이 없습니다.',
                          style: TextStyle(color: Colors.white54)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(2),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: _assets.length,
                      itemBuilder: (context, index) {
                        final asset = _assets[index];
                        final isSelected = _selected.contains(asset);
                        final selIndex = isSelected
                            ? _selected.toList().indexOf(asset) + 1
                            : -1;

                        return GestureDetector(
                          onTap: () => _toggle(asset),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 썸네일
                              _AssetThumbnail(asset: asset),

                              // 선택 오버레이
                              if (isSelected)
                                Container(color: Colors.blue.withOpacity(0.35)),

                              // 선택 순서 뱃지
                              Positioned(
                                top: 6,
                                right: 6,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blueAccent
                                        : Colors.black45,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white70, width: 1.5),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Text(
                                            '$selIndex',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

/// 개별 썸네일 위젯 (비동기 로딩 + 캐시)
class _AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;
  const _AssetThumbnail({required this.asset});

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Uint8List? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.asset
        .thumbnailDataWithSize(const ThumbnailSize(300, 300));
    if (mounted) setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return Container(color: Colors.grey[800]);
    }
    return Image.memory(_data!, fit: BoxFit.cover);
  }
}
