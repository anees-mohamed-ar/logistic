import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/branch_controller.dart';
import 'package:logistic/models/branch.dart';
import 'package:logistic/views/branch/add_edit_branch_page.dart';
import 'package:logistic/widgets/custom_app_bar.dart';

class BranchListPage extends StatefulWidget {
  const BranchListPage({Key? key}) : super(key: key);

  @override
  State<BranchListPage> createState() => _BranchListPageState();
}

class _BranchListPageState extends State<BranchListPage> {
  final BranchController controller = Get.put(BranchController());
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.fetchBranches();
    searchController.addListener(() {
      controller.filterBranches(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Branch Management'),
      body: Obx(() {
        if (controller.isLoading.value && controller.filteredBranches.isEmpty) {
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
                  onPressed: controller.fetchBranches,
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
              ],
            ),
          );
        }

        if (controller.filteredBranches.isEmpty) {
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
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No matching branches found',
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
                const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No branches found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: controller.fetchBranches,
                  icon: const Icon(Icons.refresh, size: 18),
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

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchBar(),
            ),
            // Branches List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.refreshBranches(),
                child: ListView.builder(
                  cacheExtent: 1000,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  itemCount: controller.filteredBranches.length,
                  itemBuilder: (context, index) {
                    final branch = controller.filteredBranches[index];
                    return _buildBranchCard(branch);
                  },
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddEditBranchPage()),
        backgroundColor: const Color(0xFF1E2A44),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, code, address, or phone...',
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
                  controller.filterBranches('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildBranchCard(Branch branch) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.business, color: Colors.blue),
        ),
        title: Text(
          branch.branchName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${branch.branchCode}'),
            if (branch.phone != null) Text('Phone: ${branch.phone}'),
            Text('Company: ${branch.companyName}',
                style: const TextStyle(fontSize: 12)),
            Text('Status: ${branch.status}',
                style: TextStyle(
                  fontSize: 12,
                  color: branch.status.toLowerCase() == 'active'
                      ? Colors.green
                      : Colors.red,
                )),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _navigateToEditPage(branch),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteBranch(branch.branchId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: () => _navigateToEditPage(branch),
      ),
    );
  }

  void _navigateToEditPage(Branch branch) {
    Get.to(() => AddEditBranchPage(branch: branch));
  }

  void _deleteBranch(int id) {
    Get.defaultDialog(
      title: 'Delete Branch',
      content: const Text('Are you sure you want to delete this branch?'),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Get.back();
            final success = await controller.deleteBranch(id);
            if (success) {
              Get.snackbar('Success', 'Branch deleted successfully');
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
