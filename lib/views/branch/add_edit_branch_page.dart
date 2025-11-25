import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/branch_controller.dart';
import 'package:logistic/models/branch.dart';
import 'package:logistic/config/company_config.dart';
import 'package:logistic/widgets/custom_app_bar.dart';

class AddEditBranchPage extends StatefulWidget {
  final Branch? branch;

  const AddEditBranchPage({Key? key, this.branch}) : super(key: key);

  @override
  State<AddEditBranchPage> createState() => _AddEditBranchPageState();
}

class _AddEditBranchPageState extends State<AddEditBranchPage> {
  final BranchController controller = Get.find<BranchController>();
  final _formKey = GlobalKey<FormState>();

  final _branchNameController = TextEditingController();
  final _branchCodeController = TextEditingController();
  // Use CompanyConfig for company values
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _status = CompanyConfig.defaultBranchStatus;

  @override
  void initState() {
    super.initState();
    if (widget.branch != null) {
      _branchNameController.text = widget.branch!.branchName;
      _branchCodeController.text = widget.branch!.branchCode;
      // Company ID and name are fixed for this app
      _addressController.text = widget.branch!.address ?? '';
      _phoneController.text = widget.branch!.phone ?? '';
      _emailController.text = widget.branch!.email ?? '';
      // Normalize status to match dropdown values
      _status = _normalizeStatus(widget.branch!.status);
    }
  }

  String _normalizeStatus(String status) {
    // Convert various status formats to match dropdown values
    final normalized = status.toLowerCase().trim();
    switch (normalized) {
      case 'active':
      case '1':
      case 'true':
        return 'Active';
      case 'inactive':
      case '0':
      case 'false':
        return 'Inactive';
      default:
        return 'Active'; // Default to Active if unknown
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.branch != null;

    return Scaffold(
      appBar: CustomAppBar(title: isEditing ? 'Edit Branch' : 'Add Branch'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Branch Details' : 'Enter Branch Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Branch Name
              TextFormField(
                controller: _branchNameController,
                decoration: const InputDecoration(
                  labelText: 'Branch Name *',
                  hintText: 'Enter branch name',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Branch name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Branch Code
              TextFormField(
                controller: _branchCodeController,
                decoration: const InputDecoration(
                  labelText: 'Branch Code *',
                  hintText: 'Enter branch code',
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Branch code is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Company Name (Read-only display)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CompanyConfig.companyName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter branch address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: Icon(Icons.toggle_on),
                ),
                items: ['Active', 'Inactive']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Status is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : _saveBranch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEditing ? 'Update Branch' : 'Save Branch'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _saveBranch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final branch = Branch(
      branchId: widget.branch?.branchId ?? 0,
      branchName: _branchNameController.text.trim(),
      branchCode: _branchCodeController.text.trim(),
      companyId: CompanyConfig.companyId, // Use CompanyConfig
      companyName: CompanyConfig.companyName, // Use CompanyConfig
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      status: _status,
    );

    bool success;
    if (widget.branch != null) {
      success = await controller.updateBranch(branch);
    } else {
      success = await controller.addBranch(branch);
    }

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        widget.branch != null
            ? 'Branch updated successfully'
            : 'Branch added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _branchCodeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
