import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import 'agent_edit_profile_screen.dart';
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
              icon: const Icon(LucideIcons.menu, color: AppTheme.primary),
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
                  child: const Icon(LucideIcons.bell, color: AppTheme.primary),
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
                icon: LucideIcons.layoutDashboard,
                activeIcon: LucideIcons.layoutDashboard,
                label: 'Dashboard',
              ),
              CustomBottomBarItem(
                icon: LucideIcons.userSearch,
                activeIcon: LucideIcons.userSearch,
                label: 'Customers',
              ),
              CustomBottomBarItem(
                icon: LucideIcons.scrollText,
                activeIcon: LucideIcons.scrollText,
                label: 'History',
              ),
              CustomBottomBarItem(
                icon: LucideIcons.circleUser,
                activeIcon: LucideIcons.circleUser,
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
                  child: const Icon(LucideIcons.mapPin),
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
                        child: const Icon(LucideIcons.banknote, size: 140, color: Colors.white),
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
                        const Icon(LucideIcons.trendingUp, color: Colors.white, size: 16),
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
                            child: const Icon(LucideIcons.users, color: AppTheme.primary, size: 20),
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
                            child: const Icon(LucideIcons.clipboardList, color: AppTheme.error, size: 20),
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
                    child: Icon(LucideIcons.map, color: AppTheme.primary, size: 28),
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
                          const Icon(LucideIcons.mapPin, size: 14, color: AppTheme.secondary),
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
                const Icon(LucideIcons.chevronRight, color: AppTheme.outline),
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
                    icon: const Icon(LucideIcons.scrollText, size: 18),
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
                    icon: const Icon(LucideIcons.circlePlus, size: 18),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, Color(0xFF0047BB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(agent.avatarUrl),
              ),
            ),
            accountName: Text(
              agent.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white, letterSpacing: -0.2),
            ),
            accountEmail: Text(
              'Zone: ${agent.zone} (ID: ${agent.id.toUpperCase()})',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),

          // Recent Activity
          ListTile(
            leading: const Icon(LucideIcons.history, color: AppTheme.primary, size: 20),
            title: const Text(
              'Recent Activity',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'View synced operations logs',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          const Divider(height: 1),

          // Security & Privacy
          ListTile(
            leading: const Icon(LucideIcons.shield, color: AppTheme.primary, size: 20),
            title: const Text(
              'Security & Privacy',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'Manage PIN & security settings',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/security_settings');
            },
          ),
          const Divider(height: 1),

          // Edit Agent Profile settings
          ListTile(
            leading: const Icon(LucideIcons.userCog, color: AppTheme.primary, size: 20),
            title: const Text(
              'Edit Profile Settings',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'Update name, contact & photo',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgentEditProfileScreen()),
              );
            },
          ),
          const Divider(height: 1),

          const Spacer(),
          const Divider(height: 1),

          // Switch to Admin Portal
          ListTile(
            leading: const Icon(LucideIcons.arrowLeftRight, color: AppTheme.primary, size: 20),
            title: const Text(
              'Switch to Admin Portal',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'Test synchronizations live',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context); // close drawer
              _db.switchPortal('ADMIN');
              Navigator.of(context).pushReplacementNamed('/admin_dashboard');
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(LucideIcons.logOut, color: AppTheme.error, size: 20),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'Terminate secure agent session',
              style: TextStyle(fontSize: 11, color: AppTheme.secondary),
            ),
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
