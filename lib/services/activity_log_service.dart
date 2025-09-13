import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log.dart';
import '../config/supabase_config.dart';

class ActivityLogService {
  static const String _boxName = 'activity_logs';
  static const String _supabaseTable = 'activity_logs';
  
  static final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Get Hive box for local storage (using Map for consistency)
  static Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  // Add activity log
  static Future<void> addActivityLog(ActivityLog log) async {
    try {
      // Save to Hive first (for offline support) as Map
      final box = await _getBox();
      await box.put(log.id, log.toJson());

      // Try to save to Supabase
      try {
        await _supabase.from(_supabaseTable).insert(log.toJson());
      } catch (supabaseError) {
        print('Failed to sync activity log to Supabase: $supabaseError');
        // Mark for later sync
        await _markForSync(log.id);
      }
    } catch (e) {
      print('Error adding activity log: $e');
      rethrow;
    }
  }

  // Get recent activity logs (limit to last 100)
  static Future<List<ActivityLog>> getRecentActivityLogs({
    String? farmId,
    int limit = 100,
  }) async {
    try {
      final box = await _getBox();
      var logMaps = box.values.toList();
      
      // Convert Maps to ActivityLog objects
      var logs = <ActivityLog>[];
      for (final logMap in logMaps) {
        try {
          if (logMap is Map) {
            final safeLogMap = _sanitizeActivityLogData(Map<String, dynamic>.from(logMap));
            final activityLog = ActivityLog.fromJson(safeLogMap);
            logs.add(activityLog);
          }
        } catch (e) {
          print('Failed to parse activity log: $e');
          continue;
        }
      }

      // Filter by farm ID if provided
      if (farmId != null) {
        logs = logs.where((log) => log.farmId == farmId).toList();
      }

      // Sort by creation date (newest first)
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Limit results
      return logs.take(limit).toList();
    } catch (e) {
      print('Error getting activity logs: $e');
      return [];
    }
  }

