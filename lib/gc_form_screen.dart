import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:flutter/services.dart';
// Note: WeightRate is now defined in gc_form_controller.dart,
// so 'show WeightRate' import is redundant if not also needed from this file's context
// import 'package:logistic/controller/gc_form_controller.dart' show WeightRate;

class GCFormScreen extends StatefulWidget {
  const GCFormScreen({super.key});

  @override
  State<GCFormScreen> createState() => _GCFormScreenState();
}

class _GCFormScreenState extends State<GCFormScreen> {
  late final TextEditingController searchCtrl;

  @override
  void initState() {
    super.initState();
    searchCtrl = TextEditingController();
    
    // Check for edit mode and load GC data if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args != null && args is Map && args['isEditMode'] == true) {
        final gcData = args['gcData'] as Map<String, dynamic>;
        final controller = Get.find<GCFormController>();
        controller.loadGcData(gcData);
      }
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<GCFormController>()
        ? Get.find<GCFormController>()
        : Get.put(GCFormController(), permanent: true);
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Attach once; avoids repeated subscriptions on rebuilds
    controller.attachTabScrollListener(context);

    // Ensure consignors and consignees are fetched if not already
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.consignorsLoading.value && controller.consignors.length <= 1) {
        controller.fetchConsignors();
      }
      if (!controller.consigneesLoading.value && controller.consignees.length <= 1) {
        controller.fetchConsignees();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('GC Shipment Form'),
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Get.snackbar(
                'Help',
                'Fill all required fields and navigate through tabs',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.blueGrey,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Obx(
                    () => Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: controller.tabScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        4,
                            (index) => GestureDetector(
                          onTap: () => controller.changeTab(index),
                          child: AnimatedContainer(
                            duration: 300.ms,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: controller.currentTab.value == index
                                  ? theme.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  [
                                    Icons.local_shipping,
                                    Icons.group,
                                    Icons.inventory,
                                    Icons.attach_money,
                                  ][index],
                                  size: 16,
                                  color: controller.currentTab.value == index
                                      ? Colors.white
                                      : theme.hintColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  [
                                    'Shipment',
                                    'Parties',
                                    'Goods',
                                    'Charges',
                                  ][index],
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: controller.currentTab.value == index
                                        ? Colors.white
                                        : theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Obx(
                        () => AnimatedSwitcher(
                      duration: 300.ms,
                      child: [
                        _buildShipmentTab(context, controller, isSmallScreen),
                        _buildPartiesTab(context, controller, isSmallScreen),
                        _buildGoodsTab(context, controller, isSmallScreen),
                        _buildChargesTab(context, controller, isSmallScreen),
                      ][controller.currentTab.value],
                    ),
                  ),
                ),
              ),
              Obx(
                    () => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (controller.isDraftSaved.value)
                        Text(
                          'Draft saved automatically',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ).animate().fadeIn().then().fadeOut(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (controller.currentTab.value > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: controller.navigateToPreviousTab,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: theme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: BorderSide(
                                    color: theme.primaryColor,
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.arrow_back, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Previous',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (controller.currentTab.value > 0)
                            const SizedBox(width: 12),
                          if (controller.currentTab.value < 3)
                            Expanded(
                              flex: controller.currentTab.value > 0 ? 1 : 2,
                              child: ElevatedButton(
                                onPressed: controller.navigateToNextTab,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: theme.primaryColor,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      controller.currentTab.value < 3
                                          ? 'Next'
                                          : 'Submit',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (controller.currentTab.value == 3)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.submitFormToBackend,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                                child: controller.isLoading.value
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Submit Form',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShipmentTab(
      BuildContext context,
      GCFormController controller,
      bool isSmallScreen,
      ) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Branch & Basic Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.branchesLoading.value) {
                  return TextFormField(
                    readOnly: true,
                    decoration: _inputDecoration(
                      'Branch',
                      Icons.confirmation_number,
                      hintText: 'Loading branches...',
                    ),
                  );
                }
                return _buildDropdownField(
                  context: context,
                  label: 'Branch',
                  value: controller.selectedBranch.value,
                  items: controller.branches.toList(),
                  onChanged: (value) {
                    controller.selectedBranch.value = value!;
                    controller.autoSaveDraft();
                  },
                  compact: true,
                  searchable: true,
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.gcNumberCtrl,
                      decoration: _inputDecoration(
                        'GC Number',
                        Icons.confirmation_number,
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Obx(
                            () => TextFormField(
                          readOnly: true,
                          controller: controller.gcDateCtrl,
                          decoration: _inputDecoration(
                            'GC Date',
                            Icons.calendar_today,
                          ),
                          onTap: () => controller.selectDate(
                            context,
                            controller.gcDate,
                            textController: controller.gcDateCtrl,
                          ),
                          validator: (value) => controller.gcDate.value == null
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                TextFormField(
                  readOnly: true,
                  controller: controller.gcDateCtrl,
                  decoration: _inputDecoration('GC Date', Icons.calendar_today),
                  onTap: () => controller.selectDate(
                    context,
                    controller.gcDate,
                    textController: controller.gcDateCtrl,
                  ),
                  validator: (value) =>
                  controller.gcDate.value == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.eDaysCtrl,
                      decoration: _inputDecoration('E-Days', Icons.schedule),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) {
                        controller.updateDeliveryDateFromInputs();
                        controller.autoSaveDraft();
                      },
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Obx(
                            () => TextFormField(
                          readOnly: true,
                          controller: controller.deliveryDateCtrl,
                          decoration: _inputDecoration(
                            'Delivery Date',
                            Icons.calendar_today,
                          ),
                          enableInteractiveSelection: false,
                          validator: (value) =>
                          controller.deliveryDate.value == null
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                TextFormField(
                  readOnly: true,
                  controller: controller.deliveryDateCtrl,
                  decoration: _inputDecoration(
                    'Delivery Date',
                    Icons.calendar_today,
                  ),
                  enableInteractiveSelection: false,
                  validator: (value) =>
                  controller.deliveryDate.value == null ? 'Required' : null,
                ),
              const SizedBox(height: 16),
              Text(
                'Vehicle Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      if (controller.trucksLoading.value) {
                        return TextFormField(
                          readOnly: true,
                          decoration: _inputDecoration(
                            'Truck Number',
                            Icons.local_shipping,
                            hintText: 'Loading trucks...',
                          ),
                        );
                      }
                      return _buildDropdownField(
                        context: context,
                        label: 'Truck Number',
                        value: controller.selectedTruck.value,
                        items: controller.truckNumbers.toList(),
                        onChanged: (value) {
                          controller.selectedTruck.value = value!;
                          controller.truckNumberCtrl.text = value; // keep submission compatibility
                          controller.autoSaveDraft();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty || value == 'Select Truck') {
                            return 'Required';
                          }
                          return null;
                        },
                        compact: true,
                        searchable: true,
                      );
                    }),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: TextFormField(
                        controller: controller.poNumberCtrl,
                        decoration: _inputDecoration(
                          'PO Number',
                          Icons.description,
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                        onChanged: (_) => controller.autoSaveDraft(),
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                TextFormField(
                  controller: controller.poNumberCtrl,
                  decoration: _inputDecoration('PO Number', Icons.description),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                  onChanged: (_) => controller.autoSaveDraft(),
                ),
              const SizedBox(height: 16),
              // Truck Type below Truck Number
              TextFormField(
                controller: controller.truckTypeCtrl,
                decoration: _inputDecoration('Truck Type', Icons.local_shipping),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
                onChanged: (_) => controller.autoSaveDraft(),
              ),
              const SizedBox(height: 16),
              // From / To after PO Number
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.fromCtrl,
                      readOnly: true,
                      decoration: _inputDecoration(
                        'From',
                        Icons.location_on,
                        hintText: 'Select a consignor to auto-fill',
                      ),
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: TextFormField(
                        controller: controller.toCtrl,
                        readOnly: true,
                        decoration: _inputDecoration(
                          'To',
                          Icons.location_on,
                          hintText: 'Select a consignee to auto-fill',
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                TextFormField(
                  controller: controller.toCtrl,
                  readOnly: true,
                  decoration: _inputDecoration(
                    'To',
                    Icons.location_on,
                    hintText: 'Select a consignee to auto-fill',
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.tripIdCtrl,
                decoration: _inputDecoration('Trip ID', Icons.route),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
                onChanged: (_) => controller.autoSaveDraft(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartiesTab(
      BuildContext context,
      GCFormController controller,
      bool isSmallScreen,
      ) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Broker & Driver Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // Broker and Driver row
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      if (controller.brokersLoading.value) {
                        return TextFormField(
                          readOnly: true,
                          decoration: _inputDecoration(
                            'Broker Name',
                            Icons.person,
                            hintText: 'Loading brokers...',
                          ),
                        );
                      }
                      return _buildDropdownField(
                        context: context,
                        label: 'Broker Name',
                        value: controller.selectedBroker.value,
                        items: controller.brokers.toList(),
                        onChanged: (value) {
                          controller.selectedBroker.value = value!;
                          controller.brokerNameCtrl.text = value;
                          controller.autoSaveDraft();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty || value == 'Select Broker') {
                            return 'Required';
                          }
                          return null;
                        },
                        compact: true,
                        searchable: true,
                      );
                    }),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Obx(() {
                        if (controller.driversLoading.value) {
                          return TextFormField(
                            readOnly: true,
                            decoration: _inputDecoration(
                              'Driver Name',
                              Icons.person,
                              hintText: 'Loading drivers...',
                            ),
                          );
                        }
                        return _buildDropdownField(
                          context: context,
                          label: 'Driver Name',
                          value: controller.selectedDriver.value.isEmpty
                              ? 'Select Driver'
                              : controller.selectedDriver.value,
                          items: ['Select Driver', ...controller.drivers
                              .map((driver) => driver['driverName'].toString())
                              .whereType<String>()
                              .toList()],
                          onChanged: (value) {
                            if (value != null && value != 'Select Driver') {
                              final driver = controller.drivers.firstWhere(
                                    (d) => d['driverName'] == value,
                                orElse: () => {},
                              );
                              if (driver.isNotEmpty) {
                                // Update the observable first
                                controller.selectedDriver.value = driver['driverName']?.toString() ?? '';
                                // Then update the text controllers
                                controller.driverNameCtrl.text = controller.selectedDriver.value;
                                controller.driverPhoneCtrl.text = driver['phoneNumber']?.toString() ?? '';
                                controller.autoSaveDraft();
                              }
                            } else {
                              // Clear both the observable and text controllers
                              controller.selectedDriver.value = '';
                              controller.driverNameCtrl.clear();
                              controller.driverPhoneCtrl.clear();
                              controller.autoSaveDraft();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty || value == 'Select Driver') {
                              return 'Required';
                            }
                            return null;
                          },
                          compact: true,
                          searchable: true,
                        );
                      }),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                Obx(() {
                  if (controller.driversLoading.value) {
                    return TextFormField(
                      readOnly: true,
                      decoration: _inputDecoration(
                        'Driver Name',
                        Icons.person,
                        hintText: 'Loading drivers...',
                      ),
                    );
                  }
                  return _buildDropdownField(
                    context: context,
                    label: 'Driver Name',
                    value: controller.selectedDriver.value.isEmpty
                        ? 'Select Driver'
                        : controller.selectedDriver.value,
                    items: ['Select Driver', ...controller.drivers
                        .map((driver) => driver['driverName'].toString())
                        .whereType<String>()
                        .toList()],
                    onChanged: (value) {
                      if (value != null && value != 'Select Driver') {
                        final driver = controller.drivers.firstWhere(
                              (d) => d['driverName'] == value,
                          orElse: () => {},
                        );
                        if (driver.isNotEmpty) {
                          controller.selectedDriver.value = driver['driverName']?.toString() ?? '';
                          controller.driverNameCtrl.text = controller.selectedDriver.value;
                          controller.driverPhoneCtrl.text = driver['phoneNumber']?.toString() ?? '';
                          controller.autoSaveDraft();
                        }
                      } else {
                        controller.selectedDriver.value = '';
                        controller.driverNameCtrl.clear();
                        controller.driverPhoneCtrl.clear();
                        controller.autoSaveDraft();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty || value == 'Select Driver') {
                        return 'Required';
                      }
                      return null;
                    },
                    compact: true,
                    searchable: true,
                  );
                }),
              const SizedBox(height: 16),
              // Driver Phone Number
              TextFormField(
                controller: controller.driverPhoneCtrl,
                decoration: _inputDecoration(
                  'Driver Phone Number',
                  Icons.phone,
                  hintText: 'Select driver to auto-fill',
                ),
                keyboardType: TextInputType.phone,
                readOnly: true,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Consignor Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      if (controller.consignorsLoading.value) {
                        return TextFormField(
                          readOnly: true,
                          decoration: _inputDecoration(
                            'Consignor Name',
                            Icons.person,
                            hintText: 'Loading consignors...',
                          ),
                        );
                      }
                      return _buildDropdownField(
                        context: context,
                        label: 'Consignor Name',
                        value: controller.selectedConsignor.value,
                        items: controller.consignors.toList(),
                        onChanged: (value) {
                          controller.selectedConsignor.value = value!;
                          controller.consignorNameCtrl.text = value;
                          final info = controller.consignorInfo[value];
                          if (info != null) {
                            controller.consignorGstCtrl.text = info['gst'] ?? '';
                            final address = info['address'] ?? '';
                            controller.consignorAddressCtrl.text = address;
                            // Auto-fill From field with consignor's address
                            controller.fromCtrl.text = address;
                          }
                          controller.autoSaveDraft();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty || value == 'Select Consignor') {
                            return 'Required';
                          }
                          return null;
                        },
                        compact: true,
                        searchable: true,
                      );
                    }),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Tooltip(
                        message: 'e.g., 27AABCU9603R1Z',
                        child: TextFormField(
                          controller: controller.consignorGstCtrl,
                          decoration: _inputDecoration('GST', Icons.business),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                          onChanged: (_) => controller.autoSaveDraft(),
                        ),
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                Tooltip(
                  message: 'e.g., 27AABCU9603R1Z',
                  child: TextFormField(
                    controller: controller.consignorGstCtrl,
                    decoration: _inputDecoration('GST', Icons.business),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                    onChanged: (_) => controller.autoSaveDraft(),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.consignorAddressCtrl,
                decoration: _inputDecoration('Address', Icons.location_on),
                maxLines: 2,
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
                onChanged: (_) => controller.autoSaveDraft(),
              ),
              const SizedBox(height: 24),
              Text(
                'Consignee Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      if (controller.consigneesLoading.value) {
                        return TextFormField(
                          readOnly: true,
                          decoration: _inputDecoration(
                            'Consignee Name',
                            Icons.person,
                            hintText: 'Loading consignees...',
                          ),
                        );
                      }
                      return _buildDropdownField(
                        context: context,
                        label: 'Consignee Name',
                        value: controller.selectedConsignee.value,
                        items: controller.consignees.toList(),
                        onChanged: (value) {
                          controller.selectedConsignee.value = value!;
                          controller.consigneeNameCtrl.text = value;
                          final info = controller.consigneeInfo[value];
                          if (info != null) {
                            controller.consigneeGstCtrl.text = info['gst'] ?? '';
                            final address = info['address'] ?? '';
                            controller.consigneeAddressCtrl.text = address;
                            // Auto-fill To field with consignee's address
                            controller.toCtrl.text = address;
                          }
                          controller.autoSaveDraft();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty || value == 'Select Consignee') {
                            return 'Required';
                          }
                          return null;
                        },
                        compact: true,
                        searchable: true,
                      );
                    }),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Tooltip(
                        message: 'e.g., 27AABCU9603R1Z',
                        child: TextFormField(
                          controller: controller.consigneeGstCtrl,
                          decoration: _inputDecoration('GST', Icons.business),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                          onChanged: (_) => controller.autoSaveDraft(),
                        ),
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                Tooltip(
                  message: 'e.g., 27AABCU9603R1Z',
                  child: TextFormField(
                    controller: controller.consigneeGstCtrl,
                    decoration: _inputDecoration('GST', Icons.business),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                    onChanged: (_) => controller.autoSaveDraft(),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.consigneeAddressCtrl,
                decoration: _inputDecoration('Address', Icons.location_on),
                maxLines: 2,
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
                onChanged: (_) => controller.autoSaveDraft(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoodsTab(
      BuildContext context,
      GCFormController controller,
      bool isSmallScreen,
      ) {
    // Access WeightRate from the controller
    WeightRate? selectedWeightValue = controller.selectedWeight.value;

    // Convert WeightRate list to a list of strings for the searchable dropdown
    final List<String> weightOptions = controller.weightRates.map((w) => w.weight).toList();
    // Get the string representation of the currently selected WeightRate
    final String currentSelectedWeightString = selectedWeightValue?.weight ?? 'Select Weight';


    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Goods Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Select Weight dropdown (now searchable)
              Obx(() {
                if (controller.isLoadingRates.value) {
                  return TextFormField(
                    readOnly: true,
                    decoration: _inputDecoration(
                      'Weight',
                      Icons.scale,
                      hintText: 'Loading weight options...',
                    ),
                  );
                }
                return _buildDropdownField(
                  context: context,
                  label: 'Select Weight',
                  value: currentSelectedWeightString,
                  items: ['Select Weight', ...weightOptions], // Include 'Select Weight' as first option
                  onChanged: (selectedString) {
                    if (selectedString != null && selectedString != 'Select Weight') {
                      final selectedWeightObject = controller.weightRates.firstWhere(
                            (w) => w.weight == selectedString,
                        orElse: () => throw Exception('WeightRate not found for $selectedString'),
                      );
                      controller.onWeightSelected(selectedWeightObject);
                    } else {
                      controller.onWeightSelected(null); // Clear selection
                    }
                  },
                  validator: (value) =>
                  value == null || value.isEmpty || value == 'Select Weight' ? 'Required' : null,
                  compact: true,
                  searchable: true,
                );
              }),

              const SizedBox(height: 16),
              // Nature of Goods and Package Method - Conditional Layout
              if (!isSmallScreen) // For large screens, display side-by-side
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.natureGoodsCtrl,
                        decoration: _inputDecoration(
                          'Nature of Goods',
                          Icons.category,
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                        onChanged: (_) => controller.autoSaveDraft(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: controller.methodPackageCtrl,
                        decoration: _inputDecoration(
                          'Package Method',
                          Icons.inventory_2_outlined,
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                        onChanged: (_) => controller.autoSaveDraft(),
                      ),
                    ),
                  ],
                )
              else ...[ // For small screens, stack them vertically
                TextFormField(
                  controller: controller.natureGoodsCtrl,
                  decoration: _inputDecoration(
                    'Nature of Goods',
                    Icons.category,
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                  onChanged: (_) => controller.autoSaveDraft(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.methodPackageCtrl,
                  decoration: _inputDecoration(
                    'Package Method',
                    Icons.inventory_2_outlined,
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                  onChanged: (_) => controller.autoSaveDraft(),
                ),
              ],
              const SizedBox(height: 16),
              // KM and Rate in the same row
              Row(
                children: [
                  Expanded(
                    child: Obx(
                          () => TextFormField(
                        controller: controller.kmCtrl,
                        decoration: _inputDecoration(
                          'KM',
                          Icons.speed,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        readOnly: !controller.isKmEditable.value,
                        onChanged: (value) {
                          // The listener in GCFormController handles calculateRate and autoSaveDraft
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final km = double.tryParse(value);
                          if (km == null || km <= 0) return 'Invalid KM';
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller.rateCtrl,
                      readOnly: true, // Assuming Rate is always auto-calculated and read-only here
                      decoration: _inputDecoration(
                        'Rate (Auto)',
                        Icons.attach_money,
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Total in its own row
              Obx(() => TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: controller.calculatedGoodsTotal.value.isNotEmpty
                      ? '₹${controller.calculatedGoodsTotal.value}'
                      : '',
                ),
                decoration: _inputDecoration(
                  'Total',
                  Icons.calculate,
                ),
              )),
              const SizedBox(height: 16),
              // Private Mark in its own row
              TextFormField(
                controller: controller.remarksCtrl,
                decoration: _inputDecoration(
                  'Private Mark',
                  Icons.note_alt_outlined,
                  isOptional: true,
                ),
                onChanged: (_) => controller.autoSaveDraft(),
              ),
              const SizedBox(height: 16),
              // Charges in its own row
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: 'FTL'),
                decoration: _inputDecoration(
                  'Charges',
                  Icons.monetization_on_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChargesTab(
      BuildContext context,
      GCFormController controller,
      bool isSmallScreen,
      ) {
    return SingleChildScrollView(
      key: const ValueKey(3),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Charges & Billing',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Billing Address
              TextFormField(
                controller: controller.billingAddressCtrl,
                decoration: _inputDecoration(
                  'Billing Address',
                  Icons.location_on,
                ),
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onChanged: (_) => controller.autoSaveDraft(),
              ),
              const SizedBox(height: 16),

              // Delivery from & Special Instructions / Remarks
              TextFormField(
                controller: controller.deliveryInstructionsCtrl,
                decoration: _inputDecoration(
                  'Delivery from & Special Instructions / Remarks',
                  Icons.note_alt_outlined,
                ),
                maxLines: 2,
                onChanged: (_) => controller.autoSaveDraft(),
              ),
              const SizedBox(height: 16),

              // Goods & Service Tax Payer (Dropdown)
              Obx(() => _buildDropdownField(
                context: context,
                label: 'GST Payer', // New label for clarity
                value: controller.selectedGstPayer.value,
                items: controller.gstPayerOptions,
                onChanged: (value) {
                  controller.selectedGstPayer.value = value!;
                  controller.autoSaveDraft();
                },
                validator: (value) =>
                value == null || value.isEmpty || value == 'Select GST Payer' ? 'Required' : null,
                compact: true,
                searchable: false, // Not searchable as per request
              )),
              const SizedBox(height: 16),

              // Freight Charge (referenced from goods total)
              Obx(() => TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: controller.calculatedGoodsTotal.value.isNotEmpty
                      ? '₹${controller.calculatedGoodsTotal.value}'
                      : '0.00',
                ),
                decoration: _inputDecoration(
                  'Freight Charge',
                  Icons.local_shipping,
                ),
              )),
              const SizedBox(height: 16),

              // Hire Amount
              TextFormField(
                controller: controller.hireAmountCtrl,
                decoration: _inputDecoration(
                  'Hire Amount',
                  Icons.money,
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onChanged: (_) {
                  // Listener in controller updates balanceAmount
                  controller.autoSaveDraft();
                },
              ),
              const SizedBox(height: 16),

              // Advance Amount
              TextFormField(
                controller: controller.advanceAmountCtrl,
                decoration: _inputDecoration(
                  'Advance Amount',
                  Icons.payment,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  // Listener in controller updates balanceAmount
                  controller.autoSaveDraft();
                },
              ),
              const SizedBox(height: 16),

              // Balance Amount (read-only, calculated field)
              Obx(() => TextFormField(
                readOnly: true,
                controller: TextEditingController(text: controller.balanceAmount.value),
                decoration: _inputDecoration(
                  'Balance Amount',
                  Icons.account_balance_wallet,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    FormFieldValidator<String>? validator,
    bool compact = false,
    bool searchable = false,
  }) {
    // If the value passed is not in items, it means it's an unselected placeholder
    // or an old value not found in current list, so reset it to the first item (e.g., 'Select X').
    // This prevents the DropdownButtonFormField from throwing an error if 'value' is not in 'items'.
    String? effectiveValue = items.contains(value) ? value : items.firstWhere((element) => element.startsWith('Select'), orElse: () => items.first);


    if (searchable) {
      return _buildSearchableFormField(
        context: context,
        label: label,
        value: effectiveValue!, // Use effectiveValue
        items: items,
        onChanged: onChanged,
        validator: validator,
        compact: compact,
      );
    }
    return DropdownButtonFormField<String>(
      value: effectiveValue, // Use effectiveValue here
      decoration: _inputDecoration(label, _getIconForLabel(label), compact: compact),
      items: items.map((String val) { // Renamed 'value' to 'val' to avoid conflict
        return DropdownMenuItem<String>(
          value: val,
          child: Text(val, style: Theme.of(context).textTheme.bodyMedium),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
      isExpanded: true,
      isDense: compact,
      menuMaxHeight: compact ? 280 : null,
    );
  }

  Widget _buildSearchableFormField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    FormFieldValidator<String>? validator,
    bool compact = false,
  }) {
    return FormField<String>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return InkWell(
          onTap: () async {
            final selected = await _showSearchPicker(
              context: context,
              title: label,
              items: items,
              current: value,
            );
            if (selected != null) {
              onChanged(selected);
              state.didChange(selected);
            }
          },
          child: InputDecorator(
            decoration: _inputDecoration(label, _getIconForLabel(label), compact: compact).copyWith(
              errorText: state.errorText,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (value.isEmpty || value.startsWith('Select')) ? 'Select $label' : value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: (value.isEmpty || value.startsWith('Select')) ? Theme.of(context).hintColor : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.search, color: Color(0xFF6B7280), size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showSearchPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String current,
  }) async {
    List<String> filtered = List<String>.from(items);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select $title',
                              style: Theme.of(ctx).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              searchCtrl.clear(); // Clear search on close
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (q) {
                          setState(() {
                            final query = q.trim().toLowerCase();
                            filtered = items
                                .where((e) => e.toLowerCase().contains(query))
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                          child: Text(
                            'No results',
                            style: Theme.of(ctx).textTheme.bodyMedium,
                          ),
                        )
                            : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final val = filtered[index];
                            final selected = val == current;
                            return ListTile(
                              dense: true,
                              title: Text(val, overflow: TextOverflow.ellipsis),
                              trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
                              onTap: () {
                                searchCtrl.clear(); // Clear search when item is selected
                                Navigator.of(ctx).pop(val);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Branch':
        return Icons.business;
      case 'Broker Name':
        return Icons.person;
      case 'Consignor Name':
        return Icons.person;
      case 'Consignee Name':
        return Icons.person;
      case 'Payment Method':
        return Icons.payment;
      case 'Service Type':
        return Icons.delivery_dining;
      case 'Package Method':
        return Icons.inventory_2;
      case 'Truck Number':
        return Icons.local_shipping;
      case 'Select Weight': // Updated label for clarity
        return Icons.scale;
      case 'GST Payer':
        return Icons.receipt_long; // Icon for GST Payer
      default:
        return Icons.list;
    }
  }

  InputDecoration _inputDecoration(
      String label,
      IconData icon, {
        String? hintText,
        bool isOptional = false,
        bool compact = false,
      }) {
    return InputDecoration(
      labelText: label + (isOptional ? ' (Optional)' : ''),
      hintText: hintText,
      prefixIcon: Icon(icon, size: compact ? 18 : 20, color: const Color(0xFF6B7280)),
      contentPadding: EdgeInsets.symmetric(vertical: compact ? 6 : 12, horizontal: compact ? 12 : 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isOptional ? Colors.grey.withOpacity(0.3) : Colors.grey[400]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0B7C3)),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
}