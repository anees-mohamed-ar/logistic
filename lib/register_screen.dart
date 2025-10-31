import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:logistic/api_config.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/models/branch.dart';
import 'package:logistic/controller/company_controller.dart' as company;

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
  final company.CompanyController _companyController = Get.put(
    company.CompanyController(),
  );
  company.Company? _selectedCompany;

  List<Branch> branches = [];
  Branch? _selectedBranch;

  // Upload progress tracking
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String _uploadStatus = '';

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedImage = result.files.single;
      });
    }
  }

  Future<void> _fetchBranchesForCompany(int companyId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/branch/company/$companyId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          branches = data.map((json) => Branch.fromJson(json)).toList();
          _selectedBranch = null; // Reset selection when company changes
        });
      } else {
        Get.snackbar('Error', 'Failed to load branches');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    }
  }

  Future<bool> _uploadProfilePicture(String userId) async {
    if (_pickedImage == null || _pickedImage!.bytes == null) return false;

    final dioInstance = dio.Dio();
    final formData = dio.FormData.fromMap({
      'profileImage': dio.MultipartFile.fromBytes(
        _pickedImage!.bytes!,
        filename: _pickedImage!.name,
      ),
    });

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      final response = await dioInstance.post(
        '${ApiConfig.baseUrl}/profile/profile-picture/$userId',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1) {
            final progress = sent / total;
            final speed = sent / 1024; // KB uploaded
            final totalSize = total / 1024; // KB total
            setState(() {
              _uploadProgress = progress;
              _uploadStatus =
                  'Uploading: ${(progress * 100).toStringAsFixed(1)}% (${speed.toStringAsFixed(1)} KB / ${totalSize.toStringAsFixed(1)} KB)';
            });
          } else {
            setState(() {
              _uploadStatus = 'Uploading: ${sent} bytes sent';
            });
          }
        },
        options: dio.Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _uploadProgress = 1.0;
          _uploadStatus = 'Upload completed!';
        });
        await Future.delayed(
          const Duration(seconds: 1),
        ); // Show completion briefly
        return true;
      } else {
        setState(() {
          _uploadStatus = 'Upload failed: ${response.statusCode}';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Upload error: $e';
      });
      return false;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompany == null) {
      Get.snackbar(
        'Error',
        'Please select a company',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
        if (_selectedBranch != null)
          'branch_id': _selectedBranch!.branchId.toString(),
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
            userId = (data['userId'] ?? data['id'] ?? data['data']?['userId'])
                ?.toString();
          } else if (data is List && data.isNotEmpty) {
            final first = data.first;
            if (first is Map<String, dynamic>) {
              userId = (first['userId'] ?? first['id'])?.toString();
            }
          }
        } catch (_) {}

        // If an image is selected and we have a userId, upload it
        if (_pickedImage != null &&
            _pickedImage!.bytes != null &&
            (userId?.isNotEmpty ?? false)) {
          final uploadSuccess = await _uploadProfilePicture(userId!);
          if (uploadSuccess) {
            Get.snackbar('Success', 'Profile picture uploaded successfully');
          } else {
            Get.snackbar(
              'Warning',
              'User created but image upload failed',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        } else if (_pickedImage != null &&
            (_pickedImage!.bytes != null) &&
            (userId == null || userId!.isEmpty)) {
          // Try to resolve userId via the search endpoint used by login
          try {
            final lookupResp = await http.get(
              Uri.parse(
                '${ApiConfig.baseUrl}/profile/search?userEmail=${Uri.encodeComponent(_emailCtrl.text.trim())}&password=${Uri.encodeComponent(_passwordCtrl.text.trim())}',
              ),
              headers: {'Accept': 'application/json'},
            );
            if (lookupResp.statusCode == 200) {
              final data = jsonDecode(lookupResp.body);
              if (data is List &&
                  data.isNotEmpty &&
                  data.first is Map<String, dynamic>) {
                final fetchedId = (data.first['userId'] ?? data.first['id'])
                    ?.toString();
                if (fetchedId != null && fetchedId.isNotEmpty) {
                  // Retry upload with fetched userId
                  final uploadSuccess = await _uploadProfilePicture(fetchedId);
                  if (uploadSuccess) {
                    Get.snackbar(
                      'Success',
                      'Profile picture uploaded successfully',
                    );
                  } else {
                    Get.snackbar(
                      'Warning',
                      'Image upload failed after lookup',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                } else {
                  Get.snackbar(
                    'Info',
                    'User created. Could not resolve userId for image upload.',
                    backgroundColor: Colors.blueGrey,
                    colorText: Colors.white,
                  );
                }
              } else {
                Get.snackbar(
                  'Info',
                  'User created. Lookup returned no user for image upload.',
                  backgroundColor: Colors.blueGrey,
                  colorText: Colors.white,
                );
              }
            } else {
              Get.snackbar(
                'Info',
                'User created. Lookup failed (${lookupResp.statusCode}).',
                backgroundColor: Colors.blueGrey,
                colorText: Colors.white,
              );
            }
          } catch (e) {
            Get.snackbar(
              'Info',
              'User created. Could not upload image: $e',
              backgroundColor: Colors.blueGrey,
              colorText: Colors.white,
            );
          }
        }

        Get.snackbar('Success', 'Registration successful. You can log in now.');
        Get.offAllNamed(AppRoutes.login);
      } else {
        final msg = () {
          try {
            final data = jsonDecode(response.body);
            return data['error']?.toString() ??
                response.reasonPhrase ??
                'Registration failed';
          } catch (_) {
            return response.reasonPhrase ?? 'Registration failed';
          }
        }();
        Get.snackbar(
          'Error',
          msg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to register: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
                      Text(
                        _companyController.error.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _companyController.fetchCompanies,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Loading Companies'),
                      ),
                    ],
                  );
                }
                return DropdownButtonFormField<company.Company>(
                  value:
                      _selectedCompany ??
                      (_companyController.selectedCompany.value ??
                          (_companyController.companies.isNotEmpty
                              ? _companyController.companies.first
                              : null)),
                  items: _companyController.companies
                      .map(
                        (c) => DropdownMenuItem<company.Company>(
                          value: c,
                          child: Text(c.companyName),
                        ),
                      )
                      .toList(),
                  onChanged: (c) {
                    setState(() => _selectedCompany = c);
                    if (c != null) {
                      _fetchBranchesForCompany(c.id);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Company *',
                    prefixIcon: Icon(Icons.apartment_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null ? 'Please select a company' : null,
                );
              }),
              const SizedBox(height: 16),
              if (_selectedCompany != null) ...[
                _buildSearchableBranchField(
                  context: context,
                  label: 'Branch (Optional)',
                  value: _selectedBranch?.branchName ?? '',
                  items: branches.map((b) => b.branchName).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final branch = branches.firstWhere(
                        (b) => b.branchName == value,
                        orElse: () =>
                            _selectedBranch ??
                            Branch(
                              branchId: 0,
                              branchName: '',
                              branchCode: '',
                              companyId: 0,
                              companyName: '',
                              status: 'active',
                            ),
                      );
                      setState(() {
                        _selectedBranch = branch;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera_back_outlined),
                    label: const Text('Upload Profile Picture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2A44),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
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
              // Upload progress bar
              if (_isUploading) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _uploadProgress == 1.0
                              ? Icons.check_circle
                              : Icons.upload,
                          size: 16,
                          color: _uploadProgress == 1.0
                              ? Colors.green
                              : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _uploadStatus,
                            style: TextStyle(
                              fontSize: 12,
                              color: _uploadProgress == 1.0
                                  ? Colors.green
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (_uploadProgress > 0 && _uploadProgress < 1.0)
                          Text(
                            '${(_uploadProgress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2A44),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

  Widget _buildSearchableBranchField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    final searchCtrl = TextEditingController();

    return GestureDetector(
      onTap: () async {
        final selected = await _showSearchPicker(
          context: context,
          title: label,
          items: items,
          current: value,
        );
        if (selected != null) {
          onChanged(selected);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: TextEditingController(
            text: value.isEmpty ? 'Select $label' : value,
          ),
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: const Icon(Icons.search),
          ),
          style: value.isEmpty
              ? theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)
              : theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Future<String?> _showSearchPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String current,
  }) async {
    final TextEditingController searchCtrl = TextEditingController();
    List<String> filtered = List<String>.from(items);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select $title',
                              style: Theme.of(ctx).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              searchCtrl.clear();
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (q) {
                          setState(() {
                            final query = q.trim().toLowerCase();
                            filtered = items
                                .where((e) => e.toLowerCase().contains(query))
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No results',
                                  style: Theme.of(ctx).textTheme.bodyMedium,
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (ctx, index) {
                                  final item = filtered[index];
                                  return ListTile(
                                    title: Text(item),
                                    onTap: () {
                                      searchCtrl.clear();
                                      Navigator.of(ctx).pop(item);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