  // Get activity logs by type
  static Future<List<ActivityLog>> getActivityLogsByType(
    String farmId,
    ActivityType type, {
    int limit = 50,
  }) async {
    try {
      final box = await _getBox();
      var logs = <ActivityLog>[];
      
      for (final logMap in box.values) {
        try {
          if (logMap is Map) {
            final safeLogMap = _sanitizeActivityLogData(Map<String, dynamic>.from(logMap));
            final activityLog = ActivityLog.fromJson(safeLogMap);
            if (activityLog.farmId == farmId && activityLog.type == type) {
              logs.add(activityLog);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Sort by creation date (newest first)
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return logs.take(limit).toList();
    } catch (e) {
      print('Error getting activity logs by type: $e');
      return [];
    }
  }

  // Get activity logs for today
  static Future<List<ActivityLog>> getTodayActivityLogs(String farmId) async {
    try {
      final box = await _getBox();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      var logs = <ActivityLog>[];
      for (final logMap in box.values) {
        try {
          if (logMap is Map) {
            final log = ActivityLog.fromJson(Map<String, dynamic>.from(logMap));
            if (log.farmId == farmId &&
                log.createdAt.isAfter(startOfDay) &&
                log.createdAt.isBefore(endOfDay)) {
              logs.add(log);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Sort by creation date (newest first)
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return logs;
    } catch (e) {
      print('Error getting today\'s activity logs: $e');
      return [];
    }
  }

  // Get activity logs by date range
  static Future<List<ActivityLog>> getActivityLogsByDateRange(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final box = await _getBox();
      var logs = <ActivityLog>[];
      
      for (final logMap in box.values) {
        try {
          if (logMap is Map) {
            final log = ActivityLog.fromJson(Map<String, dynamic>.from(logMap));
            if (log.farmId == farmId &&
                log.createdAt.isAfter(startDate) &&
                log.createdAt.isBefore(endDate)) {
              logs.add(log);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Sort by creation date (newest first)
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return logs;
    } catch (e) {
      print('Error getting activity logs by date range: $e');
      return [];
    }
  }

  // Clear old logs (keep last 1000)
  static Future<void> clearOldLogs({int keepCount = 1000}) async {
    try {
      final box = await _getBox();
      if (box.length <= keepCount) return;

      var logs = <ActivityLog>[];
      for (final logMap in box.values) {
        try {
          if (logMap is Map) {
            final log = ActivityLog.fromJson(Map<String, dynamic>.from(logMap));
            logs.add(log);
          }
        } catch (e) {
          continue;
        }
      }
      
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Keep only the latest logs
      final logsToKeep = logs.take(keepCount).toList();
      final keysToKeep = logsToKeep.map((log) => log.id).toSet();

      // Delete old logs
      final keysToDelete = box.keys.where((key) => !keysToKeep.contains(key));
      for (final key in keysToDelete) {
        await box.delete(key);
      }

      print('Cleared ${keysToDelete.length} old activity logs');
    } catch (e) {
      print('Error clearing old logs: $e');
    }
  }

  // Sync pending logs to Supabase
  static Future<void> syncPendingLogs() async {
    try {
      final pendingIds = await _getPendingSyncIds();
      if (pendingIds.isEmpty) return;

      final box = await _getBox();
      for (final id in pendingIds) {
        final logMap = box.get(id);
        if (logMap != null && logMap is Map) {
          try {
            // logMap is already in JSON format, so we can use it directly
            final logData = Map<String, dynamic>.from(logMap);
            await _supabase.from(_supabaseTable).insert(logData);
            await _removeSyncMarker(id);
          } catch (e) {
            print('Failed to sync log $id: $e');
          }
        }
      }
    } catch (e) {
      print('Error syncing pending logs: $e');
    }
  }

  // Load logs from Supabase
  static Future<void> loadFromSupabase(String farmId) async {
    try {
      final response = await _supabase
          .from(_supabaseTable)
          .select()
          .eq('farm_id', farmId)
          .order('created_at', ascending: false)
          .limit(500);

      final box = await _getBox();
      for (final logData in response) {
        final log = ActivityLog.fromJson(logData);
        await box.put(log.id, log.toJson()); // Store as Map
      }

      print('Loaded ${response.length} activity logs from Supabase');
    } catch (e) {
      print('Error loading logs from Supabase: $e');
    }
  }

  // Mark log for sync
  static Future<void> _markForSync(String logId) async {
    try {
      final box = await Hive.openBox('sync_pending');
      await box.put('activity_log_$logId', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error marking log for sync: $e');
    }
  }

  // Remove sync marker
  static Future<void> _removeSyncMarker(String logId) async {
    try {
      final box = await Hive.openBox('sync_pending');
      await box.delete('activity_log_$logId');
    } catch (e) {
      print('Error removing sync marker: $e');
    }
  }

  // Get pending sync IDs
  static Future<List<String>> _getPendingSyncIds() async {
    try {
      final box = await Hive.openBox('sync_pending');
      return box.keys
          .where((key) => key.toString().startsWith('activity_log_'))
          .map((key) => key.toString().replaceFirst('activity_log_', ''))
          .toList();
    } catch (e) {
      print('Error getting pending sync IDs: $e');
      return [];
    }
  }

  // Get statistics
  static Future<Map<ActivityType, int>> getActivityStatistics(
    String farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final box = await _getBox();
      var logs = <ActivityLog>[];
      
      // Convert Maps to ActivityLog objects and filter
      for (final logMap in box.values) {
        try {
          if (logMap is Map) {
            final log = ActivityLog.fromJson(Map<String, dynamic>.from(logMap));
            if (log.farmId == farmId) {
              // Filter by date range if provided
              if (startDate != null && endDate != null) {
                if (log.createdAt.isAfter(startDate) && log.createdAt.isBefore(endDate)) {
                  logs.add(log);
                }
              } else {
                logs.add(log);
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Count by activity type
      final Map<ActivityType, int> statistics = {};
      for (final log in logs) {
        statistics[log.type] = (statistics[log.type] ?? 0) + 1;
      }

      return statistics;
    } catch (e) {
      print('Error getting activity statistics: $e');
      return {};
    }
  }

  // Helper methods for specific activities
  static Future<void> logEggProduction(String farmId, int trayCount) async {
    await addActivityLog(ActivityLog.eggProduction(
      farmId: farmId,
      trayCount: trayCount,
    ));
  }

  static Future<void> logEggSale(
    String farmId,
    int trayCount,
    double pricePerTray, {
    String? customerName,
  }) async {
    await addActivityLog(ActivityLog.eggSale(
      farmId: farmId,
      trayCount: trayCount,
      pricePerTray: pricePerTray,
      customerName: customerName,
    ));
  }

  static Future<void> logCustomerAdded(String farmId, String customerName) async {
    await addActivityLog(ActivityLog.customerAdded(
      farmId: farmId,
      customerName: customerName,
    ));
  }

  static Future<void> logDebtAdded(
    String farmId,
    String customerName,
    double amount,
  ) async {
    await addActivityLog(ActivityLog.debtAdded(
      farmId: farmId,
      customerName: customerName,
      amount: amount,
    ));
  }

  static Future<void> logChickenAdded(String farmId, int count) async {
    await addActivityLog(ActivityLog.chickenAdded(
      farmId: farmId,
      count: count,
    ));
  }

  static Future<void> logChickenDeath(
    String farmId,
    int count, {
    String? reason,
  }) async {
    await addActivityLog(ActivityLog.chickenDeath(
      farmId: farmId,
      count: count,
      reason: reason,
    ));
  }

  // Sanitize activity log data to handle null values and missing fields
  static Map<String, dynamic> _sanitizeActivityLogData(Map<String, dynamic> data) {
    return {
      'id': data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'farmId': data['farmId']?.toString() ?? data['farm_id']?.toString() ?? '',
      'type': data['type']?.toString() ?? 'other',
      'title': data['title']?.toString() ?? 'Faoliyat',
      'description': data['description']?.toString() ?? '',
      'metadata': data['metadata'] is Map ? Map<String, dynamic>.from(data['metadata']) : <String, dynamic>{},
      'createdAt': data['createdAt']?.toString() ?? data['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'importance': data['importance']?.toString() ?? 'normal',
    };
  }

  // Initialize service
  static Future<void> initialize() async {
    try {
      // Register Hive adapters if not already registered
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(ActivityLogAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(ActivityTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(ActivityImportanceAdapter());
      }

      // Clean up old logs periodically
      await clearOldLogs();
      
      print('Activity Log Service initialized');
    } catch (e) {
      print('Error initializing Activity Log Service: $e');
    }
  }
}