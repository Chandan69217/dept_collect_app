import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../models/customer.dart';
import '../../models/recent_upload_item.dart';
import '../agent/customer_details_screen.dart';
import '../../widgets/custom_feedback.dart';

class UploadedRecordsView extends StatefulWidget {
  final RecentUploadItem selectedFile;

  const UploadedRecordsView({super.key, required this.selectedFile});

  @override
  State<UploadedRecordsView> createState() => _UploadedRecordsViewState();
}

// class RecordItem {
//   final String id;
//   final String loanId;
//   final String name;
//   final String status; // 'Unassigned', 'Assigned', 'In-Progress', 'Paid'
//   final double amount;
//   final String address;
//   final String phone;
//   final String? assignedAgentName;
//
//   RecordItem({
//     required this.id,
//     required this.loanId,
//     required this.name,
//     required this.status,
//     required this.amount,
//     required this.address,
//     required this.phone,
//     this.assignedAgentName,
//   });
// }

class _UploadedRecordsViewState extends State<UploadedRecordsView> {
  final _db = DatabaseService();
  String _searchQuery = '';
  String _statusFilter =
      'ALL'; // 'ALL', 'Unassigned', 'Assigned', 'In-Progress'
  String _sortBy = 'NEWEST'; // 'NEWEST', 'OLDEST', 'AMOUNT_DESC', 'AMOUNT_ASC'
  final Set<String> _selectedRecordIds = {};
  bool _isLoading = false;

