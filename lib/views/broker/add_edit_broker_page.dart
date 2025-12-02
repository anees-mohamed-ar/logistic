import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logistic/controller/broker_controller.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/models/broker.dart';
import 'package:logistic/models/state_model.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';
import 'package:logistic/api_config.dart';

class AddEditBrokerPage extends StatefulWidget {
  final Broker? broker;

  const AddEditBrokerPage({Key? key, this.broker}) : super(key: key);

  @override
  _AddEditBrokerPageState createState() => _AddEditBrokerPageState();
}

class _AddEditBrokerPageState extends State<AddEditBrokerPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<BrokerController>();
  final _idController = Get.find<IdController>();

  // Tab controller for sections
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Focus nodes for keyboard navigation
  final Map<String, FocusNode> _focusNodes = {};

  // State management
  final List<StateModel> _states = [];
  final RxBool _statesLoading = false.obs;
  final RxString _statesError = ''.obs;
  StateModel? _selectedState;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _countryController;
  late TextEditingController _commissionController;
  late TextEditingController _emailController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _phoneController;
  late TextEditingController _mobileController;
  late TextEditingController _panController;

  DateTime? _selectedDob;
  bool _isLoading = false;
  bool get isEditing => widget.broker != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _initializeFocusNodes();
    _initializeForm();
    _loadStates();
  }

  void _initializeFocusNodes() {
    final fields = [
      'brokerName', 'address', 'district', 'country', 'commission',
      'email', 'bloodGroup', 'phone', 'mobile', 'pan',
    ];

    for (var field in fields) {
      _focusNodes[field] = FocusNode();
    }
  }

  void _initializeForm() {
    final broker = widget.broker;

    _nameController = TextEditingController(text: broker?.brokerName ?? '');
    _addressController = TextEditingController(text: broker?.brokerAddress ?? '');
    _districtController = TextEditingController(text: broker?.district ?? '');
    _countryController = TextEditingController(text: broker?.country ?? '');
    _commissionController = TextEditingController(
      text: broker?.commissionPercentage.toString() ?? '',
    );
    _emailController = TextEditingController(text: broker?.email ?? '');
    _bloodGroupController = TextEditingController(text: broker?.bloodGroup ?? '');
    _phoneController = TextEditingController(text: broker?.phoneNumber ?? '');
    _mobileController = TextEditingController(text: broker?.mobileNumber ?? '');
    _panController = TextEditingController(text: broker?.panNumber ?? '');

    _selectedDob = broker?.dateofBirth != null
        ? DateTime.parse(broker!.dateofBirth!)
        : null;

    if (broker?.state != null && broker!.state.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _states.isNotEmpty) {
          final matchingState = _states.firstWhere(
                (state) => state.name.toLowerCase() == broker.state.toLowerCase(),
            orElse: () => StateModel(id: 0, name: broker.state, code: '', tin: ''),
          );
          setState(() {
            _selectedState = matchingState;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNodes.values.forEach((node) => node.dispose());
    _statesLoading.close();
    _statesError.close();
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

  Future<void> _loadStates() async {
    if (_states.isNotEmpty) return;

    try {
      _statesLoading.value = true;
      _statesError.value = '';

      final url = Uri.parse('${ApiConfig.baseUrl}/state/search');
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final states = data.map((state) => StateModel.fromJson(state)).toList();

        if (mounted) {
          setState(() {
            _states.clear();
            _states.addAll(states);

            if (widget.broker?.state != null && widget.broker!.state.isNotEmpty) {
              try {
                final matchingState = _states.firstWhere(
                      (state) =>
                  state.name.toLowerCase() ==
                      widget.broker!.state.toLowerCase(),
                  orElse: () => StateModel(
                    id: 0,
                    name: widget.broker!.state,
                    code: '',
                    tin: '',
                  ),
                );
                _selectedState = matchingState;
              } catch (e) {
                print('Error setting selected state: $e');
              }
            }
          });
        }
      } else {
        throw Exception('Failed to load states. Status: ${response.statusCode}');
      }
    } catch (e) {
      _statesError.value = 'Failed to load states: ${e.toString()}';
    } finally {
      _statesLoading.value = false;
    }
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    String? focusNodeKey,
    String? nextFocusNodeKey,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? minLines,
    bool required = false,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNodeKey != null ? _focusNodes[focusNodeKey] : null,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      textCapitalization: textCapitalization,
      textInputAction: nextFocusNodeKey != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocusNodeKey != null && _focusNodes[nextFocusNodeKey] != null) {
          FocusScope.of(context).requestFocus(_focusNodes[nextFocusNodeKey]);
        }
      },
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 14,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }

  Widget _buildStateDropdown() {
    final uniqueStates = <int, StateModel>{};
    for (var state in _states) {
      if (!uniqueStates.containsKey(state.id)) {
        uniqueStates[state.id] = state;
      }
    }

    final uniqueStatesList = uniqueStates.values.toList();

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

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: _selectedDob == null ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _saveBroker() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Validation Error',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedState == null) {
      Get.snackbar(
        'Error',
        'Please select a state',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    final broker = Broker(
      id: widget.broker?.id,
      brokerName: _nameController.text.trim(),
      brokerAddress: _addressController.text.trim(),
      district: _districtController.text.trim(),
      state: _selectedState!.name,
      country: _countryController.text.trim(),
      dateofBirth: _selectedDob?.toIso8601String(),
      commissionPercentage:
      double.tryParse(_commissionController.text.trim()) ?? 0.0,
      email: _emailController.text.trim(),
      bloodGroup: _bloodGroupController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      panNumber: _panController.text.trim(),
      companyId: int.tryParse(_idController.companyId.value) ?? 0,
    );

    try {
      bool success;
      if (isEditing) {
        success = await _controller.updateBroker(broker);
      } else {
        success = await _controller.addBroker(broker);
      }

      if (success && mounted) {
        Get.back(result: true);
        Get.snackbar(
          'Success',
          isEditing ? 'Broker updated successfully' : 'Broker added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedTextField(
            controller: _nameController,
            label: 'Broker Name',
            focusNodeKey: 'brokerName',
            nextFocusNodeKey: 'address',
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _addressController,
            label: 'Address',
            focusNodeKey: 'address',
            nextFocusNodeKey: 'district',
            maxLines: 4,
            minLines: 3,
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _districtController,
                  label: 'District',
                  focusNodeKey: 'district',
                  nextFocusNodeKey: 'country',
                  required: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _buildStateDropdown(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _countryController,
            label: 'Country',
            focusNodeKey: 'country',
            nextFocusNodeKey: 'commission',
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _commissionController,
            label: 'Commission Percentage',
            focusNodeKey: 'commission',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            required: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (double.tryParse(value!) == null) return 'Enter a valid number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDateField(
            label: 'Date of Birth',
            value: _selectedDob != null
                ? DateFormat('dd-MM-yyyy').format(_selectedDob!)
                : 'Select Date',
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _bloodGroupController,
            label: 'Blood Group',
            focusNodeKey: 'bloodGroup',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _panController,
            label: 'PAN Number',
            focusNodeKey: 'pan',
            nextFocusNodeKey: 'phone',
            textCapitalization: TextCapitalization.characters,
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  focusNodeKey: 'phone',
                  nextFocusNodeKey: 'mobile',
                  keyboardType: TextInputType.phone,
                  required: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _mobileController,
                  label: 'Mobile Number',
                  focusNodeKey: 'mobile',
                  nextFocusNodeKey: 'email',
                  keyboardType: TextInputType.phone,
                  required: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (value!.length < 10) return 'Invalid mobile number';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _emailController,
            label: 'Email',
            focusNodeKey: 'email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty && !GetUtils.isEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(isEditing ? 'Edit Broker' : 'Add Broker'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Basic Info'),
            Tab(icon: Icon(Icons.person), text: 'Personal'),
            Tab(icon: Icon(Icons.contact_phone), text: 'Contact'),
          ],
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _saveBroker,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('SAVE', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Saving broker...'),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentTabIndex + 1) / 3,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Step ${_currentTabIndex + 1} of 3',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildPersonalInfoTab(),
                  _buildContactInfoTab(),
                ],
              ),
            ),
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentTabIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _tabController.animateTo(_currentTabIndex - 1);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  if (_currentTabIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                        if (_currentTabIndex < 2) {
                          _tabController.animateTo(_currentTabIndex + 1);
                        } else {
                          _saveBroker();
                        }
                      },
                      icon: Icon(
                        _currentTabIndex < 2 ? Icons.arrow_forward : Icons.save,
                      ),
                      label: Text(
                        _currentTabIndex < 2
                            ? 'Next'
                            : (isEditing ? 'Update Broker' : 'Add Broker'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}