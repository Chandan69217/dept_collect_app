import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_bento_card.dart';
import 'verify_uploaded_records_screen.dart';

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

  void _pickMockFile() {
    setState(() {
      _selectedFileName = 'Q3_SouthZone_Debtors.csv';
      _uploadComplete = false;
    });
    _startUploadSimulation();
  }

  void _startUploadSimulation() {
    if (_selectedFileName == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate parse progress increments
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return false;

      setState(() {
        _uploadProgress += 0.15;
      });

      if (_uploadProgress >= 1.0) {
        setState(() {
          _isUploading = false;
          _uploadComplete = true;
        });
        return false;
      }
      return true;
    });
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
          'Agency Admin',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All historical imports cataloged.'),
                      ),
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
      onTap: _pickMockFile,
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
              'Supports .xlsx and .csv formats',
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
              onPressed: _pickMockFile,
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
                const Text(
                  'Parsing Ledger Structures...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.onSurface,
                  ),
                ),
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
            _selectedFileName ?? 'Q3_SouthZone_Debtors.csv',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          _buildReportRow(
            'Total Rows Scanned',
            '${_mockImportRecords.length + 3}',
          ),
          const SizedBox(height: 10),
          _buildReportRow(
            'New Debtor Accounts',
            '${_mockImportRecords.length}',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          _buildReportRow(
            'Duplicate Entries Skipped',
            '3',
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 10),
          _buildReportRow(
            'Validation Syntax Errors',
            '0',
            color: AppTheme.success,
          ),
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
