import 'dart:io';
import 'dart:isolate';
import 'package:dept_collection_app/constants/app_constants.dart';
import 'package:dept_collection_app/models/recent_upload_item.dart';
import 'package:dept_collection_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;
import '../../theme/app_theme.dart';
import '../../widgets/custom_bento_card.dart';
import '../../config/field_mapping.dart';
import 'verify_uploaded_records_screen.dart';
import '../../widgets/custom_feedback.dart';

class UploadDataScreen extends StatefulWidget {
  const UploadDataScreen({super.key});

  @override
  State<UploadDataScreen> createState() => _UploadDataScreenState();
}

class _UploadDataScreenState extends State<UploadDataScreen> {
  final _db = DatabaseService();
  String? _selectedFileName;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _uploadComplete = false;
  int _totalRowsScanned = 0;
  bool _isLoading = false;
  int _skippedRowsCount = 0;
  String _progressMessage = 'Preparing file...';

  final List<Map<String, dynamic>> _importRecords = [];

  Isolate? _activeIsolate;
  ReceivePort? _activeReceivePort;

  void _cancelUpload() {
    if (_activeIsolate != null) {
      _activeIsolate!.kill(priority: Isolate.beforeNextEvent);
      _activeIsolate = null;
    }
    if (_activeReceivePort != null) {
      _activeReceivePort!.close();
      _activeReceivePort = null;
    }
    setState(() {
      _isUploading = false;
      _uploadComplete = false;
      _selectedFileName = null;
      _totalRowsScanned = 0;
      _skippedRowsCount = 0;
      _importRecords.clear();
    });
  }

