import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/weight_to_rate_controller.dart';
import 'package:logistic/models/weight_to_rate.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/routes.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class WeightRateListPage extends StatelessWidget {
  final WeightToRateController _controller = Get.find<WeightToRateController>();

  WeightRateListPage({Key? key}) : super(key: key) {
    print('WeightRateListPage: Constructor called');
    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchWeightRates();
    });
  }

  Future<void> _refreshData() async {
    await _controller.fetchWeightRates();
  }

  @override
  Widget build(BuildContext context) {
    print('WeightRateListPage: Building widget');
    return MainLayout(
      title: 'Weight to Rate Management',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Add button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weight to Rate List',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.weightRateForm,
                    arguments: null,
                  )?.then((_) => _controller.fetchWeightRates()),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info card
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Manage your weight-based rates for different distance ranges.',
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ),
            ),
          ),

          // Data Table
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value &&
                  _controller.weightRates.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.error.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data: ${_controller.error.value}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _controller.fetchWeightRates,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (_controller.weightRates.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No weight rates found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => Get.toNamed(
                          AppRoutes.weightRateForm,
                          arguments: null,
                        )?.then((_) => _controller.fetchWeightRates()),
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Rate'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _controller.weightRates.length,
                  itemBuilder: (context, index) {
                    final rate = _controller.weightRates[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ExpansionTile(
                        title: Text(
                          rate.weight.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Tap to view rates',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              onPressed: () => Get.toNamed(
                                AppRoutes.weightRateEdit,
                                arguments: rate,
                              )?.then((_) => _controller.fetchWeightRates()),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _deleteWeightRate(rate),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRateItem(
                                  context,
                                  'Rate (0-250 KM)',
                                  '₹${rate.below250.toStringAsFixed(2)}',
                                ),
                                const SizedBox(height: 12),
                                _buildRateItem(
                                  context,
                                  'Rate (Above 250 KM)',
                                  '₹${rate.above250.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRateItem(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteWeightRate(WeightToRate weightRate) async {
    final confirmed =
        await Get.defaultDialog<bool>(
          title: 'Confirm Delete',
          middleText:
              'Are you sure you want to delete the weight rate for ${weightRate.weight}?',
          textConfirm: 'DELETE',
          textCancel: 'CANCEL',
          confirmTextColor: Colors.white,
          buttonColor: Colors.red,
          cancelTextColor: Colors.black54,
          onConfirm: () => Get.back(result: true),
          onCancel: () => Get.back(result: false),
        ) ??
        false;

    if (confirmed) {
      await _controller.deleteWeightRate(weightRate.id!);
    }
  }
}
