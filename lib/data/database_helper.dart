import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _databaseFuture;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Đảm bảo khởi tạo chỉ diễn ra một lần duy nhất (Thread-safe)
    _databaseFuture ??= _initDB('wordsprint.db');
    return await _databaseFuture!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      debugPrint('Database path: $path');

      _database = await openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
      return _database!;
    } catch (e) {
      debugPrint('Lỗi khởi tạo Database: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    await db.transaction((txn) async {
      // Tạo bảng decks (Bộ thẻ)
      await txn.execute('''
        CREATE TABLE decks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          created_at TEXT NOT NULL,
          last_studied TEXT
        )
      ''');

      // Tạo bảng words (Từ vựng)
      await txn.execute('''
        CREATE TABLE words (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          deck_id INTEGER NOT NULL,
          front TEXT NOT NULL,
          back TEXT NOT NULL,
          example TEXT,
          is_learned INTEGER DEFAULT 0,
          FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
        )
      ''');

      // Tạo bảng study_sessions (Phiên học)
      await txn.execute('''
        CREATE TABLE study_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          deck_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          correct_count INTEGER NOT NULL,
          total_count INTEGER NOT NULL,
          FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
        )
      ''');

      // Thêm dữ liệu mẫu sau khi tạo bảng
      await _insertSampleDataInTxn(txn);

      // Thêm các chỉ mục (Indexes) để tăng tốc độ truy vấn
      await txn.execute('CREATE INDEX idx_words_deck_id ON words (deck_id)');
      await txn.execute('CREATE INDEX idx_study_sessions_date ON study_sessions (date)');
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Nâng cấp từ v1 lên v2: thêm các chỉ mục
      await db.execute('CREATE INDEX idx_words_deck_id ON words (deck_id)');
      await db.execute('CREATE INDEX idx_study_sessions_date ON study_sessions (date)');
      debugPrint('Database đã được nâng cấp lên phiên bản 2 (Thêm Index)');
    }
  }

  Future<void> _insertSampleDataInTxn(Transaction txn) async {
    final now = DateTime.now().toIso8601String();

    // 1. Thêm Deck: IELTS Cơ bản
    final ieltsDeckId = await txn.insert('decks', {
      'name': 'IELTS Cơ bản',
      'created_at': now,
    });

    List<Map<String, dynamic>> ieltsWords = [
      {'front': 'Abandon', 'back': 'Từ bỏ, ruồng bỏ', 'example': 'He decided to abandon his search.'},
      {'front': 'Acquire', 'back': 'Đạt được, giành được', 'example': 'I managed to acquire all the books I needed.'},
      {'front': 'Beneficial', 'back': 'Có lợi, ích lợi', 'example': 'A stay in the country will be beneficial to his health.'},
      {'front': 'Capability', 'back': 'Khả năng, năng lực', 'example': 'She has the capability to become a great leader.'},
      {'front': 'Distinguish', 'back': 'Phân biệt', 'example': 'It is hard to distinguish between the two models.'},
      {'front': 'Enormous', 'back': 'To lớn, khổng lồ', 'example': 'The task will require an enormous amount of work.'},
      {'front': 'Fundamental', 'back': 'Cơ bản, chủ yếu', 'example': 'Hard work is fundamental to success.'},
      {'front': 'Guarantee', 'back': 'Bảo hành, cam đoan', 'example': 'We cannot guarantee that our flights will be on time.'},
      {'front': 'Hypothesis', 'back': 'Giả thuyết', 'example': 'Technically, it\'s just a hypothesis.'},
      {'front': 'Inevitable', 'back': 'Không thể tránh khỏi', 'example': 'It was inevitable that there would be job losses.'},
    ];

    for (var word in ieltsWords) {
      word['deck_id'] = ieltsDeckId;
      await txn.insert('words', word);
    }

    // 2. Thêm Deck: Giao tiếp hằng ngày
    final dailyDeckId = await txn.insert('decks', {
      'name': 'Giao tiếp hằng ngày',
      'created_at': now,
    });

    List<Map<String, dynamic>> dailyWords = [
      {'front': 'Greeting', 'back': 'Lời chào hỏi', 'example': 'They exchanged friendly greetings.'},
      {'front': 'Appointment', 'back': 'Cuộc hẹn', 'example': 'I have a dentist appointment at 3 PM.'},
      {'front': 'Complaint', 'back': 'Lời phàn nàn', 'example': 'He made a complaint about the service.'},
      {'front': 'Direction', 'back': 'Hướng đi, chỉ dẫn', 'example': 'Can you give me directions to the station?'},
      {'front': 'Experience', 'back': 'Kinh nghiệm, trải nghiệm', 'example': 'Do you have any experience with children?'},
      {'front': 'Frequent', 'back': 'Thường xuyên', 'example': 'He is a frequent visitor to the US.'},
      {'front': 'Grocery', 'back': 'Hàng tạp hóa', 'example': 'I need to go buy some groceries.'},
      {'front': 'Invitation', 'back': 'Lời mời', 'example': 'Thank you for the invitation to dinner.'},
      {'front': 'Journal', 'back': 'Nhật ký, tạp chí', 'example': 'She kept a journal of her travels.'},
      {'front': 'Knowledge', 'back': 'Kiến thức, hiểu biết', 'example': 'He has a wide knowledge of history.'},
    ];

    for (var word in dailyWords) {
      word['deck_id'] = dailyDeckId;
      await txn.insert('words', word);
    }
    
    debugPrint('Dữ liệu mẫu đã được thêm thành công!');
  }

  // --- Các hàm hỗ trợ query dữ liệu (Thêm vào để dùng sau) ---

  Future<List<Map<String, dynamic>>> getDecks() async {
    final db = await instance.database;
    return await db.query('decks', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getWordsByDeck(int deckId) async {
    final db = await instance.database;
    return await db.query('words', where: 'deck_id = ?', whereArgs: [deckId]);
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
