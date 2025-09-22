import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/consignee_controller.dart';
import 'add_edit_consignee_page.dart';
import '../../../models/consignee.dart';
import '../../../widgets/custom_app_bar.dart';

class ConsigneeListPage extends StatelessWidget {
  final ConsigneeController controller = Get.put(ConsigneeController());

  ConsigneeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Consignees',
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.consignees.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.consignees.isEmpty) {
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
          onRefresh: () => controller.fetchConsignees(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
            itemCount: controller.consignees.length,
            itemBuilder: (context, index) {
              final consignee = controller.consignees[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                    consignee.consigneeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GST: ${consignee.gst}'),
                      Text('Location: ${consignee.location}, ${consignee.state}'),
                      Text('Contact: ${consignee.contact} (${consignee.mobileNumber})'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToEditPage(consignee),
                      ),
                    ],
                  ),
                  onTap: () => _navigateToEditPage(consignee),
                ),
              );
            },
          ),
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

  void _navigateToEditPage(Consignee consignee) {
    Get.to(() => AddEditConsigneePage(consignee: consignee));
  }
}
