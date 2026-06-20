import 'dart:developer';
import 'package:intl/intl.dart';

import 'package:dept_collection_app/models/recent_upload_item.dart';
import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../models/customer.dart';
import '../models/payment_record.dart';
import '../models/notification.dart';
import 'shared_prefs_service.dart';
import 'api_service.dart';
import '../constants/app_constants.dart';

class DatabaseService extends ChangeNotifier {
  static const List<Map<String, String>> regionalDropdownValues = [
    {'value': 'Mumbai Metro Area', 'label': 'North Sector (Premium Accounts)'},
    {'value': 'Mumbai South', 'label': 'South Sector (Standard Collections)'},
    {'value': 'Mumbai West', 'label': 'West Sector (Commercial Hub)'},
    {'value': 'Mumbai East', 'label': 'East Sector (Retail Debt)'},
  ];

  // Singleton Pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    _initializeData();
  }

  final ApiService _apiService = ApiService();

  // App Auth State
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String _currentRole = AppConstants.roleAgent; // 'AGENT' or 'ADMIN'
  String get currentRole => _currentRole;

  Agent? _currentUser;
  Agent? get currentUser => _currentUser;

  // Active Data lists
  List<Agent> _agents = [];
  List<Agent> get agents => _agents;

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  List<PaymentRecord> _payments = [];
  List<PaymentRecord> get payments => _payments;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  List<Map<String, dynamic>> _activityFeed = [];
  List<Map<String, dynamic>> get activityFeed => _activityFeed;

  final List<RecentUploadItem> _recentUploads = [];
  List<RecentUploadItem> get recentUploadItem => _recentUploads;

  double _approvedTodaySum = 0.0;
  double get approvedTodaySum => _approvedTodaySum;

  int _rejectedCount = 0;
  int get rejectedCount => _rejectedCount;

  int _totalAssignmentsCount = 0;
  int get totalAssignmentsCount => _totalAssignmentsCount;

  int _completedAssignmentsCount = 0;
  int get completedAssignmentsCount => _completedAssignmentsCount;

  // Security Toggles
  bool biometricAuthEnabled = true;
  bool faceIdEnabled = true;
  bool touchIdEnabled = false;

  void toggleBiometric(bool value) {
    biometricAuthEnabled = value;
    notifyListeners();
  }

  void toggleFaceId(bool value) {
    faceIdEnabled = value;
    if (value) touchIdEnabled = false;
    notifyListeners();
  }

  void toggleTouchId(bool value) {
    touchIdEnabled = value;
    if (value) faceIdEnabled = false;
    notifyListeners();
  }

  // Prefilled Data Setup
  void _initializeData() {
    // 2. Initialize Customers

    fetchRecentUploads();

    // 3. Initialize Payments (Verification requests)
    _payments = [];

    // 4. Initialize Activity Feed
    _activityFeed = [
      {
        'id': 'act1',
        'title': 'Collection Verified',
        'subtitle': 'Agent Rahul • ₹12,500 collected from Amit Sharma',
        'time': '2m ago',
        'type': 'success',
      },
      {
        'id': 'act2',
        'title': 'Agent Login',
        'subtitle': 'Agent Priya • South Zone active',
        'time': '15m ago',
        'type': 'login',
      },
      {
        'id': 'act3',
        'title': 'Dispute Raised',
        'subtitle': 'Case #8821 • Debtor Refusal (David Miller)',
        'time': '1h ago',
        'type': 'warning',
      },
    ];

    // 5. Initialize Notifications
    _notifications = [
      AppNotification(
        id: 'not1',
        title: 'New Case Assigned',
        body: 'You have been assigned high priority case: Robert Henderson.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: 'assignment',
      ),
      AppNotification(
        id: 'not2',
        title: 'Target Approaching',
        body:
            'You are at 82% of your daily collection target. ₹2,241 remaining.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        type: 'alert',
      ),
    ];
  }

  // Auth Operations
  Future<bool> login(
    String email,
    String password, {
    required bool isAdmin,
  }) async {
    try {
      final response = await _apiService.login(
        email,
        password,
        isAdmin: isAdmin,
      );

      final dataList = response['data'];
      if (dataList != null && dataList is List && dataList.isNotEmpty) {
        final sessionData = dataList[0];
        final token = sessionData['token'];

        final isResponseAdmin = isAdmin;
        // final userData = isResponseAdmin
        //     ? sessionData[AppConstants.apiRoleAdmin]
        //     : sessionData[AppConstants.apiRoleAgent];

        if (token != null && sessionData != null) {
          final status = sessionData['status']?.toString() ?? '';
          if (status.toLowerCase() != AppConstants.statusActive) {
            throw Exception('You are blocked or inactive');
          }

          final role = isAdmin
              ? AppConstants.apiRoleAdmin
              : AppConstants.apiRoleAgent;

          // Store user details in prefs
          final Map<String, dynamic> storedUser = Map<String, dynamic>.from(
            sessionData,
          );
          storedUser['role'] = role;

          await SharedPrefsService.saveToken(token);
          await SharedPrefsService.saveUserData(storedUser);
          await SharedPrefsService.saveIsLoggedIn(true);

          _currentRole = isAdmin
              ? AppConstants.roleAdmin
              : AppConstants.roleAgent;

          final fullName = sessionData['full_name'] ?? 'Unknown User';
          final avatarUrl =
              (sessionData['profile_pic']?.toString().isNotEmpty == true)
              ? sessionData['profile_pic'].toString()
              : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=00328A&color=fff&size=150';

          final rawPermission =
              sessionData['permission'] ?? sessionData['permissions'];
          final Map<String, bool> parsedPermissions = {};
          if (rawPermission != null && rawPermission is Map) {
            rawPermission.forEach((key, value) {
              parsedPermissions[key.toString()] =
                  value == true || value == 1 || value == 'true';
            });
          }

          _currentUser = Agent(
            id:
                (isAdmin ? sessionData['admin_id'] : sessionData['agent_id'])
                    ?.toString() ??
                'unknown',
            name: fullName,
            avatarUrl: avatarUrl,
            zone:
                sessionData['region']?.toString() ??
                sessionData['zone']?.toString() ??
                'Default Zone',
            assignedTarget: isResponseAdmin ? 0.0 : 15000.0,
            collectedAmount: 0.0,
            casesCount: isResponseAdmin ? 0 : 5,
            pendingVisitsCount: isResponseAdmin ? 0 : 3,
            isAdmin: isResponseAdmin,
            isOnline: true,
            email: sessionData['email'] ?? '',
            phone: sessionData['mobile'] ?? '',
            address: sessionData['address'] ?? '',
            permissions: parsedPermissions,
          );

          _isLoggedIn = true;
          notifyListeners();

          if (!isAdmin) {
            fetchAgentAssignments(_currentUser!.id).catchError((e) {
              debugPrint('Error pre-fetching agent assignments: $e');
            });
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Try AutoLogin
  Future<void> tryAutoLogin() async {
    final isLoggedInSaved = SharedPrefsService.isLoggedIn();
    if (isLoggedInSaved) {
      final token = SharedPrefsService.getToken();
      final userData = SharedPrefsService.getUserData();
      if (token != null && userData != null) {
        _isLoggedIn = true;
        final isAdmin = userData['role'] == AppConstants.apiRoleAdmin;
        _currentRole = isAdmin
            ? AppConstants.roleAdmin
            : AppConstants.roleAgent;

        final fullName = userData['full_name'] ?? 'Unknown User';
        final avatarUrl =
            (userData['profile_pic']?.toString().isNotEmpty == true)
            ? userData['profile_pic'].toString()
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=00328A&color=fff&size=150';

        final rawPermission = userData['permission'] ?? userData['permissions'];
        final Map<String, bool> parsedPermissions = {};
        if (rawPermission != null && rawPermission is Map) {
          rawPermission.forEach((key, value) {
            parsedPermissions[key.toString()] =
                value == true || value == 1 || value == 'true';
          });
        }

        _currentUser = Agent(
          id:
              (userData['admin_id'] ?? userData['agent_id'])?.toString() ??
              'unknown',
          name: fullName,
          avatarUrl: avatarUrl,
          zone:
              userData['region']?.toString() ??
              userData['zone']?.toString() ??
              'Default Zone',
          assignedTarget: isAdmin ? 0.0 : 15000.0,
          collectedAmount: 0.0,
          casesCount: isAdmin ? 0 : 5,
          pendingVisitsCount: isAdmin ? 0 : 3,
          isAdmin: isAdmin,
          isOnline: true,
          email: userData['email'] ?? '',
          phone: userData['mobile'] ?? '',
          address: userData['address'] ?? '',
          permissions: parsedPermissions,
        );

        if (!isAdmin) {
          fetchAgentAssignments(_currentUser!.id).catchError((e) {
            debugPrint('Error auto-login pre-fetching agent assignments: $e');
          });
        }
      }
    }
  }

  void switchPortal(String role) {
    _currentRole = role;
    if (role == AppConstants.roleAdmin) {
      _currentUser = _agents.firstWhere(
        (a) => a.isAdmin,
        orElse: () => _agents[3],
      );
    } else {
      _currentUser = _agents.firstWhere(
        (a) => a.id == 'miller',
        orElse: () => _agents[0],
      );
    }
    notifyListeners();
  }

  // Logout function
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    await SharedPrefsService.clear();
    notifyListeners();
  }

  // Collection Operations (Agent recording payment)
  Future<void> recordPayment({
    required String customerId,
    required double amount,
    required String method,
    required String reference,
    String? receiptPath,
  }) async {
    final customer = _customers.firstWhere((c) => c.id == customerId);
    final txnId =
        'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Find assignmentId from corresponding customer
    final int? assignmentId = customer.assignmentId;

    if (assignmentId != null) {
      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      
      await _apiService.updateAssignment(
        assignmentId: assignmentId,
        scheduleDate: formattedDate,
        remarks: reference,
        paymentCollection: amount,
        paymentMethod: method,
        approvedImg: receiptPath ?? 'receipt.jpg',
        status: 'Pending', // Status is 'Pending' per user request!
      );
    }

    // Create pending payment record
    final newPayment = PaymentRecord(
      id: txnId,
      customerId: customerId,
      customerName: customer.name,
      agentId: _currentUser?.id ?? 'miller',
      agentName: _currentUser?.name ?? 'Agent Miller',
      amount: amount,
      paymentMethod: method,
      transactionReference: reference,
      receiptImagePath: receiptPath,
      timestamp: DateTime.now(),
      status: AppConstants.statusPending,
    );

    _payments.insert(0, newPayment);

    // Update customer status to pending verification
    _customers = _customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(status: AppConstants.statusPendingVerification);
      }
      return c;
    }).toList();

    // Decrease the agent pending visits count
    if (_currentUser != null && !_currentUser!.isAdmin) {
      _agents = _agents.map((a) {
        if (a.id == _currentUser!.id) {
          return a.copyWith(
            pendingVisitsCount: a.pendingVisitsCount > 0
                ? a.pendingVisitsCount - 1
                : 0,
          );
        }
        return a;
      }).toList();
      _currentUser = _agents.firstWhere((a) => a.id == _currentUser!.id, orElse: () => _currentUser!);
    }

    // Add activity for Admin Feed
    _activityFeed.insert(0, {
      'id': 'act_${txnId}',
      'title': 'Collection Recorded',
      'subtitle':
          '${_currentUser?.name} • ₹$amount pending approval for ${customer.name}',
      'time': 'Just now',
      'type': 'warning',
    });

    notifyListeners();
  }

  // Admin Approving Collection
  Future<void> approvePayment(String recordId) async {
    final recordIndex = _payments.indexWhere((p) => p.id == recordId);
    if (recordIndex == -1) return;

    final record = _payments[recordIndex];

    // Find assignmentId from corresponding customer or directly from recordId if it is a number
    final customer = _customers
        .where((c) => c.id == record.customerId)
        .firstOrNull;
    final int? assignmentId = int.tryParse(recordId) ?? customer?.assignmentId;

    if (assignmentId != null) {
      final scheduleDateFormatted = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(customer?.scheduledVisit ?? record.timestamp);
      await _apiService.updateAssignment(
        assignmentId: assignmentId,
        scheduleDate: scheduleDateFormatted,
        remarks:
            'Approved by Admin: Verified ${record.paymentMethod} payment of ₹${record.amount}',
        paymentCollection: record.amount,
        paymentMethod: record.paymentMethod,
        approvedImg: record.receiptImagePath ?? 'receipt.jpg',
        status: 'Completed',
      );
    }

    // Update record status to APPROVED
    _payments[recordIndex] = record.copyWith(
      status: AppConstants.statusApproved,
    );
    _approvedTodaySum += record.amount;
    _completedAssignmentsCount++;

    // Update customer status to PAID and clear due amount
    _customers = _customers.map((c) {
      if (c.id == record.customerId) {
        return c.copyWith(
          status: AppConstants.statusPaid,
          amountDue: c.amountDue - record.amount >= 0
              ? c.amountDue - record.amount
              : 0,
        );
      }
      return c;
    }).toList();

    // Credit agent targets
    _agents = _agents.map((a) {
      if (a.id == record.agentId) {
        return a.copyWith(collectedAmount: a.collectedAmount + record.amount);
      }
      return a;
    }).toList();

    // If active user is the approved agent, update current profile too
    if (_currentUser != null && _currentUser!.id == record.agentId) {
      _currentUser = _agents.firstWhere((a) => a.id == record.agentId);
    }

    // Push Notification to the specific Agent
    _notifications.insert(
      0,
      AppNotification(
        id: 'not_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Collection Verified',
        body:
            'Your collection of ₹${record.amount} for ${record.customerName} has been approved by admin.',
        timestamp: DateTime.now(),
        type: 'approval',
      ),
    );

    // Update activity feed
    _activityFeed.insert(0, {
      'id': 'act_app_${recordId}',
      'title': 'Collection Verified',
      'subtitle': 'Admin approved ₹${record.amount} by ${record.agentName}',
      'time': 'Just now',
      'type': 'success',
    });

    // Fetch latest uploads and assignments
    try {
      await fetchRecentUploads();
    } catch (e) {
      debugPrint('Error reloading data: $e');
      notifyListeners();
    }
  }

  // Admin Rejecting Collection
  Future<void> rejectPayment(String recordId) async {
    final recordIndex = _payments.indexWhere((p) => p.id == recordId);
    if (recordIndex == -1) return;

    final record = _payments[recordIndex];

    // Find assignmentId from corresponding customer or directly from recordId if it is a number
    final customer = _customers
        .where((c) => c.id == record.customerId)
        .firstOrNull;
    final int? assignmentId = int.tryParse(recordId) ?? customer?.assignmentId;

    if (assignmentId != null) {
      final scheduleDateFormatted = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(customer?.scheduledVisit ?? record.timestamp);
      await _apiService.updateAssignment(
        assignmentId: assignmentId,
        scheduleDate: scheduleDateFormatted,
        remarks:
            'Rejected by Admin: Invalid ${record.paymentMethod} payment verification.',
        paymentCollection: record.amount,
        paymentMethod: record.paymentMethod,
        approvedImg: record.receiptImagePath ?? 'receipt.jpg',
        status: 'Rejected',
      );
    }

    // Update record status to REJECTED
    _payments[recordIndex] = record.copyWith(
      status: AppConstants.statusRejected,
    );
    _rejectedCount++;

    // Update customer status back to OVERDUE
    _customers = _customers.map((c) {
      if (c.id == record.customerId) {
        return c.copyWith(status: AppConstants.statusOverdue);
      }
      return c;
    }).toList();

    // Notify agent
    _notifications.insert(
      0,
      AppNotification(
        id: 'not_rej_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Collection Rejected',
        body:
            'Your collection of ₹${record.amount} for ${record.customerName} was rejected. Please verify details.',
        timestamp: DateTime.now(),
        type: 'alert',
      ),
    );

    // Update activity feed
    _activityFeed.insert(0, {
      'id': 'act_rej_${recordId}',
      'title': 'Collection Rejected',
      'subtitle': 'Admin rejected ₹${record.amount} by ${record.agentName}',
      'time': 'Just now',
      'type': 'error',
    });

    // Fetch latest uploads and assignments
    try {
      await fetchRecentUploads();
    } catch (e) {
      debugPrint('Error reloading data: $e');
      notifyListeners();
    }
  }

  // Follow-up Scheduling
  Future<void> scheduleFollowUp({
    required String customerId,
    required DateTime date,
    required String remarks,
  }) async {
    final customer = _customers.firstWhere((c) => c.id == customerId);
    final int? assignmentId = customer.assignmentId;

    if (assignmentId != null) {
      final formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 12:00:00";

      await _apiService.updateAssignment(
        assignmentId: assignmentId,
        scheduleDate: formattedDate,
        remarks: remarks,
        paymentCollection: 0.0,
        paymentMethod: 'Cash',
        approvedImg: '',
        status: 'Pending',
      );
    }

    _customers = _customers.map((c) {
      if (c.id == customerId) {
        final List<String> updatedNotes = List.from(c.notes);
        updatedNotes.add(remarks);
        return c.copyWith(scheduledVisit: date, notes: updatedNotes);
      }
      return c;
    }).toList();

    final String agentName = _currentUser?.name ?? 'An Agent';
    _notifications.insert(
      0,
      AppNotification(
        id: 'not_sched_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Collection Scheduled',
        body:
            '$agentName scheduled a collection visit with ${customer.name} for ${date.day}/${date.month}/${date.year}.',
        timestamp: DateTime.now(),
        type: 'schedule',
        recipientRole: AppConstants.roleAdmin,
        customerId: customerId,
      ),
    );

    notifyListeners();
  }

  // Case Assignment Operation (Admin)
  Future<void> assignCase(String customerId, String newAgentId) async {
    Customer? oldCustomer = _customers
        .where((c) => c.id == customerId)
        .firstOrNull;
    if (oldCustomer == null) {
      for (var uploadItem in _recentUploads) {
        final match = uploadItem.customers
            .where((c) => c.id == customerId)
            .firstOrNull;
        if (match != null) {
          oldCustomer = match;
          break;
        }
      }
    }
    if (oldCustomer == null) return;

    // Format date as yyyy-MM-dd HH:mm:ss
    final now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    // Call API
    await _apiService.assignRecord(
      recordId: int.tryParse(customerId) ?? 0,
      agentId: int.tryParse(newAgentId) ?? 0,
      assignedBy: int.tryParse(_currentUser?.id ?? '') ?? 0,
      scheduleDate: formattedDate,
      remarks: "First visit pending",
      paymentCollection: 0.0,
      paymentMethod: "Cash",
      approvedImg: "",
      status: "Assigned",
    );

    final oldAgentId = oldCustomer.assignedAgentId;

    _customers = _customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(assignedAgentId: newAgentId);
      }
      return c;
    }).toList();

    // Update in recent uploads
    for (var uploadItem in _recentUploads) {
      for (int i = 0; i < uploadItem.customers.length; i++) {
        if (uploadItem.customers[i].id == customerId) {
          uploadItem.customers[i] = uploadItem.customers[i].copyWith(
            assignedAgentId: newAgentId,
          );
        }
      }
    }

    // Adjust case counts on agents
    _agents = _agents.map((a) {
      if (a.id == oldAgentId) {
        return a.copyWith(casesCount: a.casesCount > 0 ? a.casesCount - 1 : 0);
      }
      if (a.id == newAgentId) {
        return a.copyWith(casesCount: a.casesCount + 1);
      }
      return a;
    }).toList();

    if (_currentUser != null) {
      _currentUser = _agents.firstWhere(
        (a) => a.id == _currentUser!.id,
        orElse: () => _currentUser!,
      );
    }

    final newAgentName =
        _agents.where((a) => a.id == newAgentId).firstOrNull?.name ?? 'Agent';

    // Add activity feed
    _activityFeed.insert(0, {
      'id': 'act_asg_${customerId}',
      'title': 'Case Reassigned',
      'subtitle': '${oldCustomer.name} assigned to $newAgentName',
      'time': 'Just now',
      'type': 'login',
    });

    notifyListeners();
  }

  Future<void> unassignCase(String customerId) async {
    Customer? oldCustomer = _customers
        .where((c) => c.id == customerId)
        .firstOrNull;
    if (oldCustomer == null) {
      for (var uploadItem in _recentUploads) {
        final match = uploadItem.customers
            .where((c) => c.id == customerId)
            .firstOrNull;
        if (match != null) {
          oldCustomer = match;
          break;
        }
      }
    }
    if (oldCustomer == null) return;

    final assignmentId = oldCustomer.assignmentId;
    if (assignmentId != null) {
      await _apiService.deleteAssignment(assignmentId);
    }

    final oldAgentId = oldCustomer.assignedAgentId;

    _customers = _customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(
          assignedAgentId: '',
          assignedAgentName: '',
          assignmentId: null,
          status: 'Unassigned',
        );
      }
      return c;
    }).toList();

    // Update in recent uploads
    for (var uploadItem in _recentUploads) {
      for (int i = 0; i < uploadItem.customers.length; i++) {
        if (uploadItem.customers[i].id == customerId) {
          uploadItem.customers[i] = uploadItem.customers[i].copyWith(
            assignedAgentId: '',
            assignedAgentName: '',
            assignmentId: null,
            status: 'Unassigned',
          );
        }
      }
    }

    // Adjust case counts on agents
    _agents = _agents.map((a) {
      if (a.id == oldAgentId) {
        return a.copyWith(casesCount: a.casesCount > 0 ? a.casesCount - 1 : 0);
      }
      return a;
    }).toList();

    if (_currentUser != null) {
      _currentUser = _agents.firstWhere(
        (a) => a.id == _currentUser!.id,
        orElse: () => _currentUser!,
      );
    }

    // Add activity feed
    _activityFeed.insert(0, {
      'id': 'act_unsg_${customerId}',
      'title': 'Case Unassigned',
      'subtitle': '${oldCustomer.name} unassigned',
      'time': 'Just now',
      'type': 'warning',
    });

    notifyListeners();
  }

  // Case Priority Operation (Admin)
  Future<void> updateCasePriority(String customerId, String newPriority) async {
    Customer? targetCustomer = _customers
        .where((c) => c.id == customerId)
        .firstOrNull;
    if (targetCustomer == null) {
      for (var uploadItem in _recentUploads) {
        final match = uploadItem.customers
            .where((c) => c.id == customerId)
            .firstOrNull;
        if (match != null) {
          targetCustomer = match;
          break;
        }
      }
    }

    if (targetCustomer == null) return;

    // Call API to update priority on backend
    await _apiService.updateRecordPriority(
      recordId: customerId,
      priority: newPriority.toUpperCase(),
    );

    final String nameToMatch = targetCustomer.name.trim().toLowerCase();
    final String phoneToMatch = targetCustomer.phone.trim();
    final String loanIdToMatch = targetCustomer.loanId.trim();

    // Check matching criteria (satisfies "and all other records of customers")
    bool matchesTarget(Customer c) {
      if (c.id == customerId) return true;
      if (nameToMatch.isNotEmpty && c.name.trim().toLowerCase() == nameToMatch) {
        return true;
      }
      if (phoneToMatch.isNotEmpty && c.phone.trim() == phoneToMatch) {
        return true;
      }
      if (loanIdToMatch.isNotEmpty && c.loanId.trim() == loanIdToMatch) {
        return true;
      }
      return false;
    }

    _customers = _customers.map((c) {
      if (matchesTarget(c)) {
        return c.copyWith(priority: newPriority.toUpperCase());
      }
      return c;
    }).toList();

    // Update in recent uploads
    for (var uploadItem in _recentUploads) {
      for (int i = 0; i < uploadItem.customers.length; i++) {
        if (matchesTarget(uploadItem.customers[i])) {
          uploadItem.customers[i] = uploadItem.customers[i].copyWith(
            priority: newPriority.toUpperCase(),
          );
        }
      }
    }

    notifyListeners();
  }

  // Case Delete Operation (Admin)
  Future<void> deleteCase(int fileId, String customerId) async {
    Customer? customer = _customers
        .where((c) => c.id == customerId)
        .firstOrNull;
    if (customer == null) {
      for (var uploadItem in _recentUploads) {
        final match = uploadItem.customers
            .where((c) => c.id == customerId)
            .firstOrNull;
        if (match != null) {
          customer = match;
          break;
        }
      }
    }
    if (customer == null) return;
    final targetCustomer = customer;

    try {
      await _apiService.deleteFileRecord(fileId: fileId, recordId: customerId);

      // Remove from active list
      _customers.removeWhere((c) => c.id == customerId);

      // Remove from recent uploads list
      for (var uploadItem in _recentUploads) {
        uploadItem.customers.removeWhere((c) => c.id == customerId);
      }

      // Adjust agent case count if assigned
      if (targetCustomer.assignedAgentId.isNotEmpty &&
          targetCustomer.assignedAgentId != 'unassigned') {
        _agents = _agents.map((a) {
          if (a.id == targetCustomer.assignedAgentId) {
            return a.copyWith(
              casesCount: a.casesCount > 0 ? a.casesCount - 1 : 0,
            );
          }
          return a;
        }).toList();
      }

      // Log update in activity feed
      _activityFeed.insert(0, {
        'id':
            'act_delete_${customerId}_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Case Deleted',
        'subtitle': 'Admin deleted portfolio record for ${targetCustomer.name}',
        'time': 'Just now',
        'type': 'error',
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting case from API: $e');
      rethrow;
    }
  }

  // Bulk Case Delete Operation (Admin)
  Future<void> deleteMultipleCases(int fileId, List<String> customerIds) async {
    try {
      for (var id in customerIds) {
        Customer? customer = _customers.where((c) => c.id == id).firstOrNull;
        if (customer == null) {
          for (var uploadItem in _recentUploads) {
            final match = uploadItem.customers
                .where((c) => c.id == id)
                .firstOrNull;
            if (match != null) {
              customer = match;
              break;
            }
          }
        }
        if (customer == null) continue;
        final targetCustomer = customer;

        await _apiService.deleteFileRecord(fileId: fileId, recordId: id);

        // Adjust agent case count if assigned
        if (targetCustomer.assignedAgentId.isNotEmpty &&
            targetCustomer.assignedAgentId != 'unassigned') {
          _agents = _agents.map((a) {
            if (a.id == targetCustomer.assignedAgentId) {
              return a.copyWith(
                casesCount: a.casesCount > 0 ? a.casesCount - 1 : 0,
              );
            }
            return a;
          }).toList();
        }
      }

      // Remove from active list
      _customers.removeWhere((c) => customerIds.contains(c.id));

      // Remove from recent uploads list
      for (var uploadItem in _recentUploads) {
        uploadItem.customers.removeWhere((c) => customerIds.contains(c.id));
      }

      // Log update in activity feed
      _activityFeed.insert(0, {
        'id': 'act_bulk_delete_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Bulk Cases Deleted',
        'subtitle':
            'Admin deleted ${customerIds.length} portfolio records simultaneously.',
        'time': 'Just now',
        'type': 'error',
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error bulk deleting cases from API: $e');
      rethrow;
    }
  }

  // CSV Data upload simulation
  Future<void> uploadBankRecords(
    String fileName,
    List<Map<String, dynamic>> records,
  ) async {
    // First save the data into the api
    await _apiService.uploadRecords(fileName, records);
    await fetchRecentUploads();
    notifyListeners();
  }

  // Notification Operations
  void markNotificationAsRead(String id) {
    _notifications = _notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    _notifications = _notifications.map((n) {
      if (n.recipientRole == _currentRole) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    notifyListeners();
  }

  // Register New Field Agent
  void registerAgent(Agent newAgent) {
    _agents.add(newAgent);

    // Add to activity feed
    _activityFeed.insert(0, {
      'id': 'act_reg_${newAgent.id}',
      'title': 'New Agent Registered',
      'subtitle': 'Agent ${newAgent.name} assigned to ${newAgent.zone}',
      'time': 'Just now',
      'type': 'success',
    });

    notifyListeners();
  }

  // Toggle Field Agent Status
  Future<void> toggleAgentOnlineStatus(String agentId, bool isOnline) async {
    final agentMatches = _agents.where((a) => a.id == agentId);

    if (agentMatches.isEmpty) {
      log('Agent not found: $agentId');
      return;
    }

    final agent = agentMatches.first;
    final statusString = isOnline ? 'Active' : 'Inactive';

    await _apiService.updateAgent(
      email: agent.email,
      fullName: agent.name,
      mobile: agent.phone,
      agentId: agentId,
      status: statusString,
      region: agent.zone,
      permissions: agent.permissions,
    );

    _agents = _agents.map((a) {
      if (a.id == agentId) {
        return a.copyWith(isOnline: isOnline);
      }
      return a;
    }).toList();

    if (_currentUser?.id == agentId) {
      final currentUserMatch = _agents.where((a) => a.id == agentId);

      if (currentUserMatch.isNotEmpty) {
        _currentUser = currentUserMatch.first;
      }
    }

    _activityFeed.insert(0, {
      'id': 'act_status_${agentId}_${DateTime.now().millisecondsSinceEpoch}',
      'title': isOnline ? 'Agent Online' : 'Agent Offline',
      'subtitle':
          'Agent ID #${agentId.toUpperCase()} is now ${isOnline ? 'Online' : 'Offline'}',
      'time': 'Just now',
      'type': isOnline ? 'login' : 'warning',
    });

    notifyListeners();
  }

  Future<void> updateAgentOnBackend({
    required String agentId,
    String? fullName,
    String? email,
    String? mobile,
    String? status,
    String? region,
    Map<String, bool>? permissions,
  }) async {
    Agent? agent;
    int agentIndex = _agents.indexWhere((a) => a.id == agentId);
    if (agentIndex != -1) {
      agent = _agents[agentIndex];
    } else if (_currentUser != null && _currentUser!.id == agentId) {
      agent = _currentUser;
    }

    if (agent == null) {
      throw Exception('User not found');
    }

    final finalFullName = fullName ?? agent.name;
    final finalEmail = email ?? agent.email;
    final finalMobile = mobile ?? agent.phone;
    final finalStatus = status ?? (agent.isOnline ? 'Active' : 'Inactive');
    final finalRegion = region ?? agent.zone;
    final finalPermissions = permissions ?? agent.permissions;

    await _apiService.updateAgent(
      agentId: agentId,
      fullName: finalFullName,
      email: finalEmail,
      mobile: finalMobile,
      status: finalStatus,
      region: finalRegion,
      permissions: finalPermissions,
    );

    final updatedAgent = agent.copyWith(
      name: finalFullName,
      email: finalEmail,
      phone: finalMobile,
      isOnline: finalStatus.toLowerCase() == AppConstants.statusActive,
      zone: finalRegion,
      permissions: finalPermissions,
    );

    if (agentIndex != -1) {
      _agents[agentIndex] = updatedAgent;
    }

    if (_currentUser?.id == agentId) {
      _currentUser = updatedAgent;
    }

    notifyListeners();
  }

  // Update Field Agent Personal Profile details (Stitch Specs)
  void updateAgentProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String avatarUrl,
  }) {
    if (_currentUser == null) return;

    final finalAvatarUrl = avatarUrl.isNotEmpty
        ? avatarUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name.isNotEmpty ? name : "User")}&background=00328A&color=fff&size=150';

    final updatedAgent = _currentUser!.copyWith(
      name: name,
      email: email,
      phone: phone,
      address: address,
      avatarUrl: finalAvatarUrl,
    );

    // Update inside _agents list
    _agents = _agents.map((a) {
      if (a.id == _currentUser!.id) {
        return updatedAgent;
      }
      return a;
    }).toList();

    _currentUser = updatedAgent;

    // Update in SharedPreferences so it persists across restarts
    final storedUser = SharedPrefsService.getUserData();
    if (storedUser != null) {
      storedUser['full_name'] = name;
      storedUser['email'] = email;
      storedUser['mobile'] = phone;
      storedUser['address'] = address;
      storedUser['profile_pic'] = finalAvatarUrl;
      SharedPrefsService.saveUserData(storedUser);
    }

    // Log update in activity feed
    _activityFeed.insert(0, {
      'id':
          'act_profile_update_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Profile Updated',
      'subtitle':
          'Agent #${_currentUser!.id.toUpperCase()} successfully updated personal identity records.',
      'time': 'Just now',
      'type': 'success',
    });

    notifyListeners();
  }

  // Update Field Agent's assigned region/zone
  void updateAgentZone(String agentId, String newZone) {
    _agents = _agents.map((a) {
      if (a.id == agentId) {
        return a.copyWith(zone: newZone);
      }
      return a;
    }).toList();

    if (_currentUser?.id == agentId) {
      _currentUser = _agents.firstWhere((a) => a.id == agentId);
    }

    // Log update in activity feed
    _activityFeed.insert(0, {
      'id':
          'act_zone_update_${agentId}_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Agent Region Updated',
      'subtitle': 'Agent ID #${agentId.toUpperCase()} reassigned to $newZone.',
      'time': 'Just now',
      'type': 'success',
    });

    notifyListeners();
  }

  // recent uploads from api

  Future<void> fetchRecentUploads() async {
    try {
      final List<Map<String, dynamic>> recentUploadsData = await _apiService
          .getRecentUploads();

      List<RecentUploadItem> recentUploads = [];

      for (var data in recentUploadsData) {
        recentUploads.add(RecentUploadItem.fromJson(data));
      }

      _recentUploads.clear();
      _recentUploads.addAll(recentUploads);

      await fetchAssignmentsForQueue();

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint(
        'Error fetching recent uploads files: $e , StackTrace: ${stackTrace}',
      );
      rethrow;
    }
  }

  Future<void> fetchRecordsForFile({
    required int fileId,
    required int limits,
  }) async {
    try {
      // Fetch assignments first
      List<Map<String, dynamic>> assignmentsData = [];
      try {
        assignmentsData = await _apiService.getAssignments();
      } catch (e) {
        debugPrint('Error fetching assignments: $e');
      }

      final Map<String, Map<String, dynamic>> assignmentMap = {};
      for (var assignment in assignmentsData) {
        final recordId = assignment['record_id']?.toString();
        if (recordId != null) {
          assignmentMap[recordId] = assignment;
        }
      }

      final List<Map<String, dynamic>> recordsData = await _apiService
          .getFileRecords(fileId: fileId, limits: limits);

      List<Customer> records = [];

      for (var data in recordsData) {
        final recordId = data['record_id']?.toString();
        final assignment = assignmentMap[recordId];

        if (assignment != null) {
          final mergedData = Map<String, dynamic>.from(data);
          mergedData['status'] =
              assignment['assignment_status'] ?? assignment['status'];
          mergedData['assignment_id'] = assignment['assignment_id'];

          final nestedData = Map<String, dynamic>.from(
            mergedData['data'] as Map? ?? {},
          );

          // Merge customer data from assignment data map if available
          final assignmentData = assignment['data'] as Map?;
          if (assignmentData != null) {
            assignmentData.forEach((key, value) {
              nestedData[key] = value;
            });
          }

          final agentData = assignment['agent'] as Map?;
          final agentIdStr =
              agentData?['agent_id']?.toString() ??
              assignment['agent_id']?.toString() ??
              '';
          final agentName =
              agentData?['full_name']?.toString() ??
              _agents.where((a) => a.id == agentIdStr).firstOrNull?.name ??
              '';

          nestedData['assignedAgentId'] = agentIdStr;
          nestedData['assignedAgentName'] = agentName;
          nestedData['assigned_by'] = assignment['assigned_by']?.toString();
          nestedData['scheduledVisit'] = assignment['schedule_date'];
          nestedData['remarks'] = assignment['remarks'];

          mergedData['data'] = nestedData;
          records.add(Customer.fromJson(mergedData));
        } else {
          records.add(Customer.fromJson(data));
        }
      }

      final fileIndex = _recentUploads.indexWhere(
        (item) => item.fileId == fileId,
      );
      if (fileIndex != -1) {
        _recentUploads[fileIndex].customers.clear();
        _recentUploads[fileIndex].customers.addAll(records);
      }

      // Also set the active _customers list to contain only this file's customers
      _customers.clear();
      _customers.addAll(records);

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error fetching file records: $e , StackTrace: ${stackTrace}');
      rethrow;
    }
  }

  Future<void> deleteFile(int fileId) async {
    try {
      await _apiService.deleteFile(fileId);
      _recentUploads.removeWhere((item) => item.fileId == fileId);
      _customers.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  Future<void> deleteMultipleFiles(List<int> fileIds) async {
    try {
      for (var id in fileIds) {
        await _apiService.deleteFile(id);
      }
      _recentUploads.removeWhere((item) => fileIds.contains(item.fileId));
      _customers.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error bulk deleting files: $e');
      rethrow;
    }
  }

  Future<void> fetchAgentsFromApi() async {
    try {
      final List<Map<String, dynamic>> agentsData = await _apiService
          .getAllAgents();
      final List<Agent> apiAgents = [];
      for (var data in agentsData) {
        final id = (data['agent_id'] ?? data['id'])?.toString() ?? '';
        final name = data['full_name'] ?? data['name'] ?? 'Agent';
        final email = data['email'] ?? '';
        final phone = data['mobile'] ?? data['phone'] ?? '';
        final status = data['status'] ?? 'Active';
        final isOnline = status.toLowerCase() == 'active';
        final avatarUrl =
            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=00328A&color=fff&size=150';

        final region =
            data['region']?.toString() ??
            data['zone']?.toString() ??
            'Patna,Bihar';
        final rawPermission = data['permission'] ?? data['permissions'];
        final Map<String, bool> parsedPermissions = {};
        if (rawPermission != null && rawPermission is Map) {
          rawPermission.forEach((key, value) {
            parsedPermissions[key.toString()] =
                value == true || value == 1 || value == 'true';
          });
        }

        apiAgents.add(
          Agent(
            id: id,
            name: name,
            avatarUrl: avatarUrl,
            zone: region,
            assignedTarget: 15000.0,
            collectedAmount: 0.0,
            casesCount: 0,
            pendingVisitsCount: 0,
            isAdmin: false,
            isOnline: isOnline,
            email: email,
            phone: phone,
            permissions: parsedPermissions,
          ),
        );
      }

      // final adminAgents = _agents.where((a) => a.isAdmin).toList();
      _agents = [...apiAgents];
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error fetching agents: $e , StackTrace: ${stackTrace}');
      rethrow;
    }
  }

  Future<void> fetchAssignmentsForQueue() async {
    try {
      // Pre-fetch agents if not already loaded to resolve actual agent names
      if (_agents.isEmpty) {
        try {
          await fetchAgentsFromApi();
        } catch (e) {
          debugPrint('Error fetching agents: $e');
        }
      }

      final List<Map<String, dynamic>> assignmentsData = await _apiService
          .getAssignments();
      final List<PaymentRecord> queuePayments = [];

      double tempApprovedSum = 0.0;
      int tempRejectedCount = 0;
      int tempTotalCount = assignmentsData.length;
      int tempCompletedCount = 0;

      for (var assignment in assignmentsData) {
        final String statusRaw =
            assignment['assignment_status']?.toString() ??
            assignment['status']?.toString() ??
            '';
        final statusLower = statusRaw.toLowerCase();
        final amount =
            double.tryParse(
              assignment['payment_collection']?.toString() ?? '',
            ) ??
            0.0;

        if (statusLower == 'completed' || statusLower == 'paid') {
          tempCompletedCount++;
          tempApprovedSum += amount;
        } else if (statusLower == 'rejected') {
          tempRejectedCount++;
        }

        // If status is "In Progress" or "Pending", it represents a payment verification pending request!
        if (statusLower == 'in progress' || statusLower == 'pending_verification' || statusLower == 'pending') {
          final recordId = assignment['record_id']?.toString() ?? '';
          final agentData = assignment['agent'] as Map?;
          final agentId =
              agentData?['agent_id']?.toString() ??
              assignment['agent_id']?.toString() ??
              '';
          final method = assignment['payment_method']?.toString() ?? 'Cash';
          final remarks =
              assignment['remarks']?.toString() ?? 'Visited customer';
          final approvedImg = assignment['approved_img']?.toString() ?? '';

          // Let's resolve the agent name
          final agentName =
              agentData?['full_name']?.toString() ??
              _agents.where((a) => a.id == agentId).firstOrNull?.name ??
              'Agent #$agentId';

          // Let's search for customer name in local memory, assignment data, or uploads
          final customerData = assignment['data'] as Map?;
          String customerName =
              customerData?['customer_name']?.toString() ??
              customerData?['name']?.toString() ??
              '';
          if (customerName.isEmpty) {
            customerName = 'Record #$recordId';
            for (var uploadItem in _recentUploads) {
              final match = uploadItem.customers
                  .where((c) => c.id == recordId)
                  .firstOrNull;
              if (match != null) {
                customerName = match.name;
                break;
              }
            }
          }

          queuePayments.add(
            PaymentRecord(
              id: assignment['assignment_id']?.toString() ?? 'TXN_${recordId}',
              customerId: recordId,
              customerName: customerName,
              agentId: agentId,
              agentName: agentName,
              amount: amount,
              paymentMethod: method,
              transactionReference: remarks,
              receiptImagePath: approvedImg.isNotEmpty ? approvedImg : null,
              timestamp:
                  DateTime.tryParse(
                    assignment['updated_at']?.toString() ?? '',
                  ) ??
                  DateTime.tryParse(
                    assignment['schedule_date']?.toString() ?? '',
                  ) ??
                  DateTime.now(),
              status:
                  'Pending', // PENDING status means it shows in the verification queue!
            ),
          );
        }
      }

      _payments = [...queuePayments];
      _approvedTodaySum = tempApprovedSum;
      _rejectedCount = tempRejectedCount;
      _totalAssignmentsCount = tempTotalCount;
      _completedAssignmentsCount = tempCompletedCount;

      List<Customer> assignmentCustomers = [];
      for (var assignment in assignmentsData) {
        try {
          final customer = Customer.fromJson(assignment);
          if (customer.id.isNotEmpty) {
            assignmentCustomers.add(customer);
          }
        } catch (e) {
          debugPrint('Error parsing assignment customer: $e');
        }
      }

      // Merge assignment customers into _customers list
      for (var ac in assignmentCustomers) {
        final existingIndex = _customers.indexWhere((c) => c.id == ac.id);
        if (existingIndex != -1) {
          _customers[existingIndex] = ac;
        } else {
          _customers.add(ac);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching assignments for queue: $e');
    }
  }

  Future<void> fetchAgentAssignments(String agentId) async {
    try {
      final List<Map<String, dynamic>> assignmentsData =
          await _apiService.getAgentAssignments(agentId);

      List<Customer> agentCustomers = [];
      List<PaymentRecord> personalPayments = [];
      double collectedAmount = 0.0;
      double assignedTarget = 0.0;
      int pendingVisits = 0;

      for (var assignment in assignmentsData) {
        final customer = Customer.fromJson(assignment);
        if (customer.id.isNotEmpty) {
          agentCustomers.add(customer);
          assignedTarget += customer.amountDue;
        }

        final amount =
            double.tryParse(
              assignment['payment_collection']?.toString() ?? '',
            ) ??
            0.0;

        if (customer.status == 'Completed' || customer.status == 'Closed') {
          collectedAmount += amount;
        }

        // Pending visit is when status is 'Assigned' or 'Rejected' (not visited or rejected collection)
        if (customer.status == 'Assigned' || customer.status == 'Rejected') {
          pendingVisits++;
        }

        // Parse collection history if a payment is present or case is completed/closed
        if (amount > 0.0 || customer.status == 'Completed' || customer.status == 'Closed') {
          final recordId = assignment['record_id']?.toString() ?? '';
          final agentData = assignment['agent'] as Map?;
          final method = assignment['payment_method']?.toString() ?? 'Cash';
          final remarks =
              assignment['remarks']?.toString() ?? 'Visited customer';
          final approvedImg = assignment['approved_img']?.toString() ?? '';

          String paymentStatus = 'Pending';
          if (customer.status == 'Completed' || customer.status == 'Closed') {
            paymentStatus = customer.status;
          } else if (customer.status == 'Rejected') {
            paymentStatus = 'Rejected';
          }

          final txnId =
              assignment['assignment_id']?.toString() ?? 'TXN_$recordId';

          personalPayments.add(
            PaymentRecord(
              id: txnId,
              customerId: recordId,
              customerName: customer.name,
              agentId: agentId,
              agentName:
                  agentData?['full_name']?.toString() ??
                  _currentUser?.name ??
                  'Agent',
              amount: amount,
              paymentMethod: method,
              transactionReference: remarks,
              receiptImagePath: approvedImg.isNotEmpty ? approvedImg : null,
              timestamp:
                  DateTime.tryParse(
                    assignment['updated_at']?.toString() ?? '',
                  ) ??
                  DateTime.tryParse(
                    assignment['schedule_date']?.toString() ?? '',
                  ) ??
                  DateTime.now(),
              status: paymentStatus,
            ),
          );
        }
      }

      // Merge assignment customers into _customers list
      for (var ac in agentCustomers) {
        final existingIndex = _customers.indexWhere((c) => c.id == ac.id);
        if (existingIndex != -1) {
          _customers[existingIndex] = ac;
        } else {
          _customers.add(ac);
        }
      }

      // Merge personal payments into _payments list
      for (var p in personalPayments) {
        final existingIndex = _payments.indexWhere((pm) => pm.id == p.id);
        if (existingIndex != -1) {
          _payments[existingIndex] = p;
        } else {
          _payments.insert(0, p);
        }
      }

      // Update active user statistics
      if (_currentUser != null && _currentUser!.id == agentId) {
        _currentUser = _currentUser!.copyWith(
          casesCount: agentCustomers.length,
          pendingVisitsCount: pendingVisits,
          collectedAmount: collectedAmount,
          assignedTarget: assignedTarget,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching agent assignments: $e');
      rethrow;
    }
  }
}
