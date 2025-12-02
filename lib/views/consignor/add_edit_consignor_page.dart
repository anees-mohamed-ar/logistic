import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logistic/models/consignor.dart';
import 'package:logistic/controller/consignor_controller.dart';
import 'package:logistic/models/state_model.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';
import 'package:logistic/api_config.dart';
import 'package:async/async.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddEditConsignorPage extends StatefulWidget {
  final Consignor? consignor;

  const AddEditConsignorPage({super.key, this.consignor});

  @override
  _AddEditConsignorPageState createState() => _AddEditConsignorPageState();
}

class _AddEditConsignorPageState extends State<AddEditConsignorPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<ConsignorController>();

  // Tab controller for sections
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Focus nodes for keyboard navigation
  final Map<String, FocusNode> _focusNodes = {};

  // Controllers
  late TextEditingController _consignorNameController;
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

  bool _isLoading = false;
  bool get isEditing => widget.consignor != null;

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
      'consignorName', 'address', 'location', 'district', 'contact',
      'phoneNumber', 'mobileNumber', 'email', 'gst', 'panNumber',
      'msmeNumber', 'cinNumber', 'compType', 'industrialType', 'fax',
    ];

    for (var field in fields) {
      _focusNodes[field] = FocusNode();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNodes.values.forEach((node) => node.dispose());
    _statesLoading.close();
    _statesError.close();
    _consignorNameController.dispose();
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

            if (widget.consignor?.state != null &&
                widget.consignor!.state!.isNotEmpty) {
              try {
                final matchingState = _states.firstWhere(
                      (state) =>
                  state.name.toLowerCase() ==
                      widget.consignor!.state!.toLowerCase(),
                  orElse: () => StateModel(
                    id: 0,
                    name: widget.consignor!.state!,
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

  void _initializeForm() {
    final consignor = widget.consignor;

    _consignorNameController = TextEditingController(
      text: consignor?.consignorName ?? '',
    );
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

    if (consignor?.state != null && consignor!.state!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final matchingState = _states.firstWhere(
                (state) => state.name.toLowerCase() == consignor.state!.toLowerCase(),
            orElse: () => StateModel(id: 0, name: consignor.state!, code: '', tin: ''),
          );
          setState(() {
            _selectedState = matchingState;
          });
        }
      });
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

  Future<void> _saveConsignor() async {
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

    setState(() => _isLoading = true);

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
      msmeNumber: _msmeNumberController.text.trim().isNotEmpty
          ? _msmeNumberController.text.trim()
          : null,
      email: _emailController.text.trim(),
      cinNumber: _cinNumberController.text.trim().isNotEmpty
          ? _cinNumberController.text.trim()
          : null,
      compType: _compTypeController.text.trim().isNotEmpty
          ? _compTypeController.text.trim()
          : null,
      industrialType: _industrialTypeController.text.trim().isNotEmpty
          ? _industrialTypeController.text.trim()
          : null,
      fax: _faxController.text.trim().isNotEmpty
          ? _faxController.text.trim()
          : null,
    );

    try {
      bool success;
      if (isEditing) {
        success = await _controller.updateConsignor(
          widget.consignor!.consignorName,
          consignor,
        );
      } else {
        success = await _controller.addConsignor(consignor);
      }

      if (success && mounted) {
        Get.back(result: true);
        Get.snackbar(
          'Success',
          isEditing ? 'Consignor updated successfully' : 'Consignor added successfully',
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
            controller: _consignorNameController,
            label: 'Consignor Name',
            focusNodeKey: 'consignorName',
            nextFocusNodeKey: 'address',
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _addressController,
            label: 'Address',
            focusNodeKey: 'address',
            nextFocusNodeKey: 'location',
            maxLines: 4,
            minLines: 3,
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildStateDropdown(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _locationController,
                  label: 'Location',
                  focusNodeKey: 'location',
                  nextFocusNodeKey: 'district',
                  required: true,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _districtController,
                  label: 'District',
                  focusNodeKey: 'district',
                  nextFocusNodeKey: 'contact',
                ),
              ),
            ],
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
          _buildEnhancedTextField(
            controller: _contactController,
            label: 'Contact Person',
            focusNodeKey: 'contact',
            nextFocusNodeKey: 'phoneNumber',
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _phoneNumberController,
                  label: 'Phone Number',
                  focusNodeKey: 'phoneNumber',
                  nextFocusNodeKey: 'mobileNumber',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _mobileNumberController,
                  label: 'Mobile Number',
                  focusNodeKey: 'mobileNumber',
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
            nextFocusNodeKey: 'fax',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty && !GetUtils.isEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _faxController,
            label: 'Fax',
            focusNodeKey: 'fax',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildEnhancedTextField(
            controller: _gstController,
            label: 'GST Number',
            focusNodeKey: 'gst',
            nextFocusNodeKey: 'panNumber',
            textCapitalization: TextCapitalization.characters,
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _panNumberController,
            label: 'PAN Number',
            focusNodeKey: 'panNumber',
            nextFocusNodeKey: 'msmeNumber',
            textCapitalization: TextCapitalization.characters,
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _msmeNumberController,
            label: 'MSME Number',
            focusNodeKey: 'msmeNumber',
            nextFocusNodeKey: 'cinNumber',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _cinNumberController,
            label: 'CIN Number',
            focusNodeKey: 'cinNumber',
            nextFocusNodeKey: 'compType',
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _compTypeController,
            label: 'Company Type',
            focusNodeKey: 'compType',
            nextFocusNodeKey: 'industrialType',
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _industrialTypeController,
            label: 'Industrial Type',
            focusNodeKey: 'industrialType',
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
        title: Text(isEditing ? 'Edit Consignor' : 'Add Consignor'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Basic Info'),
            Tab(icon: Icon(Icons.contact_phone), text: 'Contact'),
            Tab(icon: Icon(Icons.description), text: 'Legal'),
          ],
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _saveConsignor,
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
            Text('Saving consignor...'),
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
                  _buildContactInfoTab(),
                  _buildLegalInfoTab(),
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
                          _saveConsignor();
                        }
                      },
                      icon: Icon(
                        _currentTabIndex < 2 ? Icons.arrow_forward : Icons.save,
                      ),
                      label: Text(
                        _currentTabIndex < 2
                            ? 'Next'
                            : (isEditing ? 'Update Consignor' : 'Add Consignor'),
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