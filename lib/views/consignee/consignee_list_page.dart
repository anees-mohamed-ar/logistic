import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/consignee_controller.dart';
import 'package:logistic/models/consignee.dart';
import 'package:logistic/widgets/custom_app_bar.dart';
import 'add_edit_consignee_page.dart';

class ConsigneeListPage extends StatelessWidget {
  final ConsigneeController controller = Get.put(ConsigneeController());

  ConsigneeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConsigneeController>();

    return Scaffold(
      appBar: CustomAppBar(title: 'Consignees'),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.filteredConsignees.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredConsignees.isEmpty) {
          if (controller.searchController.text.isNotEmpty) {
            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildSearchBar(controller),
                ),
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No consignees found',
                          style: TextStyle(fontSize: 16),
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
                const Text('No consignees found'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ElevatedButton.icon(
                    onPressed: controller.fetchConsignees,
                    icon: const Icon(Icons.refresh),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 12.0,
                      ),
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

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(controller),
            ),
            // Consignees List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchConsignees(),
                child: ListView.builder(
                  cacheExtent: 1000,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  itemCount: controller.filteredConsignees.length,
                  itemBuilder: (context, index) {
                    final consignee = controller.filteredConsignees[index];
                    return _buildConsigneeCard(consignee);
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddEditConsigneePage()),
        backgroundColor: const Color(0xFF1E2A44),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchBar(ConsigneeController controller) {
    return TextField(
      controller: controller.searchController,
      decoration: InputDecoration(
        hintText: 'Search consignees...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        suffixIcon: controller.searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.searchController.clear();
                  controller.filterConsignees('');
                },
              )
            : null,
      ),
      onChanged: (value) => controller.filterConsignees(value),
    );
  }

  Widget _buildConsigneeCard(Consignee consignee) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            consignee.consigneeName.isNotEmpty
                ? consignee.consigneeName[0].toUpperCase()
                : 'C',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        title: Text(
          consignee.consigneeName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (consignee.phoneNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      consignee.phoneNumber,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (consignee.email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        consignee.email,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onTap: () => Get.to(() => AddEditConsigneePage(consignee: consignee)),
      ),
    );
  }

  void _navigateToEditPage(Consignee consignee) {
    Get.to(() => AddEditConsigneePage(consignee: consignee));
  }
}
