import 'dart:io';
import 'package:path_provider/path_provider.dart';

const _separator = '---DIARY---';

class DiaryEntry {
  final String path;
  final String date;
  final String time;
  final String title;

  const DiaryEntry({
    required this.path,
    required this.date,
    required this.time,
    required this.title,
  });
}

class FileService {
  Future<String> getDirPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  String _serialize(String title, String content) =>
      '$title\n$_separator\n$content';

  String parseTitleFromRaw(String raw) {
    final idx = raw.indexOf('\n$_separator\n');
    if (idx == -1) return '';
    return raw.substring(0, idx);
  }

  String parseContentFromRaw(String raw) {
    final sep = '\n$_separator\n';
    final idx = raw.indexOf(sep);
    if (idx == -1) return raw;
    return raw.substring(idx + sep.length);
  }

  Future<void> saveDiaryForDate(
      String date, String title, String content) async {
    final dirPath = await getDirPath();
    final now = DateTime.now();
    final t = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final file = File('$dirPath/${date}_$t.txt');
    await file.writeAsString(_serialize(title, content));
  }

  Future<void> saveDiaryToPath(
      String path, String title, String content) async {
    await File(path).writeAsString(_serialize(title, content));
  }

  /// 날짜를 변경할 때: 기존 파일 삭제 후 새 날짜로 파일 생성. 새 경로 반환.
  Future<String> changeDiaryDate(
      String oldPath, String newDate, String title, String content) async {
    final dirPath = await getDirPath();
    // 기존 파일명에서 시간 부분 추출 (HHmmss)
    final name =
        oldPath.split(Platform.pathSeparator).last.replaceAll('.txt', '');
    final timePart = name.contains('_') ? name.split('_').last : '';
    final newPath = '$dirPath/${newDate}_$timePart.txt';
    await File(newPath).writeAsString(_serialize(title, content));
    await File(oldPath).delete();
    return newPath;
  }

  Future<List<DiaryEntry>> getDiaryEntries() async {
    final dirPath = await getDirPath();
    final dir = Directory(dirPath);
    final all = dir.listSync();
    final txts = all.where((e) => e.path.endsWith('.txt')).toList();
    txts.sort((a, b) => b.path.compareTo(a.path));

    final entries = <DiaryEntry>[];
    for (final f in txts) {
      String title = '';
      try {
        final raw = await File(f.path).readAsString();
        title = parseTitleFromRaw(raw);
      } catch (_) {}
      entries.add(DiaryEntry(
        path: f.path,
        date: getDateFromPath(f.path),
        time: getTimeFromPath(f.path),
        title: title,
      ));
    }
    return entries;
  }

  Future<String> readDiaryRaw(String path) async =>
      File(path).readAsString();

  Future<void> deleteDiary(String path) async => File(path).delete();

  Future<void> deleteMultiple(List<String> paths) async {
    for (final p in paths) {
      await deleteDiary(p);
    }
  }

  String getDateFromPath(String path) {
    final name =
        path.split(Platform.pathSeparator).last.replaceAll('.txt', '');
    return name.contains('_') ? name.split('_').first : name;
  }

  String getTimeFromPath(String path) {
    final name =
        path.split(Platform.pathSeparator).last.replaceAll('.txt', '');
    if (!name.contains('_')) return '';
    final t = name.split('_').last;
    if (t.length < 6) return '';
    return '${t.substring(0, 2)}:${t.substring(2, 4)}:${t.substring(4, 6)}';
  }

  Future<List<DiaryEntry>> searchEntries(String query) async {
    if (query.trim().isEmpty) return getDiaryEntries();
    final all = await getDiaryEntries();
    final q = query.toLowerCase();
    final result = <DiaryEntry>[];
    for (final entry in all) {
      if (entry.date.contains(q) ||
          entry.title.toLowerCase().contains(q)) {
        result.add(entry);
        continue;
      }
      try {
        final raw = await readDiaryRaw(entry.path);
        final body = parseContentFromRaw(raw);
        if (body.toLowerCase().contains(q)) {
          result.add(entry);
        }
      } catch (_) {}
    }
    return result;
  }
}
