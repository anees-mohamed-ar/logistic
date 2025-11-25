import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/gst_controller.dart';
import 'package:logistic/models/gst_model.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:intl/intl.dart';

class GstFormPage extends StatefulWidget {
  final GstModel? gst;

  const GstFormPage({Key? key, this.gst}) : super(key: key);

  @override
  _GstFormPageState createState() => _GstFormPageState();
}

class _GstFormPageState extends State<GstFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _gstController = Get.find<GstController>();

  late TextEditingController _hsnController;
  late TextEditingController _dateController;
  late TextEditingController _cgstController;
  late TextEditingController _igstController;
  late TextEditingController _sgstController;

  DateTime? _selectedDate;
  final _dateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _hsnController = TextEditingController(text: widget.gst?.hsn ?? '');
    _cgstController = TextEditingController(
      text: widget.gst?.cgst.toString() ?? '',
    );
    _igstController = TextEditingController(
      text: widget.gst?.igst.toString() ?? '',
    );
    _sgstController = TextEditingController(
      text: widget.gst?.sgst.toString() ?? '',
    );

    if (widget.gst != null) {
      _selectedDate = widget.gst!.date;
      _dateController = TextEditingController(
        text: _dateFormat.format(widget.gst!.date),
      );
    } else {
      _dateController = TextEditingController();
      _selectedDate = DateTime.now();
      _dateController.text = _dateFormat.format(_selectedDate!);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _dateFormat.format(picked);
      });
    }
  }

  Future<void> _saveGst() async {
    if (!_formKey.currentState!.validate()) return;

    final gst = GstModel(
      id: widget.gst?.id,
      hsn: _hsnController.text.trim(),
      date: _selectedDate!,
      cgst: double.tryParse(_cgstController.text) ?? 0.0,
      igst: double.tryParse(_igstController.text) ?? 0.0,
      sgst: double.tryParse(_sgstController.text) ?? 0.0,
      companyId: '1', // Replace with actual company ID from user session
    );

    bool success;
    if (widget.gst == null) {
      success = await _gstController.addGst(gst);
    } else {
      success = await _gstController.updateGst(gst);
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: widget.gst == null ? 'Add GST' : 'Edit GST',
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _hsnController,
                decoration: const InputDecoration(
                  labelText: 'HSN Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter HSN code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cgstController,
                decoration: const InputDecoration(
                  labelText: 'CGST %',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter CGST percentage';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _igstController,
                decoration: const InputDecoration(
                  labelText: 'IGST %',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter IGST percentage';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sgstController,
                decoration: const InputDecoration(
                  labelText: 'SGST %',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter SGST percentage';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveGst,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hsnController.dispose();
    _dateController.dispose();
    _cgstController.dispose();
    _igstController.dispose();
    _sgstController.dispose();
    super.dispose();
  }
}
