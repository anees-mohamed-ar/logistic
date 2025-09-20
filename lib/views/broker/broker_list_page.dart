import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/broker_controller.dart';
import 'package:logistic/models/broker.dart';
import 'package:logistic/views/broker/add_edit_broker_page.dart';
import 'package:logistic/widgets/main_layout.dart';

class BrokerListPage extends StatelessWidget {
  final BrokerController controller = Get.put(BrokerController());

  BrokerListPage({Key? key}) : super(key: key) {
    controller.fetchBrokers();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Broker Management',
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.brokers.isEmpty) {
          return const Center(child: Text('No brokers found'));
        }

        return ListView.builder(
          itemCount: controller.brokers.length,
          itemBuilder: (context, index) {
            final broker = controller.brokers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(
                  broker.brokerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone: ${broker.phoneNumber}'),
                    Text('Email: ${broker.email}'),
                    Text('Commission: ${broker.commissionPercentage}%'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToEditPage(broker),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBroker(broker.id!),
                    ),
                  ],
                ),
                onTap: () => _navigateToEditPage(broker),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF1E2A44),
        onPressed: () => Get.to(() => AddEditBrokerPage()),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToEditPage(Broker broker) {
    Get.to(() => AddEditBrokerPage(broker: broker));
  }

  void _deleteBroker(int id) {
    Get.defaultDialog(
      title: 'Delete Broker',
      content: const Text('Are you sure you want to delete this broker?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Get.back();
            final success = await controller.deleteBroker(id);
            if (success) {
              Get.snackbar('Success', 'Broker deleted successfully');
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
