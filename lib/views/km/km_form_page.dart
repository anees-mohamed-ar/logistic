import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/km_controller.dart';
import 'package:logistic/models/km_location.dart';

class KMFormPage extends StatefulWidget {
  final KMLocation? km;

  const KMFormPage({super.key, this.km});

  @override
  _KMFormPageState createState() => _KMFormPageState();
}

class _KMFormPageState extends State<KMFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _kmController = TextEditingController();
  final KMController _controller = Get.find();

  @override
  void initState() {
    super.initState();
    final km = widget.km ?? Get.arguments as KMLocation?;
    if (km != null) {
      _fromController.text = km.from;
      _toController.text = km.to;
      _kmController.text = km.km;
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final km = widget.km ?? Get.arguments as KMLocation?;
      if (km == null) {
        _controller.addKM(
          _fromController.text.trim(),
          _toController.text.trim(),
          _kmController.text.trim(),
        );
      } else {
        _controller.updateKM(
          km.id,
          _fromController.text.trim(),
          _toController.text.trim(),
          _kmController.text.trim(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final km = widget.km ?? Get.arguments as KMLocation?;
    final isEditing = km != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit KM' : 'Add KM'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'From',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the source location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'To',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the destination';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmController,
                decoration: const InputDecoration(
                  labelText: 'Distance (KM)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the distance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Obx(
                () => _controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          isEditing ? 'Update KM' : 'Add KM',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
