import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/controller/temporary_gc_controller.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logistic/widgets/gc_pdf_factory.dart';
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
  final TemporaryGCController? tempController =
      Get.isRegistered<TemporaryGCController>()
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

        // For temporary GC creation, load available temp GC numbers from pool
        await controller.fetchAvailableTemporaryGcNumbers();

        // Skip GC usage warning for temporary GC creation - will be checked when filling
      } else if (controller.isFillTemporaryMode.value) {
        // When filling temporary GC, check GC usage first
        await controller.checkGCUsageAndWarn(userId);

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
        } catch (e) {
          print('Error in form initialization: $e');
        }
      } else if (!controller.isEditMode.value) {
        controller.clearForm();

        // Check GC usage warning first for new GC creation
        await controller.checkGCUsageAndWarn(userId);

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

    // Determine if we are creating a temporary GC (not filling an existing one)
    final isTempCreation =
        controller.isTemporaryMode.value &&
        !controller.isFillTemporaryMode.value;

    // Max tab index: 0-2 for temp creation (no Attachments tab), 0-3 otherwise
    final int maxTabIndex = isTempCreation ? 2 : 3;

    // Ensure the tab index stays within the available range
    if (controller.currentTab.value > maxTabIndex) {
      controller.currentTab.value = maxTabIndex;
    } else if (controller.currentTab.value < 0) {
      controller.currentTab.value = 0;
    }

    // Attach once; avoids repeated subscriptions on rebuilds
    controller.attachTabScrollListener(context);

    // Ensure consignors and consignees are fetched if not already
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.consignorsLoading.value &&
          controller.consignors.length <= 1) {
        controller.fetchConsignors();
      }
      if (!controller.consigneesLoading.value &&
          controller.consignees.length <= 1) {
        controller.fetchConsignees();
      }
    });

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Exit GC Form?'),
              content: const Text(
                'Are you sure you want to exit? Any unsaved data in this form will be cleared.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        );

        if (shouldExit == true) {
          await _unlockIfNeeded();
          return true;
        }

        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() {
            final isTemporary =
                controller.isTemporaryMode.value ||
                controller.isFillTemporaryMode.value;

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
            final timeStr =
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

            return Row(
              children: [
                // Timer display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: controller.remainingTime.value.inSeconds > 60
                        ? Colors.white
                        : controller.remainingTime.value.inSeconds.isEven
                        ? Colors.red.shade700
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      color: controller.remainingTime.value.inSeconds > 60
                          ? Colors.redAccent
                          : controller.remainingTime.value.inSeconds.isEven
                          ? Colors.white
                          : Colors.redAccent,
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
              onPressed: () => GCPdfFactory.showPdfPreview(context, controller),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'export_pdf',
                  child: const Text('Save PDF to Device'),
                  onTap: () => GCPdfFactory.savePdfToDevice(controller),
                ),
                PopupMenuItem(
                  value: 'share_pdf',
                  child: const Text('Share PDF'),
                  onTap: () => GCPdfFactory.sharePdf(controller),
                ),
                PopupMenuItem(
                  value: 'print_pdf',
                  child: const Text('Print PDF'),
                  onTap: () => GCPdfFactory.printPdf(controller),
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
                          maxTabIndex + 1,
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
                                      if (!isTempCreation) Icons.attach_file,
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
                                      if (!isTempCreation) 'Attachments',
                                    ][index],
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color:
                                          controller.currentTab.value == index
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
                        child:
                            (isTempCreation
                            ? [
                                _buildShipmentTab(
                                  context,
                                  controller,
                                  isSmallScreen,
                                ),
                                _buildPartiesTab(
                                  context,
                                  controller,
                                  isSmallScreen,
                                ),
                                _buildGoodsTab(
                                  context,
                                  controller,
                                  isSmallScreen,
                                ),
                              ]
                            : [
                                _buildShipmentTab(
                                  context,
                                  controller,
                                  isSmallScreen,
                                ),
                                _buildPartiesTab(
                                  context,
                                  controller,
                                  isSmallScreen,
                                ),
                                _buildGoodsTab(
                                  context,
                                  controller,
                                  isSmallScreen,
                                ),
                                _buildAttachmentsTab(
                                  context,
                                  controller,
                                  isSmallScreen,
                                ),
                              ])[controller.currentTab.value
                                .clamp(0, maxTabIndex)
                                .toInt()],
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
                                    side: BorderSide(color: theme.primaryColor),
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
                            if (controller.currentTab.value < maxTabIndex)
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
                            if (controller.currentTab.value == maxTabIndex)
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
                                      : Obx(
                                          () => Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                controller.isTemporaryMode.value
                                                    ? 'Create Temporary GC'
                                                    : controller
                                                          .isFillTemporaryMode
                                                          .value
                                                    ? 'Submit & Convert'
                                                    : 'Submit Form',
                                                style: theme
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                    ),
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
    final controller = Get.isRegistered<GCFormController>()
        ? Get.find<GCFormController>()
        : null;

    if (controller != null) {
      // Unlock temporary GC if needed
      if (tempController != null &&
          controller.isFillTemporaryMode.value &&
          controller.tempGcNumber.value.isNotEmpty) {
        await tempController!.unlockTemporaryGC(controller.tempGcNumber.value);
      }

      // Reset all temporary mode flags when closing the form
      controller.isTemporaryMode.value = false;
      controller.isFillTemporaryMode.value = false;
      controller.tempGcNumber.value = '';
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
              // Temporary GC: select reusable temp GC number from backend pool
              Obx(() {
                if (!(controller.isTemporaryMode.value &&
                    !controller.isFillTemporaryMode.value)) {
                  return const SizedBox.shrink();
                }

                final items = controller.availableTempGcNumbers.toList();
                final selected = controller.selectedTempGcFromPool.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      context: context,
                      label: 'Temporary GC Number (Pool)',
                      value: selected,
                      items: items,
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          controller.selectTemporaryGcNumber(value);
                        }
                      },
                      isLoading:
                          controller.isLoadingAvailableTempGcNumbers.value,
                      error: items.isEmpty
                          ? 'No available temporary GC numbers in pool'
                          : null,
                      onRetry: () =>
                          controller.fetchAvailableTemporaryGcNumbers(),
                      compact: true,
                      searchable: false,
                    ),
                  ],
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
                    restrictToToday:
                        true, // Only allow dates up to today for GC date
                  ),
                  validator: null,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.eDaysCtrl,
                      focusNode: controller.eDaysFocus,
                      decoration: _inputDecoration(
                        'Transit Days',
                        Icons.schedule,
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: null,
                      onChanged: (_) {
                        controller.updateDeliveryDateFromInputs();
                      },
                      onFieldSubmitted: (_) {
                        controller.poNumberFocus.requestFocus();
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
              // Broker, Vehicle & Driver combined details
              Obx(() {
                // Get the list of brokers, ensuring no empty names
                final brokerList = controller.brokers
                    .where((b) => b.isNotEmpty)
                    .toList();

                // If the selected broker is not in the list, clear it
                final selectedBroker = controller.selectedBroker.value;
                if (selectedBroker.isNotEmpty &&
                    !brokerList.contains(selectedBroker)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.selectedBroker.value = '';
                    controller.brokerNameCtrl.clear();
                  });
                }

                return _buildDropdownField(
                  context: context,
                  label: 'Broker Name',
                  value: brokerList.contains(selectedBroker)
                      ? selectedBroker
                      : '',
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
                          controller.truckNumberCtrl.text =
                              value; // keep submission compatibility
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
                        focusNode: controller.poNumberFocus,
                        decoration: _inputDecoration(
                          'PO Number',
                          Icons.description,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                        onChanged: (_) {},
                        onFieldSubmitted: (_) {
                          controller.truckTypeFocus.requestFocus();
                        },
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                TextFormField(
                  controller: controller.poNumberCtrl,
                  focusNode: controller.poNumberFocus,
                  decoration: _inputDecoration('PO Number', Icons.description),
                  textInputAction: TextInputAction.next,
                  validator: null,
                  onChanged: (_) {},
                  onFieldSubmitted: (_) {
                    controller.truckTypeFocus.requestFocus();
                  },
                ),
              const SizedBox(height: 16),
              // Truck Type and Driver Name row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.truckTypeCtrl,
                      focusNode: controller.truckTypeFocus,
                      decoration: _inputDecoration(
                        'Truck Type',
                        Icons.local_shipping,
                        compact: isSmallScreen,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: null,
                      onChanged: (_) {},
                      onFieldSubmitted: (_) {
                        controller.tripIdFocus.requestFocus();
                      },
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
                        if (selectedDriver.isNotEmpty &&
                            !driverNames.contains(selectedDriver)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller.selectedDriver.value = '';
                            controller.driverNameCtrl.clear();
                            controller.driverPhoneCtrl.clear();
                          });
                        }

                        return _buildDropdownField(
                          context: context,
                          label: 'Driver Name',
                          value: driverNames.contains(selectedDriver)
                              ? selectedDriver
                              : '',
                          items: driverNames,
                          onChanged: (value) {
                            if (value != null && value.isNotEmpty) {
                              try {
                                final driver = controller.drivers.firstWhere(
                                  (d) =>
                                      (d['driverName']?.toString() ?? '') ==
                                      value,
                                );
                                controller.selectedDriver.value = value;
                                controller.driverNameCtrl.text = value;
                                controller.driverPhoneCtrl.text =
                                    driver['phoneNumber']?.toString() ?? '';
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
                  if (selectedDriver.isNotEmpty &&
                      !driverNames.contains(selectedDriver)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      controller.selectedDriver.value = '';
                      controller.driverNameCtrl.clear();
                      controller.driverPhoneCtrl.clear();
                    });
                  }

                  return _buildDropdownField(
                    context: context,
                    label: 'Driver Name',
                    value: driverNames.contains(selectedDriver)
                        ? selectedDriver
                        : '',
                    items: driverNames,
                    onChanged: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          final driver = controller.drivers.firstWhere(
                            (d) => (d['driverName']?.toString() ?? '') == value,
                          );
                          controller.selectedDriver.value = value;
                          controller.driverNameCtrl.text = value;
                          controller.driverPhoneCtrl.text =
                              driver['phoneNumber']?.toString() ?? '';
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
                validator: null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.tripIdCtrl,
                focusNode: controller.tripIdFocus,
                decoration: _inputDecoration('Trip ID', Icons.route),
                textInputAction: TextInputAction.next,
                validator: null,
                onChanged: (_) {},
                onFieldSubmitted: (_) {
                  // Last field in Shipment tab - move to next tab
                  controller.navigateToNextTab();
                },
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
                              controller.consignorGstCtrl.text =
                                  info['gst'] ?? '';
                              controller.consignorAddressCtrl.text =
                                  info['address'] ?? '';
                              final location = info['location'] ?? '';
                              // Auto-fill From field with consignor's location when available, otherwise address
                              controller.fromCtrl.text = location.isNotEmpty
                                  ? location
                                  : (info['address'] ?? '');
                            }
                          }
                        },
                        validator: (value) =>
                            value == null ||
                                value.isEmpty ||
                                value == 'Select Consignor'
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
                          focusNode: controller.consignorGstFocus,
                          decoration: _inputDecoration('GST', Icons.business),
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Required'
                              : null,
                          onChanged: (_) {},
                          onFieldSubmitted: (_) {
                            controller.consignorAddressFocus.requestFocus();
                          },
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
                    focusNode: controller.consignorGstFocus,
                    decoration: _inputDecoration('GST', Icons.business),
                    textInputAction: TextInputAction.next,
                    validator: null,
                    onChanged: (_) {},
                    onFieldSubmitted: (_) {
                      controller.consignorAddressFocus.requestFocus();
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.consignorAddressCtrl,
                focusNode: controller.consignorAddressFocus,
                decoration: _inputDecoration('Address', Icons.location_on),
                maxLines: 2,
                textInputAction: TextInputAction.next,
                validator: null,
                onChanged: (_) {},
                onFieldSubmitted: (_) {
                  controller.billToGstFocus.requestFocus();
                },
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
                          focusNode: controller.billToGstFocus,
                          decoration: _inputDecoration('GST', Icons.business),
                          textInputAction: TextInputAction.next,
                          validator: null,
                          onChanged: (_) {},
                          onFieldSubmitted: (_) {
                            controller.billToAddressFocus.requestFocus();
                          },
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
                    focusNode: controller.billToGstFocus,
                    decoration: _inputDecoration('GST', Icons.business),
                    textInputAction: TextInputAction.next,
                    validator: null,
                    onChanged: (_) {},
                    onFieldSubmitted: (_) {
                      controller.billToAddressFocus.requestFocus();
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.billToAddressCtrl,
                focusNode: controller.billToAddressFocus,
                decoration: _inputDecoration('Address', Icons.location_on),
                maxLines: 2,
                textInputAction: TextInputAction.next,
                validator: null,
                onChanged: (_) {},
                onFieldSubmitted: (_) {
                  controller.consigneeGstFocus.requestFocus();
                },
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
                              controller.consigneeGstCtrl.text =
                                  info['gst'] ?? '';
                              final address = info['address'] ?? '';
                              controller.consigneeAddressCtrl.text = address;
                              final location = info['location'] ?? '';
                              final toValue = location.isNotEmpty
                                  ? location
                                  : address;
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
                          focusNode: controller.consigneeGstFocus,
                          decoration: _inputDecoration('GST', Icons.business),
                          textInputAction: TextInputAction.next,
                          validator: null,
                          onChanged: (_) {},
                          onFieldSubmitted: (_) {
                            controller.consigneeAddressFocus.requestFocus();
                          },
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
                    focusNode: controller.consigneeGstFocus,
                    decoration: _inputDecoration('GST', Icons.business),
                    textInputAction: TextInputAction.next,
                    validator: null,
                    onChanged: (_) {},
                    onFieldSubmitted: (_) {
                      controller.consigneeAddressFocus.requestFocus();
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.consigneeAddressCtrl,
                focusNode: controller.consigneeAddressFocus,
                decoration: _inputDecoration('Address', Icons.location_on),
                maxLines: 2,
                textInputAction: TextInputAction.next,
                validator: null,
                onChanged: (_) {},
                onFieldSubmitted: (_) {
                  // Last field in Parties tab - move to next tab
                  controller.navigateToNextTab();
                },
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
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
    // WeightRate? selectedWeightValue = controller.selectedWeight.value;

    // // Convert WeightRate list to a list of strings for the searchable dropdown
    // final List<String> weightOptions = controller.weightRates
    //     .map((w) => w.weight)
    //     .toList();
    // Get the string representation of the currently selected WeightRate
    // final String currentSelectedWeightString =
    //     selectedWeightValue?.weight ?? 'Select Weight';

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
                focusNode: controller.packagesFocus,
                decoration: _inputDecoration(
                  'No. of Packages',
                  Icons.inventory_2_outlined,
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: null,
                onChanged: (_) {},
                onFieldSubmitted: (_) {
                  controller.natureGoodsFocus.requestFocus();
                },
              ),
              const SizedBox(height: 16),

              // Nature of Goods and Package Method - Conditional Layout
              if (!isSmallScreen) // For large screens, display side-by-side
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.natureGoodsCtrl,
                        focusNode: controller.natureGoodsFocus,
                        decoration: _inputDecoration(
                          'Nature of Goods',
                          Icons.category,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                        onChanged: (_) {},
                        onFieldSubmitted: (_) {
                          controller.methodPackageFocus.requestFocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: controller.methodPackageCtrl,
                        focusNode: controller.methodPackageFocus,
                        decoration: _inputDecoration(
                          'Package Method',
                          Icons.inventory_2_outlined,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                        onChanged: (_) {},
                        onFieldSubmitted: (_) {
                          controller.customInvoiceFocus.requestFocus();
                        },
                      ),
                    ),
                  ],
                )
              else ...[
                // For small screens, stack them vertically
                TextFormField(
                  controller: controller.natureGoodsCtrl,
                  focusNode: controller.natureGoodsFocus,
                  decoration: _inputDecoration(
                    'Nature of Goods',
                    Icons.category,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: null,
                  onChanged: (_) {},
                  onFieldSubmitted: (_) {
                    controller.methodPackageFocus.requestFocus();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.methodPackageCtrl,
                  focusNode: controller.methodPackageFocus,
                  decoration: _inputDecoration(
                    'Package Method',
                    Icons.inventory_2_outlined,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: null,
                  onChanged: (_) {},
                  onFieldSubmitted: (_) {
                    controller.deliveryInstructionsFocus.requestFocus();
                  },
                ),
                const SizedBox(height: 16),
                // Delivery Special Instructions
                TextFormField(
                  controller: controller.deliveryInstructionsCtrl,
                  focusNode: controller.deliveryInstructionsFocus,
                  decoration: _inputDecoration(
                    'Delivery Special Instructions',
                    Icons.delivery_dining,
                    hintText: 'Enter any special delivery instructions',
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  validator: null,
                  onChanged: (_) {},
                  onFieldSubmitted: (_) {
                    controller.customInvoiceFocus.requestFocus();
                  },
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
                        focusNode: controller.customInvoiceFocus,
                        decoration: _inputDecoration(
                          'Cust Inv No',
                          Icons.receipt_long,
                          isOptional: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {},
                        onFieldSubmitted: (_) {
                          controller.invValueFocus.requestFocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: controller.invValueCtrl,
                        focusNode: controller.invValueFocus,
                        decoration: _inputDecoration(
                          'Inv Value',
                          Icons.currency_rupee,
                          isOptional: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {},
                        onFieldSubmitted: (_) {
                          controller.ewayBillFocus.requestFocus();
                        },
                      ),
                    ),
                  ],
                )
              else ...[
                TextFormField(
                  controller: controller.customInvoiceCtrl,
                  focusNode: controller.customInvoiceFocus,
                  decoration: _inputDecoration(
                    'Cust Inv No',
                    Icons.receipt_long,
                    isOptional: true,
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {},
                  onFieldSubmitted: (_) {
                    controller.invValueFocus.requestFocus();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.invValueCtrl,
                  focusNode: controller.invValueFocus,
                  decoration: _inputDecoration(
                    'Inv Value',
                    Icons.currency_rupee,
                    isOptional: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {},
                  onFieldSubmitted: (_) {
                    controller.ewayBillFocus.requestFocus();
                  },
                ),
              ],

              const SizedBox(height: 16),

              // E-way Bill Number
              TextFormField(
                controller: controller.ewayBillCtrl,
                focusNode: controller.ewayBillFocus,
                decoration: _inputDecoration(
                  'Eway Bill No',
                  Icons.description,
                  isOptional: true,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) {},
                onFieldSubmitted: (_) {
                  controller.actualWeightFocus.requestFocus();
                },
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
                          restrictToToday: true,
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
                    restrictToToday: true,
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
                focusNode: controller.actualWeightFocus,
                decoration: _inputDecoration(
                  'Actual Weight (Kgs)',
                  Icons.scale,
                  isOptional: true,
                ).copyWith(suffixText: '.000'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                onChanged: (_) {},
                onFieldSubmitted: (_) {
                  controller.remarksFocus.requestFocus();
                },
              ),

              const SizedBox(height: 16),

              // GST Payer dropdown
              Obx(() {
                // Debug print to check the current selected value
                debugPrint(
                  'Current GST Payer in UI: ${controller.selectedGstPayer.value}',
                );
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
              Obx(
                () => _buildDropdownField(
                  context: context,
                  label: 'Payment Method',
                  value: controller.selectedPayment.value,
                  items: [...controller.paymentOptions],
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedPayment.value = value;
                    }
                  },
                  validator: null,
                  compact: true,
                  searchable: false,
                ),
              ),

              const SizedBox(height: 24),

              // Private Mark - fixed non-editable value
              TextFormField(
                readOnly: true,
                initialValue: 'O / R',
                decoration: _inputDecoration(
                  'Private Mark',
                  Icons.info_outline,
                  isOptional: true,
                ),
                maxLines: 1,
                textInputAction: TextInputAction.next,
                onTap: () {
                  // Skip focus to next field since this is non-editable
                  controller.ewayBillFocus.requestFocus();
                },
                onFieldSubmitted: (_) {
                  controller.ewayBillFocus.requestFocus();
                },
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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

  Widget _buildFileAttachmentsSection(
    BuildContext context,
    GCFormController controller,
  ) {
    return Obx(() {
      final files = controller.attachedFiles;
      // final existingFiles = controller.existingAttachments;
      // final isLoading = controller.isLoadingAttachments.value;
      // final error = controller.attachmentsError.value;
      // final isUploading = controller.isUploading.value;
      // final uploadProgress = controller.uploadProgress.value;
      // final currentUploadingFile = controller.currentUploadingFile.value;
      // final uploadStatus = controller.uploadStatus.value;

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
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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

              // Typed attachment slots: Invoice & E-way bill
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(
                          () => _buildTypedAttachmentSlot(
                            context: context,
                            label: 'Invoice',
                            icon: Icons.receipt_long,
                            attachment: controller.invoiceAttachment.value,
                            onTap: () => controller.pickTypedAttachment(
                              context,
                              type: 'invoice',
                            ),
                            onPreview: () =>
                                controller.previewInvoiceAttachment(context),
                            onDownload: () =>
                                controller.downloadInvoiceAttachment(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => _buildTypedAttachmentSlot(
                            context: context,
                            label: 'E-way bill',
                            icon: Icons.article_outlined,
                            attachment: controller.ewayAttachment.value,
                            onTap: () => controller.pickTypedAttachment(
                              context,
                              type: 'eway',
                            ),
                            onPreview: () =>
                                controller.previewEwayAttachment(context),
                            onDownload: () =>
                                controller.downloadEwayAttachment(context),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Obx(
                          () => _buildTypedAttachmentSlot(
                            context: context,
                            label: 'Invoice',
                            icon: Icons.receipt_long,
                            attachment: controller.invoiceAttachment.value,
                            onTap: () => controller.pickTypedAttachment(
                              context,
                              type: 'invoice',
                            ),
                            onPreview: () =>
                                controller.previewInvoiceAttachment(context),
                            onDownload: () =>
                                controller.downloadInvoiceAttachment(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => _buildTypedAttachmentSlot(
                            context: context,
                            label: 'E-way bill',
                            icon: Icons.article_outlined,
                            attachment: controller.ewayAttachment.value,
                            onTap: () => controller.pickTypedAttachment(
                              context,
                              type: 'eway',
                            ),
                            onPreview: () =>
                                controller.previewEwayAttachment(context),
                            onDownload: () =>
                                controller.downloadEwayAttachment(context),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Upload progress indicator
              if (controller.isUploading.value) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.uploadStatus.value,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                if (controller
                                    .currentUploadingFile
                                    .value
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.currentUploadingFile.value,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: controller.uploadProgress.value,
                        backgroundColor: Colors.blue.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(controller.uploadProgress.value * 100).toStringAsFixed(1)}% uploaded',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Show loading state for existing attachments
              if (controller.isLoadingAttachments.value) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Show error state
              if (controller.attachmentsError.value.isNotEmpty &&
                  !controller.isLoadingAttachments.value) ...[
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
                          controller.attachmentsError.value,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Existing attachments section
              Obx(
                () =>
                    controller.existingAttachments.isNotEmpty &&
                        !controller.isLoadingAttachments.value &&
                        (controller.isEditMode.value ||
                            controller.isFillTemporaryMode.value)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Existing Attachments',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
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
                              itemCount: controller.existingAttachments.length,
                              itemBuilder: (context, index) {
                                final file =
                                    controller.existingAttachments[index];
                                final fileName =
                                    file['name'] as String? ?? 'Unknown';
                                final fileSize = file['size'] as int? ?? 0;
                                final filename =
                                    file['filename'] as String? ?? '';

                                // Format file size
                                String formatFileSize(int bytes) {
                                  if (bytes < 1024) return '$bytes B';
                                  if (bytes < 1024 * 1024)
                                    return '${(bytes / 1024).toStringAsFixed(1)} KB';
                                  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                                }

                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    _getFileIcon(filename.split('.').last),
                                    color: _getFileColor(
                                      filename.split('.').last,
                                    ),
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
                                        icon: const Icon(
                                          Icons.visibility,
                                          size: 16,
                                        ),
                                        onPressed: () =>
                                            controller.previewAttachment(
                                              filename,
                                              context,
                                              isTemporaryGC: controller
                                                  .isFillTemporaryMode
                                                  .value,
                                            ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Preview',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.download,
                                          size: 16,
                                        ),
                                        onPressed: () =>
                                            controller.downloadAttachment(
                                              filename,
                                              context,
                                              isTemporaryGC: controller
                                                  .isFillTemporaryMode
                                                  .value,
                                              originalName: fileName,
                                            ),
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
                      )
                    : const SizedBox.shrink(),
              ),

              // New attachments section
              Obx(
                () => controller.attachedFiles.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Attachments to Add',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
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
                              itemCount: controller.attachedFiles.length,
                              itemBuilder: (context, index) {
                                final file = controller.attachedFiles[index];
                                final fileName =
                                    file['name'] as String? ?? 'Unknown';
                                final fileSize = file['size'] as int? ?? 0;
                                final extension =
                                    file['extension'] as String? ?? '';

                                // Format file size
                                String formatFileSize(int bytes) {
                                  if (bytes < 1024) return '$bytes B';
                                  if (bytes < 1024 * 1024)
                                    return '${(bytes / 1024).toStringAsFixed(1)} KB';
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
                                    onPressed: () =>
                                        controller.removeFile(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // // Add files button
              // SizedBox(
              //   width: double.infinity,
              //   child: OutlinedButton.icon(
              //     onPressed: controller.isPickingFiles.value
              //         ? null
              //         : () => controller.pickFiles(context),
              //     icon: controller.isPickingFiles.value
              //         ? const SizedBox(
              //             width: 16,
              //             height: 16,
              //             child: CircularProgressIndicator(strokeWidth: 2),
              //           )
              //         : const Icon(Icons.attach_file),
              //     label: Text(
              //       controller.isPickingFiles.value
              //           ? 'Selecting files...'
              //           : 'Add Files',
              //     ),
              //     style: OutlinedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //       side: BorderSide(color: Theme.of(context).primaryColor),
              //     ),
              //   ),
              // ),
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

  Widget _buildTypedAttachmentSlot({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Map<String, dynamic>? attachment,
    required VoidCallback onTap,
    VoidCallback? onPreview,
    VoidCallback? onDownload,
  }) {
    final theme = Theme.of(context);
    final hasFile =
        attachment != null &&
        (attachment['name']?.toString().isNotEmpty ?? false);
    final fileName = hasFile
        ? (attachment['name']?.toString() ?? 'Selected file')
        : 'Tap to upload';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasFile ? theme.colorScheme.primary : Colors.grey.shade300,
          ),
          color: hasFile ? theme.colorScheme.primary.withOpacity(0.04) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasFile
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: hasFile
                    ? theme.colorScheme.primary
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: hasFile
                              ? Colors.green.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hasFile ? 'Uploaded' : 'Not uploaded',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: hasFile
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: hasFile ? Colors.black87 : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasFile && (onPreview != null || onDownload != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onPreview != null)
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 18),
                              tooltip: 'Preview',
                              onPressed: onPreview,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (onDownload != null)
                            IconButton(
                              icon: const Icon(Icons.download, size: 18),
                              tooltip: 'Download',
                              onPressed: onDownload,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.upload_file,
              size: 18,
              color: hasFile ? theme.colorScheme.primary : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf;
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext))
      return Icons.image;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    if (['txt'].contains(ext)) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String extension) {
    final ext = extension.toLowerCase();
    if (['pdf'].contains(ext)) return Colors.red;
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext))
      return Colors.blue;
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
              border: Border.all(color: theme.colorScheme.error, width: 1.5),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor, width: 1),
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
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
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
        child: AbsorbPointer(child: dropdown),
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
            decoration: _inputDecoration(
              label,
              _getIconForLabel(label),
              compact: compact,
            ).copyWith(errorText: state.errorText),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    (value.isEmpty || value.startsWith('Select'))
                        ? 'Select $label'
                        : value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: (value.isEmpty || value.startsWith('Select'))
                          ? Theme.of(context).hintColor
                          : null,
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
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final val = filtered[index];
                                  final selected = val == current;
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      val,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: selected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      searchCtrl
                                          .clear(); // Clear search when item is selected
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
      prefixIcon: Icon(
        icon,
        size: compact ? 18 : 20,
        color: const Color(0xFF6B7280),
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: compact ? 6 : 12,
        horizontal: compact ? 12 : 16,
      ),
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
