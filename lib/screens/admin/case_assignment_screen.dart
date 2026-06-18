import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../models/customer.dart';
import '../../models/recent_upload_item.dart';
import '../../models/agent.dart';
import '../agent/customer_details_screen.dart';
import '../../widgets/custom_feedback.dart';

class CaseAssignmentScreen extends StatefulWidget {
  final RecentUploadItem selectedFile;
  final bool isEmbedded;

  const CaseAssignmentScreen({
    super.key,
    required this.selectedFile,
    this.isEmbedded = false,
  });

  @override
  State<CaseAssignmentScreen> createState() => _CaseAssignmentScreenState();
}

class CaseItem {
  final String id;
  final String loanId;
  final String name;
  final double amount;
  final String overdueStatus;
  final String location;
  final String riskLevel;
  final IconData riskIcon;
  final String? assignedAgentId;
  final String? assignedAgentName;

  CaseItem({
    required this.id,
    required this.loanId,
    required this.name,
    required this.amount,
    required this.overdueStatus,
    required this.location,
    required this.riskLevel,
    required this.riskIcon,
    this.assignedAgentId,
    this.assignedAgentName,
  });
}

class _CaseAssignmentScreenState extends State<CaseAssignmentScreen> {
  final _db = DatabaseService();
  String _selectedSegment = 'Unassigned'; // 'Unassigned' or 'Assigned'
  final Set<String> _selectedCaseIds = {};

  // New visual filters state variables (directly matching the filters PNG spec)
  String _statusFilter = 'Unassigned';
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy = 'Newest First';

  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
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

  // Local overrides for assigned static cases
  final Map<String, String> _caseAssignments = {};
  final Map<String, String> _casePriorities = {};

  // Standard high-fidelity mock cases from Stitch UI spec
  final List<CaseItem> _allCases = [
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        // Map actual database customers from recentUploaded's customers to CaseItems (only if file selected)
        final List<Customer> allDbCustomers = [];
        final currentFile = _db.recentUploadItem
            .where((f) => f.fileId == widget.selectedFile.fileId)
            .firstOrNull;
        allDbCustomers.addAll(currentFile?.customers ?? widget.selectedFile.customers);

        final List<CaseItem> dbCases = allDbCustomers.map((c) {
          // Resolve risk details based on priority
          IconData riskIcon = LucideIcons.triangle;
          String riskText = 'First Notice';
          if (c.priority == 'CRITICAL') {
            riskIcon = LucideIcons.triangleAlert;
            riskText = 'Critical';
          } else if (c.priority == 'HIGH') {
            riskIcon = LucideIcons.alertTriangle;
            riskText = 'High Risk';
          } else if (c.priority == 'MEDIUM') {
            riskIcon = LucideIcons.history;
            riskText = 'First Notice';
          } else if (c.priority == 'LOW') {
            riskIcon = LucideIcons.info;
            riskText = 'Low Balance';
          }

          // Generate stable Loan ID based on DB customer ID
          final String cleanId = c.id.replaceAll('cust_', '').toUpperCase();
          final String loanId = c.showLoanId
              ? '#LN-${cleanId.length > 5 ? cleanId.substring(0, 5) : cleanId}'
              : 'N/A';

          // Get assigned agent details
          final agent = _db.agents
              .where((a) => a.id == c.assignedAgentId)
              .firstOrNull;

          return CaseItem(
            id: c.id,
            loanId: loanId,
            name: c.name,
            amount: c.amountDue,
            overdueStatus: '${c.overdueDays} Days Overdue',
            location: c.address.split(',').last.trim(), // Grab region name
            riskLevel: riskText,
            riskIcon: riskIcon,
            assignedAgentId: c.assignedAgentId,
            assignedAgentName: agent?.name,
          );
        }).toList();

        // Map mock cases with local overrides
        final List<CaseItem> mappedMocks = _allCases.map((m) {
          final assignedAgentId = _caseAssignments[m.id];
          final localPriority = _casePriorities[m.id];
          String? resolvedAgentName;
          if (assignedAgentId != null) {
            final agent = _db.agents
                .where((a) => a.id == assignedAgentId)
                .firstOrNull;
            resolvedAgentName = agent?.name ?? 'Agent Miller';
          }

          // Map local priority overrides to static mock details
          String riskText = m.riskLevel;
          IconData riskIcon = m.riskIcon;
          if (localPriority != null) {
            if (localPriority == 'CRITICAL') {
              riskText = 'Critical';
              riskIcon = LucideIcons.triangleAlert;
            } else if (localPriority == 'HIGH') {
              riskText = 'High Risk';
              riskIcon = LucideIcons.alertTriangle;
            } else if (localPriority == 'MEDIUM') {
              riskText = 'First Notice';
              riskIcon = LucideIcons.history;
            } else if (localPriority == 'LOW') {
              riskText = 'Low Balance';
              riskIcon = LucideIcons.info;
            }
          }

          return CaseItem(
            id: m.id,
            loanId: m.loanId,
            name: m.name,
            amount: m.amount,
            overdueStatus: m.overdueStatus,
            location: m.location,
            riskLevel: riskText,
            riskIcon: riskIcon,
            assignedAgentId: assignedAgentId,
            assignedAgentName: resolvedAgentName,
          );
        }).toList();

        // Combine lists
        final List<CaseItem> allCases = [...dbCases, ...mappedMocks];

        // Filter based on selected Status (Unassigned, Assigned, In-Progress, Completed, Failed)
        final List<CaseItem> segmentedCases = allCases.where((c) {
          final isAssigned =
              c.assignedAgentId != null &&
              c.assignedAgentId!.isNotEmpty &&
              c.assignedAgentId != 'unassigned';

          switch (_statusFilter) {
            case 'Unassigned':
              return !isAssigned;
            case 'Assigned':
              return isAssigned;
            case 'In-Progress':
              // Assigned cases with active/ongoing risk categories
              return isAssigned &&
                  (c.riskLevel == 'High Risk' ||
                      c.riskLevel == 'Critical' ||
                      c.riskLevel == 'First Notice');
            case 'Completed':
              // Small balance accounts or settled portfolios
              return c.amount < 1000;
            case 'Failed':
              // Severe delinquency cases
              return c.riskLevel == 'Critical' ||
                  c.overdueStatus.contains('45 Days');
            default:
              return true;
          }
        }).toList();

        // Filter based on Amount Range (₹ Min / ₹ Max)
        var filteredCases = segmentedCases.where((c) {
          if (_minAmount != null && c.amount < _minAmount!) return false;
          if (_maxAmount != null && c.amount > _maxAmount!) return false;
          return true;
        }).toList();

        // Filter based on Search Query (Debtor Name, Loan ID, or Region)
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredCases = filteredCases.where((c) {
            return c.name.toLowerCase().contains(query) ||
                c.loanId.toLowerCase().contains(query) ||
                c.location.toLowerCase().contains(query);
          }).toList();
        }

