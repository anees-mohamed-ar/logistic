import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'package:logistic/models/km_location.dart'; // Ensure this file exists and KMLocation is defined
import 'dart:convert';
import 'dart:async';

class WeightRate {
  final int id;
  final String weight;
  final double below250;
  final double above250;

  WeightRate({
    required this.id,
    required this.weight,
    required this.below250,
    required this.above250,
  });

  factory WeightRate.fromJson(Map<String, dynamic> json) {
    return WeightRate(
      id: json['id'] as int,
      weight: json['weight'] as String,
      below250: double.tryParse(json['below250'].toString()) ?? 0.0,
      above250: double.tryParse(json['above250'].toString()) ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightRate &&
        other.id == id &&
        other.weight == weight &&
        other.below250 == below250 &&
        other.above250 == above250;
  }

  @override
  int get hashCode => id.hashCode ^ weight.hashCode ^ below250.hashCode ^ above250.hashCode;
}

class GCFormController extends GetxController {
  // General Form State
  final formKey = GlobalKey<FormState>();
  final currentTab = 0.obs;
  final tabScrollController = ScrollController();
  final isLoading = false.obs;
  final isDraftSaved = false.obs;
  final isEditMode = false.obs;
  String? gcNumberToEdit;
  Timer? _draftDebounce;
  bool _tabScrollListenerAttached = false;

  // Shipment Tab Controllers
  final gcNumberCtrl = TextEditingController();
  final gcDate = Rxn<DateTime>();
  final gcDateCtrl = TextEditingController(); // For UI display of GC Date
  final eDaysCtrl = TextEditingController();
  final deliveryDate = Rxn<DateTime>();
  final deliveryDateCtrl = TextEditingController(); // For UI display of Delivery Date
  final poNumberCtrl = TextEditingController();
  final truckTypeCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final tripIdCtrl = TextEditingController();

  // Shipment Tab Observables (fetched data)
  final selectedBranch = 'Select Branch'.obs;
  final branchesLoading = false.obs;
  final branches = <String>['Select Branch'].obs;
  final selectedTruck = 'Select Truck'.obs;
  final trucksLoading = false.obs;
  final truckNumbers = <String>['Select Truck'].obs;
  final truckNumberCtrl = TextEditingController(); // To hold selected truck number for submission


  // Parties Tab Controllers
  final brokerNameCtrl = TextEditingController();
  final driverNameCtrl = TextEditingController();
  final driverPhoneCtrl = TextEditingController();
  final consignorNameCtrl = TextEditingController();
  final consignorGstCtrl = TextEditingController();
  final consignorAddressCtrl = TextEditingController();
  final consigneeNameCtrl = TextEditingController();
  final consigneeGstCtrl = TextEditingController();
  final consigneeAddressCtrl = TextEditingController();

  // Parties Tab Observables (fetched data)
  final selectedBroker = 'Select Broker'.obs;
  final brokersLoading = false.obs;
  final brokers = <String>['Select Broker'].obs;
  final selectedDriver = ''.obs; // This will hold the selected driver name
  final driversLoading = false.obs;
  final drivers = <Map<String, dynamic>>[].obs; // Raw driver data from API
  final driverInfo = <String, Map<String, dynamic>>{}; // Map driver name -> details
  final selectedConsignor = 'Select Consignor'.obs;
  final consignorsLoading = false.obs;
  final consignors = <String>['Select Consignor'].obs;
  final consignorInfo = <String, Map<String, String>>{}; // Map consignor name -> details
  final selectedConsignee = 'Select Consignee'.obs;
  final consigneesLoading = false.obs;
  final consignees = <String>['Select Consignee'].obs;
  final consigneeInfo = <String, Map<String, String>>{}; // Map consignee name -> details

