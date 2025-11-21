import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/truck_controller.dart';
import 'package:logistic/models/truck.dart';
import 'package:logistic/widgets/custom_text_field.dart';
import 'package:logistic/widgets/loading_indicator.dart';

class TruckFormPage extends StatefulWidget {
  final Truck? truck;

  const TruckFormPage({super.key, this.truck});

  @override
  State<TruckFormPage> createState() => _TruckFormPageState();
}

class _TruckFormPageState extends State<TruckFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TruckController _controller;
  late Truck _truck;
  bool _isLoading = false;

  // Controllers
  final _ownerNameController = TextEditingController();
  final _ownerAddressController = TextEditingController();
  final _ownerMobileController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPanController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _lorryWeightController = TextEditingController();
  final _unladenWeightController = TextEditingController();
  final _overWeightController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _chassisNumberController = TextEditingController();
  final _roadTaxNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _micrCodeController = TextEditingController();
  final _branchCodeController = TextEditingController();
  final _insuranceController = TextEditingController();

  // Date fields
  DateTime? _roadTaxExpDate;
  DateTime? _insuranceExpDate;
  DateTime? _fcDate;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<TruckController>();

    // If a truck was passed in, make a copy of it to avoid modifying the original
    if (widget.truck != null) {
      print('📝 Initializing form with existing truck data');
      print('   - Vehicle Number: ${widget.truck!.vechileNumber}');
      print('   - Owner Name: ${widget.truck!.ownerName}');

      _truck = Truck(
        id: widget.truck!.id,
        ownerName: widget.truck!.ownerName,
        ownerAddress: widget.truck!.ownerAddress,
        ownerMobileNumber: widget.truck!.ownerMobileNumber,
        ownerEmail: widget.truck!.ownerEmail,
        ownerPanNumber: widget.truck!.ownerPanNumber,
        vechileNumber: widget.truck!.vechileNumber,
        typeofVechile: widget.truck!.typeofVechile,
        lorryWeight: widget.truck!.lorryWeight,
        unladenWeight: widget.truck!.unladenWeight,
        overWeight: widget.truck!.overWeight,
        engineeNumber: widget.truck!.engineeNumber,
        chaseNumber: widget.truck!.chaseNumber,
        roadTaxNumber: widget.truck!.roadTaxNumber,
        roadTaxExpDate: widget.truck!.roadTaxExpDate,
        bankName: widget.truck!.bankName,
        branchName: widget.truck!.branchName,
        accountNumber: widget.truck!.accountNumber,
        accountHolderName: widget.truck!.accountHolderName,
        ifscCode: widget.truck!.ifscCode,
        micrCode: widget.truck!.micrCode,
        branchCode: widget.truck!.branchCode,
        insurance: widget.truck!.insurance,
        insuranceExpDate: widget.truck!.insuranceExpDate,
        fcDate: widget.truck!.fcDate,
        companyId: widget.truck!.companyId,
      );
    } else {
      print('🆕 Initializing form for new truck');
      // Create a new empty truck
      _truck = Truck(
        id: null,
        ownerName: '',
        ownerAddress: '',
        ownerMobileNumber: null,
        ownerEmail: null,
        ownerPanNumber: null,
        vechileNumber: '',
        typeofVechile: null,
        lorryWeight: null,
        unladenWeight: null,
        overWeight: null,
        engineeNumber: null,
        chaseNumber: null,
        roadTaxNumber: null,
        roadTaxExpDate: null,
        bankName: null,
        branchName: null,
        accountNumber: null,
        accountHolderName: null,
        ifscCode: null,
        micrCode: null,
        branchCode: null,
        insurance: null,
        insuranceExpDate: null,
        fcDate: null,
        companyId: null,
      );
    }

    // Initialize form fields after setting up the truck object
    _initializeForm();
  }

  void _initializeForm() {
    print('🔄 Initializing form with truck data:');
    print('   - ID: ${_truck.id}');
    print('   - Vehicle Number: ${_truck.vechileNumber}');
    print('   - Owner Name: ${_truck.ownerName}');

    // Reset all controllers to empty first
    _ownerNameController.clear();
    _ownerAddressController.clear();
    _ownerMobileController.clear();
    _ownerEmailController.clear();
    _ownerPanController.clear();
    _vehicleNumberController.clear();
    _vehicleTypeController.clear();
    _lorryWeightController.clear();
    _unladenWeightController.clear();
    _overWeightController.clear();
    _engineNumberController.clear();
    _chassisNumberController.clear();
    _roadTaxNumberController.clear();
    _bankNameController.clear();
    _branchNameController.clear();
    _accountNumberController.clear();
    _accountHolderNameController.clear();
    _ifscCodeController.clear();
    _micrCodeController.clear();
    _branchCodeController.clear();
    _insuranceController.clear();

    // Set values from truck object
    _ownerNameController.text = _truck.ownerName;
    _ownerAddressController.text = _truck.ownerAddress;
    _ownerMobileController.text = _truck.ownerMobileNumber ?? '';
    _ownerEmailController.text = _truck.ownerEmail ?? '';
    _ownerPanController.text = _truck.ownerPanNumber ?? '';
    _vehicleNumberController.text = _truck.vechileNumber;
    _vehicleTypeController.text = _truck.typeofVechile ?? '';
    _lorryWeightController.text = _truck.lorryWeight?.toString() ?? '';
    _unladenWeightController.text = _truck.unladenWeight?.toString() ?? '';
    _overWeightController.text = _truck.overWeight?.toString() ?? '';
    _engineNumberController.text = _truck.engineeNumber ?? '';
    _chassisNumberController.text = _truck.chaseNumber ?? '';
    _roadTaxNumberController.text = _truck.roadTaxNumber ?? '';
    if (_truck.roadTaxExpDate != null) {
      _roadTaxExpDate = DateTime.tryParse(_truck.roadTaxExpDate!);
    }
    _bankNameController.text = _truck.bankName ?? '';
    _branchNameController.text = _truck.branchName ?? '';
    _accountNumberController.text = _truck.accountNumber ?? '';
    _accountHolderNameController.text = _truck.accountHolderName ?? '';
    _ifscCodeController.text = _truck.ifscCode ?? '';
    _micrCodeController.text = _truck.micrCode ?? '';
    _branchCodeController.text = _truck.branchCode ?? '';
    _insuranceController.text = _truck.insurance ?? '';
    if (_truck.insuranceExpDate != null) {
      _insuranceExpDate = DateTime.tryParse(_truck.insuranceExpDate!);
    }
    if (_truck.fcDate != null) {
      _fcDate = DateTime.tryParse(_truck.fcDate!);
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, onDateSelected),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
            ),
            child: Text(
              selectedDate != null
                  ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                  : 'Select Date',
              style: TextStyle(
                color: selectedDate != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerAddressController.dispose();
    _ownerMobileController.dispose();
    _ownerEmailController.dispose();
    _ownerPanController.dispose();
    _vehicleNumberController.dispose();
    _vehicleTypeController.dispose();
    _lorryWeightController.dispose();
    _unladenWeightController.dispose();
    _overWeightController.dispose();
    _engineNumberController.dispose();
    _chassisNumberController.dispose();
    _roadTaxNumberController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderNameController.dispose();
    _ifscCodeController.dispose();
    _micrCodeController.dispose();
    _branchCodeController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }

  Future<void> _saveTruck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicleNumber = _vehicleNumberController.text.trim();
      print('🚛 Saving truck - Vehicle Number: $vehicleNumber');

      final truck = Truck(
        id: _truck.id, // This will be null for new trucks
        ownerName: _ownerNameController.text.trim(),
        ownerAddress: _ownerAddressController.text.trim(),
        ownerMobileNumber: _ownerMobileController.text.trim().isNotEmpty
            ? _ownerMobileController.text.trim()
            : null,
        ownerEmail: _ownerEmailController.text.trim().isNotEmpty
            ? _ownerEmailController.text.trim()
            : null,
        ownerPanNumber: _ownerPanController.text.trim().isNotEmpty
            ? _ownerPanController.text.trim()
            : null,
        vechileNumber: _vehicleNumberController.text.trim(),
        typeofVechile: _vehicleTypeController.text.trim().isNotEmpty
            ? _vehicleTypeController.text.trim()
            : null,
        lorryWeight: double.tryParse(_lorryWeightController.text),
        unladenWeight: double.tryParse(_unladenWeightController.text),
        overWeight: double.tryParse(_overWeightController.text),
        engineeNumber: _engineNumberController.text.trim().isNotEmpty
            ? _engineNumberController.text.trim()
            : null,
        chaseNumber: _chassisNumberController.text.trim().isNotEmpty
            ? _chassisNumberController.text.trim()
            : null,
        roadTaxNumber: _roadTaxNumberController.text.trim().isNotEmpty
            ? _roadTaxNumberController.text.trim()
            : null,
        roadTaxExpDate: _roadTaxExpDate?.toIso8601String(),
        bankName: _bankNameController.text.trim().isNotEmpty
            ? _bankNameController.text.trim()
            : null,
        branchName: _branchNameController.text.trim().isNotEmpty
            ? _branchNameController.text.trim()
            : null,
        accountNumber: _accountNumberController.text.trim().isNotEmpty
            ? _accountNumberController.text.trim()
            : null,
        accountHolderName: _accountHolderNameController.text.trim().isNotEmpty
            ? _accountHolderNameController.text.trim()
            : null,
        ifscCode: _ifscCodeController.text.trim().isNotEmpty
            ? _ifscCodeController.text.trim()
            : null,
        micrCode: _micrCodeController.text.trim().isNotEmpty
            ? _micrCodeController.text.trim()
            : null,
        branchCode: _branchCodeController.text.trim().isNotEmpty
            ? _branchCodeController.text.trim()
            : null,
        insurance: _insuranceController.text.trim().isNotEmpty
            ? _insuranceController.text.trim()
            : null,
        insuranceExpDate: _insuranceExpDate?.toIso8601String(),
        fcDate: _fcDate?.toIso8601String(),
        companyId: _truck.companyId,
      );
      final bool isEdit = widget.truck != null;
      final String? originalVehicleNumber = widget.truck?.vechileNumber;
      print('🧭 _saveTruck: isEdit = $isEdit');

      bool success;
      if (isEdit) {
        print(
          '🔄 _saveTruck: calling updateTruck for ${truck.vechileNumber} (old: $originalVehicleNumber)',
        );
        success = await _controller.updateTruck(
          truck,
          oldVehicleNumber: originalVehicleNumber,
        );
        print('✅ _saveTruck: updateTruck returned $success');
        if (success && mounted) {
          print('🎯 _saveTruck: inside success branch for update');
          Get.back(result: true);
        } else {
          print(
            '⚠️ _saveTruck: updateTruck did not succeed or widget not mounted',
          );
        }
      } else {
        print('➕ Adding new truck with vehicle number: ${truck.vechileNumber}');
        success = await _controller.addTruck(truck);
        if (success && mounted) {
          Get.snackbar(
            'Success',
            'Truck added successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
          _truck = Truck(
            id: null,
            ownerName: '',
            ownerAddress: '',
            ownerMobileNumber: null,
            ownerEmail: null,
            ownerPanNumber: null,
            vechileNumber: '',
            typeofVechile: null,
            lorryWeight: null,
            unladenWeight: null,
            overWeight: null,
            engineeNumber: null,
            chaseNumber: null,
            roadTaxNumber: null,
            roadTaxExpDate: null,
            bankName: null,
            branchName: null,
            accountNumber: null,
            accountHolderName: null,
            ifscCode: null,
            micrCode: null,
            branchCode: null,
            insurance: null,
            insuranceExpDate: null,
            fcDate: null,
            companyId: null,
          );
          _roadTaxExpDate = null;
          _insuranceExpDate = null;
          _fcDate = null;
          _initializeForm();
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save truck: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        title: Text(
          widget.truck == null ? 'Add New Truck' : 'Edit Truck Details',
        ),
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTruck,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Owner Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  CustomTextField(
                    controller: _ownerNameController,
                    label: 'Owner Name *',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter owner name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _ownerAddressController,
                    label: 'Address *',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _ownerMobileController,
                    label: 'Mobile Number *',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter mobile number';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _ownerEmailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _ownerPanController,
                    label: 'PAN Number',
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Vehicle Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  CustomTextField(
                    controller: _vehicleNumberController,
                    label: 'Vehicle Number *',
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter vehicle number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _vehicleTypeController,
                    label: 'Vehicle Type',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _lorryWeightController,
                          label: 'Lorry Weight (kg)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _unladenWeightController,
                          label: 'Unladen Weight (kg)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _overWeightController,
                          label: 'Over Weight (kg)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _engineNumberController,
                    label: 'Engine Number',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _chassisNumberController,
                    label: 'Chassis Number',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Document Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  CustomTextField(
                    controller: _roadTaxNumberController,
                    label: 'Road Tax Number',
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    label: 'Road Tax Expiry Date',
                    selectedDate: _roadTaxExpDate,
                    onDateSelected: (date) {
                      setState(() {
                        _roadTaxExpDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _insuranceController,
                    label: 'Insurance Number',
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    label: 'Insurance Expiry Date',
                    selectedDate: _insuranceExpDate,
                    onDateSelected: (date) {
                      setState(() {
                        _insuranceExpDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDateField(
                    label: 'FC Date',
                    selectedDate: _fcDate,
                    onDateSelected: (date) {
                      setState(() {
                        _fcDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bank Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  CustomTextField(
                    controller: _bankNameController,
                    label: 'Bank Name',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _branchNameController,
                    label: 'Branch Name',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _accountNumberController,
                    label: 'Account Number',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _accountHolderNameController,
                    label: 'Account Holder Name',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _ifscCodeController,
                          label: 'IFSC Code',
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _micrCodeController,
                          label: 'MICR Code',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _branchCodeController,
                    label: 'Branch Code',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2A44),
                      ),
                      onPressed: _isLoading ? null : _saveTruck,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('SAVE TRUCK DETAILS'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
