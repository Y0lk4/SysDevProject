import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompareReportsScreen extends StatefulWidget {
  const CompareReportsScreen({super.key});

  @override
  State<CompareReportsScreen> createState() => _CompareReportsScreenState();
}

class _CompareReportsScreenState extends State<CompareReportsScreen> {
  DateTime? _date1;
  DateTime? _date2;

  Set<String> _availableDates = {};
  bool _loadingDates = true;

  @override
  void initState() {
    super.initState();
    _fetchAvailableDates();
  }

  Future<void> _fetchAvailableDates() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .get();
    setState(() {
      _availableDates = snapshot.docs.map((d) => d.id).toSet();
      _loadingDates = false;
    });
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _hasReport(DateTime d) => _availableDates.contains(_formatDate(d));

  Future<void> _pickDate(int slot) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => _CalendarDialog(
        availableDates: _availableDates,
        initialDate: slot == 1 ? _date1 : _date2,
        title: 'Date $slot',
      ),
    );
    if (picked == null) return;
    setState(() {
      if (slot == 1) {
        _date1 = picked;
      } else {
        _date2 = picked;
      }
    });
  }

  void _compareReports() {
    if (_date1 == null || _date2 == null) return;
    Navigator.pushNamed(
      context,
      '/reports/comparison-results',
      arguments: {'date1': _date1!, 'date2': _date2!},
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCompare = _date1 != null && _date2 != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE30613),
        elevation: 0,
        title: const Text(
          'Compare Reports',
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
      body: _loadingDates
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE30613)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'Select two dates to compare side by side',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  _CalendarCard(
                    label: 'Date 1',
                    selectedDate: _date1,
                    availableDates: _availableDates,
                    onDateSelected: (d) => setState(() => _date1 = d),
                  ),
                  const SizedBox(height: 16),

                  _CalendarCard(
                    label: 'Date 2',
                    selectedDate: _date2,
                    availableDates: _availableDates,
                    onDateSelected: (d) => setState(() => _date2 = d),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: canCompare ? _compareReports : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE30613),
                        disabledBackgroundColor: const Color(0xFFE30613),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Compare Reports',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    canCompare
                        ? ''
                        : 'Select one date on each calendar to compare',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _BottomNav(currentIndex: 2),
    );
  }
}

class _CalendarCard extends StatefulWidget {
  final String label;
  final DateTime? selectedDate;
  final Set<String> availableDates;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarCard({
    required this.label,
    required this.selectedDate,
    required this.availableDates,
    required this.onDateSelected,
  });

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _hasReport(DateTime d) => widget.availableDates.contains(_fmt(d));

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime?> _buildDays() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    // Sunday = 0
    final startPad = first.weekday % 7;
    final List<DateTime?> days = List.filled(startPad, null);
    for (int i = 1; i <= last.day; i++) {
      days.add(DateTime(_focusedMonth.year, _focusedMonth.month, i));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildDays();
    const headers = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFFE30613),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                }),
              ),
              const SizedBox(width: 6),
              Text(
                '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: headers
                .map(
                  (h) => SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (ctx, i) {
              final day = days[i];
              if (day == null) return const SizedBox();

              final hasReport = _hasReport(day);
              final isSelected =
                  widget.selectedDate != null &&
                  _isSameDay(day, widget.selectedDate!);
              final isToday = _isSameDay(day, DateTime.now());

              Color bgColor = Colors.transparent;
              Color textColor = Colors.black87;
              BoxBorder? border;

              if (isSelected) {
                bgColor = const Color(0xFFE30613);
                textColor = Colors.white;
              } else if (hasReport) {
                bgColor = const Color(0xFFFFEEEE);
                textColor = const Color(0xFFE30613);
                border = Border.all(color: const Color(0xFFE30613), width: 1.5);
              } else if (isToday) {
                border = Border.all(color: Colors.grey.shade400);
              }

              return GestureDetector(
                onTap: hasReport ? () => widget.onDateSelected(day) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: border,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasReport || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: hasReport || isSelected
                            ? textColor
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => const [
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
  ][m];
}

class _CalendarDialog extends StatelessWidget {
  final Set<String> availableDates;
  final DateTime? initialDate;
  final String title;

  const _CalendarDialog({
    required this.availableDates,
    required this.initialDate,
    required this.title,
  });

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

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
              Navigator.pushNamed(context, '/export');
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
