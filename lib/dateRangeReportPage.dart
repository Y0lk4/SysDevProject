import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateRangeReportPage extends StatefulWidget {
  const DateRangeReportPage({Key? key}) : super(key: key);

  @override
  State<DateRangeReportPage> createState() => _DateRangeReportPageState();
}

class _DateRangeReportPageState extends State<DateRangeReportPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic> _totals = {};

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE30613),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchReports() async {
    if (_startDate == null || _endDate == null) return;

    setState(() => _isLoading = true);

    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);

      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .get();

      List<Map<String, dynamic>> reports = [];
      for (var doc in snap.docs) {
        reports.add(doc.data());
      }

      reports.sort((a, b) {
        final da = a['date'] ?? '';
        final db = b['date'] ?? '';
        return da.compareTo(db);
      });

      double totalCash = 0, totalTips = 0, totalTax = 0;
      double totalNetSales = 0, totalGrossSales = 0;
      int totalTransactions = 0;

      for (var r in reports) {
        totalCash += (r['cash'] ?? 0.0).toDouble();
        totalTips += (r['tips'] ?? 0.0).toDouble();
        totalTax += (r['salesTax'] ?? 0.0).toDouble();
        totalTransactions += (r['transactions'] is num ? (r['transactions'] as num).toInt() : 0);
        totalNetSales += (r['netSales'] ?? 0.0).toDouble();
        totalGrossSales += (r['grossSales'] ?? 0.0).toDouble();
      }

      setState(() {
        _reports = reports;
        _totals = {
          'cash': totalCash,
          'tips': totalTips,
          'salesTax': totalTax,
          'transactions': totalTransactions,
          'netSales': totalNetSales,
          'grossSales': totalGrossSales,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching date range: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE30613),
        elevation: 0,
        title: const Text(
          'Date Range Report',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDateCard(
                    label: 'Start Date',
                    date: _startDate,
                    dateFormat: dateFormat,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateCard(
                    label: 'End Date',
                    date: _endDate,
                    dateFormat: dateFormat,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_startDate != null && _endDate != null) ? _fetchReports : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE30613),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('View Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator(color: Color(0xFFE30613)),
            if (!_isLoading && _reports.isNotEmpty) ...[
              _buildTotalsCard(currencyFormat),
              const SizedBox(height: 20),
              ..._reports.map((r) => _buildReportItem(r, currencyFormat, dateFormat)),
            ],
            if (!_isLoading && _reports.isNotEmpty)
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required DateFormat dateFormat,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              date != null ? dateFormat.format(date) : 'Select',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Totals (${_reports.length} day${_reports.length != 1 ? 's' : ''})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          _totalRow('Total Cash', currencyFormat.format(_totals['cash'])),
          _totalRow('Total Tips', currencyFormat.format(_totals['tips'])),
          _totalRow('Total Sales Tax', currencyFormat.format(_totals['salesTax'])),
          _totalRow('Total Transactions', '${_totals['transactions']}'),
          _totalRow('Total Net Sales', currencyFormat.format(_totals['netSales']), isBold: true),
          const Divider(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE30613),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL GROSS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(currencyFormat.format(_totals['grossSales']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report, NumberFormat currencyFormat, DateFormat dateFormat) {
    final date = report['date'] ?? 'Unknown';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(currencyFormat.format(report['grossSales'] ?? 0.0)),
        ],
      ),
    );
  }
}
