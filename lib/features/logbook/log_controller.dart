import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<LogCategory?> selectedCategoryFilter = ValueNotifier(null);

  static const String _storageKey = 'user_logs_cache';
  String _lastSearchQuery = "";

  LogController() {
    loadFromDisk();
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

    if (_lastSearchQuery.isNotEmpty) {
      result = result.where((log) => log.title.toLowerCase().contains(_lastSearchQuery.toLowerCase())).toList();
    }

    if (selectedCategoryFilter.value != null) {
      result = result.where((log) => log.category == selectedCategoryFilter.value).toList();
    }

    filteredLogs.value = result;
  }

  Future<void> loadFromDisk() async {
    isLoading.value = true;
    try {
      final cloudData = await MongoService().getLogs();
      logsNotifier.value = cloudData;
      _applyFilters();
      await saveToCache();
      
      await LogHelper.writeLog(
        "INFO: Cloud data loaded successfully",
        source: "log_controller",
        level: 3,
      );
    } catch (e) {
      print("Error loading data: $e");
      await _loadFromCache();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addLog(String title, String desc, LogCategory category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      category: category,
      date: DateTime.now().toIso8601String(),
    );

    try {
      await MongoService().insertLog(newLog);
      logsNotifier.value = [...logsNotifier.value, newLog];
      _applyFilters();
      await saveToCache();
    } catch (e) {
      print("Error adding log: $e");
    }
  }

  Future<void> editLog(LogModel oldLog, String title, String desc, LogCategory category) async {
    if (oldLog.id == null) return;

    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      category: category,
      date: oldLog.date,
    );

    try {
      await MongoService().updateLog(updatedLog);

      final list = List<LogModel>.from(logsNotifier.value);
      final index = list.indexWhere((e) => e.id?.toHexString() == oldLog.id?.toHexString());
      
      if (index != -1) {
        list[index] = updatedLog;
        logsNotifier.value = list;
        _applyFilters();
        await saveToCache();
      }
    } catch (e) {
      print("Error updating log: $e");
    }
  }

  Future<void> removeLog(LogModel log) async {
    if (log.id == null) return;

    final oldLogs = List<LogModel>.from(logsNotifier.value);

    logsNotifier.value = logsNotifier.value
        .where((e) => e.id?.toHexString() != log.id?.toHexString())
        .toList();
    _applyFilters();

    try {
      await MongoService().deleteLog(log.id!);
      await saveToCache();
    } catch (e) {
      print("Error removing log, rolling back state: $e");
      logsNotifier.value = oldLogs;
      _applyFilters();
    }
  }

  Future<void> saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      final cachedLogs = decoded.map((e) => LogModel.fromMap(e)).toList();
      logsNotifier.value = cachedLogs;
      _applyFilters();
    }
  }
}