import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectDatePage extends StatefulWidget {
  const SelectDatePage({Key? key}) : super(key: key);

  @override
  State<SelectDatePage> createState() => _SelectDatePageState();
}

class _SelectDatePageState extends State<SelectDatePage> {
  DateTime? _selectedDate;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    if (!next.isAfter(currentMonthStart)) {
      setState(() {
        _currentMonth = next;
      });
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
          'Select Date',
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
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildMonthHeader(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildCalendar(),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _selectedDate == null
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context, 
                          '/reportResults', 
                          arguments: _selectedDate
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedDate == null 
                      ? const Color(0xFFD1D5DB) 
                      : const Color(0xFFE30613),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD1D5DB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View Report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select a date to view its report',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
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
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < offset; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int i = 1; i <= daysInMonth; i++) {
      DateTime currentDay = DateTime(_currentMonth.year, _currentMonth.month, i);
      bool isSelected = _selectedDate != null &&
          _selectedDate!.year == currentDay.year &&
          _selectedDate!.month == currentDay.month &&
          _selectedDate!.day == currentDay.day;
      
      bool isMonday = currentDay.weekday == DateTime.monday;
      bool isFuture = currentDay.isAfter(DateTime.now());
      bool isDisabled = isMonday || isFuture;
      
      bool isOrange = [15, 20, 25, 29].contains(i) && !isDisabled;
      bool isRedOutlined = i == 30 && !isDisabled;

      dayWidgets.add(
        GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  setState(() {
                    _selectedDate = currentDay;
                  });
                },
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDisabled
                    ? Colors.grey[300]
                    : (isSelected 
                        ? Colors.black
                        : (isOrange ? Colors.orange : Colors.transparent)),
                border: isDisabled
                    ? null
                    : (isRedOutlined 
                        ? Border.all(color: const Color(0xFFE30613), width: 1.5)
                        : (isSelected ? Border.all(color: Colors.black, width: 1) : null)),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: isDisabled
                      ? Colors.grey[500]
                      : ((isSelected || isOrange) ? Colors.white : Colors.black87),
                  fontWeight: (isSelected || isOrange || isRedOutlined) ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
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
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: EdgeInsets.zero,
      children: dayWidgets,
    );
  }
}
