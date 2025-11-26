import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/location_controller.dart';
import 'package:logistic/models/location_model.dart';
import 'package:logistic/widgets/main_layout.dart';

class LocationFormPage extends StatefulWidget {
  final Location? location;

  const LocationFormPage({Key? key, this.location}) : super(key: key);

  @override
  _LocationFormPageState createState() => _LocationFormPageState();
}

class _LocationFormPageState extends State<LocationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final LocationController _controller = Get.find();

  final _branchNameController = TextEditingController();
  final _branchCodeController = TextEditingController();
  final _branchPincodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _companyIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final location = widget.location ?? Get.arguments as Location?;
    if (location != null) {
      _branchNameController.text = location.branchName;
      _branchCodeController.text = location.branchCode;
      _branchPincodeController.text = location.branchPincode;
      _addressController.text = location.address;
      _contactPersonController.text = location.contactPerson;
      _emailController.text = location.email;
      _phoneNumberController.text = location.phoneNumber;
      _companyIdController.text = location.companyId;
    }
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _branchCodeController.dispose();
    _branchPincodeController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _companyIdController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _branchNameController.clear();
    _branchCodeController.clear();
    _branchPincodeController.clear();
    _addressController.clear();
    _contactPersonController.clear();
    _emailController.clear();
    _phoneNumberController.clear();
    _companyIdController.clear();
    _formKey.currentState?.reset();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final location = Location(
        id: widget.location?.id ?? '',
        branchName: _branchNameController.text.trim(),
        branchCode: _branchCodeController.text.trim(),
        branchPincode: _branchPincodeController.text.trim(),
        address: _addressController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        companyId: _companyIdController.text.trim(),
      );

      final isEditing = widget.location != null || Get.arguments != null;
      final success = isEditing
          ? await _controller.updateLocation(location)
          : await _controller.addLocation(location);

      if (success) {
        if (!isEditing) {
          _clearForm();
          Get.snackbar(
            'Success',
            'Location added successfully',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.back(result: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location ?? Get.arguments as Location?;
    final isEditing = location != null;

    return MainLayout(
      title: isEditing ? 'Edit Location' : 'Add Location',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _branchNameController,
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter branch name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _branchCodeController,
                decoration: const InputDecoration(
                  labelText: 'Branch Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter branch code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _branchPincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Obx(
                () => _controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          isEditing ? 'Update Location' : 'Add Location',
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
