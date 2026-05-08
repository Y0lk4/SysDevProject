import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({Key? key}) : super(key: key);

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _cashController = TextEditingController();
  final _tipsController = TextEditingController();
  final _taxController = TextEditingController();
  final _transactionsController = TextEditingController();
  final _netSalesController = TextEditingController();
  final _grossSalesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String? _validateNumericField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }

    // Try to parse as double
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Please enter a valid number (no letters or special characters)';
    }

    // Check for negative values
    if (parsed < 0) {
      return 'Negative values are not allowed';
    }

    return null;
  }

  String? _validateIntegerField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty';
    }

    // Try to parse as integer
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Please enter a whole number (no decimals, letters, or special characters)';
    }

    // Check for negative values
    if (parsed < 0) {
      return 'Negative values are not allowed';
    }

    return null;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _cashController.dispose();
    _tipsController.dispose();
    _taxController.dispose();
    _transactionsController.dispose();
    _netSalesController.dispose();
    _grossSalesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Check if the selected date is a Monday
      if (picked.weekday == DateTime.monday) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot create reports on Mondays')),
          );
        }
        return;
      }
      
      // Check if the selected date is in the future
      final now = DateTime.now();
      if (picked.isAfter(DateTime(now.year, now.month, now.day))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot create reports for future dates')),
          );
        }
        return;
      }
      
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  bool _isValidReportDate(DateTime date) {
    // Check if the date is a Monday
    if (date.weekday == DateTime.monday) {
      return false;
    }
    
    // Check if the date is in the future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today)) {
      return false;
    }
    
    return true;
  }

  Future<void> _saveReport() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Parse the date from the controller
        DateTime selectedDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
        
        // Validate the date
        if (!_isValidReportDate(selectedDate)) {
          if (mounted) {
            if (selectedDate.weekday == DateTime.monday) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cannot create reports on Mondays')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cannot create reports for future dates')),
              );
            }
          }
          return;
        }

        // We use the date string as the unique ID so the calendar can find it
        String docId = _dateController.text;

        await FirebaseFirestore.instance.collection('reports').doc(docId).set({
          'date': _dateController.text,
          'cash': double.tryParse(_cashController.text) ?? 0.0,
          'tips': double.tryParse(_tipsController.text) ?? 0.0,
          'salesTax': double.tryParse(_taxController.text) ?? 0.0,
          'transactions': int.tryParse(_transactionsController.text) ?? 0,
          'netSales': double.tryParse(_netSalesController.text) ?? 0.0,
          'grossSales': double.tryParse(_grossSalesController.text) ?? 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report saved successfully!')),
          );
          Navigator.pop(context);
        }
      } on FirebaseException catch (e) {
        // Specifically handle Firebase errors by accessing the message string
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Firebase Error: ${e.message}')),
          );
        }
      } catch (e) {
        // This is the 'catch' block the error was asking for
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving report: $e')));
        }
      }
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
          'Create Report',
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
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Date of Report'),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: _inputDecoration(
                  Icons.calendar_today_outlined,
                  'yyyy-mm-dd',
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('Cash'),
              TextFormField(
                controller: _cashController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(Icons.attach_money, '0.00'),
                validator: _validateNumericField,
              ),
              const SizedBox(height: 16),
              _buildLabel('Tips'),
              TextFormField(
                controller: _tipsController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(Icons.attach_money, '0.00'),
                validator: _validateNumericField,
              ),
              const SizedBox(height: 16),
              _buildLabel('Sales Tax'),
              TextFormField(
                controller: _taxController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(Icons.attach_money, '0.00'),
                validator: _validateNumericField,
              ),
              const SizedBox(height: 16),
              _buildLabel('Transactions'),
              TextFormField(
                controller: _transactionsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(Icons.numbers, '0', prefix: '# '),
                validator: _validateIntegerField,
              ),
              const SizedBox(height: 16),
              _buildLabel('Net Sales'),
              TextFormField(
                controller: _netSalesController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(Icons.attach_money, '0.00'),
                validator: _validateNumericField,
              ),
              const SizedBox(height: 16),
              _buildLabel('Gross Sales'),
              TextFormField(
                controller: _grossSalesController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(Icons.attach_money, '0.00'),
                validator: _validateNumericField,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE30613),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    IconData icon,
    String hint, {
    String? prefix,
  }) {
    return InputDecoration(
      prefixIcon: prefix != null
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                prefix,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Icon(icon, color: Colors.grey, size: 20),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
    );
  }

}
