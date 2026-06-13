class ExcelFieldMapping {
  // Global mapping variable that user can modify
  static Map<String, List<String>> mapping = {
    'name': [
      'customer_name',
      'customer name',
      'customer',
      'name',
      'debtor name',
      'debtor',
      'client',
      'client name',
      'CUSTOMER_NAME',
      'CUSTOMER NAME',
      'DEBTOR NAME',
    ],
    'assetRegNo': [
      'registrationnumber',
      'registration number',
      'reg no',
      'registration no',
      'reg number',
      'registration_number',
      'regn no',
      'regno',
      'REGISTRATION_NUMBER',
      'RegistrationNumber',
      'RegNo',
      'Reg No',
      'asset reg no',
      'asset_reg_no',
    ],
    'engineNumber': [
      'enginenumber',
      'engine number',
      'engine no',
      'engine_number',
      'engineno',
      'ENGINE_NUMBER',
      'EngineNumber',
      'EngineNo',
      'Engine No',
    ],
    'chasisNumber': [
      'chasisnumber',
      'chasis number',
      'chassis number',
      'chasis no',
      'chassis no',
      'chasis_number',
      'chassis_number',
      'CHASIS_NUMBER',
      'CHASSIS_NUMBER',
      'ChasisNumber',
      'ChassisNumber',
    ],
    'assetVariant': [
      'assetvariant',
      'asset variant',
      'variant',
      'asset_variant',
      'ASSET_VARIANT',
      'AssetVariant',
      'Variant',
    ],
    'assetModel': [
      'assetmodel',
      'asset model',
      'model',
      'asset_model',
      'ASSET_MODEL',
      'AssetModel',
      'Model',
    ],
    'amountDue': [
      'amountdue',
      'amount due',
      'amount',
      'balance',
      'due amount',
      'due_amount',
      'AMOUNT_DUE',
      'AmountDue',
      'Amount',
    ],
    'overdueDays': [
      'overduedays',
      'overdue days',
      'overdue_days',
      'days overdue',
      'days',
      'OVERDUE_DAYS',
      'OverdueDays',
      'Overdue Days',
    ],
    'address': [
      'address',
      'location',
      'residence',
      'customer address',
      'debtor address',
      'ADDRESS',
      'Address',
    ],
    'phone': [
      'phone',
      'mobile',
      'contact',
      'phone number',
      'mobile number',
      'contact number',
      'PHONE',
      'Phone',
      'Mobile',
      'Mobile No',
    ],
    'priority': [
      'priority',
      'priority level',
      'class',
      'segment',
      'PRIORITY',
      'Priority',
    ],
  };

  /// Given a header name from Excel, find the mapped common field key.
  /// Returns null if not mapped.
  static String? mapHeader(String header) {
    final cleanHeader = header.trim().toLowerCase();
    for (var entry in mapping.entries) {
      final key = entry.key;
      final synonyms = entry.value;
      if (key.toLowerCase() == cleanHeader) {
        return key;
      }
      for (var synonym in synonyms) {
        if (synonym.toLowerCase() == cleanHeader) {
          return key;
        }
      }
    }
    return null;
  }
}
