import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/gc_assignment_controller.dart';

class GCAssignmentPage extends StatelessWidget {
  const GCAssignmentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GCAssignmentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('GC Assignment'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Selection Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          if (controller.usersLoading.value) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (controller.usersError.value != null) {
                            return Column(
                              children: [
                                Text(
                                  controller.usersError.value!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: controller.fetchUsers,
                                  child: const Text('Retry'),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              // User Search Field
                              TextFormField(
                                controller: controller.userCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Search users...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: controller.filterUsers,
                                validator: controller.validateUser,
                              ),
                              const SizedBox(height: 8),

                              // User Dropdown
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ListView.builder(
                                  itemCount: controller.filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = controller.filteredUsers[index];
                                    final isSelected = controller.selectedUser.value?['userId'] == user['userId'];

                                    return ListTile(
                                      title: Text(user['userName'] ?? 'Unknown'),
                                      subtitle: Text(user['userEmail'] ?? ''),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle, color: Color(0xFF4A90E2))
                                          : null,
                                      onTap: () async {
                                        controller.selectedUser.value = user;
                                        controller.userCtrl.text = user['userName'] ?? '';

                                        // Check if user has active ranges
                                        await controller.checkUserActiveRanges(user['userId']);
                                      },
                                    );
                                  },
                                ),
                              ),

                              // Selected User Info
                              Obx(() {
                                if (controller.selectedUser.value != null) {
                                  final user = controller.selectedUser.value!;
                                  return Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A90E2).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, color: Color(0xFF4A90E2)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Selected: ${user['userName']}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text('Email: ${user['userEmail']}'),
                                              if (user['phoneNumber'] != null)
                                                Text('Phone: ${user['phoneNumber']}'),
                                            ],
                                          ),
                                        ),
                                        Obx(() {
                                          if (controller.checkingRangeStatus.value) {
                                            return const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          }

                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: controller.hasActiveRanges.value
                                                  ? Colors.orange
                                                  : Colors.green,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              controller.hasActiveRanges.value ? 'QUEUED' : 'ACTIVE',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Assignment Details Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assignment Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // From GC Number
                        TextFormField(
                          controller: controller.fromGcCtrl,
                          decoration: const InputDecoration(
                            labelText: 'From GC Number',
                            hintText: 'Enter starting GC number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: controller.validateFromGc,
                        ),
                        const SizedBox(height: 16),

                        // Count
                        TextFormField(
                          controller: controller.countCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Count',
                            hintText: 'Enter number of GCs to assign',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: controller.validateCount,
                        ),
                        const SizedBox(height: 16),

                        // Status (Read-only, set by user selection)
                        TextFormField(
                          controller: controller.statusCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                Obx(() {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.isSubmitting.value
                          ? null
                          : controller.submitAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isSubmitting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Create Assignment',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Clear Form Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: controller.clearForm,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clear Form'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
