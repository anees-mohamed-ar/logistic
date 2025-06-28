import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logistic/controller/gc_form_controller.dart';

class GCFormScreen extends StatelessWidget {
  const GCFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GCFormController());
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Listen to currentTab changes and scroll to center the selected tab
    controller.currentTab.listen((index) {
      double tabWidth = 160.0;
      double screenWidth = MediaQuery.of(context).size.width;
      double offset = (tabWidth * index) - (screenWidth / 2) + (tabWidth / 2);
      if (controller.tabScrollController.hasClients) {
        double maxScroll = controller.tabScrollController.position.maxScrollExtent;
        offset = offset.clamp(0.0, maxScroll);
        controller.tabScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
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
              _buildDropdownField(
                context: context,
                label: 'Branch',
                value: controller.selectedBranch.value,
                items: controller.branches,
                onChanged: (value) {
                  controller.selectedBranch.value = value!;
                  controller.autoSaveDraft();
                },
              ),
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
                      onChanged: (_) => controller.autoSaveDraft(),
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
                          onTap: () => controller.selectDate(
                            context,
                            controller.deliveryDate,
                            textController: controller.deliveryDateCtrl,
                          ),
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
                  onTap: () => controller.selectDate(
                    context,
                    controller.deliveryDate,
                    textController: controller.deliveryDateCtrl,
                  ),
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
                    child: TextFormField(
                      controller: controller.truckNumberCtrl,
                      decoration: _inputDecoration(
                        'Truck Number',
                        Icons.local_shipping,
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.brokerNameCtrl,
                      decoration: _inputDecoration('Broker Name', Icons.person),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: TextFormField(
                        controller: controller.driverNameCtrl,
                        decoration: _inputDecoration(
                          'Driver Name',
                          Icons.person,
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
                  controller: controller.driverNameCtrl,
                  decoration: _inputDecoration('Driver Name', Icons.person),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                  onChanged: (_) => controller.autoSaveDraft(),
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
                    child: TextFormField(
                      controller: controller.consignorNameCtrl,
                      decoration: _inputDecoration('Name', Icons.person),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
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
                    child: TextFormField(
                      controller: controller.consigneeNameCtrl,
                      decoration: _inputDecoration('Name', Icons.person),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.packagesCtrl,
                      decoration: _inputDecoration(
                        'Number of Packages',
                        Icons.inventory,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: TextFormField(
                        controller: controller.actualWeightCtrl,
                        decoration: _inputDecoration(
                          'Actual Weight (kg)',
                          Icons.scale,
                        ),
                        keyboardType: TextInputType.number,
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
                  controller: controller.actualWeightCtrl,
                  decoration: _inputDecoration(
                    'Actual Weight (kg)',
                    Icons.scale,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                  onChanged: (_) => controller.autoSaveDraft(),
                ),
              const SizedBox(height: 16),
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
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: _buildDropdownField(
                        context: context,
                        label: 'Package Method',
                        value: controller.selectedPackageMethod.value,
                        items: controller.packageMethods,
                        onChanged: (value) {
                          controller.selectedPackageMethod.value = value!;
                          controller.autoSaveDraft();
                        },
                      ),
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                _buildDropdownField(
                  context: context,
                  label: 'Package Method',
                  value: controller.selectedPackageMethod.value,
                  items: controller.packageMethods,
                  onChanged: (value) {
                    controller.selectedPackageMethod.value = value!;
                    controller.autoSaveDraft();
                  },
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
                'Payment & Charges',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                context: context,
                label: 'Payment Method',
                value: controller.selectedPayment.value,
                items: controller.paymentOptions,
                onChanged: (value) {
                  controller.selectedPayment.value = value!;
                  controller.autoSaveDraft();
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                context: context,
                label: 'Service Type',
                value: controller.selectedService.value,
                items: controller.serviceOptions,
                onChanged: (value) {
                  controller.selectedService.value = value!;
                  controller.autoSaveDraft();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.customInvoiceCtrl,
                      decoration: _inputDecoration(
                        'Custom Invoice (Optional)',
                        Icons.receipt,
                        isOptional: true,
                      ),
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Tooltip(
                        message: 'Unique E-Way Bill number',
                        child: TextFormField(
                          controller: controller.ewayBillCtrl,
                          decoration: _inputDecoration(
                            'E-Way Bill',
                            Icons.document_scanner,
                          ),
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
                  message: 'Unique E-Way Bill number',
                  child: TextFormField(
                    controller: controller.ewayBillCtrl,
                    decoration: _inputDecoration(
                      'E-Way Bill',
                      Icons.document_scanner,
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                    onChanged: (_) => controller.autoSaveDraft(),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: controller.ewayBillDateCtrl,
                      decoration: _inputDecoration(
                        'E-Way Bill Date',
                        Icons.calendar_today,
                      ),
                      onTap: () => controller.selectDate(
                        context,
                        controller.ewayBillDate,
                        textController: controller.ewayBillDateCtrl,
                      ),
                      validator: (value) =>
                      controller.ewayBillDate.value == null
                          ? 'Required'
                          : null,
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: Obx(
                            () => TextFormField(
                          readOnly: true,
                          controller: controller.ewayExpiredCtrl,
                          decoration: _inputDecoration(
                            'E-Way Expired (Optional)',
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
                    ),
                ],
              ),
              if (isSmallScreen) const SizedBox(height: 16),
              if (isSmallScreen)
                TextFormField(
                  readOnly: true,
                  controller: controller.ewayExpiredCtrl,
                  decoration: _inputDecoration(
                    'E-Way Expired (Optional)',
                    Icons.calendar_today,
                    isOptional: true,
                  ),
                  onTap: () => controller.selectDate(
                    context,
                    controller.ewayExpired,
                    textController: controller.ewayExpiredCtrl,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.rateCtrl,
                      decoration: _inputDecoration(
                        'Rate',
                        Icons.currency_rupee,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: TextFormField(
                        controller: controller.kmCtrl,
                        decoration: _inputDecoration(
                          'Distance (KM)',
                          Icons.directions,
                        ),
                        keyboardType: TextInputType.number,
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
                  controller: controller.kmCtrl,
                  decoration: _inputDecoration(
                    'Distance (KM)',
                    Icons.directions,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                  onChanged: (_) => controller.autoSaveDraft(),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.hireAmountCtrl,
                      decoration: _inputDecoration(
                        'Hire Amount',
                        Icons.currency_rupee,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: TextFormField(
                        controller: controller.advanceAmountCtrl,
                        decoration: _inputDecoration(
                          'Advance Amount',
                          Icons.currency_rupee,
                        ),
                        keyboardType: TextInputType.number,
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
                  controller: controller.advanceAmountCtrl,
                  decoration: _inputDecoration(
                    'Advance Amount',
                    Icons.currency_rupee,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                  onChanged: (_) => controller.autoSaveDraft(),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.deliveryAddressCtrl,
                      decoration: _inputDecoration(
                        'Delivery Address',
                        Icons.location_on,
                      ),
                      maxLines: 2,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                      onChanged: (_) => controller.autoSaveDraft(),
                    ),
                  ),
                  if (!isSmallScreen) const SizedBox(width: 16),
                  if (!isSmallScreen)
                    Expanded(
                      child: TextFormField(
                        controller: controller.freightChargeCtrl,
                        decoration: _inputDecoration(
                          'Freight Charge',
                          Icons.currency_rupee,
                        ),
                        keyboardType: TextInputType.number,
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
                  controller: controller.freightChargeCtrl,
                  decoration: _inputDecoration(
                    'Freight Charge',
                    Icons.currency_rupee,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                  onChanged: (_) => controller.autoSaveDraft(),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.remarksCtrl,
                decoration: _inputDecoration(
                  'Remarks / Instructions (Optional)',
                  Icons.note,
                  isOptional: true,
                ),
                maxLines: 3,
                onChanged: (_) => controller.autoSaveDraft(),
              ),
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
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label, _getIconForLabel(label)),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        );
      }).toList(),
      onChanged: onChanged,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
      isExpanded: true,
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Branch':
        return Icons.business;
      case 'Payment Method':
        return Icons.payment;
      case 'Service Type':
        return Icons.delivery_dining;
      case 'Package Method':
        return Icons.inventory_2;
      default:
        return Icons.list;
    }
  }

  InputDecoration _inputDecoration(
      String label,
      IconData icon, {
        String? hintText,
        bool isOptional = false,
      }) {
    return InputDecoration(
      labelText: label + (isOptional ? ' (Optional)' : ''),
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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