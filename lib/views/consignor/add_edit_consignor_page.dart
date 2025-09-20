import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/models/consignor.dart';
import 'package:logistic/controller/consignor_controller.dart';
import 'package:logistic/models/state_model.dart';
import 'package:logistic/services/state_service.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';
// State service import removed as we're using dummy data
import 'package:async/async.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logistic/services/state_service.dart';
// Search choices import removed


class AddEditConsignorPage extends StatefulWidget {
  final Consignor? consignor;

  const AddEditConsignorPage({super.key, this.consignor});

  @override
  _AddEditConsignorPageState createState() => _AddEditConsignorPageState();
}

class _AddEditConsignorPageState extends State<AddEditConsignorPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<ConsignorController>();
  late TextEditingController _consignorNameController;
  late TextEditingController _addressController;
  StateModel? _selectedState;
  final _statesCache = AsyncMemoizer<List<StateModel>>();
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

  bool get isEditing => widget.consignor != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadStates();
  }

  @override
  void dispose() {
    _statesLoading.close();
    _statesError.close();
    super.dispose();
  }

  Widget _buildStateDropdown() {
    print('Building state dropdown with ${_states.length} states');
    print('Selected state: ${_selectedState?.name}');
    
    // Ensure we have unique states by id
    final uniqueStates = <int, StateModel>{};
    for (var state in _states) {
      if (!uniqueStates.containsKey(state.id)) {
        uniqueStates[state.id] = state;
      } else {
        print('Duplicate state found: ${state.id} - ${state.name}');
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
      label: 'State',
      value: _selectedState,
      items: items,
      onChanged: (StateModel? newValue) {
        print('State changed to: ${newValue?.name}');
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

  Future<void> _loadStates() async {
    if (_states.isNotEmpty) return; // Already loaded
    
    try {
      _statesLoading.value = true;
      _statesError.value = '';
      
      print('Fetching states from API...');
      final url = Uri.parse('http://192.168.1.166:8080/state/search');
      print('URL: $url');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('Successfully parsed ${data.length} states');
          
          final states = data.map((state) => StateModel.fromJson(state)).toList();
          
          if (mounted) {
            setState(() {
              _states.clear();
              _states.addAll(states);
              print('Updated _states with ${_states.length} items');
              
              // If we're editing and have a consignor with a state, try to find a match
              if (widget.consignor?.state != null && widget.consignor!.state!.isNotEmpty) {
                try {
                  final matchingState = _states.firstWhere(
                    (state) => state.name.toLowerCase() == widget.consignor!.state!.toLowerCase(),
                    orElse: () => StateModel(id: 0, name: widget.consignor!.state!, code: '', tin: '')
                  );
                  
                  _selectedState = matchingState;
                  print('Found matching state for consignor: ${_selectedState?.name}');
                } catch (e) {
                  print('Error setting selected state: $e');
                }
              }
            });
          }
        } catch (e) {
          print('Error parsing response: $e');
          throw Exception('Failed to parse states: $e');
        }
      } else {
        throw Exception('Failed to load states. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('HTTP Client Exception: $e');
      _statesError.value = 'Network error: ${e.message}';
    } on FormatException catch (e) {
      print('Format Exception: $e');
      _statesError.value = 'Invalid data format: ${e.message}';
    } on TimeoutException {
      print('Request timed out');
      _statesError.value = 'Request timed out. Please check your connection.';
    } catch (e) {
      print('Unexpected error: $e');
      _statesError.value = 'Failed to load states: ${e.toString()}';
    } finally {
      _statesLoading.value = false;
      print('Finished loading states. Error: ${_statesError.value}');
    }
  }

  void _initializeForm() {
    final consignor = widget.consignor;
    
    // Initialize all controllers first
    _consignorNameController = TextEditingController(text: consignor?.consignorName ?? '');
    _addressController = TextEditingController(text: consignor?.address ?? '');
    _locationController = TextEditingController(text: consignor?.location ?? '');
    _districtController = TextEditingController(text: consignor?.district ?? '');
    _contactController = TextEditingController(text: consignor?.contact ?? '');
    _phoneNumberController = TextEditingController(text: consignor?.phoneNumber ?? '');
    _mobileNumberController = TextEditingController(text: consignor?.mobileNumber ?? '');
    _gstController = TextEditingController(text: consignor?.gst ?? '');
    _panNumberController = TextEditingController(text: consignor?.panNumber ?? '');
    _msmeNumberController = TextEditingController(text: consignor?.msmeNumber ?? '');
    _emailController = TextEditingController(text: consignor?.email ?? '');
    _cinNumberController = TextEditingController(text: consignor?.cinNumber ?? '');
    _compTypeController = TextEditingController(text: consignor?.compType ?? '');
    _industrialTypeController = TextEditingController(text: consignor?.industrialType ?? '');
    _faxController = TextEditingController(text: consignor?.fax ?? '');
    
    // Set the selected state after a small delay to ensure states are loaded
    if (consignor?.state != null && consignor!.state!.isNotEmpty) {
      // Wait for states to be loaded before trying to set the selected state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Try to find a matching state from the loaded states
          final matchingState = _states.firstWhere(
            (state) => state.name.toLowerCase() == consignor.state!.toLowerCase(),
            orElse: () => StateModel(id: 0, name: consignor.state!, code: '', tin: '')
          );
          
          setState(() {
            _selectedState = matchingState;
          });
          
          print('Set selected state to: ${_selectedState?.name}');
        }
      });
    }
  }

  // State dropdown controllers

  Future<void> _saveConsignor() async {
    if (!_formKey.currentState!.validate()) return;

    final consignor = Consignor(
      consignorName: _consignorNameController.text.trim(),
      address: _addressController.text.trim(),
      state: _selectedState?.name ?? '',
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
        success = await _controller.updateConsignor(widget.consignor!.consignorName, consignor);
      } else {
        success = await _controller.addConsignor(consignor);
      }

      if (success) {
        Get.back();
        Get.snackbar('Success', isEditing ? 'Consignor updated successfully' : 'Consignor added successfully');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Consignor' : 'Add Consignor'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField(_consignorNameController, 'Consignor Name *', TextInputType.text, (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter consignor name';
              }
              return null;
            }),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              maxLines: 4,
              minLines: 3,
              decoration: InputDecoration(
                labelText: 'Address *',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey[100],
              ),
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'State *',
                        style: Theme.of(context).inputDecorationTheme.labelStyle,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _buildStateDropdown(),
                      ),
                    ],
                  ),
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
              onPressed: _saveConsignor,
              child: Text(isEditing ? 'Update Consignor' : 'Add Consignor'),
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
