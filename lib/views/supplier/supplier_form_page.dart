import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/controller/supplier_controller.dart';
import 'package:logistic/models/supplier_model.dart';
import 'package:logistic/models/state_model.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';
import 'package:logistic/api_config.dart';

class SupplierFormPage extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormPage({Key? key, this.supplier}) : super(key: key);

  @override
  _SupplierFormPageState createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<SupplierController>();
  
  // State management
  final _states = <StateModel>[].obs;
  final _statesLoading = false.obs;
  final _statesError = ''.obs;
  StateModel? _selectedState;
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _locationController;
  late TextEditingController _districtController;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _gstController;
  late TextEditingController _panController;
  late TextEditingController _msmeController;
  late TextEditingController _emailController;
  late TextEditingController _cinController;
  late TextEditingController _compTypeController;
  late TextEditingController _industrialTypeController;
  late TextEditingController _faxController;
  late TextEditingController _companyIdController;
  late TextEditingController _accountNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _micrController;
  late TextEditingController _bankNameController;
  late TextEditingController _branchCodeController;
  late TextEditingController _branchNameController;
  late TextEditingController _supplierNoController;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    _nameController = TextEditingController(text: supplier?.supplierName ?? '');
    _addressController = TextEditingController(text: supplier?.address ?? '');
    
    // Initialize other controllers
    _locationController = TextEditingController(text: supplier?.location ?? '');
    _districtController = TextEditingController(text: supplier?.district ?? '');
    _contactController = TextEditingController(text: supplier?.contact ?? '');
    _phoneController = TextEditingController(text: supplier?.phoneNumber ?? '');
    _mobileController = TextEditingController(text: supplier?.mobileNumber ?? '');
    _gstController = TextEditingController(text: supplier?.gst ?? '');
    _panController = TextEditingController(text: supplier?.panNumber ?? '');
    _msmeController = TextEditingController(text: supplier?.msmeNumber ?? '');
    _emailController = TextEditingController(text: supplier?.email ?? '');
    _cinController = TextEditingController(text: supplier?.cinNumber ?? '');
    _compTypeController = TextEditingController(text: supplier?.compType ?? '');
    _industrialTypeController = TextEditingController(text: supplier?.industrialType ?? '');
    _faxController = TextEditingController(text: supplier?.fax ?? '');
    _companyIdController = TextEditingController(text: supplier?.companyId ?? '');
    _accountNameController = TextEditingController(text: supplier?.accountHolderName ?? '');
    _accountNumberController = TextEditingController(text: supplier?.accountNumber ?? '');
    _ifscController = TextEditingController(text: supplier?.ifscCode ?? '');
    _micrController = TextEditingController(text: supplier?.micrCode ?? '');
    _bankNameController = TextEditingController(text: supplier?.bankName ?? '');
    _branchCodeController = TextEditingController(text: supplier?.branchCode ?? '');
    _branchNameController = TextEditingController(text: supplier?.branchName ?? '');
    _supplierNoController = TextEditingController(text: supplier?.supplierNo ?? '');
    
    // Load states after initializing controllers
    _loadStates();
    _locationController = TextEditingController(text: supplier?.location ?? '');
    _districtController = TextEditingController(text: supplier?.district ?? '');
    _contactController = TextEditingController(text: supplier?.contact ?? '');
    _phoneController = TextEditingController(text: supplier?.phoneNumber ?? '');
    _mobileController = TextEditingController(text: supplier?.mobileNumber ?? '');
    _gstController = TextEditingController(text: supplier?.gst ?? '');
    _panController = TextEditingController(text: supplier?.panNumber ?? '');
    _msmeController = TextEditingController(text: supplier?.msmeNumber ?? '');
    _emailController = TextEditingController(text: supplier?.email ?? '');
    _cinController = TextEditingController(text: supplier?.cinNumber ?? '');
    _compTypeController = TextEditingController(text: supplier?.compType ?? '');
    _industrialTypeController = TextEditingController(text: supplier?.industrialType ?? '');
    _faxController = TextEditingController(text: supplier?.fax ?? '');
    _companyIdController = TextEditingController(text: supplier?.companyId ?? '');
    _accountNameController = TextEditingController(text: supplier?.accountHolderName ?? '');
    _accountNumberController = TextEditingController(text: supplier?.accountNumber ?? '');
    _ifscController = TextEditingController(text: supplier?.ifscCode ?? '');
    _micrController = TextEditingController(text: supplier?.micrCode ?? '');
    _bankNameController = TextEditingController(text: supplier?.bankName ?? '');
    _branchCodeController = TextEditingController(text: supplier?.branchCode ?? '');
    _branchNameController = TextEditingController(text: supplier?.branchName ?? '');
    _supplierNoController = TextEditingController(text: supplier?.supplierNo ?? '');
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
        if (widget.supplier != null && widget.supplier!.state.isNotEmpty) {
          setState(() {
            _selectedState = _states.firstWhere(
              (state) => state.name.toLowerCase() == widget.supplier!.state.toLowerCase(),
              orElse: () => StateModel(id: 0, name: widget.supplier!.state, code: '', tin: '')
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
        return Text('Error: ${_statesError.value}');
      }

      return SearchableDropdown<StateModel>(
        label: 'State *',
        value: _selectedState,
        items: _states.map((state) => DropdownMenuItem<StateModel>(
          value: state,
          child: Text(state.name),
        )).toList(),
        onChanged: (StateModel? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedState = newValue;
            });
          }
        },
        isRequired: true,
        validator: (value) => value == null ? 'Please select a state' : null,
      );
    });
  }

  @override
  void dispose() {
    _statesLoading.close();
    _statesError.close();
    _nameController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _districtController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _msmeController.dispose();
    _emailController.dispose();
    _cinController.dispose();
    _compTypeController.dispose();
    _industrialTypeController.dispose();
    _faxController.dispose();
    _companyIdController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _micrController.dispose();
    _bankNameController.dispose();
    _branchCodeController.dispose();
    _branchNameController.dispose();
    _supplierNoController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _addressController.clear();
    setState(() => _selectedState = null);
    _districtController.clear();
    _contactController.clear();
    _phoneController.clear();
    _mobileController.clear();
    _gstController.clear();
    _panController.clear();
    _msmeController.clear();
    _emailController.clear();
    _cinController.clear();
    _compTypeController.clear();
    _industrialTypeController.clear();
    _faxController.clear();
    _companyIdController.clear();
    _accountNameController.clear();
    _accountNumberController.clear();
    _ifscController.clear();
    _micrController.clear();
    _bankNameController.clear();
    _branchCodeController.clear();
    _branchNameController.clear();
    _supplierNoController.clear();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedState == null) {
        Get.snackbar('Error', 'Please select a state');
        return;
      }
      
      final supplier = Supplier(
        id: widget.supplier?.id,
        supplierName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        state: _selectedState!.name,
        location: _locationController.text,
        district: _districtController.text,
        contact: _contactController.text,
        phoneNumber: _phoneController.text,
        mobileNumber: _mobileController.text,
        gst: _gstController.text,
        panNumber: _panController.text,
        msmeNumber: _msmeController.text,
        email: _emailController.text,
        cinNumber: _cinController.text,
        compType: _compTypeController.text,
        industrialType: _industrialTypeController.text,
        fax: _faxController.text,
        companyId: _companyIdController.text,
        accountHolderName: _accountNameController.text,
        accountNumber: _accountNumberController.text,
        ifscCode: _ifscController.text,
        micrCode: _micrController.text,
        bankName: _bankNameController.text,
        branchCode: _branchCodeController.text,
        branchName: _branchNameController.text,
        supplierNo: _supplierNoController.text,
      );

      final success = widget.supplier == null
          ? await _controller.addSupplier(supplier)
          : await _controller.updateSupplier(supplier);

      if (success && mounted) {
        Get.back();
        Get.snackbar('Success',
            'Supplier ${widget.supplier == null ? 'added' : 'updated'} successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '${widget.supplier == null ? 'Add' : 'Edit'} Supplier',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader('Basic Information'),
            _buildTextFormField('Supplier Name', _nameController, isRequired: true),
            _buildTextFormField('Address', _addressController, maxLines: 2),
            _buildStateDropdown(),
            const SizedBox(height: 16),
            _buildTextFormField('Location', _locationController),
            _buildTextFormField('District', _districtController),
            _buildTextFormField('Contact Person', _contactController, isRequired: true),
            _buildTextFormField('Phone', _phoneController, keyboardType: TextInputType.phone),
            _buildTextFormField('Mobile', _mobileController, keyboardType: TextInputType.phone, isRequired: true),
            _buildTextFormField('Email', _emailController, keyboardType: TextInputType.emailAddress),
            
            _buildSectionHeader('Business Information'),
            _buildTextFormField('GST Number', _gstController, isRequired: true),
            _buildTextFormField('PAN Number', _panController, isRequired: true),
            _buildTextFormField('MSME Number', _msmeController),
            _buildTextFormField('CIN Number', _cinController),
            _buildTextFormField('Company Type', _compTypeController),
            _buildTextFormField('Industrial Type', _industrialTypeController),
            _buildTextFormField('Fax', _faxController, keyboardType: TextInputType.phone),
            _buildTextFormField('Company ID', _companyIdController),
            _buildTextFormField('Supplier Number', _supplierNoController, isRequired: true),
            
            _buildSectionHeader('Bank Details'),
            _buildTextFormField('Account Holder Name', _accountNameController, isRequired: true),
            _buildTextFormField('Account Number', _accountNumberController, keyboardType: TextInputType.number, isRequired: true),
            _buildTextFormField('Bank Name', _bankNameController, isRequired: true),
            _buildTextFormField('Branch Name', _branchNameController, isRequired: true),
            _buildTextFormField('Branch Code', _branchCodeController),
            _buildTextFormField('IFSC Code', _ifscController, isRequired: true),
            _buildTextFormField('MICR Code', _micrController),
            
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF1E2A44)),
              onPressed: _submitForm,
              child: Text(widget.supplier == null ? 'Add Supplier' : 'Update Supplier'),
            ),
            if (widget.supplier != null) ...{
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _confirmDelete(),
                child: const Text('Delete Supplier', style: TextStyle(color: Colors.red)),
              ),
            },
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildTextFormField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          if (keyboardType == TextInputType.emailAddress && value!.isNotEmpty) {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
          }
          return null;
        },
      ),
    );
  }

  void _confirmDelete() {
    Get.defaultDialog(
      title: 'Delete Supplier',
      content: const Text('Are you sure you want to delete this supplier? This action cannot be undone.'),
      confirm: ElevatedButton(
        onPressed: () async {
          Get.back(); // Close the dialog
          final success = await _controller.deleteSupplier(widget.supplier!.id!);
          if (success && mounted) {
            Get.back(); // Go back to previous screen
            Get.snackbar('Success', 'Supplier deleted successfully');
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: const Text('Delete'),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text('Cancel'),
      ),
    );
  }
}