  // Local overrides for mock record modifications (assignments and statuses)
  final Map<String, String> _mockAssignments = {};
  final Map<String, String> _mockStatuses = {};

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _db.fetchAgentsFromApi();
      await _db.fetchRecordsForFile(
        fileId: widget.selectedFile.fileId,
        limits: widget.selectedFile.totalRecords,
      );
    } catch (e) {
      if (mounted) {
        CustomFeedback.showToast(
          context,
          'Failed to load records: ${e.toString().replaceAll('Exception: ', '')}',
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        // Map database records to high-fidelity RecordItems (only if file is selected)
        final List<Customer> dbRecords = [];
        final currentFile = _db.recentUploadItem
            .where((f) => f.fileId == widget.selectedFile.fileId)
            .firstOrNull;
        final sourceCustomers =
            currentFile?.customers ?? widget.selectedFile.customers;

        for (final c in sourceCustomers) {
          String resolvedStatus = 'Assigned';
          if (c.status == 'Pending') {
            resolvedStatus = 'In-Progress';
          } else if (c.status == 'Completed' || c.status == 'Closed') {
            resolvedStatus = 'Paid';
          } else if (c.assignedAgentId.isEmpty ||
              c.assignedAgentId == 'unassigned') {
            resolvedStatus = 'Unassigned';
          }

          final String cleanId = c.id.replaceAll('cust_', '').toUpperCase();
          final String loanId = c.showLoanId
              ? (cleanId.length > 4 ? cleanId.substring(0, 4) : cleanId)
              : 'N/A';

          final agent = _db.agents
              .where((a) => a.id == c.assignedAgentId)
              .firstOrNull;

          dbRecords.add(
            c.copyWith(
              id: c.id,
              loanId: loanId,
              name: c.name,
              status: resolvedStatus,
              amountDue: c.amountDue,
              address: c.address,
              phone: c.phone,
              assignedAgentName: agent?.name ?? '',
            ),
          );
        }

        // Dynamic search, status filter, and sorting
        final List<Customer> filteredRecords = dbRecords.where((r) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch =
              r.name.toLowerCase().contains(query) ||
              r.loanId.toLowerCase().contains(query) ||
              r.address.toLowerCase().contains(query);

          final matchesStatus =
              _statusFilter == 'ALL' || r.status == _statusFilter;

          return matchesSearch && matchesStatus;
        }).toList();

        // Sort items
        filteredRecords.sort((a, b) {
          if (_sortBy == 'AMOUNT_DESC') {
            return b.amountDue.compareTo(a.amountDue);
          } else if (_sortBy == 'AMOUNT_ASC') {
            return a.amountDue.compareTo(b.amountDue);
          } else if (_sortBy == 'OLDEST') {
            return a.name.compareTo(b.name); // Alphabetical fallback
          } else {
            return b.name.compareTo(a.name); // Default fallback for 'NEWEST'
          }
        });

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(widget.selectedFile.fileName),
            actions: [
              IconButton(
                icon: const Icon(
                  LucideIcons.refreshCw,
                  color: AppTheme.primary,
                ),
                onPressed: _isLoading ? null : _refreshData,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading) CustomFeedback.showProgressIndicator(),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by ID or Customer Name...',
                          prefixIcon: const Icon(
                            LucideIcons.search,
                            size: 20,
                            color: AppTheme.outline,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          fillColor: const Color(0xFFF1F3F9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter Action Button
                    _buildHeaderButton(
                      icon: LucideIcons.filter,
                      label:
                          'Filter${_statusFilter == 'ALL' ? '' : ': $_statusFilter'}',
                      onPressed: () => _showFilterBottomSheet(context),
                      backgroundColor: Colors.white,
                      textColor: AppTheme.onSurfaceVariant,
                      hasBorder: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All Records', 'ALL', LucideIcons.inbox),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Unassigned',
                        'Unassigned',
                        LucideIcons.userX,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'In-Progress',
                        'In-Progress',
                        LucideIcons.timer,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Assigned',
                        'Assigned',
                        LucideIcons.userCheck,
                      ),
                    ],
                  ),
                ),
              ),

              // List Header (Showing and Sort selection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value:
                              filteredRecords.isNotEmpty &&
                              filteredRecords.every(
                                (r) => _selectedRecordIds.contains(r.id),
                              ),
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedRecordIds.addAll(
                                  filteredRecords.map((r) => r.id),
                                );
                              } else {
                                _selectedRecordIds.removeAll(
                                  filteredRecords.map((r) => r.id),
                                );
                              }
                            });
                          },
                        ),
                        Text(
                          'Showing ${filteredRecords.length} records',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Sort: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondary,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            icon: const Icon(
                              LucideIcons.chevronDown,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'NEWEST',
                                child: Text('Newest First'),
                              ),
                              DropdownMenuItem(
                                value: 'OLDEST',
                                child: Text('Oldest First'),
                              ),
                              DropdownMenuItem(
                                value: 'AMOUNT_DESC',
                                child: Text('Amount: High to Low'),
                              ),
                              DropdownMenuItem(
                                value: 'AMOUNT_ASC',
                                child: Text('Amount: Low to High'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortBy = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Bulk Actions Panel
              if (_selectedRecordIds.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      border: Border.all(
                        color: AppTheme.error.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedRecordIds.length} records selected',
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
                                  _selectedRecordIds.clear();
                                });
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () =>
                                  _confirmBulkDeleteRecords(filteredRecords),
                              icon: const Icon(LucideIcons.trash2, size: 14),
                              label: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Records Cards List - Scrolls with page fluidly
              Expanded(
                child: filteredRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.folderOpen,
                              size: 48,
                              color: AppTheme.outline.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching ledger entries found',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 32.0,
                        ),
                        itemCount: filteredRecords.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return _buildRecordCard(record);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
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
        border: hasBorder
            ? Border.all(color: AppTheme.outlineVariant, width: 1)
            : null,
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

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppTheme.outlineVariant,
          width: 1,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
    );
  }

  Customer _createMockCustomerFromRecord(Customer record) {
    final agent = _db.agents
        .where((a) => a.id == record.assignedAgentId)
        .firstOrNull;
    return Customer(
      id: record.id,
      name: record.name,
      amountDue: record.amountDue,
      dueDate: DateTime.now().subtract(const Duration(days: 15)),
      overdueDays: 15,
      address: record.address,
      phone: record.phone,
      priority: record.amountDue > 100000.0 ? 'HIGH' : 'MEDIUM',
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      lat: 19.0760,
      lng: 72.8777,
      assignedAgentId: record.assignedAgentName.isNotEmpty
          ? 'miller'
          : 'unassigned',
      status: record.status == 'Paid'
          ? 'Completed'
          : (record.status == 'In-Progress'
                ? 'Pending'
                : 'Assigned'),
      notes: [
        'Uploaded record parsed from debt ledger.',
        'Verification of address complete.',
      ],
      assignedAgentName: agent?.name ?? '',
    );
  }

  void _confirmDeleteRecord(Customer record) {
    CustomFeedback.showFeedbackDialog(
      context,
      title: 'Delete Record?',
      message:
          'Are you sure you want to delete ${record.name}\'s ledger record (${record.loanId})? This action is permanent.',
      type: 'error',
      confirmLabel: 'DELETE',
      onConfirm: () async {
        try {
          await _db.deleteCase(widget.selectedFile.fileId, record.id);

          setState(() {
            _selectedRecordIds.remove(record.id);
          });

          if (mounted) {
            CustomFeedback.showToast(
              context,
              '${record.name}\'s record was successfully deleted.',
              type: 'success',
            );
          }
        } catch (e) {
          if (mounted) {
            CustomFeedback.showToast(
              context,
              'Failed to delete record: ${e.toString().replaceAll('Exception: ', '')}',
              type: 'error',
            );
          }
        }
      },
    );
  }

  void _confirmBulkDeleteRecords(List<Customer> filteredRecords) {
    final count = _selectedRecordIds.length;
    CustomFeedback.showFeedbackDialog(
      context,
      title: 'Delete Selected Records?',
      message:
          'Are you sure you want to delete all $count selected ledger records permanently? This cannot be undone.',
      type: 'error',
      confirmLabel: 'DELETE ALL',
      onConfirm: () async {
        final List<String> selectedIds = _selectedRecordIds.toList();

        try {
          await _db.deleteMultipleCases(
            widget.selectedFile.fileId,
            selectedIds,
          );

          setState(() {
            _selectedRecordIds.clear();
          });

          if (mounted) {
            CustomFeedback.showToast(
              context,
              'Successfully deleted $count ledger records.',
              type: 'error',
            );
          }
        } catch (e) {
          if (mounted) {
            CustomFeedback.showToast(
              context,
              'Failed to delete records: ${e.toString().replaceAll('Exception: ', '')}',
              type: 'error',
            );
          }
        }
      },
    );
  }

  Widget _buildRecordCard(Customer record) {
    // Styling attributes based on status - Gorgeous vibrant HSL colors
    Color chipBg;
    Color chipText;
    if (record.status == 'Unassigned') {
      chipBg = const Color(0xFFFFDAD6);
      chipText = const Color(0xFFBA1A1A);
    } else if (record.status == 'In-Progress') {
      chipBg = const Color(0xFFFFF3E0);
      chipText = const Color(0xFFE65100);
    } else if (record.status == 'Paid') {
      chipBg = const Color(0xFFE8F5E9);
      chipText = const Color(0xFF2E7D32);
    } else {
      // Assigned
      chipBg = const Color(0xFFEFF4FF);
      chipText = AppTheme.primary;
    }

    final isChecked = _selectedRecordIds.contains(record.id);

    return CustomBentoCard(
      padding: 0,
      onTap: () {
        setState(() {
          if (isChecked) {
            _selectedRecordIds.remove(record.id);
          } else {
            _selectedRecordIds.add(record.id);
          }
        });
      },
      onLongPress: () => _showReassignDialog(record),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox Container
            Container(
              margin: const EdgeInsets.only(top: 2.0),
              width: 24,
              height: 24,
              child: Checkbox(
                value: isChecked,
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedRecordIds.add(record.id);
                    } else {
                      _selectedRecordIds.remove(record.id);
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),

            // Card Body content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row (Loan ID + Status Chip)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Loan ID: ${record.loanId}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.outline,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          record.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: chipText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Customer Name
                  Text(
                    record.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),

                  // Subtitle address description
                  if (record.assignedAgentName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.headset,
                          size: 14,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned to: ${record.assignedAgentName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.triangleAlert,
                          size: 14,
                          color: AppTheme.error,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Pending deployment assignment',
                          style: TextStyle(fontSize: 11, color: AppTheme.error),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.outlineVariant),
                  const SizedBox(height: 12),

                  // Bottom Row (Principal Amount + Chevron Button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Principal Amount',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${record.amountDue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Single Record Delete Button
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: AppTheme.error,
                            ),
                            onPressed: () => _confirmDeleteRecord(record),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              final customer = _db.customers.firstWhere(
                                (c) => c.id == record.id,
                                orElse: () =>
                                    _createMockCustomerFromRecord(record),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CustomerDetailsScreen(customer: customer),
                                ),
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.outlineVariant,
                                ),
                                color: AppTheme.primary.withOpacity(0.04),
                              ),
                              child: const Icon(
                                LucideIcons.chevronRight,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption(
                'All Ledger Entries',
                'ALL',
                LucideIcons.inbox,
              ),
              _buildFilterOption(
                'Unassigned Cases',
                'Unassigned',
                LucideIcons.userX,
              ),
              _buildFilterOption(
                'Assigned Portfolio',
                'Assigned',
                LucideIcons.userCheck,
              ),
              _buildFilterOption(
                'In-Progress Verification',
                'In-Progress',
                LucideIcons.timerReset,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final isSelected = _statusFilter == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primary : AppTheme.secondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? const Icon(LucideIcons.check, color: AppTheme.primary)
          : null,
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showReassignDialog(Customer record) {
    CustomFeedback.showFeedbackDialog(
      context,
      title: record.status == 'Unassigned'
          ? 'Assign Debtor Portfolio'
          : 'Reassign Portfolio',
      message: '',
      type: 'info',
      showCancel: false,
      confirmLabel: 'CANCEL',
      customBody: SizedBox(
        width: 300,
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debtor Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Loan ID: ${record.loanId} • ₹${record.amountDue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: record.status == 'Unassigned'
                          ? AppTheme.errorContainer
                          : AppTheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.status,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: record.status == 'Unassigned'
                            ? AppTheme.error
                            : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SELECT ACTIVE AGENT TO DEPLOY:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.outline,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Active Agents list from Database
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _db.agents.where((a) => !a.isAdmin).length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final agent = _db.agents
                      .where((a) => !a.isAdmin)
                      .toList()[index];
                  final isCurrentlyAssigned =
                      record.assignedAgentName == agent.name;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(agent.avatarUrl),
                    ),
                    title: Text(
                      agent.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Zone: ${agent.zone} • ${agent.casesCount} active cases',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondary,
                      ),
                    ),
                    trailing: isCurrentlyAssigned
                        ? const Icon(
                            LucideIcons.checkCircle,
                            color: AppTheme.primary,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Deploy',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                    onTap: () async {
                      final localContext = context;
                      if (isCurrentlyAssigned) {
                        CustomFeedback.showFeedbackDialog(
                          localContext,
                          title: 'Delete Assignment',
                          message: 'Are you sure you want to remove the assignment of this case to ${agent.name}?',
                          type: 'warning',
                          confirmLabel: 'DELETE',
                          cancelLabel: 'CANCEL',
                          showCancel: true,
                          onConfirm: () async {
                            if (!localContext.mounted) return;
                            try {
                              Navigator.pop(localContext); // Close the deploy list dialog
                              setState(() {
                                _isLoading = true;
                              });
                              if (!record.id.startsWith('cust_')) {
                                await _db.unassignCase(record.id);
                              } else {
                                setState(() {
                                  _mockAssignments.remove(record.id);
                                  _mockStatuses[record.id] = 'Unassigned';
                                });
                              }
                              if (localContext.mounted) {
                                CustomFeedback.showToast(
                                  localContext,
                                  'Assignment successfully removed.',
                                  type: 'success',
                                );
                              }
                            } catch (e) {
                              if (localContext.mounted) {
                                CustomFeedback.showToast(
                                  localContext,
                                  'Failed to remove assignment: ${e.toString().replaceAll('Exception: ', '')}',
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
                        return;
                      }

                      // Action reassign
                      try {
                        if (!record.id.startsWith('cust_')) {
                          // Reassign actual database customer!
                          await _db.assignCase(record.id, agent.id);
                        } else {
                          // Reassign static mock local override!
                          setState(() {
                            _mockAssignments[record.id] = agent.id;
                            _mockStatuses[record.id] = 'Assigned';
                          });
                        }

                        if (localContext.mounted) {
                          Navigator.pop(localContext);
                          CustomFeedback.showToast(
                            localContext,
                            '${record.name} portfolio successfully deployed to ${agent.name}.',
                            type: 'success',
                          );
                        }
                      } catch (e) {
                        if (localContext.mounted) {
                          Navigator.pop(localContext);
                          CustomFeedback.showToast(
                            localContext,
                            'Failed to deploy case: ${e.toString().replaceAll('Exception: ', '')}',
                            type: 'error',
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
