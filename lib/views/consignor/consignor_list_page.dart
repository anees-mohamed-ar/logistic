import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/consignor_controller.dart';
import 'package:logistic/models/consignor.dart';
import 'package:logistic/widgets/custom_app_bar.dart';
import 'add_edit_consignor_page.dart';

class ConsignorListPage extends StatelessWidget {
  final ConsignorController controller = Get.put(ConsignorController());

  ConsignorListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Consignors',
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.consignors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.consignors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No consignors found'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ElevatedButton.icon(
                    onPressed: controller.fetchConsignors,
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

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search consignors...',
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
                            controller.filterConsignors('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) => controller.filterConsignors(value),
              ),
            ),
            // Consignors List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchConsignors(),
                child: ListView.builder(
                  // itemExtent: 100, // Fixed height for each item
                  cacheExtent: 1000, // Cache more items off-screen for smoother scrolling
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: controller.filteredConsignors.length,
                  itemBuilder: (context, index) {
                    final consignor = controller.filteredConsignors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            consignor.consignorName.isNotEmpty ? consignor.consignorName[0].toUpperCase() : 'C',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                        title: Text(
                          consignor.consignorName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (consignor.mobileNumber.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      consignor.mobileNumber,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            if (consignor.gst.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.receipt, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      consignor.gst,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            if (consignor.location.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${consignor.location}${consignor.state.isNotEmpty ? ', ${consignor.state}' : ''}',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        onTap: () => Get.to(() => AddEditConsignorPage(consignor: consignor)),
                      ),
                    );
                    
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddEditConsignorPage()),
        backgroundColor: const Color(0xFF1E2A44),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _navigateToEditPage(Consignor consignor) {
    Get.to(() => AddEditConsignorPage(consignor: consignor));
  }
}
