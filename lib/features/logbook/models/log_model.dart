import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

/// ENUM KATEGORI
@HiveType(typeId: 1)
enum LogCategory {
  @HiveField(0)
  pekerjaan,

  @HiveField(1)
  pribadi,

  @HiveField(2)
  belajar,

  @HiveField(3)
  catatanPenting,

  @HiveField(4)
  other,
}

/// Mapping nama kategori
String getCategoryName(LogCategory category) {
  switch (category) {
    case LogCategory.pekerjaan:
      return "Pekerjaan";
    case LogCategory.pribadi:
      return "Pribadi";
    case LogCategory.belajar:
      return "Belajar";
    case LogCategory.catatanPenting:
      return "Catatan Penting";
    case LogCategory.other:
      return "Other";
  }
}

/// Mapping warna kategori
final Map<LogCategory, Color> categoryColors = {
  LogCategory.pekerjaan: Colors.blue,
  LogCategory.pribadi: Colors.green,
  LogCategory.belajar: Colors.orange,
  LogCategory.catatanPenting: Colors.red,
  LogCategory.other: Colors.grey,
};

/// MODEL DATA
@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String teamId;

  @HiveField(6)
  final LogCategory category;

  // Task 5: Field status privasi (Privacy Status)
  @HiveField(7)
  final bool isPublic;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    this.category = LogCategory.other,
    this.isPublic = false, // Default: Private
  });

  /// Object -> Map (MongoDB)
  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
      'title': title,
      'description': description,
      'date': date,
      'authorId': authorId,
      'teamId': teamId,
      'category': category.name,
      'isPublic': isPublic,
    };
  }

  /// Map -> Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    ObjectId? parsedId;

    final rawId = map['_id'];

    if (rawId is ObjectId) {
      parsedId = rawId;
    } else if (rawId is Map && rawId.containsKey('\$oid')) {
      parsedId = ObjectId.fromHexString(rawId['\$oid']);
    } else if (rawId is String) {
      parsedId = ObjectId.fromHexString(rawId);
    }

    return LogModel(
      id: parsedId?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      category: LogCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => LogCategory.other,
      ),
      isPublic: map['isPublic'] ?? false,
    );
  }
}