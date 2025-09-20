import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/api_config.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final idController = Get.find<IdController>();
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Obx(() {
            final name = idController.userName.value;
            final email = idController.userEmail.value;
            final userId = idController.userId.value;
            final hasImage = userId.isNotEmpty;
            final imageUrl = hasImage
                ? '${ApiConfig.baseUrl}/profile/profile-picture/$userId'
                : '';

            return UserAccountsDrawerHeader(
              accountName: Text(
                name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                email,
                style: const TextStyle(fontSize: 14),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: hasImage
                    ? ClipOval(
                        child: Image.network(
                          imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to initials if image fails
                            return Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 40, color: Colors.blue),
                              ),
                            );
                          },
                        ),
                      )
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 40, color: Colors.blue),
                      ),
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2A44),
              ),
            );
          }),
          
          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              if (Get.currentRoute != AppRoutes.home) {
                Get.offAllNamed(AppRoutes.home);
              } else {
                Get.back();
              }
            },
          ),
          
          // Operations
          ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('New GC Note'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.gcForm);
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('GC List'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.gcList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Update Transit'),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.updateTransit);
            },
          ),
          Obx(() => idController.userRole.value == 'admin'
              ? ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Reports'),
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppRoutes.gcReport);
                  },
                )
              : const SizedBox.shrink()),

          // Fleet
          Obx(() => idController.userRole.value == 'admin'
              ? ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: const Text('Truck Management'),
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppRoutes.truckList);
                  },
                )
              : const SizedBox.shrink()),

          // Masters (Admin only)
          Obx(() => idController.userRole.value == 'admin'
              ? Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.speed),
                      title: const Text('KM Management'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.kmList);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Locations'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.locationList);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Customers'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.customerList);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.inventory),
                      title: const Text('Suppliers'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.supplierList);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: const Text('Drivers'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.driverManagement);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('Consignors'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.consignorList);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Consignees'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.consigneeList);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('Broker Management'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.brokerList);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.scale),
                      title: const Text('Weight Rate Management'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.weightRateList);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('GST Management'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.gstList);
                      },
                    ),
                    // Keep User Management accessible (admin only)
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings),
                      title: const Text('User Management'),
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.userManagement);
                      },
                    ),
                  ],
                )
              : const SizedBox.shrink()),

          // Utilities
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Get.back();
              // Navigate to settings
            },
          ),
          
          const Divider(),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2A44),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // Clear user data and navigate to login
                idController.clearUserData();
                Get.offAllNamed(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
