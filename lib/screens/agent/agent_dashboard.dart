import 'package:dept_collection_app/widgets/custom_feedback.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/status_chip.dart';
import '../shared/login_screen.dart';
// import '../shared/notifications_screen.dart';
import 'customer_list_screen.dart';
import 'customer_details_screen.dart';
import 'collections_history_screen.dart';
import 'agent_profile_screen.dart';
import 'agent_edit_profile_screen.dart';
import 'record_payment_sheet.dart';
import '../../models/customer.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  int _currentIndex = 0;
  final _db = DatabaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final agentId = _db.currentUser?.id;
      if (agentId != null) {
        setState(() {
          _isLoading = true;
        });
        try {
          await _db.fetchAgentAssignments(agentId);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load assignments: $e')),
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
    });
  }

  Customer? _getPriorityCustomer() {
    if (_db.customers.isEmpty) return null;
    final agentId = _db.currentUser?.id;
    final myCustomers = _db.customers
        .where((c) => c.assignedAgentId == agentId)
        .toList();
    if (myCustomers.isEmpty) return null;

    final highPriority = myCustomers
        .where((c) => c.priority.toUpperCase() == 'HIGH')
        .firstOrNull;
    if (highPriority != null) return highPriority;
    final robert = myCustomers.where((c) => c.id == 'cust_robert').firstOrNull;
    if (robert != null) return robert;
    return myCustomers.first;
  }

  bool _hasPermission(String fieldKey) {
    final user = _db.currentUser;
    if (user != null && !user.isAdmin) {
      return user.permissions[fieldKey] ?? false;
    }
    return false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.menu, color: AppTheme.primary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              titleSpacing: 0,
              title: Row(
                children: [
                  Image.asset(
                    AppTheme.appLogo,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppTheme.appName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                      // style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      //   color: AppTheme.primary,
                      //   fontWeight: FontWeight.w800,
                      // ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                // IconButton(
                //   icon: Badge(
                //     isLabelVisible: _db.notifications.any((n) => !n.isRead),
                //     child: const Icon(
                //       LucideIcons.bell,
                //       color: AppTheme.primary,
                //     ),
                //   ),
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => const NotificationsScreen(),
                //       ),
                //     );
                //   },
                // ),
                const SizedBox(width: 8),
              ],
            ),
            drawer: _buildDrawer(context, agent),
            body: pages[_currentIndex],
            bottomNavigationBar: CustomBottomBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 2 && !_hasPermission('accessHistory')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You do not have permission to view history.',
                      ),
                    ),
                  );
                  return;
                }
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
            floatingActionButton:
                _hasPermission('priority') && _currentIndex == 0
                ? Builder(
                    builder: (context) {
                      final pc = _getPriorityCustomer();
                      if (pc == null) return const SizedBox();
                      return FloatingActionButton(
                        backgroundColor: AppTheme.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CustomerDetailsScreen(customer: pc),
                            ),
                          );
                        },
                        child: const Icon(LucideIcons.mapPin),
                      );
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildHomeDashboard(BuildContext context, dynamic agent) {
    final priorityCustomer = _getPriorityCustomer();

    final double targetMetPercentVal = agent.assignedTarget > 0
        ? (agent.collectedAmount / agent.assignedTarget * 100)
        : 0.0;
    final targetMetPercent = targetMetPercentVal.toStringAsFixed(0);

    final hour = DateTime.now().hour;
    final String greetingStr;
    if (hour < 12) {
      greetingStr = 'Good Morning';
    } else if (hour < 17) {
      greetingStr = 'Good Afternoon';
    } else {
      greetingStr = 'Good Evening';
    }

    return RefreshIndicator(
      onRefresh: () async {
        final agentId = _db.currentUser?.id;
        if (agentId != null) {
          await _db.fetchAgentAssignments(agentId);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (_isLoading) ...[
              CustomFeedback.showProgressIndicator(),
              // const SizedBox(height: 8),
            ],
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wishing based on local time
                  Text(
                    '$greetingStr, ${agent.name}',
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
                  const SizedBox(height: 16),
                  _buildQuickSearchBar(context),
                  const SizedBox(height: 24),
                  if (_searchQuery.isNotEmpty) ...[
                    _buildSearchResults(context),
                  ] else ...[
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
                                  child: const Icon(
                                    LucideIcons.banknote,
                                    size: 140,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Total Recovered",
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₹${agent.collectedAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.trendingUp,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$targetMetPercent% of Target Met (Target: ₹${agent.assignedTarget.toStringAsFixed(2)})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
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
                                        color: AppTheme.primaryContainer
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall,
                                        ),
                                      ),
                                      child: const Icon(
                                        LucideIcons.users,
                                        color: AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${agent.casesCount}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Assigned Today',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
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
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall,
                                        ),
                                      ),
                                      child: const Icon(
                                        LucideIcons.clipboardList,
                                        color: AppTheme.error,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${agent.pendingVisitsCount}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AppTheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Pending Visits',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
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
                    if (!_hasPermission('priority'))
                      CustomBentoCard(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.shieldAlert,
                                color: AppTheme.secondary.withOpacity(0.5),
                                size: 32,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'You have no permission to view',
                                style: TextStyle(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (priorityCustomer != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomBentoCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerDetailsScreen(
                                    customer: priorityCustomer,
                                  ),
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
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.map,
                                      color: AppTheme.primary,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        priorityCustomer.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.mapPin,
                                            size: 14,
                                            color: AppTheme.secondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              priorityCustomer.address,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          StatusChip(
                                            label:
                                                '${priorityCustomer.priority.toUpperCase()} PRIORITY',
                                            type: priorityCustomer.priority
                                                .toUpperCase(),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Due: 10:30 AM',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  LucideIcons.chevronRight,
                                  color: AppTheme.outline,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Quick Field Actions
                          Text(
                            'FIELD ACTIONS',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
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
                                      if (!_hasPermission('approvePartial')) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'You do not have permission to collect payments.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      // Trigger record payment sheet for priority customer
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            RecordPaymentSheet(
                                              customer: priorityCustomer,
                                            ),
                                      );
                                    },
                                    icon: const Icon(
                                      LucideIcons.scrollText,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Scan Receipt',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
                                    icon: const Icon(
                                      LucideIcons.circlePlus,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'New Collection',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            accountEmail: Text(
              'Zone: ${agent.zone} (ID: ${agent.id.toUpperCase()})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Recent Activity
          ListTile(
            leading: const Icon(
              LucideIcons.history,
              color: AppTheme.primary,
              size: 20,
            ),
            title: const Text(
              'Recent Activity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
                fontSize: 14,
              ),
            ),
            subtitle: const Text(
              'View synced operations logs',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              if (!_hasPermission('accessHistory')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You do not have permission to view history.',
                    ),
                  ),
                );
                return;
              }
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          const Divider(height: 1),

          // Security & Privacy
          // ListTile(
          //   leading: const Icon(
          //     LucideIcons.shield,
          //     color: AppTheme.primary,
          //     size: 20,
          //   ),
          //   title: const Text(
          //     'Security & Privacy',
          //     style: TextStyle(
          //       fontWeight: FontWeight.bold,
          //       color: AppTheme.onSurface,
          //       fontSize: 14,
          //     ),
          //   ),
          //   subtitle: const Text(
          //     'Manage PIN & security settings',
          //     style: TextStyle(fontSize: 12, color: AppTheme.secondary),
          //   ),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.of(context).pushNamed('/security_settings');
          //   },
          // ),
          // const Divider(height: 1),

          // Edit Agent Profile settings
          ListTile(
            leading: const Icon(
              LucideIcons.userCog,
              color: AppTheme.primary,
              size: 20,
            ),
            title: const Text(
              'Edit Profile Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
                fontSize: 14,
              ),
            ),
            subtitle: const Text(
              'Update name, contact & photo',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentEditProfileScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),

          const Spacer(),
          const Divider(height: 1),

          // Switch to Admin Portal
          // ListTile(
          //   leading: const Icon(
          //     LucideIcons.arrowLeftRight,
          //     color: AppTheme.primary,
          //     size: 20,
          //   ),
          //   title: const Text(
          //     'Switch to Admin Portal',
          //     style: TextStyle(
          //       fontWeight: FontWeight.bold,
          //       color: AppTheme.onSurface,
          //       fontSize: 14,
          //     ),
          //   ),
          //   subtitle: const Text(
          //     'Test synchronizations live',
          //     style: TextStyle(fontSize: 12, color: AppTheme.secondary),
          //   ),
          //   onTap: () {
          //     Navigator.pop(context); // close drawer
          //     _db.switchPortal('ADMIN');
          //     Navigator.of(context).pushReplacementNamed('/admin_dashboard');
          //   },
          // ),
          // const Divider(height: 1),
          ListTile(
            leading: const Icon(
              LucideIcons.logOut,
              color: AppTheme.error,
              size: 20,
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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

  Widget _buildQuickSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppTheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Search assigned cases (name, ID, address)...',
        hintStyle: TextStyle(
          color: AppTheme.secondary.withOpacity(0.6),
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.search,
              color: AppTheme.primary,
              size: 18,
            ),
          ),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.outlineVariant.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      color: AppTheme.secondary,
                      size: 14,
                    ),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              )
            : null,
        // border: InputBorder.none,
        // enabledBorder: InputBorder.none,
        // focusedBorder: InputBorder.none,
        // contentPadding: const EdgeInsets.symmetric(
        //   horizontal: 16,
        //   vertical: 16,
        // ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final agentId = _db.currentUser?.id ?? 'miller';
    final List<dynamic> matchingCustomers = _db.customers
        .where(
          (c) =>
              c.assignedAgentId == agentId &&
              (c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  c.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  c.address.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  c.assetRegNo.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  )),
        )
        .toList();

    if (matchingCustomers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.userSearch,
              size: 48,
              color: AppTheme.secondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching cases assigned to you',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.secondary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            'SEARCH RESULTS (${matchingCustomers.length})',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: matchingCustomers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final customer = matchingCustomers[index];
            final bool isPaid =
                customer.status == 'Completed' || customer.status == 'Closed';
            final bool isPending = customer.status == 'Pending';

            return CustomBentoCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CustomerDetailsScreen(customer: customer),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppTheme.successContainer
                          : (isPending
                                ? AppTheme.warningContainer
                                : AppTheme.errorContainer),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isPaid
                            ? LucideIcons.circleCheck
                            : (isPending
                                  ? LucideIcons.hourglass
                                  : LucideIcons.circleAlert),
                        color: isPaid
                            ? AppTheme.success
                            : (isPending ? AppTheme.warning : AppTheme.error),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? AppTheme.secondary
                                : AppTheme.onSurface,
                            decoration: isPaid
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: AppTheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customer.address,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${customer.amountDue.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? AppTheme.secondary : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? AppTheme.success
                              : (isPending ? AppTheme.warning : AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
