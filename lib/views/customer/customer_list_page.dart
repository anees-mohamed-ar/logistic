import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/customer_controller.dart';
import 'package:logistic/models/customer_model.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/widgets/main_layout.dart';

class CustomerListPage extends StatelessWidget {
  final CustomerController controller = Get.put(CustomerController());
  
  CustomerListPage({Key? key}) : super(key: key) {
    print('CustomerListPage constructor called');
    // Explicitly fetch customers when the page is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Fetching customers...');
      controller.fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building CustomerListPage');
    
    return MainLayout(
      title: 'Customer Management',
      child: Stack(
        children: [
          Obx(() {
            print('Obx builder rebuilt. Loading: ${controller.isLoading.value}, Customer count: ${controller.customers.length}');
            if (controller.isLoading.value && controller.customers.isEmpty) {
              print('Showing loading indicator');
              return const Center(child: CircularProgressIndicator());
            }
            
            if (controller.customers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No customers found'),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: ElevatedButton.icon(
                        onPressed: controller.fetchCustomers,
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
              onRefresh: () => controller.fetchCustomers(),
              child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Space for FAB
              itemCount: controller.customers.length,
              itemBuilder: (context, index) {
                final customer = controller.customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(customer.customerName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.address),
                        if (customer.contact.isNotEmpty)
                          Text('Contact: ${customer.contact}'),
                        if (customer.phoneNumber.isNotEmpty || customer.mobileNumber.isNotEmpty)
                          Text('Phone: ${customer.phoneNumber.isNotEmpty ? customer.phoneNumber : customer.mobileNumber}'),
                        if (customer.gst.isNotEmpty)
                          Text('GST: ${customer.gst}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => Get.toNamed(
                            AppRoutes.customerForm,
                            arguments: customer,
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
              onPressed: () => Get.toNamed(AppRoutes.customerForm),
              backgroundColor: const Color(0xFF1E2A44),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
