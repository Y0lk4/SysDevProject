import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Exports_stuff/ExcelExport.dart';
import 'Exports_stuff/PdfExport.dart';


class ComparisonResultsScreen extends StatefulWidget {
  const ComparisonResultsScreen({super.key});
  static const routeName = '/reports/comparison-results';

  @override
  State<ComparisonResultsScreen> createState() =>
      _ComparisonResultsScreenState();
}

class _ComparisonResultsScreenState extends State<ComparisonResultsScreen> {
  Map<String, dynamic>? _report1;
  Map<String, dynamic>? _report2;
  bool _loading = true;
  String? _error;

  late DateTime _date1;
  late DateTime _date2;
  bool _datesResolved = false;

  static const List<Map<String, String>> _fields = [
    {'key': 'cash', 'label': 'Cash', 'type': 'currency'},
    {'key': 'tips', 'label': 'Tips', 'type': 'currency'},
    {'key': 'salesTax', 'label': 'Sales Tax', 'type': 'currency'},
    {'key': 'transactions', 'label': 'Transactions', 'type': 'number'},
    {'key': 'netSales', 'label': 'Net Sales', 'type': 'currency'},
    {'key': 'grossSales', 'label': 'Gross Sales', 'type': 'currency'},
  ];

  // didChangeDependencies is used instead of initState because
  // ModalRoute.of(context) is unavailable during initState.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_datesResolved) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _date1 = args['date1'] as DateTime;
      _date2 = args['date2'] as DateTime;
      _datesResolved = true;
      _fetchReports();
    }
  }

  String _fmtDocId(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _fetchReports() async {
    try {
      final ref = FirebaseFirestore.instance.collection('reports');
      final results = await Future.wait([
        ref.doc(_fmtDocId(_date1)).get(),
        ref.doc(_fmtDocId(_date2)).get(),
      ]);

      if (!results[0].exists) {
        setState(() {
          _error = 'No report found for ${_fmtDisplay(_date1)}.';
          _loading = false;
        });
        return;
      }
      if (!results[1].exists) {
        setState(() {
          _error = 'No report found for ${_fmtDisplay(_date2)}.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _report1 = results[0].data();
        _report2 = results[1].data();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reports: $e';
        _loading = false;
      });
    }
  }

  String _fmtDisplay(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  num _val(Map<String, dynamic> report, String key) {
    final v = report[key];
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  String _fmtValue(num value, String type) => type == 'currency'
      ? '\$${value.toStringAsFixed(2)}'
      : value.toStringAsFixed(0);

  String _fmtDiff(num diff, String type) {
    final sign = diff >= 0 ? '+' : '';
    return type == 'currency'
        ? '$sign\$${diff.abs().toStringAsFixed(2)}'
        : '$sign${diff.toStringAsFixed(0)}';
  }

  String _fmtPct(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  String _buildSummary() {
    final t1 = _val(_report1!, 'grossSales');
    final t2 = _val(_report2!, 'grossSales');
    final salesDiff = t2 - t1;
    final salesPct = t1 != 0 ? (salesDiff / t1 * 100) : 0.0;
    final higherSales = salesDiff >= 0
        ? _fmtDisplay(_date2)
        : _fmtDisplay(_date1);
    final lowerSales = salesDiff >= 0
        ? _fmtDisplay(_date1)
        : _fmtDisplay(_date2);

    final tx1 = _val(_report1!, 'transactions');
    final tx2 = _val(_report2!, 'transactions');
    final txDiff = (tx2 - tx1).abs();
    final higherTx = tx2 >= tx1 ? _fmtDisplay(_date2) : _fmtDisplay(_date1);
    final lowerTx = tx2 >= tx1 ? _fmtDisplay(_date1) : _fmtDisplay(_date2);

    return '$higherSales had higher gross sales than $lowerSales '
        'by \$${salesDiff.abs().toStringAsFixed(2)} '
        '(${salesPct.abs().toStringAsFixed(1)}% ${salesDiff >= 0 ? 'increase' : 'decrease'}).\n\n'
        '$higherTx had $txDiff more transaction${txDiff != 1 ? 's' : ''} than $lowerTx.';
  }

  void _showExportOptions(BuildContext context) {
    try {
      String dateStr = "${DateFormat('yyyy-MM-dd').format(_date1)}_vs_${DateFormat('yyyy-MM-dd').format(_date2)}";

      final Map<String, dynamic> combinedData = {
        'report1': _report1,
        'report2': _report2,
        'date1': _fmtDisplay(_date1),
        'date2': _fmtDisplay(_date2),
        'isComparison': true,
      };

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Export Report',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.table_chart, color: Colors.green),
                  ),
                  title: const Text('Excel (.xlsx)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Best for data and spreadsheets'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportComparisonToExcel(combinedData, dateStr);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.picture_as_pdf, color: Colors.red),
                  ),
                  title: const Text('PDF (.pdf)', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Best for printing and viewing'),
                  onTap: () {
                    Navigator.pop(context);
                    _exportComparisonToPdf(combinedData, dateStr);
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _exportComparisonToExcel(Map<String, dynamic> data, String dateStr) async {
    try {
      await ExcelExport.exportReport(data, dateStr, comparison: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comparison exported to Excel!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel export failed: $e')),
      );
    }
  }

  Future<void> _exportComparisonToPdf(Map<String, dynamic> data, String dateStr) async {
    try {
      await PdfExport.exportReport(data, dateStr, comparison: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comparison exported to PDF!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE30613),
        elevation: 0,
        title: const Text(
          'Comparison Results',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE30613)),
            )
          : _error != null
          ? _buildError()
          : _buildResults(),
      bottomNavigationBar: _BottomNav(
        currentIndex: 2,
        onExportTap: () => _showExportOptions(context),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE30613), size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE30613),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final r1 = _report1!;
    final r2 = _report2!;
    final t1 = _val(r1, 'grossSales');
    final t2 = _val(r2, 'grossSales');
    final totalDiff = t2 - t1;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DateLabel(label: 'Date 1', date: _fmtDisplay(_date1)),
              const SizedBox(width: 32),
              _DateLabel(label: 'Date 2', date: _fmtDisplay(_date2)),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _TableHeader(),
                ..._fields.map((f) {
                  final v1 = _val(r1, f['key']!);
                  final v2 = _val(r2, f['key']!);
                  final diff = v2 - v1;
                  final pct = v1 != 0 ? diff / v1 * 100 : 0.0;
                  return _TableRow(
                    label: f['label']!,
                    val1: _fmtValue(v1, f['type']!),
                    val2: _fmtValue(v2, f['type']!),
                    diffText: _fmtPct(pct),
                    isPositive: diff >= 0,
                  );
                }),
                _TotalsRow(
                  val1: _fmtValue(t1, 'currency'),
                  val2: _fmtValue(t2, 'currency'),
                  diffText: _fmtDiff(totalDiff, 'currency'),
                  isPositive: totalDiff >= 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  _buildSummary(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _showExportOptions(context),
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Export Comparison',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE30613),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.popUntil(context, ModalRoute.withName('/reports')),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Back to Menu',
                style: TextStyle(color: Colors.black87, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

}

class _DateLabel extends StatelessWidget {
  final String label, date;
  const _DateLabel({required this.label, required this.date});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE30613),
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
    child: const Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Field',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Date 1',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Date 2',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Diff',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _TableRow extends StatelessWidget {
  final String label, val1, val2, diffText;
  final bool isPositive;

  const _TableRow({
    required this.label,
    required this.val1,
    required this.val2,
    required this.diffText,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          flex: 2,
          child: Text(val1, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          flex: 2,
          child: Text(val2, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${isPositive ? '↑ ' : '↓ '}$diffText',
            style: TextStyle(
              fontSize: 13,
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TotalsRow extends StatelessWidget {
  final String val1, val2, diffText;
  final bool isPositive;

  const _TotalsRow({
    required this.val1,
    required this.val2,
    required this.diffText,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE30613),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text('TOTALS', style: style)),
          Expanded(flex: 2, child: Text(val1, style: style)),
          Expanded(flex: 2, child: Text(val2, style: style)),
          Expanded(flex: 2, child: Text(diffText, style: style)),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onExportTap;
  const _BottomNav({required this.currentIndex, this.onExportTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == currentIndex) return;
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              Navigator.pushNamed(context, '/createReport');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/reports');
            } else if (index == 3) {
              onExportTap?.call();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFE30613),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add, size: 26),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined, size: 26),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_download_outlined, size: 26),
              label: 'Export',
            ),
          ],
        ),
      ),
    );
  }
}