        // Sort cases based on selected criteria
        filteredCases.sort((a, b) {
          switch (_sortBy) {
            case 'Newest First':
              // Sort by loan ID descending
              return b.loanId.compareTo(a.loanId);
            case 'Oldest First':
              return a.loanId.compareTo(b.loanId);
            case 'Amount: High to Low':
              return b.amount.compareTo(a.amount);
            case 'Amount: Low to High':
              return a.amount.compareTo(b.amount);
            default:
              return 0;
          }
        });

        // Calculate count indicator
        final int unassignedCount =
            allCases
                .where(
                  (c) =>
                      c.assignedAgentId == null ||
                      c.assignedAgentId == 'unassigned' ||
                      c.assignedAgentId!.isEmpty,
                )
                .length;

        final scaffoldBody = Column(
          children: [
            if (_isLoading) CustomFeedback.showProgressIndicator(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Cases',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$unassignedCount Unassigned Cases',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.error,
                                ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Updated 2m ago',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Segmented Control (Toggle Unassigned / Assigned)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildSegmentButton('Unassigned')),
                        Expanded(child: _buildSegmentButton('Assigned')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Beautiful Search Input Bar (Stitch Specs)
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by debtor name, region, or loan...',
                      hintStyle: TextStyle(
                        color: AppTheme.secondary.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        fontFamily: 'Inter',
                      ),
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          color: AppTheme.secondary,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                     
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bulk Action Controller Panel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value:
                                filteredCases.isNotEmpty &&
                                filteredCases.every(
                                  (c) => _selectedCaseIds.contains(c.id),
                                ),
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedCaseIds.addAll(
                                    filteredCases.map((c) => c.id),
                                  );
                                } else {
                                  _selectedCaseIds.removeAll(
                                    filteredCases.map((c) => c.id),
                                  );
                                }
                              });
                            },
                          ),
                          const Text(
                            'Select All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      // Filter Button
                      TextButton.icon(
                        onPressed: () => _showFilterBottomSheet(),
                        icon: const Icon(
                          LucideIcons.slidersHorizontal,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        label: Text(
                          _statusFilter == 'Unassigned'
                              ? 'Filter'
                              : 'Filter: $_statusFilter',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: AppTheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sticky Assignment and Priority Action Panel (Dual Side-by-Side buttons)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 52,
                    child: Row(
                      children: [
                        // Assign Button
                        Expanded(
                          child: SizedBox(
                            height: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedCaseIds.isNotEmpty
                                    ? AppTheme.primary
                                    : AppTheme.outline.withOpacity(0.12),
                                foregroundColor: _selectedCaseIds.isNotEmpty
                                    ? Colors.white
                                    : AppTheme.secondary.withOpacity(0.5),
                                elevation: _selectedCaseIds.isNotEmpty ? 4 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: _selectedCaseIds.isNotEmpty
                                  ? () => _showBulkDeployDialog(allCases)
                                  : null,
                              icon: Icon(
                                LucideIcons.userPlus,
                                size: 20,
                                color: _selectedCaseIds.isNotEmpty
                                    ? Colors.white
                                    : AppTheme.secondary.withOpacity(0.4),
                              ),
                              label: Text(
                                _selectedCaseIds.isNotEmpty
                                    ? 'Assign (${_selectedCaseIds.length})'
                                    : 'Assign',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Set Priority Button
                        Expanded(
                          child: SizedBox(
                            height: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedCaseIds.isNotEmpty
                                    ? Colors.white
                                    : AppTheme.outline.withOpacity(0.05),
                                foregroundColor: _selectedCaseIds.isNotEmpty
                                    ? AppTheme.primary
                                    : AppTheme.secondary.withOpacity(0.4),
                                side: BorderSide(
                                  color: _selectedCaseIds.isNotEmpty
                                      ? AppTheme.primary
                                      : AppTheme.outlineVariant.withOpacity(
                                          0.5,
                                        ),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: _selectedCaseIds.isNotEmpty
                                  ? () => _showPriorityBottomSheet(
                                      allCases
                                          .where(
                                            (c) =>
                                                _selectedCaseIds.contains(c.id),
                                          )
                                          .toList(),
                                    )
                                  : null,
                              icon: Icon(
                                LucideIcons.listOrdered,
                                size: 20,
                                color: _selectedCaseIds.isNotEmpty
                                    ? AppTheme.primary
                                    : AppTheme.secondary.withOpacity(0.4),
                              ),
                              label: Text(
                                _selectedCaseIds.isNotEmpty
                                    ? 'Set Priority (${_selectedCaseIds.length})'
                                    : 'Set Priority',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
            const Divider(height: 1, color: AppTheme.outlineVariant),

            // Cases list view mapping
            Expanded(
              child: filteredCases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.folder,
                            size: 56,
                            color: AppTheme.outline.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No portfolio cases found in segment.',
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
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 32.0),
                      itemCount: filteredCases.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final caseItem = filteredCases[index];
                        final isChecked = _selectedCaseIds.contains(
                          caseItem.id,
                        );

                        return _buildCaseCard(caseItem, isChecked);
                      },
                    ),
            ),
          ],
        );

        if (widget.isEmbedded) return scaffoldBody;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
              widget.selectedFile.fileName,
            ),
          ),
          body: scaffoldBody,
        );
      },
    );
  }

  Widget _buildSegmentButton(String segmentName) {
    final isSelected = _selectedSegment == segmentName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSegment = segmentName;
          _statusFilter = segmentName; // Keep status filter in sync
          _selectedCaseIds.clear(); // Reset selections on segment flip
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          segmentName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Customer _createMockCustomer(CaseItem item) {
    // Determine priority based on risk level
    String priority = 'MEDIUM';
    if (item.riskLevel == 'Critical' || item.riskLevel == 'High Risk') {
      priority = 'HIGH';
    } else if (item.riskLevel == 'Low Balance') {
      priority = 'LOW';
    }

    // Parse overdue days from overdueStatus e.g. "12 Days Overdue" or "Due Tomorrow"
    int overdueDays = 15;
    final RegExp matchDays = RegExp(r'(\d+)');
    final match = matchDays.firstMatch(item.overdueStatus);
    if (match != null) {
      overdueDays = int.tryParse(match.group(1) ?? '15') ?? 15;
    } else if (item.overdueStatus.contains('Tomorrow')) {
      overdueDays = 1;
    }

    return Customer(
      id: item.id,
      name: item.name,
      amountDue: item.amount,
      dueDate: DateTime.now().subtract(Duration(days: overdueDays)),
      overdueDays: overdueDays,
      address: '${item.location}, Mumbai Metro Area',
      phone: '+91 99999 88888',
      priority: priority,
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      lat: 19.0760,
      lng: 72.8777,
      assignedAgentId: item.assignedAgentId ?? 'miller',
      status: item.riskLevel == 'Critical' ? 'OVERDUE' : 'PENDING_VERIFICATION',
      notes: [
        'Initial mock case record imported.',
        'Verified geographic region: ${item.location}.',
      ],
      assignedAgentName: ""
    );
  }

  Widget _buildCaseCard(CaseItem caseItem, bool isChecked) {
    // Resolve premium colors for each risk level badge
    Color badgeBgColor;
    Color badgeTextColor;

    switch (caseItem.riskLevel) {
      case 'Critical':
        badgeBgColor = const Color(0xFFFFDAD6);
        badgeTextColor = const Color(0xFFBA1A1A);
        break;
      case 'High Risk':
        badgeBgColor = const Color(0xFFFFF3E0);
        badgeTextColor = const Color(0xFFE65100);
        break;
      case 'First Notice':
        badgeBgColor = const Color(0xFFEFF4FF);
        badgeTextColor = AppTheme.primary;
        break;
      case 'Low Balance':
        badgeBgColor = const Color(0xFFE0F2F1);
        badgeTextColor = const Color(0xFF00796B);
        break;
      case 'Low Risk':
      case 'Low':
        badgeBgColor = const Color(0xFFE8F5E9);
        badgeTextColor = const Color(0xFF2E7D32);
        break;
      default:
        badgeBgColor = const Color(0xFFECEFF1);
        badgeTextColor = const Color(0xFF455A64);
    }

    return CustomBentoCard(
      padding: 0,
      onTap: () {
        setState(() {
          if (isChecked) {
            _selectedCaseIds.remove(caseItem.id);
          } else {
            _selectedCaseIds.add(caseItem.id);
          }
        });
      },
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
                      _selectedCaseIds.add(caseItem.id);
                    } else {
                      _selectedCaseIds.remove(caseItem.id);
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
                  // Upper block (Loan ID & Overdue + Name & Amount)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              caseItem.loanId,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.outline,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              caseItem.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${caseItem.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            caseItem.overdueStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  caseItem.overdueStatus.contains('Tomorrow') ||
                                      caseItem.overdueStatus.contains('days')
                                  ? AppTheme.onSurfaceVariant
                                  : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.outlineVariant),
                  const SizedBox(height: 12),

                  // Lower block (Location & Risk tags & details link)
                  Row(
                    children: [
                      // Location label
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: AppTheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            caseItem.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Risk Capsule Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              caseItem.riskIcon,
                              size: 11,
                              color: badgeTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              caseItem.riskLevel,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Subtle Premium Details Link
                      GestureDetector(
                        onTap: () {
                          final customer = _db.recentUploadItem
                              .expand((item) => item.customers)
                              .firstWhere(
                            (c) => c.id == caseItem.id,
                            orElse: () => _createMockCustomer(caseItem),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomerDetailsScreen(customer: customer),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 13,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // If assigned, show who has this case
                  if (caseItem.assignedAgentName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.user,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Assignee: ${caseItem.assignedAgentName}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterBottomSheet(
          initialStatus: _statusFilter,
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          initialMinAmount: _minAmount,
          initialMaxAmount: _maxAmount,
          initialSortBy: _sortBy,
          onApply: (status, start, end, min, max, sort) {
            setState(() {
              _statusFilter = status;
              if (status == 'Unassigned' || status == 'Assigned') {
                _selectedSegment = status;
              } else {
                _selectedSegment = 'Assigned';
              }
              _startDate = start;
              _endDate = end;
              _minAmount = min;
              _maxAmount = max;
              _sortBy = sort;
              _selectedCaseIds.clear();
            });
          },
        );
      },
    );
  }

  void _showBulkDeployDialog(List<CaseItem> allCases) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DeployAgentBottomSheet(
          selectedCaseIds: _selectedCaseIds,
          agents: _db.agents.where((a) => !a.isAdmin).toList(),
          onDeploy: (agent) {
            // Execute bulk migrations on database service loop!
            for (var id in _selectedCaseIds) {
              if (id.startsWith('cust_')) {
                _db.assignCase(id, agent.id);
              } else {
                // Static local override
                _caseAssignments[id] = agent.id;
              }
            }

            final count = _selectedCaseIds.length;
            setState(() {
              _selectedCaseIds.clear(); // Reset selections
            });

            CustomFeedback.showToast(
              context,
              'Successfully deployed $count case${count > 1 ? 's' : ''} to ${agent.name}.',
              type: 'success',
            );
          },
        );
      },
    );
  }

  void _showPriorityBottomSheet(List<CaseItem> selectedCases) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SetPriorityBottomSheet(
          selectedCases: selectedCases,
          onApply: (priority) {
            setState(() {
              for (var caseItem in selectedCases) {
                if (caseItem.id.startsWith('cust_')) {
                  _db.updateCasePriority(caseItem.id, priority);
                } else {
                  _casePriorities[caseItem.id] = priority.toUpperCase();
                }
              }
              _selectedCaseIds.clear(); // Reset selections
              CustomFeedback.showToast(
                context,
                'Updated priority to $priority for ${selectedCases.length} case${selectedCases.length > 1 ? 's' : ''}.',
                type: 'success',
              );
            });
          },
        );
      },
    );
  }
}

