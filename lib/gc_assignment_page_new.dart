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
                        TextFormField(
                          controller: controller.userCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          onChanged: controller.filterUsers,
                          validator: controller.validateUser,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: Obx(() {
                            if (controller.filteredUsers.isEmpty) {
                              return const ListTile(
                                title: Text(
                                  'No users found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return Column(
                              children: controller.filteredUsers.map((user) {
                                final isSelected = controller.selectedUser.value?['userId'] == user['userId'];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF4A90E2).withOpacity(0.1) : Colors.transparent,
                                    border: isSelected
                                        ? const Border(
                                            bottom: BorderSide(
                                              color: Color(0xFF4A90E2),
                                              width: 2,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? const Color(0xFF4A90E2)
                                          : Colors.grey.shade300,
                                      child: Icon(
                                        Icons.person,
                                        color: isSelected ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                    title: Text(
                                      user['userName'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? const Color(0xFF4A90E2) : Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      user['userEmail'] ?? '',
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFF4A90E2) : Colors.grey,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF4A90E2),
                                          )
                                        : null,
                                    onTap: () async {
                                      controller.selectedUser.value = user;
                                      controller.userCtrl.text = user['userName'] ?? '';
                                      await controller.checkUserActiveRanges(user['userId']);
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                        ),
                        Obx(() {
                          if (controller.selectedUser.value != null) {
                            final user = controller.selectedUser.value!;
                            return Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A90E2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selected: ${user['userName']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4A90E2),
                                          ),
                                        ),
                                        Text(
                                          'Email: ${user['userEmail']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4A90E2),
                                          ),
                                        ),
                                        if (user['phoneNumber'] != null)
                                          Text(
                                            'Phone: ${user['phoneNumber']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4A90E2),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Obx(() {
                                    if (controller.checkingRangeStatus.value) {
                                      return const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                                        ),
                                      );
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: controller.hasActiveRanges.value
                                            ? Colors.orange
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        controller.hasActiveRanges.value ? 'QUEUED' : 'ACTIVE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
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
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                        TextFormField(
                          controller: controller.fromGcCtrl,
                          decoration: InputDecoration(
                            labelText: 'From GC Number',
                            hintText: 'Enter starting GC number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          validator: controller.validateFromGc,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controller.countCtrl,
                          decoration: InputDecoration(
                            labelText: 'Count',
                            hintText: 'Enter number of GCs to assign',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          validator: controller.validateCount,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controller.statusCtrl,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
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
