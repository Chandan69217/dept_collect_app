import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:workmanager/workmanager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utility/excel_parser.dart';
import 'shared_prefs_service.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'package:protect/protect.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Helper methods to persist active upload status in SharedPreferences
Future<void> saveActiveUploadState(
  String taskId,
  String fileName,
  double progress, {
  String statusMessage = 'Uploading...',
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('active_upload_task_id', taskId);
  await prefs.setString('active_upload_file_name', fileName);
  await prefs.setDouble('active_upload_progress', progress);
  await prefs.setString('active_upload_status_message', statusMessage);
}

Future<void> updateActiveUploadProgress(
  String taskId,
  double progress, {
  String? statusMessage,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('active_upload_task_id') == taskId) {
    await prefs.setDouble('active_upload_progress', progress);
    if (statusMessage != null) {
      await prefs.setString('active_upload_status_message', statusMessage);
    }
  }
}

Future<void> clearActiveUploadState(String taskId) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('active_upload_task_id') == taskId) {
    await prefs.remove('active_upload_task_id');
    await prefs.remove('active_upload_file_name');
    await prefs.remove('active_upload_progress');
    await prefs.remove('active_upload_status_message');
  }
}

// Notification helpers
Future<void> showUploadProgressNotification({
  required int id,
  required String title,
  required String body,
  required int progress,
}) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'upload_progress_channel',
    'Upload Progress',
    channelDescription: 'Notifications showing file upload progress',
    importance: Importance.low,
    priority: Priority.low,
    onlyAlertOnce: true,
    showProgress: true,
    maxProgress: 100,
    progress: progress,
    ongoing: true,
  );
  final NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: platformDetails,
  );
}

