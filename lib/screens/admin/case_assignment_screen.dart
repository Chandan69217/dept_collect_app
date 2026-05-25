import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_bento_card.dart';

class CaseAssignmentScreen extends StatefulWidget {
  final bool isEmbedded;

  const CaseAssignmentScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<CaseAssignmentScreen> createState() => _CaseAssignmentScreenState();
}

class CaseItem {
  final String id;
  final String loanId;
  final String name;
  final double amount;
  final String overdueStatus;
  final String location;
  final String riskLevel;
  final IconData riskIcon;
  final String? assignedAgentId;
  final String? assignedAgentName;

  CaseItem({
    required this.id,
    required this.loanId,
    required this.name,
    required this.amount,
    required this.overdueStatus,
    required this.location,
    required this.riskLevel,
    required this.riskIcon,
    this.assignedAgentId,
    this.assignedAgentName,
  });
}

class _CaseAssignmentScreenState extends State<CaseAssignmentScreen> {
  final _db = DatabaseService();
  String _selectedSegment = 'Unassigned'; // 'Unassigned' or 'Assigned'
  final Set<String> _selectedCaseIds = {};
  String _riskFilter = 'ALL'; // 'ALL', 'High Risk', 'Critical', 'Low Balance'

  // Local overrides for assigned static cases
  final Map<String, String> _mockAssignments = {};

  // Standard high-fidelity mock cases from Stitch UI spec
  final List<CaseItem> _staticMockCases = [
    CaseItem(
      id: 'mock_case_1',
      loanId: '#LN-882104',
      name: 'Dominic Chambers',
      amount: 4250.00,
      overdueStatus: '12 Days Overdue',
      location: 'Queens, NY',
      riskLevel: 'High Risk',
      riskIcon: Icons.priority_high,
    ),
    CaseItem(
      id: 'mock_case_2',
      loanId: '#LN-773291',
      name: 'Elena Rodriguez',
      amount: 1120.50,
      overdueStatus: 'Due Tomorrow',
      location: 'Brooklyn, NY',
      riskLevel: 'First Notice',
      riskIcon: Icons.history,
    ),
    CaseItem(
      id: 'mock_case_3',
      loanId: '#LN-901445',
      name: 'Marcus Thorne',
      amount: 12800.00,
      overdueStatus: '45 Days Overdue',
      location: 'Manhattan, NY',
      riskLevel: 'Critical',
      riskIcon: Icons.warning,
    ),
    CaseItem(
      id: 'mock_case_4',
      loanId: '#LN-110292',
      name: 'Sarah Jenkins',
      amount: 850.00,
      overdueStatus: 'Due in 5 days',
      location: 'Staten Island, NY',
      riskLevel: 'Low Balance',
      riskIcon: Icons.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _db,
      builder: (context, child) {
        // Map actual database customers to CaseItems
        final List<CaseItem> dbCases = _db.customers.map((c) {
          // Resolve risk details based on priority
          IconData riskIcon = Icons.info;
          String riskText = 'Medium Risk';
          if (c.priority == 'HIGH') {
            riskIcon = Icons.warning;
            riskText = 'Critical';
          } else if (c.priority == 'LOW') {
            riskIcon = Icons.info_outline;
            riskText = 'Low Risk';
          }

          // Generate stable Loan ID based on DB customer ID
          final String cleanId = c.id.replaceAll('cust_', '').toUpperCase();
          final String loanId = '#LN-${cleanId.length > 5 ? cleanId.substring(0, 5) : cleanId}';

          // Get assigned agent details
          final agent = _db.agents.where((a) => a.id == c.assignedAgentId).firstOrNull;

          return CaseItem(
            id: c.id,
            loanId: loanId,
            name: c.name,
            amount: c.amountDue,
            overdueStatus: '${c.overdueDays} Days Overdue',
            location: c.address.split(',').last.trim(), // Grab region name
            riskLevel: riskText,
            riskIcon: riskIcon,
            assignedAgentId: c.assignedAgentId,
            assignedAgentName: agent?.name,
          );
        }).toList();

        // Map mock cases with local overrides
        final List<CaseItem> mappedMocks = _staticMockCases.map((m) {
          final assignedAgentId = _mockAssignments[m.id];
          String? resolvedAgentName;
          if (assignedAgentId != null) {
            final agent = _db.agents.where((a) => a.id == assignedAgentId).firstOrNull;
            resolvedAgentName = agent?.name ?? 'Agent Miller';
          }

          return CaseItem(
            id: m.id,
            loanId: m.loanId,
            name: m.name,
            amount: m.amount,
            overdueStatus: m.overdueStatus,
            location: m.location,
            riskLevel: m.riskLevel,
            riskIcon: m.riskIcon,
            assignedAgentId: assignedAgentId,
            assignedAgentName: resolvedAgentName,
          );
        }).toList();

        // Combine lists
        final List<CaseItem> allCases = [...dbCases, ...mappedMocks];

        // Filter based on Unassigned / Assigned Segment
        final List<CaseItem> segmentedCases = allCases.where((c) {
          final isAssigned = c.assignedAgentId != null && 
              c.assignedAgentId!.isNotEmpty && 
              c.assignedAgentId != 'unassigned';

          if (_selectedSegment == 'Unassigned') {
            return !isAssigned;
          } else {
            return isAssigned;
          }
        }).toList();

        // Filter based on Risk Level dropdown
        final List<CaseItem> filteredCases = segmentedCases.where((c) {
          if (_riskFilter == 'ALL') return true;
          return c.riskLevel == _riskFilter;
        }).toList();

        // Calculate count indicator
        final int unassignedCount = 838 + allCases.where((c) => c.assignedAgentId == null || c.assignedAgentId == 'unassigned' || c.assignedAgentId!.isEmpty).length;

        final scaffoldBody = Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                children: [
                  // Hero Header Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Cases',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$unassignedCount Unassigned Cases',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Updated 2m ago',
                            style: TextStyle(fontSize: 11, color: AppTheme.secondary, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Segmented Control (Toggle Unassigned / Assigned)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton('Unassigned'),
                        ),
                        Expanded(
                          child: _buildSegmentButton('Assigned'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bulk Action Controller Panel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: filteredCases.isNotEmpty && 
                                filteredCases.every((c) => _selectedCaseIds.contains(c.id)),
                            activeColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedCaseIds.addAll(filteredCases.map((c) => c.id));
                                } else {
                                  _selectedCaseIds.removeAll(filteredCases.map((c) => c.id));
                                }
                              });
                            },
                          ),
                          const Text(
                            'Select All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      // Filter Button
                      TextButton.icon(
                        onPressed: () => _showFilterDialog(),
                        icon: const Icon(Icons.filter_list, size: 18, color: AppTheme.primary),
                        label: Text(
                          _riskFilter == 'ALL' ? 'Filter' : 'Filter: $_riskFilter',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppTheme.outlineVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sticky Assignment deploy button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 52,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedCaseIds.isNotEmpty ? AppTheme.primary : AppTheme.outline.withOpacity(0.12),
                        foregroundColor: _selectedCaseIds.isNotEmpty ? Colors.white : AppTheme.secondary.withOpacity(0.5),
                        elevation: _selectedCaseIds.isNotEmpty ? 4 : 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _selectedCaseIds.isNotEmpty ? () => _showBulkDeployDialog(allCases) : null,
                      icon: Icon(
                        Icons.person_add,
                        size: 20,
                        color: _selectedCaseIds.isNotEmpty ? Colors.white : AppTheme.secondary.withOpacity(0.4),
                      ),
                      label: Text(
                        _selectedCaseIds.isNotEmpty 
                            ? 'Assign ${_selectedCaseIds.length} Case${_selectedCaseIds.length > 1 ? 's' : ''} to Agent'
                            : 'Assign to Agent',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),

                  // Cases list view mapping
                  filteredCases.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48.0),
                            child: Column(
                              children: [
                                Icon(Icons.folder_shared_outlined, size: 56, color: AppTheme.outline.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No portfolio cases found in segment.',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredCases.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final caseItem = filteredCases[index];
                            final isChecked = _selectedCaseIds.contains(caseItem.id);

                            return _buildCaseCard(caseItem, isChecked);
                          },
                        ),
                  const SizedBox(height: 80),
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
              'Case Assignment Manager',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          body: scaffoldBody,
        );
      },
    );
  }

