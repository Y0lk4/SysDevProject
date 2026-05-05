import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ExcelExport {
  static Future<void> exportReport(Map<String, dynamic> data, String date) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    final List<String> categories = [
      'Date',
      'Tips',
      'Sales Tax',
      'Transactions',
      'Net Sales',
      'Gross Sales'
    ];

    for (int i = 0; i < categories.length; i++) {
      Range headerCell = sheet.getRangeByIndex(1, i+1);
      headerCell.setText(categories[i]);
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.backColor = '#E2E8F0';
      headerCell.cellStyle.hAlign = HAlignType.center;
    }

    sheet.getRangeByIndex(2, 1).setText(date);
    sheet.getRangeByIndex(2, 2).setNumber((data['tips'] ?? 0.0).toDouble());
    sheet.getRangeByIndex(2, 3).setNumber((data['salesTax'] ?? 0.0).toDouble());
    sheet.getRangeByIndex(2, 4).setNumber((data['transactions'] ?? 0).toDouble());
    sheet.getRangeByIndex(2, 5).setNumber((data['netSales'] ?? 0.0).toDouble());
    sheet.getRangeByIndex(2, 6).setNumber((data['grossSales'] ?? 0.0).toDouble());

    //format the currency
    final String currencyFormat = r'$#,##0.00';
    sheet.getRangeByIndex(2, 2).numberFormat = currencyFormat;
    sheet.getRangeByIndex(2, 3).numberFormat = currencyFormat;
    sheet.getRangeByIndex(2, 5).numberFormat = currencyFormat;
    sheet.getRangeByIndex(2, 6).numberFormat = currencyFormat;

    sheet.getRangeByName('A1:F2').autoFit(); //clean up ts

    final List<int> bytes = workbook.saveAsStream();

    // final output = await getTemporaryDirectory();
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/report_$date.xlsx');
    await file.writeAsBytes(bytes);
    await OpenFilex.open(file.path);
  }
}

