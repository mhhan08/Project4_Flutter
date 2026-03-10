import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:hive/hive.dart';
import 'models/log_model.dart';
import '../../services/mongo_service.dart';
import '../../helpers/log_helper.dart';
import '../../services/access_control_service.dart';

class LogController {

  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  final ValueNotifier<List<LogModel>> filteredLogs =
      ValueNotifier<List<LogModel>>([]);

  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  final ValueNotifier<LogCategory?> selectedCategoryFilter =
      ValueNotifier(null);

  String _lastSearchQuery = "";

  late Box<LogModel> _myBox;

  late String userRole;
  late String userId;

  Future<void> init(String role, String uid) async {
    userRole = role;
    userId = uid;

    _myBox = await Hive.openBox<LogModel>('log_cache');
  }

  void searchLog(String query) {
    _lastSearchQuery = query;
    _applyFilters();
  }

  void filterByCategory(LogCategory? category) {
    selectedCategoryFilter.value = category;
    _applyFilters();
  }

  void _applyFilters() {
    List<LogModel> result = logsNotifier.value;

    // Filter Visibilitas
    result = result.where((log) => log.authorId == userId || log.isPublic).toList();

    if (_lastSearchQuery.isNotEmpty) {
      result = result
          .where((log) => log.title
              .toLowerCase()
              .contains(_lastSearchQuery.toLowerCase()))
          .toList();
    }

    if (selectedCategoryFilter.value != null) {
      result = result
          .where((log) => log.category == selectedCategoryFilter.value)
          .toList();
    }

    filteredLogs.value = result;
  }

  Future<void> loadLogs(String teamId) async {
    isLoading.value = true;

    try {
      logsNotifier.value = _myBox.values.toList();
      _applyFilters();

      final cloudData = await MongoService().getLogs(teamId);

      await _myBox.clear();
      await _myBox.addAll(cloudData);

      logsNotifier.value = cloudData;
      _applyFilters();

      await LogHelper.writeLog(
        "SYNC: Data retrieved from Atlas",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Using local cache data",
        level: 2,
      );
    }

    isLoading.value = false;
  }

  Future<void> addLog(
    String title,
    String desc,
    LogCategory category,
    String authorId,
    String teamId,
    bool isPublic, 
  ) async {
    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
      authorId: authorId,
      teamId: teamId,
      isPublic: isPublic, 
    );

    await _myBox.add(newLog);

    logsNotifier.value = [...logsNotifier.value, newLog];
    _applyFilters();

    try {
      await MongoService().insertLog(newLog);

      await LogHelper.writeLog(
        "SUCCESS: Data synced to cloud",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data saved locally, will sync when online",
        level: 1,
      );
    }
  }

  Future<void> editLog(
    LogModel oldLog,
    String title,
    String desc,
    LogCategory category,
    bool isPublic, 
  ) async {
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      category: category,
      date: oldLog.date,
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      isPublic: isPublic, 
    );

    final list = List<LogModel>.from(logsNotifier.value);
    final index =
        list.indexWhere((e) => e.id == oldLog.id);

    if (index != -1) {
      list[index] = updatedLog;
      logsNotifier.value = list;
      _applyFilters();

      await _myBox.putAt(index, updatedLog);
    }

    try {
      await MongoService().updateLog(updatedLog);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Edit only saved locally",
        level: 1,
      );
    }
  }

  Future<void> removeLog(int index) async {

    final target = logsNotifier.value[index];

    if (!AccessControlService.canPerform(
        userRole,
        AccessControlService.actionDelete,
        isOwner: target.authorId == userId)) {

      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt",
        level: 1,
      );

      return;
    }

    await _myBox.deleteAt(index);

    final list = List<LogModel>.from(logsNotifier.value);
    list.removeAt(index);

    logsNotifier.value = list;
    _applyFilters();

    try {
      if (target.id != null) {
        await MongoService().deleteLog(target.id!);
      }
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Failed to delete in cloud",
        level: 1,
      );
    }
  }

  Future<void> syncPendingLogs(String teamId) async {
    final localLogs = _myBox.values.toList();

    for (var log in localLogs) {
      try {
        await MongoService().updateLog(log);
      } catch (e) {
        await LogHelper.writeLog(
          "SYNC ERROR: Gagal sinkronisasi data ${log.title}",
          level: 1,
        );
      }
    }

    await loadLogs(teamId);
  }
}