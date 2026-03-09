import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2, // 1=ERROR, 2=INFO, 3=VERBOSE
  }) async {
    // ================= 1. CONFIG FILTER (.env) =================
    final int configLevel =
        int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;

    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (muteList
        .split(',')
        .map((e) => e.trim())
        .contains(source)) return;

    try {
      // ================= 2. TIME & LABEL =================
      final now = DateTime.now();
      final String timeStamp = DateFormat('HH:mm:ss').format(now);
      final String dateFile = DateFormat('dd-MM-yyyy').format(now);

      final String label = _getLabel(level);
      final String color = _getColor(level);

      final String formattedLog =
          '[$timeStamp][$label][$source] -> $message';

      // ================= 3. DEBUG CONSOLE =================
      dev.log(
        message,
        name: source,
        time: now,
        level: level * 100,
      );

      // ================= 4. TERMINAL OUTPUT =================
      print('$color$formattedLog\x1B[0m');

      // ================= 5. FILE LOGGING (AUDIT TRAIL) =================
      final Directory logDir = Directory('logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final File logFile = File('logs/$dateFile.log');

      await logFile.writeAsString(
        '$formattedLog\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      dev.log(
        "Logging system failure: $e",
        name: "SYSTEM",
        level: 1000,
      );
    }
  }

  // ================= LABEL =================
  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  // ================= COLOR =================
  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Red
      case 2:
        return '\x1B[32m'; // Green
      case 3:
        return '\x1B[34m'; // Blue
      default:
        return '\x1B[0m';
    }
  }
}