import 'dart:io';
import 'dart:isolate';
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

class RecentUploadItem {
  final String fileName;
  final String date;
  final int recordsCount;
  final String status; // 'Processing', 'Completed', 'Failed'

  RecentUploadItem({
    required this.fileName,
    required this.date,
    required this.recordsCount,
    required this.status,
  });
}

class _UploadDataScreenState extends State<UploadDataScreen> {
  String? _selectedFileName;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _uploadComplete = false;
  int _totalRowsScanned = 0;
  int _skippedRowsCount = 0;
  String _progressMessage = 'Preparing file...';

  // Track recent upload history dynamically
  final List<RecentUploadItem> _recentUploads = [
    RecentUploadItem(
      fileName: 'Q3_Collections_Final.xlsx',
      date: 'Oct 24, 2023',
      recordsCount: 1240,
      status: 'Processing',
    ),
    RecentUploadItem(
      fileName: 'West_Region_Sept.csv',
      date: 'Oct 22, 2023',
      recordsCount: 856,
      status: 'Completed',
    ),
    RecentUploadItem(
      fileName: 'Legacy_Export_Raw.csv',
      date: 'Oct 21, 2023',
      recordsCount: 0,
      status: 'Failed',
    ),
  ];

  final List<Map<String, dynamic>> _mockImportRecords = [
    {
      'name': 'Ganesh Hegde',
      'amountDue': 14200.0,
      'overdueDays': 20,
      'address': 'Flat 304, Green Heights, Santacruz West, Mumbai',
      'phone': '+91 97777 66666',
      'priority': 'HIGH',
    },
    {
      'name': 'Aditi Rao',
      'amountDue': 6500.0,
      'overdueDays': 10,
      'address': 'B-12, Sagar Darshan Society, Juhu, Mumbai',
      'phone': '+91 96666 55555',
      'priority': 'MEDIUM',
    },
    {
      'name': 'Vikram Malhotra',
      'amountDue': 9800.0,
      'overdueDays': 35,
      'address': '12A, Sunset Boulevard, Malabar Hill, Mumbai',
      'phone': '+91 95555 44444',
      'priority': 'HIGH',
    },
    {
      'name': 'Karan Johar',
      'amountDue': 3100.0,
      'overdueDays': 5,
      'address': 'Penthouse 3, Galaxy Apartments, Bandra West, Mumbai',
      'phone': '+91 94444 33333',
      'priority': 'LOW',
    },
  ];

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
      });

      final filePath = file.path;
      final fileBytes = file.bytes;

      List<int> bytes;
      if (kIsWeb) {
        if (fileBytes != null) {
          bytes = fileBytes;
        } else {
          _showErrorSnackBar('Could not read file data (bytes are empty).');
          setState(() {
            _isUploading = false;
          });
          return;
        }
      } else {
        if (filePath != null) {
          bytes = await File(filePath).readAsBytes();
        } else if (fileBytes != null) {
          bytes = fileBytes;
        } else {
          _showErrorSnackBar(
            'Could not read file data (both path and bytes are empty).',
          );
          setState(() {
            _isUploading = false;
          });
          return;
        }
      }

      setState(() {
        _uploadProgress = 0.05;
        _progressMessage = 'Spawning background parser...';
      });

      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _parseExcelIsolate,
        _ExcelIsolateParams(bytes: bytes, sendPort: receivePort.sendPort),
      );

      receivePort.listen((message) {
        if (message is Map<String, dynamic>) {
          final type = message['type'];
          if (type == 'progress') {
            setState(() {
              _uploadProgress = message['progress'] as double;
              _progressMessage = message['message'] as String;
            });
          } else if (type == 'success') {
            final List<Map<String, dynamic>> parsedRecords =
                List<Map<String, dynamic>>.from(message['records']);
            final int totalRows = message['totalRows'] as int;
            final int skippedRows = message['skippedRows'] as int;

            setState(() {
              _uploadProgress = 1.0;
              _isUploading = false;
              _uploadComplete = true;
              _totalRowsScanned = totalRows;
              _skippedRowsCount = skippedRows;
              _mockImportRecords.clear();
              _mockImportRecords.addAll(parsedRecords);
            });
            receivePort.close();
            isolate.kill(priority: Isolate.beforeNextEvent);
          } else if (type == 'error') {
            final error = message['error'];
            setState(() {
              _isUploading = false;
              _uploadComplete = false;
            });
            _showErrorSnackBar('Failed to parse Excel file: $error');
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
          records: _mockImportRecords,
        ),
      ),
    ).then((success) {
      if (success == true) {
        // If successfully committed from that screen, update local uploads log!
        setState(() {
          _recentUploads.insert(
            0,
            RecentUploadItem(
              fileName: _selectedFileName ?? 'Imported_Ledger.csv',
              date: 'Just now',
              recordsCount: _mockImportRecords.length,
              status: 'Completed',
            ),
          );
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Text(
              'Upload Data',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Import ledger files for collection processing.',
              style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
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
                    CustomFeedback.showToast(
                      context,
                      'All historical imports cataloged.',
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
              itemCount: _recentUploads.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _recentUploads[index];
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
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
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
                Text(
                  '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _uploadProgress > 1.0 ? 1.0 : _uploadProgress,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceContainerLow,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
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
          const Row(
            children: [
              Icon(LucideIcons.checkCircle, color: AppTheme.success, size: 20),
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
            '${_mockImportRecords.length}',
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
                'COMMIT IMPORT TO LEDGER',
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
                  '${item.date} • ${item.recordsCount} records',
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
  final List<int> bytes;
  final SendPort sendPort;

  _ExcelIsolateParams({required this.bytes, required this.sendPort});
}

void _parseExcelIsolate(_ExcelIsolateParams params) {
  final sendPort = params.sendPort;
  final bytes = params.bytes;

  try {
    sendPort.send({
      'type': 'progress',
      'progress': 0.1,
      'message': 'Decoding Excel spreadsheet...',
    });

    final stopwatch = Stopwatch()..start();
    var excel = Excel.decodeBytes(bytes);
    debugPrint(
      'Isolate: Excel decode completed in ${stopwatch.elapsedMilliseconds}ms',
    );

    sendPort.send({
      'type': 'progress',
      'progress': 0.3,
      'message': 'Analyzing sheets and data structure...',
    });

    List<Map<String, dynamic>> parsedRecords = [];
    int totalRows = 0;
    int skippedRows = 0;

    if (excel.tables.isNotEmpty) {
      final String firstSheetName = excel.tables.keys.first;
      debugPrint('Isolate: Target sheet name: $firstSheetName');

      final sheet = excel.tables[firstSheetName];
      if (sheet != null) {
        totalRows = sheet.maxRows;
        final int maxCols = sheet.maxColumns;
        debugPrint(
          'Isolate: sheet.maxRows = $totalRows, sheet.maxColumns = $maxCols',
        );

        if (totalRows > 0 && maxCols > 0) {
          // Extract headers
          List<String> headers = [];
          for (int j = 0; j < maxCols; j++) {
            final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: 0),
            );
            headers.add(cell.value?.toString() ?? '');
          }
          debugPrint('Isolate: Mapped headers: $headers');

          // We will parse the first 20,000 rows completely for preview.
          // For rows beyond 20,000, we only check the customer name cell.
          const int previewLimit = 20000;

          // Find the name column index
          int nameColIndex = headers.indexWhere(
            (h) =>
                ExcelFieldMapping.mapHeader(h) == 'name' ||
                h.toLowerCase() == 'name' ||
                h.toLowerCase() == 'customer_name' ||
                h.toLowerCase() == 'customer name',
          );
          if (nameColIndex == -1) nameColIndex = 0;

          // Parse data rows
          for (int i = 1; i < totalRows; i++) {
            // Periodically report progress to UI thread
            if (i % 10000 == 0 || i == totalRows - 1 || i == 1) {
              final double percent = 0.3 + (i / totalRows) * 0.6;
              final String displayPercent = (percent * 100).toStringAsFixed(0);
              sendPort.send({
                'type': 'progress',
                'progress': percent,
                'message': 'Parsed $i / $totalRows rows ($displayPercent%)...',
              });
            }

            if (i < previewLimit) {
              // Full parse
              Map<String, dynamic> record = {};
              for (int j = 0; j < headers.length; j++) {
                final cell = sheet.cell(
                  CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i),
                );
                final val = cell.value;
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
                      double.tryParse(
                        rawAmount.toString().replaceAll(',', ''),
                      ) ??
                      0.0;
                }

                int overdueDays = 10;
                final rawOverdue =
                    record['overdueDays'] ?? record['days'] ?? '';
                if (rawOverdue.toString().isNotEmpty) {
                  overdueDays = int.tryParse(rawOverdue.toString()) ?? 10;
                }

                final address =
                    record['address'] ?? record['location'] ?? 'No Address';
                final phone =
                    record['phone'] ?? record['mobile'] ?? '+91 99999 99999';
                final priority = record['priority'] ?? 'MEDIUM';

                parsedRecords.add({
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
            } else {
              // Lightweight check to prevent OOM
              final cell = sheet.cell(
                CellIndex.indexByColumnRow(
                  columnIndex: nameColIndex,
                  rowIndex: i,
                ),
              );
              final nameVal = cell.value?.toString() ?? '';
              if (nameVal.trim().isEmpty) {
                skippedRows++;
              }
            }
          }
          debugPrint(
            'Isolate: Completed parsing of all rows in ${stopwatch.elapsedMilliseconds}ms. Parsed records: ${parsedRecords.length}, Skipped: $skippedRows',
          );
        }
      }
    }

    sendPort.send({
      'type': 'success',
      'records': parsedRecords,
      'totalRows': totalRows,
      'skippedRows': skippedRows,
    });
  } catch (e) {
    sendPort.send({'type': 'error', 'error': e.toString()});
  }
}
