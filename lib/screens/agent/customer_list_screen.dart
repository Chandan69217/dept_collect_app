import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import 'customer_details_screen.dart';
import 'record_payment_sheet.dart';
import 'schedule_visit_sheet.dart';
import '../../widgets/custom_feedback.dart';

class CustomerListScreen extends StatefulWidget {
  final bool isEmbedded;

  const CustomerListScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _db = DatabaseService();
  String _searchQuery = '';
  String _selectedTab = 'ALL'; // 'ALL', 'OVERDUE', 'DUE_SOON', 'PAID'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(showProgress: true);
    });
  }

  Future<void> _refreshData({bool showProgress = false}) async {
    final agentId = _db.currentUser?.id;
    if (agentId == null) return;

    if (showProgress) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _db.fetchAgentAssignments(agentId);
    } catch (e) {
      if (mounted) {
        CustomFeedback.showToast(
          context,
          'Failed to load assignments: $e',
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

  // Premium visual filters state variables
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy = 'Newest First';

  String _formatDate(DateTime date, String customerId) {
    if (customerId == 'cust_robert') {
      return 'Oct 12, 2023';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _hasPermission(String fieldKey) {
    final user = _db.currentUser;
    if (user != null && !user.isAdmin) {
      return user.permissions[fieldKey] ?? true;
    }
    return true;
  }

  String _getMaskedText(String fieldKey, String value) {
    if (!_hasPermission(fieldKey)) {
      return '••••••••';
    }
    return value;
  }

  String _formatCurrency(double amount) {
    if (!_hasPermission('amountDue')) {
      return '••••';
    }
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String _getLocationSub(dynamic customer) {
    final bool hasAddr = _hasPermission('address');
    final String locName = hasAddr
        ? (customer.id == 'cust_robert'
            ? 'West Hills Park'
            : (customer.id == 'cust_jenkins' ? 'Downtown Plaza' : 'North Industrial'))
        : '••••••••';

    if (customer.id == 'cust_robert') return '0.8 km • $locName';
    if (customer.id == 'cust_jenkins') return '2.4 km • $locName';
    if (customer.status == 'PAID') return 'Paid on Oct 20';
    return '5.1 km • $locName';
  }

  String _getTxnId(String customerId) {
    if (customerId == 'cust_chen') return '#9821-XCA';
    return '#CSV-${customerId.hashCode.toString().substring(0, 4)}';
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FilterBottomSheet(
          initialStatus: _selectedTab,
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          initialMinAmount: _minAmount,
          initialMaxAmount: _maxAmount,
          initialSortBy: _sortBy,
          onApply: (status, start, end, min, max, sort) {
            setState(() {
              _selectedTab = status;
              _startDate = start;
              _endDate = end;
              _minAmount = min;
              _maxAmount = max;
              _sortBy = sort;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        final agentId = _db.currentUser?.id ?? '';

        // Filter customers assigned to active agent
        final List<dynamic> allAgentCustomers = _db.customers
            .where((c) => c.assignedAgentId == agentId)
            .toList();

        // Calculate dynamic filter counts
        final int totalCount = allAgentCustomers.length;
        final int overdueCount = allAgentCustomers.where((c) => c.status == 'Assigned' || c.status == 'Rejected').length;
        final int dueSoonCount = allAgentCustomers.where((c) => c.status == 'Pending' || c.status == 'Assigned' || c.status == 'Rejected').length;
        final int paidCount = allAgentCustomers.where((c) => c.status == 'Completed' || c.status == 'Closed').length;

        // Apply filters
        var filteredCustomers = allAgentCustomers.where((c) {
          final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.assetRegNo.toLowerCase().contains(_searchQuery.toLowerCase());
          if (!matchesSearch) return false;

          bool matchesTab = true;
          if (_selectedTab == 'OVERDUE') {
            matchesTab = c.status == 'Assigned' || c.status == 'Rejected';
          } else if (_selectedTab == 'DUE_SOON') {
            matchesTab = c.status == 'Pending' || c.status == 'Assigned' || c.status == 'Rejected';
          } else if (_selectedTab == 'PAID') {
            matchesTab = c.status == 'Completed' || c.status == 'Closed';
          }
          if (!matchesTab) return false;

          if (_minAmount != null && c.amountDue < _minAmount!) return false;
          if (_maxAmount != null && c.amountDue > _maxAmount!) return false;

          if (_startDate != null && c.dueDate.isBefore(_startDate!)) return false;
          if (_endDate != null && c.dueDate.isAfter(_endDate!.add(const Duration(days: 1)))) return false;

          return true;
        }).toList();

        // Sort customers based on selected criteria
        filteredCustomers.sort((a, b) {
          switch (_sortBy) {
            case 'Newest First':
              return b.dueDate.compareTo(a.dueDate);
            case 'Oldest First':
              return a.dueDate.compareTo(b.dueDate);
            case 'Amount: High to Low':
              return b.amountDue.compareTo(a.amountDue);
            case 'Amount: Low to High':
              return a.amountDue.compareTo(b.amountDue);
            default:
              return 0;
          }
        });

        final content = Column(
          children: [
            if (_isLoading) CustomFeedback.showProgressIndicator(),
            // Search & Filter Sticky Area
            Container(
              color: AppTheme.background,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Bar Input
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search customers by name or ID...',
                              prefixIcon: const Icon(LucideIcons.search, color: AppTheme.outline),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.outline),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => _showFilterBottomSheet(),
                          icon: const Icon(
                            LucideIcons.slidersHorizontal,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          label: Text(
                            _selectedTab == 'ALL'
                                ? 'Filter'
                                : 'Filter: ${_selectedTab == 'DUE_SOON' ? 'Due Soon' : _selectedTab[0] + _selectedTab.substring(1).toLowerCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Stats filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // All Tab
                        _buildFilterTab(
                          label: 'All ($totalCount)',
                          isActive: _selectedTab == 'ALL',
                          color: AppTheme.primary,
                          onTap: () {
                            setState(() {
                              _selectedTab = 'ALL';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        // Overdue Tab
                        _buildFilterTab(
                          label: 'Overdue ($overdueCount)',
                          isActive: _selectedTab == 'OVERDUE',
                          color: AppTheme.error,
                          onTap: () {
                            setState(() {
                              _selectedTab = 'OVERDUE';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        // Due Soon Tab
                        _buildFilterTab(
                          label: 'Due Soon ($dueSoonCount)',
                          isActive: _selectedTab == 'DUE_SOON',
                          color: Colors.orange,
                          onTap: () {
                            setState(() {
                              _selectedTab = 'DUE_SOON';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        // Paid Tab
                        _buildFilterTab(
                          label: 'Paid ($paidCount)',
                          isActive: _selectedTab == 'PAID',
                          color: AppTheme.success,
                          onTap: () {
                            setState(() {
                              _selectedTab = 'PAID';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List of Customer Cards
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refreshData(),
                color: AppTheme.primary,
                child: filteredCustomers.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.users,
                                size: 64,
                                color: AppTheme.secondary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Customers Found',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try altering your search or filters.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filteredCustomers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          final bool isPaid = customer.status == 'Completed' || customer.status == 'Closed';
                          final bool isPending = customer.status == 'Pending';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerDetailsScreen(customer: customer),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isPaid ? AppTheme.surfaceContainer : Colors.white,
                                border: Border.all(
                                  color: AppTheme.outlineVariant.withOpacity(isPaid ? 0.5 : 1.0),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Top Title Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getMaskedText('name', customer.name),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isPaid ? AppTheme.secondary : AppTheme.onSurface,
                                                decoration: isPaid ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  isPaid ? LucideIcons.circleCheck : LucideIcons.mapPin,
                                                  size: 14,
                                                  color: isPaid ? AppTheme.success : AppTheme.outline,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _getLocationSub(customer),
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: AppTheme.outline,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status Badge tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPaid
                                              ? const Color(0xFFECFDF5)
                                              : (isPending ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isPaid
                                              ? 'PAID'
                                              : (isPending ? 'DUE SOON' : 'OVERDUE'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isPaid
                                                ? const Color(0xFF065F46)
                                                : (isPending ? const Color(0xFF9A3412) : const Color(0xFF991B1B)),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Card Body Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'EMI AMOUNT',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  fontSize: 10,
                                                  color: isPaid ? AppTheme.outline : AppTheme.secondary,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCurrency(customer.amountDue),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isPaid ? AppTheme.secondary : AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            isPaid ? 'TRANSACTION ID' : 'DUE DATE',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  fontSize: 10,
                                                  color: isPaid ? AppTheme.outline : AppTheme.secondary,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isPaid
                                                ? _getTxnId(customer.id)
                                                : _formatDate(customer.dueDate, customer.id),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isPaid
                                                  ? AppTheme.secondary
                                                  : (customer.status == 'Assigned' || customer.status == 'Rejected'
                                                      ? AppTheme.error
                                                      : AppTheme.onSurface),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Unpaid buttons Actions row
                                  if (!isPaid) ...[
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isPending ? Colors.white : AppTheme.primary,
                                                foregroundColor: isPending ? AppTheme.primary : Colors.white,
                                                side: isPending
                                                    ? const BorderSide(color: AppTheme.primary)
                                                    : null,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                              ),
                                              onPressed: () {
                                                if (isPending) {
                                                  if (!_hasPermission('editDetails')) {
                                                    CustomFeedback.showToast(
                                                      context,
                                                      'You do not have permission to schedule follow-up visits.',
                                                      type: 'error',
                                                    );
                                                    return;
                                                  }
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor: Colors.transparent,
                                                    builder: (context) => ScheduleVisitSheet(customer: customer),
                                                  );
                                                } else {
                                                  if (!_hasPermission('approvePartial')) {
                                                    CustomFeedback.showToast(
                                                      context,
                                                      'You do not have permission to collect payments.',
                                                      type: 'error',
                                                    );
                                                    return;
                                                  }
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor: Colors.transparent,
                                                    builder: (context) => RecordPaymentSheet(customer: customer),
                                                  );
                                                }
                                              },
                                              icon: Icon(
                                                isPending ? LucideIcons.notebookPen : LucideIcons.banknote,
                                                size: 16,
                                              ),
                                              label: Text(
                                                isPending ? 'Record Visit' : 'Collect',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppTheme.outlineVariant),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              customer.status == 'Assigned' || customer.status == 'Rejected'
                                                  ? LucideIcons.navigation
                                                  : LucideIcons.phone,
                                              color: AppTheme.primary,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              if (customer.status == 'Assigned' || customer.status == 'Rejected') {
                                                if (!_hasPermission('address')) {
                                                  CustomFeedback.showToast(
                                                    context,
                                                    'Address access denied.',
                                                    type: 'warning',
                                                  );
                                                  return;
                                                }
                                                final address = customer.address;
                                                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
                                                try {
                                                  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                                                  if (!launched) {
                                                    await launchUrl(url, mode: LaunchMode.platformDefault);
                                                  }
                                                } catch (e) {
                                                  try {
                                                    await launchUrl(url, mode: LaunchMode.platformDefault);
                                                  } catch (e2) {
                                                    if (context.mounted) {
                                                      CustomFeedback.showToast(
                                                        context,
                                                        'Could not launch maps: $e2',
                                                        type: 'error',
                                                      );
                                                    }
                                                  }
                                                }
                                              } else {
                                                if (!_hasPermission('phone')) {
                                                  CustomFeedback.showToast(
                                                    context,
                                                    'Calling permission denied.',
                                                    type: 'warning',
                                                  );
                                                  return;
                                                }
                                                final phone = customer.phone.trim();
                                                if (phone.isEmpty) {
                                                  CustomFeedback.showToast(
                                                    context,
                                                    'Phone number not available.',
                                                    type: 'warning',
                                                  );
                                                  return;
                                                }
                                                final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                                                try {
                                                  if (await canLaunchUrl(phoneUri)) {
                                                    await launchUrl(phoneUri);
                                                  } else {
                                                    if (context.mounted) {
                                                      CustomFeedback.showToast(
                                                        context,
                                                        'Could not launch dialer.',
                                                        type: 'error',
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    CustomFeedback.showToast(
                                                      context,
                                                      'Error placing call: $e',
                                                      type: 'error',
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            )
          ],
        );

        if (widget.isEmbedded) return content;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.menu, color: AppTheme.primary),
              onPressed: () {
                // Can open drawer
              },
            ),
            title: const Text(
              AppTheme.appName,
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isActive ? AppTheme.primary.withOpacity(0.2) : AppTheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? AppTheme.primary : AppTheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stateful bottom sheet filter widget matching premium visual style
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
  ) onApply;

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
                          _buildStatusChip('ALL', 'All'),
                          _buildStatusChip('OVERDUE', 'Overdue'),
                          _buildStatusChip('DUE_SOON', 'Due Soon'),
                          _buildStatusChip('PAID', 'Paid'),
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

  Widget _buildStatusChip(String value, String label) {
    final isSelected = _status == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _status = value;
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
      _status = 'ALL';
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
