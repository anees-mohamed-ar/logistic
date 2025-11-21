import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/truck_controller.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/models/truck.dart';
import 'package:logistic/views/truck/truck_form_page.dart';
import 'package:logistic/widgets/custom_app_bar.dart';

class TruckListPage extends StatefulWidget {
  const TruckListPage({super.key});

  @override
  State<TruckListPage> createState() => _TruckListPageState();
}

class _TruckListPageState extends State<TruckListPage> {
  final TruckController controller = Get.put(TruckController());
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.fetchTrucks();
    searchController.addListener(() {
      controller.searchTrucks(searchController.text);
    });
  }

  Future<void> _deleteTruck(int id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Truck'),
        content: const Text('Are you sure you want to delete this truck?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.deleteTruck(id);
      if (success) {
        Get.snackbar('Success', 'Truck deleted successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Truck Management'),
      body: Obx(() {
        if (controller.isLoading.value && controller.filteredTrucks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.fetchTrucks,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2A44),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.filteredTrucks.isEmpty) {
          if (searchController.text.isNotEmpty) {
            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSearchBar(),
                ),
                // Empty state with search icon
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No matching trucks found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No trucks found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: controller.fetchTrucks,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2A44),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),
            // Trucks List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.refreshTrucks(),
                child: ListView.builder(
                  cacheExtent: 1000,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  itemCount: controller.filteredTrucks.length,
                  itemBuilder: (context, index) {
                    final truck = controller.filteredTrucks[index];
                    return _buildTruckCard(truck);
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const TruckFormPage()),
        backgroundColor: const Color(0xFF1E2A44),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search by vehicle number, owner, or engine number',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  controller.searchTrucks('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildTruckCard(Truck truck) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.local_shipping, color: Colors.orange),
        ),
        title: Text(
          truck.vechileNumber,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${truck.ownerName ?? 'No owner'} • ${truck.ownerMobileNumber ?? ''}',
            ),
            if (truck.engineeNumber?.isNotEmpty ?? false)
              Text(
                'Engine: ${truck.engineeNumber}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () async {
                final result = await Get.to(() => TruckFormPage(truck: truck));
                if (result == true) {
                  Get.snackbar(
                    'Success',
                    'Truck updated successfully',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            // const SizedBox(width: 8),
            // IconButton(
            //   icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            //   onPressed: () => _deleteTruck(truck.id!),
            //   padding: EdgeInsets.zero,
            //   constraints: const BoxConstraints(),
            // ),
          ],
        ),
        onTap: () async {
          Get.put(
            GCFormController(),
          ); // Initialize controller before navigating
          final result = await Get.to(() => TruckFormPage(truck: truck));
          if (result == true) {
            Get.snackbar(
              'Success',
              'Truck updated successfully',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Text(':  ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

//   // Future<void> _deleteTruck(String id) async {
//   //   final confirmed = await Get.dialog<bool>(
//   //     AlertDialog(
//   //       title: const Text('Delete Truck'),
//   //       content: const Text('Are you sure you want to delete this truck?'),
//   //       actions: [
//   //         TextButton(
//   //           onPressed: () => Get.back(result: false),
//   //           child: const Text('Cancel'),
//   //         ),
//   //         TextButton(
//   //           onPressed: () => Get.back(result: true),
//   //           child: const Text('Delete', style: TextStyle(color: Colors.red)),
//   //         ),
//   //       ],
//   //     ),
//     );
//
//     if (confirmed == true) {
//       await controller.deleteTruck(id as int);
//     }
//   }
// }
