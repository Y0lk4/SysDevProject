import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ExcelExport {
  static Future<void> exportReport(Map<String, dynamic> data, String date, {bool comparison = false}) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      if (comparison) {
        _buildComparisonSheet(sheet, data, date);
      } else {
        _buildSingleReportSheet(sheet, data, date);
      }

      excel.setDefaultSheet('Sheet1');
      final bytes = excel.save();
      if (bytes == null) throw Exception('Failed to save Excel file');

      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/report_$date.xlsx');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      print('Error exporting to Excel: $e');
      rethrow;
    }
  }

  static void _setCell(Sheet sheet, int row, int col, String value, {bool bold = false, String? bgColor}) {
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    if (bold || bgColor != null) {
      cell.cellStyle = CellStyle(
        bold: bold,
        backgroundColorHex: bgColor != null ? ExcelColor.fromHexString(bgColor) : ExcelColor.none,
      );
    }
  }

  static void _setNumberCell(Sheet sheet, int row, int col, num value) {
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = DoubleCellValue(value.toDouble());
    cell.cellStyle = CellStyle(
      numberFormat: CustomNumericNumFormat(formatCode: r'"$"#,##0.00'),
    );
  }

  static void _setIntCell(Sheet sheet, int row, int col, int value) {
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = IntCellValue(value);
  }

  static void _buildSingleReportSheet(Sheet sheet, Map<String, dynamic> data, String date) {
    try {
      final List<String> headers = [
        'Date', 'Cash', 'Tips', 'Sales Tax', 'Transactions', 'Net Sales', 'Gross Sales'
      ];

      for (int i = 0; i < headers.length; i++) {
        _setCell(sheet, 0, i, headers[i], bold: true, bgColor: '#E2E8F0');
      }

      _setCell(sheet, 1, 0, date);
      _setNumberCell(sheet, 1, 1, data['cash'] ?? 0.0);
      _setNumberCell(sheet, 1, 2, data['tips'] ?? 0.0);
      _setNumberCell(sheet, 1, 3, data['salesTax'] ?? 0.0);
      _setIntCell(sheet, 1, 4, (data['transactions'] ?? 0).toInt());
      _setNumberCell(sheet, 1, 5, data['netSales'] ?? 0.0);
      _setNumberCell(sheet, 1, 6, data['grossSales'] ?? 0.0);

      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }
    } catch (e) {
      print('Error building single report sheet: $e');
      _setCell(sheet, 0, 0, 'Error: $e');
    }
  }

  static void _buildComparisonSheet(Sheet sheet, Map<String, dynamic> data, String date) {
    try {
      final report1 = data['report1'] as Map<String, dynamic>?;
      final report2 = data['report2'] as Map<String, dynamic>?;

      if (report1 == null || report2 == null) {
        _setCell(sheet, 0, 0, 'Error: Missing report data');
        return;
      }

      final String d1Label = data['date1'] ?? 'Date 1';
      final String d2Label = data['date2'] ?? 'Date 2';

      num val(Map<String, dynamic> r, String key) =>
          r[key] is num ? r[key] : (num.tryParse(r[key].toString()) ?? 0);

      final fields = [
        {'key': 'cash', 'label': 'Cash'},
        {'key': 'tips', 'label': 'Tips'},
        {'key': 'salesTax', 'label': 'Sales Tax'},
        {'key': 'transactions', 'label': 'Transactions'},
        {'key': 'netSales', 'label': 'Net Sales'},
        {'key': 'grossSales', 'label': 'Gross Sales'},
      ];

      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
          customValue: TextCellValue('Sales Comparison Report'));
      var titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      titleCell.cellStyle = CellStyle(bold: true);

      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1),
          customValue: TextCellValue('Comparing: $d1Label vs $d2Label'));

      _setCell(sheet, 3, 0, 'Field', bold: true, bgColor: '#E2E8F0');
      _setCell(sheet, 3, 1, 'Date 1', bold: true, bgColor: '#E2E8F0');
      _setCell(sheet, 3, 2, 'Date 2', bold: true, bgColor: '#E2E8F0');
      _setCell(sheet, 3, 3, 'Diff (%)', bold: true, bgColor: '#E2E8F0');

      for (int i = 0; i < fields.length; i++) {
        final f = fields[i];
        final v1 = val(report1, f['key']!);
        final v2 = val(report2, f['key']!);
        final diff = v2 - v1;
        final pct = v1 != 0 ? (diff / v1 * 100) : 0.0;
        bool isCurrency = f['key'] != 'transactions';
        int row = 4 + i;

        _setCell(sheet, row, 0, f['label']!);
        if (isCurrency) {
          _setNumberCell(sheet, row, 1, v1);
          _setNumberCell(sheet, row, 2, v2);
        } else {
          _setIntCell(sheet, row, 1, v1.toInt());
          _setIntCell(sheet, row, 2, v2.toInt());
        }
        _setCell(sheet, row, 3, '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%');
      }

      int totalRow = 4 + fields.length;
      _setCell(sheet, totalRow, 0, 'TOTAL GROSS', bold: true, bgColor: '#E30613');
      _setNumberCell(sheet, totalRow, 1, val(report1, 'grossSales'));
      _setNumberCell(sheet, totalRow, 2, val(report2, 'grossSales'));

      final totalDiff = val(report2, 'grossSales') - val(report1, 'grossSales');
      var totalDiffCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRow));
      totalDiffCell.value = DoubleCellValue(totalDiff.toDouble());
      totalDiffCell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E30613'),
        numberFormat: CustomNumericNumFormat(formatCode: r'"$"#,##0.00'),
      );

      for (int i = 0; i < 4; i++) {
        sheet.setColumnAutoFit(i);
      }
    } catch (e) {
      print('Error building comparison sheet: $e');
      _setCell(sheet, 0, 0, 'Error: $e');
    }
  }
}
