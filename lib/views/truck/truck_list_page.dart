import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/truck_controller.dart';
import 'package:logistic/models/truck.dart';
import 'package:logistic/routes.dart';
import 'package:logistic/widgets/custom_app_bar.dart';
import 'package:logistic/widgets/loading_indicator.dart';
import 'package:logistic/widgets/custom_text_field.dart';

class TruckListPage extends StatefulWidget {
  const TruckListPage({super.key});

  @override
  State<TruckListPage> createState() => _TruckListPageState();
}

class _TruckListPageState extends State<TruckListPage> {
  late final TruckController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<TruckController>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _controller.searchTrucks(query);
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _deleteTruck(int id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Truck'),
        content: const Text('Are you sure you want to delete this truck?'),
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
      final success = await _controller.deleteTruck(id);
      if (success) {
        Get.snackbar('Success', 'Truck deleted successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Truck Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed(AppRoutes.truckForm)?.then((_) => _controller.fetchTrucks()),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.trucks.isEmpty) {
          return const Center(child: LoadingIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search by vehicle number, owner, or engine number',
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildTruckList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTruckList() {
    if (_controller.error.value.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${_controller.error.value}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.fetchTrucks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_controller.filteredTrucks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _controller.searchQuery.isEmpty 
                  ? 'No trucks found' 
                  : 'No trucks found for "${_controller.searchQuery.value}"',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_controller.searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _controller.searchTrucks('');
                },
                child: const Text('Clear search'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _controller.filteredTrucks.length,
      itemBuilder: (context, index) {
        final truck = _controller.filteredTrucks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              truck.vechileNumber,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Owner: ${truck.ownerName ?? 'N/A'} • ${truck.ownerMobileNumber ?? 'N/A'}',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () {
                print('📝 Editing truck: ${truck.vechileNumber} (ID: ${truck.id})');
                Get.toNamed(
                  AppRoutes.truckForm,
                  arguments: truck,
                )?.then((_) => _controller.fetchTrucks());
              },
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Owner Name', truck.ownerName ?? 'N/A'),
                    _buildInfoRow('Address', truck.ownerAddress ?? 'N/A'),
                    _buildInfoRow('Mobile', truck.ownerMobileNumber ?? 'N/A'),
                    if (truck.ownerEmail?.isNotEmpty ?? false)
                      _buildInfoRow('Email', truck.ownerEmail!),
                    if (truck.ownerPanNumber?.isNotEmpty ?? false)
                      _buildInfoRow('PAN', truck.ownerPanNumber!),
                    const Divider(),
                    _buildInfoRow('Vehicle Type', truck.typeofVechile ?? 'N/A'),
                    _buildInfoRow('Engine No.', truck.engineeNumber ?? 'N/A'),
                    _buildInfoRow('Chassis No.', truck.chaseNumber ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
