import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectDatePage extends StatefulWidget {
  const SelectDatePage({Key? key}) : super(key: key);

  @override
  State<SelectDatePage> createState() => _SelectDatePageState();
}

class _SelectDatePageState extends State<SelectDatePage> {
  DateTime? _selectedDate;
  final DateTime _currentMonth = DateTime.now();

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
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildCalendar(_currentMonth),
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

  Widget _buildCalendar(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
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
      DateTime currentDay = DateTime(date.year, date.month, i);
      bool isSelected = _selectedDate != null &&
          _selectedDate!.year == currentDay.year &&
          _selectedDate!.month == currentDay.month &&
          _selectedDate!.day == currentDay.day;
      
      // Mock data from the image: 15, 20, 25, 29 are orange, 30 is red outlined
      bool isOrange = [15, 20, 25, 29].contains(i);
      bool isRedOutlined = i == 30;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
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
                color: isSelected 
                    ? Colors.black
                    : (isOrange ? Colors.orange : Colors.transparent),
                border: isRedOutlined 
                    ? Border.all(color: const Color(0xFFE30613), width: 1.5)
                    : (isSelected ? Border.all(color: Colors.black, width: 1) : null),
              ),
              child: Text(
                '$i',
                style: TextStyle(
                  color: (isSelected || isOrange) ? Colors.white : Colors.black87,
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