Future<void> showUploadCompletedNotification({
  required int id,
  required String title,
  required String body,
  required bool isSuccess,
}) async {
  // Cancel progress notification first
  await flutterLocalNotificationsPlugin.cancel(id: id);

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'upload_channel_id',
    'Upload Status',
    channelDescription: 'Notifications for file upload background status',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );
  final NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    id: id + 1,
    title: title,
    body: body,
    notificationDetails: platformDetails,
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final String? taskId = inputData?['taskId'] as String?;
    if (taskId == null) return true;

    final int notificationId = taskId.hashCode.abs() % 100000;

    // Initialize local notifications in the background isolate
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Initialize services for background isolate
    await SharedPrefsService.init();

    if (taskId.startsWith('parse_')) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final configFile = File('${docDir.path}/$taskId.json');
        if (!await configFile.exists()) {
          return true;
        }

        final content = await configFile.readAsString();
        final config = jsonDecode(content);
        final String fileName = config['fileName'] as String;
        final String filePath = config['filePath'] as String;
        final String? password = config['password'] as String?;
        final bool isPasswordProtected =
            config['isPasswordProtected'] as bool? ?? false;

        // Show starting notification
        await showUploadProgressNotification(
          id: notificationId,
          title: 'Parsing spreadsheet...',
          body: 'Processing "$fileName"',
          progress: 5,
        );

        await saveActiveUploadState(
          taskId,
          fileName,
          0.05,
          statusMessage: 'Parsing spreadsheet...',
        );

        // Read file bytes and parse Excel in background
        final excelFile = File(filePath);
        if (!await excelFile.exists()) {
          throw Exception('Excel file does not exist');
        }
        var bytes = await excelFile.readAsBytes();

        if (isPasswordProtected) {
          await saveActiveUploadState(
            taskId,
            fileName,
            0.10,
            statusMessage: 'Decrypting file...',
          );
          await showUploadProgressNotification(
            id: notificationId,
            title: 'Parsing spreadsheet...',
            body: 'Decrypting "$fileName"',
            progress: 10,
          );

          final decrypted = Protect.decryptUint8List(bytes, password ?? '');
          if (!decrypted.isDataValid || decrypted.processedBytes == null) {
            throw Exception('password incorrect');
          }
          bytes = decrypted.processedBytes!;
        }

        await saveActiveUploadState(
          taskId,
          fileName,
          0.20,
          statusMessage: 'Decoding spreadsheet...',
        );
        await showUploadProgressNotification(
          id: notificationId,
          title: 'Parsing spreadsheet...',
          body: 'Decoding "$fileName"',
          progress: 20,
        );

        // Parse records
        final records = parseExcelSync(bytes);

        // Write parsed records to JSON file
        final parsedFile = File('${docDir.path}/parsed_$taskId.json');
        await parsedFile.writeAsString(
          jsonEncode({'fileName': fileName, 'records': records}),
        );

        // Show parsed notification
        await showUploadCompletedNotification(
          id: notificationId,
          title: 'Spreadsheet Parsed',
          body: 'Spreadsheet "$fileName" parsed successfully. Ready to verify.',
          isSuccess: true,
        );

        int totalRows = records.length;
        int skippedRows = 0;
        if (records is ParsedRecordsList) {
          totalRows = records.totalRows;
          skippedRows = records.skippedRows;
        }

        // Fallback safety: scanned rows cannot be less than parsed records
        if (totalRows < records.length) {
          totalRows = records.length;
        }

        // Set status to verification_pending
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('active_upload_records_count', records.length);
        await prefs.setInt('active_upload_scanned_count', totalRows);
        await prefs.setInt('active_upload_skipped_count', skippedRows);
        await prefs.setString(
          'active_upload_parsed_date',
          DateTime.now().toIso8601String(),
        );
        await updateActiveUploadProgress(
          taskId,
          1.0,
          statusMessage: 'verification_pending',
        );

        if (await configFile.exists()) await configFile.delete();
        if (await excelFile.exists()) await excelFile.delete();
        return true;
      } catch (e) {
        debugPrint('Background parse error for $taskId: $e');

        try {
          final docDir = await getApplicationDocumentsDirectory();
          final configFile = File('${docDir.path}/$taskId.json');
          if (await configFile.exists()) {
            final content = await configFile.readAsString();
            final config = jsonDecode(content);
            final String fileName = config['fileName'] as String;
            final String filePath = config['filePath'] as String;

            // Show failed notification
            await showUploadCompletedNotification(
              id: notificationId,
              title: 'Background Parse Failed',
              body:
                  'File "$fileName" failed to parse: ${e.toString().replaceAll('Exception: ', '')}',
              isSuccess: false,
            );

            if (await configFile.exists()) await configFile.delete();
            final excelFile = File(filePath);
            if (await excelFile.exists()) await excelFile.delete();
          }
        } catch (_) {}

        await clearActiveUploadState(taskId);
        return false;
      }
    } else {
      try {
        // Find the file in Application Documents Directory
        final docDir = await getApplicationDocumentsDirectory();
        final file = File('${docDir.path}/$taskId.json');
        if (!await file.exists()) {
          return true;
        }

        final content = await file.readAsString();
        final data = jsonDecode(content);
        final String fileName = data['fileName'] as String;
        final List<Map<String, dynamic>> records =
            List<Map<String, dynamic>>.from(data['records']);

        // Show starting notification
        await showUploadProgressNotification(
          id: notificationId,
          title: 'Background Uploading...',
          body: 'Uploading "$fileName"',
          progress: 0,
        );

        await saveActiveUploadState(taskId, fileName, 0.0);

        final apiService = ApiService();
        await apiService.uploadRecords(
          fileName,
          records,
          onProgress: (progress) {
            final int percent = (progress * 100).toInt();
            showUploadProgressNotification(
              id: notificationId,
              title: 'Background Uploading...',
              body: 'Uploading "$fileName": $percent% completed',
              progress: percent,
            );
            updateActiveUploadProgress(taskId, progress);
          },
        );

        // Save success result in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        List<String> completedList =
            prefs.getStringList('bg_completed_uploads') ?? [];
        completedList.add(
          jsonEncode({
            'fileName': fileName,
            'recordsCount': records.length,
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'success',
          }),
        );
        await prefs.setStringList('bg_completed_uploads', completedList);

        // Show completed notification
        await showUploadCompletedNotification(
          id: notificationId,
          title: 'Background Import Successful',
          body:
              'File "$fileName" with ${records.length} records imported successfully.',
          isSuccess: true,
        );

        // Clear state
        await clearActiveUploadState(taskId);
        await file.delete();
        return true;
      } catch (e) {
        debugPrint('Background upload error for $taskId: $e');

        try {
          final docDir = await getApplicationDocumentsDirectory();
          final file = File('${docDir.path}/$taskId.json');
          if (await file.exists()) {
            final content = await file.readAsString();
            final data = jsonDecode(content);
            final String fileName = data['fileName'] as String;
            final List<Map<String, dynamic>> records = data['records'] != null
                ? List<Map<String, dynamic>>.from(data['records'])
                : [];

            final prefs = await SharedPreferences.getInstance();
            List<String> completedList =
                prefs.getStringList('bg_completed_uploads') ?? [];
            completedList.add(
              jsonEncode({
                'fileName': fileName,
                'recordsCount': records.length,
                'timestamp': DateTime.now().toIso8601String(),
                'status': 'failure',
                'error': e.toString().replaceAll('Exception: ', ''),
              }),
            );
            await prefs.setStringList('bg_completed_uploads', completedList);

            // Show failed notification
            await showUploadCompletedNotification(
              id: notificationId,
              title: 'Background Import Failed',
              body:
                  'File "$fileName" failed to upload: ${e.toString().replaceAll('Exception: ', '')}',
              isSuccess: false,
            );
          }
        } catch (_) {}

        await clearActiveUploadState(taskId);
        return false;
      }
    }
  });
}