class _SetPriorityBottomSheet extends StatefulWidget {
  final List<CaseItem> selectedCases;
  final Function(String priority) onApply;

  const _SetPriorityBottomSheet({
    required this.selectedCases,
    required this.onApply,
  });

  @override
  State<_SetPriorityBottomSheet> createState() =>
      _SetPriorityBottomSheetState();
}

class _SetPriorityBottomSheetState extends State<_SetPriorityBottomSheet> {
  String _selectedPriority = 'medium'; // Default to medium

  String _getInitials(String name) {
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardOffset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardOffset),
      child: Container(
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
              // Drag Handle / Header Line
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

              // Title Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Color(0xFF0B1C30),
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Set Case Priority',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1C30),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected Cases Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFC3C6D6)),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${widget.selectedCases.length} CASE${widget.selectedCases.length > 1 ? 'S' : ''} SELECTED",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00328A),
                                    letterSpacing: 0.5,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const Icon(
                                  LucideIcons.clipboardCheck,
                                  color: Color(0xFF00328A),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Vertical list of case names with circular avatars
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.selectedCases.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final c = widget.selectedCases[index];
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFFDCE9FF),
                                      child: Text(
                                        _getInitials(c.name),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00328A),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0B1C30),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SELECT PRIORITY LEVEL Label
                      const Text(
                        'SELECT PRIORITY LEVEL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF434653),
                          letterSpacing: 0.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Priority Option cards
                      _buildPriorityOptionCard(
                        value: 'critical',
                        title: 'Critical',
                        description:
                            'Immediate field visit required. Case escalates to director level if no payment action within 24 hours.',
                        icon: LucideIcons.alertTriangle,
                        textColor: const Color(0xFFBA1A1A),
                        iconColor: const Color(0xFFBA1A1A),
                        iconBgColor: const Color(0xFFFFDAD6),
                        checkedBorderColor: const Color(0xFFBA1A1A),
                        checkedBgColor: const Color(
                          0xFFFFDAD6,
                        ).withOpacity(0.1),
                      ),
                      const SizedBox(height: 12),

                      _buildPriorityOptionCard(
                        value: 'high',
                        title: 'High',
                        description:
                            'Prioritized contact queue. Daily follow-up required until payment plan is established.',
                        icon: LucideIcons.triangleAlert,
                        textColor: const Color(0xFFEA580C),
                        iconColor: const Color(0xFFF97316),
                        iconBgColor: const Color(0xFFFFF3E0),
                        checkedBorderColor: const Color(0xFFF97316),
                        checkedBgColor: const Color(0xFFFFF7ED),
                      ),
                      const SizedBox(height: 12),

                      _buildPriorityOptionCard(
                        value: 'medium',
                        title: 'Medium',
                        description:
                            'Standard workflow procedure. Routine monitoring and bi-weekly engagement sessions.',
                        icon: LucideIcons.triangle,
                        textColor: const Color(0xFF00328A),
                        iconColor: const Color(0xFF00328A),
                        iconBgColor: const Color(0xFFEFF4FF),
                        checkedBorderColor: const Color(0xFF00328A),
                        checkedBgColor: const Color(0xFFEFF4FF),
                      ),
                      const SizedBox(height: 12),

                      _buildPriorityOptionCard(
                        value: 'low',
                        title: 'Low',
                        description:
                            'Maintenance mode. Minimal field resources allocated. Periodic digital notification alerts.',
                        icon: LucideIcons.listOrdered,
                        textColor: const Color(0xFF5C5F61),
                        iconColor: const Color(0xFF5C5F61),
                        iconBgColor: const Color(0xFFE0E3E5),
                        checkedBorderColor: const Color(0xFF5C5F61),
                        checkedBgColor: const Color(
                          0xFFE0E3E5,
                        ).withOpacity(0.2),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Confirm Area
              const Divider(height: 1, color: Color(0xFFC3C6D6)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_selectedPriority);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF0047BB,
                      ), // Primary container blue
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Confirm & Apply',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.05,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          LucideIcons.checkCircle,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
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

  Widget _buildPriorityOptionCard({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required Color textColor,
    required Color iconColor,
    required Color iconBgColor,
    required Color checkedBorderColor,
    required Color checkedBgColor,
  }) {
    final isSelected = _selectedPriority == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? checkedBgColor : Colors.white,
          border: Border.all(
            color: isSelected ? checkedBorderColor : const Color(0xFFC3C6D6),
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Circle Icon Container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),

            // Middle Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                      // Custom Radio button indicator
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF434653),
                      height: 1.4,
                      fontFamily: 'Inter',
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
}

// Stateful bottom sheet filter widget matching PNG spec
class _FilterBottomSheet extends StatefulWidget {
  final String initialStatus;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final double? initialMinAmount;
  final double? initialMaxAmount;
  final String initialSortBy;
  final Function(
    String status,
    DateTime? start,
    DateTime? end,
    double? min,
    double? max,
    String sortBy,
  )
  onApply;

