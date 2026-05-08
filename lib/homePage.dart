import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _previousMonth() {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    if (!next.isAfter(currentMonthStart)) {
      setState(() {
        _calendarMonth = next;
      });
    }
  }

  Future<void> _pickMonthYear() async {
    final now = DateTime.now();
    final currentMonth = _calendarMonth.month;
    final currentYear = _calendarMonth.year;

    final monthCtl = TextEditingController(text: currentMonth.toString());
    final yearCtl = TextEditingController(text: currentYear.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to Month/Year'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Month (1-12)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Year'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Go')),
        ],
      ),
    );

    if (result == true) {
      final m = int.tryParse(monthCtl.text);
      final y = int.tryParse(yearCtl.text);
      if (m != null && y != null && m >= 1 && m <= 12 && y >= 2020 && y <= now.year) {
        final target = DateTime(y, m, 1);
        if (!target.isAfter(DateTime(now.year, now.month, 1))) {
          setState(() {
            _calendarMonth = target;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE30613),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 12),
                  child: const Center(
                    child: Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back, Ibrahim',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    _formatDate(now),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Report Calendar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Calendar navigation
                  _buildCalendarNav(),
                  const SizedBox(height: 10),
                  // Compact Calendar
                  _buildCalendar(),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                  const SizedBox(height: 25),
                  Center(
                    child: Text(
                      'Last report created: ${_formatLastReportDate(now)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
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
              if (index == 1) {
                Navigator.pushNamed(context, '/createReport');
              } else if (index == 2) {
                Navigator.pushNamed(context, '/viewReports');
              } else if (index == 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Go to Reports to export your data'),
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

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatLastReportDate(DateTime date) {
    final lastReport = date.subtract(const Duration(days: 1));
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[lastReport.month - 1]} ${lastReport.day}, ${lastReport.year}';
  }

  Widget _buildCalendarNav() {
    final now = DateTime.now();
    final isCurrent = _calendarMonth.year == now.year && _calendarMonth.month == now.month;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 22),
          onPressed: _previousMonth,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
        GestureDetector(
          onTap: _pickMonthYear,
          child: Text(
            DateFormat('MMMM yyyy').format(_calendarMonth),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 22),
          onPressed: isCurrent ? null : _nextMonth,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastDayOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    int offset = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (var day in weekdays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < offset; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      bool isToday = i == DateTime.now().day && _calendarMonth.month == DateTime.now().month && _calendarMonth.year == DateTime.now().year;

      dayWidgets.add(
        Center(
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isToday ? Border.all(color: const Color(0xFFE30613), width: 1.2) : null,
            ),
            child: Text(
              '$i',
              style: TextStyle(
                color: isToday ? Colors.black : Colors.black87,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: EdgeInsets.zero,
      children: dayWidgets,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/createReport'),
          child: _buildButton(
            color: const Color(0xFFE30613),
            title: 'Create Report',
            subtitle: 'Enter today\'s financial data',
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/viewReports'),
          child: _buildButton(
            color: const Color(0xFF1D2733),
            title: 'View Reports',
            subtitle: 'Browse and compare past reports',
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              title == 'Create Report' ? Icons.add : Icons.bar_chart,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
