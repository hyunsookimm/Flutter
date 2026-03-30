import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/album.dart';
import '../models/photo.dart';

class DbService {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'gallery.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE albums (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            password TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE photos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            album_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            title TEXT,
            memo TEXT,
            created_at TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE albums ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0');
          final albums = await db.query('albums', orderBy: 'id ASC');
          for (int i = 0; i < albums.length; i++) {
            await db.update(
              'albums',
              {'sort_order': i},
              where: 'id = ?',
              whereArgs: [albums[i]['id']],
            );
          }
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE photos ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0');
          final photos = await db.query('photos', orderBy: 'id ASC');
          for (int i = 0; i < photos.length; i++) {
            await db.update(
              'photos',
              {'sort_order': i},
              where: 'id = ?',
              whereArgs: [photos[i]['id']],
            );
          }
        }
      },
    );
  }

  // ─── Album CRUD ───────────────────────────────────────────────

  Future<int> insertAlbum(Album album) async {
    final database = await db;
    final result =
        await database.rawQuery('SELECT MAX(sort_order) as max_o FROM albums');
    final maxOrder = (result.first['max_o'] as int?) ?? -1;
    final map = album.toMap()
      ..remove('id')
      ..['sort_order'] = maxOrder + 1;
    return database.insert('albums', map);
  }

  Future<List<Album>> getAlbums() async {
    final database = await db;
    final rows = await database.query('albums', orderBy: 'sort_order ASC');
    return rows.map(Album.fromMap).toList();
  }

  Future<void> updateAlbumSortOrders(List<int> orderedIds) async {
    final database = await db;
    final batch = database.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'albums',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateAlbumPassword(int id, String? newPassword) async {
    final database = await db;
    await database.update(
      'albums',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAlbum(int id) async {
    final database = await db;
    await database.delete('albums', where: 'id = ?', whereArgs: [id]);
    await database.delete('photos', where: 'album_id = ?', whereArgs: [id]);
  }

  // ─── Photo CRUD ───────────────────────────────────────────────

  Future<int> insertPhoto(Photo photo) async {
    final database = await db;
    final result = await database.rawQuery(
        'SELECT MAX(sort_order) as max_o FROM photos WHERE album_id = ?',
        [photo.albumId]);
    final maxOrder = (result.first['max_o'] as int?) ?? -1;
    final map = photo.toMap()
      ..remove('id')
      ..['sort_order'] = maxOrder + 1;
    return database.insert('photos', map);
  }

  Future<List<Photo>> getPhotos(int albumId) async {
    final database = await db;
    final rows = await database.query(
      'photos',
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(Photo.fromMap).toList();
  }

  Future<void> updatePhotoSortOrders(List<int> orderedIds) async {
    final database = await db;
    final batch = database.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'photos',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updatePhotoMeta(int id, String title, String memo) async {
    final database = await db;
    await database.update(
      'photos',
      {'title': title, 'memo': memo},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePhoto(int id) async {
    final database = await db;
    await database.delete('photos', where: 'id = ?', whereArgs: [id]);
  }
}
