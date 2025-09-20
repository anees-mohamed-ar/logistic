import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/widgets/custom_app_bar.dart';
import 'package:logistic/api_config.dart';
import 'package:intl/intl.dart';
import 'package:logistic/models/state_model.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';

class DriverManagementPage extends StatefulWidget {
  const DriverManagementPage({Key? key}) : super(key: key);

  @override
  _DriverManagementPageState createState() => _DriverManagementPageState();
}

class _DriverManagementPageState extends State<DriverManagementPage> {
  final String baseUrl = '${ApiConfig.baseUrl}/driver';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dlNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _countryController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _panController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  DateTime? _selectedDob;
  
  List<Map<String, dynamic>> drivers = [];
  bool isLoading = true;
  bool isAddingDriver = false;
  bool isEditMode = false;
  String? editingDriverDlNumber;

  // State dropdown data
  List<StateModel> _states = [];
  bool _statesLoading = false;
  String? _statesError;
  StateModel? _selectedState;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
    _loadStates();
  }

  Widget _buildStateDropdown() {
    if (_statesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_statesError != null) {
      // Show a compact field label with a Retry button to refetch states
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'State *',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _loadStates,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      );
    }

    return SearchableDropdown<StateModel>(
      label: 'State *',
      value: _selectedState,
      isRequired: true,
      validator: (value) => value == null ? 'Please select a state' : null,
      items: _states
          .map((s) => DropdownMenuItem<StateModel>(
                value: s,
                child: Text(s.name),
              ))
          .toList(),
      onChanged: (StateModel? value) {
        setState(() {
          _selectedState = value;
        });
      },
    );
  }

  Future<void> _fetchDrivers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        if (responseData is List) {
          setState(() {
            // Map the response to the expected format
            drivers = responseData.map<Map<String, dynamic>>((driver) {
              return {
                'driverId': driver['driverId'],
                'driverName': driver['driverName'] ?? 'N/A',
                'driverAddress': driver['driverAddress'] ?? 'N/A',
                'district': driver['district'] ?? 'N/A',
                'state': driver['state'] ?? 'N/A',
                'country': driver['country']?.trim() ?? 'N/A',
                'dateofBirth': driver['dateofBirth'],
                'dlNumber': driver['dlNumber'] ?? 'N/A',
                'email': driver['email'] ?? 'N/A',
                'bloodGroup': driver['bloodGroup'] ?? 'N/A',
                'phoneNumber': driver['phoneNumber'] ?? 'N/A',
                'mobileNumber': driver['mobileNumber'] ?? 'N/A',
                'panNumber': driver['panNumber'] ?? 'N/A',
                'CompanyId': driver['CompanyId'] ?? 'N/A',
              };
            }).toList();
          });
        } else {
          Get.snackbar('Error', 'Invalid response format');
        }
      } else {
        final error = json.decode(response.body)['error'] ?? 'Failed to load drivers';
        Get.snackbar('Error', error);
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addOrUpdateDriver() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      Get.snackbar('Error', 'Please select date of birth');
      return;
    }
    if (_selectedState == null) {
      Get.snackbar('Error', 'Please select a State');
      return;
    }

    setState(() => isAddingDriver = true);
    
    try {
      final url = isEditMode 
          ? '$baseUrl/update/$editingDriverDlNumber' 
          : '$baseUrl/add';
          
      final method = isEditMode ? 'PUT' : 'POST';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'driverName': _nameController.text.trim(),
          'driverAddress': _addressController.text.trim(),
          'district': _districtController.text.trim(),
          'state': _selectedState?.name ?? '',
          'country': _countryController.text.trim(),
          'dateofBirth': DateFormat('yyyy-MM-dd').format(_selectedDob!),
          'dlNumber': _dlNumberController.text.trim(),
          'email': _emailController.text.trim(),
          'bloodGroup': _bloodGroupController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'mobileNumber': _mobileController.text.trim(),
          'panNumber': _panController.text.trim(),
          'CompanyId': Get.find<IdController>().companyId.value.toString(),
        }),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', isEditMode 
            ? 'Driver updated successfully' 
            : 'Driver added successfully');
        _resetForm();
        _fetchDrivers();
      } else {
        final error = json.decode(response.body)['error'] ?? 
            'Failed to ${isEditMode ? 'update' : 'add'} driver';
        Get.snackbar('Error', error.toString());
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      setState(() => isAddingDriver = false);
    }
  }

  void _editDriver(Map<String, dynamic> driver) {
    setState(() {
      isEditMode = true;
      editingDriverDlNumber = driver['dlNumber'];
      _nameController.text = driver['driverName'] ?? '';
      _dlNumberController.text = driver['dlNumber'] ?? '';
      _addressController.text = driver['driverAddress'] ?? '';
      _districtController.text = driver['district'] ?? '';
      final stName = (driver['state'] ?? '').toString();
      _selectedState = stName.isNotEmpty
          ? _states.firstWhere(
              (s) => s.name.toLowerCase() == stName.toLowerCase(),
              orElse: () => StateModel(id: 0, name: stName, code: '', tin: ''),
            )
          : null;
      _countryController.text = driver['country'] ?? '';
      if (driver['dateofBirth'] != null) {
        _selectedDob = DateTime.parse(driver['dateofBirth']);
      }
      _emailController.text = driver['email'] ?? '';
      _bloodGroupController.text = driver['bloodGroup'] ?? '';
      _phoneController.text = driver['phoneNumber'] ?? '';
      _mobileController.text = driver['mobileNumber'] ?? '';
      _panController.text = driver['panNumber'] ?? '';
    });
    
    // Scroll to form
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedDob = null;
      isEditMode = false;
      editingDriverDlNumber = null;
      _selectedState = null;
    });
  }

  Future<void> _loadStates() async {
    try {
      setState(() {
        _statesLoading = true;
        _statesError = null;
      });
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/state/search'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _states = data.map((e) => StateModel.fromJson(e)).toList();
        });
      } else {
        setState(() {
          _statesError = 'Failed to load states';
        });
      }
    } catch (e) {
      setState(() {
        _statesError = 'Failed to load states: $e';
      });
    } finally {
      setState(() {
        _statesLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() => _selectedDob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Driver Management',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Driver Form
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditMode ? 'Edit Driver' : 'Add New Driver',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Driver Name *'),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dlNumberController,
                        decoration: const InputDecoration(labelText: 'Driving License Number *'),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address *'),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _districtController,
                              decoration: const InputDecoration(labelText: 'District *'),
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStateDropdown(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(labelText: 'Country *'),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: _selectedDob != null
                                  ? DateFormat('dd-MM-yyyy').format(_selectedDob!)
                                  : '',
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth *',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            validator: (value) => _selectedDob == null ? 'Required' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Phone Number *'),
                              keyboardType: TextInputType.phone,
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _mobileController,
                              decoration: const InputDecoration(labelText: 'Mobile Number *'),
                              keyboardType: TextInputType.phone,
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _panController,
                              decoration: const InputDecoration(labelText: 'PAN Number'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _bloodGroupController,
                              decoration: const InputDecoration(labelText: 'Blood Group'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: isAddingDriver ? null : _addOrUpdateDriver,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: isAddingDriver
                                ? const CircularProgressIndicator()
                                : Text(isEditMode ? 'Update Driver' : 'Add Driver'),
                          ),
                          if (isEditMode) ...[
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _resetForm,
                              child: const Text('Cancel'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Drivers List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Driver List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${drivers.length} Drivers',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : drivers.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No drivers found'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: drivers.length,
                        itemBuilder: (context, index) {
                          final driver = drivers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                child: Text(
                                  (driver['driverName']?[0] ?? 'D').toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                driver['driverName'] ?? 'No Name',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'DL: ${driver['dlNumber'] ?? 'N/A'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editDriver(driver),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('Address', driver['driverAddress']),
                                      _buildDetailRow('District', driver['district']),
                                      _buildDetailRow('State', driver['state']),
                                      _buildDetailRow('Country', driver['country']),
                                      _buildDetailRow('Phone', driver['phoneNumber']),
                                      _buildDetailRow('Mobile', driver['mobileNumber']),
                                      _buildDetailRow('Email', driver['email']),
                                      _buildDetailRow('PAN', driver['panNumber']),
                                      _buildDetailRow('Blood Group', driver['bloodGroup']),
                                      if (driver['dateofBirth'] != null)
                                        _buildDetailRow(
                                          'Date of Birth',
                                          DateFormat('dd-MM-yyyy').format(
                                            DateTime.parse(driver['dateofBirth']),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const Text(': ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dlNumberController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _panController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }
}
