import 'dart:typed_data';
import 'dart:collection';
import 'package:excel/excel.dart';
import '../config/field_mapping.dart';

class ParsedRecordsList extends ListBase<Map<String, dynamic>> {
  final List<Map<String, dynamic>> _innerList;
  final int totalRows;
  final int skippedRows;

  ParsedRecordsList(
    this._innerList, {
    required this.totalRows,
    required this.skippedRows,
  });

  @override
  int get length => _innerList.length;

  @override
  set length(int newLength) {
    _innerList.length = newLength;
  }

  @override
  Map<String, dynamic> operator [](int index) => _innerList[index];

  @override
  void operator []=(int index, Map<String, dynamic> value) {
    _innerList[index] = value;
  }

  @override
  void add(Map<String, dynamic> element) => _innerList.add(element);

  @override
  void addAll(Iterable<Map<String, dynamic>> iterable) =>
      _innerList.addAll(iterable);
}

List<Map<String, dynamic>> parseExcelSync(Uint8List bytes) {
  var excel = Excel.decodeBytes(bytes);
  final List<Map<String, dynamic>> parsedRecords = [];
  int totalRows = 0;
  int skippedRows = 0;

  if (excel.tables.isNotEmpty) {
    final String firstSheetName = excel.tables.keys.first;
    final sheet = excel.tables[firstSheetName];
    if (sheet != null) {
      final rows = sheet.rows;
      totalRows = rows.length;

      if (rows.isNotEmpty) {
        final headerRow = rows.first;
        List<String> headers = [];
        for (final cell in headerRow) {
          headers.add(cell?.value?.toString() ?? '');
        }

        for (int i = 1; i < totalRows; i++) {
          final row = rows[i];
          Map<String, dynamic> record = {};
          for (int j = 0; j < headers.length; j++) {
            final cell = j < row.length ? row[j] : null;
            final val = cell?.value;
            final header = headers[j];
            final mappedKey = ExcelFieldMapping.mapHeader(header);
            if (mappedKey != null) {
              record[mappedKey] = val?.toString() ?? '';
            } else {
              record[header] = val?.toString() ?? '';
            }
          }

          final name = ExcelFieldMapping.getMappedValue(record, 'name') ?? '';
          if (name.trim().isNotEmpty) {
            double amountDue = 0.0;
            final rawAmount =
                ExcelFieldMapping.getMappedValue(record, 'amountDue') ?? '';
            if (rawAmount.isNotEmpty) {
              amountDue = double.tryParse(rawAmount.replaceAll(',', '')) ?? 0.0;
            }

            int overdueDays = 10;
            final rawOverdue =
                ExcelFieldMapping.getMappedValue(record, 'overdueDays') ?? '';
            if (rawOverdue.isNotEmpty) {
              overdueDays = int.tryParse(rawOverdue) ?? 10;
            }

            final address =
                ExcelFieldMapping.getMappedValue(record, 'address') ??
                'No Address';
            final phone =
                ExcelFieldMapping.getMappedValue(record, 'phone') ??
                '+91 99999 99999';
            final priority =
                ExcelFieldMapping.getMappedValue(record, 'priority') ??
                'MEDIUM';
            final assetModel =
                ExcelFieldMapping.getMappedValue(record, 'assetModel') ?? '';
            final assetRegNo =
                ExcelFieldMapping.getMappedValue(record, 'assetRegNo') ?? '';
            final engineNumber =
                ExcelFieldMapping.getMappedValue(record, 'engineNumber') ?? '';
            final chasisNumber =
                ExcelFieldMapping.getMappedValue(record, 'chasisNumber') ?? '';
            final assetVariant =
                ExcelFieldMapping.getMappedValue(record, 'assetVariant') ?? '';

            parsedRecords.add({
              'name': name.trim(),
              'amountDue': amountDue,
              'overdueDays': overdueDays,
              'address': address.trim(),
              'phone': phone.trim(),
              'priority':
                  (priority.toUpperCase() == 'HIGH' ||
                      priority.toUpperCase() == 'LOW')
                  ? priority.toUpperCase()
                  : 'MEDIUM',
              'assetModel': assetModel,
              'assetRegNo': assetRegNo,
              'engineNumber': engineNumber,
              'chasisNumber': chasisNumber,
              'assetVariant': assetVariant,
            });
          } else {
            skippedRows++;
          }
        }
      }
    }
  }
  return ParsedRecordsList(
    parsedRecords,
    totalRows: totalRows,
    skippedRows: skippedRows,
  );
}
