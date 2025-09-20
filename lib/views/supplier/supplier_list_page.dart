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
              return const Center(child: Text('No suppliers found'));
            }

            return ListView.builder(
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
