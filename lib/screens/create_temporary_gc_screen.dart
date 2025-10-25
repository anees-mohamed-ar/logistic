import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/temporary_gc_controller.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/controller/id_controller.dart';

class CreateTemporaryGCScreen extends StatefulWidget {
  const CreateTemporaryGCScreen({super.key});

  @override
  State<CreateTemporaryGCScreen> createState() => _CreateTemporaryGCScreenState();
}

class _CreateTemporaryGCScreenState extends State<CreateTemporaryGCScreen> {
  late final GCFormController gcController;
  late final TemporaryGCController tempGCController;
  late final IdController idController;

  @override
  void initState() {
    super.initState();
    gcController = Get.put(GCFormController(), permanent: true);
    tempGCController = Get.find<TemporaryGCController>();
    idController = Get.find<IdController>();
    
    // Clear form for fresh start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gcController.clearForm();
      gcController.isEditMode.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Temporary GC'),
        actions: [
          Obx(() => tempGCController.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Save as Temporary GC',
                  onPressed: _saveTemporaryGC,
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fill in the fields you want to pre-populate. Users will complete the remaining fields.',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // GC Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Information', Icons.info_outline),
                  _buildBasicInfoSection(),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Route Details', Icons.route),
                  _buildRouteSection(),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Party Details', Icons.business),
                  _buildPartySection(),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Goods Details', Icons.inventory_2_outlined),
                  _buildGoodsSection(),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Financial Details', Icons.attach_money),
                  _buildFinancialSection(),
                  
                  const SizedBox(height: 32),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => ElevatedButton.icon(
                      onPressed: tempGCController.isLoading.value
                          ? null
                          : _saveTemporaryGC,
                      icon: tempGCController.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        tempGCController.isLoading.value
                            ? 'Creating...'
                            : 'Create Temporary GC',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        // Branch selection
        Obx(() => DropdownButtonFormField<String>(
          value: gcController.selectedBranch.value == 'Select Branch'
              ? null
              : gcController.selectedBranch.value,
          decoration: const InputDecoration(
            labelText: 'Branch',
            border: OutlineInputBorder(),
          ),
          items: gcController.branches
              .where((branch) => branch != 'Select Branch')
              .map((branch) => DropdownMenuItem(
                    value: branch,
                    child: Text(branch),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              gcController.selectedBranch.value = value;
              gcController.selectedBranchCode.value =
                  gcController.branchCodeMap[value] ?? '';
            }
          },
        )),
        const SizedBox(height: 12),

        // Truck Type
        TextField(
          controller: gcController.truckTypeCtrl,
          decoration: const InputDecoration(
            labelText: 'Truck Type',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // PO Number
        TextField(
          controller: gcController.poNumberCtrl,
          decoration: const InputDecoration(
            labelText: 'PO Number',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteSection() {
    return Column(
      children: [
        TextField(
          controller: gcController.fromCtrl,
          decoration: const InputDecoration(
            labelText: 'From Location',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: gcController.toCtrl,
          decoration: const InputDecoration(
            labelText: 'To Location',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }

  Widget _buildPartySection() {
    return Column(
      children: [
        // Broker
        Obx(() => DropdownButtonFormField<String>(
          value: gcController.selectedBroker.value == 'Select Broker'
              ? null
              : gcController.selectedBroker.value,
          decoration: const InputDecoration(
            labelText: 'Broker',
            border: OutlineInputBorder(),
          ),
          items: gcController.brokers
              .where((broker) => broker != 'Select Broker')
              .map((broker) => DropdownMenuItem(
                    value: broker,
                    child: Text(broker),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              gcController.selectedBroker.value = value;
            }
          },
        )),
        const SizedBox(height: 12),

        // Consignor
        Obx(() => DropdownButtonFormField<String>(
          value: gcController.selectedConsignor.value == 'Select Consignor'
              ? null
              : gcController.selectedConsignor.value,
          decoration: const InputDecoration(
            labelText: 'Consignor',
            border: OutlineInputBorder(),
          ),
          items: gcController.consignors
              .where((consignor) => consignor != 'Select Consignor')
              .map((consignor) => DropdownMenuItem(
                    value: consignor,
                    child: Text(consignor),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              gcController.selectedConsignor.value = value;
            }
          },
        )),
        const SizedBox(height: 12),

        // Consignee
        Obx(() => DropdownButtonFormField<String>(
          value: gcController.selectedConsignee.value == 'Select Consignee'
              ? null
              : gcController.selectedConsignee.value,
          decoration: const InputDecoration(
            labelText: 'Consignee',
            border: OutlineInputBorder(),
          ),
          items: gcController.consignees
              .where((consignee) => consignee != 'Select Consignee')
              .map((consignee) => DropdownMenuItem(
                    value: consignee,
                    child: Text(consignee),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              gcController.selectedConsignee.value = value;
            }
          },
        )),
      ],
    );
  }

  Widget _buildGoodsSection() {
    return Column(
      children: [
        TextField(
          controller: gcController.natureGoodsCtrl,
          decoration: const InputDecoration(
            labelText: 'Goods Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: gcController.packagesCtrl,
                decoration: const InputDecoration(
                  labelText: 'No. of Packages',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: gcController.methodPackageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Packing Method',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    return Column(
      children: [
        TextField(
          controller: gcController.freightChargeCtrl,
          decoration: const InputDecoration(
            labelText: 'Freight Charge',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_rupee),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: gcController.advanceAmountCtrl,
          decoration: const InputDecoration(
            labelText: 'Advance Amount',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_rupee),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Future<void> _saveTemporaryGC() async {
    // Collect all form data
    final gcData = {
      'CompanyId': idController.companyId.value,
      'Branch': gcController.selectedBranch.value != 'Select Branch'
          ? gcController.selectedBranch.value
          : null,
      'BranchCode': gcController.selectedBranchCode.value.isNotEmpty
          ? gcController.selectedBranchCode.value
          : null,
      'TruckType': gcController.truckTypeCtrl.text.isNotEmpty
          ? gcController.truckTypeCtrl.text
          : null,
      'PoNumber': gcController.poNumberCtrl.text.isNotEmpty
          ? gcController.poNumberCtrl.text
          : null,
      'TruckFrom': gcController.fromCtrl.text.isNotEmpty
          ? gcController.fromCtrl.text
          : null,
      'TruckTo': gcController.toCtrl.text.isNotEmpty
          ? gcController.toCtrl.text
          : null,
      'BrokerNameShow': gcController.selectedBroker.value != 'Select Broker'
          ? gcController.selectedBroker.value
          : null,
      'Consignor': gcController.selectedConsignor.value != 'Select Consignor'
          ? gcController.selectedConsignor.value
          : null,
      'Consignee': gcController.selectedConsignee.value != 'Select Consignee'
          ? gcController.selectedConsignee.value
          : null,
      'GoodContain': gcController.natureGoodsCtrl.text.isNotEmpty
          ? gcController.natureGoodsCtrl.text
          : null,
      'NumberofPkg': gcController.packagesCtrl.text.isNotEmpty
          ? gcController.packagesCtrl.text
          : null,
      'MethodofPkg': gcController.methodPackageCtrl.text.isNotEmpty
          ? gcController.methodPackageCtrl.text
          : null,
      'FreightCharge': gcController.freightChargeCtrl.text.isNotEmpty
          ? gcController.freightChargeCtrl.text
          : null,
      'AdvanceAmount': gcController.advanceAmountCtrl.text.isNotEmpty
          ? gcController.advanceAmountCtrl.text
          : null,
    };

    // Remove null values
    gcData.removeWhere((key, value) => value == null);

    if (gcData.length <= 1) {
      // Only CompanyId is present
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill at least one field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await tempGCController.createTemporaryGC(gcData);
    
    if (success) {
      // Clear form and go back
      gcController.clearForm();
      Get.back();
    }
  }
}
