import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/gc_assignment_controller.dart';

class GCAssignmentPage extends StatelessWidget {
  const GCAssignmentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GCAssignmentController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'GC Assignment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildSectionHeader(
                  icon: Icons.assignment_ind_rounded,
                  title: 'User Selection',
                  subtitle: 'Search and select a user to assign GC numbers',
                ),
                const SizedBox(height: 16),

                // User Selection Card
                _buildUserSelectionCard(controller),

                const SizedBox(height: 32),

                // User Usage Statistics (Collapsible - only show when user is selected)
                Obx(() {
                  if (controller.selectedUser.value != null) {
                    return Column(
                      children: [
                        _buildUsageStatisticsCollapsible(controller),
                        const SizedBox(height: 32),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Assignment Details Header
                _buildSectionHeader(
                  icon: Icons.description_rounded,
                  title: 'Assignment Details',
                  subtitle: 'Configure the GC number range and status',
                ),
                const SizedBox(height: 16),

                // Assignment Details Card
                _buildAssignmentDetailsCard(controller),

                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4A90E2),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserSelectionCard(GCAssignmentController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            TextFormField(
              controller: controller.userCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: controller.filterUsers,
              validator: controller.validateUser,
            ),
            const SizedBox(height: 16),

            // User List
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Obx(() {
                if (controller.filteredUsers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            'No users found',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final selectedUserId = controller.selectedUser.value?['userId'];

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.filteredUsers.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final user = controller.filteredUsers[index];
                    final isSelected = selectedUserId == user['userId'];

                    return InkWell(
                      onTap: () async {
                        controller.selectedUser.value = user;
                        controller.userCtrl.text = user['userName'] ?? '';
                        await controller.checkUserActiveRanges(user['userId']);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4A90E2).withOpacity(0.05) : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                  colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                                )
                                    : LinearGradient(
                                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['userName'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user['userEmail'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4A90E2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // Selected User Info
            Obx(() {
              if (controller.selectedUser.value != null) {
                final user = controller.selectedUser.value!;
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4A90E2).withOpacity(0.1),
                        const Color(0xFF4A90E2).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected User',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A90E2),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user['userName'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user['userEmail'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: controller.hasActiveRanges.value
                                ? Colors.orange[600]
                                : Colors.green[600],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (controller.hasActiveRanges.value
                                    ? Colors.orange[600]!
                                    : Colors.green[600]!)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            controller.hasActiveRanges.value ? 'QUEUED' : 'ACTIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
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
    );
  }

  Widget _buildUsageStatisticsCollapsible(GCAssignmentController controller) {
    final isExpanded = true.obs;

    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Collapsible Header
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Color(0xFF4A90E2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usage Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active and queued GC ranges for selected user',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded.value ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF4A90E2),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Content
          if (isExpanded.value) ...[
            Divider(height: 1, color: Colors.grey[200]),
            _buildUsageStatistics(controller),
          ],
        ],
      ),
    ));
  }

  Widget _buildUsageStatistics(GCAssignmentController controller) {
    return Obx(() {
      if (controller.loadingUsage.value) {
        return Container(
          padding: const EdgeInsets.all(40),
          child: const Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading usage data...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.usageError.value != null) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                controller.usageError.value!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      if (controller.userUsageData.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline, size: 48, color: Colors.green[400]),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active or Queued Ranges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This user has no active or queued GC assignments',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      // Calculate summary statistics
      int totalGCs = 0;
      int usedGCs = 0;
      int remainingGCs = 0;

      for (var usage in controller.userUsageData) {
        totalGCs += (usage['totalGCs'] as int?) ?? 0;
        usedGCs += (usage['usedGCs'] as int?) ?? 0;
        remainingGCs += (usage['remainingGCs'] as int?) ?? 0;
      }

      double overallPercentage = totalGCs > 0 ? (usedGCs / totalGCs * 100) : 0;

      return Column(
        children: [
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.inventory_rounded,
                    label: 'Total GCs',
                    value: totalGCs.toString(),
                    color: const Color(0xFF4A90E2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Used',
                    value: usedGCs.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    icon: Icons.pending_rounded,
                    label: 'Remaining',
                    value: remainingGCs.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Overall Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Usage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      '${overallPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A90E2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: overallPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(overallPercentage),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.grey[200]),

          // Individual Range Details
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.userUsageData.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final usage = controller.userUsageData[index];
              return _buildUsageRangeCard(usage);
            },
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRangeCard(Map<String, dynamic> usage) {
    final status = usage['status'] ?? '';
    final fromGC = usage['fromGC'] ?? '';
    final toGC = usage['toGC'] ?? '';
    final currentGC = usage['currentGC'] ?? '';
    final totalGCs = usage['totalGCs'] ?? 0;
    final usedGCs = usage['usedGCs'] ?? 0;
    final remainingGCs = usage['remainingGCs'] ?? 0;
    final percentage = (usage['percentageUsed'] ?? 0).toDouble();

    final statusColor = status == 'active' ? Colors.green : Colors.orange;
    final statusIcon = status == 'active' ? Icons.play_circle_filled : Icons.schedule;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'GC $fromGC - $toGC',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current: $currentGC',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUsageMetric('Used', usedGCs.toString(), Colors.green),
              ),
              Expanded(
                child: _buildUsageMetric('Remaining', remainingGCs.toString(), Colors.orange),
              ),
              Expanded(
                child: _buildUsageMetric('Total', totalGCs.toString(), const Color(0xFF4A90E2)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(percentage),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _getProgressColor(percentage),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentDetailsCard(GCAssignmentController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildGCNumberFieldWithValidation(controller),
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: controller.countCtrl,
              label: 'Count',
              hint: 'Number of GCs to assign',
              icon: Icons.format_list_numbered_rounded,
              keyboardType: TextInputType.number,
              validator: controller.validateCount,
            ),
            const SizedBox(height: 20),
            _buildToGCNumberFieldWithValidation(controller),
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: controller.statusCtrl,
              label: 'Status',
              hint: 'Assignment status',
              icon: Icons.info_rounded,
              readOnly: true,
              fillColor: Colors.grey[100],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGCNumberFieldWithValidation(GCAssignmentController controller) {
    return Obx(() {
      // Determine border color and icon based on validation status
      Color borderColor = Colors.grey[300]!;
      Color? fillColor = Colors.grey[50];
      Widget? suffixIcon;
      
      if (controller.gcNumberValidating.value) {
        // Checking status - blue with loading indicator
        borderColor = const Color(0xFF4A90E2);
        suffixIcon = const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
            ),
          ),
        );
      } else if (controller.gcNumberStatus.value != null) {
        final status = controller.gcNumberStatus.value!;
        
        if (status == 'available') {
          // Available - green with check icon
          borderColor = Colors.green;
          fillColor = Colors.green[50];
          suffixIcon = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          );
        } else if (status == 'active') {
          // Active range - orange with warning icon
          borderColor = Colors.orange;
          fillColor = Colors.orange[50];
          suffixIcon = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
          );
        } else if (status == 'queued') {
          // Queued range - blue with info icon
          borderColor = Colors.blue;
          fillColor = Colors.blue[50];
          suffixIcon = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.schedule,
              color: Colors.blue,
              size: 24,
            ),
          );
        } else if (status == 'expired') {
          // Expired range - red with error icon
          borderColor = Colors.red[300]!;
          fillColor = Colors.red[50];
          suffixIcon = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 24,
            ),
          );
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'From GC Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.fromGcCtrl,
            decoration: InputDecoration(
              hintText: 'Enter starting GC number',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(
                Icons.numbers_rounded,
                color: Color(0xFF4A90E2),
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            keyboardType: TextInputType.number,
            validator: controller.validateFromGc,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500,
            ),
          ),
          // Status message
          if (controller.gcNumberMessage.value != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getStatusIcon(controller.gcNumberStatus.value),
                  size: 16,
                  color: _getStatusColor(controller.gcNumberStatus.value),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    controller.gcNumberMessage.value!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(controller.gcNumberStatus.value),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }

  Widget _buildToGCNumberFieldWithValidation(GCAssignmentController controller) {
    return Obx(() {
      // Determine border color and icon based on validation status
      Color borderColor = Colors.grey[300]!;
      Color? fillColor = Colors.grey[100];
      Widget? suffixIcon;
      
      if (controller.toGcNumberValidating.value) {
        // Checking status - blue with loading indicator
        borderColor = const Color(0xFF4A90E2);
        suffixIcon = const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
            ),
          ),
        );
      } else if (controller.toGcNumberStatus.value != null) {
        final status = controller.toGcNumberStatus.value!;
        
        if (status == 'available') {
          // Available - green with check icon
          borderColor = Colors.green;
          fillColor = Colors.green[50];
          suffixIcon = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          );
        } else if (status == 'active') {
          // Active range - orange with warning icon
          borderColor = Colors.orange;
          fillColor = Colors.orange[50];
          suffixIcon = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
          );
        } else if (status == 'queued') {
          // Queued range - blue with info icon
          borderColor = Colors.blue;
          fillColor = Colors.blue[50];
          suffixIcon = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.schedule,
              color: Colors.blue,
              size: 24,
            ),
          );
        } else if (status == 'expired') {
          // Expired range - red with error icon
          borderColor = Colors.red[300]!;
          fillColor = Colors.red[50];
          suffixIcon = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 24,
            ),
          );
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To GC Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.toGcCtrl,
            decoration: InputDecoration(
              hintText: 'Auto-calculated',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.grey[400],
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            readOnly: true,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          // Status message
          if (controller.toGcNumberMessage.value != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getStatusIcon(controller.toGcNumberStatus.value),
                  size: 16,
                  color: _getStatusColor(controller.toGcNumberStatus.value),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    controller.toGcNumberMessage.value!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(controller.toGcNumberStatus.value),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.info_outline;
    switch (status) {
      case 'available':
        return Icons.check_circle;
      case 'active':
        return Icons.warning_amber_rounded;
      case 'queued':
        return Icons.schedule;
      case 'expired':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'available':
        return Colors.green;
      case 'active':
        return Colors.orange;
      case 'queued':
        return Colors.blue;
      case 'expired':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    Color? fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: readOnly ? Colors.grey[400] : const Color(0xFF4A90E2)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: fillColor ?? Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? Colors.grey[600] : const Color(0xFF1A1A1A),
            fontWeight: readOnly ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(GCAssignmentController controller) {
    return Column(
      children: [
        Obx(() {
          return Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90E2).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: controller.isSubmitting.value ? null : controller.submitAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_task_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create Assignment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: controller.clearForm,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!, width: 1.5),
              foregroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Clear Form',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 50) return Colors.green;
    if (percentage < 80) return Colors.orange;
    return Colors.red;
  }
}