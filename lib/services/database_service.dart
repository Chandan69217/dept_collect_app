import 'dart:developer';

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
    _customers = [
      Customer(
        id: 'cust_robert',
        name: 'Robert Henderson',
        amountDue: 12450.0,
        dueDate: DateTime.now().subtract(const Duration(days: 45)),
        overdueDays: 45,
        address: '422 Oakwood Avenue, Suite 400, Mumbai',
        phone: '+91 98765 43210',
        priority: 'HIGH',
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        lat: 19.0760,
        lng: 72.8777,
        assignedAgentId: 'miller',
        status: 'OVERDUE',
        notes: [
          'Customer was busy during last visit.',
          'Needs verification of UPI transaction.',
        ],
      ),
      Customer(
        id: 'cust_jenkins',
        name: 'Sarah Jenkins',
        amountDue: 1800.0,
        dueDate: DateTime.now().subtract(const Duration(days: 12)),
        overdueDays: 12,
        address: '102 Skyline Apartments, Bandra West, Mumbai',
        phone: '+91 98123 45678',
        priority: 'MEDIUM',
        avatarUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        lat: 19.0596,
        lng: 72.8295,
        assignedAgentId: 'miller',
        status: 'OVERDUE',
        notes: ['Agreed to pay on next visit.'],
      ),
      Customer(
        id: 'cust_david',
        name: 'David Miller',
        amountDue: 3500.0,
        dueDate: DateTime.now().subtract(const Duration(days: 30)),
        overdueDays: 30,
        address: '58 Orchard Road, Andheri East, Mumbai',
        phone: '+91 97654 32109',
        priority: 'HIGH',
        avatarUrl:
            'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
        lat: 19.1136,
        lng: 72.8697,
        assignedAgentId: 'miller',
        status: 'OVERDUE',
      ),
      Customer(
        id: 'cust_amit',
        name: 'Amit Sharma',
        amountDue: 12500.0,
        dueDate: DateTime.now().subtract(const Duration(days: 60)),
        overdueDays: 60,
        address: '702 Sea Green Complex, Worli, Mumbai',
        phone: '+91 99999 88888',
        priority: 'HIGH',
        avatarUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
        lat: 19.0178,
        lng: 72.8174,
        assignedAgentId: 'rahul',
        status: 'PAID',
      ),
      Customer(
        id: 'cust_priya_p',
        name: 'Priya Patel',
        amountDue: 8200.0,
        dueDate: DateTime.now().subtract(const Duration(days: 15)),
        overdueDays: 15,
        address: 'Tower 4, Apex Heights, Powai, Mumbai',
        phone: '+91 98888 77777',
        priority: 'MEDIUM',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        lat: 19.1176,
        lng: 72.9060,
        assignedAgentId: 'priya',
        status: 'PENDING_VERIFICATION',
      ),
    ];

    // 3. Initialize Payments (Verification requests)
    _payments = [
      PaymentRecord(
        id: 'TXN9881A',
        customerId: 'cust_priya_p',
        customerName: 'Priya Patel',
        agentId: 'priya',
        agentName: 'Agent Priya',
        amount: 8200.0,
        paymentMethod: 'UPI',
        transactionReference: 'UPI88921820',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'PENDING',
      ),
      PaymentRecord(
        id: 'TXN1120B',
        customerId: 'cust_amit',
        customerName: 'Amit Sharma',
        agentId: 'rahul',
        agentName: 'Agent Rahul',
        amount: 12500.0,
        paymentMethod: 'Cash',
        transactionReference: 'CASH-AMIT-Worli',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'APPROVED',
      ),
      PaymentRecord(
        id: 'TXN7701M',
        customerId: 'cust_robert',
        customerName: 'Robert Henderson',
        agentId: 'miller',
        agentName: 'Agent Miller',
        amount: 4500.0,
        paymentMethod: 'UPI',
        transactionReference: 'UPI-ROB-Today',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'PENDING',
      ),
      PaymentRecord(
        id: 'TXN5502M',
        customerId: 'cust_jenkins',
        customerName: 'Sarah Jenkins',
        agentId: 'miller',
        agentName: 'Agent Miller',
        amount: 8000.0,
        paymentMethod: 'Cash',
        transactionReference: 'CASH-SARAH-Yest',
        timestamp: DateTime.now().subtract(const Duration(hours: 26)),
        status: 'APPROVED',
      ),
      PaymentRecord(
        id: 'TXN3303M',
        customerId: 'cust_david',
        customerName: 'David Miller',
        agentId: 'miller',
        agentName: 'Agent Miller',
        amount: 12450.0,
        paymentMethod: 'Cheque',
        transactionReference: 'CHQ-DAVID-Prev',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        status: 'APPROVED',
      ),
    ];

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
  void recordPayment({
    required String customerId,
    required double amount,
    required String method,
    required String reference,
    String? receiptPath,
  }) {
    final customer = _customers.firstWhere((c) => c.id == customerId);
    final txnId =
        'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

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
      _currentUser = _agents.firstWhere((a) => a.id == _currentUser!.id);
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
  void approvePayment(String recordId) {
    final recordIndex = _payments.indexWhere((p) => p.id == recordId);
    if (recordIndex == -1) return;

    final record = _payments[recordIndex];

    // Update record status to APPROVED
    _payments[recordIndex] = record.copyWith(
      status: AppConstants.statusApproved,
    );

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

    notifyListeners();
  }

  // Admin Rejecting Collection
  void rejectPayment(String recordId) {
    final recordIndex = _payments.indexWhere((p) => p.id == recordId);
    if (recordIndex == -1) return;

    final record = _payments[recordIndex];

    // Update record status to REJECTED
    _payments[recordIndex] = record.copyWith(
      status: AppConstants.statusRejected,
    );

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

    notifyListeners();
  }

  // Follow-up Scheduling
  void scheduleFollowUp(String customerId, DateTime date) {
    _customers = _customers.map((c) {
      if (c.id == customerId) {
        final List<String> updatedNotes = List.from(c.notes);
        updatedNotes.add(
          'Scheduled follow-up visit for ${date.day}/${date.month}/${date.year}.',
        );
        return c.copyWith(scheduledVisit: date, notes: updatedNotes);
      }
      return c;
    }).toList();

    final customer = _customers.firstWhere((c) => c.id == customerId);
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
  void assignCase(String customerId, String newAgentId) {
    final oldCustomer = _customers.firstWhere((c) => c.id == customerId);
    final oldAgentId = oldCustomer.assignedAgentId;

    _customers = _customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(assignedAgentId: newAgentId);
      }
      return c;
    }).toList();

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

    final newAgentName = _agents.firstWhere((a) => a.id == newAgentId).name;

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

  // Case Priority Operation (Admin)
  void updateCasePriority(String customerId, String newPriority) {
    _customers = _customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(priority: newPriority.toUpperCase());
      }
      return c;
    }).toList();

    notifyListeners();
  }

  // Case Delete Operation (Admin)
  void deleteCase(String customerId) {
    final customer = _customers.where((c) => c.id == customerId).firstOrNull;
    if (customer == null) return;

    // Remove from active list
    _customers.removeWhere((c) => c.id == customerId);

    // Adjust agent case count if assigned
    if (customer.assignedAgentId.isNotEmpty &&
        customer.assignedAgentId != 'unassigned') {
      _agents = _agents.map((a) {
        if (a.id == customer.assignedAgentId) {
          return a.copyWith(
            casesCount: a.casesCount > 0 ? a.casesCount - 1 : 0,
          );
        }
        return a;
      }).toList();
    }

    // Log update in activity feed
    _activityFeed.insert(0, {
      'id': 'act_delete_${customerId}_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Case Deleted',
      'subtitle': 'Admin deleted portfolio record for ${customer.name}',
      'time': 'Just now',
      'type': 'error',
    });

    notifyListeners();
  }

  // Bulk Case Delete Operation (Admin)
  void deleteMultipleCases(List<String> customerIds) {
    for (var id in customerIds) {
      final customer = _customers.where((c) => c.id == id).firstOrNull;
      if (customer == null) continue;

      // Adjust agent case count if assigned
      if (customer.assignedAgentId.isNotEmpty &&
          customer.assignedAgentId != 'unassigned') {
        _agents = _agents.map((a) {
          if (a.id == customer.assignedAgentId) {
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
  }

  // CSV Data upload simulation
  Future<void> uploadBankRecords(
    String fileName,
    List<Map<String, dynamic>> records,
  ) async {
    // First save the data into the api
    await _apiService.uploadRecords(fileName, records);
    await fetchRecentUploads();
    int addedCount = 0;
    for (var r in records) {
      final id =
          'cust_csv_${DateTime.now().millisecondsSinceEpoch}_$addedCount';
      final newCust = Customer(
        id: id,
        name: r['name'] ?? '',
        amountDue: (r['amountDue'] as num?)?.toDouble() ?? 0.0,
        dueDate: DateTime.now().subtract(
          Duration(days: r['overdueDays'] as int? ?? 10),
        ),
        overdueDays: r['overdueDays'] as int? ?? 0,
        address: r['address'] ?? '',
        phone: r['phone'] ?? '',
        priority: r['priority'] ?? 'MEDIUM',
        avatarUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        lat: 19.0760 + (addedCount * 0.01),
        lng: 72.8777 + (addedCount * 0.01),
        assignedAgentId: 'miller', // auto assign to miller for test
        status: 'OVERDUE',
        assetModel: r['assetModel'] ?? '',
        assetRegNo: r['assetRegNo'] ?? '',
        engineNumber: r['engineNumber'] ?? '',
        chasisNumber: r['chasisNumber'] ?? '',
        assetVariant: r['assetVariant'] ?? '',
        showLoanId: r['showLoanId'] ?? true,
      );
      _customers.add(newCust);
      addedCount++;
    }

    // Update Agent Miller's casesCount
    _agents = _agents.map((a) {
      if (a.id == 'miller') {
        return a.copyWith(casesCount: a.casesCount + addedCount);
      }
      return a;
    }).toList();

    if (_currentUser != null && _currentUser!.id == 'miller') {
      _currentUser = _agents.firstWhere((a) => a.id == 'miller');
    }

    // Add activity feed
    _activityFeed.insert(0, {
      'id': 'act_csv_upload',
      'title': 'CSV Data Imported',
      'subtitle': '$addedCount records successfully parsed and assigned.',
      'time': 'Just now',
      'type': 'success',
    });

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

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint(
        'Error fetching recent uploads files: $e , StackTrace: ${stackTrace}',
      );
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
}
