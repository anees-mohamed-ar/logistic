import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'package:logistic/models/km_location.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:async';
import 'package:collection/collection.dart';

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
  final selectedBranchCode = ''.obs;
  final branchesLoading = false.obs;
  final branches = <String>['Select Branch'].obs;
  final branchCodeMap = <String, String>{}.obs; // Maps branch name to branch code
  final trucks = <String>['Select Truck'].obs;
  final selectedTruck = 'Select Truck'.obs;
  final trucksLoading = false.obs;
  final truckNumberCtrl = TextEditingController(); // To hold selected truck number for submission
  final truckNumbers = <String>['Select Truck'].obs; // For truck numbers dropdown
  final selectedBroker = 'Select Broker'.obs;
  final brokersLoading = false.obs;
  final brokers = <String>['Select Broker'].obs;
  final selectedConsignor = 'Select Consignor'.obs;
  final consignorsLoading = false.obs;
  final consignors = <String>['Select Consignor'].obs;
  final selectedConsignee = 'Select Consignee'.obs;
  final consigneesLoading = false.obs;
  final consignees = <String>['Select Consignee'].obs;

  // Error states for dropdowns
  final branchesError = RxnString();
  final trucksError = RxnString();
  final brokersError = RxnString();
  final consignorsError = RxnString();
  final consigneesError = RxnString();

  // Parties Tab Controllers
  final brokerNameCtrl = TextEditingController();
  final driverNameCtrl = TextEditingController();
  final driverPhoneCtrl = TextEditingController();
  final consignorNameCtrl = TextEditingController();
  
  // Goods Tab Controllers
  final weightCtrl = TextEditingController();
  final natureOfGoodsCtrl = TextEditingController();
  final consignorGstCtrl = TextEditingController();
  final consignorAddressCtrl = TextEditingController();
  final consigneeNameCtrl = TextEditingController();
  final consigneeGstCtrl = TextEditingController();
  final consigneeAddressCtrl = TextEditingController();

  // Parties Tab Observables (fetched data)
  final selectedDriver = ''.obs; // This will hold the selected driver name
  final driversLoading = false.obs;
  final driversError = RxnString();
  final drivers = <Map<String, dynamic>>[].obs; // Raw driver data from API
  final driverInfo = <String, Map<String, dynamic>>{}; // Map driver name -> details
  final consignorInfo = <String, Map<String, String>>{}; // Map consignor name -> details
  final consigneeInfo = <String, Map<String, String>>{}; // Map consignee name -> details

  // Goods Tab Controllers
  final customInvoiceCtrl = TextEditingController();
  final invValueCtrl = TextEditingController();
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
  final RxString weightRatesError = RxString('');
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

  // Helper method to safely dispose controllers
  void _disposeIfMounted(TextEditingController? controller) {
    if (controller != null) {
      controller.dispose();
    }
  }
  // Removed gstCtrl, replaced by selectedGstPayer
  // final gstCtrl = TextEditingController();

  // Charges Tab Observables
  final RxString balanceAmount = '0.00'.obs; // Reactive balance amount
  final gstPayerOptions = ['Consignor', 'Consignee', 'Transporter'];
  final selectedGstPayer = 'Consignor'.obs; // Default value for GST Payer

  // Edit Mode Variables
  final isEditMode = false.obs;
  final editingGcNumber = ''.obs;
  final editingCompanyId = ''.obs;


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
    fetchKMLocations();
  }

  @override
  void onClose() {
    // Reset tab scroll listener flag
    _tabScrollListenerAttached = false;
    
    // Remove listeners
    try {
      kmCtrl.removeListener(calculateRate);
      fromCtrl.removeListener(_handleLocationChange);
      toCtrl.removeListener(_handleLocationChange);
      hireAmountCtrl.removeListener(_updateBalanceAmount);
      advanceAmountCtrl.removeListener(_updateBalanceAmount);
    } catch (e) {
      // Ignore errors during listener removal
    }

    // Dispose all TextEditingControllers safely
    _disposeIfMounted(gcNumberCtrl);
    _disposeIfMounted(gcDateCtrl);
    _disposeIfMounted(eDaysCtrl);
    _disposeIfMounted(deliveryDateCtrl);
    _disposeIfMounted(poNumberCtrl);
    _disposeIfMounted(truckTypeCtrl);
    _disposeIfMounted(fromCtrl);
    _disposeIfMounted(toCtrl);
    _disposeIfMounted(tripIdCtrl);
    _disposeIfMounted(brokerNameCtrl);
    _disposeIfMounted(driverNameCtrl);
    _disposeIfMounted(driverPhoneCtrl);
    _disposeIfMounted(customInvoiceCtrl);
    _disposeIfMounted(invValueCtrl);
    _disposeIfMounted(ewayBillCtrl);
    _disposeIfMounted(ewayBillDateCtrl);
    _disposeIfMounted(ewayExpiredCtrl);
    _disposeIfMounted(consignorNameCtrl);
    _disposeIfMounted(consignorGstCtrl);
    _disposeIfMounted(consignorAddressCtrl);
    _disposeIfMounted(consigneeNameCtrl);
    _disposeIfMounted(consigneeGstCtrl);
    _disposeIfMounted(consigneeAddressCtrl);
    _disposeIfMounted(packagesCtrl);
    _disposeIfMounted(natureGoodsCtrl);
    _disposeIfMounted(methodPackageCtrl);
    _disposeIfMounted(actualWeightCtrl);
    _disposeIfMounted(rateCtrl);
    _disposeIfMounted(kmCtrl);
    _disposeIfMounted(remarksCtrl);
    _disposeIfMounted(fromLocationCtrl);
    _disposeIfMounted(toLocationCtrl);
    _disposeIfMounted(hireAmountCtrl);
    _disposeIfMounted(advanceAmountCtrl);
    _disposeIfMounted(deliveryAddressCtrl);
    _disposeIfMounted(freightChargeCtrl);
    _disposeIfMounted(billingAddressCtrl);
    _disposeIfMounted(deliveryInstructionsCtrl);
    tabScrollController.dispose();

    super.onClose(); // Always call super.onClose() last
  }

  /// Attach tab scroll centering listener once to avoid multiple subscriptions.
  void attachTabScrollListener(BuildContext context) {
    if (_tabScrollListenerAttached) return;
    _tabScrollListenerAttached = true;
    
    // Store context safely and check if mounted before using
    ever<int>(currentTab, (index) {
      try {
        // Check if context is still valid and mounted
        if (context.mounted) {
          final double estimatedTabWidth = 120.0;
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
        }
      } catch (e) {
        // Silently handle context errors
        print('Tab scroll listener error: $e');
      }
    });
  }

  void changeTab(int index) {
    // Allow immediate tab change for better UX
    currentTab.value = index;
  }

  void navigateToPreviousTab() {
    if (currentTab.value > 0) {
      currentTab.value--;
    }
  }

  void navigateToNextTab() {
    if (currentTab.value < 3) {
      currentTab.value++;
    } else {
      // Validate only when submitting on the last tab
      if (formKey.currentState?.validate() ?? false) {
        submitFormToBackend();
      } else {
        Fluttertoast.showToast(
          msg: 'Please fill all required fields before submitting.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
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


  // API Call Methods

  // Generate GC number based on branch code
  Future<String> generateGcNumber() async {
    if (selectedBranchCode.value.isEmpty || selectedBranch.value == 'Select Branch') {
      return '';
    }

    try {
      // Get all GC numbers for the company
      final url = Uri.parse('${ApiConfig.baseUrl}/gc/gcList/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final List<dynamic> gcList = jsonDecode(response.body);
        final branchPrefix = selectedBranchCode.value;
        
        // Filter GC numbers for the current branch and extract numeric parts
        final branchGcNumbers = gcList
            .where((gc) => 
                gc['GcNumber'] != null && 
                gc['GcNumber'].toString().startsWith(branchPrefix) &&
                gc['GcNumber'].toString().length > branchPrefix.length)
            .map((gc) {
              final gcNumber = gc['GcNumber'].toString();
              final numericPart = gcNumber.substring(branchPrefix.length);
              return int.tryParse(numericPart) ?? 0;
            })
            .where((number) => number > 0) // Filter out invalid numbers
            .toList();
        
        // Find the highest number and increment
        final nextNumber = branchGcNumbers.isNotEmpty 
            ? (branchGcNumbers.reduce((a, b) => a > b ? a : b) + 1)
            : 1; // Start from 1 if no existing GCs for this branch
            
        // Format with leading zeros (5 digits total)
        return '${branchPrefix}${nextNumber.toString().padLeft(5, '0')}';
      }
      
      // Fallback if API call fails
      return '${selectedBranchCode.value}00001';
    } catch (e) {
      print('Error generating GC number: $e');
      // Fallback in case of any error
      return '${selectedBranchCode.value}00001';
    }
  }

  // Handle branch selection
  void onBranchSelected(String? branch) async {
    if (branch == null || branch == 'Select Branch') {
      selectedBranch.value = 'Select Branch';
      selectedBranchCode.value = '';
      gcNumberCtrl.clear();
      return;
    }
    
    // Only proceed if branch has changed
    if (selectedBranch.value != branch) {
      selectedBranch.value = branch;
      selectedBranchCode.value = branchCodeMap[branch] ?? '';
      
      // Generate and set GC number
      if (selectedBranchCode.value.isNotEmpty) {
        try {
          isLoading.value = true;
          final newGcNumber = await generateGcNumber();
          if (newGcNumber.isNotEmpty) {
            gcNumberCtrl.text = newGcNumber;
          } else {
            // Fallback: Generate a default number if API call fails
            gcNumberCtrl.text = '${selectedBranchCode.value}00001';
          }
        } catch (e) {
          print('Error generating GC number: $e');
          gcNumberCtrl.text = '${selectedBranchCode.value}00001';
        } finally {
          isLoading.value = false;
        }
      }
    }
  }

  Future<void> fetchBranches() async {
    try {
      branchesLoading.value = true;
      branchesError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/location/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          // Clear existing data
          branches.clear();
          branchCodeMap.clear();
          
          // Add default option
          branches.add('Select Branch');
          
          // Process each branch
          for (var branch in decoded) {
            final name = (branch['branchName'] ?? branch['BranchName'] ?? '').toString();
            final code = (branch['branchCode'] ?? branch['BranchCode'] ?? '').toString();
            
            if (name.isNotEmpty && code.isNotEmpty) {
              branches.add(name);
              branchCodeMap[name] = code;
            }
          }
          
          // Remove duplicates and sort
          branches.value = branches.toSet().toList()..sort((a, b) => a == 'Select Branch' ? -1 : a.compareTo(b));
          
          // Reset selection if needed
          if (!branches.contains(selectedBranch.value)) {
            selectedBranch.value = 'Select Branch';
            selectedBranchCode.value = '';
          }
        } else {
          branchesError.value = 'Unexpected response format';
        }
      } else {
        branchesError.value = 'Failed to load branches (${response.statusCode})';
      }
    } catch (e) {
      branchesError.value = 'Failed to load branches. Tap to retry.';
    } finally {
      branchesLoading.value = false;
    }
  }

  Future<void> fetchTrucks() async {
    try {
      trucksLoading.value = true;
      trucksError.value = null;
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
            
          // Also update the trucks list for backward compatibility
          trucks
            ..clear()
            ..addAll(['Select Truck', ...list]);
            
          if (!truckNumbers.contains(selectedTruck.value)) {
            selectedTruck.value = 'Select Truck';
          }
        } else {
          trucksError.value = 'Unexpected response format';
        }
      } else {
        trucksError.value = 'Failed to load trucks (${response.statusCode})';
      }
    } catch (e) {
      trucksError.value = 'Failed to load trucks. Tap to retry.';
    } finally {
      trucksLoading.value = false;
    }
  }

  Future<void> fetchBrokers() async {
    try {
      brokersLoading.value = true;
      brokersError.value = null;
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
          brokersError.value = 'Unexpected brokers response format';
        }
      } else {
        brokersError.value = 'Failed to load brokers: Tap to retry.';
      }
    } catch (e) {
      final errorMsg = 'Failed to load brokers: Tap to retry.';
      brokersError.value = errorMsg;
    } finally {
      brokersLoading.value = false;
    }
  }

  Future<void> fetchDrivers() async {
    try {
      driversLoading.value = true;
      driversError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/driver/search');
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

        // Clear and update the drivers list with the new data
        drivers.assignAll(decoded.cast<Map<String, dynamic>>());
        
        // Force UI update by triggering a change in the observable list
        drivers.refresh();
        
        if (driverNames.isEmpty) {
          driversError.value = 'No drivers found';
        }

        if (driverNames.isEmpty) {
          Fluttertoast.showToast(
            msg: 'No drivers found',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        final errorMsg = 'Failed to load drivers: Tap to retry.';
        driversError.value = errorMsg;
        Fluttertoast.showToast(
          msg: errorMsg,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      final errorMsg = 'Failed to load drivers: Tap to retry.';
      driversError.value = errorMsg;
      Fluttertoast.showToast(
        msg: errorMsg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      driversLoading.value = false;
    }
  }


  Future<void> fetchConsignors() async {
    try {
      consignorsLoading.value = true;
      consignorsError.value = null;
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
            consignorsError.value = 'No consignors found';
          }
        } else {
          consignorsError.value = 'Unexpected response format';
        }
      } else {
        consignorsError.value = 'Failed to load consignors (${response.statusCode})';
      }
    } catch (e) {
      consignorsError.value = 'Failed to load consignors. Tap to retry.';
    } finally {
      consignorsLoading.value = false;
    }
  }

  Future<void> fetchConsignees() async {
    try {
      consigneesLoading.value = true;
      consigneesError.value = null;
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
            consigneesError.value = 'No consignees found';
          }
        } else {
          consigneesError.value = 'Unexpected response format';
        }
      } else {
        consigneesError.value = 'Failed to load consignees (${response.statusCode})';
      }
    } catch (e) {
      consigneesError.value = 'Failed to load consignees. Tap to retry.';
    } finally {
      consigneesLoading.value = false;
    }
  }

  Future<void> fetchWeightRates() async {
    try {
      isLoadingRates.value = true;
      weightRatesError.value = '';
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/weight_to_rate/search'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        weightRates.assignAll(
          data.map((item) => WeightRate.fromJson(item)).toList(),
        );
        if (weightRates.isEmpty) {
          weightRatesError.value = 'No weight rates found';
        }
        // If we're editing and an actual weight is present but nothing selected yet,
        // try to auto-select a matching weight rate now that data is available
        if (isEditMode.value && selectedWeight.value == null) {
          final wStr = actualWeightCtrl.text.trim();
          if (wStr.isNotEmpty) {
            selectWeightForActualWeight(wStr);
          }
        }
      } else {
        weightRatesError.value = 'Failed to load weight rates. Tap to retry.';
      }
    } catch (e) {
      weightRatesError.value = 'Failed to load weight rates. Tap to retry.';
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
        Fluttertoast.showToast(
          msg: 'Failed to load KM locations: ${response.statusCode}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error fetching KM locations: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
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
    final km = double.tryParse(kmCtrl.text) ?? 0.0;

    // If KM is invalid or zero, clear only the total (keep any typed rate)
    if (km <= 0) {
      freightChargeCtrl.clear();
      calculatedGoodsTotal.value = '';
      return;
    }

    // Case 1: We have a selected weight rate -> derive rate from weight/km tier
    if (selectedWeight.value != null) {
      final baseRate = km <= 250
          ? selectedWeight.value!.below250
          : selectedWeight.value!.above250;

      rateCtrl.text = baseRate.toStringAsFixed(2); // rate per KM

      final totalFreight = baseRate * km;
      freightChargeCtrl.text = totalFreight.toStringAsFixed(2);
      calculatedGoodsTotal.value = totalFreight.toStringAsFixed(2);
      return;
    }

    // Case 2: No selected weight rate (e.g., editing existing GC)
    // If a rate is already present, use it to compute the total
    final existingRate = double.tryParse(rateCtrl.text);
    if (existingRate != null && existingRate > 0) {
      final totalFreight = existingRate * km;
      freightChargeCtrl.text = totalFreight.toStringAsFixed(2);
      calculatedGoodsTotal.value = totalFreight.toStringAsFixed(2);
      return;
    }

    // Otherwise, nothing to compute yet
    freightChargeCtrl.clear();
    calculatedGoodsTotal.value = '';
  }

  // Update selected weight and calculate rate
  void onWeightSelected(WeightRate? weight) {
    selectedWeight.value = weight;
    // Also update the actualWeightCtrl.text with the weight value so it gets sent to backend
    if (weight != null) {
      actualWeightCtrl.text = weight.weight;
    } else {
      actualWeightCtrl.clear();
    }
    calculateRate(); // Recalculate rate and total when weight changes
  }

  // Attempts to pick a WeightRate for a given actual weight string and trigger recalculation
  void selectWeightForActualWeight(String weightStr) {
    final rate = pickWeightRateForActualWeight(weightStr);
    selectedWeight.value = rate;
    // Also update the actualWeightCtrl.text with the weight value so it gets sent to backend
    if (rate != null) {
      actualWeightCtrl.text = rate.weight;
    } else {
      actualWeightCtrl.clear();
    }
    calculateRate();
  }

  // Parses available weight rate labels and tries multiple strategies (including unit conversion)
  // to match the given actual weight string
  WeightRate? pickWeightRateForActualWeight(String weightStr) {
    final cleanedInput = weightStr.trim().toLowerCase();
    final actualRaw = double.tryParse(cleanedInput.replaceAll(RegExp(r'[^0-9\.]'), ''));

    WeightRate? exactTextMatch;
    WeightRate? containsTextMatch;
    WeightRate? numericMatch;

    for (final wr in weightRates) {
      final labelRaw = wr.weight;
      final label = labelRaw.trim().toLowerCase();

      // 1) Exact, case-insensitive text match
      if (label == cleanedInput) {
        exactTextMatch = wr;
        break;
      }

      // 2) Contains match either way (handles labels like "19MT" vs input "19" or vice versa)
      if (label.contains(cleanedInput) || cleanedInput.contains(label)) {
        containsTextMatch ??= wr;
      }

      // 3) Numeric-normalized matching (supports kg and ton inputs)
      if (actualRaw != null) {
        // Try multiple interpretations: as-is, kg->tons, tons->kg
        final candidates = <double>{
          actualRaw,
          actualRaw / 1000.0,
          actualRaw * 1000.0,
        };

        final labelNum = double.tryParse(label.replaceAll(RegExp(r'[^0-9\.]'), ''));
        if (labelNum != null) {
          for (final actual in candidates) {
            if ((labelNum - actual).abs() < 0.0001) {
              numericMatch ??= wr;
              break;
            }
          }
        }

        // Also support common bracket-like labels (e.g., "0-250", ">250")
        final dash = RegExp(r'^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)$');
        final plus = RegExp(r'^(\d+(?:\.\d+)?)\s*\+$');
        final above = RegExp(r'^(?:above|>)\s*(\d+(?:\.\d+)?)$');
        final below = RegExp(r'^(?:below|<)\s*(\d+(?:\.\d+)?)$');
        final eqNum = RegExp(r'^(\d+(?:\.\d+)?)$');

        RegExpMatch? m;
        if ((m = dash.firstMatch(label)) != null) {
          final low = double.tryParse(m!.group(1)!) ?? double.negativeInfinity;
          final high = double.tryParse(m.group(2)!) ?? double.infinity;
          for (final actual in candidates) {
            if (actual >= low && actual <= high) {
              numericMatch ??= wr;
              break;
            }
          }
        } else if ((m = plus.firstMatch(label)) != null) {
          final base = double.tryParse(m!.group(1)!) ?? double.negativeInfinity;
          for (final actual in candidates) {
            if (actual >= base) {
              numericMatch ??= wr;
              break;
            }
          }
        } else if ((m = above.firstMatch(label)) != null) {
          final th = double.tryParse(m!.group(1)!) ?? double.negativeInfinity;
          for (final actual in candidates) {
            if (actual > th) {
              numericMatch ??= wr;
              break;
            }
          }
        } else if ((m = below.firstMatch(label)) != null) {
          final th = double.tryParse(m!.group(1)!) ?? double.infinity;
          for (final actual in candidates) {
            if (actual <= th) {
              numericMatch ??= wr;
              break;
            }
          }
        } else if ((m = eqNum.firstMatch(label)) != null) {
          final num = double.tryParse(m!.group(1)!) ?? double.nan;
          for (final actual in candidates) {
            if ((num - actual).abs() < 0.0001) {
              numericMatch ??= wr;
              break;
            }
          }
        }
      }
    }

    return exactTextMatch ?? numericMatch ?? containsTextMatch; // best available
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
  }


  

  // Clear all form fields and reset state
  void clearForm() {
    // Reset form validation state
    formKey.currentState?.reset();
    
    // Clear all text controllers
    gcNumberCtrl.clear();
    gcDateCtrl.clear();
    eDaysCtrl.clear();
    deliveryDateCtrl.clear();
    truckNumberCtrl.clear();
    truckTypeCtrl.clear();
    fromCtrl.clear();
    toCtrl.clear();
    poNumberCtrl.clear();
    tripIdCtrl.clear();
    driverNameCtrl.clear();
    driverPhoneCtrl.clear();
    consignorNameCtrl.clear();
    consignorGstCtrl.clear();
    consignorAddressCtrl.clear();
    consigneeNameCtrl.clear();
    consigneeGstCtrl.clear();
    consigneeAddressCtrl.clear();
    customInvoiceCtrl.clear();
    invValueCtrl.clear();
    ewayBillCtrl.clear();
    ewayBillDateCtrl.clear();
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
    
    // Reset reactive values
    gcDate.value = null;
    deliveryDate.value = null;
    ewayBillDate.value = null;
    ewayExpired.value = null;
    balanceAmount.value = '0.00';
    
    // Reset dropdowns to default values
    selectedTruck.value = 'Select Truck';
    selectedBroker.value = 'Select Broker';
    selectedDriver.value = '';
    selectedConsignor.value = 'Select Consignor';
    selectedConsignee.value = 'Select Consignee';
    selectedPayment.value = 'Cash';
    selectedService.value = 'Express';
    selectedGstPayer.value = 'Consignor';
    selectedPackageMethod.value = 'Boxes';
    
    // Reset weight selection
    selectedWeight.value = null;
    
    // Clear edit mode
    isEditMode.value = false;
    editingGcNumber.value = '';
    editingCompanyId.value = '';
    
    // Clear calculated values
    calculatedGoodsTotal.value = '';
  }

  // Helper method to format dates
  String formatDate(DateTime date) {
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  Future<void> submitFormToBackend() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    
    final Map<String, dynamic> data = {
      'Branch': selectedBranch.value,
      'BranchCode': '', // Add if available
      'GcNumber': gcNumberCtrl.text,
      'GcDate': gcDate.value?.toIso8601String(),
      'TruckNumber': selectedTruck.value,
      'vechileNumber': selectedTruck.value, // Backend expects this field name
      'TruckType': truckTypeCtrl.text,
      'BrokerNameShow': selectedBroker.value,
      'BrokerName': selectedBroker.value,
      'TruckFrom': fromCtrl.text,
      'TruckTo': toCtrl.text,
      'PaymentDetails': selectedPayment.value,
      'LcNo': '', // Add if available
      'DeliveryDate': deliveryDate.value?.toIso8601String(),
      'EBillDate': ewayBillDate.value?.toIso8601String(),
      'DriverNameShow': selectedDriver.value,
      'DriverName': selectedDriver.value,
      'DriverPhoneNumber': driverPhoneCtrl.text,
      'Consignor': selectedConsignor.value,
      'ConsignorName': selectedConsignor.value,
      'ConsignorAddress': consignorAddressCtrl.text,
      'ConsignorGst': consignorGstCtrl.text,
      'Consignee': selectedConsignee.value,
      'ConsigneeName': selectedConsignee.value,
      'ConsigneeAddress': consigneeAddressCtrl.text,
      'ConsigneeGst': consigneeGstCtrl.text,
      'CustInvNo': customInvoiceCtrl.text,
      'InvValue': invValueCtrl.text,
      'EInv': ewayBillCtrl.text,
      'EInvDate': ewayBillDate.value?.toIso8601String(),
      'Eda': ewayExpired.value?.toIso8601String(),
      'NumberofPkg': packagesCtrl.text,
      'MethodofPkg': selectedPackageMethod.value,
      'ActualWeightKgs': actualWeightCtrl.text,
      'NumberofPkg2': '', // Add if available
      'MethodofPkg2': '', // Add if available
      'ActualWeightKgs2': '', // Add if available
      'km': kmCtrl.text,
      'km2': '', // Add if available
      'km3': '', // Add if available
      'km4': '', // Add if available
      'NumberofPkg3': '', // Add if available
      'MethodofPkg3': '', // Add if available
      'ActualWeightKgs3': '', // Add if available
      'NumberofPkg4': '', // Add if available
      'MethodofPkg4': '', // Add if available
      'ActualWeightKgs4': '', // Add if available
      'PrivateMark': remarksCtrl.text,
      'PrivateMark2': '', // Add if available
      'PrivateMark3': '', // Add if available
      'PrivateMark4': '', // Add if available
      'Charges': '', // Add if available
      'Charges2': '', // Add if available
      'Charges3': '', // Add if available
      'Charges4': '', // Add if available
      'GoodContain': natureGoodsCtrl.text,
      'GoodContain2': '', // Add if available
      'GoodContain3': '', // Add if available
      'GoodContain4': '', // Add if available
      'Rate': rateCtrl.text,
      'Total': freightChargeCtrl.text,
      'Rate2': '', // Add if available
      'Total2': '', // Add if available
      'Rate3': '', // Add if available
      'Total3': '', // Add if available
      'Rate4': '', // Add if available
      'Total4': '', // Add if available
      'PoNumber': poNumberCtrl.text,
      'TripId': tripIdCtrl.text,
      'DeliveryFromSpecial': '', // Add if available
      'DeliveryAddress': deliveryAddressCtrl.text,
      'ServiceTax': '', // Add if available
      'ReceiptBillNo': '', // Add if available
      'ReceiptBillNoAmount': '', // Add if available
      'ReceiptBillNoDate': '', // Add if available
      'TotalRate': rateCtrl.text,
      'TotalWeight': actualWeightCtrl.text,
      'HireAmount': hireAmountCtrl.text,
      'AdvanceAmount': advanceAmountCtrl.text,
      'BalanceAmount': balanceAmount.value,
      'FreightCharge': freightChargeCtrl.text,
      'Day1': '', // Add if available
      'Day1Place': '', // Add if available
      'Day2': '', // Add if available
      'Day3': '', // Add if available
      'Day4': '', // Add if available
      'Day5': '', // Add if available
      'Day6': '', // Add if available
      'Day7': '', // Add if available
      'Day8': '', // Add if available
      'CompanyId': editingCompanyId.value.isNotEmpty ? editingCompanyId.value : '1', // Use stored company ID or default
    };

    try {
      final Uri url;
      final http.Response response;
      
      if (isEditMode.value && editingGcNumber.value.isNotEmpty) {
        // Update existing GC
        url = Uri.parse('${ApiConfig.baseUrl}/gc/updateGC/${editingGcNumber.value}');
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
        final message = isEditMode.value ? 'GC updated successfully!' : 'GC created successfully!';
        
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF4A90E2),
          textColor: Colors.white,
          fontSize: 16.0,
        );
        
        // Clear the form after successful operation
        clearForm();
        
        // Navigate back to GC list
        Get.until((route) => route.isFirst);
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      isLoading.value = false;
      final operation = isEditMode.value ? 'update' : 'create';
      Fluttertoast.showToast(
        msg: 'Failed to $operation GC: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }
}