import 'package:cloud_firestore/cloud_firestore.dart';

class Word {
  final String? id;
  final String deckId;
  final String front;
  final String back;
  final String? example;
  final bool isLearned;
  final DateTime? learnedAt;

  Word({
    this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.example,
    this.isLearned = false,
    this.learnedAt,
  });

  // Chuyển đổi từ Map sang Object
  factory Word.fromMap(Map<String, dynamic> map, {String? id}) {
    return Word(
      id: id ?? map['id']?.toString(),
      deckId: map['deck_id']?.toString() ?? '',
      front: map['front'] ?? '',
      back: map['back'] ?? '',
      example: map['example'],
      isLearned: map['is_learned'] == 1 || (map['is_learned'] is bool && map['is_learned'] == true),
      learnedAt: map['learned_at'] != null 
          ? (map['learned_at'] is Timestamp 
              ? (map['learned_at'] as Timestamp).toDate() 
              : DateTime.parse(map['learned_at']))
          : null,
    );
  }

  // Chuyển đổi từ Object sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'front': front,
      'back': back,
      'example': example,
      'is_learned': isLearned ? 1 : 0,
      'learned_at': learnedAt?.toIso8601String(),
    };
  }

  // Chuyển đổi dành riêng cho Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'deck_id': deckId,
      'front': front,
      'back': back,
      'example': example,
      'is_learned': isLearned,
      'learned_at': learnedAt != null ? Timestamp.fromDate(learnedAt!) : null,
    };
  }

  // Tạo bản sao của word với các thuộc tính thay đổi
  Word copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    String? example,
    bool? isLearned,
    DateTime? learnedAt,
  }) {
    return Word(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      example: example ?? this.example,
      isLearned: isLearned ?? this.isLearned,
      learnedAt: learnedAt ?? this.learnedAt,
    );
  }
}
