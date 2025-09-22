import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/supplier_controller.dart';
import 'package:logistic/models/supplier_model.dart';
import 'package:logistic/routes.dart' show AppRoutes;
import 'package:logistic/widgets/main_layout.dart';

class SupplierListPage extends StatelessWidget {
  final SupplierController controller = Get.put(SupplierController());
  
  SupplierListPage({Key? key}) : super(key: key) {
    print('SupplierListPage constructor called');
    // Explicitly fetch suppliers when the page is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Fetching suppliers...');
      controller.fetchSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building SupplierListPage');
    
    return MainLayout(
      title: 'Supplier Management',
      child: Stack(
        children: [
          Obx(() {
            print('Obx builder rebuilt. Loading: ${controller.isLoading.value}, Supplier count: ${controller.suppliers.length}');
            if (controller.isLoading.value && controller.suppliers.isEmpty) {
              print('Showing loading indicator');
              return const Center(child: CircularProgressIndicator());
            }
            
            if (controller.suppliers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No suppliers found'),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: ElevatedButton.icon(
                        onPressed: controller.fetchSuppliers,
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
              onRefresh: () => controller.fetchSuppliers(),
              child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Space for FAB
              itemCount: controller.suppliers.length,
              itemBuilder: (context, index) {
                final supplier = controller.suppliers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(supplier.supplierName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GST: ${supplier.gst}'),
                        Text('Contact: ${supplier.contact}'),
                        Text('Phone: ${supplier.phoneNumber}'),
                        Text('Email: ${supplier.email}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Get.toNamed(AppRoutes.supplierForm, arguments: supplier);
                      },
                    ),
                    onTap: () {
                      // Navigate to supplier details/edit page
                      Get.toNamed(AppRoutes.supplierForm, arguments: supplier);
                    },
                  ),
                );
                },
              ),
            );
          }),
          
          // Add New Supplier FAB
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF1E2A44),
              onPressed: () {
                // Navigate to add new supplier page
                Get.toNamed(AppRoutes.supplierForm);
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
