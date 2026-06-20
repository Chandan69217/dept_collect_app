import 'package:intl/intl.dart';

class AppConstants {
  // Roles
  static const String roleAdmin = 'ADMIN';
  static const String roleAgent = 'AGENT';

  // API Role keys
  static const String apiRoleAdmin = 'admin';
  static const String apiRoleAgent = 'agent';

  // Statuses
  static const String statusActive = 'active';
  static const String statusInActive = 'inactive';

  // Customer Priorities
  static const String priorityHigh = 'HIGH';
  static const String priorityMedium = 'MEDIUM';
  static const String priorityLow = 'LOW';

  // Customer / Payment Statuses
  static const String statusOverdue = 'Assigned';
  static const String statusPaid = 'Completed';
  static const String statusPendingVerification = 'Pending';
  static const String statusPending = 'Pending';
  static const String statusApproved = 'Completed';
  static const String statusRejected = 'Rejected';
  static const String statusClosed = 'Closed';

  // DateFormater

  static final DateFormat dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  // Validation Regex Expressions
  static final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9_+&*-]+(?:\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,7}$",
  );
  static final RegExp mobileRegex = RegExp(r"^(?:\+?\d{1,3}[- ]?)?[0-9]{10}$");
  static final RegExp passwordRegex = RegExp(r"^.{6,}$");
}
