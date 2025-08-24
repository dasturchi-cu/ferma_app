// import 'dart:convert';
// import 'dart:io';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:googleapis_auth/auth_io.dart';
// import 'package:hive/hive.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart';
// import '../models/farm.dart';

// class GoogleAuthClient extends BaseClient {
//   final Map<String, String> _headers;

//   GoogleAuthClient(this._headers);

//   @override
//   Future<StreamedResponse> send(BaseRequest request) {
//     request.headers.addAll(_headers);
//     return request.send();
//   }
// }

// class AutoBackupService {
//   static const String _backupTaskName = 'ferma_backup_task';
//   static const String _backupFolderName = 'Ferma App Backups';

//   // Initialize background backup tasks
//   static Future<void> initialize() async {
//     await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
//     await scheduleAutoBackup();
//   }

//   // Schedule daily automatic backup
//   static Future<void> scheduleAutoBackup() async {
//     await Workmanager().registerPeriodicTask(
//       _backupTaskName,
//       'performDailyBackup',
//       frequency: const Duration(hours: 24),
//       initialDelay: const Duration(hours: 1),
//       constraints: Constraints(
//         networkType: NetworkType.connected,
//         requiresBatteryNotLow: true,
//       ),
//     );
//   }

//   // Cancel automatic backup
//   static Future<void> cancelAutoBackup() async {
//     await Workmanager().cancelByUniqueName(_backupTaskName);
//   }

//   // Manual backup to Google Drive with retry logic
//   static Future<BackupResult> backupToGoogleDrive({
//     bool showProgress = false,
//     int maxRetries = 3,
//   }) async {
//     int attempt = 0;
//     Exception? lastError;
    
//     while (attempt < maxRetries) {
//       try {
//         attempt++;
        
//         if (showProgress) {
//           print('Backup attempt $attempt of $maxRetries...');
//         }

//         // 1. Get all farm data
//         final userData = await _exportUserData();
//         if (userData == null) {
//           throw Exception('Ma\'lumotlar topilmadi');
//         }

//         // 2. Create backup metadata with validation
//         final backupData = await _createBackupData(userData);
//         if (backupData == null || backupData.isEmpty) {
//           throw Exception('Backup ma\'lumotlari yaratib bo\'lmadi');
//         }

//         // 3. Convert to JSON with validation
//         final backupJson = jsonEncode(backupData);
//         if (backupJson.isEmpty) {
//           throw Exception('JSON ma\'lumotlari yaratib bo\'lmadi');
//         }

//         // 4. Authenticate with Google Drive with timeout
//         final driveApi = await _authenticateWithRetry(
//           maxRetries: 2,
//           timeout: const Duration(seconds: 30),
//         );
        
//         if (driveApi == null) {
//           throw Exception('Google Drive ga ulanishda xatolik');
//         }

//         // 5. Create backup file with unique name
//         final timestamp = DateTime.now().millisecondsSinceEpoch;
//         final fileName = 'ferma_backup_${Farm.id}_$timestamp.json';
        
//         final driveFile = drive.File()
//           ..name = fileName
//           ..description = 'Ferma App backup - ${DateTime.now()} - Attempt $attempt'
//           ..parents = [await _getOrCreateBackupFolder(driveApi)];

//         // 6. Upload to Google Drive with progress tracking
//         final media = drive.Media(
//           Stream.fromIterable([utf8.encode(backupJson)]),
//           backupJson.length,
//         );

//         if (showProgress) {
//           print('Backup fayli yuklanmoqda...');
//         }
        
//         final uploadResponse = await driveApi.files.create(
//           driveFile,
//           uploadMedia: media,
//         ).timeout(
//           const Duration(minutes: 5),
//           onTimeout: () => throw TimeoutException('Backup vaqt tugadi'),
//         );

//         if (uploadResponse.id == null) {
//           throw Exception('Fayl yuklanmadi');
//         }

//         // 7. Verify the backup was created
//         final file = await driveApi.files.get(
//           uploadResponse.id!,
//           $fields: 'id,name,size,createdTime',
//         ) as drive.File;

//         if (file.size == null || file.size! <= 0) {
//           throw Exception('Backup fayli bo\'sh yoki xato');
//         }

