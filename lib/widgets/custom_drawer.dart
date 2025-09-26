import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/api_config.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  bool _isManagementExpanded = false;
  String _selectedItem = '';

  @override
  void initState() {
    super.initState();
    _selectedItem = Get.currentRoute;
  }

  @override
  Widget build(BuildContext context) {
    final idController = Get.find<IdController>();
    final isSmallScreen = MediaQuery.of(context).size.width < 700;

    return Drawer(
      width: isSmallScreen ? 280 : 320,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Enhanced User Header
          _buildUserHeader(idController),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Quick Access Section
                _buildSectionHeader('Quick Access'),
                _buildMenuItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: AppRoutes.home,
                  onTap: () => _navigateTo(AppRoutes.home),
                ),

                const SizedBox(height: 16),

                // Operations Section
                _buildSectionHeader('Operations'),
                _buildMenuItem(
                  icon: Icons.note_add_outlined,
                  title: 'New GC Note',
                  route: AppRoutes.gcForm,
                  onTap: () => _navigateTo(AppRoutes.gcForm),
                ),
                _buildMenuItem(
                  icon: Icons.list_alt_outlined,
                  title: 'GC List',
                  route: AppRoutes.gcList,
                  onTap: () => _navigateTo(AppRoutes.gcList),
                ),
                _buildMenuItem(
                  icon: Icons.update_outlined,
                  title: 'Update Transit',
                  route: AppRoutes.updateTransit,
                  onTap: () => _navigateTo(AppRoutes.updateTransit),
                ),

                // Admin Only Items
                Obx(() => idController.userRole.value == 'admin'
                    ? Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.bar_chart_outlined,
                      title: 'Reports',
                      route: AppRoutes.gcReport,
                      onTap: () => _navigateTo(AppRoutes.gcReport),
                    ),
                    const SizedBox(height: 16),

                    // Management Section (Expandable)
                    _buildExpandableSection(),
                  ],
                )
                    : const SizedBox.shrink()),

                const SizedBox(height: 16),

                // Settings Section
                _buildSectionHeader('Settings'),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Get.back();
                    // Navigate to settings
                  },
                ),
              ],
            ),
          ),

          // Footer Section
          _buildFooterSection(idController),
        ],
      ),
    );
  }

  Widget _buildUserHeader(IdController idController) {
    return Obx(() {
      final name = idController.userName.value;
      final email = idController.userEmail.value;
      final userId = idController.userId.value;
      final userRole = idController.userRole.value;
      final hasImage = userId.isNotEmpty;
      final imageUrl = hasImage
          ? '${ApiConfig.baseUrl}/profile/profile-picture/$userId'
          : '';

      return Container(
        padding: const EdgeInsets.fromLTRB(80, 60, 100, 24),
        decoration: const BoxDecoration(

          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E2A44),
              Color(0xFF414457),
            ],
          ),
        ),
        child: Column(
          children: [
            // Profile Picture
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: hasImage
                    ? ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildAvatarFallback(name);
                    },
                  ),
                )
                    : _buildAvatarFallback(name),
              ),
            ),

            const SizedBox(height: 16),

            // User Info
            Text(
              name.isNotEmpty ? name : 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            Text(
              email.isNotEmpty ? email : 'user@example.com',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              // overflow: TextOver,
            ),

            const SizedBox(height: 8),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: userRole == 'admin'
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                userRole.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A90E2),
            const Color(0xFF357ABD),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? route,
    required VoidCallback onTap,
    bool hasNotification = false,
    int notificationCount = 0,
  }) {
    final isSelected = route != null && _selectedItem == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? const Color(0xFF4A90E2).withOpacity(0.1) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4A90E2)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF1E2A44)
                : const Color(0xFF1E2A44),
          ),
        ),
        trailing: hasNotification && notificationCount > 0
            ? Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: Text(
            notificationCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildExpandableSection() {
    final idController = Get.find<IdController>();

    return Obx(() => idController.userRole.value == 'admin'
        ? Column(
      children: [
        // Management Header (Expandable)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isManagementExpanded
                ? const Color(0xFF4A90E2).withOpacity(0.05)
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                size: 20,
                color: Color(0xFF8B5CF6),
              ),
            ),
            title: const Text(
              'Management',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            trailing: AnimatedRotation(
              turns: _isManagementExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.expand_more,
                color: Color(0xFF64748B),
              ),
            ),
            onTap: () {
              setState(() {
                _isManagementExpanded = !_isManagementExpanded;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Expandable Management Items
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isManagementExpanded ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isManagementExpanded ? 1.0 : 0.0,
            child: _isManagementExpanded
                ? Container(
              margin: const EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  _buildSubMenuItem(
                    icon: Icons.local_shipping_outlined,
                    title: 'Truck Management',
                    route: AppRoutes.truckList,
                    onTap: () => _navigateTo(AppRoutes.truckList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.speed_outlined,
                    title: 'KM Management',
                    route: AppRoutes.kmList,
                    onTap: () => _navigateTo(AppRoutes.kmList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Locations',
                    route: AppRoutes.locationList,
                    onTap: () => _navigateTo(AppRoutes.locationList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.people_outline,
                    title: 'Customers',
                    route: AppRoutes.customerList,
                    onTap: () => _navigateTo(AppRoutes.customerList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Suppliers',
                    route: AppRoutes.supplierList,
                    onTap: () => _navigateTo(AppRoutes.supplierList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.person_outline,
                    title: 'Drivers',
                    route: AppRoutes.driverManagement,
                    onTap: () => _navigateTo(AppRoutes.driverManagement),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.business_outlined,
                    title: 'Consignors',
                    route: AppRoutes.consignorList,
                    onTap: () => _navigateTo(AppRoutes.consignorList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.person_pin_outlined,
                    title: 'Consignees',
                    route: AppRoutes.consigneeList,
                    onTap: () => _navigateTo(AppRoutes.consigneeList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Broker Management',
                    route: AppRoutes.brokerList,
                    onTap: () => _navigateTo(AppRoutes.brokerList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.scale_outlined,
                    title: 'Weight Management',
                    route: AppRoutes.weightRateList,
                    onTap: () => _navigateTo(AppRoutes.weightRateList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'GST Management',
                    route: AppRoutes.gstList,
                    onTap: () => _navigateTo(AppRoutes.gstList),
                  ),
                  _buildSubMenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'User Management',
                    route: AppRoutes.userManagement,
                    onTap: () => _navigateTo(AppRoutes.userManagement),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    )
        : const SizedBox.shrink());
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String title,
    String? route,
    required VoidCallback onTap,
  }) {
    final isSelected = route != null && _selectedItem == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        leading: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4A90E2)
                : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF1E2A44)
                : const Color(0xFF64748B),
          ),
        ),
        onTap: onTap,
        minLeadingWidth: 20,
      ),
    );
  }

  Widget _buildFooterSection(IdController idController) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Version Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logistics Pro',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E2A44),
                        ),
                      ),
                      Text(
                        'Version 1.2.0',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            margin: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(String route) {
    setState(() {
      _selectedItem = route;
    });

    Get.back();

    if (route == AppRoutes.home) {
      if (Get.currentRoute != AppRoutes.home) {
        Get.offAllNamed(AppRoutes.home);
      }
    } else {
      Get.toNamed(route);
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2A44),
          ),
        ),
        content: const Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final idController = Get.find<IdController>();
      idController.clearUserData();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}