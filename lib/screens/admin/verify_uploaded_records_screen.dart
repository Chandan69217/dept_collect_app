import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_feedback.dart';
import '../../config/field_mapping.dart';

class VerifyUploadedRecordsScreen extends StatefulWidget {
  final String fileName;
  final List<Map<String, dynamic>> records;

  const VerifyUploadedRecordsScreen({
    super.key,
    required this.fileName,
    required this.records,
  });

  @override
  State<VerifyUploadedRecordsScreen> createState() =>
      _VerifyUploadedRecordsScreenState();
}

class _VerifyUploadedRecordsScreenState
    extends State<VerifyUploadedRecordsScreen> {
  final _db = DatabaseService();
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final Set<int> _selectedIndices = {};

  // Cache structure for fast lookup and filtering
  final List<_RecordCache> _cachedRecords = [];

  // Column visibility flags
  final Map<String, bool> _fieldVisibility = {};
  bool _showLoanId = true;

  // Metadata mapping for known keys with dynamic camelCase fallback
  Map<String, dynamic> _getFieldMetadata(String key) {
    switch (key) {
      case 'name':
        return {
          'title': 'Debtor Name',
          'description': 'Full legal identity of the debtor',
          'icon': LucideIcons.user,
        };
      case 'amountDue':
        return {
          'title': 'Amount',
          'description': 'Total outstanding ledger balance',
          'icon': LucideIcons.banknote,
        };
      case 'phone':
        return {
          'title': 'Contact Phone',
          'description': 'Primary telephone notification digits',
          'icon': LucideIcons.phone,
        };
      case 'address':
        return {
          'title': 'Debtor Address',
          'description': 'Location or residence of the debtor',
          'icon': LucideIcons.mapPin,
        };
      case 'overdueDays':
        return {
          'title': 'Overdue Days',
          'description': 'Number of days payment is overdue',
          'icon': LucideIcons.calendarClock,
        };
      case 'priority':
        return {
          'title': 'Priority',
          'description': 'Assigned Urgency / Priority level',
          'icon': LucideIcons.alertTriangle,
        };
      case 'assetModel':
        return {
          'title': 'Asset Model',
          'description': 'Mapped asset model reference info',
          'icon': LucideIcons.car,
        };
      case 'assetRegNo':
        return {
          'title': 'Asset Reg No',
          'description': 'Mapped asset registration number details',
          'icon': LucideIcons.hash,
        };
      case 'assetVariant':
        return {
          'title': 'Asset Variant',
          'description': 'Mapped asset specification variant configuration',
          'icon': LucideIcons.layers,
        };
      case 'engineNumber':
        return {
          'title': 'Engine Number',
          'description': 'Mapped asset engine block identifier key',
          'icon': LucideIcons.activity,
        };
      case 'chasisNumber':
        return {
          'title': 'Chassis Number',
          'description': 'Mapped asset chassis serial structural ID',
          'icon': LucideIcons.shieldAlert,
        };
      default:
        final camelCaseRegex = RegExp(r'(^[a-z]+|[A-Z][a-z]*)');
        final matches = camelCaseRegex.allMatches(key);
        String label = key;
        if (matches.isNotEmpty) {
          label = matches
              .map((m) {
                final s = m.group(0) ?? '';
                if (s.isEmpty) return s;
                return s[0].toUpperCase() + s.substring(1);
              })
              .join(' ');
        } else {
          label = key.isNotEmpty
              ? key[0].toUpperCase() + key.substring(1)
              : key;
        }
        return {
          'title': label,
          'description': 'Mapped $label column from source file',
          'icon': LucideIcons.hash,
        };
    }
  }

  // Filter criteria
  String _selectedStatusFilter =
      'All'; // 'All', 'New', 'Matched', 'Discrepancy'
  double? _minAmount;
  double? _maxAmount;
  String _selectedDateFilter =
      'Today'; // 'Today', 'Last 7 Days', 'Custom Range'
  bool _isUploading = false;

  // Match mappings (1st item Ganesh Hegde is discrepancy, 2nd is matched, 3rd is new, 4th is new)
  final Set<int> _matchedIndices = {1};
  final Set<int> _discrepancyIndices = {0};

  @override
  void initState() {
    super.initState();
    // Initialize visibility flags from global ExcelFieldMapping
    for (final key in ExcelFieldMapping.mapping.keys) {
      _fieldVisibility[key] = true;
    }
    _precomputeCache();
  }

  void _precomputeCache() {
    _cachedRecords.clear();
    _selectedIndices.clear();

    for (int i = 0; i < widget.records.length; i++) {
      final r = widget.records[i];

      // Safe name extraction
      final String name = r['name']?.toString() ?? 'No Name';
      final String nameLower = name.toLowerCase();

      // Safe phone extraction
      final String phone = r['phone']?.toString() ?? '';

      // Safe loan ID calculation
      final hashStr = name.hashCode.abs().toString();
      final cleanHash = hashStr.length > 5 ? hashStr.substring(0, 5) : hashStr;
      final loanIdDisplay = '#LN-88$cleanHash';
      final loanIdLower = loanIdDisplay.toLowerCase();

      // Safe status calculation
      String status;
      if (_discrepancyIndices.contains(i)) {
        status = 'Discrepancy';
      } else if (_matchedIndices.contains(i)) {
        status = 'Matched';
      } else {
        status = 'New Record';
      }

      // Safe amountDue parsing
      double amount = 0.0;
      if (r['amountDue'] != null) {
        if (r['amountDue'] is num) {
          amount = (r['amountDue'] as num).toDouble();
        } else {
          amount =
              double.tryParse(r['amountDue'].toString().replaceAll(',', '')) ??
              0.0;
        }
      }

      _cachedRecords.add(
        _RecordCache(
          record: r,
          nameLower: nameLower,
          phone: phone,
          loanId: loanIdLower,
          loanIdDisplay: loanIdDisplay,
          status: status,
          amountDue: amount,
        ),
      );

      _selectedIndices.add(i);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getLoanId(Map<String, dynamic> record, int index) {
    // Generate stable Loan ID based on hash
    final name = record['name']?.toString() ?? 'Unknown debtor';
    final hashStr = name.hashCode.abs().toString();
    final cleanHash = hashStr.length > 5 ? hashStr.substring(0, 5) : hashStr;
    return '#LN-88$cleanHash';
  }

  String _getStatus(int index) {
    if (_discrepancyIndices.contains(index)) {
      return 'Discrepancy';
    } else if (_matchedIndices.contains(index)) {
      return 'Matched';
    } else {
      return 'New Record';
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) {
        return _FilterUploadedSheet(
          initialStatus: _selectedStatusFilter,
          initialMinAmount: _minAmount,
          initialMaxAmount: _maxAmount,
          initialDateFilter: _selectedDateFilter,
          onApply: (status, min, max, date) {
            setState(() {
              _selectedStatusFilter = status;
              _minAmount = min;
              _maxAmount = max;
              _selectedDateFilter = date;
            });
          },
        );
      },
    );
  }

  void _showManageFieldsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) {
        return _ManageImportFieldsSheet(
          fieldVisibility: Map<String, bool>.from(_fieldVisibility),
          showLoanId: _showLoanId,
          onSave: (updatedVisibility, loanId) {
            setState(() {
              _fieldVisibility.clear();
              _fieldVisibility.addAll(updatedVisibility);
              _showLoanId = loanId;
            });
          },
        );
      },
    );
  }

  Future<void> _confirmAndImport() async {
    if (_isUploading) return;

    // Collect and filter records according to field visibility
    final List<Map<String, dynamic>> processedRecords = [];
    for (int index in _selectedIndices) {
      if (index >= 0 && index < widget.records.length) {
        final record = widget.records[index];
        final copy = Map<String, dynamic>.from(record);

        // Nullify fields whose visibility is turned off
        for (final entry in _fieldVisibility.entries) {
          final key = entry.key;
          final isVisible = entry.value;
          if (!isVisible) {
            copy[key] = null;
          }
        }

        // Handle Loan ID toggle - pass showLoanId preference in record Map
        copy['showLoanId'] = _showLoanId;

        processedRecords.add(copy);
      }
    }

    if (processedRecords.isEmpty) {
      CustomFeedback.showToast(
        context,
        'Please select at least one record to import.',
        type: 'error',
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Commit to global database service (first saves to API then local db)
      await _db.uploadBankRecords(widget.fileName, processedRecords);

      if (!mounted) return;

      CustomFeedback.showFeedbackDialog(
        context,
        title: 'Import Successful',
        message:
            'Import complete: ${processedRecords.length} records committed successfully!',
        type: 'success',
        confirmLabel: 'OK',
        showCancel: false,
        onConfirm: () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        CustomFeedback.showFeedbackDialog(
          context,
          title: 'Import Failed',
          message:
              'Failed to upload records: ${e.toString().replaceAll('Exception: ', '')}',
          type: 'error',
          confirmLabel: 'OK',
          showCancel: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter records dynamically
    final List<Map<String, dynamic>> filteredRecords = [];
    final List<int> originalIndices = [];

    final hasSearch = _searchQuery.isNotEmpty;
    final hasStatusFilter = _selectedStatusFilter != 'All';
    final hasAmountFilter = _minAmount != null || _maxAmount != null;

    if (!hasSearch && !hasStatusFilter && !hasAmountFilter) {
      // Direct assignment - no loop needed!
      filteredRecords.addAll(widget.records);
      originalIndices.addAll(Iterable<int>.generate(widget.records.length));
    } else {
      // Loop over cached records for fast matching
      final query = _searchQuery.toLowerCase();
      final statusQuery = _selectedStatusFilter.toLowerCase();

      for (int i = 0; i < _cachedRecords.length; i++) {
        final cache = _cachedRecords[i];

        // Match Search query
        if (hasSearch) {
          final matchesSearch =
              cache.nameLower.contains(query) ||
              cache.phone.contains(query) ||
              cache.loanId.contains(query);
          if (!matchesSearch) continue;
        }

        // Match Status Filter
        if (hasStatusFilter) {
          final matchesStatus = cache.status.toLowerCase() == statusQuery;
          if (!matchesStatus) continue;
        }

        // Match Amount Filters
        if (_minAmount != null && cache.amountDue < _minAmount!) continue;
        if (_maxAmount != null && cache.amountDue > _maxAmount!) continue;

        filteredRecords.add(cache.record);
        originalIndices.add(i);
      }
    }

    bool isAllSelected = filteredRecords.isNotEmpty;
    for (int i = 0; i < filteredRecords.length; i++) {
      final origIdx = originalIndices[i];
      if (!_selectedIndices.contains(origIdx)) {
        isAllSelected = false;
        break;
      }
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
        title: const Text(
          'Verify Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isUploading) CustomFeedback.showProgressIndicator(),
          // Header Summary Block
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'VERIFICATION STEP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary.withOpacity(0.8),
                        letterSpacing: 1.0,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verify Uploaded Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.fileText,
                      color: AppTheme.secondary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.fileName} • ${widget.records.length} records',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dynamic Search Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                border: Border.all(color: AppTheme.outlineVariant),
                borderRadius: BorderRadius.circular(100),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurface,
                  fontFamily: 'Inter',
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search records...',
                  hintStyle: TextStyle(
                    color: AppTheme.secondary.withOpacity(0.6),
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: AppTheme.secondary,
                    size: 18,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: AppTheme.secondary,
                            size: 16,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Select All Strip Sticky Control
          Container(
            color: const Color(0xFFEFF4FF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isAllSelected) {
                        for (int k = 0; k < filteredRecords.length; k++) {
                          final idx = originalIndices[k];
                          _selectedIndices.remove(idx);
                        }
                      } else {
                        for (int k = 0; k < filteredRecords.length; k++) {
                          final idx = originalIndices[k];
                          _selectedIndices.add(idx);
                        }
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isAllSelected
                              ? AppTheme.primary
                              : Colors.white,
                          border: Border.all(
                            color: isAllSelected
                                ? AppTheme.primary
                                : AppTheme.outline,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isAllSelected
                            ? const Icon(
                                LucideIcons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const Text(
                        'Select All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${_selectedIndices.length} Selected',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter & Manage Fields Control Row + Visibility Pills
          Container(
            color: const Color(0xFFEFF4FF),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppTheme.outlineVariant,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _showFilterSheet,
                        icon: const Icon(
                          LucideIcons.filter,
                          size: 16,
                          color: AppTheme.secondary,
                        ),
                        label: Text(
                          _selectedStatusFilter == 'All'
                              ? 'Filter'
                              : 'Filter: $_selectedStatusFilter',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppTheme.outlineVariant,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _showManageFieldsSheet,
                        icon: const Icon(
                          LucideIcons.settings2,
                          size: 16,
                          color: AppTheme.secondary,
                        ),
                        label: const Text(
                          'Manage Fields',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Visibilities Horizontal Pills
                SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildVisibilityChip(
                        'Loan ID',
                        _showLoanId,
                        (val) => setState(() => _showLoanId = val),
                      ),
                      ..._fieldVisibility.entries.map((entry) {
                        final key = entry.key;
                        final isVisible = entry.value;
                        final metadata = _getFieldMetadata(key);
                        final label = metadata['title'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildVisibilityChip(
                            label,
                            isVisible,
                            (val) =>
                                setState(() => _fieldVisibility[key] = val),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Record Checklist Items
          Expanded(
            child: filteredRecords.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.folderOpen,
                          size: 50,
                          color: AppTheme.secondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No matching records to verify.',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: filteredRecords.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = filteredRecords[index];
                      final origIdx = originalIndices[index];
                      final isChecked = _selectedIndices.contains(origIdx);
                      final status = _getStatus(origIdx);

                      return _buildRecordCard(r, origIdx, isChecked, status);
                    },
                  ),
          ),
        ],
      ),

      // Fixed Sticky Confirm Action footer
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppTheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isUploading ? null : _confirmAndImport,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isUploading
                            ? 'Importing...'
                            : 'Confirm & Import (${_selectedIndices.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.uploadCloud, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.secondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityChip(
    String label,
    bool isVisible,
    Function(bool) onToggle,
  ) {
    return GestureDetector(
      onTap: () => onToggle(!isVisible),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isVisible ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isVisible ? Colors.transparent : AppTheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isVisible ? Colors.white : AppTheme.secondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    Map<String, dynamic> record,
    int origIndex,
    bool isChecked,
    String status,
  ) {
    Color statusBgColor;
    Color statusTextColor;
    Color statusDotColor;

    if (status == 'Matched') {
      statusBgColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF2E7D32);
      statusDotColor = const Color(0xFF4CAF50);
    } else if (status == 'Discrepancy') {
      statusBgColor = const Color(0xFFFFDAD6);
      statusTextColor = const Color(0xFFBA1A1A);
      statusDotColor = const Color(0xFFF44336);
    } else {
      // New Record
      statusBgColor = const Color(0xFFEFF4FF);
      statusTextColor = AppTheme.primary;
      statusDotColor = const Color(0xFF2196F3);
    }

    // Safe extraction with fallback to cached values if available
    final String name = origIndex < _cachedRecords.length
        ? (_cachedRecords[origIndex].record['name']?.toString() ?? 'No Name')
        : (record['name']?.toString() ?? 'No Name');

    final String initials = name.trim().isNotEmpty
        ? name
              .trim()
              .split(' ')
              .where((s) => s.isNotEmpty)
              .map((s) => s[0])
              .take(2)
              .join('')
              .toUpperCase()
        : '?';

    final double amount = origIndex < _cachedRecords.length
        ? _cachedRecords[origIndex].amountDue
        : (() {
            if (record['amountDue'] == null) return 0.0;
            if (record['amountDue'] is num) {
              return (record['amountDue'] as num).toDouble();
            }
            return double.tryParse(
                  record['amountDue'].toString().replaceAll(',', ''),
                ) ??
                0.0;
          })();

    // Premium dynamic avatar colors
    final List<Color> avatarColors = [
      const Color(0xFFE8EAF6),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
      const Color(0xFFF3E5F5),
      const Color(0xFFE0F2F1),
      const Color(0xFFE1F5FE),
    ];
    final List<Color> avatarTextColors = [
      const Color(0xFF283593),
      const Color(0xFF2E7D32),
      const Color(0xFFEF6C00),
      const Color(0xFF6A1B9A),
      const Color(0xFF00695C),
      const Color(0xFF0277BD),
    ];
    final int colorIndex = name.hashCode.abs() % avatarColors.length;
    final Color avatarBgColor = avatarColors[colorIndex];
    final Color avatarTextColor = avatarTextColors[colorIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isChecked ? const Color(0xFFF5F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked ? AppTheme.primary : AppTheme.outlineVariant,
          width: isChecked ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isChecked)
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.06),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isChecked) {
                _selectedIndices.remove(origIndex);
              } else {
                _selectedIndices.add(origIndex);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar initials badge
                    if (_fieldVisibility['name'] ?? true) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: avatarBgColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: avatarTextColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_fieldVisibility['name'] ?? true)
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                                fontFamily: 'Inter',
                              ),
                            ),
                          if (_fieldVisibility['amountDue'] ?? true) ...[
                            const SizedBox(height: 2),
                            Text(
                              '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status capsule
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusDotColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusTextColor,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Checkbox
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isChecked ? AppTheme.primary : Colors.white,
                            border: Border.all(
                              color: isChecked
                                  ? AppTheme.primary
                                  : const Color(0xFFC3C6D6),
                              width: isChecked ? 2 : 1.5,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 11,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                // Card details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showLoanId) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.fingerprint,
                            size: 10,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            origIndex < _cachedRecords.length
                                ? _cachedRecords[origIndex].loanIdDisplay
                                : _getLoanId(record, origIndex),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_fieldVisibility['phone'] ?? true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.phone,
                            size: 10,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            record['phone']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_fieldVisibility['address'] ?? true) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1.5),
                            child: Icon(
                              LucideIcons.mapPin,
                              size: 10,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              record['address']?.toString() ?? 'No Address',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant,
                                fontFamily: 'Inter',
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if ((_fieldVisibility['overdueDays'] ?? true) ||
                        (_fieldVisibility['priority'] ?? true)) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (_fieldVisibility['overdueDays'] ?? true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.errorContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.calendarClock,
                                    size: 9,
                                    color: AppTheme.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(() {
                                      final val = record['overdueDays'];
                                      if (val == null) return 10;
                                      if (val is num) return val.toInt();
                                      return int.tryParse(val.toString()) ?? 10;
                                    })()} Days Overdue',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.error,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_fieldVisibility['priority'] ?? true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.alertTriangle,
                                    size: 9,
                                    color: Color(0xFFE65100),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Priority: ${record['priority']?.toString() ?? 'MEDIUM'}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE65100),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                    (() {
                      final assetModel = record['assetModel']?.toString() ?? '';
                      final assetRegNo = record['assetRegNo']?.toString() ?? '';
                      final engineNo = record['engineNumber']?.toString() ?? '';
                      final chasisNo = record['chasisNumber']?.toString() ?? '';
                      final assetVariant =
                          record['assetVariant']?.toString() ?? '';

                      final showModel =
                          (_fieldVisibility['assetModel'] ?? true) &&
                          assetModel.isNotEmpty;
                      final showRegNo =
                          (_fieldVisibility['assetRegNo'] ?? true) &&
                          assetRegNo.isNotEmpty;
                      final showVariant =
                          (_fieldVisibility['assetVariant'] ?? true) &&
                          assetVariant.isNotEmpty;
                      final showEngine =
                          (_fieldVisibility['engineNumber'] ?? true) &&
                          engineNo.isNotEmpty;
                      final showChassis =
                          (_fieldVisibility['chasisNumber'] ?? true) &&
                          chasisNo.isNotEmpty;

                      final hasAssetInfo =
                          showModel ||
                          showRegNo ||
                          showVariant ||
                          showEngine ||
                          showChassis;

                      Widget? assetBox;
                      if (hasAssetInfo) {
                        assetBox = Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.car,
                                    size: 10,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ASSET INFORMATION (MAPPED)',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary.withOpacity(0.8),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  if (showModel)
                                    _buildAssetBadge('Model', assetModel),
                                  if (showRegNo)
                                    _buildAssetBadge('Reg No', assetRegNo),
                                  if (showVariant)
                                    _buildAssetBadge('Variant', assetVariant),
                                  if (showEngine)
                                    _buildAssetBadge('Engine', engineNo),
                                  if (showChassis)
                                    _buildAssetBadge('Chassis', chasisNo),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      // Render other custom added fields dynamically
                      final List<Widget> dynamicFieldBadges = [];
                      final coreKeys = {
                        'name',
                        'amountDue',
                        'phone',
                        'address',
                        'overdueDays',
                        'priority',
                        'assetModel',
                        'assetRegNo',
                        'assetVariant',
                        'engineNumber',
                        'chasisNumber',
                      };

                      for (final key in _fieldVisibility.keys) {
                        if (coreKeys.contains(key)) continue;
                        if (!(_fieldVisibility[key] ?? true)) continue;
                        final value = record[key]?.toString() ?? '';
                        if (value.isNotEmpty) {
                          final metadata = _getFieldMetadata(key);
                          dynamicFieldBadges.add(
                            _buildAssetBadge(
                              metadata['title'] as String,
                              value,
                            ),
                          );
                        }
                      }

                      Widget? customBox;
                      if (dynamicFieldBadges.isNotEmpty) {
                        customBox = Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.listPlus,
                                    size: 10,
                                    color: AppTheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ADDITIONAL INFORMATION',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary.withOpacity(0.8),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: dynamicFieldBadges,
                              ),
                            ],
                          ),
                        );
                      }

                      if (assetBox == null && customBox == null) {
                        return const SizedBox();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [?assetBox, ?customBox],
                      );
                    })(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDCE9FF)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 9,
            fontFamily: 'Inter',
            color: AppTheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondary,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// FILTER records bottom sheet widget
// ----------------------------------------------------------------------------
class _FilterUploadedSheet extends StatefulWidget {
  final String initialStatus;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final String initialDateFilter;
  final Function(String status, double? min, double? max, String date) onApply;

  const _FilterUploadedSheet({
    required this.initialStatus,
    required this.initialMinAmount,
    required this.initialMaxAmount,
    required this.initialDateFilter,
    required this.onApply,
  });

  @override
  State<_FilterUploadedSheet> createState() => _FilterUploadedSheetState();
}

class _FilterUploadedSheetState extends State<_FilterUploadedSheet> {
  late String _status;
  late String _dateFilter;
  late RangeValues _rangeValues;
  DateTime? _startDate;
  DateTime? _endDate;

  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _dateFilter = widget.initialDateFilter;

    double minVal = widget.initialMinAmount ?? 0.0;
    double maxVal = widget.initialMaxAmount ?? 100000.0;
    if (minVal < 0.0) minVal = 0.0;
    if (maxVal > 100000.0) maxVal = 100000.0;
    if (minVal > maxVal) minVal = maxVal;
    _rangeValues = RangeValues(minVal, maxVal);

    _minController.text = minVal.toStringAsFixed(0);
    _maxController.text = maxVal.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String _formatCurrency(double val) {
    return val
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00328A), // brand blue
              onPrimary: Colors.white,
              onSurface: Color(0xFF0B1C30),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardOffset = MediaQuery.of(context).viewInsets.bottom;

    final String minValText = _formatCurrency(_rangeValues.start);
    final String maxValText = _rangeValues.end == 100000.0
        ? '100,000+'
        : _formatCurrency(_rangeValues.end);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardOffset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(top: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3C6D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Records',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B1C30),
                        fontFamily: 'Inter',
                        letterSpacing: -0.22,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Color(0xFF434653),
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: const Color(0xFFC3C6D6).withOpacity(0.3),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Record Status Chips
                      const Text(
                        'RECORD STATUS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C5F61),
                          letterSpacing: 0.7,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusChip('All'),
                            const SizedBox(width: 8),
                            _buildStatusChip('New Record'),
                            const SizedBox(width: 8),
                            _buildStatusChip('Matched'),
                            const SizedBox(width: 8),
                            _buildStatusChip('Discrepancy'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section: Amount Range
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AMOUNT RANGE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5C5F61),
                              letterSpacing: 0.7,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '₹$minValText - ₹$maxValText',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF00328A),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 4),
                                  child: Text(
                                    'Min Value',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF434653),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 56,
                                  child: TextField(
                                    controller: _minController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0B1C30),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                    onChanged: (val) {
                                      final parsed =
                                          double.tryParse(val) ?? 0.0;
                                      if (parsed >= 0.0 && parsed <= 100000.0) {
                                        setState(() {
                                          _rangeValues = RangeValues(
                                            parsed,
                                            _rangeValues.end < parsed
                                                ? parsed
                                                : _rangeValues.end,
                                          );
                                          if (_rangeValues.end < parsed) {
                                            _maxController.text = parsed
                                                .toStringAsFixed(0);
                                          }
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      prefixStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF434653),
                                        fontFamily: 'Inter',
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFC3C6D6),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFC3C6D6),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF00328A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 4),
                                  child: Text(
                                    'Max Value',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF434653),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 56,
                                  child: TextField(
                                    controller: _maxController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0B1C30),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                    onChanged: (val) {
                                      final parsed =
                                          double.tryParse(val) ?? 100000.0;
                                      if (parsed >= 0.0 && parsed <= 100000.0) {
                                        setState(() {
                                          _rangeValues = RangeValues(
                                            _rangeValues.start > parsed
                                                ? parsed
                                                : _rangeValues.start,
                                            parsed,
                                          );
                                          if (_rangeValues.start > parsed) {
                                            _minController.text = parsed
                                                .toStringAsFixed(0);
                                          }
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      prefixStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF434653),
                                        fontFamily: 'Inter',
                                      ),
                                      hintText: '50,000+',
                                      hintStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF737685),
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Inter',
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFC3C6D6),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFC3C6D6),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF00328A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Premium Custom Range Slider Picker bi-directionally synchronized
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF00328A),
                          inactiveTrackColor: const Color(0xFFDCE9FF),
                          thumbColor: const Color(0xFF00328A),
                          overlayColor: const Color(
                            0xFF00328A,
                          ).withOpacity(0.12),
                          trackHeight: 4.0,
                          rangeThumbShape: const CustomRangeThumbShape(
                            enabledThumbRadius: 12.0,
                          ),
                        ),
                        child: RangeSlider(
                          values: _rangeValues,
                          min: 0.0,
                          max: 100000.0,
                          divisions: 100, // snap increments of 1,000
                          onChanged: (RangeValues values) {
                            setState(() {
                              _rangeValues = values;
                              _minController.text = values.start
                                  .toStringAsFixed(0);
                              _maxController.text = values.end.toStringAsFixed(
                                0,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section: Upload Date
                      const Text(
                        'UPLOAD DATE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C5F61),
                          letterSpacing: 0.7,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDateRadio('Today'),
                      _buildDateRadio('Last 7 Days'),
                      _buildDateRadio('Custom Range'),
                    ],
                  ),
                ),
              ),

              // Sticky stacked bottom actions footer conforming to Stitch layout
              Container(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFC3C6D6).withOpacity(0.3),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(
                            _status,
                            _rangeValues.start == 0.0
                                ? null
                                : _rangeValues.start,
                            _rangeValues.end == 100000.0
                                ? null
                                : _rangeValues.end,
                            _dateFilter,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF0047BB,
                          ), // Brand primary container blue
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.05,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _status = 'All';
                            _rangeValues = const RangeValues(0.0, 100000.0);
                            _minController.text = '0';
                            _maxController.text = '100000';
                            _startDate = null;
                            _endDate = null;
                            _dateFilter = 'Today';
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF00328A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final isSelected = _status == label;
    return GestureDetector(
      onTap: () => setState(() => _status = label),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0047BB) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00328A)
                : const Color(0xFFC3C6D6),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0047BB).withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label == 'New Record' ? 'New' : label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? const Color(0xFFAFC1FF)
                : const Color(0xFF434653),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildDateRadio(String label) {
    final isSelected = _dateFilter == label;
    String displayLabel = label;
    if (label == 'Custom Range' && _startDate != null && _endDate != null) {
      displayLabel =
          'Custom: ${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _dateFilter = label;
            });
            if (label == 'Custom Range') {
              _selectCustomDateRange();
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF4FF) : Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00328A)
                    : const Color(0xFFC3C6D6),
                width: isSelected ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00328A)
                          : const Color(0xFF737685),
                      width: isSelected ? 6.0 : 2.0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: const Color(0xFF0B1C30),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (label == 'Custom Range' && isSelected) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectCustomDateRange,
                    child: Container(
                      height: 56, // Premium 56px height!
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC3C6D6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: Color(0xFF00328A),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF737685),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Text(
                                  _startDate != null
                                      ? _formatDate(_startDate!)
                                      : 'Select',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1C30),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectCustomDateRange,
                    child: Container(
                      height: 56, // Premium 56px height!
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC3C6D6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: Color(0xFF00328A),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF737685),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Text(
                                  _endDate != null
                                      ? _formatDate(_endDate!)
                                      : 'Select',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1C30),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// CUSTOM RANGE SLIDER THUMB SHAPE
// ----------------------------------------------------------------------------
class CustomRangeThumbShape extends RangeSliderThumbShape {
  final double enabledThumbRadius;

  const CustomRangeThumbShape({this.enabledThumbRadius = 12.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isPressed) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
  }) {
    final Canvas canvas = context.canvas;

    // Draw thumb shadow
    final Path shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: enabledThumbRadius));
    canvas.drawShadow(shadowPath, Colors.black, 3.5, true);

    // Draw outer white border circle
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, borderPaint);

    // Draw inner primary blue fill circle
    final Paint fillPaint = Paint()
      ..color = sliderTheme.thumbColor ?? const Color(0xFF00328A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius - 4.0, fillPaint);
  }
}

// ----------------------------------------------------------------------------
// MANAGE FIELDS visibility selection bottom sheet widget
// ----------------------------------------------------------------------------
class _ManageImportFieldsSheet extends StatefulWidget {
  final Map<String, bool> fieldVisibility;
  final bool showLoanId;
  final Function(Map<String, bool> fieldVisibility, bool showLoanId) onSave;

  const _ManageImportFieldsSheet({
    required this.fieldVisibility,
    required this.showLoanId,
    required this.onSave,
  });

  @override
  State<_ManageImportFieldsSheet> createState() =>
      _ManageImportFieldsSheetState();
}

class _ManageImportFieldsSheetState extends State<_ManageImportFieldsSheet> {
  late Map<String, bool> _fieldVisibility;
  late bool _showLoanId;

  @override
  void initState() {
    super.initState();
    _fieldVisibility = Map<String, bool>.from(widget.fieldVisibility);
    _showLoanId = widget.showLoanId;
  }

  Map<String, dynamic> _getFieldMetadata(String key) {
    switch (key) {
      case 'name':
        return {
          'title': 'Debtor Name',
          'description': 'Full legal identity of the debtor',
          'icon': LucideIcons.user,
        };
      case 'amountDue':
        return {
          'title': 'Amount',
          'description': 'Total outstanding ledger balance',
          'icon': LucideIcons.banknote,
        };
      case 'phone':
        return {
          'title': 'Contact Phone',
          'description': 'Primary telephone notification digits',
          'icon': LucideIcons.phone,
        };
      case 'address':
        return {
          'title': 'Debtor Address',
          'description': 'Location or residence of the debtor',
          'icon': LucideIcons.mapPin,
        };
      case 'overdueDays':
        return {
          'title': 'Overdue Days',
          'description': 'Number of days payment is overdue',
          'icon': LucideIcons.calendarClock,
        };
      case 'priority':
        return {
          'title': 'Priority',
          'description': 'Assigned Urgency / Priority level',
          'icon': LucideIcons.alertTriangle,
        };
      case 'assetModel':
        return {
          'title': 'Asset Model',
          'description': 'Mapped asset model reference info',
          'icon': LucideIcons.car,
        };
      case 'assetRegNo':
        return {
          'title': 'Asset Reg No',
          'description': 'Mapped asset registration number details',
          'icon': LucideIcons.hash,
        };
      case 'assetVariant':
        return {
          'title': 'Asset Variant',
          'description': 'Mapped asset specification variant configuration',
          'icon': LucideIcons.layers,
        };
      case 'engineNumber':
        return {
          'title': 'Engine Number',
          'description': 'Mapped asset engine block identifier key',
          'icon': LucideIcons.activity,
        };
      case 'chasisNumber':
        return {
          'title': 'Chassis Number',
          'description': 'Mapped asset chassis serial structural ID',
          'icon': LucideIcons.shieldAlert,
        };
      default:
        final camelCaseRegex = RegExp(r'(^[a-z]+|[A-Z][a-z]*)');
        final matches = camelCaseRegex.allMatches(key);
        String label = key;
        if (matches.isNotEmpty) {
          label = matches
              .map((m) {
                final s = m.group(0) ?? '';
                if (s.isEmpty) return s;
                return s[0].toUpperCase() + s.substring(1);
              })
              .join(' ');
        } else {
          label = key.isNotEmpty
              ? key[0].toUpperCase() + key.substring(1)
              : key;
        }
        return {
          'title': label,
          'description': 'Mapped $label column from source file',
          'icon': LucideIcons.hash,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC4C7C5),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage Import Fields',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1C30),
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toggle visibility of parsed columns.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondary.withOpacity(0.8),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      color: Color(0xFF0B1C30),
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFC3C6D6)),

            // Switch Toggles List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                children: [
                  _buildToggleRow(
                    title: 'Loan ID',
                    description: 'Unique contract reference keys',
                    icon: LucideIcons.fingerprint,
                    value: _showLoanId,
                    onChanged: (val) => setState(() => _showLoanId = val),
                  ),
                  ..._fieldVisibility.entries.map((entry) {
                    final key = entry.key;
                    final isVisible = entry.value;
                    final metadata = _getFieldMetadata(key);
                    return _buildToggleRow(
                      title: metadata['title'] as String,
                      description: metadata['description'] as String,
                      icon: metadata['icon'] as IconData,
                      value: isVisible,
                      onChanged: (val) =>
                          setState(() => _fieldVisibility[key] = val),
                    );
                  }),
                ],
              ),
            ),

            // Discard & Save footer
            const Divider(height: 1, color: Color(0xFFC3C6D6)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC3C6D6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Discard',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C5F61),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onSave(_fieldVisibility, _showLoanId);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00328A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Configuration',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3C6D6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1C30),
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5C5F61),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RecordCache {
  final Map<String, dynamic> record;
  final String nameLower;
  final String phone;
  final String loanId;
  final String loanIdDisplay;
  final String status;
  final double amountDue;

  _RecordCache({
    required this.record,
    required this.nameLower,
    required this.phone,
    required this.loanId,
    required this.loanIdDisplay,
    required this.status,
    required this.amountDue,
  });
}
