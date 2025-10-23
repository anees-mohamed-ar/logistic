import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/supplier_controller.dart';
import 'package:logistic/models/supplier_model.dart';
import 'package:logistic/views/supplier/supplier_form_page.dart';
import 'package:logistic/widgets/custom_app_bar.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({Key? key}) : super(key: key);

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  final SupplierController controller = Get.put(SupplierController());
  final searchController = TextEditingController();
  final RxList<Supplier> filteredSuppliers = <Supplier>[].obs;

  @override
  void initState() {
    super.initState();
    // Initialize filteredSuppliers with all suppliers when they're loaded
    ever(controller.suppliers, (_) => _filterSuppliers());
    controller.fetchSuppliers();
    searchController.addListener(_filterSuppliers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterSuppliers() {
    if (controller.suppliers.isEmpty) return;

    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      filteredSuppliers.assignAll(controller.suppliers);
    } else {
      filteredSuppliers.assignAll(
        controller.suppliers.where((supplier) {
          return supplier.supplierName.toLowerCase().contains(query) ||
              (supplier.contact ?? '').toLowerCase().contains(query) ||
              (supplier.mobileNumber ?? '').toLowerCase().contains(query) ||
              (supplier.gst ?? '').toLowerCase().contains(query) ||
              (supplier.panNumber ?? '').toLowerCase().contains(query);
        }).toList(),
      );
    }

    // Force UI update
    filteredSuppliers.refresh();
  }

  Future<void> _deleteSupplier(String? id) async {
    if (id == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Supplier'),
        content: const Text('Are you sure you want to delete this supplier?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteSupplier(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Supplier Management'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search suppliers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.suppliers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Always use filteredSuppliers which is kept in sync by _filterSuppliers
              final suppliers =
                  filteredSuppliers.isEmpty && searchController.text.isEmpty
                  ? controller.suppliers
                  : filteredSuppliers;

              if (suppliers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        searchController.text.isEmpty
                            ? 'No suppliers found'
                            : 'No matching suppliers',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      if (searchController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'No results for "${searchController.text}"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: controller.fetchSuppliers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2A44),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.fetchSuppliers,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return _buildSupplierCard(supplier);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const SupplierFormPage()),
        backgroundColor: const Color(0xFF1E2A44),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: const Icon(Icons.business, color: Colors.purple),
        ),
        title: Text(
          supplier.supplierName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.contact?.isNotEmpty ?? false)
              Text(supplier.contact ?? ''),
            if (supplier.mobileNumber?.isNotEmpty ?? false)
              Text(
                supplier.mobileNumber ?? '',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () =>
                  Get.to(() => SupplierFormPage(supplier: supplier)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            // IconButton(
            //   icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            //   onPressed: () => _deleteSupplier(supplier.id),
            //   padding: EdgeInsets.zero,
            //   constraints: const BoxConstraints(),
            // ),
          ],
        ),
        onTap: () => Get.to(() => SupplierFormPage(supplier: supplier)),
      ),
    );
  }
}
