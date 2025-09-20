import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/consignor_controller.dart';
import 'package:logistic/widgets/custom_app_bar.dart';
import 'add_edit_consignor_page.dart';
import 'package:logistic/models/consignor.dart';
import 'package:logistic/widgets/custom_app_bar.dart';

class ConsignorListPage extends StatelessWidget {
  final ConsignorController controller = Get.put(ConsignorController());

  ConsignorListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Consignors',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetchConsignors,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.consignors.isEmpty) {
          return const Center(child: Text('No consignors found'));
        }

        return ListView.builder(
          itemCount: controller.consignors.length,
          itemBuilder: (context, index) {
            final consignor = controller.consignors[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(consignor.consignorName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GST: ${consignor.gst}'),
                    Text('Location: ${consignor.location}, ${consignor.state}'),
                    Text('Contact: ${consignor.contact} (${consignor.mobileNumber})'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToEditPage(consignor),
                    ),
                  ],
                ),
                onTap: () => _navigateToEditPage(consignor),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddEditConsignorPage()),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToEditPage(Consignor consignor) {
    Get.to(() => AddEditConsignorPage(consignor: consignor));
  }
}
