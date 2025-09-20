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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchConsignees,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.consignees.isEmpty) {
          return const Center(child: Text('No consignees found'));
        }

        return ListView.builder(
          itemCount: controller.consignees.length,
          itemBuilder: (context, index) {
            final consignee = controller.consignees[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(consignee.consigneeName),
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
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddEditConsigneePage()),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToEditPage(Consignee consignee) {
    Get.to(() => AddEditConsigneePage(consignee: consignee));
  }
}
