import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/widgets/gc_pdf_factory.dart';
import 'package:logistic/config/flavor_config.dart';

/// Service for generating PDF preview without opening the GC form
class GCPdfPreviewService {
  /// Fetch GC data and show PDF preview
  static Future<void> showPdfPreviewFromGCData(
    BuildContext context,
    String gcNumber, {
    String? companyId,
    String? branchId,
  }) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Loading GC data...'),
            ],
          ),
        ),
      );

      // Get company and branch IDs if not provided
      final idController = Get.find<IdController>();
      final finalCompanyId = companyId ?? idController.companyId.value;
      final finalBranchId = branchId ?? idController.branchId.value;

      if (finalCompanyId.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar(context, 'Company not selected');
        return;
      }

      // Fetch GC data
      final gcData = await _fetchGCData(
        gcNumber,
        finalCompanyId,
        finalBranchId,
      );

      if (gcData == null) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar(context, 'GC data not found');
        return;
      }

      // Close loading dialog
      Navigator.pop(context);

      // Create a temporary controller with the GC data
      final tempController = Get.put(GCFormController(), permanent: false);
      await _populateControllerWithGCData(
        tempController,
        gcData,
        finalCompanyId,
      );

      // Show PDF preview
      await GCPdfFactory.showPdfPreview(context, tempController);

      // Clean up the temporary controller
      Get.delete<GCFormController>();
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar(context, 'Error generating PDF: $e');
    }
  }

  /// Fetch GC data from backend
  static Future<Map<String, dynamic>?> _fetchGCData(
    String gcNumber,
    String companyId,
    String? branchId,
  ) async {
    try {
      final queryParameters = {
        'GcNumber': gcNumber,
        'companyId': companyId,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
      };

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/gc/search',
        ).replace(queryParameters: queryParameters),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List && responseData.isNotEmpty) {
          final gcData = responseData.firstWhere(
            (item) =>
                item is Map<String, dynamic> &&
                item['GcNumber']?.toString() == gcNumber,
            orElse: () => responseData[0],
          );

          if (gcData is Map<String, dynamic>) {
            return gcData;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error fetching GC data: $e');
      return null;
    }
  }

  /// Populate controller with GC data (similar to _populateFormWithGCData)
  static Future<void> _populateControllerWithGCData(
    GCFormController controller,
    Map<String, dynamic> gcData,
    String companyId,
  ) async {
    // Set basic info
    controller.gcNumberCtrl.text = gcData['GcNumber']?.toString() ?? '';
    controller.isEditMode.value = true;
    controller.editingGcNumber.value = gcData['GcNumber']?.toString() ?? '';
    controller.editingCompanyId.value = companyId;

    // Populate the GC creator's booking officer name for PDF display
    controller.gcBookingOfficerName.value =
        gcData['booking_officer_name']?.toString() ?? '';

    // Set branch
    controller.selectedBranch.value =
        gcData['Branch']?.toString() ?? 'Select Branch';

    // Set dates
    if (gcData['GcDate'] != null) {
      try {
        final gcDate = DateTime.parse(gcData['GcDate'].toString());
        controller.gcDate.value = gcDate;
        controller.gcDateCtrl.text = controller.formatDate(gcDate);
      } catch (e) {}
    }

    if (gcData['DeliveryDate'] != null) {
      try {
        final deliveryDate = DateTime.parse(gcData['DeliveryDate'].toString());
        controller.deliveryDate.value = deliveryDate;
        controller.deliveryDateCtrl.text = controller.formatDate(deliveryDate);
      } catch (e) {}
    }

    // Set truck details
    controller.selectedTruck.value =
        gcData['TruckNumber']?.toString() ?? 'Select Truck';
    controller.truckNumberCtrl.text = gcData['TruckNumber']?.toString() ?? '';
    controller.truckTypeCtrl.text = gcData['TruckType']?.toString() ?? '';
    controller.poNumberCtrl.text = gcData['PoNumber']?.toString() ?? '';
    controller.tripIdCtrl.text = gcData['TripId']?.toString() ?? '';
    controller.fromCtrl.text = gcData['TruckFrom']?.toString() ?? '';
    controller.toCtrl.text = gcData['TruckTo']?.toString() ?? '';

    // Set broker and driver
    controller.selectedBroker.value =
        gcData['BrokerName']?.toString() ?? 'Select Broker';
    controller.brokerNameCtrl.text = gcData['BrokerName']?.toString() ?? '';
    controller.selectedDriver.value =
        gcData['DriverName']?.toString() ?? 'Select Driver';
    controller.driverNameCtrl.text = gcData['DriverName']?.toString() ?? '';
    controller.driverPhoneCtrl.text =
        gcData['DriverPhoneNumber']?.toString() ?? '';

    // Set consignor and consignee
    controller.selectedConsignor.value =
        gcData['ConsignorName']?.toString() ?? 'Select Consignor';
    controller.consignorNameCtrl.text =
        gcData['ConsignorName']?.toString() ?? '';
    controller.consignorGstCtrl.text = gcData['ConsignorGst']?.toString() ?? '';
    controller.consignorAddressCtrl.text =
        gcData['ConsignorAddress']?.toString() ?? '';

    final consigneeAddress = gcData['ConsigneeAddress']?.toString() ?? '';
    controller.selectedConsignee.value =
        gcData['ConsigneeName']?.toString() ?? 'Select Consignee';
    controller.consigneeNameCtrl.text =
        gcData['ConsigneeName']?.toString() ?? '';
    controller.consigneeGstCtrl.text = gcData['ConsigneeGst']?.toString() ?? '';
    controller.consigneeAddressCtrl.text = consigneeAddress;

    // Set bill to
    controller.selectedBillTo.value =
        gcData['BillToName']?.toString() ?? 'Select Bill To';
    controller.billToNameCtrl.text = gcData['BillToName']?.toString() ?? '';
    controller.billToGstCtrl.text = gcData['BillToGst']?.toString() ?? '';
    controller.billToAddressCtrl.text =
        gcData['BillToAddress']?.toString() ?? '';

    // Set goods info
    final natureOfGoods = gcData['GoodContain']?.toString() ?? '';
    final methodOfPkg = (gcData['MethodofPkg']?.toString() ?? '').isNotEmpty
        ? gcData['MethodofPkg'].toString()
        : 'Boxes';

    final rawWeight =
        (gcData['TotalWeight'] ?? gcData['ActualWeightKgs'])?.toString() ?? '';

    final normalizedWeight = (() {
      final raw = rawWeight.trim();
      if (raw.isEmpty) return '';

      final cleaned = raw.replaceAll(RegExp(r'[^0-9\.]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed == null) return raw;

      // For the form field, we want only the integer part;
      // the UI shows a fixed .000 suffix and the controller
      // will append .000 on submit.
      return parsed.toStringAsFixed(0);
    })();

    final formattedMethod = methodOfPkg.isNotEmpty
        ? '${methodOfPkg[0].toUpperCase()}${methodOfPkg.substring(1).toLowerCase()}'
        : 'Boxes';

    controller.natureGoodsCtrl.text = natureOfGoods;
    controller.packagesCtrl.text = gcData['NumberofPkg']?.toString() ?? '';
    controller.methodPackageCtrl.text = formattedMethod;
    controller.selectedPackageMethod.value = formattedMethod;
    controller.actualWeightCtrl.text = normalizedWeight;
    controller.weightCtrl.text = normalizedWeight;

    // PrivateMark is a fixed value in the UI
    controller.remarksCtrl.text = 'O / R';
    controller.billingAddressCtrl.text =
        gcData['ConsigneeAddress']?.toString() ?? '';

    controller.kmCtrl.text = gcData['km']?.toString() ?? '';
    controller.rateCtrl.text = gcData['Rate']?.toString() ?? '';

    controller.hireAmountCtrl.text = gcData['HireAmount']?.toString() ?? '';
    controller.advanceAmountCtrl.text =
        gcData['AdvanceAmount']?.toString() ?? '';
    controller.deliveryAddressCtrl.text =
        gcData['DeliveryAddress']?.toString() ?? '';
    if ((controller.freightChargeCtrl.text).isEmpty) {
      controller.freightChargeCtrl.text =
          gcData['FreightCharge']?.toString() ?? '';
    }
    controller.selectedPayment.value =
        gcData['PaymentDetails']?.toString() ?? 'Cash';

    // Important: Set GST payer selection
    controller.onGstPayerSelected(gcData['ServiceTax']?.toString());

    controller.customInvoiceCtrl.text = gcData['CustInvNo']?.toString() ?? '';
    controller.deliveryInstructionsCtrl.text =
        gcData['DeliveryFromSpecial']?.toString() ?? '';
    controller.invValueCtrl.text = gcData['InvValue']?.toString() ?? '';
    controller.ewayBillCtrl.text = gcData['EInv']?.toString() ?? '';
    if (gcData['EInvDate'] != null) {
      try {
        final ewayDate = DateTime.parse(gcData['EInvDate'].toString());
        controller.ewayBillDate.value = ewayDate;
        controller.ewayBillDateCtrl.text = controller.formatDate(ewayDate);
      } catch (e) {}
    }

    // Map EBillExpDate (E-way bill expiry date)
    if (gcData['EBillExpDate'] != null) {
      try {
        final ewayExpDate = DateTime.parse(gcData['EBillExpDate'].toString());
        controller.ewayExpired.value = ewayExpDate;
        controller.ewayExpiredCtrl.text = controller.formatDate(ewayExpDate);
      } catch (e) {}
    }

    // Fetch invoice and e-way bill attachments from backend
    await controller.fetchInvoiceEwayAttachments(
      gcData['GcNumber']?.toString() ?? '',
    );

    // Update controller to refresh UI
    controller.update();
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
