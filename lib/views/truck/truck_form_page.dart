import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/truck_controller.dart';
import 'package:logistic/models/truck.dart';
import 'package:logistic/widgets/custom_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logistic/api_config.dart';

class TruckFormPage extends StatefulWidget {
  final Truck? truck;

  const TruckFormPage({super.key, this.truck});

  @override
  State<TruckFormPage> createState() => _TruckFormPageState();
}

class _TruckFormPageState extends State<TruckFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TruckController _controller;
  late Truck _truck;
  bool _isLoading = false;

  // Tab controller for sections
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Focus nodes for keyboard navigation
  final Map<String, FocusNode> _focusNodes = {};

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

  List<PlatformFile> _attachments = [];
  List<Map<String, dynamic>> _existingAttachments = [];
  bool _isLoadingExistingAttachments = false;
  String? _existingAttachmentsError;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<TruckController>();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _initializeFocusNodes();

    if (widget.truck != null) {
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

    _initializeForm();

    if (widget.truck != null && _truck.vechileNumber.isNotEmpty) {
      _fetchExistingAttachments();
    }
  }

  void _initializeFocusNodes() {
    final fields = [
      'ownerName',
      'ownerAddress',
      'ownerMobile',
      'ownerEmail',
      'ownerPan',
      'vehicleNumber',
      'vehicleType',
      'lorryWeight',
      'unladenWeight',
      'overWeight',
      'engineNumber',
      'chassisNumber',
      'roadTaxNumber',
      'insurance',
      'bankName',
      'branchName',
      'accountNumber',
      'accountHolderName',
      'ifscCode',
      'micrCode',
      'branchCode',
    ];

    for (var field in fields) {
      _focusNodes[field] = FocusNode();
    }
  }

  void _initializeForm() {
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
    _bankNameController.text = _truck.bankName ?? '';
    _branchNameController.text = _truck.branchName ?? '';
    _accountNumberController.text = _truck.accountNumber ?? '';
    _accountHolderNameController.text = _truck.accountHolderName ?? '';
    _ifscCodeController.text = _truck.ifscCode ?? '';
    _micrCodeController.text = _truck.micrCode ?? '';
    _branchCodeController.text = _truck.branchCode ?? '';
    _insuranceController.text = _truck.insurance ?? '';

    if (_truck.roadTaxExpDate != null) {
      _roadTaxExpDate = DateTime.tryParse(_truck.roadTaxExpDate!);
    }
    if (_truck.insuranceExpDate != null) {
      _insuranceExpDate = DateTime.tryParse(_truck.insuranceExpDate!);
    }
    if (_truck.fcDate != null) {
      _fcDate = DateTime.tryParse(_truck.fcDate!);
    }
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachments = result.files;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick attachments: ${e.toString()}');
    }
  }

  Future<void> _fetchExistingAttachments() async {
    setState(() {
      _isLoadingExistingAttachments = true;
      _existingAttachmentsError = null;
    });

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/truckmaster/attachments/${Uri.encodeComponent(_truck.vechileNumber)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['attachments'] as List<dynamic>? ?? [];

        setState(() {
          _existingAttachments = list
              .map(
                (a) => {
                  'name': a['originalName']?.toString() ?? 'Unknown',
                  'filename': a['filename']?.toString() ?? '',
                  'size': a['size'] ?? 0,
                  'type': a['mimeType']?.toString() ?? 'unknown',
                  'uploadedAt': a['uploadDate']?.toString() ?? '',
                },
              )
              .toList();
          _isLoadingExistingAttachments = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _existingAttachments = [];
          _isLoadingExistingAttachments = false;
          _existingAttachmentsError = 'No attachments found';
        });
      } else {
        setState(() {
          _isLoadingExistingAttachments = false;
          _existingAttachmentsError = 'Failed to load attachments';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingExistingAttachments = false;
        _existingAttachmentsError = 'Error loading attachments';
      });
    }
  }

  Future<void> _previewExistingAttachment(String filename) async {
    try {
      final url = '${ApiConfig.baseUrl}/truckmaster/attachments/file/$filename';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(
          msg: 'Cannot open file',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error opening file',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _downloadExistingAttachment(
    String filename,
    String originalName,
  ) async {
    // Same implementation as before
    Directory? downloadDir;

    try {
      final url =
          '${ApiConfig.baseUrl}/truckmaster/attachments/file/$filename/download';

      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('Invalid URL format');
      }

      if (Platform.isAndroid) {
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Storage Permission'),
            content: const Text('Allow storage access to download files?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Allow'),
              ),
            ],
          ),
        );

        if (shouldRequest != true) return;

        PermissionStatus status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }

        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Storage permission required'),
                action: status.isPermanentlyDenied
                    ? SnackBarAction(
                        label: 'Settings',
                        onPressed: () => openAppSettings(),
                      )
                    : null,
              ),
            );
          }
          return;
        }
      }

      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      final fileName = 'TRUCK_${_truck.vechileNumber}_$originalName';
      final filePath = '${downloadDir?.path}/$fileName';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading...'),
              ],
            ),
          ),
        );
      }

      final dio = Dio();
      await dio.download(url, filePath);

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Downloaded: $fileName')));
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('pdf')) return Icons.picture_as_pdf;
    if (lowerType.contains('image')) return Icons.image;
    if (lowerType.contains('doc')) return Icons.description;
    if (lowerType.contains('excel') || lowerType.contains('sheet')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('pdf')) return Colors.red;
    if (lowerType.contains('image')) return Colors.blue;
    if (lowerType.contains('doc')) return Colors.blue.shade700;
    if (lowerType.contains('excel') || lowerType.contains('sheet')) {
      return Colors.green;
    }
    return Colors.grey;
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
    bool required = false,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, onDateSelected),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : 'Select date',
          style: TextStyle(
            color: selectedDate != null ? Colors.black87 : Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    String? focusNodeKey,
    String? nextFocusNodeKey,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNodeKey != null ? _focusNodes[focusNodeKey] : null,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      textInputAction: nextFocusNodeKey != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocusNodeKey != null && _focusNodes[nextFocusNodeKey] != null) {
          FocusScope.of(context).requestFocus(_focusNodes[nextFocusNodeKey]);
        }
      },
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E2A44), width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNodes.values.forEach((node) => node.dispose());
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

    try {
      final truck = Truck(
        id: _truck.id,
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
      bool success;

      if (isEdit) {
        success = await _controller.updateTruck(
          truck,
          oldVehicleNumber: widget.truck?.vechileNumber,
          attachments: _attachments,
        );
        if (success && mounted) {
          Get.snackbar(
            'Success',
            'Truck updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Navigator.of(context).pop(true);
        }
      } else {
        success = await _controller.addTruck(truck, attachments: _attachments);
        if (success && mounted) {
          Get.snackbar(
            'Success',
            'Truck added successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          // _resetForm();
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
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
    _attachments = [];
    _initializeForm();
  }

  Widget _buildOwnerDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedTextField(
            controller: _ownerNameController,
            label: 'Owner Name',
            focusNodeKey: 'ownerName',
            nextFocusNodeKey: 'ownerAddress',
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _ownerAddressController,
            label: 'Address',
            focusNodeKey: 'ownerAddress',
            nextFocusNodeKey: 'ownerMobile',
            maxLines: 3,
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _ownerMobileController,
            label: 'Mobile Number',
            focusNodeKey: 'ownerMobile',
            nextFocusNodeKey: 'ownerEmail',
            keyboardType: TextInputType.phone,
            required: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (value!.length < 10) return 'Invalid mobile number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _ownerEmailController,
            label: 'Email',
            focusNodeKey: 'ownerEmail',
            nextFocusNodeKey: 'ownerPan',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _ownerPanController,
            label: 'PAN Number',
            focusNodeKey: 'ownerPan',
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildEnhancedTextField(
            controller: _vehicleNumberController,
            label: 'Vehicle Number',
            focusNodeKey: 'vehicleNumber',
            nextFocusNodeKey: 'vehicleType',
            textCapitalization: TextCapitalization.characters,
            required: true,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _vehicleTypeController,
            label: 'Vehicle Type',
            focusNodeKey: 'vehicleType',
            nextFocusNodeKey: 'lorryWeight',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _lorryWeightController,
                  label: 'Lorry Weight (kg)',
                  focusNodeKey: 'lorryWeight',
                  nextFocusNodeKey: 'unladenWeight',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _unladenWeightController,
                  label: 'Unladen Weight',
                  focusNodeKey: 'unladenWeight',
                  nextFocusNodeKey: 'overWeight',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _overWeightController,
            label: 'Over Weight (kg)',
            focusNodeKey: 'overWeight',
            nextFocusNodeKey: 'engineNumber',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _engineNumberController,
            label: 'Engine Number',
            focusNodeKey: 'engineNumber',
            nextFocusNodeKey: 'chassisNumber',
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _chassisNumberController,
            label: 'Chassis Number',
            focusNodeKey: 'chassisNumber',
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildEnhancedTextField(
            controller: _roadTaxNumberController,
            label: 'Road Tax Number',
            focusNodeKey: 'roadTaxNumber',
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Road Tax Expiry Date',
            selectedDate: _roadTaxExpDate,
            onDateSelected: (date) => setState(() => _roadTaxExpDate = date),
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _insuranceController,
            label: 'Insurance Number',
            focusNodeKey: 'insurance',
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'Insurance Expiry Date',
            selectedDate: _insuranceExpDate,
            onDateSelected: (date) => setState(() => _insuranceExpDate = date),
          ),
          const SizedBox(height: 16),
          _buildDateField(
            label: 'FC Date',
            selectedDate: _fcDate,
            onDateSelected: (date) => setState(() => _fcDate = date),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildEnhancedTextField(
            controller: _bankNameController,
            label: 'Bank Name',
            focusNodeKey: 'bankName',
            nextFocusNodeKey: 'branchName',
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _branchNameController,
            label: 'Branch Name',
            focusNodeKey: 'branchName',
            nextFocusNodeKey: 'accountNumber',
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _accountNumberController,
            label: 'Account Number',
            focusNodeKey: 'accountNumber',
            nextFocusNodeKey: 'accountHolderName',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _accountHolderNameController,
            label: 'Account Holder Name',
            focusNodeKey: 'accountHolderName',
            nextFocusNodeKey: 'ifscCode',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _ifscCodeController,
                  label: 'IFSC Code',
                  focusNodeKey: 'ifscCode',
                  nextFocusNodeKey: 'micrCode',
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _micrCodeController,
                  label: 'MICR Code',
                  focusNodeKey: 'micrCode',
                  nextFocusNodeKey: 'branchCode',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedTextField(
            controller: _branchCodeController,
            label: 'Branch Code',
            focusNodeKey: 'branchCode',
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.truck != null) ...[
            if (_isLoadingExistingAttachments)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_existingAttachmentsError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _existingAttachmentsError!,
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              )
            else if (_existingAttachments.isNotEmpty) ...[
              Text(
                'Existing Attachments (${_existingAttachments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _existingAttachments.length,
                itemBuilder: (context, index) {
                  final attachment = _existingAttachments[index];
                  final name = attachment['name'] as String;
                  final filename = attachment['filename'] as String;
                  final size = attachment['size'] as int;
                  final mimeType = attachment['type'] as String;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: _getFileColor(
                          mimeType,
                        ).withOpacity(0.1),
                        child: Icon(
                          _getFileIcon(mimeType),
                          color: _getFileColor(mimeType),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatFileSize(size)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility,
                              color: Colors.blue,
                            ),
                            onPressed: () =>
                                _previewExistingAttachment(filename),
                            tooltip: 'Preview',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Colors.green,
                            ),
                            onPressed: () =>
                                _downloadExistingAttachment(filename, name),
                            tooltip: 'Download',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
          const Text(
            'New Attachments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickAttachments,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2A44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${_attachments.length} file(s) selected',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final file = _attachments[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: Colors.blue,
                    ),
                    title: Text(file.name),
                    subtitle: file.size != null
                        ? Text(_formatFileSize(file.size!))
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _attachments.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.truck == null ? 'Add New Truck' : 'Edit Truck'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Owner'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Vehicle'),
            Tab(icon: Icon(Icons.description), text: 'Documents'),
            Tab(icon: Icon(Icons.account_balance), text: 'Bank'),
            Tab(icon: Icon(Icons.attach_file), text: 'Files'),
          ],
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _saveTruck,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('SAVE', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? Obx(() {
              final uploading = _controller.isUploading.value;
              final progress = _controller.uploadProgress.value;
              final hasProgress = uploading && progress > 0 && progress < 1;
              final percent = (progress * 100).clamp(0, 100).toInt();

              String title;
              String subtitle;
              if (hasProgress) {
                if (percent < 30) {
                  title = 'Starting upload...';
                  subtitle = 'Preparing your truck details and files.';
                } else if (percent < 70) {
                  title = 'Uploading files';
                  subtitle = 'Please keep this screen open while we upload.';
                } else if (percent < 100) {
                  title = 'Finalizing';
                  subtitle = 'Almost done, applying changes on the server.';
                } else {
                  title = 'Processing response';
                  subtitle = 'Just a moment while we finish up.';
                }
              } else {
                title = uploading ? 'Uploading...' : 'Saving truck...';
                subtitle = 'This usually takes just a few seconds.';
              }

              final filesCount = _attachments.length;

              // Bytes info from controller (total across the whole multipart upload)
              final sentBytes = _controller.uploadBytesSent.value;
              final totalBytes = _controller.uploadBytesTotal.value;

              String _formatBytes(int bytes) {
                if (bytes <= 0) return '0 B';
                const kb = 1024;
                const mb = kb * 1024;
                if (bytes >= mb) {
                  return '${(bytes / mb).toStringAsFixed(1)} MB';
                }
                if (bytes >= kb) {
                  return '${(bytes / kb).toStringAsFixed(1)} KB';
                }
                return '$bytes B';
              }

              // Rough estimate of how many files are done, based on byte ratio
              int estimatedFilesDone = 0;
              if (filesCount > 0 && totalBytes > 0 && sentBytes > 0) {
                final ratio = sentBytes / totalBytes;
                estimatedFilesDone = (ratio * filesCount).floor();
                if (estimatedFilesDone > filesCount) {
                  estimatedFilesDone = filesCount;
                }
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E2A44), Color(0xFF3A4B73)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: hasProgress ? progress : null,
                                minHeight: 10,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFFC857),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      hasProgress
                                          ? Icons.cloud_upload
                                          : Icons.autorenew,
                                      size: 18,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      hasProgress
                                          ? '$percent% complete'
                                          : 'Calculating...',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (filesCount > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${_formatBytes(sentBytes)} / ${_formatBytes(totalBytes)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${estimatedFilesDone.clamp(0, filesCount)} of $filesCount file${filesCount > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Progress indicator
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (_currentTabIndex + 1) / 5,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1E2A44),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Step ${_currentTabIndex + 1} of 5',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E2A44),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOwnerDetailsTab(),
                        _buildVehicleDetailsTab(),
                        _buildDocumentDetailsTab(),
                        _buildBankDetailsTab(),
                        _buildAttachmentsTab(),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF1E2A44),
                                ),
                                foregroundColor: const Color(0xFF1E2A44),
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
                                    if (_currentTabIndex < 4) {
                                      _tabController.animateTo(
                                        _currentTabIndex + 1,
                                      );
                                    } else {
                                      _saveTruck();
                                    }
                                  },
                            icon: Icon(
                              _currentTabIndex < 4
                                  ? Icons.arrow_forward
                                  : Icons.save,
                            ),
                            label: Text(
                              _currentTabIndex < 4 ? 'Next' : 'Save Truck',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2A44),
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
