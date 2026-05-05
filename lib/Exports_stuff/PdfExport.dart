
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PdfExport {
  static Future<void> exportReport(Map<String, dynamic> data, String date) async{
    final pdf = pw.Document();
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);


    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Daily Sales Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              // color
              pw.Divider( thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              _buildVerticalRow('Date', date),
              _buildVerticalRow('Tips', currency.format(data['tips'] ?? 0.0)),
              _buildVerticalRow('Sales Tax', currency.format(data['salesTax'] ?? 0.0)),
              _buildVerticalRow('Transactions', '${data['transactions'] ?? 0}'),
              _buildVerticalRow('Net Sales', currency.format(data['netSales'] ?? 0.0), isBold: true),

              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: const pw.BoxDecoration(
                  // color
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: _buildVerticalRow('Gross Sales', currency.format(data['grossSales'] ?? 0.0), isBold: true),
              ),

            ]
          );
        }
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/report_$date.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  static pw.Widget _buildVerticalRow(String label, String value, {bool isBold = false}) {
    final style = pw.TextStyle(
        fontSize: 14,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style.copyWith(color: PdfColors.grey700)),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

}