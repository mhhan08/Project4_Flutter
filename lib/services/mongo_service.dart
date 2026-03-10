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

  // INTERNAL SAFETY
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Collection not ready, attempting reconnection...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }

  // CONNECT
  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) {
        throw Exception("MONGODB_URI not found in .env");
      }

      _db = await Db.create(dbUri);
      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception("Connection Timeout. Check IP Whitelist and network.");
        },
      );

      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Connected to MongoDB Atlas",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Connection failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // READ
  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId",
        source: _source,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId))
          .toList();

      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  // CREATE
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection.insertOne(log.toMap());

      await LogHelper.writeLog(
        "DATABASE: '${log.title}' successfully saved",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Insert failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // UPDATE
  Future<void> updateLog(LogModel log) async {
    try {
      if (log.id == null) {
        throw Exception("Log ID not found for update");
      }

      final collection = await _getSafeCollection();
      final objectId = ObjectId.fromHexString(log.id!);

      await collection.replaceOne(
        where.eq('_id', objectId),
        log.toMap(),
        upsert: true,
      );

      await LogHelper.writeLog(
        "DATABASE: Update/Upsert '${log.title}' successful",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Update failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // DELETE
  Future<void> deleteLog(String id) async {
    try {
      final collection = await _getSafeCollection();
      final objectId = ObjectId.fromHexString(id);

      await collection.remove(where.eq('_id', objectId));

      await LogHelper.writeLog(
        "DATABASE: Delete log ID $id successful",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Delete failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // CLOSE
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();

      await LogHelper.writeLog(
        "DATABASE: Connection closed",
        source: _source,
        level: 2,
      );
    }
  }
}