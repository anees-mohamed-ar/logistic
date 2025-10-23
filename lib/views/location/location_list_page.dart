import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/location_controller.dart';
import 'package:logistic/models/location_model.dart';
import 'package:logistic/views/location/location_form_page.dart';
import 'package:logistic/widgets/custom_app_bar.dart';

class LocationListPage extends StatefulWidget {
  const LocationListPage({Key? key}) : super(key: key);

  @override
  State<LocationListPage> createState() => _LocationListPageState();
}

class _LocationListPageState extends State<LocationListPage> {
  final LocationController controller = Get.put(LocationController());
  final searchController = TextEditingController();
  final RxList<Location> filteredLocations = <Location>[].obs;

  @override
  void initState() {
    super.initState();
    // Initialize filteredLocations with all locations when they're loaded
    ever(controller.locations, (_) => _filterLocations());
    controller.fetchLocations();
    searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterLocations() {
    if (controller.locations.isEmpty) return;
    
    final query = searchController.text.trim().toLowerCase();
    
    if (query.isEmpty) {
      filteredLocations.assignAll(controller.locations);
    } else {
      filteredLocations.assignAll(controller.locations.where((location) {
        return location.branchName.toLowerCase().contains(query) ||
            (location.branchCode?.toLowerCase() ?? '').contains(query) ||
            (location.contactPerson?.toLowerCase() ?? '').contains(query) ||
            (location.phoneNumber?.contains(query) ?? false);
      }).toList());
    }
    
    // Force UI update
    filteredLocations.refresh();
  }

  Future<void> _deleteLocation(String id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Location'),
        content: const Text('Are you sure you want to delete this location?'),
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
      await controller.deleteLocation(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Location Management'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search locations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Always use filteredLocations which is kept in sync by _filterLocations
              final locations = filteredLocations.isEmpty && searchController.text.isEmpty
                  ? controller.locations
                  : filteredLocations;

              if (locations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchController.text.isEmpty
                            ? 'No locations found'
                            : 'No matching locations',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (searchController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'No results for "${searchController.text}"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: controller.fetchLocations,
                        icon: const Icon(Icons.refresh),
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

              return RefreshIndicator(
                onRefresh: controller.fetchLocations,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return _buildLocationCard(location);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const LocationFormPage()),
        backgroundColor: const Color(0xFF1E2A44),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLocationCard(Location location) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.location_on, color: Colors.blue),
        ),
        title: Text(
          location.branchName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${location.branchCode} • ${location.contactPerson}'),
            if (location.phoneNumber.isNotEmpty)
              Text(
                location.phoneNumber,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => Get.to(() => LocationFormPage(location: location)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            // IconButton(
            //   icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            //   onPressed: () => _deleteLocation(location.id!),
            //   padding: EdgeInsets.zero,
            //   constraints: const BoxConstraints(),
            // ),
          ],
        ),
        onTap: () => Get.to(() => LocationFormPage(location: location)),
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
