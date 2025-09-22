import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/km_controller.dart';
import 'package:logistic/models/km_location.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/widgets/main_layout.dart';

class KMListPage extends StatelessWidget {
  final KMController controller = Get.put(KMController());

  KMListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'KM Management',
      child: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value && controller.kmList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (controller.kmList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No KM records found'),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: ElevatedButton.icon(
                        onPressed: controller.fetchKMList,
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
              onRefresh: () => controller.fetchKMList(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                itemCount: controller.kmList.length,
              itemBuilder: (context, index) {
                final km = controller.kmList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text('${km.from} to ${km.to}'),
                    subtitle: Text('${km.km} km'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => Get.toNamed(
                            AppRoutes.kmForm,
                            arguments: km,
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
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => Get.toNamed(AppRoutes.kmForm),
              backgroundColor: const Color(0xFF1E2A44),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