  Widget _buildSegmentButton(String segmentName) {
    final isSelected = _selectedSegment == segmentName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSegment = segmentName;
          _selectedCaseIds.clear(); // Reset selections on segment flip
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          segmentName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCaseCard(CaseItem caseItem, bool isChecked) {
    return CustomBentoCard(
      padding: 0,
      onTap: () {
        setState(() {
          if (isChecked) {
            _selectedCaseIds.remove(caseItem.id);
          } else {
            _selectedCaseIds.add(caseItem.id);
          }
        });
      },
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedCaseIds.add(caseItem.id);
                    } else {
                      _selectedCaseIds.remove(caseItem.id);
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
                  // Upper block (Loan ID & Overdue + Name & Amount)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              caseItem.loanId,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.outline,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              caseItem.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${caseItem.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            caseItem.overdueStatus,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: caseItem.overdueStatus.contains('Tomorrow') || caseItem.overdueStatus.contains('days') 
                                  ? AppTheme.onSurfaceVariant 
                                  : AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.outlineVariant),
                  const SizedBox(height: 12),

                  // Lower block (Location & Risk tags)
                  Row(
                    children: [
                      // Location label
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            caseItem.location,
                            style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Risk label
                      Row(
                        children: [
                          Icon(caseItem.riskIcon, size: 14, color: AppTheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            caseItem.riskLevel,
                            style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // If assigned, show who has this case
                  if (caseItem.assignedAgentName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.support_agent, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Assignee: ${caseItem.assignedAgentName}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Filter by Priority / Risk', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All Risk Profiles', 'ALL'),
              _buildFilterOption('Critical', 'Critical'),
              _buildFilterOption('High Risk', 'High Risk'),
              _buildFilterOption('First Notice', 'First Notice'),
              _buildFilterOption('Low Balance', 'Low Balance'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String value) {
    final isSelected = _riskFilter == value;
    return ListTile(
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
          _riskFilter = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showBulkDeployDialog(List<CaseItem> allCases) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_outlined, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text('Deploy Active Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Assigning ${_selectedCaseIds.length} Case${_selectedCaseIds.length > 1 ? 's' : ''} simultaneously.',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SELECT AGENT PORTFOLIO TARGET:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _db.agents.where((a) => !a.isAdmin).length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final agent = _db.agents.where((a) => !a.isAdmin).toList()[index];
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
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Assign All',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                        onTap: () {
                          // Execute bulk migrations on database service loop!
                          for (var id in _selectedCaseIds) {
                            if (id.startsWith('cust_')) {
                              _db.assignCase(id, agent.id);
                            } else {
                              // Static local override
                              _mockAssignments[id] = agent.id;
                            }
                          }

                          final count = _selectedCaseIds.length;
                          setState(() {
                            _selectedCaseIds.clear(); // Reset selections
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('Successfully deployed $count case${count > 1 ? 's' : ''} to ${agent.name}.'),
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
