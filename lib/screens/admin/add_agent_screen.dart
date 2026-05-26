import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_bento_card.dart';
import '../../services/database_service.dart';
import '../../models/agent.dart';

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
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedRegion;

  // Toggle values
  bool _recordPayments = true;
  bool _modifyLedgers = false;
  bool _accessSensitive = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with a random ID matching Stitch format (e.g. 8843-XC)
    _idController.text = _generateRandomId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ID generator engine
  String _generateRandomId() {
    final rand = Random();
    final randomDigits = 1000 + rand.nextInt(9000);
    final char1 = String.fromCharCode(65 + rand.nextInt(26));
    final char2 = String.fromCharCode(65 + rand.nextInt(26));
    return '$randomDigits-$char1$char2';
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
                        hintText: 'e.g. Marcus Thorne',
                        hintStyle: TextStyle(
                          color: AppTheme.secondary.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 2,
                          ),
                        ),
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

              // Agent ID card stacked vertically
              CustomBentoCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agent ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _idController,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        fillColor: const Color(0xFFEFF4FF),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            LucideIcons.refreshCw,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _idController.text = _generateRandomId();
                            });
                          },
                        ),
                      ),
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                        hintText: 'm.thorne@debtconnect.pro',
                        hintStyle: TextStyle(
                          color: AppTheme.secondary.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email required';
                        }
                        if (!val.contains('@')) {
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
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: '+1 (555) 000-0000',
                        hintStyle: TextStyle(
                          color: AppTheme.secondary.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Phone required';
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppTheme.error,
                            width: 1,
                          ),
                        ),
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
                      items: const [
                        DropdownMenuItem(
                          value: 'Mumbai Metro Area',
                          child: Text('North Sector (Premium Accounts)'),
                        ),
                        DropdownMenuItem(
                          value: 'Mumbai South',
                          child: Text('South Sector (Standard Collections)'),
                        ),
                        DropdownMenuItem(
                          value: 'Mumbai West',
                          child: Text('West Sector (Commercial Hub)'),
                        ),
                        DropdownMenuItem(
                          value: 'Mumbai East',
                          child: Text('East Sector (Retail Debt)'),
                        ),
                      ],
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
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

                    // Switch 1: Record Payments
                    _buildFormPermissionRow(
                      LucideIcons.banknote,
                      'Record Payments',
                      'Allow agent to finalize collection entries',
                      _recordPayments,
                      (val) => setState(() => _recordPayments = val),
                    ),

                    // Switch 2: Modify Ledgers
                    _buildFormPermissionRow(
                      LucideIcons.notebookPen,
                      'Modify Ledgers',
                      'Update primary debt record details',
                      _modifyLedgers,
                      (val) => setState(() => _modifyLedgers = val),
                    ),

                    // Switch 3: Access Sensitive Data
                    _buildFormPermissionRow(
                      LucideIcons.shieldCheck,
                      'Access Sensitive Data',
                      'View full financial history of debtors',
                      _accessSensitive,
                      (val) => setState(() => _accessSensitive = val),
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
                  onPressed: _handleSubmit,
                  icon: const Icon(LucideIcons.userPlus, size: 20, color: Colors.white),
                  label: const Text(
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
        border: Border.all(
          color: const Color(0xFFC3C6D6),
          width: 1.0,
        ),
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
            trackOutlineColor: MaterialStateProperty.all(const Color(0xFFC3C6D6)),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Handle form submission and database registration
  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Pick a random default avatar image from existing agents to keep design high-fidelity
      final List<String> avatars = [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', // Rahul style
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', // Priya style
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      ];
      final String randAvatar = avatars[Random().nextInt(avatars.length)];

      final String inputName = _nameController.text.trim();
      final String generatedId = _idController.text.trim().toLowerCase();
      final String finalZone = _selectedRegion ?? 'Mumbai Metro Area';

      // Create model object
      final newAgent = Agent(
        id: generatedId,
        name: inputName,
        avatarUrl: randAvatar,
        zone: finalZone,
        assignedTarget: 15000.0,
        collectedAmount: 0.0,
        casesCount: 0,
        pendingVisitsCount: 0,
        isAdmin: false,
        isOnline: true,
      );

      // Save in state provider
      _db.registerAgent(newAgent);

      // Alert UI
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              const Icon(LucideIcons.circleCheck, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Profile Created Successfully: ${newAgent.name} (#${newAgent.id.toUpperCase()})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Go back to the Cockpit
      Navigator.pop(context);
    }
  }
}
