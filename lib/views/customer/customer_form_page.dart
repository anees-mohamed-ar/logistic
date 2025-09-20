import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/controller/customer_controller.dart';
import 'package:logistic/models/customer_model.dart';
import 'package:logistic/models/state_model.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';
import 'package:logistic/api_config.dart';

class CustomerFormPage extends StatefulWidget {
  final Customer? customer;

  const CustomerFormPage({Key? key, this.customer}) : super(key: key);

  @override
  _CustomerFormPageState createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final CustomerController _controller = Get.find();
  
  // State management
  final _states = <StateModel>[].obs;
  final _statesLoading = false.obs;
  final _statesError = ''.obs;
  StateModel? _selectedState;
  
  // Controllers for form fields
  final _customerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _districtController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _gstController = TextEditingController();
  final _panNumberController = TextEditingController();
  final _msmeNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _cinNumberController = TextEditingController();
  final _compTypeController = TextEditingController();
  final _industrialTypeController = TextEditingController();
  final _faxController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _micrCodeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchCodeController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _companyIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final customer = widget.customer ?? Get.arguments as Customer?;
    if (customer != null) {
      _customerNameController.text = customer.customerName;
      _addressController.text = customer.address;
      _locationController.text = customer.location;
      _districtController.text = customer.district;
      _contactController.text = customer.contact;
      _phoneNumberController.text = customer.phoneNumber;
      _mobileNumberController.text = customer.mobileNumber;
      _gstController.text = customer.gst;
      _panNumberController.text = customer.panNumber;
      _msmeNumberController.text = customer.msmeNumber;
      _emailController.text = customer.email;
      _cinNumberController.text = customer.cinNumber;
      _compTypeController.text = customer.compType;
      _industrialTypeController.text = customer.industrialType;
      _faxController.text = customer.fax;
      _accountHolderNameController.text = customer.accountHolderName;
      _accountNumberController.text = customer.accountNumber;
      _ifscCodeController.text = customer.ifscCode;
      _micrCodeController.text = customer.micrCode;
      _bankNameController.text = customer.bankName;
      _branchCodeController.text = customer.branchCode;
      _branchNameController.text = customer.branchName;
      _companyIdController.text = customer.companyId;
    }
    _loadStates();
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
        final customer = widget.customer ?? Get.arguments as Customer?;
        if (customer != null && customer.state.isNotEmpty) {
          setState(() {
            _selectedState = _states.firstWhere(
              (state) => state.name.toLowerCase() == customer.state.toLowerCase(),
              orElse: () => StateModel(id: 0, name: customer.state, code: '', tin: '')
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
          setState(() {
            _selectedState = newValue;
          });
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
    _customerNameController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    _districtController.dispose();
    _contactController.dispose();
    _phoneNumberController.dispose();
    _mobileNumberController.dispose();
    _gstController.dispose();
    _panNumberController.dispose();
    _msmeNumberController.dispose();
    _emailController.dispose();
    _cinNumberController.dispose();
    _compTypeController.dispose();
    _industrialTypeController.dispose();
    _faxController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _micrCodeController.dispose();
    _bankNameController.dispose();
    _branchCodeController.dispose();
    _branchNameController.dispose();
    _companyIdController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _customerNameController.clear();
    _addressController.clear();
    setState(() => _selectedState = null);
    _locationController.clear();
    _districtController.clear();
    _contactController.clear();
    _phoneNumberController.clear();
    _mobileNumberController.clear();
    _gstController.clear();
    _panNumberController.clear();
    _msmeNumberController.clear();
    _emailController.clear();
    _cinNumberController.clear();
    _compTypeController.clear();
    _industrialTypeController.clear();
    _faxController.clear();
    _accountHolderNameController.clear();
    _accountNumberController.clear();
    _ifscCodeController.clear();
    _micrCodeController.clear();
    _bankNameController.clear();
    _branchCodeController.clear();
    _branchNameController.clear();
    _formKey.currentState?.reset();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedState == null) {
        Get.snackbar('Error', 'Please select a state');
        return;
      }
      
      final customer = Customer(
        id: widget.customer?.id,
        customerName: _customerNameController.text.trim(),
        address: _addressController.text.trim(),
        state: _selectedState!.name,
        location: _locationController.text.trim(),
        district: _districtController.text.trim(),
        contact: _contactController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        mobileNumber: _mobileNumberController.text.trim(),
        gst: _gstController.text.trim(),
        panNumber: _panNumberController.text.trim(),
        msmeNumber: _msmeNumberController.text.trim(),
        email: _emailController.text.trim(),
        cinNumber: _cinNumberController.text.trim(),
        compType: _compTypeController.text.trim(),
        industrialType: _industrialTypeController.text.trim(),
        fax: _faxController.text.trim(),
        companyId: _companyIdController.text.trim(),
        accountHolderName: _accountHolderNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscCodeController.text.trim(),
        micrCode: _micrCodeController.text.trim(),
        bankName: _bankNameController.text.trim(),
        branchCode: _branchCodeController.text.trim(),
        branchName: _branchNameController.text.trim(),
      );

      final isEditing = widget.customer != null || Get.arguments != null;
      final success = isEditing 
          ? await _controller.updateCustomer(customer)
          : await _controller.addCustomer(customer);
          
      if (success) {
        if (!isEditing) {
          _clearForm();
          Get.snackbar('Success', 'Customer added successfully',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.back(result: true);
        }
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer ?? Get.arguments as Customer?;
    final isEditing = customer != null;
    
    return MainLayout(
      title: isEditing ? 'Edit Customer' : 'Add New Customer',
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Basic Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Customer Name *',
                controller: _customerNameController,
                isRequired: true,
              ),
              _buildFormField(
                label: 'Address',
                controller: _addressController,
                maxLines: 2,
              ),
              _buildStateDropdown(),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Location',
                controller: _locationController,
              ),
              _buildFormField(
                label: 'District',
                controller: _districtController,
              ),
              _buildFormField(
                label: 'Contact Person',
                controller: _contactController,
              ),
              _buildFormField(
                label: 'Phone Number',
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
              ),
              _buildFormField(
                label: 'Mobile Number',
                controller: _mobileNumberController,
                keyboardType: TextInputType.phone,
              ),
              _buildFormField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildFormField(
                label: 'GST',
                controller: _gstController,
              ),
              _buildFormField(
                label: 'PAN Number',
                controller: _panNumberController,
              ),
              _buildFormField(
                label: 'MSME Number',
                controller: _msmeNumberController,
              ),
              _buildFormField(
                label: 'CIN Number',
                controller: _cinNumberController,
              ),
              _buildFormField(
                label: 'Company Type',
                controller: _compTypeController,
              ),
              _buildFormField(
                label: 'Industrial Type',
                controller: _industrialTypeController,
              ),
              _buildFormField(
                label: 'Fax',
                controller: _faxController,
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Bank Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Account Holder Name',
                controller: _accountHolderNameController,
              ),
              _buildFormField(
                label: 'Account Number',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
              ),
              _buildFormField(
                label: 'Bank Name',
                controller: _bankNameController,
              ),
              _buildFormField(
                label: 'Branch Name',
                controller: _branchNameController,
              ),
              _buildFormField(
                label: 'Branch Code',
                controller: _branchCodeController,
              ),
              _buildFormField(
                label: 'IFSC Code',
                controller: _ifscCodeController,
              ),
              _buildFormField(
                label: 'MICR Code',
                controller: _micrCodeController,
              ),
              
              const SizedBox(height: 24),
              Obx(() => _controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2A44),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEditing ? 'Update Customer' : 'Add Customer',
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
