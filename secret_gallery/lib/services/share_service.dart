import 'package:share_plus/share_plus.dart';

class ShareService {
  /// 이미지 파일 경로를 받아 공유 시트를 띄운다 (카카오톡 포함).
  Future<void> sharePhoto(String imagePath) async {
    await Share.shareXFiles([XFile(imagePath)]);
  }
}
