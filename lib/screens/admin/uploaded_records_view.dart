import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';
import '../../models/customer.dart';
import '../agent/customer_details_screen.dart';
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
  final Set<String> _selectedRecordIds = {};

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
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Agency Admin',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: AppTheme.primary),
                onPressed: () => setState(() {}),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                prefixIcon: const Icon(
                                  LucideIcons.search, size: 20, color: AppTheme.outline),
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
                            icon: LucideIcons.filter,
                            label: 'Filter${_statusFilter == 'ALL' ? '' : ': $_statusFilter'}',
                            onPressed: () => _showFilterBottomSheet(context),
                            backgroundColor: Colors.white,
                            textColor: AppTheme.onSurfaceVariant,
                            hasBorder: true,
                          ),
                          const SizedBox(width: 8),
                          // Import Action Button
                          _buildHeaderButton(
                            icon: LucideIcons.upload,
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

                // Bento-lite Stats Grid Row - Highly Compact Height with Colorful Icons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    childAspectRatio: 3.1,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBentoStatCard(
                        label: 'Total Records',
                        value: '$totalCount',
                        valueColor: AppTheme.primary,
                        icon: LucideIcons.database,
                        iconColor: AppTheme.primary,
                        iconBgColor: AppTheme.primary.withOpacity(0.08),
                      ),
                      _buildBentoStatCard(
                        label: 'Unassigned',
                        value: '$unassignedCount',
                        valueColor: AppTheme.error,
                        icon: LucideIcons.userX,
                        iconColor: AppTheme.error,
                        iconBgColor: AppTheme.error.withOpacity(0.08),
                      ),
                      _buildBentoStatCard(
                        label: 'In-Progress',
                        value: '$inProgressCount',
                        valueColor: const Color(0xFF3C475A),
                        icon: LucideIcons.timer,
                        iconColor: const Color(0xFFE65100),
                        iconBgColor: const Color(0xFFFFF3E0),
                      ),
                      _buildBentoStatCard(
                        label: 'Total Value',
                        value: '₹4.2M',
                        valueColor: const Color(0xFF2E7D32),
                        icon: LucideIcons.indianRupee,
                        iconColor: const Color(0xFF2E7D32),
                        iconBgColor: const Color(0xFFE8F5E9),
                      ),
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
                        _buildFilterChip('All Records', 'ALL', LucideIcons.inbox),
                        const SizedBox(width: 8),
                        _buildFilterChip('Unassigned', 'Unassigned', LucideIcons.userX),
                        const SizedBox(width: 8),
                        _buildFilterChip('In-Progress', 'In-Progress', LucideIcons.timerReset),
                        const SizedBox(width: 8),
                        _buildFilterChip('Assigned', 'Assigned', LucideIcons.userCheck),
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
                      Row(
                        children: [
                          Checkbox(
                            value: filteredRecords.isNotEmpty && filteredRecords.every((r) => _selectedRecordIds.contains(r.id)),
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedRecordIds.addAll(filteredRecords.map((r) => r.id));
                                } else {
                                  _selectedRecordIds.removeAll(filteredRecords.map((r) => r.id));
                                }
                              });
                            },
                          ),
                          Text(
                            'Showing ${filteredRecords.length} records',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Sort: ', style: TextStyle(fontSize: 12, color: AppTheme.secondary)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              icon: const Icon(LucideIcons.chevronDown, color: AppTheme.primary, size: 18),
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

                // Bulk Actions Panel
                if (_selectedRecordIds.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedRecordIds.length} records selected',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.error,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedRecordIds.clear();
                                  });
                                },
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.error,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => _confirmBulkDeleteRecords(filteredRecords),
                                icon: const Icon(LucideIcons.trash2, size: 14),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Records Cards List - Scrolls with page fluidly
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: filteredRecords.isEmpty
                      ? SizedBox(
                          height: 250,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.folderOpen, size: 48, color: AppTheme.outline.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No matching ledger entries found',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 32),
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

  Widget _buildBentoStatCard({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return CustomBentoCard(
      padding: 10.0,
      child: Row(
        children: [
          Expanded(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 15,
              color: iconColor,
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

  Customer _createMockCustomerFromRecord(RecordItem record) {
    return Customer(
      id: record.id,
      name: record.name,
      amountDue: record.amount,
      dueDate: DateTime.now().subtract(const Duration(days: 15)),
      overdueDays: 15,
      address: record.address,
      phone: record.phone,
      priority: record.amount > 100000.0 ? 'HIGH' : 'MEDIUM',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      lat: 19.0760,
      lng: 72.8777,
      assignedAgentId: record.assignedAgentName != null ? 'miller' : 'unassigned',
      status: record.status == 'Paid' ? 'PAID' : (record.status == 'In-Progress' ? 'PENDING_VERIFICATION' : 'OVERDUE'),
      notes: ['Uploaded record parsed from debt ledger.', 'Verification of address complete.'],
    );
  }

  void _confirmDeleteRecord(RecordItem record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(LucideIcons.triangleAlert, color: AppTheme.error),
              SizedBox(width: 8),
              Text(
                'Delete Record?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${record.name}\'s ledger record (${record.loanId})? This action is permanent.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Execute deletion
                if (record.id.startsWith('cust_')) {
                  _db.deleteCase(record.id);
                } else {
                  // Static mock record local removal
                  setState(() {
                    _staticMockRecords.removeWhere((r) => r.id == record.id);
                  });
                }
                
                setState(() {
                  _selectedRecordIds.remove(record.id);
                });
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text('${record.name}\'s record was successfully deleted.'),
                  ),
                );
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _confirmBulkDeleteRecords(List<RecordItem> filteredRecords) {
    showDialog(
      context: context,
      builder: (context) {
        final count = _selectedRecordIds.length;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(LucideIcons.triangleAlert, color: AppTheme.error),
              SizedBox(width: 8),
              Text(
                'Delete Selected Records?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete all $count selected ledger records permanently? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final List<String> selectedIds = _selectedRecordIds.toList();
                
                // Separate db cases and mock cases
                final dbIds = selectedIds.where((id) => id.startsWith('cust_')).toList();
                final mockIds = selectedIds.where((id) => !id.startsWith('cust_')).toList();

                if (dbIds.isNotEmpty) {
                  _db.deleteMultipleCases(dbIds);
                }

                if (mockIds.isNotEmpty) {
                  setState(() {
                    _staticMockRecords.removeWhere((r) => mockIds.contains(r.id));
                  });
                }

                setState(() {
                  _selectedRecordIds.clear();
                });
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text('Successfully deleted $count ledger records.'),
                  ),
                );
              },
              child: const Text('DELETE ALL'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(RecordItem record) {
    // Styling attributes based on status - Gorgeous vibrant HSL colors
    Color chipBg;
    Color chipText;
    if (record.status == 'Unassigned') {
      chipBg = const Color(0xFFFFDAD6);
      chipText = const Color(0xFFBA1A1A);
    } else if (record.status == 'In-Progress') {
      chipBg = const Color(0xFFFFF3E0);
      chipText = const Color(0xFFE65100);
    } else if (record.status == 'Paid') {
      chipBg = const Color(0xFFE8F5E9);
      chipText = const Color(0xFF2E7D32);
    } else {
      // Assigned
      chipBg = const Color(0xFFEFF4FF);
      chipText = AppTheme.primary;
    }

    final isChecked = _selectedRecordIds.contains(record.id);

    return CustomBentoCard(
      padding: 0,
      onTap: () {
        setState(() {
          if (isChecked) {
            _selectedRecordIds.remove(record.id);
          } else {
            _selectedRecordIds.add(record.id);
          }
        });
      },
      onLongPress: () => _showReassignDialog(record),
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
                      _selectedRecordIds.add(record.id);
                    } else {
                      _selectedRecordIds.remove(record.id);
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
                        const Icon(LucideIcons.headset, size: 14, color: AppTheme.secondary),
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
                        Icon(LucideIcons.triangleAlert, size: 14, color: AppTheme.error),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Single Record Delete Button
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.error),
                            onPressed: () => _confirmDeleteRecord(record),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              final customer = _db.customers.firstWhere(
                                (c) => c.id == record.id,
                                orElse: () => _createMockCustomerFromRecord(record),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerDetailsScreen(customer: customer),
                                ),
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.outlineVariant),
                                color: AppTheme.primary.withOpacity(0.04),
                              ),
                              child: const Icon(LucideIcons.chevronRight, size: 20, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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
              _buildFilterOption('All Ledger Entries', 'ALL', LucideIcons.inbox),
              _buildFilterOption('Unassigned Cases', 'Unassigned', LucideIcons.userX),
              _buildFilterOption('Assigned Portfolio', 'Assigned', LucideIcons.userCheck),
              _buildFilterOption('In-Progress Verification', 'In-Progress', LucideIcons.timerReset),
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
      trailing: isSelected ? const Icon(LucideIcons.check, color: AppTheme.primary) : null,
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
              const Icon(LucideIcons.userCog, color: AppTheme.primary),
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
                            ? const Icon(
                                LucideIcons.checkCircle, color: AppTheme.primary)
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
                                  const Icon(LucideIcons.checkCircle, color: Colors.white),
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
