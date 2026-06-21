import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_bento_card.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_feedback.dart';
import '../../constants/app_constants.dart';
import '../../models/agent.dart';
import '../../config/field_mapping.dart';

class AddAgentScreen extends StatefulWidget {
  const AddAgentScreen({super.key});

  @override
  State<AddAgentScreen> createState() => _AddAgentScreenState();
}

class _AddAgentScreenState extends State<AddAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRegion;

  // Toggle values
  bool _accessHistory = true;
  bool _approvePartial = false;
  bool _deleteRecords = false;

  late final Map<String, bool> _fieldPermissions;

  @override
  void initState() {
    super.initState();
    _fieldPermissions = {
      for (var key in ExcelFieldMapping.mapping.keys) key: false,
    };
  }

  // Form states
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          'Agent Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb & Section Title
              const Text(
                'ADMIN / USER MANAGEMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Assign New Agent',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Bento Section: Identity Group stacked vertically
              CustomBentoCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter agent full name',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Full name required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact Details Card stacked vertically
              CustomBentoCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,

                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: 'Enter agent email',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email required';
                        }
                        if (!AppConstants.emailRegex.hasMatch(val.trim())) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Contact Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      maxLength: 10,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: 'Enter agent phone',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Phone required';
                        }
                        if (!AppConstants.mobileRegex.hasMatch(val.trim())) {
                          return 'Invalid phone format (must be 10 digits)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Password and Confirm Password Card
              CustomBentoCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Credentials',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter password (min 6 characters)',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: AppTheme.secondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password required';
                        }
                        if (!AppConstants.passwordRegex.hasMatch(val)) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Confirm password',

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: AppTheme.secondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Confirm password required';
                        }
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Regional Assignment dropdown card
              CustomBentoCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Regional Assignment',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Region/Sector',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),

                      hint: Text(
                        'Select a region...',
                        style: TextStyle(
                          color: AppTheme.secondary.withOpacity(0.5),
                        ),
                      ),
                      icon: const Icon(
                        LucideIcons.chevronDown,
                        color: AppTheme.secondary,
                      ),
                      items: DatabaseService.regionalDropdownValues.map((e) {
                        return DropdownMenuItem(
                          value: e['value'],
                          child: Text(e['label'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRegion = val;
                        });
                      },
                      validator: (val) {
                        if (val == null) return 'Region is required';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Initial Permissions switch list card
              CustomBentoCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Initial Permissions',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                        ),
                        TextButton(
                          onPressed: _showAllRolesBottomSheet,
                          child: const Text(
                            'View All Roles',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Switch 1: Access Collections History
                    _buildFormPermissionRow(
                      LucideIcons.history,
                      'Access Collections History',
                      'Allow agent to view historical ledger data and previous transaction attempts for all assigned debtors.',
                      _accessHistory,
                      (val) => setState(() => _accessHistory = val),
                    ),

                    // Switch 2: Approve Partial Payments
                    _buildFormPermissionRow(
                      LucideIcons.percent,
                      'Approve Partial Payments',
                      'Enable authorization for payment plans and partial settlements without immediate supervisor override.',
                      _approvePartial,
                      (val) => setState(() => _approvePartial = val),
                    ),

                    // Switch 3: Remove Assigned Records
                    _buildFormPermissionRow(
                      LucideIcons.trash2,
                      'Remove Assigned Records',
                      'Allows agents to remove assigned customer records from the system.',
                      _deleteRecords,
                      (val) => setState(() => _deleteRecords = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Creation / Submit Action Buttons (Vertically stacked)
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(
                          LucideIcons.userPlus,
                          size: 20,
                          color: Colors.white,
                        ),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Create Agent Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppTheme.outlineVariant,
                      width: 2.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Discard Draft',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormPermissionRow(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFC3C6D6), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFD3E4FE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF00328A), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeColor: const Color(0xFF00328A),
            activeTrackColor: const Color(0xFFD3E4FE),
            inactiveThumbColor: AppTheme.secondary,
            inactiveTrackColor: Colors.white,
            trackOutlineColor: MaterialStateProperty.all(
              const Color(0xFFC3C6D6),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Handle form submission and database registration
  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final String inputName = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String phone = _phoneController.text.trim();
      final String password = _passwordController.text.trim();
      final String finalZone = _selectedRegion ?? 'Mumbai Metro Area';

      // Fetch active admin ID
      final int adminId = int.tryParse(_db.currentUser?.id ?? '') ?? 1;

      try {
        final apiService = ApiService();
        _fieldPermissions['accessHistory'] = _accessHistory;
        _fieldPermissions['approvePartial'] = _approvePartial;
        _fieldPermissions['deleteRecords'] = _deleteRecords;
        final response = await apiService.createAgent(
          adminId: adminId,
          fullName: inputName,
          email: email,
          mobile: phone,
          password: password,
          region: finalZone,
          permissions: _fieldPermissions,
        );

        // API Success. Extract ID from response details if available
        String createdId = 'unknown';
        final data = response['data'];
        if (data != null && data is List && data.isNotEmpty) {
          final agentData = data[0];
          final agentObj = agentData['agent'];
          if (agentObj != null) {
            createdId =
                (agentObj['agent_id'] ?? agentObj['id'])?.toString() ??
                'unknown';
          } else {
            createdId =
                (agentData['agent_id'] ?? agentData['id'])?.toString() ??
                'unknown';
          }
        }

        // Fallback or custom avatar
        final List<String> avatars = [
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        ];
        final String randAvatar = avatars[Random().nextInt(avatars.length)];

        // Create local model object to sync inside local list provider
        final newAgent = Agent(
          id: createdId,
          name: inputName,
          avatarUrl: randAvatar,
          zone: finalZone,
          assignedTarget: 0,
          collectedAmount: 0.0,
          casesCount: 0,
          pendingVisitsCount: 0,
          isAdmin: false,
          isOnline: true,
          email: email,
          phone: phone,
          joinDate: DateTime.now(),
          permissions: _fieldPermissions,
        );

        // Save in state provider
        _db.registerAgent(newAgent);

        // Alert UI
        if (mounted) {
          CustomFeedback.showToast(
            context,
            'Profile Created Successfully: ${newAgent.name}',
            type: 'success',
          );

          // Go back to the Cockpit
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          String errorMsg = e.toString();
          if (errorMsg.startsWith('Exception: ')) {
            errorMsg = errorMsg.substring(11);
          }
          CustomFeedback.showFeedbackDialog(
            context,
            title: 'Registration Error',
            message: errorMsg,
            type: 'error',
            confirmLabel: 'OK',
            showCancel: false,
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
  }

  void _showAllRolesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                20,
                16,
                MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Field Visibility Permissions',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toggle which database fields the agent is allowed to view in their screens.',
                    style: TextStyle(fontSize: 13, color: AppTheme.secondary),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: _fieldPermissions.keys.map((fieldKey) {
                        // Create a user friendly label from key
                        final label =
                            fieldKey[0].toUpperCase() +
                            fieldKey
                                .substring(1)
                                .replaceAllMapped(
                                  RegExp(r'[A-Z]'),
                                  (match) => ' ${match.group(0)}',
                                );
                        return SwitchListTile(
                          title: Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                          subtitle: Text(
                            'Access to view "$fieldKey" data',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _fieldPermissions[fieldKey] ?? false,
                          activeColor: AppTheme.primary,
                          onChanged: (bool value) {
                            setModalState(() {
                              _fieldPermissions[fieldKey] = value;
                            });
                            setState(() {
                              _fieldPermissions[fieldKey] = value;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
