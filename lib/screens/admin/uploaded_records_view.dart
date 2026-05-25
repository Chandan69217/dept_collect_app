import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import 'upload_data_screen.dart';

class UploadedRecordsView extends StatefulWidget {
  const UploadedRecordsView({super.key});

  @override
  State<UploadedRecordsView> createState() => _UploadedRecordsViewState();
}

class RecordItem {
  final String id;
  final String loanId;
  final String name;
  final String status; // 'Unassigned', 'Assigned', 'In-Progress', 'Paid'
  final double amount;
  final String address;
  final String phone;
  final String? assignedAgentName;

  RecordItem({
    required this.id,
    required this.loanId,
    required this.name,
    required this.status,
    required this.amount,
    required this.address,
    required this.phone,
    this.assignedAgentName,
  });
}

class _UploadedRecordsViewState extends State<UploadedRecordsView> {
  final _db = DatabaseService();
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'Unassigned', 'Assigned', 'In-Progress'
  String _sortBy = 'NEWEST'; // 'NEWEST', 'OLDEST', 'AMOUNT_DESC', 'AMOUNT_ASC'

  // Local overrides for mock record modifications (assignments and statuses)
  final Map<String, String> _mockAssignments = {};
  final Map<String, String> _mockStatuses = {};

  // Standard high-fidelity mock records matching the Stitch UI design
  final List<RecordItem> _staticMockRecords = [
    RecordItem(
      id: 'DC-9921-X',
      loanId: 'DC-9921-X',
      name: 'Arjun Mehra',
      status: 'Unassigned',
      amount: 84500.0,
      address: 'Sector 15, Vashi, Navi Mumbai',
      phone: '+91 99333 22211',
    ),
    RecordItem(
      id: 'DC-8842-A',
      loanId: 'DC-8842-A',
      name: 'Priya Sharma',
      status: 'Assigned',
      amount: 124000.0,
      address: '702 Sea Green Complex, Worli, Mumbai',
      phone: '+91 98888 77777',
      assignedAgentName: 'Agent Rahul',
    ),
    RecordItem(
      id: 'DC-7711-B',
      loanId: 'DC-7711-B',
      name: 'Vikram Singh',
      status: 'In-Progress',
      amount: 45200.0,
      address: 'Tower 4, Apex Heights, Powai, Mumbai',
      phone: '+91 98123 45678',
      assignedAgentName: 'Agent Priya',
    ),
    RecordItem(
      id: 'DC-5523-Q',
      loanId: 'DC-5523-Q',
      name: 'Sneha Kapoor',
      status: 'In-Progress',
      amount: 210000.0,
      address: '102 Skyline Apartments, Bandra West, Mumbai',
      phone: '+91 99999 88888',
      assignedAgentName: 'Agent Miller',
    ),
    RecordItem(
      id: 'DC-2299-W',
      loanId: 'DC-2299-W',
      name: 'Rahul Deshmukh',
      status: 'Unassigned',
      amount: 12800.0,
      address: 'Flat 304, Green Heights, Santacruz West, Mumbai',
      phone: '+91 97777 66666',
    ),
    RecordItem(
      id: 'DC-1104-Y',
      loanId: 'DC-1104-Y',
      name: 'Anita Verma',
      status: 'Assigned',
      amount: 98000.0,
      address: '58 Orchard Road, Andheri East, Mumbai',
      phone: '+91 97654 32109',
      assignedAgentName: 'Agent Rahul',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        // Map database records to high-fidelity RecordItems
        final List<RecordItem> dbRecords = _db.customers.map((c) {
          // Resolve status
          String resolvedStatus = 'Assigned';
          if (c.status == 'PENDING_VERIFICATION') {
            resolvedStatus = 'In-Progress';
          } else if (c.status == 'PAID') {
            resolvedStatus = 'Assigned';
          } else if (c.assignedAgentId.isEmpty || c.assignedAgentId == 'unassigned') {
            resolvedStatus = 'Unassigned';
          }

          // Generate stable Loan ID based on DB customer ID
          final String cleanId = c.id.replaceAll('cust_', '').toUpperCase();
          final String loanId = 'DC-${cleanId.length > 4 ? cleanId.substring(0, 4) : cleanId}-X';

          // Get assigned agent name
          final agent = _db.agents.where((a) => a.id == c.assignedAgentId).firstOrNull;

          return RecordItem(
            id: c.id,
            loanId: loanId,
            name: c.name,
            status: resolvedStatus,
            amount: c.amountDue,
            address: c.address,
            phone: c.phone,
            assignedAgentName: agent?.name,
          );
        }).toList();

        // Map mock records with local overrides
        final List<RecordItem> mappedMocks = _staticMockRecords.map((m) {
          final overrideAgentId = _mockAssignments[m.id];
          final overrideStatus = _mockStatuses[m.id];
          
          String? resolvedAgentName = m.assignedAgentName;
          if (overrideAgentId != null) {
            final agent = _db.agents.where((a) => a.id == overrideAgentId).firstOrNull;
            resolvedAgentName = agent?.name ?? 'Assigned';
          }

          return RecordItem(
            id: m.id,
            loanId: m.loanId,
            name: m.name,
            status: overrideStatus ?? m.status,
            amount: m.amount,
            address: m.address,
            phone: m.phone,
            assignedAgentName: resolvedAgentName,
          );
        }).toList();

        // Combine lists
        final List<RecordItem> allRecords = [...dbRecords, ...mappedMocks];

        // Compute metrics counts for Bento-lite cards
        final int totalCount = 1278 + allRecords.length;
        final int unassignedCount = 140 + allRecords.where((r) => r.status == 'Unassigned').length;
        final int inProgressCount = 886 + allRecords.where((r) => r.status == 'In-Progress').length;
        
        // Dynamic search, status filter, and sorting
        final List<RecordItem> filteredRecords = allRecords.where((r) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = r.name.toLowerCase().contains(query) ||
              r.loanId.toLowerCase().contains(query) ||
              r.address.toLowerCase().contains(query);

          final matchesStatus = _statusFilter == 'ALL' || r.status == _statusFilter;

          return matchesSearch && matchesStatus;
        }).toList();

        // Sort items
        filteredRecords.sort((a, b) {
          if (_sortBy == 'AMOUNT_DESC') {
            return b.amount.compareTo(a.amount);
          } else if (_sortBy == 'AMOUNT_ASC') {
            return a.amount.compareTo(b.amount);
          } else if (_sortBy == 'OLDEST') {
            return a.name.compareTo(b.name); // Alphabetical fallback
          } else {
            return b.name.compareTo(a.name); // Reverse alphabetical default fallback for 'NEWEST'
          }
        });

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Agency Admin',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.primary),
                onPressed: () => setState(() {}),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Header / Search & Filter Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Records',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Review and manage imported debt ledger entries',
                      style: TextStyle(fontSize: 12, color: AppTheme.secondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by ID or Customer Name...',
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
                        ),
                        const SizedBox(width: 8),
                        // Filter Action Button
                        _buildHeaderButton(
                          icon: Icons.filter_list,
                          label: 'Filter${_statusFilter == 'ALL' ? '' : ': $_statusFilter'}',
                          onPressed: () => _showFilterBottomSheet(context),
                          backgroundColor: Colors.white,
                          textColor: AppTheme.onSurfaceVariant,
                          hasBorder: true,
                        ),
                        const SizedBox(width: 8),
                        // Import Action Button
                        _buildHeaderButton(
                          icon: Icons.upload_file,
                          label: 'Import',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UploadDataScreen()),
                            );
                          },
                          backgroundColor: AppTheme.primary,
                          textColor: Colors.white,
                          hasBorder: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bento-lite Stats Grid Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  childAspectRatio: 2.3,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBentoStatCard('Total Records', '$totalCount', AppTheme.primary),
                    _buildBentoStatCard('Unassigned', '$unassignedCount', AppTheme.error),
                    _buildBentoStatCard('In-Progress', '$inProgressCount', const Color(0xFF3C475A)),
                    _buildBentoStatCard('Total Value', '₹4.2M', AppTheme.primary),
                  ],
                ),
              ),

              // Quick Filter Chips Row for Unassigned / In-Progress / All
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All Records', 'ALL', Icons.all_inbox),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unassigned', 'Unassigned', Icons.person_add_disabled_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('In-Progress', 'In-Progress', Icons.hourglass_empty),
                      const SizedBox(width: 8),
                      _buildFilterChip('Assigned', 'Assigned', Icons.support_agent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // List Header (Showing and Sort selection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${filteredRecords.length} records',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Sort: ', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 18),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'NEWEST', child: Text('Newest First')),
                              DropdownMenuItem(value: 'OLDEST', child: Text('Oldest First')),
                              DropdownMenuItem(value: 'AMOUNT_DESC', child: Text('Amount: High to Low')),
                              DropdownMenuItem(value: 'AMOUNT_ASC', child: Text('Amount: Low to High')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _sortBy = val;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Records Cards List
              Expanded(
                child: filteredRecords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_outlined, size: 64, color: AppTheme.outline.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching ledger entries found',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: filteredRecords.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return _buildRecordCard(record);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
    required bool hasBorder,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: hasBorder ? Border.all(color: AppTheme.outlineVariant, width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoStatCard(String label, String value, Color valueColor) {
    return CustomBentoCard(
      padding: 8.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppTheme.outlineVariant,
          width: 1,
        ),
      ),
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
    );
  }

  Widget _buildRecordCard(RecordItem record) {
    // Styling attributes based on status
    Color chipBg;
    Color chipText;
    if (record.status == 'Unassigned') {
      chipBg = AppTheme.errorContainer;
      chipText = AppTheme.error;
    } else if (record.status == 'In-Progress') {
      chipBg = AppTheme.surfaceContainer;
      chipText = const Color(0xFF3C475A);
    } else if (record.status == 'Paid') {
      chipBg = AppTheme.successContainer;
      chipText = AppTheme.success;
    } else {
      // Assigned
      chipBg = AppTheme.surfaceContainerHighest;
      chipText = AppTheme.primary;
    }

    return CustomBentoCard(
      padding: 0,
      onTap: () => _showReassignDialog(record),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (Loan ID + Status Chip)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan ID: ${record.loanId}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.outline,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: chipText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Customer Name
            Text(
              record.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            
            // Subtitle address description
            if (record.assignedAgentName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.support_agent, size: 14, color: AppTheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: ${record.assignedAgentName}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.error),
                  SizedBox(width: 4),
                  Text(
                    'Pending deployment assignment',
                    style: TextStyle(fontSize: 11, color: AppTheme.error),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.outlineVariant),
            const SizedBox(height: 12),

            // Bottom Row (Principal Amount + Chevron Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Principal Amount',
                      style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${record.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: const Icon(Icons.chevron_right, size: 20, color: AppTheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Records',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
              ),
              const SizedBox(height: 16),
              _buildFilterOption('All Ledger Entries', 'ALL', Icons.all_inbox),
              _buildFilterOption('Unassigned Cases', 'Unassigned', Icons.person_add_disabled_outlined),
              _buildFilterOption('Assigned Portfolio', 'Assigned', Icons.support_agent),
              _buildFilterOption('In-Progress Verification', 'In-Progress', Icons.hourglass_empty),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final isSelected = _statusFilter == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.secondary),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.onSurface,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primary) : null,
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showReassignDialog(RecordItem record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actionsPadding: const EdgeInsets.all(12),
          title: Row(
            children: [
              const Icon(Icons.assignment_ind_outlined, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.status == 'Unassigned' ? 'Assign Debtor Portfolio' : 'Reassign Portfolio',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Debtor Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Loan ID: ${record.loanId} • ₹${record.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: record.status == 'Unassigned' ? AppTheme.errorContainer : AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record.status,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: record.status == 'Unassigned' ? AppTheme.error : AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SELECT ACTIVE AGENT TO DEPLOY:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),

                // Active Agents list from Database
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _db.agents.where((a) => !a.isAdmin).length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final agent = _db.agents.where((a) => !a.isAdmin).toList()[index];
                      final isCurrentlyAssigned = record.assignedAgentName == agent.name;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(agent.avatarUrl),
                        ),
                        title: Text(
                          agent.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Zone: ${agent.zone} • ${agent.casesCount} active cases',
                          style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                        ),
                        trailing: isCurrentlyAssigned
                            ? const Icon(Icons.check_circle, color: AppTheme.primary)
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Deploy',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ),
                        onTap: () {
                          if (isCurrentlyAssigned) {
                            Navigator.pop(context);
                            return;
                          }

                          // Action reassign
                          if (record.id.startsWith('cust_')) {
                            // Reassign actual database customer!
                            _db.assignCase(record.id, agent.id);
                          } else {
                            // Reassign static mock local override!
                            setState(() {
                              _mockAssignments[record.id] = agent.id;
                              _mockStatuses[record.id] = 'Assigned';
                            });
                          }

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.success,
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('${record.name} portfolio successfully deployed to ${agent.name}.'),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
