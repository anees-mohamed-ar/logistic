import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/temporary_gc_controller.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/models/temporary_gc.dart';
import 'package:logistic/routes.dart';
import 'package:intl/intl.dart';
// Removed unused imports to clean up the code

class TemporaryGCListScreen extends StatefulWidget {
  const TemporaryGCListScreen({super.key});

  @override
  State<TemporaryGCListScreen> createState() => _TemporaryGCListScreenState();
}

class _TemporaryGCListScreenState extends State<TemporaryGCListScreen> with WidgetsBindingObserver {
  late TemporaryGCController controller;
  // Simplified access control - you can implement proper authentication later
  final RxBool hasGCAccess = true.obs;
  final RxBool isCheckingAccess = false.obs;
  final RxString accessMessage = 'Access granted'.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = Get.put(TemporaryGCController());

    // Check GC access and fetch data on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    // Check GC access first
    await _checkGCAccess();

    // Then fetch temporary GCs
    if (!controller.isLoading.value) {
      controller.fetchTemporaryGCs();
    }
  }

  // Check if user has access to GC ranges (either active or queued)
  Future<void> _checkGCAccess() async {
    try {
      isCheckingAccess.value = true;
      
      // Check for active or queued GC ranges using existing endpoints
      final hasAccess = await controller.checkGCAccess();
      hasGCAccess.value = hasAccess;
      accessMessage.value = hasAccess ? 'Access granted' : 'No active GC ranges found';
      
    } catch (e) {
      // If there's an error, we default to denying access to ensure security.
      hasGCAccess.value = false;
      accessMessage.value = 'Could not verify access. Please check your connection and try again.';
      print('Error checking GC access, defaulting to denied access: $e');

      // Optionally, show a temporary error message to the user.
      Get.snackbar(
        'Network Error',
        'Failed to check permissions. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }
    finally {
      isCheckingAccess.value = false;
    }
  }

  final RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    // Clean up the search controller
    searchController.dispose();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Call super.dispose()
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      controller.fetchTemporaryGCs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Obx(() => isSearching.value
            ? Container(
                height: 42,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search GCs...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, 
                                size: 20, 
                                color: Colors.grey),
                            onPressed: () {
                              searchController.clear();
                              controller.updateSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  cursorColor: theme.colorScheme.primary,
                  onChanged: controller.updateSearchQuery,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temporary GC Forms',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${controller.filteredGCs.length} of ${controller.temporaryGCs.length} form${controller.temporaryGCs.length != 1 ? 's' : ''} shown',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              )),
        actions: [
          // Search toggle button
          Obx(() {
            if (controller.temporaryGCs.isEmpty) return const SizedBox.shrink();
            
            return isSearching.value
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      isSearching.value = false;
                      searchController.clear();
                      controller.updateSearchQuery('');
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => isSearching.value = true,
                  );
          }),
          // Filter button
          Obx(() {
            if (controller.temporaryGCs.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: 'Filter',
                onPressed: () => _showFilterDialog(context, controller),
              );
            }
            return const SizedBox.shrink();
          }),
          // Admin create button - only show if admin and has GC access
          Obx(() {
            if (controller.isAdmin && hasGCAccess.value) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.add_circle_rounded),
                  tooltip: 'Create Temporary GC',
                  onPressed: _createNewTemporaryGC,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value || isCheckingAccess.value) {
          return _buildLoadingState();
        }

        // Show access denied message if no access
        if (!hasGCAccess.value) {
          return _buildNoAccessState();
        }

        if (controller.temporaryGCs.isEmpty) {
          return _buildEmptyState(context, controller);
        }

        return Column(
          children: [
            // Statistics Card
            _buildStatisticsCard(controller, theme),

            // List Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.fetchTemporaryGCs,
                color: theme.colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: controller.filteredGCs.length,
                  itemBuilder: (context, index) {
                    final tempGC = controller.filteredGCs[index];
                    return _EnhancedTemporaryGCCard(
                      tempGC: tempGC,
                      controller: controller,
                      index: index,
                      hasGCAccess: hasGCAccess,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        if (controller.isAdmin && controller.temporaryGCs.isNotEmpty) {
          return FloatingActionButton.extended(
            onPressed: () => _createNewTemporaryGC(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Form'),
            elevation: 4,
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: 24),
          Obx(() => Text(
            isCheckingAccess.value ? 'Verifying access...' : 'Loading temporary forms...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNoAccessState() {
    return RefreshIndicator(
      onRefresh: () async {
        await _checkGCAccess();
        if (hasGCAccess.value) {
          await controller.fetchTemporaryGCs();
        }
      },
      color: Theme.of(context).colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 80,
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => Text(
                accessMessage.value.isEmpty
                    ? 'No active or queued GC ranges found or Server down'
                    : accessMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              )),
              const SizedBox(height: 8),
              Text(
                'Please contact your administrator to get GC range access',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _checkGCAccess();
                      if (hasGCAccess.value) {
                        await controller.fetchTemporaryGCs();
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to help or contact admin screen
                      Get.snackbar(
                        'Contact Admin',
                        'Please reach out to your administrator for GC range access',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.blue.shade100,
                        colorText: Colors.blue.shade900,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                        icon: Icon(Icons.info_outline, color: Colors.blue.shade900),
                      );
                    },
                    icon: const Icon(Icons.support_agent_rounded),
                    label: const Text('Contact Admin'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TemporaryGCController controller) {
    return RefreshIndicator(
      onRefresh: controller.fetchTemporaryGCs,
      color: Theme.of(context).colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inbox_rounded,
                  size: 80,
                  color: Colors.blue.shade300,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Temporary GC Forms',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                controller.isAdmin
                    ? 'Create your first temporary form to get started'
                    : 'No forms available at the moment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
              if (controller.isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _createNewTemporaryGC(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create Temporary GC'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => controller.fetchTemporaryGCs(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(TemporaryGCController controller, ThemeData theme) {
    final total = controller.temporaryGCs.length;
    final locked = controller.temporaryGCs.where((gc) => gc.isLocked).length;
    final available = total - locked;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CompactStatItem(
            icon: Icons.description_rounded,
            label: 'Total',
            value: total.toString(),
            color: theme.colorScheme.primary,
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          _CompactStatItem(
            icon: Icons.check_circle_rounded,
            label: 'Available',
            value: available.toString(),
            color: Colors.green.shade600,
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
          ),
          _CompactStatItem(
            icon: Icons.lock_rounded,
            label: 'In Use',
            value: locked.toString(),
            color: Colors.orange.shade600,
          ),
        ],
      ),
    );
  }

  void _createNewTemporaryGC() {
    if (!hasGCAccess.value) {
      Get.snackbar(
        'Access Denied',
        'You need an active or queued GC range to create a temporary GC',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
      return;
    }

    final gcController = Get.isRegistered<GCFormController>()
        ? Get.find<GCFormController>()
        : Get.put(GCFormController(), permanent: true);

    gcController.clearForm();
    gcController.isTemporaryMode.value = true;
    gcController.isFillTemporaryMode.value = false;
    gcController.isEditMode.value = false;

    Get.toNamed(AppRoutes.gcForm);
  }

  // Removed _showSearchDialog as we've moved search to the app bar

  void _showFilterDialog(BuildContext context, TemporaryGCController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Forms'),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive_rounded),
              title: const Text('All Forms'),
              trailing: controller.currentFilter.value == 'all' 
                  ? const Icon(Icons.check_rounded, color: Colors.green)
                  : null,
              onTap: () {
                controller.updateFilter('all');
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
              title: const Text('Available Only'),
              trailing: controller.currentFilter.value == 'available' 
                  ? const Icon(Icons.check_rounded, color: Colors.green)
                  : null,
              onTap: () {
                controller.updateFilter('available');
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded, color: Colors.orange),
              title: const Text('In Use Only'),
              trailing: controller.currentFilter.value == 'in_use' 
                  ? const Icon(Icons.check_rounded, color: Colors.green)
                  : null,
              onTap: () {
                controller.updateFilter('in_use');
                Navigator.pop(context);
              },
            ),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () {
              // Reset filters when canceling
              if (controller.currentFilter.value != 'all' || 
                  controller.searchQuery.value.isNotEmpty) {
                controller.updateFilter('all');
                controller.updateSearchQuery('');
              }
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CompactStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnhancedTemporaryGCCard extends StatelessWidget {
  final TemporaryGC tempGC;
  final TemporaryGCController controller;
  final int index;
  final RxBool hasGCAccess;

  const _EnhancedTemporaryGCCard({
    required this.tempGC,
    required this.controller,
    required this.index,
    required this.hasGCAccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final istDate = tempGC.createdAt.add(const Duration(hours: 5, minutes: 30));

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleTap(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row - GC Number + Status
                  Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tempGC.tempGcNumber,
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _CompactStatusBadge(isLocked: tempGC.isLocked),
                      if (controller.isAdmin) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showDeleteConfirmation(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Route
                  if (tempGC.truckFrom != null || tempGC.truckTo != null)
                    Row(
                      children: [
                        Icon(Icons.route_rounded, size: 15, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${tempGC.truckFrom ?? 'N/A'} → ${tempGC.truckTo ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  // Consignor/Consignee
                  if (tempGC.consignorName != null || tempGC.consigneeName != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.business_outlined,
                            text: tempGC.consignorName ?? 'N/A',
                            color: Colors.purple,
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _CompactInfo(
                            icon: Icons.business_center_outlined,
                            text: tempGC.consigneeName ?? 'N/A',
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Bottom Row - Details + Action
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Branch & Truck Type
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (tempGC.branch != null)
                              _MiniChip(
                                icon: Icons.account_tree_outlined,
                                label: tempGC.branch!,
                              ),
                            if (tempGC.truckType != null)
                              _MiniChip(
                                icon: Icons.local_shipping_outlined,
                                label: tempGC.truckType!,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action Button
                      SizedBox(
                        width: 90, // Slightly reduced fixed width
                        child: ElevatedButton(
                          onPressed: tempGC.isLocked || !hasGCAccess.value
                              ? null
                              : () => _handleTap(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 1,
                            minimumSize: const Size(0, 36), // Ensure minimum touch target
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  tempGC.isLocked 
                                    ? Icons.lock_rounded 
                                    : (!hasGCAccess.value
                                        ? Icons.block_rounded
                                        : Icons.edit_rounded),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tempGC.isLocked 
                                    ? 'Locked' 
                                    : (!hasGCAccess.value
                                        ? 'No Access'
                                        : 'Fill'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Timestamp
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(istDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
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
  }

  void _handleTap(BuildContext context) async {
    // Check access before allowing to fill form
    if (!hasGCAccess.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.block_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('You do not have access to fill GC forms. Please contact admin.'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (tempGC.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('This form is currently being used by another user'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Locking form...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final locked = await controller.lockTemporaryGC(tempGC.tempGcNumber);

    // Close loading dialog
    Navigator.pop(context);

    if (locked) {
      // Refresh the list immediately to show the locked status
      await controller.fetchTemporaryGCs();

      final gcController = Get.isRegistered<GCFormController>()
          ? Get.find<GCFormController>()
          : Get.put(GCFormController(), permanent: true);

      gcController.loadTemporaryGc(tempGC);
      gcController.isFillTemporaryMode.value = true;
      gcController.tempGcNumber.value = tempGC.tempGcNumber;
      gcController.isEditMode.value = false;
      gcController.isTemporaryMode.value = false;

      // Navigate and refresh on return
      await Get.toNamed(AppRoutes.gcForm);

      // Refresh list when coming back from GC form
      await controller.fetchTemporaryGCs();
    } else {
      // Refresh the list to show updated status
      await controller.fetchTemporaryGCs();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Unable to lock form. It may be in use by another user.'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_rounded, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Delete Temporary GC'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this form?',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tempGC.tempGcNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);

              // Show deleting indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Deleting form...'),
                    ],
                  ),
                  backgroundColor: Colors.grey.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );

              await controller.deleteTemporaryGC(tempGC.tempGcNumber);

              // Refresh the list immediately after deletion
              await controller.fetchTemporaryGCs();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Form deleted successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CompactStatusBadge extends StatelessWidget {
  final bool isLocked;

  const _CompactStatusBadge({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLocked ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isLocked ? Colors.orange.shade300 : Colors.green.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock_rounded : Icons.check_circle_rounded,
            size: 12,
            color: isLocked ? Colors.orange.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isLocked ? 'In Use' : 'Available',
            style: TextStyle(
              fontSize: 10,
              color: isLocked ? Colors.orange.shade800 : Colors.green.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final MaterialColor color;

  const _CompactInfo({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}