//         // 8. Clean old backups (keep only last 10)
//         await _cleanOldBackups(driveApi);

//         // 9. Update last backup time
//         await _updateLastBackupTime();

//         return BackupResult(
//           success: true,
//           message: 'Backup muvaffaqiyatli yaratildi',
//           fileName: file.name ?? fileName,
//           fileSize: file.size ?? backupJson.length,
//           backupId: file.id,
//           backupTime: file.createdTime ?? DateTime.now().toIso8601String(),
//         );
//       } on TimeoutException catch (e) {
//         lastError = e;
//         print('Backup timeout: $e');
//       } on drive.DetailedApiRequestError catch (e) {
//         lastError = e;
//         print('Google API error: ${e.status} - ${e.message}');
        
//         // If it's an auth error, we might need to re-authenticate
//         if (e.status == 401 || e.status == 403) {
//           // Clear any cached credentials
//           await _clearCachedCredentials();
//         }
//       } catch (e) {
//         lastError = e is Exception ? e : Exception(e.toString());
//         print('Backup error (attempt $attempt): $e');
        
//         // If it's not the last attempt, wait before retrying
//         if (attempt < maxRetries) {
//           await Future.delayed(Duration(seconds: attempt * 2));
//           continue;
//         }
//       }
//     }

//     // If we get here, all attempts failed
//     return BackupResult(
//       success: false,
//       message: 'Backup yaratib bo\'lmadi: ${lastError?.toString() ?? 'Noma\'lum xatolik'}\nUrinishlar soni: $attempt',
//     );
//   }
  
//   // Helper method to authenticate with retry logic
//   static Future<drive.DriveApi?> _authenticateWithRetry({
//     int maxRetries = 2,
//     Duration? timeout,
//   }) async {
//     int attempt = 0;
//     Exception? lastError;
    
//     while (attempt < maxRetries) {
//       try {
//         final authClient = await _getAuthenticatedClient();
//         if (authClient != null) {
//           return drive.DriveApi(authClient);
//         }
//       } catch (e) {
//         lastError = e is Exception ? e : Exception(e.toString());
//         print('Auth error (attempt ${attempt + 1}): $e');
        
//         // Clear any cached credentials on auth failure
//         await _clearCachedCredentials();
        
//         if (attempt < maxRetries - 1) {
//           await Future.delayed(Duration(seconds: (attempt + 1) * 2));
//         }
//       }
      
//       attempt++;
//     }
    
//     print('Authentication failed after $maxRetries attempts: $lastError');
//     return null;
//   }
  
//   // Clear any cached authentication tokens
//   static Future<void> _clearCachedCredentials() async {
//     try {
//       final googleSignIn = GoogleSignIn();
//       await googleSignIn.signOut();
//       await googleSignIn.disconnect();
//     } catch (e) {
//       print('Error clearing cached credentials: $e');
//     }
//   }

//   // Restore from latest backup
//   static Future<BackupResult> restoreFromBackup() async {
//     try {
//       // 1. Authenticate with Google Drive
//       final driveApi = await _authenticateGoogleDrive();
//       if (driveApi == null) {
//         return BackupResult(
//           success: false,
//           message: 'Google Drive ga ulanishda xatolik',
//         );
//       }

//       // 2. Find latest backup file
//       final latestBackup = await _findLatestBackup(driveApi);
//       if (latestBackup == null) {
//         return BackupResult(success: false, message: 'Backup fayl topilmadi');
//       }

//       // 3. Download backup file
//       final backupContent = await _downloadBackupFile(
//         driveApi,
//         latestBackup.id!,
//       );
//       if (backupContent == null) {
//         return BackupResult(
//           success: false,
//           message: 'Backup faylni yuklab olishda xatolik',
//         );
//       }

//       // 4. Parse backup data
//       final backupData = jsonDecode(backupContent);

//       // 5. Validate backup data
//       if (!_validateBackupData(backupData)) {
//         return BackupResult(
//           success: false,
//           message: 'Backup fayl buzilgan yoki noto\'g\'ri format',
//         );
//       }