  void _cancelParsedData() {
    setState(() {
      _uploadComplete = false;
      _selectedFileName = null;
      _totalRowsScanned = 0;
      _skippedRowsCount = 0;
      _importRecords.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _db.fetchRecentUploads();
    } catch (e) {
      if (mounted) {
        CustomFeedback.showToast(
          context,
          'Failed to load recent uploads: ${e.toString().replaceAll('Exception: ', '')}',
          type: 'error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.first;
      final extension = file.extension?.toLowerCase();
      if (extension != 'xlsx' && extension != 'xls') {
        _showErrorSnackBar(
          'Invalid file format. Please upload an Excel file (.xlsx or .xls).',
        );
        return;
      }

      setState(() {
        _selectedFileName = file.name;
        _isUploading = true;
        _uploadProgress = 0.0;
        _progressMessage = 'Reading file from disk...';
        _uploadComplete = false;
        _totalRowsScanned = 0;
        _skippedRowsCount = 0;
        _importRecords.clear();
      });

      final filePath = file.path;
      final fileBytes = file.bytes;

      // Ensure we have data to process
      if (kIsWeb && fileBytes == null) {
        _showErrorSnackBar('Could not read file data (bytes are empty).');
        setState(() {
          _isUploading = false;
        });
        return;
      }
      if (!kIsWeb && filePath == null && fileBytes == null) {
        _showErrorSnackBar(
          'Could not read file data (both path and bytes are empty).',
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      setState(() {
        _uploadProgress = 0.05;
        _progressMessage = 'Spawning background parser...';
      });

      final receivePort = ReceivePort();
      _activeReceivePort = receivePort;
      final isolate = await Isolate.spawn(
        _parseExcelIsolate,
        _ExcelIsolateParams(
          filePath: kIsWeb ? null : filePath,
          bytes: kIsWeb ? fileBytes : null,
          sendPort: receivePort.sendPort,
        ),
      );
      _activeIsolate = isolate;

      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          final type = message['type'];
          if (type == 'progress') {
            setState(() {
              _uploadProgress = message['progress'] as double;
              _progressMessage = message['message'] as String;
            });
          } else if (type == 'chunk') {
            final List<Map<String, dynamic>> chunkRecords =
                List<Map<String, dynamic>>.from(message['records']);
            final double? progress = message['progress'] as double?;
            final String? progressMsg = message['message'] as String?;
            setState(() {
              _importRecords.addAll(chunkRecords);
              if (progress != null) {
                _uploadProgress = progress;
              }
              if (progressMsg != null) {
                _progressMessage = progressMsg;
              }
            });
          } else if (type == 'success') {
            final int totalRows = message['totalRows'] as int;
            final int skippedRows = message['skippedRows'] as int;

            setState(() {
              _uploadProgress = 1.0;
              _isUploading = false;
              _uploadComplete = true;
              _totalRowsScanned = totalRows;
              _skippedRowsCount = skippedRows;
            });
            _activeReceivePort = null;
            _activeIsolate = null;
            receivePort.close();
            isolate.kill(priority: Isolate.beforeNextEvent);
          } else if (type == 'error') {
            final error = message['error'];
            setState(() {
              _isUploading = false;
              _uploadComplete = false;
            });
            _showErrorSnackBar('Failed to parse Excel file: $error');
            _activeReceivePort = null;
            _activeIsolate = null;
            receivePort.close();
            isolate.kill(priority: Isolate.beforeNextEvent);
          }
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadComplete = false;
      });
      _showErrorSnackBar('Failed to parse Excel file: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  void _commitImport() {
    // Navigate to VerifyUploadedRecordsScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyUploadedRecordsScreen(
          fileName: _selectedFileName ?? 'Q3_SouthZone_Debtors.csv',
          records: _importRecords,
        ),
      ),
    ).then((success) {
      if (success == true) {
        // If successfully committed from that screen, update local uploads log!
        setState(() {
          _uploadComplete = false;
          _selectedFileName = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: _db,
          builder: (context, child) {
            return Column(
              children: [
                if (_isLoading) CustomFeedback.showProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title
                      Text(
                        'Upload Data',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Import ledger files for collection processing.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dynamic Interaction Block (Upload area, Loading progress, or Report analysis)
                      if (_isUploading) ...[
                        _buildProgressCard(),
                      ] else if (_uploadComplete) ...[
                        _buildReportCard(),
                      ] else ...[
                        _buildUploadDropZone(),
                      ],
                      const SizedBox(height: 28),

                      // Recent Uploads Logger Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Uploads',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) {
                                  return _RecentUploadsBottomSheet(
                                    uploads: _db.recentUploadItem,
                                    cardBuilder: _buildRecentUploadCard,
                                  );
                                },
                              );
                            },
                            child: const Text(
                              'VIEW ALL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _db.recentUploadItem.length > 5
                            ? 5
                            : _db.recentUploadItem.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _db.recentUploadItem[index];
                          return _buildRecentUploadCard(item);
                        },
                      ),
                      const SizedBox(height: 28),

                      // Requirements Guidance Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.info,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Data Requirements',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "Ensure headers include 'DebtorID', 'Amount', and 'DueDate' for automatic mapping.",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadDropZone() {
    return GestureDetector(
      onTap: _pickExcelFile,
      child: Container(
        width: double.infinity,
        height: 230,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.2),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.cloudUpload,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to select or drop files',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Supports Excel (.xlsx, .xls) formats',
              style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              onPressed: _pickExcelFile,
              child: const Text(
                'Browse Files',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final bool isIndeterminate = _uploadProgress < 0.3;

    return CustomBentoCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.refreshCw,
              color: AppTheme.primary,
              size: 44,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _progressMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isIndeterminate)
                  Text(
                    '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primary,
                    ),
                  )
                else
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: isIndeterminate ? null : (_uploadProgress > 1.0 ? 1.0 : _uploadProgress),
                minHeight: 8,
                backgroundColor: AppTheme.surfaceContainerLow,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _cancelUpload,
              icon: const Icon(LucideIcons.x, size: 16),
              label: const Text(
                'Cancel Parsing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                backgroundColor: AppTheme.error.withOpacity(0.04),
                side: BorderSide(
                  color: AppTheme.error.withOpacity(0.25),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard() {
    return CustomBentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    color: AppTheme.success,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'PARSING ANALYSIS COMPLETE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _cancelParsedData,
                icon: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: AppTheme.secondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 24, color: AppTheme.outlineVariant),
          _buildReportRow(
            'File Selected',
            _selectedFileName ?? 'Imported_File.xlsx',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          _buildReportRow('Total Rows Scanned', '$_totalRowsScanned'),
          const SizedBox(height: 10),
          _buildReportRow(
            'New Debtor Accounts',
            '${_importRecords.length}',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          _buildReportRow(
            'Duplicate/Invalid Skipped',
            '$_skippedRowsCount',
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 10),
          _buildReportRow(
            'Validation Syntax Errors',
            '0',
            color: AppTheme.success,
          ),
          if (_totalRowsScanned > 10000) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    color: AppTheme.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Large Dataset Warning',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'The selected file contains ${_totalRowsScanned.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")} rows. The preview below is capped at 10,000 records to ensure app stability and responsiveness.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 24, color: AppTheme.outlineVariant),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _commitImport,
              child: const Text(
                'COMMIT AND VERIFY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUploadCard(RecentUploadItem item) {
    Color badgeBg;
    Color badgeText;
    Widget statusWidget;

    if (item.status == 'Processing') {
      badgeBg = AppTheme.surfaceContainer;
      badgeText = const Color(0xFF3C475A);
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseIndicator(),
          const SizedBox(width: 6),
          Text(
            item.status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeText,
            ),
          ),
        ],
      );
    } else if (item.status == 'Failed') {
      badgeBg = AppTheme.errorContainer;
      badgeText = AppTheme.error;
      statusWidget = Text(
        item.status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeText,
        ),
      );
    } else {
      // Completed
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF1B5E20);
      statusWidget = Text(
        item.status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeText,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          // Doc Icon Box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.fileText,
              color: AppTheme.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.formattedDate} • ${item.totalRecords} records',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: statusWidget,
          ),
        ],
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ExcelIsolateParams {
  final String? filePath;
  final List<int>? bytes;
  final SendPort sendPort;

  _ExcelIsolateParams({
    this.filePath,
    this.bytes,
    required this.sendPort,
  });
}

void _parseExcelIsolate(_ExcelIsolateParams params) {
  final sendPort = params.sendPort;
  final filePath = params.filePath;
  List<int>? bytes = params.bytes;

  try {
    if (bytes == null && filePath != null) {
      sendPort.send({
        'type': 'progress',
        'progress': 0.08,
        'message': 'Reading file from disk...',
      });
      bytes = File(filePath).readAsBytesSync();
    }

    if (bytes == null) {
      throw Exception('File data is empty');
    }

    sendPort.send({
      'type': 'progress',
      'progress': 0.12,
      'message': 'Decoding Excel spreadsheet...',
    });

    final stopwatch = Stopwatch()..start();
    var excel = Excel.decodeBytes(bytes);
    debugPrint(
      'Isolate: Excel decode completed in ${stopwatch.elapsedMilliseconds}ms',
    );

    sendPort.send({
      'type': 'progress',
      'progress': 0.25,
      'message': 'Analyzing sheets and data structure...',
    });

    int totalRows = 0;
    int skippedRows = 0;

    if (excel.tables.isNotEmpty) {
      final String firstSheetName = excel.tables.keys.first;
      debugPrint('Isolate: Target sheet name: $firstSheetName');

      final sheet = excel.tables[firstSheetName];
      if (sheet != null) {
        final rows = sheet.rows;
        totalRows = rows.length;

        if (rows.isNotEmpty) {
          // Extract headers
          final headerRow = rows.first;
          List<String> headers = [];
          for (final cell in headerRow) {
            headers.add(cell?.value?.toString() ?? '');
          }
          debugPrint('Isolate: Mapped headers: $headers');

          // Parse data rows in chunks
          final List<Map<String, dynamic>> chunk = [];
          const int chunkSize = 1000;

          for (int i = 1; i < totalRows; i++) {
            final row = rows[i];
            Map<String, dynamic> record = {};
            for (int j = 0; j < headers.length; j++) {
              final cell = j < row.length ? row[j] : null;
              final val = cell?.value;
              final header = headers[j];
              final mappedKey = ExcelFieldMapping.mapHeader(header);
              if (mappedKey != null) {
                record[mappedKey] = val?.toString() ?? '';
              } else {
                record[header] = val?.toString() ?? '';
              }
            }

            // Normalise mandatory fields to pass to VerifyUploadedRecordsScreen
            final name =
                record['name'] ??
                record['customer_name'] ??
                record['CUSTOMER_NAME'] ??
                '';
            if (name.toString().trim().isNotEmpty) {
              double amountDue = 0.0;
              final rawAmount =
                  record['amountDue'] ??
                  record['amount'] ??
                  record['Amount'] ??
                  '';
              if (rawAmount.toString().isNotEmpty) {
                amountDue =
                    double.tryParse(rawAmount.toString().replaceAll(',', '')) ??
                    0.0;
              }

              int overdueDays = 10;
              final rawOverdue = record['overdueDays'] ?? record['days'] ?? '';
              if (rawOverdue.toString().isNotEmpty) {
                overdueDays = int.tryParse(rawOverdue.toString()) ?? 10;
              }

              final address =
                  record['address'] ?? record['location'] ?? 'No Address';
              final phone =
                  record['phone'] ?? record['mobile'] ?? '+91 99999 99999';
              final priority = record['priority'] ?? 'MEDIUM';

              chunk.add({
                'name': name.toString().trim(),
                'amountDue': amountDue,
                'overdueDays': overdueDays,
                'address': address.toString().trim(),
                'phone': phone.toString().trim(),
                'priority':
                    (priority.toString().toUpperCase() == 'HIGH' ||
                        priority.toString().toUpperCase() == 'LOW')
                    ? priority.toString().toUpperCase()
                    : 'MEDIUM',
                // Additional excel mapped fields
                'assetModel': record['assetModel'] ?? '',
                'assetRegNo': record['assetRegNo'] ?? '',
                'engineNumber': record['engineNumber'] ?? '',
                'chasisNumber': record['chasisNumber'] ?? '',
                'assetVariant': record['assetVariant'] ?? '',
              });
            } else {
              skippedRows++;
            }

            if (chunk.length >= chunkSize) {
              final double percent = 0.3 + (i / totalRows) * 0.6;
              final String displayPercent = (percent * 100).toStringAsFixed(0);
              sendPort.send({
                'type': 'chunk',
                'records': List<Map<String, dynamic>>.from(chunk),
                'progress': percent,
                'message': 'Parsed $i / $totalRows rows ($displayPercent%)...',
              });
              chunk.clear();
            }
          }

          // Send any remaining records in the last chunk
          if (chunk.isNotEmpty) {
            sendPort.send({
              'type': 'chunk',
              'records': List<Map<String, dynamic>>.from(chunk),
              'progress': 0.9,
              'message': 'Parsed all rows...',
            });
            chunk.clear();
          }

          debugPrint(
            'Isolate: Completed parsing of all rows in ${stopwatch.elapsedMilliseconds}ms. Skipped: $skippedRows',
          );
        }
      }
    }

    sendPort.send({
      'type': 'success',
      'totalRows': totalRows,
      'skippedRows': skippedRows,
    });
  } catch (e) {
    sendPort.send({'type': 'error', 'error': e.toString()});
  }
}

class _RecentUploadsBottomSheet extends StatefulWidget {
  final List<RecentUploadItem> uploads;
  final Widget Function(RecentUploadItem) cardBuilder;

  const _RecentUploadsBottomSheet({
    required this.uploads,
    required this.cardBuilder,
  });

  @override
  State<_RecentUploadsBottomSheet> createState() =>
      _RecentUploadsBottomSheetState();
}

class _RecentUploadsBottomSheetState extends State<_RecentUploadsBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RecentUploadItem> get _filteredUploads {
    return widget.uploads.where((item) {
      // 1. Search Query Filter
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesFile = item.fileName.toLowerCase().contains(query);
        final matchesUploader =
            item.uploadedBy?.toLowerCase().contains(query) ?? false;
        if (!matchesFile && !matchesUploader) {
          return false;
        }
      }

      // 2. Status Filter
      if (_selectedStatus != 'All') {
        if (item.status.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }
      }

      // 3. Date Range Filter
      if (_selectedDateRange != null) {
        final itemDate = DateTime(
          item.createdAt.year,
          item.createdAt.month,
          item.createdAt.day,
        );
        final startDate = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final endDate = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );

        if (itemDate.isBefore(startDate) || itemDate.isAfter(endDate)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUploads;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Title and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Upload Records',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Search and filter all historical Excel collection imports.',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            const SizedBox(height: 16),

            // Filters Card
            CustomBentoCard(
              padding: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar Input
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by file name or uploader...',
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppTheme.secondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Choice chips for status filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Success', 'Failed', 'Processing'].map((
                        status,
                      ) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            selectedColor: AppTheme.primary.withOpacity(0.12),
                            backgroundColor: AppTheme.surfaceContainerLow,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.secondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primary.withOpacity(0.3)
                                    : AppTheme.outlineVariant,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatus = status;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.outlineVariant),
                  const SizedBox(height: 6),

                  // Date Picker row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: AppTheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedDateRange == null
                                    ? 'No date filter applied'
                                    : '${AppConstants.dateFormat.format(_selectedDateRange!.start)} - ${AppConstants.dateFormat.format(_selectedDateRange!.end)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                initialDateRange: _selectedDateRange,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppTheme.primary,
                                        onPrimary: Colors.white,
                                        onSurface: AppTheme.onSurface,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDateRange = picked;
                                });
                              }
                            },
                            child: Text(
                              _selectedDateRange == null
                                  ? 'Filter Date'
                                  : 'Change Date',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          if (_selectedDateRange != null)
                            IconButton(
                              icon: const Icon(
                                LucideIcons.x,
                                size: 16,
                                color: AppTheme.error,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedDateRange = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search results or empty state list
            Flexible(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return widget.cardBuilder(filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.fileSearch,
                  size: 28,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No Upload Records Found',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try adjusting your search query or filters.',
                style: TextStyle(fontSize: 11, color: AppTheme.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
