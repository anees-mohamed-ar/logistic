import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logistic/controller/gst_controller.dart';
import 'package:logistic/models/gst_model.dart';
import 'package:logistic/widgets/custom_app_bar.dart';
import 'gst_form_page.dart';

class GstListPage extends StatelessWidget {
  final GstController controller = Get.put(GstController());
  final _dateFormat = DateFormat('dd-MM-yyyy');
  final searchController = TextEditingController();

  GstListPage({Key? key}) : super(key: key) {
    searchController.addListener(() {
      controller.filterGstEntries(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'GST Management'),
      body: Obx(() {
        if (controller.isLoading.value && controller.filteredGstList.isEmpty) {
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
                  onPressed: controller.refreshGstList,
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

        if (controller.filteredGstList.isEmpty) {
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
                          'No matching GST entries found',
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
                const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No GST entries found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: controller.refreshGstList,
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
            // GST List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.refreshGstList(),
                child: ListView.builder(
                  cacheExtent: 1000,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  itemCount: controller.filteredGstList.length,
                  itemBuilder: (context, index) {
                    final gst = controller.filteredGstList[index];
                    return _buildGstCard(context, gst);
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => GstFormPage()),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search by HSN...',
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
                  controller.filterGstEntries('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildGstCard(BuildContext context, GstModel gst) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.receipt, color: Colors.green),
        ),
        title: Text(
          'HSN: ${gst.hsn}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Date: ${_dateFormat.format(gst.date)}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildTaxChip(context, 'CGST', '${gst.cgst}%'),
                _buildTaxChip(context, 'SGST', '${gst.sgst}%'),
                _buildTaxChip(context, 'IGST', '${gst.igst}%'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
          onPressed: () => Get.to(() => GstFormPage(gst: gst)),
        ),
        onTap: () => Get.to(() => GstFormPage(gst: gst)),
      ),
    );
  }

  Widget _buildTaxChip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
