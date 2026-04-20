import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/deck.dart';
import '../models/word.dart';

class DeckProvider with ChangeNotifier {
  List<Deck> _decks = [];
  List<Word> _currentWords = [];
  int _currentStreak = 0;
  bool _isInitialLoading = true;

  List<Deck> get decks => _decks;
  List<Word> get currentWords => _currentWords;
  int get currentStreak => _currentStreak;
  bool get isInitialLoading => _isInitialLoading;

  // Tải danh sách bộ thẻ từ database
  Future<void> fetchDecks() async {
    final data = await DatabaseHelper.instance.getDecks();
    _decks = data.map((item) => Deck.fromMap(item)).toList();
    _isInitialLoading = false;
    notifyListeners();
  }

  // Tải danh sách từ vựng theo ID bộ thẻ
  Future<void> fetchWords(int deckId) async {
    final data = await DatabaseHelper.instance.getWordsByDeck(deckId);
    _currentWords = data.map((item) => Word.fromMap(item)).toList();
    notifyListeners();
  }

  // Thêm bộ thẻ mới
  Future<void> addDeck(String name) async {
    try {
      final newDeck = Deck(name: name, createdAt: DateTime.now());

      // Tối ưu: Thêm vào list cục bộ ngay lập tức để UI cập nhật
      _decks.insert(0, newDeck);
      notifyListeners();

      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('decks', newDeck.toMap());

      // Cập nhật lại ID thực sau khi insert thành công
      final index = _decks.indexOf(newDeck);
      if (index != -1) {
        _decks[index] = newDeck.copyWith(id: id);
      }
      debugPrint('Đã thêm bộ thẻ: $name (ID: $id)');
    } catch (e) {
      debugPrint('Lỗi khi thêm bộ thẻ: $e');
      await fetchDecks(); // Nếu lỗi thì fetch lại bản chuẩn từ DB
    }
  }

  // Thêm từ vựng mới vào bộ thẻ
  Future<void> addWord(
    int deckId,
    String front,
    String back,
    String? example,
  ) async {
    try {
      final newWord = Word(
        deckId: deckId,
        front: front,
        back: back,
        example: example,
      );

      // Tối ưu: Thêm vào list từ hiện tại
      _currentWords.add(newWord);
      notifyListeners();

      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('words', newWord.toMap());

      // Cập nhật ID thực
      final index = _currentWords.indexOf(newWord);
      if (index != -1) {
        _currentWords[index] = newWord.copyWith(id: id);
      }
    } catch (e) {
      debugPrint('Lỗi khi thêm từ: $e');
      await fetchWords(deckId);
    }
  }

  // Cập nhật trạng thái "Đã thuộc" của từ vựng
  Future<void> toggleWordLearned(Word word) async {
    final updatedWord = word.copyWith(isLearned: !word.isLearned);

    // Cập nhật UI trước (Optimistic)
    final index = _currentWords.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _currentWords[index] = updatedWord;
      notifyListeners();
    }

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'words',
        updatedWord.toMap(),
        where: 'id = ?',
        whereArgs: [word.id],
      );
    } catch (e) {
      debugPrint('Lỗi khi update từ: $e');
      await fetchWords(word.deckId); // Revert nếu lỗi
    }
  }

  // Ghi lại phiên học tập và cập nhật last_studied của deck
  Future<void> recordStudySession(int deckId, int correct, int total) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().toIso8601String();

      // Thực hiện các thao tác Database trong một batch hoặc song song
      await Future.wait([
        db.insert('study_sessions', {
          'deck_id': deckId,
          'date': now,
          'correct_count': correct,
          'total_count': total,
        }),
        db.update(
          'decks',
          {'last_studied': now},
          where: 'id = ?',
          whereArgs: [deckId],
        ),
      ]);

      // Thay vì gọi fetchDecks() tốn kém, ta chỉ cập nhật deck bị thay đổi
      final deckIndex = _decks.indexWhere((d) => d.id == deckId);
      if (deckIndex != -1) {
        _decks[deckIndex] = _decks[deckIndex].copyWith(
          lastStudied: DateTime.parse(now),
        );
        // Đưa deck vừa học lên đầu danh sách (tùy chọn UI)
        final movedDeck = _decks.removeAt(deckIndex);
        _decks.insert(0, movedDeck);
        notifyListeners();
      }

      await calculateStreak();
    } catch (e) {
      debugPrint('Lỗi record session: $e');
      await fetchDecks();
    }
  }

  // Lấy tất cả phiên học của một bộ thẻ
  Future<List<Map<String, dynamic>>> getAllStudySessions(int deckId) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final sessions = await db.query(
        'study_sessions',
        where: 'deck_id = ?',
        whereArgs: [deckId],
        orderBy: 'date ASC',
      );

      return sessions;
    } catch (e) {
      debugPrint('Lỗi lấy study sessions: $e');
      return [];
    }
  }

  // Tính toán chuỗi ngày học (Streak)
  Future<void> calculateStreak() async {
    final db = await DatabaseHelper.instance.database;
    // Lấy tất cả các ngày duy nhất có session học, sắp xếp giảm dần
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT DISTINCT date(date) as study_date 
      FROM study_sessions 
      ORDER BY study_date DESC
    ''');

    if (results.isEmpty) {
      _currentStreak = 0;
      notifyListeners();
      return;
    }

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    for (var row in results) {
      DateTime studyDate = DateTime.parse(row['study_date']);
      // Nếu là hôm nay hoặc hôm qua so với checkDate (để nối chuỗi)
      if (studyDate == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (studyDate.isBefore(checkDate)) {
        // Nếu cách ngày thì dừng streak
        break;
      }
    }

    _currentStreak = streak;
    notifyListeners();
  }
}
