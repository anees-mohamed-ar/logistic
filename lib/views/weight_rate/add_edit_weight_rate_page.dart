import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/weight_to_rate_controller.dart';
import 'package:logistic/models/weight_to_rate.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/routes.dart';

class AddEditWeightRatePage extends StatefulWidget {
  final WeightToRate? weightRate;

  AddEditWeightRatePage({Key? key, this.weightRate}) : super(key: key) {
    print('AddEditWeightRatePage: Constructor called with weightRate: $weightRate');
  }
  
  static Widget create(Object? arguments) {
    print('AddEditWeightRatePage.create called with arguments: $arguments');
    if (arguments is WeightToRate) {
      return AddEditWeightRatePage(weightRate: arguments);
    } else if (arguments is Map<String, dynamic>) {
      return AddEditWeightRatePage(weightRate: WeightToRate.fromJson(arguments));
    } else {
      return AddEditWeightRatePage();
    }
  }

  @override
  _AddEditWeightRatePageState createState() => _AddEditWeightRatePageState();
}

class _AddEditWeightRatePageState extends State<AddEditWeightRatePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<WeightToRateController>();
  
  final _weightController = TextEditingController();
  final _below250Controller = TextEditingController();
  final _above250Controller = TextEditingController();

  bool get isEditing => widget.weightRate != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _weightController.text = widget.weightRate!.weight;
      _below250Controller.text = widget.weightRate!.below250.toStringAsFixed(2);
      _above250Controller.text = widget.weightRate!.above250.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _below250Controller.dispose();
    _above250Controller.dispose();
    super.dispose();
  }
  
  // Parse a string to double, handling empty strings and invalid formats
  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
  }

  Future<void> _saveWeightRate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final below250 = _parseDouble(_below250Controller.text);
      final above250 = _parseDouble(_above250Controller.text);
      
      if (below250 == null || above250 == null) {
        throw 'Please enter valid numbers for rates';
      }
      
      if (below250 <= 0 || above250 <= 0) {
        throw 'Rates must be greater than 0';
      }

      final weightRate = WeightToRate(
        id: widget.weightRate?.id,
        weight: _weightController.text.trim(),
        below250: below250,
        above250: above250,
      );

      final success = isEditing
          ? await _controller.updateWeightRate(weightRate)
          : await _controller.addWeightRate(weightRate);

      if (success && mounted) {
        Get.back(result: true); // Return success result
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: isEditing ? 'Edit Weight Rate' : 'Add New Weight Rate',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Weight Field
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (e.g., 1mt, 2.5mt, 5mt)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a weight';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Below 250km Rate
              TextFormField(
                controller: _below250Controller,
                decoration: const InputDecoration(
                  labelText: 'Rate (Below 250km)',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.money_off_csred),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a rate';
                  }
                  final rate = _parseDouble(value);
                  if (rate == null) {
                    return 'Please enter a valid number';
                  }
                  if (rate <= 0) {
                    return 'Rate must be greater than 0';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Above 250km Rate
              TextFormField(
                controller: _above250Controller,
                decoration: const InputDecoration(
                  labelText: 'Rate (Above 250km)',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveWeightRate(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a rate';
                  }
                  final rate = _parseDouble(value);
                  if (rate == null) {
                    return 'Please enter a valid number';
                  }
                  if (rate <= 0) {
                    return 'Rate must be greater than 0';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save/Update Button
              Obx(() {
                return _controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveWeightRate,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2A44),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: Text(
                          isEditing ? 'UPDATE RATE' : 'SAVE RATE',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
              }),
              
              // Cancel Button
              if (!_controller.isLoading.value) ...[  
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('CANCEL'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
