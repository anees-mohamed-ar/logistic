import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logistic/controller/broker_controller.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/models/broker.dart';
import 'package:logistic/models/state_model.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';
import 'package:logistic/api_config.dart';

class AddEditBrokerPage extends StatefulWidget {
  final Broker? broker;

  const AddEditBrokerPage({Key? key, this.broker}) : super(key: key);

  @override
  _AddEditBrokerPageState createState() => _AddEditBrokerPageState();
}

class _AddEditBrokerPageState extends State<AddEditBrokerPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<BrokerController>();
  final _idController = Get.find<IdController>();
  
  // State management
  final _states = <StateModel>[].obs;
  final _statesLoading = false.obs;
  final _statesError = ''.obs;
  StateModel? _selectedState;
  
  // Controllers for form fields
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _countryController = TextEditingController();
  final _commissionController = TextEditingController();
  final _emailController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _panController = TextEditingController();
  
  DateTime? _selectedDob;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.broker != null) {
      _populateForm(widget.broker!);
    }
    _loadStates();
  }

  void _populateForm(Broker broker) {
    _nameController.text = broker.brokerName;
    _addressController.text = broker.brokerAddress;
    _districtController.text = broker.district;
    _countryController.text = broker.country;
    _selectedDob = broker.dateofBirth != null ? DateTime.parse(broker.dateofBirth!) : null;
    _commissionController.text = broker.commissionPercentage.toString();
    _emailController.text = broker.email;
    _bloodGroupController.text = broker.bloodGroup;
    _phoneController.text = broker.phoneNumber;
    _mobileController.text = broker.mobileNumber;
    _panController.text = broker.panNumber;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _saveBroker() async {
    if (!_formKey.currentState!.validate()) return;

    final broker = Broker(
      id: widget.broker?.id,
      brokerName: _nameController.text.trim(),
      brokerAddress: _addressController.text.trim(),
      district: _districtController.text.trim(),
      state: _selectedState?.name ?? '',
      country: _countryController.text.trim(),
      dateofBirth: _selectedDob?.toIso8601String(),
      commissionPercentage: double.tryParse(_commissionController.text.trim()) ?? 0.0,
      email: _emailController.text.trim(),
      bloodGroup: _bloodGroupController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      panNumber: _panController.text.trim(),
      companyId: int.tryParse(_idController.companyId.value) ?? 0,
    );

    setState(() => _isLoading = true);
    
    final success = widget.broker == null
        ? await _controller.addBroker(broker)
        : await _controller.updateBroker(broker);

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        widget.broker == null ? 'Broker added successfully' : 'Broker updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: widget.broker == null ? 'Add Broker' : 'Edit Broker',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Broker Name *',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address *',
                      maxLines: 3,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _districtController,
                            label: 'District *',
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStateDropdown(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _countryController,
                      label: 'Country *',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'Date of Birth',
                      value: _selectedDob != null
                          ? DateFormat('dd-MM-yyyy').format(_selectedDob!)
                          : 'Select Date',
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _commissionController,
                      label: 'Commission Percentage *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isNotEmpty ?? false) {
                          if (!GetUtils.isEmail(value!)) {
                            return 'Enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bloodGroupController,
                      label: 'Blood Group',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number *',
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile Number *',
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _panController,
                      label: 'PAN Number *',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveBroker,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2A44),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.broker == null ? 'Add Broker' : 'Update Broker',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value),
          ),
        ),
      ],
    );
  }

  Future<void> _loadStates() async {
    try {
      _statesLoading.value = true;
      _statesError.value = '';
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/state/search'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _states.value = data.map((state) => StateModel.fromJson(state)).toList();
        
        // Set selected state if editing
        if (widget.broker != null && widget.broker!.state.isNotEmpty) {
          setState(() {
            _selectedState = _states.firstWhere(
              (state) => state.name.toLowerCase() == widget.broker!.state.toLowerCase(),
              orElse: () => StateModel(id: 0, name: widget.broker!.state, code: '', tin: '')
            );
          });
        }
      } else {
        throw Exception('Failed to load states');
      }
    } catch (e) {
      _statesError.value = 'Failed to load states: $e';
    } finally {
      _statesLoading.value = false;
    }
  }
  
  Widget _buildStateDropdown() {
    return Obx(() {
      if (_statesLoading.value) {
        return const CircularProgressIndicator();
      }
      
      if (_statesError.value.isNotEmpty) {
        return Text(
          _statesError.value,
          style: const TextStyle(color: Colors.red),
        );
      }
      
      return SearchableDropdown<StateModel>(
        label: 'State *',
        value: _selectedState,
        items: _states.map((state) => DropdownMenuItem<StateModel>(
          value: state,
          child: Text(state.name),
        )).toList(),
        onChanged: (StateModel? state) {
          setState(() {
            _selectedState = state;
          });
        },
        validator: (value) => _selectedState == null ? 'Please select a state' : null,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    _commissionController.dispose();
    _emailController.dispose();
    _bloodGroupController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _panController.dispose();
    super.dispose();
  }
}
