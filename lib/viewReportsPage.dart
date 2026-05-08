import 'package:flutter/material.dart';

class ViewReportsPage extends StatefulWidget {
  const ViewReportsPage({Key? key}) : super(key: key);

  @override
  State<ViewReportsPage> createState() => _ViewReportsPageState();
}

class _ViewReportsPageState extends State<ViewReportsPage> {
  int _currentIndex = 2; // Reports tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE30613),
        elevation: 0,
        title: const Text(
          'View Reports',
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Text(
              'Select how you want to view your reports',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 30),
            _buildOptionCard(
              context: context,
              icon: Icons.calendar_today_outlined,
              title: 'View by Single Date',
              subtitle: 'See the report for one specific day',
              onTap: () {
                Navigator.pushNamed(context, '/selectDate');
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context: context,
              icon: Icons.date_range_outlined,
              title: 'View by Date Range',
              subtitle: 'See totals across multiple days',
              onTap: () {
                Navigator.pushNamed(context, '/dateRangeReport');
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context: context,
              icon: Icons.compare_arrows_outlined,
              title: 'Compare Two Reports',
              subtitle: 'Compare two different dates side by side',
              onTap: () {
                Navigator.pushNamed(context, '/reports/compare');
              },
            ),
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
                Navigator.pushNamed(context, '/createReport');
              } else if (index == 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Select a report first, then export'),
                    duration: Duration(seconds: 2),
                  ),
                );
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

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFE30613), size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFE30613)),
          ],
        ),
      ),
    );
  }
}