  // Goods Tab Controllers
  final customInvoiceCtrl = TextEditingController();
  final ewayBillCtrl = TextEditingController();
  final ewayBillDate = Rxn<DateTime>();
  final ewayBillDateCtrl = TextEditingController(); // For UI display of Eway Bill Date
  final ewayExpired = Rxn<DateTime>();
  final ewayExpiredCtrl = TextEditingController(); // For UI display of Eway Expired Date
  final packagesCtrl = TextEditingController();
  final natureGoodsCtrl = TextEditingController();
  final methodPackageCtrl = TextEditingController();
  final actualWeightCtrl = TextEditingController();
  final kmCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  final fromLocationCtrl = TextEditingController(); // Used for KM lookup input (if separate from 'fromCtrl')
  final toLocationCtrl = TextEditingController();   // Used for KM lookup input (if separate from 'toCtrl')

  // Goods Tab Observables
  final isLoadingRates = false.obs;
  final weightRates = <WeightRate>[].obs;
  final selectedWeight = Rxn<WeightRate>();
  final RxString calculatedGoodsTotal = ''.obs; // Reactive total (rate * km) for Goods tab
  final RxList<KMLocation> kmLocations = <KMLocation>[].obs; // For KM data from API
  final RxBool isKmEditable = true.obs; // Controls if KM field can be edited manually
  final paymentOptions = ['Cash', 'Credit', 'Online'];
  final serviceOptions = ['Express', 'Standard', 'Pickup'];
  final packageMethods = ['Boxes', 'Cartons', 'Pallets', 'Bags', 'Barrels'];
  final selectedPayment = 'Cash'.obs;
  final selectedService = 'Express'.obs;
  final selectedPackageMethod = 'Boxes'.obs;


  // Charges Tab Controllers
  final hireAmountCtrl = TextEditingController();
  final advanceAmountCtrl = TextEditingController();
  final deliveryAddressCtrl = TextEditingController();
  final freightChargeCtrl = TextEditingController(); // Represents total freight (auto-calculated)
  final billingAddressCtrl = TextEditingController();
  final deliveryInstructionsCtrl = TextEditingController();
  // Removed gstCtrl, replaced by selectedGstPayer
  // final gstCtrl = TextEditingController();

  // Charges Tab Observables
  final RxString balanceAmount = '0.00'.obs; // Reactive balance amount
  final gstPayerOptions = ['Consignor', 'Consignee', 'Transporter'];
  final selectedGstPayer = 'Consignor'.obs; // Default value for GST Payer


  @override
  void onInit() {
    super.onInit(); // Always call super.onInit() first

    // Attach listeners
    kmCtrl.addListener(calculateRate);
    fromCtrl.addListener(_handleLocationChange); // Listen to changes in 'From' field for KM lookup
    toCtrl.addListener(_handleLocationChange);   // Listen to changes in 'To' field for KM lookup
    hireAmountCtrl.addListener(_updateBalanceAmount); // Listen for hire amount changes
    advanceAmountCtrl.addListener(_updateBalanceAmount); // Listen for advance amount changes


    // Fetch initial data for dropdowns and rates
    fetchBranches();
    fetchTrucks();
    fetchBrokers();
    fetchDrivers();
    fetchConsignors();
    fetchConsignees();
    fetchWeightRates();
  }

  @override
  void onClose() {
    // Cancel debounce timer
    _draftDebounce?.cancel();

    // Remove listeners
    kmCtrl.removeListener(calculateRate);
    fromCtrl.removeListener(_handleLocationChange);
    toCtrl.removeListener(_handleLocationChange);
    hireAmountCtrl.removeListener(_updateBalanceAmount);
    advanceAmountCtrl.removeListener(_updateBalanceAmount);

    // Dispose all TextEditingControllers
    gcNumberCtrl.dispose();
    gcDateCtrl.dispose();
    eDaysCtrl.dispose();
    deliveryDateCtrl.dispose();
    poNumberCtrl.dispose();
    truckTypeCtrl.dispose();
    fromCtrl.dispose();
    toCtrl.dispose();
    tripIdCtrl.dispose();
    brokerNameCtrl.dispose();
    driverNameCtrl.dispose();
    driverPhoneCtrl.dispose();
    customInvoiceCtrl.dispose();
    ewayBillCtrl.dispose();
    ewayBillDateCtrl.dispose();
    ewayExpiredCtrl.dispose();
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
    fromLocationCtrl.dispose();
    toLocationCtrl.dispose();
    hireAmountCtrl.dispose();
    advanceAmountCtrl.dispose();
    deliveryAddressCtrl.dispose();
    freightChargeCtrl.dispose();
    billingAddressCtrl.dispose();
    deliveryInstructionsCtrl.dispose();
    tabScrollController.dispose();

    super.onClose(); // Always call super.onClose() last
  }

