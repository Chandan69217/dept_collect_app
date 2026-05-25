import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';

class AgentTrackingScreen extends StatefulWidget {
  final bool isEmbedded;

  const AgentTrackingScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<AgentTrackingScreen> createState() => _AgentTrackingScreenState();
}

class _AgentTrackingScreenState extends State<AgentTrackingScreen> {
  final _db = DatabaseService();
  String _searchQuery = '';
  String _selectedZoneFilter = 'ALL'; // 'ALL', 'Mumbai Metro Area', 'Mumbai South', 'Mumbai West'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        // Filter out admin, only track field agents
        final List<dynamic> fieldAgents = _db.agents.where((a) => !a.isAdmin).toList();

        // Apply filters
        final filteredAgents = fieldAgents.where((agent) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = agent.name.toLowerCase().contains(query) ||
              agent.id.toLowerCase().contains(query) ||
              agent.zone.toLowerCase().contains(query);

          final matchesZone = _selectedZoneFilter == 'ALL' || agent.zone == _selectedZoneFilter;

          return matchesSearch && matchesZone;
        }).toList();

        final scaffoldBody = Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                children: [
                  // Hero Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agent Performance',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Real-time productivity and collection tracking for field agents.',
                        style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Bar Input
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Find agent by name or ID...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.outline),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      fillColor: const Color(0xFFF1F3F9),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Horizontal Filter Chips (All, Metro, South, West Zones)
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All Zones', 'ALL'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Mumbai Metro', 'Mumbai Metro Area'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Mumbai South', 'Mumbai South'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Mumbai West', 'Mumbai West'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Performance Cards List mapping
                  filteredAgents.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48.0),
                            child: Column(
                              children: [
                                Icon(Icons.support_agent_outlined, size: 56, color: AppTheme.outline.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No field agents found matching filters.',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAgents.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final agent = filteredAgents[index];
                            return _buildAgentCard(agent);
                          },
                        ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        );

        if (widget.isEmbedded) return scaffoldBody;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Field Agents Productivity Cockpit',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          body: scaffoldBody,
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedZoneFilter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppTheme.outlineVariant,
          width: 1,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _selectedZoneFilter = value;
        });
      },
    );
  }

  Widget _buildAgentCard(dynamic agent) {
    final double targetPercentage = agent.assignedTarget == 0
        ? 0.0
        : (agent.collectedAmount / agent.assignedTarget);

    // Dynamic color maps
    final Color pctColor = agent.isOnline ? AppTheme.primary : AppTheme.secondary;
    final Color progressFillColor = agent.isOnline ? AppTheme.primary : AppTheme.outlineVariant;

    // Greyscale Matrix filter for offline avatars
    final grayscaleFilter = const ColorFilter.matrix([
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ]);

    return CustomBentoCard(
      padding: 0,
      child: Opacity(
        opacity: agent.isOnline ? 1.0 : 0.75, // Lower opacity for offline state matching Stitch specs
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section (Profile Hero & Collected Summary)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Profile Photo, Name, and sector ID
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            agent.isOnline
                                ? CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(agent.avatarUrl),
                                  )
                                : ColorFiltered(
                                    colorFilter: grayscaleFilter,
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundImage: NetworkImage(agent.avatarUrl),
                                    ),
                                  ),
                            if (agent.isOnline)
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: _StatusPulseIndicator(),
                              )
                            else
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppTheme.outlineVariant,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agent.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: #${agent.id.toUpperCase()} • ${agent.zone}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: Online text & Collected aggregated rupee amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        agent.isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: agent.isOnline ? AppTheme.success : AppTheme.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${agent.collectedAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: agent.isOnline ? AppTheme.primary : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom Section: Target Achievement progress bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Achievement Target',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant),
                      ),
                      Text(
                        '${(targetPercentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: pctColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: targetPercentage > 1.0 ? 1.0 : targetPercentage,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFEFF4FF),
                      valueColor: AlwaysStoppedAnimation<Color>(progressFillColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPulseIndicator extends StatefulWidget {
  const _StatusPulseIndicator();

  @override
  State<_StatusPulseIndicator> createState() => _StatusPulseIndicatorState();
}

class _StatusPulseIndicatorState extends State<_StatusPulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}
