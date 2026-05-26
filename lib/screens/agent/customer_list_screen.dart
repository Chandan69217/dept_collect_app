import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import 'customer_details_screen.dart';
import 'record_payment_sheet.dart';
import 'schedule_visit_sheet.dart';

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
  String _selectedTab = 'ALL'; // 'ALL', 'OVERDUE', 'DUE_SOON'

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

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String _getLocationSub(dynamic customer) {
    if (customer.id == 'cust_robert') return '0.8 km • West Hills Park';
    if (customer.id == 'cust_jenkins') return '2.4 km • Downtown Plaza';
    if (customer.status == 'PAID') return 'Paid on Oct 20';
    return '5.1 km • North Industrial';
  }

  String _getTxnId(String customerId) {
    if (customerId == 'cust_chen') return '#9821-XCA';
    return '#CSV-${customerId.hashCode.toString().substring(0, 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        final agentId = _db.currentUser?.id ?? 'miller';

        // Filter customers assigned to active agent
        final List<dynamic> allAgentCustomers = _db.customers
            .where((c) => c.assignedAgentId == agentId)
            .toList();

        // Calculate dynamic filter counts
        final int totalCount = allAgentCustomers.length;
        final int overdueCount = allAgentCustomers.where((c) => c.status == 'OVERDUE').length;
        final int dueSoonCount = allAgentCustomers.where((c) => c.status == 'PENDING_VERIFICATION' || c.status == 'OVERDUE').length;

        // Apply filters
        final filteredCustomers = allAgentCustomers.where((c) {
          final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.address.toLowerCase().contains(_searchQuery.toLowerCase());

          bool matchesTab = true;
          if (_selectedTab == 'OVERDUE') {
            matchesTab = c.status == 'OVERDUE';
          } else if (_selectedTab == 'DUE_SOON') {
            matchesTab = c.status == 'PENDING_VERIFICATION' || c.status == 'OVERDUE';
          }

          return matchesSearch && matchesTab;
        }).toList();

        final content = Column(
          children: [
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
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceContainerHigh,
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Filter configurations triggered.')),
                            );
                          },
                          child: const Text('Filter', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List of Customer Cards
            Expanded(
              child: filteredCustomers.isEmpty
                  ? Center(
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
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: filteredCustomers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final bool isPaid = customer.status == 'PAID';
                        final bool isPending = customer.status == 'PENDING_VERIFICATION';

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
                                            customer.name,
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
                                                : (customer.status == 'OVERDUE'
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
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor: Colors.transparent,
                                                  builder: (context) => ScheduleVisitSheet(customer: customer),
                                                );
                                              } else {
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
                                            customer.status == 'OVERDUE'
                                                ? LucideIcons.navigation
                                                : LucideIcons.phone,
                                            color: AppTheme.primary,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            if (customer.status == 'OVERDUE') {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Opening Navigation Route direction...')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Calling customer ${customer.name} at ${customer.phone}...')),
                                              );
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
