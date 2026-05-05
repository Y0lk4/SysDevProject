import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'Exports_stuff/Pdfexport.dart';    // Replace with your actual filename
import 'Exports_stuff/Excelexport.dart';

class ReportResultsPage extends StatefulWidget {
  final DateTime selectedDate;

  const ReportResultsPage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  State<ReportResultsPage> createState() => _ReportResultsPageState();
}

class _ReportResultsPageState extends State<ReportResultsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  Map<String, dynamic> _overviewTotals = {
    'cash': 0.0,
    'tips': 0.0,
    'salesTax': 0.0,
    'transactions': 0,
    'netSales': 0.0,
    'grossSales': 0.0,
  };
  int _currentIndex = 2; // Reports tab

  void _showExportOptions(BuildContext context) {

    String dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

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
                  ExcelExport.exportReport(_reportData ?? {}, dateStr);
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
                  PdfExport.exportReport(_reportData ?? {}, dateStr);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    String dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    try {
      // Fetch specific report for the selected day
      var reportSnap = await FirebaseFirestore.instance
          .collection('reports')
          .where('date', isEqualTo: dateStr)
          .limit(1)
          .get();

      if (reportSnap.docs.isNotEmpty) {
        _reportData = reportSnap.docs.first.data();
      }

      // Fetch all reports to calculate Overview totals
      var allReportsSnap = await FirebaseFirestore.instance.collection('reports').get();
      
      double totalCash = 0;
      double totalTips = 0;
      double totalTax = 0;
      num totalTransactionsNum = 0;
      double totalNetSales = 0;
      double totalGrossSales = 0;

      for (var doc in allReportsSnap.docs) {
        var data = doc.data();
        totalCash += (data['cash'] ?? 0.0).toDouble();
        totalTips += (data['tips'] ?? 0.0).toDouble();
        totalTax += (data['salesTax'] ?? 0.0).toDouble();
        totalTransactionsNum += (data['transactions'] ?? 0);
        totalNetSales += (data['netSales'] ?? 0.0).toDouble();
        totalGrossSales += (data['grossSales'] ?? 0.0).toDouble();
      }

      setState(() {
        _overviewTotals = {
          'cash': totalCash,
          'tips': totalTips,
          'salesTax': totalTax,
          'transactions': totalTransactionsNum.toInt(),
          'netSales': totalNetSales,
          'grossSales': totalGrossSales,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching report data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    String formattedDate = DateFormat('MMMM d, yyyy').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE30613),
        elevation: 0,
        title: const Text(
          'Report Results',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE30613)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Column(
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.grey[500], 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMainReportCard(currencyFormat),
                  const SizedBox(height: 25),
                  _buildOverviewCard(currencyFormat),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == _currentIndex) return;
              if (index == 0) {
                Navigator.pushReplacementNamed(context, '/home');
              } else if (index == 1) {
                Navigator.pushReplacementNamed(context, '/createReport');
              } else if (index == 2) {
                Navigator.popUntil(context, (route) => route.settings.name == '/viewReports' || route.isFirst);
              } else if (index == 3) {
                // Export tab
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
      ),
    );
  }

  Widget _buildMainReportCard(NumberFormat currencyFormat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildReportRow('Tips', currencyFormat.format(_reportData?['tips'] ?? 0.0)),
          _buildReportRow('Sales Tax', currencyFormat.format(_reportData?['salesTax'] ?? 0.0)),
          _buildReportRow('Transactions', '${_reportData?['transactions'] ?? 0}'),
          _buildReportRow('Net Sales', currencyFormat.format(_reportData?['netSales'] ?? 0.0), isBold: true),
          _buildReportRow('Gross Sales', currencyFormat.format(_reportData?['grossSales'] ?? 0.0), isBold: true),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFE30613),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(19),
                bottomRight: Radius.circular(19),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTALS',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 20,
                    letterSpacing: 0.5
                  ),
                ),
                Text(
                  currencyFormat.format(_overviewTotals['grossSales']),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 20
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[50]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildOverviewRow('Total Cash:', currencyFormat.format(_overviewTotals['cash'])),
          _buildOverviewRow('Total Tips:', currencyFormat.format(_overviewTotals['tips'])),
          _buildOverviewRow('Total Sales Tax:', currencyFormat.format(_overviewTotals['salesTax'])),
          _buildOverviewRow('Total Transactions:', '${_overviewTotals['transactions']}'),
          _buildOverviewRow('Total Net Sales:', currencyFormat.format(_overviewTotals['netSales']), isBold: true),
        ],
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15, 
              color: Colors.blueGrey[400],
              fontWeight: FontWeight.w400
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 65,
          child: ElevatedButton.icon(
            onPressed: () {
              _showExportOptions(context);
            },
            icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 28),
            label: const Text(
              'Export Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE30613),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 65,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text(
              'Back to Menu',
              style: TextStyle(
                fontSize: 18, 
                color: Color(0xFF475569), 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
      ],
    );
  }
}




