
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class PdfExport {
  static Future<void> exportReport(Map<String, dynamic> data, String date, {bool comparison = false}) async {
    try {
      final pdf = pw.Document();

      if (comparison) {
        _buildComparisonPage(pdf, data, date);
      } else {
        _buildSingleReportPage(pdf, data, date);
      }

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/report_$date.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) {
      print('Error exporting to PDF: $e');
      rethrow;
    }
  }

  static void _buildComparisonPage(pw.Document pdf, Map<String, dynamic> data, String date){
    try {
      final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

      // Extract reports from the bundle
      final report1 = data['report1'] as Map<String, dynamic>?;
      final report2 = data['report2'] as Map<String, dynamic>?;
      
      if (report1 == null || report2 == null) {
        pdf.addPage(pw.Page(
          build: (pw.Context context) => pw.Text('Error: Missing report data'),
        ));
        return;
      }
      
      final String d1Label = data['date1'] ?? 'Date 1';
      final String d2Label = data['date2'] ?? 'Date 2';

      // Helper to extract numbers safely
      num val(Map<String, dynamic> r, String key) => r[key] is num ? r[key] : (num.tryParse(r[key].toString()) ?? 0);

      final fields = [
        {'key': 'cash', 'label': 'Cash'},
        {'key': 'tips', 'label': 'Tips'},
        {'key': 'salesTax', 'label': 'Sales Tax'},
        {'key': 'transactions', 'label': 'Transactions'},
        {'key': 'netSales', 'label': 'Net Sales'},
        {'key': 'grossSales', 'label': 'Gross Sales'},
      ];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sales Comparison Report',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                pw.SizedBox(height: 8),
                pw.Text('Comparing: $d1Label vs $d2Label', style: const pw.TextStyle(color: PdfColors.grey700)),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2, color: PdfColors.red),
                pw.SizedBox(height: 20),

                // Table definition
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _pCell('Field', isBold: true),
                        _pCell('Date 1', isBold: true),
                        _pCell('Date 2', isBold: true),
                        _pCell('Diff (%)', isBold: true),
                      ],
                    ),
                    // Data Rows
                    ...fields.map((f) {
                      final v1 = val(report1, f['key']!);
                      final v2 = val(report2, f['key']!);
                      final diff = v2 - v1;
                      final pct = v1 != 0 ? (diff / v1 * 100) : 0.0;

                      bool isCurrency = f['key'] != 'transactions';

                      return pw.TableRow(
                        children: [
                          _pCell(f['label']!),
                          _pCell(isCurrency ? currency.format(v1) : v1.toString()),
                          _pCell(isCurrency ? currency.format(v2) : v2.toString()),
                          _pCell(
                            '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                            color: pct >= 0 ? PdfColors.green : PdfColors.red,
                          ),
                        ],
                      );
                    }),
                    // Totals Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.red),
                      children: [
                        _pCell('TOTAL GROSS', isBold: true, color: PdfColors.white),
                        _pCell(currency.format(val(report1, 'grossSales')), isBold: true, color: PdfColors.white),
                        _pCell(currency.format(val(report2, 'grossSales')), isBold: true, color: PdfColors.white),
                        _pCell(
                            currency.format(val(report2, 'grossSales') - val(report1, 'grossSales')),
                            isBold: true,
                            color: PdfColors.white
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      print('Error building PDF comparison page: $e');
      pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Text('Error: $e'),
      ));
    }
  }

  static void _buildSingleReportPage(pw.Document pdf, Map<String, dynamic> data, String date){
    try {
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
                    pw.Divider( thickness: 1, color: PdfColors.grey300),
                    pw.SizedBox(height: 20),

                    _buildVerticalRow('Date', date),
                    _buildVerticalRow('Cash', currency.format(data['cash'] ?? 0.0)),
                    _buildVerticalRow('Tips', currency.format(data['tips'] ?? 0.0)),
                    _buildVerticalRow('Sales Tax', currency.format(data['salesTax'] ?? 0.0)),
                    _buildVerticalRow('Transactions', '${data['transactions'] ?? 0}'),
                    _buildVerticalRow('Net Sales', currency.format(data['netSales'] ?? 0.0), isBold: true),

                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: const pw.BoxDecoration(
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
    } catch (e) {
      print('Error building PDF single report page: $e');
      pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Text('Error: $e'),
      ));
    }
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

  static pw.Widget _pCell(String text, {bool isBold = false, PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

}