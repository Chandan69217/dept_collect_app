import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../models/customer.dart';
import '../models/payment_record.dart';
import '../models/notification.dart';

class DatabaseService extends ChangeNotifier {
  // Singleton Pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    _initializeData();
  }

  // App Auth State
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String _currentRole = 'AGENT'; // 'AGENT' or 'ADMIN'
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
    // 1. Initialize Agents
    _agents = [
      const Agent(
        id: 'miller',
        name: 'Agent Miller',
        avatarUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
        zone: 'Mumbai Metro Area',
        assignedTarget: 12450.0,
        collectedAmount: 10209.0, // 82% of target met
        casesCount: 14,
        pendingVisitsCount: 6,
        isAdmin: false,
        isOnline: true,
      ),
      const Agent(
        id: 'rahul',
        name: 'Agent Rahul',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        zone: 'Mumbai South',
        assignedTarget: 15000.0,
        collectedAmount: 12500.0,
        casesCount: 18,
        pendingVisitsCount: 8,
        isAdmin: false,
        isOnline: true,
      ),
      const Agent(
        id: 'priya',
        name: 'Agent Priya',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        zone: 'Mumbai West',
        assignedTarget: 18000.0,
        collectedAmount: 8500.0,
        casesCount: 16,
        pendingVisitsCount: 9,
        isAdmin: false,
        isOnline: true,
      ),
      const Agent(
        id: 'vance',
        name: 'Alexander Vance',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDBRx9r1cR-RQb8YjXwlBrDNww_q6yPcvL1U55Qh2Yl9AppZD8M1pD6LFz9X8hOAC5DaSNf1I-LLbjynUbailf1POhaR5Du84ro-go9UPHhTm0MvD_mN-WQE_A3VY7mc9gq2oJD4EJ-suFIO7f9iUy3gt4omfLfilmFyVOyOfqWu5cqtCG0we8amXFCaT9bkbl_tBlmKBdkeM8IZ2nIM3qXDMC0Sqksb66gR_uhYPHucAk80p-8hQXaB3KOT1Rr_IjfdqTwdJ1hjAxe',
        zone: 'All Zones',
        assignedTarget: 0.0,
        collectedAmount: 0.0,
        casesCount: 0,
        pendingVisitsCount: 0,
        isAdmin: true,
        isOnline: true,
      )
    ];

    // Default current user to Agent Miller
    _currentUser = _agents[0];

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
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        lat: 19.0760,
        lng: 72.8777,
        assignedAgentId: 'miller',
        status: 'OVERDUE',
        notes: ['Customer was busy during last visit.', 'Needs verification of UPI transaction.'],
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
        avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
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
        avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
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
        avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
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
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
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
      }
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
        body: 'You are at 82% of your daily collection target. ₹2,241 remaining.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        type: 'alert',
      )
    ];
  }

  // Auth Operations
  bool login(String username, String password) {
    if (username.toLowerCase().contains('admin') || password.toLowerCase().contains('admin')) {
      _currentRole = 'ADMIN';
      _currentUser = _agents.firstWhere((a) => a.isAdmin);
    } else {
      _currentRole = 'AGENT';
      // Find matching agent or default to Miller
      _currentUser = _agents.firstWhere((a) => a.id == 'miller', orElse: () => _agents[0]);
    }
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  void switchPortal(String role) {
    _currentRole = role;
    if (role == 'ADMIN') {
      _currentUser = _agents.firstWhere((a) => a.isAdmin, orElse: () => _agents[3]);
    } else {
      _currentUser = _agents.firstWhere((a) => a.id == 'miller', orElse: () => _agents[0]);
    }
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
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
    final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

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
      status: 'PENDING',
    );

    _payments.insert(0, newPayment);

    // Update customer status to pending verification
    _customers = _customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(status: 'PENDING_VERIFICATION');
      }
      return c;
    }).toList();

    // Decrease the agent pending visits count
    if (_currentUser != null && !_currentUser!.isAdmin) {
      _agents = _agents.map((a) {
        if (a.id == _currentUser!.id) {
          return a.copyWith(
            pendingVisitsCount: a.pendingVisitsCount > 0 ? a.pendingVisitsCount - 1 : 0,
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
      'subtitle': '${_currentUser?.name} • ₹$amount pending approval for ${customer.name}',
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
    _payments[recordIndex] = record.copyWith(status: 'APPROVED');

    // Update customer status to PAID and clear due amount
    _customers = _customers.map((c) {
      if (c.id == record.customerId) {
        return c.copyWith(
          status: 'PAID',
          amountDue: c.amountDue - record.amount >= 0 ? c.amountDue - record.amount : 0,
        );
      }
      return c;
    }).toList();

    // Credit agent targets
    _agents = _agents.map((a) {
      if (a.id == record.agentId) {
        return a.copyWith(
          collectedAmount: a.collectedAmount + record.amount,
        );
      }
      return a;
    }).toList();

    // If active user is the approved agent, update current profile too
    if (_currentUser != null && _currentUser!.id == record.agentId) {
      _currentUser = _agents.firstWhere((a) => a.id == record.agentId);
    }

    // Push Notification to the specific Agent
    _notifications.insert(0, AppNotification(
      id: 'not_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Collection Verified',
      body: 'Your collection of ₹${record.amount} for ${record.customerName} has been approved by admin.',
      timestamp: DateTime.now(),
      type: 'approval',
    ));

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
    _payments[recordIndex] = record.copyWith(status: 'REJECTED');

    // Update customer status back to OVERDUE
    _customers = _customers.map((c) {
      if (c.id == record.customerId) {
        return c.copyWith(status: 'OVERDUE');
      }
      return c;
    }).toList();

    // Notify agent
    _notifications.insert(0, AppNotification(
      id: 'not_rej_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Collection Rejected',
      body: 'Your collection of ₹${record.amount} for ${record.customerName} was rejected. Please verify details.',
      timestamp: DateTime.now(),
      type: 'alert',
    ));

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
        updatedNotes.add('Scheduled follow-up visit for ${date.day}/${date.month}/${date.year}.');
        return c.copyWith(
          scheduledVisit: date,
          notes: updatedNotes,
        );
      }
      return c;
    }).toList();

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
        return a.copyWith(
          casesCount: a.casesCount > 0 ? a.casesCount - 1 : 0,
        );
      }
      if (a.id == newAgentId) {
        return a.copyWith(
          casesCount: a.casesCount + 1,
        );
      }
      return a;
    }).toList();

    if (_currentUser != null) {
      _currentUser = _agents.firstWhere((a) => a.id == _currentUser!.id, orElse: () => _currentUser!);
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

  // CSV Data upload simulation
  void uploadBankRecords(List<Map<String, dynamic>> records) {
    int addedCount = 0;
    for (var r in records) {
      final id = 'cust_csv_${DateTime.now().millisecondsSinceEpoch}_$addedCount';
      final newCust = Customer(
        id: id,
        name: r['name'] ?? 'Unknown debtor',
        amountDue: (r['amountDue'] as num?)?.toDouble() ?? 0.0,
        dueDate: DateTime.now().subtract(Duration(days: r['overdueDays'] as int? ?? 10)),
        overdueDays: r['overdueDays'] as int? ?? 10,
        address: r['address'] ?? 'No address provided',
        phone: r['phone'] ?? '+91 99999 99999',
        priority: r['priority'] ?? 'MEDIUM',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        lat: 19.0760 + (addedCount * 0.01),
        lng: 72.8777 + (addedCount * 0.01),
        assignedAgentId: 'miller', // auto assign to miller for test
        status: 'OVERDUE',
      );
      _customers.add(newCust);
      addedCount++;
    }

    // Update Agent Miller's casesCount
    _agents = _agents.map((a) {
      if (a.id == 'miller') {
        return a.copyWith(
          casesCount: a.casesCount + addedCount,
        );
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
      return n.copyWith(isRead: true);
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
  void toggleAgentOnlineStatus(String agentId, bool isOnline) {
    _agents = _agents.map((a) {
      if (a.id == agentId) {
        return a.copyWith(isOnline: isOnline);
      }
      return a;
    }).toList();
    
    if (_currentUser?.id == agentId) {
      _currentUser = _agents.firstWhere((a) => a.id == agentId);
    }
    
    // Log in activity feed
    _activityFeed.insert(0, {
      'id': 'act_status_${agentId}_${DateTime.now().millisecondsSinceEpoch}',
      'title': isOnline ? 'Agent Online' : 'Agent Offline',
      'subtitle': 'Agent ID #${agentId.toUpperCase()} is now ${isOnline ? 'Online' : 'Offline'}',
      'time': 'Just now',
      'type': isOnline ? 'login' : 'warning',
    });
    
    notifyListeners();
  }
}
