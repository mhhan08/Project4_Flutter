import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../features/logbook/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();

  Db? _db;
  DbCollection? _collection;

  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  /// ================= INTERNAL SAFETY =================
  /// Menjamin koleksi selalu siap sebelum CRUD
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3, // VERBOSE
      );
      await connect();
    }
    return _collection!;
  }

  /// ================= CONNECT =================
  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) {
        throw Exception("MONGODB_URI tidak ditemukan di .env");
      }

      _db = await Db.create(dbUri);

      // Timeout toleran jaringan mobile
      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            "Koneksi Timeout. Pastikan IP Whitelist (0.0.0.0/0) & jaringan stabil.",
          );
        },
      );

      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Terhubung ke MongoDB Atlas",
        source: _source,
        level: 2, // INFO
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal koneksi - $e",
        source: _source,
        level: 1, // ERROR
      );
      rethrow;
    }
  }

  /// ================= READ =================
  Future<List<LogModel>> getLogs() async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "DATABASE: Mengambil data dari Cloud",
        source: _source,
        level: 3, // VERBOSE
      );

      final data = await collection.find().toList();
      return data.map((e) => LogModel.fromMap(e)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Fetch gagal - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  /// ================= CREATE =================
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection.insertOne(log.toMap());

      await LogHelper.writeLog(
        "DATABASE: '${log.title}' berhasil disimpan",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Insert gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// ================= UPDATE =================
  Future<void> updateLog(LogModel log) async {
    try {
      if (log.id == null) {
        throw Exception("ID log tidak ditemukan untuk update");
      }

      final collection = await _getSafeCollection();
      await collection.replaceOne(
        where.id(log.id!),
        log.toMap(),
      );

      await LogHelper.writeLog(
        "DATABASE: Update '${log.title}' berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Update gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// ================= DELETE =================
  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));

      await LogHelper.writeLog(
        "DATABASE: Hapus log ID $id berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Hapus gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// ================= CLOSE =================
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }
}