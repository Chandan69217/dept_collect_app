import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/performance_chart.dart';
import '../shared/login_screen.dart';
import '../shared/notifications_screen.dart';
import 'agent_tracking_screen.dart';
import 'case_assignment_screen.dart';
import 'verification_queue_screen.dart';
import 'upload_data_screen.dart';
import 'uploaded_records_view.dart';
import 'add_agent_screen.dart';
import '../agent/agent_edit_profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final _db = DatabaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        final admin = _db.currentUser;
        if (admin == null) return const SizedBox();

        // Count pending approvals
        final pendingCount = _db.payments.where((p) => p.status == 'PENDING').length;
        final adminUnreadCount = _db.notifications
            .where((n) => n.recipientRole == 'ADMIN' && !n.isRead)
            .length;

        final List<Widget> pages = [
          _buildHomeDashboard(context, pendingCount),
          const AgentTrackingScreen(isEmbedded: true),
          const CaseAssignmentScreen(isEmbedded: true),
          const VerificationQueueScreen(isEmbedded: true),
        ];

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(LucideIcons.menu, color: AppTheme.primary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: const Text(
              'Agency Admin',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            actions: [
              IconButton(
                icon: Badge(
                  label: Text('$adminUnreadCount'),
                  isLabelVisible: adminUnreadCount > 0,
                  child: const Icon(LucideIcons.bell, color: AppTheme.primary),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.outlineVariant, width: 1),
                    image: DecorationImage(
                      image: NetworkImage(admin.avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          drawer: _buildDrawer(context, admin),
          body: pages[_currentIndex],
          floatingActionButton: _currentIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddAgentScreen()),
                    );
                  },
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(LucideIcons.userPlus),
                  label: const Text('Add Agent', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : null,
          bottomNavigationBar: CustomBottomBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              const CustomBottomBarItem(
                icon: LucideIcons.layoutDashboard,
                activeIcon: LucideIcons.layoutDashboard,
                label: 'Dashboard',
              ),
              const CustomBottomBarItem(
                icon: LucideIcons.users,
                activeIcon: LucideIcons.users,
                label: 'Agents',
              ),
              const CustomBottomBarItem(
                icon: LucideIcons.folderHeart,
                activeIcon: LucideIcons.folderHeart,
                label: 'Cases',
              ),
              CustomBottomBarItem(
                icon: LucideIcons.userRoundCheck,
                activeIcon: LucideIcons.userRoundCheck,
                label: 'Approvals ($pendingCount)',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeDashboard(BuildContext context, int pendingCount) {
    // Calculate total recovery (sum of approved collections + prefill 45.2L)
    final double sessionApprovedSum = _db.payments
        .where((p) => p.status == 'APPROVED' && p.id.startsWith('TXN_'))
        .fold(0.0, (sum, item) => sum + item.amount);

    final double displayedTotalRecovery = 45200.0 + sessionApprovedSum;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Admin Dashboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            'Performance summary for Q3 Recovery Cycle',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          // Bento Grid Stats
          Column(
            children: [
              // Total Collected Bento Card (Wide)
              CustomBentoCard(
                backgroundDecoration: Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Transform.translate(
                        offset: const Offset(10, 10),
                        child: const Icon(LucideIcons.wallet, size: 120, color: AppTheme.primary),
                      ),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.banknote, color: AppTheme.secondary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Total Collected',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${displayedTotalRecovery.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.trendingUp, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '+12% from last month',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Two grid boxes
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Active Agents Box
                    Expanded(
                      child: CustomBentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Active Agents', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 8),
                            Text(
                              '24/30',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            // Mini bar progress
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: const LinearProgressIndicator(
                                value: 24 / 30,
                                minHeight: 6,
                                backgroundColor: AppTheme.surfaceContainerLow,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Pending Approvals Box
                    Expanded(
                      child: CustomBentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pending Approvals', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 8),
                            Text(
                              '$pendingCount',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: pendingCount > 0 ? AppTheme.error : AppTheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            // Tiny Avatars stack
                            Row(
                              children: [
                                ..._db.agents.take(3).map((a) => Padding(
                                      padding: const EdgeInsets.only(right: 2.0),
                                      child: CircleAvatar(
                                        radius: 9,
                                        backgroundImage: NetworkImage(a.avatarUrl),
                                      ),
                                    )),
                                if (_db.agents.length > 3)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text(
                                      '+2',
                                      style: TextStyle(fontSize: 6, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recovery Rate Radial Gauge Card (Wide)
              CustomBentoCard(
                backgroundColor: AppTheme.primary,
                borderSide: BorderSide.none,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recovery Rate',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '72% Success',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Q3 Recovery Cycle',
                            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const PerformanceChart(
                      type: ChartType.gauge,
                      value: 0.72,
                      centerText: '72%',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions for upload CSV
          Text(
            'QUICK ACTIONS',
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UploadDataScreen()),
                      );
                    },
                    icon: const Icon(LucideIcons.upload, size: 18),
                    label: const Text('Upload Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 1; // jump to agents tracking map
                      });
                    },
                    icon: const Icon(LucideIcons.map, size: 18),
                    label: const Text('View Live Map', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Real-time Activity Feed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REAL-TIME ACTIVITY FEED',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('See All Activities Logged.')),
                  );
                },
                child: const Text('See All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _db.activityFeed.take(3).length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final act = _db.activityFeed[index];
              IconData icon;
              Color color;
              Color bg;

              if (act['type'] == 'success') {
                icon = LucideIcons.circleCheck;
                color = AppTheme.success;
                bg = AppTheme.successContainer;
              } else if (act['type'] == 'warning') {
                icon = LucideIcons.hourglass;
                color = AppTheme.warning;
                bg = AppTheme.warningContainer;
              } else if (act['type'] == 'error') {
                icon = LucideIcons.circleAlert;
                color = AppTheme.error;
                bg = AppTheme.errorContainer;
              } else {
                icon = LucideIcons.logIn;
                color = AppTheme.primary;
                bg = AppTheme.primaryContainer.withOpacity(0.1);
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            act['subtitle'] ?? '',
                            style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      act['time'] ?? '',
                      style: const TextStyle(fontSize: 10, color: AppTheme.secondary),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Geographic Zone Map Card
          Text(
            'GEOGRAPHIC RECOVERY FOCUS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 12),
          CustomBentoCard(
            padding: 0,
            child: Column(
              children: [
                // map mockup image
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(LucideIcons.map, color: AppTheme.primary.withOpacity(0.2), size: 100),
                        // pulsating dots
                        const Positioned(
                          left: 100,
                          top: 50,
                          child: _PulseDot(color: AppTheme.primary),
                        ),
                        const Positioned(
                          right: 120,
                          bottom: 40,
                          child: _PulseDot(color: AppTheme.error),
                        ),
                        const Positioned(
                          right: 60,
                          top: 70,
                          child: _PulseDot(color: AppTheme.success),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text('Mumbai Metro Live Tracking Active', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const Text(
                        'EXPAND',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic admin) {
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
                backgroundImage: NetworkImage(admin.avatarUrl),
              ),
            ),
            accountName: Text(
              admin.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white, letterSpacing: -0.2),
            ),
            accountEmail: Text(
              'Senior Administrator (ID: ${admin.id.toUpperCase()})',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),

          // Register New Agent
          ListTile(
            leading: const Icon(LucideIcons.userPlus, color: AppTheme.primary, size: 20),
            title: const Text(
              'Register New Agent',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'Configure credentials & regions',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddAgentScreen()),
              );
            },
          ),
          const Divider(height: 1),

          // Import Debtors CSV
          ListTile(
            leading: const Icon(LucideIcons.fileUp, color: AppTheme.primary, size: 20),
            title: const Text(
              'Import Debtors CSV',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'Parse external debt ledger sheets',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadDataScreen()),
              );
            },
          ),
          const Divider(height: 1),

          // Manage Uploaded Records
          ListTile(
            leading: const Icon(LucideIcons.layoutDashboard, color: AppTheme.primary, size: 20),
            title: const Text(
              'Manage Uploaded Records',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'Review and deploy portfolios',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadedRecordsView()),
              );
            },
          ),
          const Divider(height: 1),

          // Edit Admin Profile settings
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

          // System Protocols Logs
          ListTile(
            leading: const Icon(LucideIcons.terminal, color: AppTheme.primary, size: 20),
            title: const Text(
              'System Protocols Logs',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'Inspect techno-operational log stream',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening System logs...')),
              );
            },
          ),
          
          const Spacer(),
          const Divider(height: 1),
          
          // Switch to Agent Portal
          ListTile(
            leading: const Icon(LucideIcons.arrowLeftRight, color: AppTheme.primary, size: 20),
            title: const Text(
              'Switch to Agent Portal',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 14),
            ),
            subtitle: const Text(
              'Simulate field updates',
              style: TextStyle(fontSize: 12, color: AppTheme.secondary),
            ),
            onTap: () {
              Navigator.pop(context); // close drawer
              _db.switchPortal('AGENT');
              Navigator.of(context).pushReplacementNamed('/agent_dashboard');
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
              'Terminate secure admin session',
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

class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: widget.color.withOpacity(0.5), shape: BoxShape.circle),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
            ),
          ],
        );
      },
    );
  }
}