class BackgroundUploadService {
  static final BackgroundUploadService _instance =
      BackgroundUploadService._internal();
  factory BackgroundUploadService() => _instance;
  BackgroundUploadService._internal();

  bool isAppInitialized = false;
  String? pendingSharedFilePath;

  void init() {
    // 1. Initialize Workmanager
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // 2. Initialize Local Notifications Plugin and request permissions
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin
        .initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            // Navigate to upload screen when notification is clicked
            Future.delayed(const Duration(milliseconds: 500), () {
              navigatorKey.currentState?.pushNamed('/upload_data');
            });
          },
        )
        .then((_) {
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
        });

    // 3. Listen for Excel files shared from other apps (WhatsApp, Files, etc.)
    FlutterSharingIntent.instance.getMediaStream().listen((
      List<SharedFile> files,
    ) {
      if (files.isNotEmpty) {
        final path = files.first.value;
        if (path != null) _handleSharedFile(path);
      }
    }, onError: (err) => debugPrint('Sharing intent stream error: $err'));

    // Handle file shared when app was cold-started from a share intent
    FlutterSharingIntent.instance.getInitialSharing().then((
      List<SharedFile> files,
    ) {
      if (files.isNotEmpty) {
        final path = files.first.value;
        if (path != null) _handleSharedFile(path);
      }
    });
  }

  void _handleSharedFile(String path) {
    try {
      String cleanPath = path;
      if (cleanPath.startsWith('file://')) {
        cleanPath = Uri.parse(cleanPath).toFilePath();
      }
      final file = File(cleanPath);
      final String fileName = file.path.split('/').last.split('\\').last;
      final ext = fileName.split('.').last.toLowerCase();

      if (ext != 'xlsx' && ext != 'xls') {
        debugPrint('Shared file is not an Excel file: $fileName');
        return;
      }

      if (!isAppInitialized) {
        debugPrint('App not initialized yet. Caching shared file: $cleanPath');
        pendingSharedFilePath = cleanPath;
        return;
      }

      if (!SharedPrefsService.isLoggedIn()) {
        debugPrint('User not logged in, ignoring shared file.');
        return;
      }

      // Navigate to upload screen so the user can see progress
      Future.delayed(const Duration(milliseconds: 500), () {
        navigatorKey.currentState?.pushNamed('/upload_data');
      });

      final actualBytes = file.readAsBytesSync();

      // Check if file is password protected
      if (DatabaseService().checkIsPasswordProtectedPublic(actualBytes)) {
        // Prompt password in foreground
        DatabaseService().setupDecryptPrompt(fileName, actualBytes);
      } else {
        // Start foreground parsing!
        DatabaseService().startParsingExcel(
          fileName: fileName,
          filePath: cleanPath,
        );
      }
    } catch (e) {
      debugPrint('Error handling shared file: $e');
    }
  }

  void processPendingSharedFile() {
    if (pendingSharedFilePath != null) {
      final path = pendingSharedFilePath!;
      pendingSharedFilePath = null;
      _handleSharedFile(path);
    }
  }

  Future<String> prepareBackup(
    String fileName,
    List<Map<String, dynamic>> records,
  ) async {
    final String taskId = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final docDir = await getApplicationDocumentsDirectory();
    final file = File('${docDir.path}/$taskId.json');

    await file.writeAsString(
      jsonEncode({'fileName': fileName, 'records': records}),
    );
    return taskId;
  }

  Future<void> enqueueUpload(String taskId) async {
    await Workmanager().registerOneOffTask(
      taskId,
      "uploadTask",
      inputData: {'taskId': taskId},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Future<void> removeBackup(String taskId) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/$taskId.json');
      if (await file.exists()) {
        await file.delete();
      }
      await Workmanager().cancelByUniqueName(taskId);
    } catch (e) {
      debugPrint('Error removing backup/task: $e');
    }
  }
}
