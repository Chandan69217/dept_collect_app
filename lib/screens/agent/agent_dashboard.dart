import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/status_chip.dart';
import '../shared/login_screen.dart';
import '../shared/notifications_screen.dart';
import 'customer_list_screen.dart';
import 'customer_details_screen.dart';
import 'collections_history_screen.dart';
import 'agent_profile_screen.dart';
import 'record_payment_sheet.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  int _currentIndex = 0;
  final _db = DatabaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        final agent = _db.currentUser;
        if (agent == null) return const SizedBox();

        final List<Widget> pages = [
          _buildHomeDashboard(context, agent),
          const CustomerListScreen(isEmbedded: true),
          const CollectionsHistoryScreen(isEmbedded: true),
          const AgentProfileScreen(isEmbedded: true),
        ];

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.primary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(AppTheme.appIcon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  AppTheme.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: _db.notifications.any((n) => !n.isRead),
                  child: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: _buildDrawer(context, agent),
          body: pages[_currentIndex],
          bottomNavigationBar: CustomBottomBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              CustomBottomBarItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
              ),
              CustomBottomBarItem(
                icon: Icons.person_search_outlined,
                activeIcon: Icons.person_search,
                label: 'Customers',
              ),
              CustomBottomBarItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'History',
              ),
              CustomBottomBarItem(
                icon: Icons.account_circle_outlined,
                activeIcon: Icons.account_circle,
                label: 'Profile',
              ),
            ],
          ),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  onPressed: () {
                    // Navigate to priority visit customer details
                    final robert = _db.customers.firstWhere((c) => c.id == 'cust_robert');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDetailsScreen(customer: robert),
                      ),
                    );
                  },
                  child: const Icon(Icons.location_on),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHomeDashboard(BuildContext context, dynamic agent) {
    // Find next priority customer (Robert Henderson)
    final priorityCustomer = _db.customers.firstWhere(
      (c) => c.id == 'cust_robert',
      orElse: () => _db.customers[0],
    );

    final targetMetPercent = (agent.collectedAmount / agent.assignedTarget * 100).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Good Morning miller
          Text(
            'Good Morning, ${agent.name}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily Overview',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 24),

          // Bento Grid Asymmetric Layout
          Column(
            children: [
              // Today's Collection Card
              CustomBentoCard(
                backgroundColor: AppTheme.primaryContainer,
                borderSide: BorderSide.none,
                backgroundDecoration: Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Transform.translate(
                        offset: const Offset(20, 20),
                        child: const Icon(Icons.payments, size: 140, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Collection Target",
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${agent.assignedTarget.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$targetMetPercent% of Target Met (₹${agent.collectedAmount.toStringAsFixed(2)} collected)',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Two grid item
              Row(
                children: [
                  Expanded(
                    child: CustomBentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: const Icon(Icons.group, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${agent.casesCount}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Assigned Today',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomBentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.errorContainer,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: const Icon(Icons.pending_actions, color: AppTheme.error, size: 20),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${agent.pendingVisitsCount}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Pending Visits',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Next Priority Visit Section
          Text(
            'NEXT PRIORITY VISIT',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 12),
          CustomBentoCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerDetailsScreen(customer: priorityCustomer),
                ),
              );
            },
            child: Row(
              children: [
                // map route thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Center(
                    child: Icon(Icons.map, color: AppTheme.primary, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priorityCustomer.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.secondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              priorityCustomer.address,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const StatusChip(label: 'HIGH PRIORITY', type: 'HIGH'),
                          const SizedBox(width: 8),
                          Text(
                            'Due: 10:30 AM',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.outline),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Field Actions
          Text(
            'FIELD ACTIONS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Trigger record payment sheet for Henderson
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => RecordPaymentSheet(customer: priorityCustomer),
                      );
                    },
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Scan Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to customers tab to start selection
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('New Collection', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic agent) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(agent.avatarUrl),
            ),
            accountName: Text(
              agent.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              'Zone: ${agent.zone} (ID: ${agent.id})',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: AppTheme.primary),
            title: const Text('Switch to Admin Portal', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Test synchronizations live'),
            onTap: () {
              Navigator.pop(context); // close drawer
              _db.switchPortal('ADMIN');
              Navigator.of(context).pushReplacementNamed('/admin_dashboard');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Recent Activity'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security & Privacy'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/security_settings');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Sign Out', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            onTap: () {
              _db.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