//       // 6. Import data to local storage
//       await _importUserData(backupData['data']);

//       return BackupResult(
//         success: true,
//         message: 'Ma\'lumotlar muvaffaqiyatli tiklandi',
//         fileName: latestBackup.name,
//       );
//     } catch (e) {
//       print('Restore error: $e');
//       return BackupResult(
//         success: false,
//         message: 'Ma\'lumotlarni tiklashda xatolik: ${e.toString()}',
//       );
//     }
//   }

//   // List available backups
//   static Future<List<BackupInfo>> listBackups() async {
//     try {
//       final driveApi = await _authenticateGoogleDrive();
//       if (driveApi == null) return [];

//       final folderId = await _getOrCreateBackupFolder(driveApi);
//       final fileList = await driveApi.files.list(
//         q: "parents in '$folderId' and name contains 'ferma_backup_'",
//         orderBy: 'createdTime desc',
//         pageSize: 20,
//       );

//       List<BackupInfo> backups = [];
//       for (var file in fileList.files ?? []) {
//         backups.add(
//           BackupInfo(
//             id: file.id!,
//             name: file.name!,
//             createdTime: file.createdTime!,
//             size: file.size?.toInt() ?? 0,
//           ),
//         );
//       }

//       return backups;
//     } catch (e) {
//       print('List backups error: $e');
//       return [];
//     }
//   }

//   // Delete specific backup
//   static Future<bool> deleteBackup(String fileId) async {
//     try {
//       final driveApi = await _authenticateGoogleDrive();
//       if (driveApi == null) return false;

//       await driveApi.files.delete(fileId);
//       return true;
//     } catch (e) {
//       print('Delete backup error: $e');
//       return false;
//     }
//   }

//   // Private helper methods
//   static Future<drive.DriveApi?> _authenticateGoogleDrive() async {
//     try {
//       final googleSignIn = GoogleSignIn(
//         scopes: [drive.DriveApi.driveFileScope],
//       );

//       final account = await googleSignIn.signIn();
//       if (account == null) return null;

//       final authHeaders = await account.authHeaders;
//       final authenticateClient = GoogleAuthClient(authHeaders);

//       return drive.DriveApi(authenticateClient);
//     } catch (e) {
//       print('Google Drive authentication error: $e');
//       return null;
//     }
//   }

//   static Future<String> _getOrCreateBackupFolder(
//     drive.DriveApi driveApi,
//   ) async {
//     // Search for existing backup folder
//     final folderList = await driveApi.files.list(
//       q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder'",
//     );

//     if (folderList.files?.isNotEmpty == true) {
//       return folderList.files!.first.id!;
//     }

//     // Create new backup folder
//     final folder = drive.File()
//       ..name = _backupFolderName
//       ..mimeType = 'application/vnd.google-apps.folder';

//     final createdFolder = await driveApi.files.create(folder);
//     return createdFolder.id!;
//   }

//   static Future<Map<String, dynamic>?> _exportUserData() async {
//     try {
//       final farmBox = await Hive.openBox<Farm>('farms');
//       final farms = farmBox.values.toList();

//       if (farms.isEmpty) return null;

//       return {
//         'farms': farms.map((farm) => farm.toJson()).toList(),
//         'version': '1.0',
//         'exported_at': DateTime.now().toIso8601String(),
//       };
//     } catch (e) {
//       print('Export data error: $e');
//       return null;
//     }
//   }

//   static Future<Map<String, dynamic>> _createBackupData(
//     Map<String, dynamic> userData,
//   ) async {
//     final packageInfo = await PackageInfo.fromPlatform();
//     final deviceInfo = await DeviceInfoPlugin().deviceInfo;

//     return {
//       'backup_date': DateTime.now().toIso8601String(),
//       'app_version': packageInfo.version,
//       'app_build': packageInfo.buildNumber,
//       'device_info': _getDeviceInfoMap(deviceInfo),
//       'total_records': userData['farms']?.length ?? 0,
//       'data': userData,
//     };
//   }

