import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/customer_controller.dart';
import 'package:logistic/models/customer_model.dart';
import 'package:logistic/widgets/custom_app_bar.dart';
import 'customer_form_page.dart';

class CustomerListPage extends StatelessWidget {
  final CustomerController controller = Get.put(CustomerController());
  final searchController = TextEditingController();

  CustomerListPage({Key? key}) : super(key: key) {
    searchController.addListener(() {
      controller.filterCustomers(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Customer Management'),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.filteredCustomers.isEmpty) {
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
                  onPressed: controller.fetchCustomers,
                  icon: const Icon(Icons.refresh),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 12.0,
                    ),
                    child: Text('Retry'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.filteredCustomers.isEmpty) {
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
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No matching customers found',
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
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No customers found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: controller.fetchCustomers,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
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
            // Customers List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.refreshCustomers(),
                child: ListView.builder(
                  cacheExtent: 1000,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  itemCount: controller.filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = controller.filteredCustomers[index];
                    return _buildCustomerCard(context, customer);
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => CustomerFormPage()),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search customers...',
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
                  controller.filterCustomers('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            customer.customerName.isNotEmpty
                ? customer.customerName[0].toUpperCase()
                : 'C',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
        title: Text(
          customer.customerName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.address,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (customer.phoneNumber.isNotEmpty ||
                customer.mobileNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      customer.phoneNumber.isNotEmpty
                          ? customer.phoneNumber
                          : customer.mobileNumber,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (customer.gst.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'GST: ${customer.gst}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onTap: () => Get.to(() => CustomerFormPage(customer: customer)),
      ),
    );
  }
}
