import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../models/recent_upload_item.dart';
import '../../constants/app_constants.dart';
import 'upload_data_screen.dart';
import 'uploaded_records_view.dart';
import 'case_assignment_screen.dart';
import '../../widgets/custom_feedback.dart';

class UploadedFilesScreen extends StatefulWidget {
  final bool isForCaseAssignment;
  final bool isEmbedded;

  const UploadedFilesScreen({
    super.key,
    required this.isForCaseAssignment,
    this.isEmbedded = false,
  });

  @override
  State<UploadedFilesScreen> createState() => _UploadedFilesScreenState();
}

class _UploadedFilesScreenState extends State<UploadedFilesScreen> {
  final _db = DatabaseService();
  String _fileSearchQuery = '';
  String _dateFilterType = 'All'; // 'All', 'Today', 'Yesterday', 'This Week', 'This Month', 'Custom'
  DateTimeRange? _selectedDateRange;
  final Set<int> _selectedFileIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _db.fetchRecentUploads();
    } catch (e) {
      if (mounted) {
        CustomFeedback.showToast(
          context,
          'Failed to load files: ${e.toString().replaceAll('Exception: ', '')}',
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

  void _confirmDeleteFiles() {
    final count = _selectedFileIds.length;
    CustomFeedback.showFeedbackDialog(
      context,
      title: 'Delete Selected Files?',
      message: 'Are you sure you want to delete all $count selected files permanently? This will remove all associated customer records and cannot be undone.',
      type: 'error',
      confirmLabel: 'DELETE ALL',
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });
        try {
          await _db.deleteMultipleFiles(_selectedFileIds.toList());
          setState(() {
            _selectedFileIds.clear();
          });
          if (mounted) {
            CustomFeedback.showToast(
              context,
              'Successfully deleted $count files.',
              type: 'success',
            );
          }
        } catch (e) {
          if (mounted) {
            CustomFeedback.showToast(
              context,
              'Failed to delete files: ${e.toString().replaceAll('Exception: ', '')}',
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
      },
    );
  }

  void _selectFile(RecentUploadItem item) {
    if (widget.isForCaseAssignment) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaseAssignmentScreen(selectedFile: item),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadedRecordsView(selectedFile: item),
        ),
      );
    }
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
    required bool hasBorder,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: hasBorder ? Border.all(color: AppTheme.outlineVariant, width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBody = ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        final filteredFiles = _db.recentUploadItem.where((f) {
          // 1. Search filter
          if (_fileSearchQuery.isNotEmpty &&
              !f.fileName.toLowerCase().contains(_fileSearchQuery.toLowerCase())) {
            return false;
          }

          // 2. Date filter
          switch (_dateFilterType) {
            case 'Today':
              return f.createdAt.isAfter(todayStart);
            case 'Yesterday':
              final yesterdayStart = todayStart.subtract(const Duration(days: 1));
              return f.createdAt.isAfter(yesterdayStart) && f.createdAt.isBefore(todayStart);
            case 'This Week':
              final weekStart = todayStart.subtract(const Duration(days: 7));
              return f.createdAt.isAfter(weekStart);
            case 'This Month':
              final monthStart = DateTime(now.year, now.month, 1);
              return f.createdAt.isAfter(monthStart);
            case 'Custom':
              if (_selectedDateRange != null) {
                final endLimit = DateTime(
                  _selectedDateRange!.end.year,
                  _selectedDateRange!.end.month,
                  _selectedDateRange!.end.day,
                  23, 59, 59, 999,
                );
                return f.createdAt.isAfter(_selectedDateRange!.start) &&
                    f.createdAt.isBefore(endLimit);
              }
              return true;
            case 'All':
            default:
              return true;
          }
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) CustomFeedback.showProgressIndicator(),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isForCaseAssignment ? 'Select File for Assignment' : 'Uploaded Excels Files',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isForCaseAssignment
                        ? 'Select an uploaded ledger file to allocate debtor cases'
                        : 'Review and manage your uploaded Excel sheets',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _fileSearchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search files by name...',
                            prefixIcon: const Icon(
                              LucideIcons.search, size: 20, color: AppTheme.outline),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            fillColor: const Color(0xFFF1F3F9),
                            


                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date Filter Dropdown (Popup Menu Button)
                      Container(
                        decoration: BoxDecoration(
                          color: _dateFilterType == 'All' ? const Color(0xFFF1F3F9) : AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            LucideIcons.calendarRange,
                            color: _dateFilterType == 'All' ? AppTheme.onSurfaceVariant : AppTheme.primary,
                            size: 20,
                          ),
                          tooltip: 'Filter by Date',
                          onSelected: (String value) async {
                            if (value == 'Custom') {
                              final pickedRange = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: _selectedDateRange,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppTheme.primary,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: AppTheme.onSurface,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedRange != null) {
                                setState(() {
                                  _dateFilterType = 'Custom';
                                  _selectedDateRange = pickedRange;
                                });
                              }
                            } else {
                              setState(() {
                                _dateFilterType = value;
                                _selectedDateRange = null;
                              });
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'All',
                              child: Text('All Time'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Today',
                              child: Text('Today'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Yesterday',
                              child: Text('Yesterday'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'This Week',
                              child: Text('Last 7 Days'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'This Month',
                              child: Text('This Month'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'Custom',
                              child: Text('Custom Range...'),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isForCaseAssignment) ...[
                        const SizedBox(width: 8),
                        _buildHeaderButton(
                          icon: LucideIcons.upload,
                          label: 'Import',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UploadDataScreen()),
                            );
                            _fetchFiles();
                          },
                          backgroundColor: AppTheme.primary,
                          textColor: Colors.white,
                          hasBorder: false,
                        ),
                      ],
                    ],
                  ),
                  if (_dateFilterType != 'All')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Chip(
                        label: Text(
                          _dateFilterType == 'Custom' && _selectedDateRange != null
                              ? 'Date: ${AppConstants.dateFormat.format(_selectedDateRange!.start)} - ${AppConstants.dateFormat.format(_selectedDateRange!.end)}'
                              : 'Date: $_dateFilterType',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                        backgroundColor: AppTheme.primary.withOpacity(0.08),
                        deleteIcon: const Icon(LucideIcons.x, size: 14, color: AppTheme.primary),
                        onDeleted: () {
                          setState(() {
                            _dateFilterType = 'All';
                            _selectedDateRange = null;
                          });
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide.none,
                      ),
                    ),
                ],
              ),
            ),
            if (!widget.isForCaseAssignment && _selectedFileIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedFileIds.length} files selected',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedFileIds.clear();
                              });
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _confirmDeleteFiles,
                            icon: const Icon(LucideIcons.trash2, size: 14),
                            label: const Text(
                              'Delete Selected',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchFiles,
                color: AppTheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: filteredFiles.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: 250,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.folderOpen, size: 48, color: AppTheme.outline.withOpacity(0.5)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No files found',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredFiles.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final fileItem = filteredFiles[index];
                            final isChecked = _selectedFileIds.contains(fileItem.fileId);

                            return CustomBentoCard(
                              padding: 0,
                              onTap: () => _selectFile(fileItem),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    if (!widget.isForCaseAssignment) ...[
                                      Checkbox(
                                        value: isChecked,
                                        activeColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedFileIds.add(fileItem.fileId);
                                            } else {
                                              _selectedFileIds.remove(fileItem.fileId);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LucideIcons.fileSpreadsheet,
                                        color: AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fileItem.fileName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppTheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Records: ${fileItem.totalRecords} • Uploaded: ${fileItem.formattedDate}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!widget.isForCaseAssignment) ...[
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, color: AppTheme.error, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _selectedFileIds.add(fileItem.fileId);
                                          });
                                          _confirmDeleteFiles();
                                        },
                                      ),
                                    ],
                                    const Icon(
                                      LucideIcons.chevronRight,
                                      color: AppTheme.outline,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.isEmbedded) {
      return scaffoldBody;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isForCaseAssignment ? 'Cases File Selection' : 'Manage Ledgers',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
      body: scaffoldBody,
    );
  }
}
