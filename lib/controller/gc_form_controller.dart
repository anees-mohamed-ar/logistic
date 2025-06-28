import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'dart:convert';

class GCFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final gcNumberCtrl = TextEditingController();
  final eDaysCtrl = TextEditingController();
  final truckNumberCtrl = TextEditingController();
  final poNumberCtrl = TextEditingController();
  final tripIdCtrl = TextEditingController();
  final brokerNameCtrl = TextEditingController();
  final driverNameCtrl = TextEditingController();
  final customInvoiceCtrl = TextEditingController();
  final ewayBillCtrl = TextEditingController();
  final consignorNameCtrl = TextEditingController();
  final consignorGstCtrl = TextEditingController();
  final consignorAddressCtrl = TextEditingController();
  final consigneeNameCtrl = TextEditingController();
  final consigneeGstCtrl = TextEditingController();
  final consigneeAddressCtrl = TextEditingController();
  final packagesCtrl = TextEditingController();
  final natureGoodsCtrl = TextEditingController();
  final methodPackageCtrl = TextEditingController();
  final actualWeightCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final kmCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  final hireAmountCtrl = TextEditingController();
  final advanceAmountCtrl = TextEditingController();
  final deliveryAddressCtrl = TextEditingController();
  final freightChargeCtrl = TextEditingController();

  // Date controllers
  final gcDateCtrl = TextEditingController();
  final deliveryDateCtrl = TextEditingController();
  final ewayBillDateCtrl = TextEditingController();
  final ewayExpiredCtrl = TextEditingController();

  var selectedBranch = 'Branch A'.obs;
  var selectedPayment = 'Cash'.obs;
  var selectedService = 'Express'.obs;
  var selectedPackageMethod = 'Boxes'.obs;
  var currentTab = 0.obs;
  final gcDate = Rxn<DateTime>();
  final deliveryDate = Rxn<DateTime>();
  final ewayBillDate = Rxn<DateTime>();
  final ewayExpired = Rxn<DateTime>();
  var isLoading = false.obs;
  var isDraftSaved = false.obs;

  final branches = ['Branch A', 'Branch B', 'Branch C'];
  final paymentOptions = ['Cash', 'Credit', 'Online'];
  final serviceOptions = ['Express', 'Standard', 'Pickup'];
  final packageMethods = ['Boxes', 'Cartons', 'Pallets', 'Bags', 'Barrels'];

  // Add ScrollController for tab bar
  final tabScrollController = ScrollController();

  void selectDate(
      BuildContext context,
      Rxn<DateTime> targetDate, {
        TextEditingController? textController,
      }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4A90E2),
            onPrimary: Colors.white,
            surface: Color(0xFFF7F9FC),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      targetDate.value = picked;
      if (textController != null) {
        textController.text = DateFormat('dd-MMM-yyyy').format(picked);
      }
      autoSaveDraft();
    }
  }

  void autoSaveDraft() {
    isDraftSaved.value = true;
    Future.delayed(const Duration(seconds: 2), () {
      isDraftSaved.value = false;
    });
  }

  void changeTab(int index) {
    if (formKey.currentState!.validate()) {
      currentTab.value = index;
    }
  }

  void navigateToPreviousTab() {
    if (currentTab.value > 0) {
      currentTab.value--;
    }
  }

  void navigateToNextTab() {
    if (currentTab.value < 3 && formKey.currentState!.validate()) {
      currentTab.value++;
    }
  }

  Future<void> submitFormToBackend() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    final url = Uri.parse('${ApiConfig.baseUrl}/gc/add');
    final Map<String, dynamic> data = {
      'Branch': selectedBranch.value,
      'GcNumber': gcNumberCtrl.text,
      'GcDate': gcDate.value?.toIso8601String(),
      'TruckNumber': truckNumberCtrl.text,
      'PoNumber': poNumberCtrl.text,
      'TripId': tripIdCtrl.text,
      'BrokerName': brokerNameCtrl.text,
      'DriverName': driverNameCtrl.text,
      'ConsignorName': consignorNameCtrl.text,
      'ConsignorGst': consignorGstCtrl.text,
      'ConsignorAddress': consignorAddressCtrl.text,
      'ConsigneeName': consigneeNameCtrl.text,
      'ConsigneeGst': consigneeGstCtrl.text,
      'ConsigneeAddress': consigneeAddressCtrl.text,
      'NumberofPkg': packagesCtrl.text,
      'MethodofPkg': selectedPackageMethod.value,
      'ActualWeightKgs': actualWeightCtrl.text,
      'Rate': rateCtrl.text,
      'km': kmCtrl.text,
      'Remarks': remarksCtrl.text,
      'HireAmount': hireAmountCtrl.text,
      'AdvanceAmount': advanceAmountCtrl.text,
      'DeliveryAddress': deliveryAddressCtrl.text,
      'FreightCharge': freightChargeCtrl.text,
      'PaymentDetails': selectedPayment.value,
    };
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      isLoading.value = false;
      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'GC data submitted successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4A90E2),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to submit GC data: ${response.body}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to submit GC data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    gcNumberCtrl.dispose();
    eDaysCtrl.dispose();
    truckNumberCtrl.dispose();
    poNumberCtrl.dispose();
    tripIdCtrl.dispose();
    brokerNameCtrl.dispose();
    driverNameCtrl.dispose();
    customInvoiceCtrl.dispose();
    ewayBillCtrl.dispose();
    consignorNameCtrl.dispose();
    consignorGstCtrl.dispose();
    consignorAddressCtrl.dispose();
    consigneeNameCtrl.dispose();
    consigneeGstCtrl.dispose();
    consigneeAddressCtrl.dispose();
    packagesCtrl.dispose();
    natureGoodsCtrl.dispose();
    methodPackageCtrl.dispose();
    actualWeightCtrl.dispose();
    rateCtrl.dispose();
    kmCtrl.dispose();
    remarksCtrl.dispose();
    hireAmountCtrl.dispose();
    advanceAmountCtrl.dispose();
    deliveryAddressCtrl.dispose();
    freightChargeCtrl.dispose();
    tabScrollController.dispose();
    gcDateCtrl.dispose();
    deliveryDateCtrl.dispose();
    ewayBillDateCtrl.dispose();
    ewayExpiredCtrl.dispose();
    super.onClose();
  }
}