  /// Attach tab scroll centering listener once to avoid multiple subscriptions.
  void attachTabScrollListener(BuildContext context) {
    if (_tabScrollListenerAttached) return;
    _tabScrollListenerAttached = true;
    ever<int>(currentTab, (index) {
      // You might need to adjust tabWidth based on actual item width + margin
      // For accurate centering, calculate the total width of tabs before the current one
      // and subtract half the screen width. This is a simplified estimate.
      final double estimatedTabWidth = 120.0; // Estimate average tab width
      final double screenWidth = MediaQuery.of(context).size.width;
      double offset = (estimatedTabWidth * index) - (screenWidth / 2) + (estimatedTabWidth / 2);

      if (tabScrollController.hasClients) {
        final double maxScroll = tabScrollController.position.maxScrollExtent;
        offset = offset.clamp(0.0, maxScroll);
        tabScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    });
  }

  void changeTab(int index) {
    // Only allow tab change if the current tab's form is valid
    if (formKey.currentState?.validate() ?? false) {
      currentTab.value = index;
    } else {
      Get.snackbar('Validation Error', 'Please fill all required fields in the current tab.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  void navigateToPreviousTab() {
    if (currentTab.value > 0) {
      currentTab.value--;
    }
  }

  void navigateToNextTab() {
    if (formKey.currentState?.validate() ?? false) {
      if (currentTab.value < 3) {
        currentTab.value++;
      } else {
        submitFormToBackend(); // Submit if on the last tab
      }
    } else {
      Get.snackbar('Validation Error', 'Please fill all required fields.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  // Load draft data from storage (placeholder)
  void loadDraft() {
    // TODO: Implement your draft loading logic here
    // Example: retrieve data from SharedPreferences or a local database
    // and populate the controllers and Rx variables.
  }

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
      // Re-compute delivery date in case GC date changed
      updateDeliveryDateFromInputs();
      autoSaveDraft();
    }
  }

  /// Computes Delivery Date = GC Date + E-days and updates UI state.
  void updateDeliveryDateFromInputs() {
    final DateTime? gc = gcDate.value;
    final int eDays = int.tryParse(eDaysCtrl.text.trim()) ?? -1;
    if (gc != null && eDays >= 0) {
      final DateTime computed = gc.add(Duration(days: eDays));
      deliveryDate.value = computed;
      deliveryDateCtrl.text = DateFormat('dd-MMM-yyyy').format(computed);
    } else {
      // Clear if inputs are incomplete/invalid
      deliveryDate.value = null;
      deliveryDateCtrl.text = '';
    }
  }

  void autoSaveDraft() {
    _draftDebounce?.cancel(); // Cancel any existing debounce
    _draftDebounce = Timer(const Duration(milliseconds: 600), () {
      isDraftSaved.value = true;
      Future.delayed(const Duration(seconds: 2), () {
        isDraftSaved.value = false;
      });
      // TODO: Implement your actual draft saving logic here
    });
  }

  // API Call Methods

  Future<void> fetchBranches() async {
    try {
      branchesLoading.value = true;
      final url = Uri.parse('${ApiConfig.baseUrl}/location/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final names = decoded
              .map((e) => (e['branchName'] ?? e['BranchName'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();
          branches
            ..clear()
            ..addAll(['Select Branch', ...names]);
          if (!branches.contains(selectedBranch.value)) {
            selectedBranch.value = 'Select Branch'; // Reset if old value not found
          }
        } else {
          Get.snackbar('Error', 'Unexpected branches response format',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar('Error', 'Failed to load branches: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load branches: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      branchesLoading.value = false;
    }
  }

  Future<void> fetchTrucks() async {
    try {
      trucksLoading.value = true;
      final url = Uri.parse('${ApiConfig.baseUrl}/truckmaster/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final list = decoded
              .map((e) => (e['vechileNumber'] ?? e['vehicleNumber'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();
          truckNumbers
            ..clear()
            ..addAll(['Select Truck', ...list]);
          if (!truckNumbers.contains(selectedTruck.value)) {
            selectedTruck.value = 'Select Truck'; // Reset if old value not found
          }
        } else {
          Get.snackbar('Error', 'Unexpected trucks response format',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar('Error', 'Failed to load trucks: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load trucks: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      trucksLoading.value = false;
    }
  }

  Future<void> fetchBrokers() async {
    try {
      brokersLoading.value = true;
      final url = Uri.parse('${ApiConfig.baseUrl}/broker/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final names = decoded
              .map((e) => (e['brokerName'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();
          brokers
            ..clear()
            ..addAll(['Select Broker', ...names]);
          if (!brokers.contains(selectedBroker.value)) {
            selectedBroker.value = 'Select Broker'; // Reset if old value not found
          }
        } else {
          Get.snackbar('Error', 'Unexpected brokers response format',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar('Error', 'Failed to load brokers: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load brokers: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      brokersLoading.value = false;
    }
  }

  Future<void> fetchDrivers() async {
    try {
      driversLoading.value = true;
      final url = Uri.parse('${ApiConfig.baseUrl}/driver/search'); // Using ApiConfig.baseUrl
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        driverInfo.clear();
        final driverNames = <String>{};

        for (final driver in decoded) {
          final name = (driver['driverName'] ?? '').toString();
          if (name.isEmpty) continue;

          driverNames.add(name);
          driverInfo[name] = {
            'phoneNumber': (driver['phoneNumber'] ?? '').toString(),
            'dlNumber': (driver['dlNumber'] ?? '').toString(),
            'address': (driver['driverAddress'] ?? '').toString(),
          };
        }

        // Store the full list of maps in `drivers` observable
        drivers.assignAll(decoded.cast<Map<String, dynamic>>());

        if (driverNames.isEmpty) {
          Get.snackbar('Info', 'No drivers found', snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        Get.snackbar('Error', 'Failed to load drivers: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load drivers: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      driversLoading.value = false;
    }
  }


  Future<void> fetchConsignors() async {
    try {
      consignorsLoading.value = true;
      final url = Uri.parse('${ApiConfig.baseUrl}/consignor/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          consignorInfo.clear();
          final names = <String>{};
          for (final e in decoded) {
            final name = (e['consignorName'] ?? '').toString();
            if (name.isEmpty) continue;
            names.add(name);
            consignorInfo[name] = {
              'gst': (e['gst'] ?? '').toString(),
              'address': (e['address'] ?? '').toString(),
            };
          }
          consignors
            ..clear()
            ..addAll(['Select Consignor', ...names.toList()]);
          if (!consignors.contains(selectedConsignor.value)) {
            selectedConsignor.value = 'Select Consignor'; // Reset if old value not found
          }
          if (names.isEmpty) {
            Get.snackbar('Info', 'No consignors found', snackPosition: SnackPosition.BOTTOM);
          }
        } else {
          Get.snackbar('Error', 'Unexpected consignors response format',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar('Error', 'Failed to load consignors: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load consignors: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      consignorsLoading.value = false;
    }
  }

  Future<void> fetchConsignees() async {
    try {
      consigneesLoading.value = true;
      final url = Uri.parse('${ApiConfig.baseUrl}/consignee/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          consigneeInfo.clear();
          final names = <String>{};
          for (final e in decoded) {
            final name = (e['consigneeName'] ?? '').toString();
            if (name.isEmpty) continue;
            names.add(name);
            consigneeInfo[name] = {
              'gst': (e['gst'] ?? '').toString(),
              'address': (e['address'] ?? '').toString(),
            };
          }
          consignees
            ..clear()
            ..addAll(['Select Consignee', ...names.toList()]);
          if (!consignees.contains(selectedConsignee.value)) {
            selectedConsignee.value = 'Select Consignee'; // Reset if old value not found
          }
          if (names.isEmpty) {
            Get.snackbar('Info', 'No consignees found', snackPosition: SnackPosition.BOTTOM);
          }
        } else {
          Get.snackbar('Error', 'Unexpected consignees response format',
              snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        Get.snackbar('Error', 'Failed to load consignees: ${response.statusCode}',
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load consignees: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      consigneesLoading.value = false;
    }
  }

  Future<void> fetchWeightRates() async {
    try {
      isLoadingRates.value = true;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/weight_to_rate/search'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        weightRates.assignAll(
          data.map((item) => WeightRate.fromJson(item)).toList(),
        );
      } else {
        Get.snackbar('Error', 'Failed to load weight rates: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to connect to server for weight rates: $e');
    } finally {
      isLoadingRates.value = false;
    }
  }

  Future<void> fetchKMLocations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/km/search'), // Using ApiConfig.baseUrl
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        kmLocations.assignAll(data.map((json) => KMLocation.fromJson(json)).toList());
      } else {
        Get.snackbar('Error', 'Failed to load KM locations: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching KM locations: $e');
    }
  }

  // KM data handling
  void _handleLocationChange() {
    final from = fromCtrl.text.trim();
    final to = toCtrl.text.trim();

    if (from.isNotEmpty && to.isNotEmpty) {
      updateKM(from, to);
    } else {
      kmCtrl.clear();
      isKmEditable.value = true;
      calculateRate(); // Recalculate if KM is cleared or becomes editable
    }
  }

  void updateKM(String from, String to) {
    // Try to find exact match
    final match = kmLocations.firstWhereOrNull(
            (loc) => loc.from.toLowerCase() == from.toLowerCase() &&
            loc.to.toLowerCase() == to.toLowerCase()
    );

    if (match != null) {
      kmCtrl.text = match.km;
      isKmEditable.value = false;
    } else {
      kmCtrl.clear(); // Clear KM if no match found
      isKmEditable.value = true;
    }
    calculateRate(); // Always recalculate rate after KM is updated
  }


  // Calculate rate based on KM and selected weight
  void calculateRate() {
    if (selectedWeight.value == null || kmCtrl.text.isEmpty) {
      rateCtrl.clear();
      freightChargeCtrl.clear();
      calculatedGoodsTotal.value = '';
      autoSaveDraft();
      return;
    }

    final km = double.tryParse(kmCtrl.text) ?? 0.0;
    if (km <= 0) {
      rateCtrl.clear();
      freightChargeCtrl.clear();
      calculatedGoodsTotal.value = '';
      autoSaveDraft();
      return;
    }

    // Determine the base rate from selectedWeight based on KM
    final baseRate = km <= 250
        ? selectedWeight.value!.below250
        : selectedWeight.value!.above250;

    rateCtrl.text = baseRate.toStringAsFixed(2); // This is the rate per KM

    // Calculate total freight charge
    final totalFreight = baseRate * km;
    freightChargeCtrl.text = totalFreight.toStringAsFixed(2);

    // Update the reactive total for the Goods tab UI
    calculatedGoodsTotal.value = totalFreight.toStringAsFixed(2);

    autoSaveDraft();
  }

  // Update selected weight and calculate rate
  void onWeightSelected(WeightRate? weight) {
    selectedWeight.value = weight;
    calculateRate(); // Recalculate rate and total when weight changes
    autoSaveDraft();
  }

  // Calculate balance amount
  void _updateBalanceAmount() {
    try {
      final hireAmount = double.tryParse(hireAmountCtrl.text) ?? 0;
      final advanceAmount = double.tryParse(advanceAmountCtrl.text) ?? 0;
      final balance = hireAmount - advanceAmount;
      balanceAmount.value = balance.toStringAsFixed(2);
    } catch (e) {
      balanceAmount.value = '0.00';
    }
    autoSaveDraft(); // Save draft after balance update
  }


  // Load GC data into the form for editing
  void loadGcData(Map<String, dynamic> gcData) {
    try {
      // Shipment Tab
      gcNumberCtrl.text = gcData['gcNumber'] ?? '';
      gcNumberToEdit = gcData['gcNumber'];
      
      if (gcData['gcDate'] != null) {
        gcDate.value = DateTime.tryParse(gcData['gcDate']);
        if (gcDate.value != null) {
          gcDateCtrl.text = DateFormat('dd-MM-yyyy').format(gcDate.value!);
        }
      }
      
      selectedBranch.value = gcData['branch'] ?? 'Select Branch';
      selectedTruck.value = gcData['truckNumber'] ?? 'Select Truck';
      truckNumberCtrl.text = gcData['truckNumber'] ?? '';
      poNumberCtrl.text = gcData['poNumber'] ?? '';
      tripIdCtrl.text = gcData['tripId'] ?? '';
      
      // Parties Tab
      selectedBroker.value = gcData['brokerName'] ?? 'Select Broker';
      selectedDriver.value = gcData['driverName'] ?? '';
      driverNameCtrl.text = gcData['driverName'] ?? '';
      driverPhoneCtrl.text = gcData['driverPhone'] ?? '';
      
      selectedConsignor.value = gcData['consignorName'] ?? 'Select Consignor';
      consignorNameCtrl.text = gcData['consignorName'] ?? '';
      consignorGstCtrl.text = gcData['consignorGst'] ?? '';
      consignorAddressCtrl.text = gcData['consignorAddress'] ?? '';
      
      selectedConsignee.value = gcData['consigneeName'] ?? 'Select Consignee';
      consigneeNameCtrl.text = gcData['consigneeName'] ?? '';
      consigneeGstCtrl.text = gcData['consigneeGst'] ?? '';
      consigneeAddressCtrl.text = gcData['consigneeAddress'] ?? '';
      
      // Goods Tab
      packagesCtrl.text = gcData['numberOfPackages']?.toString() ?? '';
      selectedPackageMethod.value = gcData['packageMethod'] ?? 'Boxes';
      actualWeightCtrl.text = gcData['actualWeight']?.toString() ?? '';
      kmCtrl.text = gcData['distance']?.toString() ?? '';
      rateCtrl.text = gcData['rate']?.toString() ?? '';
      
      // Charges Tab
      hireAmountCtrl.text = gcData['hireAmount']?.toString() ?? '';
      advanceAmountCtrl.text = gcData['advanceAmount']?.toString() ?? '';
      deliveryAddressCtrl.text = gcData['deliveryAddress'] ?? '';
      freightChargeCtrl.text = gcData['freightCharge']?.toString() ?? '';
      selectedPayment.value = gcData['paymentMethod'] ?? 'Cash';
      
      // Update balance amount
      _updateBalanceAmount();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load GC data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Clear all form fields
  void clearForm() {
    formKey.currentState?.reset();
    gcNumberCtrl.clear();
    gcDate.value = null;
    gcDateCtrl.clear();
    eDaysCtrl.clear();
    deliveryDate.value = null;
    deliveryDateCtrl.clear();
    selectedTruck.value = 'Select Truck';
    truckNumberCtrl.clear();
    truckTypeCtrl.clear();
    fromCtrl.clear();
    toCtrl.clear();
    poNumberCtrl.clear();
    tripIdCtrl.clear();
    selectedBroker.value = 'Select Broker';
    selectedDriver.value = '';
    driverNameCtrl.clear();
    driverPhoneCtrl.clear();
    selectedConsignor.value = 'Select Consignor';
    consignorNameCtrl.clear();
    consignorGstCtrl.clear();
    consignorAddressCtrl.clear();
    selectedConsignee.value = 'Select Consignee';
    consigneeNameCtrl.clear();
    consigneeGstCtrl.clear();
    consigneeAddressCtrl.clear();
    customInvoiceCtrl.clear();
    ewayBillCtrl.clear();
    ewayBillDate.value = null;
    ewayBillDateCtrl.clear();
    ewayExpired.value = null;
    ewayExpiredCtrl.clear();
    packagesCtrl.clear();
    natureGoodsCtrl.clear();
    methodPackageCtrl.clear();
    actualWeightCtrl.clear();
    kmCtrl.clear();
    rateCtrl.clear();
    remarksCtrl.clear();
    hireAmountCtrl.clear();
    advanceAmountCtrl.clear();
    deliveryAddressCtrl.clear();
    freightChargeCtrl.clear();
    billingAddressCtrl.clear();
    deliveryInstructionsCtrl.clear();
    balanceAmount.value = '0.00';
    selectedPayment.value = 'Cash';
    selectedService.value = 'Express';
    selectedGstPayer.value = 'No';
    selectedPackageMethod.value = 'Boxes';
  }

  Future<void> submitFormToBackend() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    
    final Map<String, dynamic> data = {
      'Branch': selectedBranch.value,
      'GcNumber': gcNumberCtrl.text,
      'GcDate': gcDate.value?.toIso8601String(),
      'EDays': eDaysCtrl.text,
      'DeliveryDate': deliveryDate.value?.toIso8601String(),
      'TruckNumber': selectedTruck.value,
      'TruckType': truckTypeCtrl.text,
      'From': fromCtrl.text,
      'To': toCtrl.text,
      'PoNumber': poNumberCtrl.text,
      'TripId': tripIdCtrl.text,
      'BrokerName': selectedBroker.value,
      'BrokerNameShow': selectedBroker.value,
      'DriverName': selectedDriver.value,
      'DriverNameShow': selectedDriver.value,
      'DriverPhoneNumber': driverPhoneCtrl.text,
      'Consignor': selectedConsignor.value,
      'ConsignorName': selectedConsignor.value,
      'ConsignorGst': consignorGstCtrl.text,
      'ConsignorAddress': consignorAddressCtrl.text,
      'Consignee': selectedConsignee.value,
      'ConsigneeName': selectedConsignee.value,
      'ConsigneeGst': consigneeGstCtrl.text,
      'ConsigneeAddress': consigneeAddressCtrl.text,
      'NumberofPkg': packagesCtrl.text,
      'MethodofPkg': selectedPackageMethod.value,
      'ActualWeightKgs': actualWeightCtrl.text,
      'km': kmCtrl.text,
      'Rate': rateCtrl.text,
      'HireAmount': hireAmountCtrl.text,
      'AdvanceAmount': advanceAmountCtrl.text,
      'BalanceAmount': balanceAmount.value,
      'DeliveryAddress': deliveryAddressCtrl.text,
      'FreightCharge': freightChargeCtrl.text,
      'PaymentDetails': selectedPayment.value,
      'ServiceType': selectedService.value,
      'GstPayer': selectedGstPayer.value,
      'Remarks': remarksCtrl.text,
      'CustomInvoiceNo': customInvoiceCtrl.text,
      'EwayBillNo': ewayBillCtrl.text,
      'EwayBillDate': ewayBillDate.value?.toIso8601String(),
      'EwayBillExpiryDate': ewayExpired.value?.toIso8601String(),
      'BillingAddress': billingAddressCtrl.text,
      'DeliveryInstructions': deliveryInstructionsCtrl.text,
    };

    try {
      final Uri url;
      final http.Response response;
      
      if (isEditMode.value && gcNumberToEdit != null) {
        // Update existing GC
        url = Uri.parse('${ApiConfig.baseUrl}/updateGC/$gcNumberToEdit');
        response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
      } else {
        // Create new GC
        url = Uri.parse('${ApiConfig.baseUrl}/gc/add');
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
      }
      
      isLoading.value = false;
      
      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          isEditMode.value ? 'GC updated successfully!' : 'GC created successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4A90E2),
          colorText: Colors.white,
        );
        
        // Clear the form if not in edit mode
        if (!isEditMode.value) {
          clearForm();
        }
        
        // Navigate back to GC list
        Get.until((route) => route.isFirst);
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to ${isEditMode.value ? 'update' : 'create'} GC: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}