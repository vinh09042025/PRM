import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String? id;
  final String name;
  final DateTime createdAt;
  final DateTime? lastStudied;

  Deck({
    this.id,
    required this.name,
    required this.createdAt,
    this.lastStudied,
  });

  // Chuyển đổi từ Map (SQLite/Firestore) sang Object
  factory Deck.fromMap(Map<String, dynamic> map, {String? id}) {
    return Deck(
      id: id ?? map['id']?.toString(),
      name: map['name'] ?? '',
      createdAt: map['created_at'] != null 
          ? (map['created_at'] is Timestamp 
              ? (map['created_at'] as Timestamp).toDate() 
              : DateTime.parse(map['created_at']))
          : DateTime.now(),
      lastStudied: map['last_studied'] != null 
          ? (map['last_studied'] is Timestamp 
              ? (map['last_studied'] as Timestamp).toDate() 
              : DateTime.parse(map['last_studied']))
          : null,
    );
  }

  // Chuyển đổi từ Object sang Map để lưu vào SQLite/Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'last_studied': lastStudied?.toIso8601String(),
    };
  }

  // Chuyển đổi dành riêng cho Firestore (dùng Timestamp)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'created_at': Timestamp.fromDate(createdAt),
      'last_studied': lastStudied != null ? Timestamp.fromDate(lastStudied!) : null,
    };
  }

  // Tạo bản sao với các thuộc tính thay đổi
  Deck copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastStudied,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastStudied: lastStudied ?? this.lastStudied,
    );
  }
}