  const _FilterBottomSheet({
    required this.initialStatus,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.initialMinAmount,
    required this.initialMaxAmount,
    required this.initialSortBy,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String _status;
  DateTime? _startDate;
  DateTime? _endDate;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  late String _sortBy;
  late RangeValues _amountRange;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _sortBy = widget.initialSortBy;

    double minVal = widget.initialMinAmount ?? 0.0;
    double maxVal = widget.initialMaxAmount ?? 30000.0;
    if (minVal < 0.0) minVal = 0.0;
    if (maxVal > 30000.0) maxVal = 30000.0;
    if (minVal > maxVal) minVal = maxVal;
    _amountRange = RangeValues(minVal, maxVal);

    if (widget.initialMinAmount != null) {
      _minController.text = widget.initialMinAmount!.toStringAsFixed(0);
    }
    if (widget.initialMaxAmount != null) {
      _maxController.text = widget.initialMaxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'mm/dd/yyyy';
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
              // Drag handle
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

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1C30),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Color(0xFF1C1B1F),
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form Fields scroll list
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status chips section
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1C30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildStatusChip('Unassigned'),
                          _buildStatusChip('Assigned'),
                          _buildStatusChip('In-Progress'),
                          _buildStatusChip('Completed'),
                          _buildStatusChip('Failed'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Date range picker Row
                      const Text(
                        'Due Date Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1C30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF5C5F61),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF4FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFC3C6D6),
                                      ),
                                    ),
                                    child: Text(
                                      _formatDate(_startDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _startDate == null
                                            ? const Color(0xFF737685)
                                            : const Color(0xFF0B1C30),
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
                                const Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF5C5F61),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    height: 48,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF4FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFC3C6D6),
                                      ),
                                    ),
                                    child: Text(
                                      _formatDate(_endDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: _endDate == null
                                            ? const Color(0xFF737685)
                                            : const Color(0xFF0B1C30),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Amount range inputs Row
                      const Text(
                        'EMI Amount Range (₹)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1C30),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Theme(
                        data: Theme.of(context).copyWith(
                          sliderTheme: SliderThemeData(
                            activeTrackColor: const Color(0xFF00328A),
                            inactiveTrackColor: const Color(0xFFEFF4FF),
                            thumbColor: const Color(0xFF00328A),
                            overlayColor: const Color(0xFF00328A).withOpacity(0.12),
                            valueIndicatorColor: const Color(0xFF0B1C30),
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                            showValueIndicator: ShowValueIndicator.always,
                          ),
                        ),
                        child: RangeSlider(
                          values: _amountRange,
                          min: 0.0,
                          max: 30000.0,
                          divisions: 60,
                          labels: RangeLabels(
                            '₹${_amountRange.start.toStringAsFixed(0)}',
                            '₹${_amountRange.end.toStringAsFixed(0)}',
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _amountRange = values;
                              _minController.text = values.start.toStringAsFixed(0);
                              _maxController.text = values.end.toStringAsFixed(0);
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFC3C6D6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    '₹ ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF737685),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Expanded(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        inputDecorationTheme:
                                            const InputDecorationTheme(
                                              filled: false,
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedErrorBorder:
                                                  InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                      ),
                                      child: TextField(
                                        controller: _minController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          final parsed = double.tryParse(val) ?? 0.0;
                                          setState(() {
                                            _amountRange = RangeValues(
                                              parsed.clamp(0.0, _amountRange.end),
                                              _amountRange.end,
                                            );
                                          });
                                        },
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF0B1C30),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Min',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF737685),
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 48,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFC3C6D6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    '₹ ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF737685),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Expanded(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        inputDecorationTheme:
                                            const InputDecorationTheme(
                                              filled: false,
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              focusedErrorBorder:
                                                  InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                      ),
                                      child: TextField(
                                        controller: _maxController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          final parsed = double.tryParse(val) ?? 30000.0;
                                          setState(() {
                                            _amountRange = RangeValues(
                                              _amountRange.start,
                                              parsed.clamp(_amountRange.start, 30000.0),
                                            );
                                          });
                                        },
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF0B1C30),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Max',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF737685),
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                          ),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sort option list
                      const Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1C30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSortRadio('Newest First'),
                      _buildSortRadio('Oldest First'),
                      _buildSortRadio('Amount: High to Low'),
                      _buildSortRadio('Amount: Low to High'),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEFF1F5)),

