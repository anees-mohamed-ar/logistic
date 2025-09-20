import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/gst_controller.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:intl/intl.dart';

class GstListPage extends StatelessWidget {
  final GstController controller = Get.put(GstController());
  final _dateFormat = DateFormat('dd-MM-yyyy');

  GstListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'GST Management',
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E2A44),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.gstForm);
          if (result == true) {
            controller.refreshGstList();
          }
        },
        child: const Icon(Icons.add),
      ),
      child: Obx(() {
        if (controller.isLoading.value && controller.gstList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.error.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshGstList,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.gstList.isEmpty) {
          return const Center(
            child: Text('No GST entries found'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshGstList(),
          child: ListView.builder(
            itemCount: controller.gstList.length,
            itemBuilder: (context, index) {
              final gst = controller.gstList[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text('HSN: ${gst.hsn}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${_dateFormat.format(gst.date)}'),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CGST: ${gst.cgst}%'),
                          Text('SGST: ${gst.sgst}%'),
                          Text('IGST: ${gst.igst}%'),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            AppRoutes.gstForm,
                            arguments: gst,
                          );
                          if (result == true) {
                            controller.refreshGstList();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
