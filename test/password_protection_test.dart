import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:protect/protect.dart';
import 'package:dept_collection_app/services/shared_prefs_service.dart';
import 'package:dept_collection_app/services/database_service.dart';
import 'package:dept_collection_app/services/file_decryption_service.dart';

class MockFileDecryptionService extends FileDecryptionService {
  MockFileDecryptionService() : super.internal();

  @override
  Future<ProtectResponse> FileDecryptionService(
    Uint8List bytes,
    String password,
  ) async {
    if (password.trim() == 'password') {
      final excelBytes = _getMockExcelBytes();
      return ProtectResponse(isDataValid: true, processedBytes: excelBytes);
    } else {
      return const ProtectResponse(isDataValid: false);
    }
  }

  Uint8List _getMockExcelBytes() {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    // Add headers
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Amount'),
      TextCellValue('Overdue Days'),
      TextCellValue('Phone'),
      TextCellValue('Address'),
      TextCellValue('Priority'),
      TextCellValue('Reg No'),
    ]);

    // Add records
    sheet.appendRow([
      TextCellValue('Decrypted Customer A'),
      TextCellValue('45000'),
      TextCellValue('22'),
      TextCellValue('+91 99999 11111'),
      TextCellValue('Ashok Rajpath, Patna'),
      TextCellValue('HIGH'),
      TextCellValue('BR 01 JM3069'),
    ]);

    return Uint8List.fromList(excel.encode() ?? []);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService Password Protected File Tests', () {
    late DatabaseService db;
    // OLE Compound File Header
    final encryptedHeaderBytes = Uint8List.fromList([
      208,
      207,
      17,
      224,
      161,
      177,
      26,
      225,
      1,
      2,
      3,
      4,
    ]);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPrefsService.init();
      FileDecryptionService.setMockInstance(MockFileDecryptionService());
      db = DatabaseService();
      db.resetParsedData();
    });

    test(
      'Should prompt for password when OLE Compound File header is detected',
      () async {
        db.startParsingExcel(
          fileName: 'encrypted.xlsx',
          bytes: encryptedHeaderBytes,
        );

        // Verify that parsing is paused and password required is true
        expect(db.isParsing, isFalse);
        expect(db.isPasswordProtectedFile, isTrue);
        expect(db.pendingBytesToDecrypt, equals(encryptedHeaderBytes));
        expect(db.pendingFileNameToDecrypt, equals('encrypted.xlsx'));
        expect(db.passwordError, isNull);
      },
    );

    test(
      'Should set passwordError when incorrect password is provided',
      () async {
        db.startParsingExcel(
          fileName: 'encrypted.xlsx',
          bytes: encryptedHeaderBytes,
        );

        expect(db.isPasswordProtectedFile, isTrue);

        // Submit incorrect password
        db.startParsingExcel(
          fileName: 'encrypted.xlsx',
          bytes: db.pendingBytesToDecrypt,
          password: 'wrong_password',
        );

        // Give it a brief delay since startParsingExcel runs async tasks/delays
        await Future.delayed(const Duration(milliseconds: 1500));

        expect(db.isParsing, isFalse);
        expect(db.isPasswordProtectedFile, isTrue);
        expect(db.passwordError, equals('password incorrect'));
      },
    );

    test(
      'Should complete password verification when correct password is provided',
      () async {
        db.startParsingExcel(
          fileName: 'encrypted.xlsx',
          bytes: encryptedHeaderBytes,
        );

        expect(db.isPasswordProtectedFile, isTrue);

        // Submit correct password
        db.startParsingExcel(
          fileName: 'encrypted.xlsx',
          bytes: db.pendingBytesToDecrypt,
          password: 'password',
        );

        // Wait for delay
        await Future.delayed(const Duration(milliseconds: 1500));

        expect(db.passwordError, isNull);
        expect(db.isPasswordProtectedFile, isFalse);
      },
    );
  });
}
