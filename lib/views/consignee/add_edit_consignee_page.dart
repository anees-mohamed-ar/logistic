import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/controller/consignee_controller.dart';
import 'package:logistic/models/consignee.dart';
import 'package:logistic/models/state_model.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';

class AddEditConsigneePage extends StatefulWidget {
  final Consignee? consignee;

  const AddEditConsigneePage({super.key, this.consignee});

  @override
  _AddEditConsigneePageState createState() => _AddEditConsigneePageState();
}

class _AddEditConsigneePageState extends State<AddEditConsigneePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<ConsigneeController>();
  late TextEditingController _consigneeNameController;
  late TextEditingController _addressController;
  StateModel? _selectedState;
  final List<StateModel> _states = [];
  final RxBool _statesLoading = false.obs;
  final RxString _statesError = ''.obs;
  late TextEditingController _locationController;
  late TextEditingController _districtController;
  late TextEditingController _contactController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _gstController;
  late TextEditingController _panNumberController;
  late TextEditingController _msmeNumberController;
  late TextEditingController _emailController;
  late TextEditingController _cinNumberController;
  late TextEditingController _compTypeController;
  late TextEditingController _industrialTypeController;
  late TextEditingController _faxController;

  bool get isEditing => widget.consignee != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadStates();
  }

  void _initializeForm() {
    final consignee = widget.consignee;
    _consigneeNameController = TextEditingController(text: consignee?.consigneeName ?? '');
    _addressController = TextEditingController(text: consignee?.address ?? '');
    _locationController = TextEditingController(text: consignee?.location ?? '');
    
    // Set selected state if editing
    if (consignee?.state != null) {
      _selectedState = _states.firstWhere(
        (state) => state.name.toLowerCase() == consignee!.state!.toLowerCase(),
        orElse: () => StateModel(id: 0, name: consignee!.state!, code: '', tin: '')
      );
    }
    _districtController = TextEditingController(text: consignee?.district ?? '');
    _contactController = TextEditingController(text: consignee?.contact ?? '');
    _phoneNumberController = TextEditingController(text: consignee?.phoneNumber ?? '');
    _mobileNumberController = TextEditingController(text: consignee?.mobileNumber ?? '');
    _gstController = TextEditingController(text: consignee?.gst ?? '');
    _panNumberController = TextEditingController(text: consignee?.panNumber ?? '');
    _msmeNumberController = TextEditingController(text: consignee?.msmeNumber ?? '');
    _emailController = TextEditingController(text: consignee?.email ?? '');
    _cinNumberController = TextEditingController(text: consignee?.cinNumber ?? '');
    _compTypeController = TextEditingController(text: consignee?.compType ?? '');
    _industrialTypeController = TextEditingController(text: consignee?.industrialType ?? '');
    _faxController = TextEditingController(text: consignee?.fax ?? '');
  }

  @override
  @override
  void dispose() {
    _statesLoading.close();
    _statesError.close();
    _consigneeNameController.dispose();
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
    super.dispose();
  }

  Future<void> _loadStates() async {
    if (_states.isNotEmpty) return; // Already loaded
    
    try {
      _statesLoading.value = true;
      _statesError.value = '';
      
      print('Fetching states from API...');
      final url = Uri.parse('http://192.168.1.166:8080/state/search');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          final states = data.map((state) => StateModel.fromJson(state)).toList();
          
          if (mounted) {
            setState(() {
              _states.clear();
              _states.addAll(states);
              
              // If we're editing and have a consignee with a state, try to find a match
              if (widget.consignee?.state != null && widget.consignee!.state!.isNotEmpty) {
                try {
                  _selectedState = _states.firstWhere(
                    (state) => state.name.toLowerCase() == widget.consignee!.state!.toLowerCase(),
                    orElse: () => StateModel(id: 0, name: widget.consignee!.state!, code: '', tin: '')
                  );
                } catch (e) {
                  print('Error setting selected state: $e');
                }
              }
            });
          }
        } catch (e) {
          throw Exception('Failed to parse states: $e');
        }
      } else {
        throw Exception('Failed to load states. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      _statesError.value = 'Network error: ${e.message}';
    } on FormatException catch (e) {
      _statesError.value = 'Invalid data format: ${e.message}';
    } on TimeoutException {
      _statesError.value = 'Request timed out. Please check your connection.';
    } catch (e) {
      _statesError.value = 'Failed to load states: ${e.toString()}';
    } finally {
      _statesLoading.value = false;
    }
  }

  Widget _buildStateDropdown() {
    // Ensure we have unique states by id
    final uniqueStates = <int, StateModel>{};
    for (var state in _states) {
      if (!uniqueStates.containsKey(state.id)) {
        uniqueStates[state.id] = state;
      }
    }
    
    final uniqueStatesList = uniqueStates.values.toList();
    
    // If we have a selected state but it's not in our unique list, clear it
    if (_selectedState != null && 
        !uniqueStatesList.any((state) => state.id == _selectedState!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedState = null;
          });
        }
      });
    }

    // Create dropdown items with unique values
    final items = uniqueStatesList.map<DropdownMenuItem<StateModel>>((state) {
      return DropdownMenuItem<StateModel>(
        value: state,
        child: Text(state.name),
      );
    }).toList();

    return SearchableDropdown<StateModel>(
      label: 'State *',
      value: _selectedState,
      items: items,
      onChanged: (StateModel? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedState = newValue;
          });
        }
      },
      isLoading: _statesLoading.value,
      error: _statesError.value,
      onRetry: _loadStates,
      isRequired: true,
    );
  }

  Future<void> _saveConsignee() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      Get.snackbar('Error', 'Please select a state');
      return;
    }

    final consignee = Consignee(
      consigneeName: _consigneeNameController.text.trim(),
      address: _addressController.text.trim(),
      state: _selectedState!.name,
      location: _locationController.text.trim(),
      district: _districtController.text.trim(),
      contact: _contactController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      mobileNumber: _mobileNumberController.text.trim(),
      gst: _gstController.text.trim(),
      panNumber: _panNumberController.text.trim(),
      msmeNumber: _msmeNumberController.text.trim().isNotEmpty ? _msmeNumberController.text.trim() : null,
      email: _emailController.text.trim(),
      cinNumber: _cinNumberController.text.trim().isNotEmpty ? _cinNumberController.text.trim() : null,
      compType: _compTypeController.text.trim().isNotEmpty ? _compTypeController.text.trim() : null,
      industrialType: _industrialTypeController.text.trim().isNotEmpty ? _industrialTypeController.text.trim() : null,
      fax: _faxController.text.trim().isNotEmpty ? _faxController.text.trim() : null,
    );

    try {
      bool success;
      if (isEditing) {
        success = await _controller.updateConsignee(widget.consignee!.consigneeName, consignee);
      } else {
        success = await _controller.addConsignee(consignee);
      }

      if (success) {
        Get.back();
        Get.snackbar('Success', isEditing ? 'Consignee updated successfully' : 'Consignee added successfully');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Consignee' : 'Add Consignee'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField(_consigneeNameController, 'Consignee Name *', TextInputType.text, (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter consignee name';
              }
              return null;
            }),
            const SizedBox(height: 8),
            _buildTextField(_addressController, 'Address *', TextInputType.streetAddress, (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter address';
              }
              return null;
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStateDropdown(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(_districtController, 'District', TextInputType.text, null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(_locationController, 'Location *', TextInputType.text, (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter location';
              }
              return null;
            }),
            const SizedBox(height: 8),
            _buildTextField(_contactController, 'Contact Person *', TextInputType.text, (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter contact person';
              }
              return null;
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_phoneNumberController, 'Phone', TextInputType.phone, null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(_mobileNumberController, 'Mobile *', TextInputType.phone, (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    return null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(_emailController, 'Email', TextInputType.emailAddress, (value) {
              if (value != null && value.isNotEmpty && !GetUtils.isEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            }),
            const SizedBox(height: 8),
            _buildTextField(_gstController, 'GST Number *', TextInputType.text, (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter GST number';
              }
              return null;
            }),
            const SizedBox(height: 8),
            _buildTextField(_panNumberController, 'PAN Number *', TextInputType.text, (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter PAN number';
              }
              return null;
            }),
            const SizedBox(height: 8),
            _buildTextField(_msmeNumberController, 'MSME Number', TextInputType.text, null),
            const SizedBox(height: 8),
            _buildTextField(_cinNumberController, 'CIN Number', TextInputType.text, null),
            const SizedBox(height: 8),
            _buildTextField(_compTypeController, 'Company Type', TextInputType.text, null),
            const SizedBox(height: 8),
            _buildTextField(_industrialTypeController, 'Industrial Type', TextInputType.text, null),
            const SizedBox(height: 8),
            _buildTextField(_faxController, 'Fax', TextInputType.text, null),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveConsignee,
              child: Text(isEditing ? 'Update Consignee' : 'Add Consignee'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type, FormFieldValidator<String>? validator) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        filled: true,
        fillColor: Colors.grey[100],
      ),
      keyboardType: type,
      validator: validator,
    );
  }
}
