import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

// Enum untuk Kategori
enum LogCategory { pekerjaan, pribadi, belajar, catatanPenting, other }

// Mapping Kategori ke Nama String yang rapi
String getCategoryName(LogCategory category) {
  switch (category) {
    case LogCategory.pekerjaan: return "Pekerjaan";
    case LogCategory.pribadi: return "Pribadi";
    case LogCategory.belajar: return "Belajar";
    case LogCategory.catatanPenting: return "Catatan Penting";
    case LogCategory.other: return "Other";
  }
}

// Mapping Kategori ke Warna Kartu
final Map<LogCategory, Color> categoryColors = {
  LogCategory.pekerjaan: Colors.blue.shade100,
  LogCategory.pribadi: Colors.green.shade100,
  LogCategory.belajar: Colors.orange.shade100,
  LogCategory.catatanPenting: Colors.red.shade100,
  LogCategory.other: Colors.grey.shade100,
};

// Model Data Catatan
class LogModel {
  final ObjectId? id; 
  final String title;
  final String description;
  final String date;
  final LogCategory category;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
  });


  // Konversi dari Object ke JSON (Map)
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), 
      'title': title,
      'date': date,
      'description': description,
      'category': category.toString(), // Simpan enum sebagai string
    };
  }

    // Konversi dari JSON (Map) ke Object
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
    id: parsedId,
    title: map['title'],
    date: map['date'],
    description: map['description'],
    category: LogCategory.values.firstWhere(
      (e) => e.toString() == map['category'],
      orElse: () => LogCategory.other,
    ),
  );
}
}