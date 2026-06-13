import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_bento_card.dart';
import '../../models/agent.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_feedback.dart';

class EditPermissionsScreen extends StatefulWidget {
  final Agent agent;

  const EditPermissionsScreen({
    super.key,
    required this.agent,
  });

  @override
  State<EditPermissionsScreen> createState() => _EditPermissionsScreenState();
}

class _EditPermissionsScreenState extends State<EditPermissionsScreen> {
  // Stateful permission toggles
  bool _accessHistory = true;
  bool _editDetails = true;
  bool _approvePartial = false;
  bool _exportData = true;
  bool _deleteRecords = false;

  bool _isSaving = false;
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.agent.zone;
  }

  @override
  Widget build(BuildContext context) {
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
          'Edit Permissions',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outlineVariant, width: 1),
              image: DecorationImage(
                image: NetworkImage(widget.agent.avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Agent Identity Card (Bento Style)
                CustomBentoCard(
                  padding: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.shieldCheck, color: AppTheme.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TARGET AGENT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Agent ID: ${widget.agent.id.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            Text(
                              'Region: $_selectedRegion • v2.4.0',
                              style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Regional Assignment Selector
                CustomBentoCard(
                  padding: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'REGIONAL ASSIGNMENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          LucideIcons.chevronDown,
                          color: AppTheme.secondary,
                          size: 18,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Mumbai Metro Area',
                            child: Text('Mumbai Metro Area (North Sector)'),
                          ),
                          DropdownMenuItem(
                            value: 'Mumbai South',
                            child: Text('Mumbai South (South Sector)'),
                          ),
                          DropdownMenuItem(
                            value: 'Mumbai West',
                            child: Text('Mumbai West (West Sector)'),
                          ),
                          DropdownMenuItem(
                            value: 'Mumbai East',
                            child: Text('Mumbai East (East Sector)'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedRegion = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Permission Toggles List
                Column(
                  children: [
                    _buildPermissionToggle(
                      'Access Collections History',
                      'Allow agent to view historical ledger data and previous transaction attempts for all assigned debtors.',
                      _accessHistory,
                      (val) => setState(() => _accessHistory = val),
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionToggle(
                      'Edit Customer Details',
                      'Permit modifications to contact information, addresses, and employment status in the field.',
                      _editDetails,
                      (val) => setState(() => _editDetails = val),
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionToggle(
                      'Approve Partial Payments',
                      'Enable authorization for payment plans and partial settlements without immediate supervisor override.',
                      _approvePartial,
                      (val) => setState(() => _approvePartial = val),
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionToggle(
                      'Export Data',
                      'Download collection summaries and route performance reports as CSV or PDF documents.',
                      _exportData,
                      (val) => setState(() => _exportData = val),
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionToggle(
                      'Delete Records',
                      'Ability to permanently remove transaction logs or debtor profiles from the local and sync databases.',
                      _deleteRecords,
                      (val) => setState(() => _deleteRecords = val),
                      isHighRisk: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // System Note Info card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.info, size: 18, color: AppTheme.secondary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Changes to permissions are logged and audited. The agent will be notified via push notification once these updates are synchronized.',
                          style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar Footer
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppTheme.outlineVariant, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.outline, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSaveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Saving...', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.save, size: 16),
                                      SizedBox(width: 6),
                                      Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Styled Permission toggle card
  Widget _buildPermissionToggle(
    String title,
    String description,
    bool val,
    ValueChanged<bool> onChanged, {
    bool isHighRisk = false,
  }) {
    return CustomBentoCard(
      padding: 16,
      onTap: () => onChanged(!val),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    if (isHighRisk) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIGH RISK',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.error,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 32,
            width: 44,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch(
                value: val,
                activeColor: AppTheme.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppTheme.outlineVariant,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stateful save workflow
  void _handleSaveChanges() {
    setState(() {
      _isSaving = true;
    });

    // Simulate saving delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      // Update region assignment in shared DatabaseService
      if (_selectedRegion != null) {
        DatabaseService().updateAgentZone(widget.agent.id, _selectedRegion!);
      }

      setState(() {
        _isSaving = false;
      });

      // Show a floating material toast
      CustomFeedback.showToast(
        context,
        'Permissions Updated Successfully',
        type: 'success',
      );

      // Return back to profile
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    });
  }
}
