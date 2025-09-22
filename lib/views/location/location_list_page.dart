import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/location_controller.dart';
import 'package:logistic/models/location_model.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/views/location/location_form_page.dart';
import 'package:logistic/widgets/main_layout.dart';

class LocationListPage extends StatelessWidget {
  final LocationController _controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Location Management',
      child: Stack(
        children: [
          Obx(() {
            if (_controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (_controller.locations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No locations found'),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: ElevatedButton.icon(
                        onPressed: _controller.fetchLocations,
                        icon: const Icon(Icons.refresh),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                          child: Text('Retry'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2A44),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _controller.fetchLocations(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                itemCount: _controller.locations.length,
                itemBuilder: (context, index) {
                final location = _controller.locations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(location.branchName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(location.address),
                        if (location.contactPerson.isNotEmpty)
                          Text('Contact: ${location.contactPerson}'),
                        if (location.phoneNumber.isNotEmpty)
                          Text('Phone: ${location.phoneNumber}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => Get.toNamed(
                            AppRoutes.locationForm,
                            arguments: location,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            );
          }),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => Get.toNamed(AppRoutes.locationForm),
              backgroundColor: const Color(0xFF1E2A44),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
