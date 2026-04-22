import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';
import '../models/word.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: FirebaseFirestore.instance.app,
    databaseId: 'prj-prm',
  );
  final String uid;

  FirebaseFirestore get db => _db;

  FirestoreService({required this.uid});

  // --- Decks ---

  Stream<List<Deck>> streamDecks() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Deck.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<String> addDeck(String name) async {
    final docRef = await _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .add({
      'name': name,
      'created_at': FieldValue.serverTimestamp(),
      'last_studied': null,
    });
    return docRef.id;
  }

  Future<void> updateDeck(String deckId, String name) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId)
        .update({'name': name});
  }

  Future<void> deleteDeck(String deckId) async {
    // Note: In production, you might want to use a Cloud Function to delete subcollections
    // or delete words manually here. For simplicity, we'll just delete the deck.
    await _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId)
        .delete();
  }

  // --- Words ---

  Stream<List<Word>> streamWords(String deckId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId)
        .collection('words')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Word.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  Future<String> addWord(String deckId, Word word) async {
    final wordWithUid = word.copyWith(uid: uid);
    final docRef = await _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId)
        .collection('words')
        .add(wordWithUid.toFirestore());
    return docRef.id;
  }

  Future<void> updateWord(String deckId, String wordId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId)
        .collection('words')
        .doc(wordId)
        .update(data);
  }

  Future<void> deleteWord(String deckId, String wordId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId)
        .collection('words')
        .doc(wordId)
        .delete();
  }

  // --- Streak & Stats (Simplified for Cloud) ---
  
  Future<void> recordSession(String deckId, int correct, int total) async {
    final now = DateTime.now();
    final batch = _db.batch();

    final sessionRef = _db
        .collection('users')
        .doc(uid)
        .collection('study_sessions')
        .doc();
    
    batch.set(sessionRef, {
      'deck_id': deckId,
      'date': Timestamp.fromDate(now),
      'correct_count': correct,
      'total_count': total,
    });

    final deckRef = _db
        .collection('users')
        .doc(uid)
        .collection('decks')
        .doc(deckId);
    
    batch.update(deckRef, {'last_studied': Timestamp.fromDate(now)});

    await batch.commit();
  }

  Future<List<Word>> getLearnedWords() async {
    final snapshot = await _db
        .collectionGroup('words')
        .where('uid', isEqualTo: uid)
        .where('is_learned', isEqualTo: true)
        .get();
    
    return snapshot.docs
        .map((doc) => Word.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStudySessions() async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('study_sessions')
        .orderBy('date', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<Map<String, dynamic>>> streamStudySessions() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('study_sessions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
