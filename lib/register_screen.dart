import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/controller/company_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _serverCtrl = TextEditingController(text: ApiConfig.baseUrl);
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  bool _isSubmitting = false;
  PlatformFile? _pickedImage;
  final CompanyController _companyController = Get.put(CompanyController());
  Company? _selectedCompany;

  @override
  void dispose() {
    _serverCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedImage = result.files.single;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      Get.snackbar('Error', 'Please select a company', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      ApiConfig.baseUrl = _serverCtrl.text.trim();

      // Follow the same API shape as User Management: JSON to /profile/user/add
      final url = Uri.parse('${ApiConfig.baseUrl}/profile/user/add');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final body = jsonEncode({
        'userName': _nameCtrl.text.trim(),
        'userEmail': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
        'phoneNumber': _mobileCtrl.text.trim(),
        'user_role': 'user',
        'companyName': _selectedCompany?.companyName,
        'companyId': _selectedCompany?.id.toString(),
        // Optionally include company fields if required by backend:
        // 'companyName': '...',
        // 'companyId': '...'
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        String? userId;
        try {
          final data = jsonDecode(response.body);
          // Try common patterns
          if (data is Map<String, dynamic>) {
            userId = (data['userId'] ?? data['id'] ?? data['data']?['userId'])?.toString();
          } else if (data is List && data.isNotEmpty) {
            final first = data.first;
            if (first is Map<String, dynamic>) {
              userId = (first['userId'] ?? first['id'])?.toString();
            }
          }
        } catch (_) {}

        // If an image is selected and we have a userId, upload it
        if (_pickedImage != null && _pickedImage!.bytes != null && (userId?.isNotEmpty ?? false)) {
          try {
            final uploadUri = Uri.parse('${ApiConfig.baseUrl}/profile/profile-picture/$userId');
            final req = http.MultipartRequest('POST', uploadUri);
            req.files.add(
              http.MultipartFile.fromBytes(
                'profileImage',
                _pickedImage!.bytes!,
                filename: _pickedImage!.name,
              ),
            );
            final streamed = await req.send();
            final uploadResp = await http.Response.fromStream(streamed);
            if (uploadResp.statusCode == 200) {
              Get.snackbar('Success', 'Profile picture uploaded successfully');
            } else {
              Get.snackbar('Warning', 'User created but image upload failed (${uploadResp.statusCode})', backgroundColor: Colors.orange, colorText: Colors.white);
            }
          } catch (e) {
            Get.snackbar('Warning', 'User created but image upload failed: $e', backgroundColor: Colors.orange, colorText: Colors.white);
          }
        } else if (_pickedImage != null && (_pickedImage!.bytes != null) && (userId == null || userId!.isEmpty)) {
          // Try to resolve userId via the search endpoint used by login
          try {
            final lookupResp = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/profile/search?userEmail=${Uri.encodeComponent(_emailCtrl.text.trim())}&password=${Uri.encodeComponent(_passwordCtrl.text.trim())}'),
              headers: {'Accept': 'application/json'},
            );
            if (lookupResp.statusCode == 200) {
              final data = jsonDecode(lookupResp.body);
              if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
                final fetchedId = (data.first['userId'] ?? data.first['id'])?.toString();
                if (fetchedId != null && fetchedId.isNotEmpty) {
                  // Retry upload with fetched userId
                  final uploadUri = Uri.parse('${ApiConfig.baseUrl}/profile/profile-picture/$fetchedId');
                  final req = http.MultipartRequest('POST', uploadUri);
                  req.files.add(
                    http.MultipartFile.fromBytes(
                      'profileImage',
                      _pickedImage!.bytes!,
                      filename: _pickedImage!.name,
                    ),
                  );
                  final streamed = await req.send();
                  final uploadResp = await http.Response.fromStream(streamed);
                  if (uploadResp.statusCode == 200) {
                    Get.snackbar('Success', 'Profile picture uploaded successfully');
                  } else {
                    Get.snackbar('Warning', 'Image upload failed after lookup (${uploadResp.statusCode})', backgroundColor: Colors.orange, colorText: Colors.white);
                  }
                } else {
                  Get.snackbar('Info', 'User created. Could not resolve userId for image upload.', backgroundColor: Colors.blueGrey, colorText: Colors.white);
                }
              } else {
                Get.snackbar('Info', 'User created. Lookup returned no user for image upload.', backgroundColor: Colors.blueGrey, colorText: Colors.white);
              }
            } else {
              Get.snackbar('Info', 'User created. Lookup failed (${lookupResp.statusCode}).', backgroundColor: Colors.blueGrey, colorText: Colors.white);
            }
          } catch (e) {
            Get.snackbar('Info', 'User created. Could not upload image: $e', backgroundColor: Colors.blueGrey, colorText: Colors.white);
          }
        }

        Get.snackbar('Success', 'Registration successful. You can log in now.');
        Get.offAllNamed(AppRoutes.login);
      } else {
        final msg = () {
          try {
            final data = jsonDecode(response.body);
            return data['error']?.toString() ?? response.reasonPhrase ?? 'Registration failed';
          } catch (_) {
            return response.reasonPhrase ?? 'Registration failed';
          }
        }();
        Get.snackbar('Error', msg, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to register: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register User'),
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _serverCtrl,
                decoration: const InputDecoration(
                  labelText: 'Backend Server',
                  hintText: 'Enter server URL or IP',
                  prefixIcon: Icon(Icons.dns_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!GetUtils.isEmail(v)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (_companyController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_companyController.error.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_companyController.error.value, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _companyController.fetchCompanies,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Loading Companies'),
                      ),
                    ],
                  );
                }
                return DropdownButtonFormField<Company>(
                  value: _selectedCompany ?? (_companyController.selectedCompany.value ?? (_companyController.companies.isNotEmpty ? _companyController.companies.first : null)),
                  items: _companyController.companies
                      .map((c) => DropdownMenuItem<Company>(value: c, child: Text(c.companyName)))
                      .toList(),
                  onChanged: (c) => setState(() => _selectedCompany = c),
                  decoration: const InputDecoration(
                    labelText: 'Company *',
                    prefixIcon: Icon(Icons.apartment_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null ? 'Please select a company' : null,
                );
              }),
              const SizedBox(height: 16),

              // Profile image picker
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera_back_outlined),
                    label: const Text('Upload Profile Picture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2A44),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedImage?.name ?? 'No file selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2A44),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
