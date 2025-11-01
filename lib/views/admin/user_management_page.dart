import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/widgets/custom_app_bar.dart';
import 'package:logistic/api_config.dart';
import 'package:logistic/models/branch.dart';
import 'package:logistic/config/company_config.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String get baseUrl => '${ApiConfig.baseUrl}/profile';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  String _selectedRole = CompanyConfig.defaultUserRole;
  
  // Use CompanyConfig for company values
  final IdController _idController = Get.find<IdController>();
  
  List<Branch> branches = [];
  Branch? _selectedBranch;
  
  List<dynamic> users = [];
  bool isLoading = true;
  bool isAddingUser = false;
  bool isEditing = false;
  String? editingUserId;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchBranchesForCompany(CompanyConfig.companyId); // Fetch branches for hardcoded company
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/search')
          .replace(queryParameters: {
        'companyId': _idController.companyId.value,
      }));
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      } else {
        Get.snackbar('Error', 'Failed to load users');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchBranchesForCompany(int companyId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/branch/company/$companyId'));
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

  Future<void> _addUser() async {
    // First validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Always use hardcoded company
    setState(() => isAddingUser = true);
    
    try {
      // Prepare the request body
      final Map<String, dynamic> requestBody = {};
      
      // Add fields to request body
      final name = _nameController.text.trim();
      if (name.isNotEmpty) requestBody['userName'] = name;
      
      final email = _emailController.text.trim();
      if (email.isNotEmpty) requestBody['userEmail'] = email;
      
      // Only include password if it's not empty (for edit mode)
      final password = _passwordController.text;
      if (password.isNotEmpty || !isEditing) {
        requestBody['password'] = password;
      }
      
      // Add hardcoded company info
      requestBody['companyName'] = CompanyConfig.companyName;
      requestBody['companyId'] = CompanyConfig.companyId.toString();
      
      // Add branch info if available
      if (_selectedBranch != null) {
        requestBody['branch_id'] = _selectedBranch!.branchId.toString();
      }
      
      // Add optional fields if they have values
      final phoneNumber = _phoneController.text.trim();
      if (phoneNumber.isNotEmpty) requestBody['phoneNumber'] = phoneNumber;
      
      final bloodGroup = _bloodGroupController.text.trim();
      if (bloodGroup.isNotEmpty) requestBody['bloodGroup'] = bloodGroup;
      
      // Always include role as it's required
      requestBody['user_role'] = _selectedRole;
      
      // Set up headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Determine the URL and method
      final url = isEditing && editingUserId != null
          ? Uri.parse('$baseUrl/user/update/$editingUserId')
              .replace(queryParameters: {'companyId': _idController.companyId.value})
          : Uri.parse('$baseUrl/user/add');
          
      print('Sending request to: ${url.toString()}');
      print('Request body: $requestBody');

      // Send the request
      final response = isEditing && editingUserId != null
          ? await http.put(
              url,
              headers: headers,
              body: jsonEncode(requestBody),
            )
          : await http.post(
              url,
              headers: headers,
              body: jsonEncode(requestBody),
            );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', isEditing ? 'User updated successfully' : 'User added successfully');
        _resetForm();
        _fetchUsers();
      } else {
        String errorMessage = isEditing ? 'Failed to update user' : 'Failed to add user';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (e) {
          // If response is not JSON, use the raw response
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }
        Get.snackbar('Error', errorMessage);
      }
    } catch (e) {
      print('Error in _addUser: $e');
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      setState(() {
        isAddingUser = false;
        if (isEditing) {
          isEditing = false;
          editingUserId = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'User Management',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add User Form
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
                        isEditing ? 'Edit User' : 'Add New User',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),

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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E2A44),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 8),
                      if (branches.isNotEmpty) ...[
                        _buildSearchableBranchField(
                          context: context,
                          label: 'Branch (Optional)',
                          value: _selectedBranch?.branchName ?? '',
                          items: branches.map((b) => b.branchName).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              final branch = branches.firstWhere(
                                (b) => b.branchName == value,
                                orElse: () => _selectedBranch ?? Branch(branchId: 0, branchName: '', branchCode: '', companyId: 0, companyName: '', status: 'active'),
                              );
                              setState(() {
                                _selectedBranch = branch;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bloodGroupController,
                        decoration: const InputDecoration(labelText: 'Blood Group (Optional)'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: ['user', 'admin']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value ?? 'user';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isAddingUser ? null : _addUser,
                              child: isAddingUser
                                  ? const CircularProgressIndicator()
                                  : Text(isEditing ? 'Update User' : 'Add User'),
                            ),
                          ),
                          if (isEditing) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: isAddingUser ? null : _resetForm,
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
            // Users List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'User List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${users.length} Users',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No users found'),
                        ),
                      )
                    : Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final isAdmin = (user['user_role'] ?? '').toString().toLowerCase() == 'admin';
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isAdmin ? Colors.blue[100] : Colors.grey[200],
                                child: Text(
                                  (user['userName']?[0] ?? '?').toUpperCase(),
                                  style: TextStyle(
                                    color: isAdmin ? Colors.blue[800] : Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['userName'] ?? 'No Name',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    user['userEmail'] ?? 'No Email',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (user['phoneNumber']?.isNotEmpty == true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      user['phoneNumber'],
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? Colors.blue[50] : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isAdmin ? 'Admin' : 'User',
                                      style: TextStyle(
                                        color: isAdmin ? Colors.blue[800] : Colors.grey[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _loadUserForEditing(user);
                                        // Scroll to form
                                        await Future.delayed(const Duration(milliseconds: 300));
                                        Scrollable.ensureVisible(
                                          _formKey.currentContext!,
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.easeInOut,
                                        );
                                      } else if (value == 'delete') {
                                        // Using 'userId' to match the API response
                                        final userId = user['userId']?.toString();
                                        if (userId == null || userId.isEmpty || userId == 'null') {
                                          print('Invalid user data: ${user.toString()}');
                                          Get.snackbar(
                                            'Error',
                                            'Invalid user ID',
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                          return;
                                        }
                                        print('Initiating delete for user ID: $userId');
                                        await _deleteUser(userId);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchableCompanyField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isError = false,
    String? errorText,
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
          controller: TextEditingController(text: value.isEmpty ? 'Select $label' : value),
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isError ? theme.colorScheme.error : theme.dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isError ? theme.colorScheme.error : theme.dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isError ? theme.colorScheme.error : theme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            errorText: errorText,
            suffixIcon: const Icon(Icons.search),
          ),
          style: value.isEmpty 
              ? theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)
              : theme.textTheme.bodyMedium,
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
          controller: TextEditingController(text: value.isEmpty ? 'Select $label' : value),
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _phoneController.clear();
      _bloodGroupController.clear();
      _selectedBranch = null;
      _selectedRole = CompanyConfig.defaultUserRole;
      isEditing = false;
      editingUserId = null;
    });
  }

  void _loadUserForEditing(Map<String, dynamic> user) {
    setState(() {
      isEditing = true;
      editingUserId = user['userId']?.toString();
      _nameController.text = user['userName'] ?? '';
      _emailController.text = user['userEmail'] ?? '';
      _passwordController.clear(); // Clear password for security
      _phoneController.text = user['phoneNumber'] ?? '';
      _bloodGroupController.text = user['bloodGroup'] ?? '';
      _selectedRole = user['user_role']?.toString().toLowerCase() ?? CompanyConfig.defaultUserRole;

      // Company is hardcoded, no need to set it

      // Set branch if available
      if (user['branch_id'] != null && branches.isNotEmpty) {
        final branchId = int.tryParse(user['branch_id'].toString());
        if (branchId != null) {
          _selectedBranch = branches.firstWhere(
            (b) => b.branchId == branchId,
            orElse: () => _selectedBranch ?? Branch(branchId: 0, branchName: '', branchCode: '', companyId: 0, companyName: '', status: 'active'),
          );
        }
      }
    });
  }

  Future<void> _deleteUser(String userId) async {
    print('_deleteUser called with userId: $userId');
    
    if (userId.isEmpty) {
      print('Error: Empty user ID provided');
      Get.snackbar(
        'Error',
        'Cannot delete user: Invalid user ID',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user ID: $userId? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              print('User cancelled deletion');
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              print('User confirmed deletion');
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      print('User cancelled the deletion');
      return;
    }

    setState(() => isLoading = true);
    print('Proceeding with deletion of user: $userId');
    
    try {
      final url = Uri.parse('$baseUrl/user/delete/$userId')
          .replace(queryParameters: {'companyId': _idController.companyId.value});
      print('Sending DELETE request to: $url');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      print('Request headers: $headers');
      
      final response = await http.delete(
        url,
        headers: headers,
      );
      
      print('Delete response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      // Try to parse JSON response if possible
      dynamic responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('Could not parse response as JSON: $e');
      }

      if (response.statusCode == 200) {
        print('User deletion successful: $responseData');
        
        Get.snackbar(
          'Success', 
          responseData != null && responseData['message'] != null 
              ? responseData['message'].toString()
              : 'User deleted successfully',
          duration: const Duration(seconds: 3),
        );
        
        // Refresh the user list
        _fetchUsers();
      } else {
        String errorMessage = 'Failed to delete user (Status: ${response.statusCode})';
        
        if (responseData != null) {
          errorMessage = responseData['error'] ?? 
                       responseData['message'] ?? 
                       errorMessage;
        } else {
          // If not JSON, try to get the raw response
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : errorMessage;
        }
        
        print('Delete error details: $errorMessage');
        
        Get.snackbar(
          'Error', 
          errorMessage,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e, stackTrace) {
      print('Exception during user deletion:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      Get.snackbar(
        'Error', 
        'An error occurred: ${e.toString()}',
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }
}