              // Apply & Reset footer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _handleReset,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFC3C6D6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00328A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleApply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00328A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final isSelected = _status == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _status = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00328A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFC3C6D6),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF0B1C30),
          ),
        ),
      ),
    );
  }

  Widget _buildSortRadio(String optionName) {
    final isSelected = _sortBy == optionName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = optionName;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
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
                      : const Color(0xFFC3C6D6),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(3.5),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00328A),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              optionName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0B1C30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReset() {
    setState(() {
      _status = 'Unassigned';
      _startDate = null;
      _endDate = null;
      _minController.clear();
      _maxController.clear();
      _sortBy = 'Newest First';
      _amountRange = const RangeValues(0.0, 30000.0);
    });
  }

  void _handleApply() {
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    widget.onApply(_status, _startDate, _endDate, min, max, _sortBy);
    Navigator.pop(context);
  }
}

class _DeployAgentBottomSheet extends StatefulWidget {
  final Set<String> selectedCaseIds;
  final List<Agent> agents;
  final Function(Agent agent) onDeploy;

  const _DeployAgentBottomSheet({
    required this.selectedCaseIds,
    required this.agents,
    required this.onDeploy,
  });

  @override
  State<_DeployAgentBottomSheet> createState() => _DeployAgentBottomSheetState();
}

class _DeployAgentBottomSheetState extends State<_DeployAgentBottomSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAgents = widget.agents.where((agent) {
      final nameMatches = agent.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final zoneMatches = agent.zone.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || zoneMatches;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
              // Drag handle
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

              // Title Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Deploy Active Agent',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B1C30),
                        fontFamily: 'Inter',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Color(0xFF1C1B1F),
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Info Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Assigning ${widget.selectedCaseIds.length} Case${widget.selectedCaseIds.length > 1 ? 's' : ''} simultaneously.',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Bar Input
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search agent by name or zone...',
                          prefixIcon: const Icon(LucideIcons.search, color: AppTheme.outline, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.outline),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                              : null,

                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'SELECT AGENT PORTFOLIO TARGET:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.outline,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Active Agents list
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: filteredAgents.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'No active agents found',
                                    style: TextStyle(
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredAgents.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final agent = filteredAgents[index];
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
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppTheme.outlineVariant),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Assign All',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onDeploy(agent);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
