import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/controller/temporary_gc_controller.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logistic/widgets/gc_pdf.dart';
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
  final TemporaryGCController? tempController = Get.isRegistered<TemporaryGCController>()
      ? Get.find<TemporaryGCController>()
      : null;

  @override
  void initState() {
    super.initState();
    searchCtrl = TextEditingController();
    
    // Get the existing controller or create a new one if it doesn't exist
    final controller = Get.put(GCFormController(), permanent: true);
    
    // Check access when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final idController = Get.find<IdController>();
      final userId = idController.userId.value;

      if (userId.isEmpty) {
        Fluttertoast.showToast(
          msg: 'User ID not found. Please login again.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        Get.back();
        return;
      }

      if (controller.isTemporaryMode.value) {
        controller.clearForm();
        controller.prepareTemporaryGcForm();
      } else if (controller.isFillTemporaryMode.value) {
        // When filling temporary GC, check access and get next GC number
        final hasAccess = await controller.checkGCAccess(userId);
        if (!hasAccess) {
          Fluttertoast.showToast(
            msg: controller.accessMessage.value,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          Get.back();
          return;
        }

        try {
          final nextGC = await controller.fetchNextGCNumber(userId);
          if (nextGC != null) {
            controller.gcNumberCtrl.text = nextGC;
          }

          await controller.checkGCUsageAndWarn(userId);
        } catch (e) {
          print('Error in form initialization: $e');
        }
      } else if (!controller.isEditMode.value) {
        controller.clearForm();

        final hasAccess = await controller.checkGCAccess(userId);
        if (!hasAccess) {
          Fluttertoast.showToast(
            msg: controller.accessMessage.value,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          Get.back();
          return;
        }

        try {
          final nextGC = await controller.fetchNextGCNumber(userId);
          if (nextGC != null) {
            controller.gcNumberCtrl.text = nextGC;
          }

          await controller.checkGCUsageAndWarn(userId);
        } catch (e) {
          print('Error in form initialization: $e');
        }
      }

      controller.currentTab.value = 0;
    });
  }

  @override
  void dispose() {
    _unlockIfNeeded();
    searchCtrl.dispose();
    // Don't dispose the controller here as it's managed by GetX with permanent: true
    // The controller will be managed by GetX and can be reused
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<GCFormController>()
        ? Get.find<GCFormController>()
        : Get.put(GCFormController());
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Ensure the tab index stays within the available range (0-3)
    if (controller.currentTab.value > 3) {
      controller.currentTab.value = 3;
    } else if (controller.currentTab.value < 0) {
      controller.currentTab.value = 0;
    }

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

    return WillPopScope(
      onWillPop: () async {
        await _unlockIfNeeded();
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final isTemporary = controller.isTemporaryMode.value || controller.isFillTemporaryMode.value;

          if (!isTemporary) {
            // Regular GC form - no timer
            if (controller.isEditMode.value) {
              return const Text('Edit GC');
            } else {
              return const Text('GC Shipment Form');
            }
          }

          // Temporary GC mode - show timer
          final minutes = controller.remainingTime.value.inMinutes;
          final seconds = controller.remainingTime.value.inSeconds % 60;
          final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

          return Row(
            children: [
              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.remainingTime.value.inSeconds <= 30
                      ? Colors.red.shade600
                      : Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title text
              Text(
                controller.isTemporaryMode.value
                    ? 'Create Temporary GC'
                    : 'Fill Temporary GC',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }),
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, size: 24),
            tooltip: 'Export to PDF',
            onPressed: () => GCPdfGenerator.showPdfPreview(context, controller),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export_pdf',
                child: const Text('Save PDF to Device'),
                onTap: () => GCPdfGenerator.savePdfToDevice(controller),
              ),
              PopupMenuItem(
                value: 'share_pdf',
                child: const Text('Share PDF'),
                onTap: () => GCPdfGenerator.sharePdf(controller),
              ),
              PopupMenuItem(
                value: 'print_pdf',
                child: const Text('Print PDF'),
                onTap: () => GCPdfGenerator.printPdf(controller),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'help',
                child: const Text('Help'),
                onTap: () {
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
                          onTap: () {
                            controller.changeTab(index);
                            // Force UI rebuild
                            setState(() {});
                          },
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
                                    Icons.attach_file,
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
                                    'Attachments',
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
                        _buildAttachmentsTab(context, controller, isSmallScreen),
                      ][controller.currentTab.value.clamp(0, 3).toInt()],
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
                      Row(
                        children: [
                          if (controller.currentTab.value > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  controller.navigateToPreviousTab();
                                  // Force UI rebuild
                                  setState(() {});
                                },
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
                                onPressed: () {
                                  controller.navigateToNextTab();
                                  // Force UI rebuild
                                  setState(() {});
                                },
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
                                      'Next',
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
                                    : Obx(() => Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      controller.isTemporaryMode.value
                                          ? 'Create Temporary GC'
                                          : controller.isFillTemporaryMode.value
                                              ? 'Submit & Convert'
                                              : 'Submit Form',
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
                                )),
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
      ),
    );
  }

  Future<void> _unlockIfNeeded() async {
    if (tempController != null) {
      final controller = Get.isRegistered<GCFormController>()
          ? Get.find<GCFormController>()
          : null;
      if (controller != null && controller.isFillTemporaryMode.value && controller.tempGcNumber.value.isNotEmpty) {
        await tempController!.unlockTemporaryGC(controller.tempGcNumber.value);
        controller.isFillTemporaryMode.value = false;
        controller.tempGcNumber.value = '';
      }
    }
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
                return _buildDropdownField(
                  context: context,
                  label: 'Branch',
                  value: controller.selectedBranch.value,
                  items: controller.branches.toList(),
                  onChanged: controller.onBranchSelected,
                  isLoading: controller.branchesLoading.value,
                  error: controller.branchesError.value,
                  onRetry: () => controller.fetchBranches(),
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
                      readOnly: true,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: _inputDecoration(
                        'GC Number',
                        Icons.confirmation_number,
                      ),
                      validator: null,
                      onChanged: (_) {},
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
                    restrictToToday: true, // Only allow dates up to today for GC date
                  ),
                  validator: null,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.eDaysCtrl,
                      decoration: _inputDecoration('E-Days', Icons.schedule),
                      keyboardType: TextInputType.number,
                      validator: null,
                      onChanged: (_) {
                        controller.updateDeliveryDateFromInputs();
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
                          validator: null,
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
                  validator: null,
                ),
              const SizedBox(height: 16),
              Text(
                'Vehicle & Driver Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      return _buildDropdownField(
                        context: context,
                        label: 'Truck Number',
                        value: controller.selectedTruck.value,
                        items: controller.truckNumbers.toList(),
                        onChanged: (value) {
                          controller.selectedTruck.value = value!;
                          controller.truckNumberCtrl.text = value; // keep submission compatibility
                        },
                        validator: null,
                        compact: true,
                        searchable: true,
                        isLoading: controller.trucksLoading.value,
                        error: controller.trucksError.value,
                        onRetry: () => controller.fetchTrucks(),
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
                        onChanged: (_) {},
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                TextFormField(
                  controller: controller.poNumberCtrl,
                  decoration: _inputDecoration('PO Number', Icons.description),
                  validator: null,
                  onChanged: (_) {},
                ),
              const SizedBox(height: 16),
              // Truck Type and Driver Name row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.truckTypeCtrl,
                      decoration: _inputDecoration('Truck Type', Icons.local_shipping, compact: isSmallScreen),
                      validator: null,
                      onChanged: (_) {},
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Obx(() {
                        final driverNames = controller.drivers
                            .map((d) => d['driverName']?.toString() ?? '')
                            .where((name) => name.isNotEmpty)
                            .toList();
                            
                        final selectedDriver = controller.selectedDriver.value;
                        if (selectedDriver.isNotEmpty && !driverNames.contains(selectedDriver)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.selectedDriver.value = '';
                            controller.driverNameCtrl.clear();
                            controller.driverPhoneCtrl.clear();
                          });
                        }
                        
                        return _buildDropdownField(
                          context: context,
                          label: 'Driver Name',
                          value: driverNames.contains(selectedDriver) ? selectedDriver : '',
                          items: driverNames,
                          onChanged: (value) {
                            if (value != null && value.isNotEmpty) {
                              try {
                                final driver = controller.drivers.firstWhere(
                                  (d) => (d['driverName']?.toString() ?? '') == value,
                                );
                                controller.selectedDriver.value = value;
                                controller.driverNameCtrl.text = value;
                                controller.driverPhoneCtrl.text = driver['phoneNumber']?.toString() ?? '';
                              } catch (e) {
                                controller.selectedDriver.value = '';
                                controller.driverNameCtrl.clear();
                                controller.driverPhoneCtrl.clear();
                              }
                            } else {
                              controller.selectedDriver.value = '';
                              controller.driverNameCtrl.clear();
                              controller.driverPhoneCtrl.clear();
                            }
                          },
                          validator: null,
                          compact: true,
                          searchable: true,
                          isLoading: controller.driversLoading.value,
                          error: controller.driversError.value,
                          onRetry: () => controller.fetchDrivers(),
                        );
                      }),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                Obx(() {
                  final driverNames = controller.drivers
                      .map((d) => d['driverName']?.toString() ?? '')
                      .where((name) => name.isNotEmpty)
                      .toList();
                      
                  final selectedDriver = controller.selectedDriver.value;
                  if (selectedDriver.isNotEmpty && !driverNames.contains(selectedDriver)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      controller.selectedDriver.value = '';
                      controller.driverNameCtrl.clear();
                      controller.driverPhoneCtrl.clear();
                    });
                  }
                  
                  return _buildDropdownField(
                    context: context,
                    label: 'Driver Name',
                    value: driverNames.contains(selectedDriver) ? selectedDriver : '',
                    items: driverNames,
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final driver = controller.drivers.firstWhere(
                            (d) => (d['driverName']?.toString() ?? '') == value,
                          );
                          controller.selectedDriver.value = value;
                          controller.driverNameCtrl.text = value;
                          controller.driverPhoneCtrl.text = driver['phoneNumber']?.toString() ?? '';
                        } catch (e) {
                          controller.selectedDriver.value = '';
                          controller.driverNameCtrl.clear();
                          controller.driverPhoneCtrl.clear();
                        }
                      } else {
                        controller.selectedDriver.value = '';
                        controller.driverNameCtrl.clear();
                        controller.driverPhoneCtrl.clear();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                    compact: true,
                    searchable: true,
                    isLoading: controller.driversLoading.value,
                    error: controller.driversError.value,
                    onRetry: () => controller.fetchDrivers(),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.tripIdCtrl,
                decoration: _inputDecoration('Trip ID', Icons.route),
                validator: null,
                onChanged: (_) {},
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
                'Broker Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // Broker field only
              Obx(() {
                // Get the list of brokers, ensuring no empty or null names
                final brokerList = controller.brokers
                    .where((b) => b != null && b.isNotEmpty)
                    .toList();
                    
                // If the selected broker is not in the list, clear it
                final selectedBroker = controller.selectedBroker.value;
                if (selectedBroker.isNotEmpty && !brokerList.contains(selectedBroker)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.selectedBroker.value = '';
                    controller.brokerNameCtrl.clear();
                  });
                }
                
                return _buildDropdownField(
                  context: context,
                  label: 'Broker Name',
                  value: brokerList.contains(selectedBroker) ? selectedBroker : '',
                  items: brokerList,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedBroker.value = value;
                      controller.brokerNameCtrl.text = value;
                    } else {
                      controller.selectedBroker.value = '';
                      controller.brokerNameCtrl.clear();
                    }
                  },
                  validator: null,
                  compact: true,
                  searchable: true,
                  isLoading: controller.brokersLoading.value,
                  error: controller.brokersError.value,
                  onRetry: () => controller.fetchBrokers(),
                );
              }),
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
                      return _buildDropdownField(
                        context: context,
                        label: 'Consignor Name',
                        value: controller.selectedConsignor.value,
                        items: controller.consignors.toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedConsignor.value = value;
                            controller.consignorNameCtrl.text = value;
                            final info = controller.consignorInfo[value];
                            if (info != null) {
                              controller.consignorGstCtrl.text = info['gst'] ?? '';
                              controller.consignorAddressCtrl.text = info['address'] ?? '';
                              final location = info['location'] ?? '';
                              // Auto-fill From field with consignor's location when available, otherwise address
                              controller.fromCtrl.text = location.isNotEmpty ? location : (info['address'] ?? '');
                            }
                          }
                        },
                        validator: (value) => value == null || value.isEmpty || value == 'Select Consignor' 
                            ? 'Required' 
                            : null,
                        compact: true,
                        searchable: true,
                        isLoading: controller.consignorsLoading.value,
                        error: controller.consignorsError.value,
                        onRetry: () => controller.fetchConsignors(),
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
                          onChanged: (_) {},
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
                    validator: null,
                    onChanged: (_) {},
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.consignorAddressCtrl,
                decoration: _inputDecoration('Address', Icons.location_on),
                maxLines: 2,
                validator: null,
                onChanged: (_) {},
              ),
              const SizedBox(height: 24),
              Text(
                'Bill To Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      return _buildDropdownField(
                        context: context,
                        label: 'Bill To Name',
                        value: controller.selectedBillTo.value,
                        items: controller.billTos.toList(),
                        onChanged: controller.onBillToSelected,
                        validator: null,
                        compact: true,
                        searchable: true,
                        isLoading: controller.billTosLoading.value,
                        error: controller.billTosError.value,
                        onRetry: () => controller.fetchBillTos(),
                      );
                    }),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Tooltip(
                        message: 'e.g., 27AABCU9603R1Z',
                        child: TextFormField(
                          controller: controller.billToGstCtrl,
                          decoration: _inputDecoration('GST', Icons.business),
                          validator: null,
                          onChanged: (_) {},
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
                    controller: controller.billToGstCtrl,
                    decoration: _inputDecoration('GST', Icons.business),
                    validator: null,
                    onChanged: (_) {},
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.billToAddressCtrl,
                decoration: _inputDecoration('Address', Icons.location_on),
                maxLines: 2,
                validator: null,
                onChanged: (_) {},
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
                      return _buildDropdownField(
                        context: context,
                        label: 'Consignee Name',
                        value: controller.selectedConsignee.value,
                        items: controller.consignees.toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedConsignee.value = value;
                            controller.consigneeNameCtrl.text = value;
                            final info = controller.consigneeInfo[value];
                            if (info != null) {
                              controller.consigneeGstCtrl.text = info['gst'] ?? '';
                              final address = info['address'] ?? '';
                              controller.consigneeAddressCtrl.text = address;
                              final location = info['location'] ?? '';
                              final toValue = location.isNotEmpty ? location : address;
                              // Auto-fill To field and Billing Address with consignee's location/address
                              controller.toCtrl.text = toValue;
                              controller.billingAddressCtrl.text = address;
                            }
                          }
                        },
                        validator: null,
                        compact: true,
                        searchable: true,
                        isLoading: controller.consigneesLoading.value,
                        error: controller.consigneesError.value,
                        onRetry: () => controller.fetchConsignees(),
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
                          validator: null,
                          onChanged: (_) {},
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
                    validator: null,
                    onChanged: (_) {},
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.consigneeAddressCtrl,
                decoration: _inputDecoration('Address', Icons.location_on),
                maxLines: 2,
                validator: null,
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              // From / To fields
              Text(
                'Route Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.fromCtrl,
                readOnly: true,
                decoration: _inputDecoration(
                  'From',
                  Icons.location_on,
                  hintText: 'Select a consignor to auto-fill',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.toCtrl,
                readOnly: true,
                decoration: _inputDecoration(
                  'To',
                  Icons.location_on,
                  hintText: 'Select a consignee to auto-fill',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
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
              // const SizedBox(height: 16),

              // // Select Weight dropdown (now searchable)
              // Obx(() {
              //   // Show error state if there's an error
              //   if (controller.weightRatesError.isNotEmpty) {
              //     return _buildDropdownField(
              //       context: context,
              //       label: 'Select Weight',
              //       value: 'Error loading weights',
              //       items: const ['Error loading weights'],
              //       onChanged: (_) {}, // No-op function
              //       validator: null,
              //       compact: true,
              //       error: controller.weightRatesError.value,
              //       onRetry: () => controller.fetchWeightRates(),
              //     );
              //   }

              //   // Show loading state
              //   if (controller.isLoadingRates.value) {
              //     return TextFormField(
              //       decoration: InputDecoration(
              //         labelText: 'Select Weight',
              //         suffixIcon: const Padding(
              //           padding: EdgeInsets.all(8.0),
              //           child: CircularProgressIndicator(strokeWidth: 2),
              //         ),
              //         border: OutlineInputBorder(
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //       ),
              //       readOnly: true,
              //       controller: TextEditingController(text: 'Loading weight rates...'),
              //     );
              //   }
                
                // // Get the current selected weight string from the controller's selectedWeight
                // final selectedWeight = controller.selectedWeight.value;
                // final selectedWeightString = selectedWeight?.weight ?? 'Select Weight';
                
              //   return _buildDropdownField(
              //     context: context,
              //     label: 'Select Weight',
              //     value: selectedWeightString,
              //     items: ['Select Weight', ...weightOptions],
              //     onChanged: (selectedString) {
              //       if (selectedString != null && selectedString != 'Select Weight') {
              //         final selectedWeightObject = controller.weightRates.firstWhere(
              //               (w) => w.weight == selectedString,
              //           orElse: () => throw Exception('WeightRate not found for $selectedString'),
              //         );
              //         controller.onWeightSelected(selectedWeightObject);
              //       } else {
              //         controller.onWeightSelected(null);
              //       }
              //     },
              //     validator: (value) =>
              //     value == null || value.isEmpty || value == 'Select Weight' ? 'Required' : null,
              //     compact: true,
              //     searchable: true,
              //   );
              // }),

              const SizedBox(height: 16),

              // Number of Packages
              TextFormField(
                controller: controller.packagesCtrl,
                decoration: _inputDecoration(
                  'No. of Packages',
                  Icons.inventory_2_outlined,
                ),
                keyboardType: TextInputType.number,
                validator: null,
                onChanged: (_) {},
              ),
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
                        onChanged: (_) {},
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
                        onChanged: (_) {},
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
                  validator: null,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.methodPackageCtrl,
                  decoration: _inputDecoration(
                    'Package Method',
                    Icons.inventory_2_outlined,
                  ),
                  validator: null,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                // Delivery Special Instructions
                TextFormField(
                  controller: controller.deliveryInstructionsCtrl,
                  decoration: _inputDecoration(
                    'Delivery Special Instructions',
                    Icons.delivery_dining,
                    hintText: 'Enter any special delivery instructions',
                  ),
                  maxLines: 3,
                  validator: null,
                  onChanged: (_) {},
                ),
              ],
              // // const SizedBox(height: 16),
              // // // KM and Rate in the same row
              // // Row(
              // //   children: [
              // //     Expanded(
              // //       child: Obx(
              // //             () => TextFormField(
              // //           controller: controller.kmCtrl,
              // //           decoration: _inputDecoration(
              // //             'KM',
              // //             Icons.speed,
              // //           ),
              // //           keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // //           readOnly: !controller.isKmEditable.value,
              // //           onChanged: (value) {
              // //             // The listener in GCFormController handles calculateRate
              // //           },
              // //           validator: (value) {
              // //             if (value == null || value.isEmpty) return 'Required';
              // //             final km = double.tryParse(value);
              // //             if (km == null || km <= 0) return 'Invalid KM';
              // //             return null;
              // //           },
              // //         ),
              // //       ),
              // //     ),
              // //   ],
              // // ),
              // const SizedBox(height: 16),
              // // Rate in its own row
              // TextFormField(
              //   controller: controller.rateCtrl,
              //   readOnly: true, // Assuming Rate is always auto-calculated and read-only here
              //   decoration: _inputDecoration(
              //     'Rate per KM',
              //     Icons.attach_money,
              //   ),
              //   validator: null,
              // ),
              // const SizedBox(height: 16),
              // // Total in its own row
              // Obx(() => TextFormField(
              //   readOnly: true,
              //   controller: TextEditingController(
              //     text: controller.calculatedGoodsTotal.value.isNotEmpty
              //         ? '₹${controller.calculatedGoodsTotal.value}'
              //         : '',
              //   ),
              //   decoration: _inputDecoration(
              //     'Total',
              //     Icons.calculate,
              //   ),
              // )),
              const SizedBox(height: 16),
              
              // Invoice Details Section
              Text(
                'Invoice & E-way Bill Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              // Customer Invoice Number and Invoice Value
              if (!isSmallScreen)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.customInvoiceCtrl,
                        decoration: _inputDecoration(
                          'Cust Inv No',
                          Icons.receipt_long,
                          isOptional: true,
                        ),
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: controller.invValueCtrl,
                        decoration: _inputDecoration(
                          'Inv Value',
                          Icons.currency_rupee,
                          isOptional: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                )
              else ...[
                TextFormField(
                  controller: controller.customInvoiceCtrl,
                  decoration: _inputDecoration(
                    'Cust Inv No',
                    Icons.receipt_long,
                    isOptional: true,
                  ),
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.invValueCtrl,
                  decoration: _inputDecoration(
                    'Inv Value',
                    Icons.currency_rupee,
                    isOptional: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {},
                ),
              ],
              
              const SizedBox(height: 16),
              
              // E-way Bill Number
              TextFormField(
                controller: controller.ewayBillCtrl,
                decoration: _inputDecoration(
                  'Eway Bill No',
                  Icons.description,
                  isOptional: true,
                ),
                onChanged: (_) {},
              ),
              
              const SizedBox(height: 16),
              
              // E-way Bill Date and Expiry Date
              if (!isSmallScreen)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: controller.ewayBillDateCtrl,
                        decoration: _inputDecoration(
                          'Eway Bill Date',
                          Icons.calendar_today,
                          isOptional: true,
                        ),
                        onTap: () => controller.selectDate(
                          context,
                          controller.ewayBillDate,
                          textController: controller.ewayBillDateCtrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: controller.ewayExpiredCtrl,
                        decoration: _inputDecoration(
                          'Eway Bill Exp Date',
                          Icons.calendar_today,
                          isOptional: true,
                        ),
                        onTap: () => controller.selectDate(
                          context,
                          controller.ewayExpired,
                          textController: controller.ewayExpiredCtrl,
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                TextFormField(
                  readOnly: true,
                  controller: controller.ewayBillDateCtrl,
                  decoration: _inputDecoration(
                    'Eway Bill Date',
                    Icons.calendar_today,
                    isOptional: true,
                  ),
                  onTap: () => controller.selectDate(
                    context,
                    controller.ewayBillDate,
                    textController: controller.ewayBillDateCtrl,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  controller: controller.ewayExpiredCtrl,
                  decoration: _inputDecoration(
                    'Eway Bill Exp Date',
                    Icons.calendar_today,
                    isOptional: true,
                  ),
                  onTap: () => controller.selectDate(
                    context,
                    controller.ewayExpired,
                    textController: controller.ewayExpiredCtrl,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Actual Weight field
              TextFormField(
                controller: controller.actualWeightCtrl,
                decoration: _inputDecoration(
                  'Actual Weight (Kgs)',
                  Icons.scale,
                  isOptional: true,
                ),
                keyboardType: TextInputType.text,
                onChanged: (_) {},
              ),
              
              const SizedBox(height: 16),
              
              // GST Payer dropdown
              Obx(() {
                // Debug print to check the current selected value
                debugPrint('Current GST Payer in UI: ${controller.selectedGstPayer.value}');
                debugPrint('Available options: ${controller.gstPayerOptions}');
                
                return _buildDropdownField(
                  context: context,
                  label: 'GST Payer',
                  value: controller.selectedGstPayer.value,
                  items: controller.gstPayerOptions,
                  onChanged: (value) {
                    if (value != null) {
                      controller.onGstPayerSelected(value);
                    }
                  },
                  validator: null,
                  compact: true,
                  searchable: false,
                );
              }),
              
              const SizedBox(height: 16),
              
              // Payment Method dropdown
              Obx(() => _buildDropdownField(
                context: context,
                label: 'Payment Method',
                value: controller.selectedPayment.value,
                items: [ ...controller.paymentOptions],
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedPayment.value = value;
                  }
                },
                validator: null,
                compact: true,
                searchable: false,
              )),
              
              const SizedBox(height: 24),
              
              // Private Mark in its own row
              TextFormField(
                controller: controller.remarksCtrl,
                decoration: _inputDecoration(
                  'Private Mark',
                  Icons.note_alt_outlined,
                  isOptional: true,
                ),
                onChanged: (_) {},
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentsTab(
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
                'GC Attachments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Attach supporting documents for this GC. You can add documents to existing GCs or attach files before submission.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // File Attachments Section
              _buildFileAttachmentsSection(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileAttachmentsSection(BuildContext context, GCFormController controller) {
    return Obx(() {
      final files = controller.attachedFiles;
      final existingFiles = controller.existingAttachments;
      final isLoading = controller.isLoadingAttachments.value;
      final error = controller.attachmentsError.value;

      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'File Attachments',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (files.isNotEmpty) ...[
                    Text(
                      '${files.length} new file${files.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: controller.clearAllFiles,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear New'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Show loading state for existing attachments
              if (isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Show error state
              if (error.isNotEmpty && !isLoading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Existing attachments section
              if (existingFiles.isNotEmpty && !isLoading) ...[
                Text(
                  'Existing Attachments',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: existingFiles.length,
                    itemBuilder: (context, index) {
                      final file = existingFiles[index];
                      final fileName = file['name'] as String? ?? 'Unknown';
                      final fileSize = file['size'] as int? ?? 0;
                      final filename = file['filename'] as String? ?? '';

                      // Format file size
                      String formatFileSize(int bytes) {
                        if (bytes < 1024) return '$bytes B';
                        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
                        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                      }

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getFileIcon(filename.split('.').last),
                          color: _getFileColor(filename.split('.').last),
                          size: 20,
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          formatFileSize(fileSize),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 16),
                              onPressed: () => controller.previewAttachment(filename, context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Preview',
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, size: 16),
                              onPressed: () => controller.downloadAttachment(filename, context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Download',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // New attachments section
              if (files.isNotEmpty) ...[
                Text(
                  'New Attachments to Add',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final fileName = file['name'] as String? ?? 'Unknown';
                      final fileSize = file['size'] as int? ?? 0;
                      final extension = file['extension'] as String? ?? '';

                      // Format file size
                      String formatFileSize(int bytes) {
                        if (bytes < 1024) return '$bytes B';
                        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
                        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                      }

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getFileIcon(extension),
                          color: _getFileColor(extension),
                          size: 20,
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          formatFileSize(fileSize),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => controller.removeFile(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Add files button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.isPickingFiles.value
                      ? null
                      : () => controller.pickFiles(context),
                  icon: controller.isPickingFiles.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                  label: Text(
                    controller.isPickingFiles.value
                        ? 'Selecting files...'
                        : 'Add Files',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'You can attach any type of file (PDF, images, documents, etc.). Maximum 10 files, 10MB each.\n\n'
                'Tip: Hold Ctrl/Cmd to select multiple files, or click "Add Files" multiple times.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) return Icons.image;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    if (['txt'].contains(ext)) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String extension) {
    final ext = extension.toLowerCase();
    if (['pdf'].contains(ext)) return Colors.red;
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) return Colors.blue;
    if (['doc', 'docx'].contains(ext)) return Colors.blue[700]!;
    if (['xls', 'xlsx'].contains(ext)) return Colors.green;
    return Colors.grey;
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
    bool isLoading = false,
    String? error,
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);
    final isError = validator?.call(value) != null || error != null;

    // Show error state if there's an error message
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Show loading state
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.dividerColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final dropdown = DropdownButtonFormField<String>(
      value: (value.isEmpty || !items.contains(value)) ? null : value,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: item == 'Select $label' ? theme.hintColor : null,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isError ? theme.colorScheme.error : null,
        ),
        errorText: isError ? (error ?? validator!(value)) : null,
        errorStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isError ? theme.colorScheme.error : theme.dividerColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isError ? theme.colorScheme.error : theme.dividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isError ? theme.colorScheme.error : theme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      icon: Icon(
        Icons.arrow_drop_down,
        color: isError ? theme.colorScheme.error : theme.hintColor,
      ),
      style: theme.textTheme.bodyMedium,
    );

    if (searchable) {
      return GestureDetector(
        onTap: () {
          _showSearchPicker(
            context: context,
            title: 'Select $label',
            items: items,
            current: value,
          ).then((selected) {
            if (selected != null) {
              onChanged(selected);
            }
          });
        },
        child: AbsorbPointer(
          child: dropdown,
        ),
      );
    }

    return dropdown;
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
