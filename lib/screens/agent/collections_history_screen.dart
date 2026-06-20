import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/custom_feedback.dart';

class CollectionsHistoryScreen extends StatefulWidget {
  final bool isEmbedded;

  const CollectionsHistoryScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<CollectionsHistoryScreen> createState() => _CollectionsHistoryScreenState();
}

class _CollectionsHistoryScreenState extends State<CollectionsHistoryScreen> {
  final db = DatabaseService();
  final _searchController = TextEditingController();
  
  String _activeFilter = 'ALL'; // 'ALL', 'PENDING', 'COMPLETED', 'REJECTED'
  String _dateFilter = 'ALL'; // 'ALL', 'TODAY', 'YESTERDAY', 'WEEK' (Last 7 days)
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(showProgress: true);
    });
  }

  Future<void> _refreshData({bool showProgress = false}) async {
    final agentId = db.currentUser?.id;
    if (agentId == null) return;

    if (showProgress) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await db.fetchAgentAssignments(agentId);
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, child) {
        final agentId = db.currentUser?.id ?? 'miller';

        // Filter collections logged by this agent
        final personalPayments = db.payments.where((p) => p.agentId == agentId).toList();
        
        // 1. Apply Status Filter Tab
        var filteredPayments = personalPayments.where((p) {
          if (_activeFilter == 'ALL') return true;
          if (_activeFilter == 'COMPLETED') {
            return p.status.toUpperCase() == 'COMPLETED' || p.status.toUpperCase() == 'PAID' || p.status.toUpperCase() == 'CLOSED';
          }
          return p.status.toUpperCase() == _activeFilter;
        }).toList();

        // 2. Apply Date Range Filter
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));
        final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));

        filteredPayments = filteredPayments.where((p) {
          if (_dateFilter == 'ALL') return true;
          if (_dateFilter == 'TODAY') {
            return p.timestamp.isAfter(todayStart);
          }
          if (_dateFilter == 'YESTERDAY') {
            return p.timestamp.isAfter(yesterdayStart) && p.timestamp.isBefore(todayStart);
          }
          if (_dateFilter == 'WEEK') {
            return p.timestamp.isAfter(sevenDaysAgo);
          }
          return true;
        }).toList();

        // 3. Apply Search Query Filter
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.toLowerCase().trim();
          filteredPayments = filteredPayments.where((p) {
            return p.customerName.toLowerCase().contains(query) ||
                   p.id.toLowerCase().contains(query) ||
                   p.transactionReference.toLowerCase().contains(query);
          }).toList();
        }

        // Calculate summary aggregates (only for approved and pending collections)
        final double totalApprovedToday = personalPayments
            .where((p) => p.status.toUpperCase() == 'COMPLETED' || p.status.toUpperCase() == 'PAID' || p.status.toUpperCase() == 'CLOSED')
            .fold(0.0, (sum, p) => sum + p.amount);

        final double totalPendingToday = personalPayments
            .where((p) => p.status.toUpperCase() == 'PENDING')
            .fold(0.0, (sum, p) => sum + p.amount);

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) CustomFeedback.showProgressIndicator(),
            // 1. Ledger Summary card with rich gradients
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: CustomBentoCard(
                backgroundColor: AppTheme.primary,
                borderSide: BorderSide.none,
                padding: 18.0,
                backgroundDecoration: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF0047BB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COLLECTIONS BALANCE LEDGER',
                              style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Total Recovered',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '₹${totalApprovedToday.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(height: 10),
                    // Secondary stats row: Pending amounts
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pending Verification: ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '₹${totalPendingToday.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Interactive Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.8),
                    width: _searchQuery.isNotEmpty ? 1.5 : 1,
                  ),
                  boxShadow: _searchQuery.isNotEmpty
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.search, color: AppTheme.secondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, color: AppTheme.secondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    hintText: 'Search by debtor name, TXN, or reference...',
                    hintStyle: TextStyle(color: AppTheme.secondary.withOpacity(0.6), fontSize: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Date Filter Chips Row (All, Today, Yesterday, Last 7 Days)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildDateChip('ALL', 'All Time'),
                    const SizedBox(width: 8),
                    _buildDateChip('TODAY', 'Today'),
                    const SizedBox(width: 8),
                    _buildDateChip('YESTERDAY', 'Yesterday'),
                    const SizedBox(width: 8),
                    _buildDateChip('WEEK', 'Last 7 Days'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4. Status Filter Tabs Row (All, Pending, Completed, Rejected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterTab('ALL', personalPayments.length),
                    const SizedBox(width: 8),
                    _buildFilterTab('PENDING', personalPayments.where((p) => p.status.toUpperCase() == 'PENDING').length),
                    const SizedBox(width: 8),
                    _buildFilterTab('COMPLETED', personalPayments.where((p) => p.status.toUpperCase() == 'COMPLETED' || p.status.toUpperCase() == 'PAID' || p.status.toUpperCase() == 'CLOSED').length),
                    const SizedBox(width: 8),
                    _buildFilterTab('REJECTED', personalPayments.where((p) => p.status.toUpperCase() == 'REJECTED').length),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Transactions List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refreshData(),
                color: AppTheme.primary,
                child: filteredPayments.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.scrollText,
                                size: 64,
                                color: AppTheme.secondary.withOpacity(0.25),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Collections Logged',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No logged payments match your search criteria: "$_searchQuery"'
                                      : 'No logged transactions match the selected filter categories.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.secondary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: filteredPayments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredPayments[index];
                          IconData icon;
                          Color iconColor;

                          switch (item.paymentMethod.toUpperCase()) {
                            case 'UPI':
                              icon = LucideIcons.qrCode;
                              iconColor = AppTheme.primary;
                              break;
                            case 'CHEQUE':
                              icon = LucideIcons.fileText;
                              iconColor = Colors.purple;
                              break;
                            default:
                              icon = LucideIcons.banknote;
                              iconColor = const Color(0xFF1B5E20);
                          }

                          return CustomBentoCard(
                            padding: 14.0,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.customerName,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${item.paymentMethod} • ',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.secondary,
                                            ),
                                          ),
                                          Text(
                                            item.id,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} - ${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}',
                                        style: TextStyle(
                                          fontSize: 10, 
                                          color: AppTheme.secondary.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${item.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.onSurface,
                                        fontSize: 15,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    StatusChip(label: item.status, type: item.status),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );

        if (widget.isEmbedded) return content;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Collections Ledger'),
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildFilterTab(String label, int count) {
    final bool isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryContainer.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String value, String label) {
    final bool isActive = _dateFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _dateFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