//   static Map<String, dynamic> _getDeviceInfoMap(BaseDeviceInfo deviceInfo) {
//     if (deviceInfo is AndroidDeviceInfo) {
//       return {
//         'platform': 'android',
//         'model': deviceInfo.model,
//         'brand': deviceInfo.brand,
//         'version': deviceInfo.version.release,
//       };
//     } else if (deviceInfo is IosDeviceInfo) {
//       return {
//         'platform': 'ios',
//         'model': deviceInfo.model,
//         'name': deviceInfo.name,
//         'version': deviceInfo.systemVersion,
//       };
//     } else {
//       return {'platform': 'unknown'};
//     }
//   }

//   static Future<drive.File?> _findLatestBackup(drive.DriveApi driveApi) async {
//     final folderId = await _getOrCreateBackupFolder(driveApi);
//     final fileList = await driveApi.files.list(
//       q: "parents in '$folderId' and name contains 'ferma_backup_'",
//       orderBy: 'createdTime desc',
//       pageSize: 1,
//     );

//     return fileList.files?.isNotEmpty == true ? fileList.files!.first : null;
//   }

//   static Future<String?> _downloadBackupFile(
//     drive.DriveApi driveApi,
//     String fileId,
//   ) async {
//     try {
//       final media = await driveApi.files.get(
//         fileId,
//         downloadOptions: drive.DownloadOptions.fullMedia,
//       );

//       if (media is drive.Media) {
//         final bytes = await media.stream.toList();
//         final content = utf8.decode(bytes.expand((x) => x).toList());
//         return content;
//       }
//     } catch (e) {
//       print('Download backup file error: $e');
//     }
//     return null;
//   }

//   static bool _validateBackupData(Map<String, dynamic> backupData) {
//     return backupData.containsKey('data') &&
//         backupData.containsKey('backup_date') &&
//         backupData.containsKey('app_version');
//   }

//   static Future<void> _importUserData(Map<String, dynamic> userData) async {
//     try {
//       final farmBox = await Hive.openBox<Farm>('farms');

//       // Clear existing data
//       await farmBox.clear();

//       // Import farms
//       if (userData['farms'] != null) {
//         for (var farmJson in userData['farms']) {
//           final farm = Farm.fromJson(farmJson);
//           await farmBox.put(farm.id, farm);
//         }
//       }
//     } catch (e) {
//       print('Import data error: $e');
//       rethrow;
//     }
//   }

//   static Future<void> _cleanOldBackups(drive.DriveApi driveApi) async {
//     try {
//       final folderId = await _getOrCreateBackupFolder(driveApi);
//       final fileList = await driveApi.files.list(
//         q: "parents in '$folderId' and name contains 'ferma_backup_'",
//         orderBy: 'createdTime desc',
//         pageSize: 20,
//       );

//       final files = fileList.files ?? [];
//       if (files.length > 10) {
//         // Delete files beyond the 10 most recent
//         for (int i = 10; i < files.length; i++) {
//           await driveApi.files.delete(files[i].id!);
//         }
//       }
//     } catch (e) {
//       print('Clean old backups error: $e');
//     }
//   }

//   static Future<void> _updateLastBackupTime() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
//   }

//   static Future<DateTime?> getLastBackupTime() async {
//     final prefs = await SharedPreferences.getInstance();
//     final timeString = prefs.getString('last_backup_time');
//     return timeString != null ? DateTime.parse(timeString) : null;
//   }
// }

// // Background task callback
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     switch (task) {
//       case 'performDailyBackup':
//         final result = await AutoBackupService.backupToGoogleDrive();
//         print('Background backup result: ${result.message}');
//         return result.success;
//       default:
//         return true;
//     }
//   });
// }

// // Data classes
// class BackupResult {
//   final bool success;
//   final String message;
//   final String? fileName;
//   final int? fileSize;

//   BackupResult({
//     required this.success,
//     required this.message,
//     this.fileName,
//     this.fileSize,
//   });
// }

// class BackupInfo {
//   final String id;
//   final String name;
//   final DateTime createdTime;
//   final int size;

//   BackupInfo({
//     required this.id,
//     required this.name,
//     required this.createdTime,
//     required this.size,
//   });

//   String get formattedSize {
//     if (size < 1024) return '$size B';
//     if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
//     return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
//   }
// }
