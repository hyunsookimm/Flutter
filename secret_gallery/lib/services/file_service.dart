import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileService {
  Future<String> _getImageDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${dir.path}/images');

    if (!imageDir.existsSync()) {
      imageDir.createSync();
    }

    return imageDir.path;
  }

  /// 갤러리에서 선택된 임시 파일을 앱 내부 저장소로 복사하고 경로를 반환한다.
  Future<String> saveImage(String sourcePath) async {
    final dir = await _getImageDir();
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final newPath = '$dir/$fileName.png';

    await File(sourcePath).copy(newPath);

    return newPath;
  }

  /// 앱 내부 저장소에서 이미지 파일을 삭제한다.
  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
