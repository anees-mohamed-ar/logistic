import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:logistic/gc_form_screen.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'api_config.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GCListPage extends StatefulWidget {
  const GCListPage({Key? key}) : super(key: key);

  @override
  State<GCListPage> createState() => _GCListPageState();
}

class _GCListPageState extends State<GCListPage> {
  List<Map<String, dynamic>> gcList = [];
  List<Map<String, dynamic>> filteredGcList = [];
  bool isLoading = true;
  String? error;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGCList();
  }

  Future<void> fetchGCList() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/gc/search');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is List) {
          setState(() {
            gcList = List<Map<String, dynamic>>.from(decodedData.whereType<Map<String, dynamic>>());
            filteredGcList = List.from(gcList);
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Failed to load GC list: Unexpected data format';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load GC list: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load GC list: $e';
        isLoading = false;
      });
    }
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredGcList = List.from(gcList);
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      filteredGcList = gcList.where((gc) {
        return (gc['GcNumber']?.toString().toLowerCase().contains(lowerCaseQuery) ?? false) ||
            (gc['TruckNumber']?.toString().toLowerCase().contains(lowerCaseQuery) ?? false) ||
            (gc['PoNumber']?.toString().toLowerCase().contains(lowerCaseQuery) ?? false) ||
            (gc['TripId']?.toString().toLowerCase().contains(lowerCaseQuery) ?? false) ||
            (gc['DriverName']?.toString().toLowerCase().contains(lowerCaseQuery) ?? false) ||
            (gc['ConsignorName']?.toString().toLowerCase().contains(lowerCaseQuery) ?? false) ||
            (gc['Branch']?.toString().toLowerCase().contains(lowerCaseQuery) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GC List'),
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: filterSearchResults,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search GCs...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      )
          : filteredGcList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No GCs found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (searchController.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  searchController.clear();
                  filterSearchResults('');
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  minimumSize: const Size(0, 40),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchGCList,
        child: ListView.builder(
          itemCount: filteredGcList.length,
          itemBuilder: (context, index) {
            final gc = filteredGcList[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        gc['GcNumber'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Text('Branch: ${gc['Branch'] ?? ''}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('GC Date', gc['GcDate']),
                        _infoRow('Truck Number', gc['TruckNumber']),
                        _infoRow('PO Number', gc['PoNumber']),
                        _infoRow('Trip ID', gc['TripId']),
                        _infoRow('Broker Name', gc['BrokerName']),
                        _infoRow('Driver Name', gc['DriverName']),
                        _infoRow('Consignor Name', gc['ConsignorName']),
                        _infoRow('Consignor GST', gc['ConsignorGst']),
                        _infoRow(
                          'Consignor Address',
                          gc['ConsignorAddress'],
                        ),
                        _infoRow('Consignee Name', gc['ConsigneeName']),
                        _infoRow('Consignee GST', gc['ConsigneeGst']),
                        _infoRow(
                          'Consignee Address',
                          gc['ConsigneeAddress'],
                        ),
                        _infoRow('Number of Packages', gc['NumberofPkg']),
                        _infoRow('Package Method', gc['MethodofPkg']),
                        _infoRow(
                          'Actual Weight (kg)',
                          gc['ActualWeightKgs'],
                        ),
                        _infoRow('Rate', gc['Rate']),
                        _infoRow('Distance (KM)', gc['km']),
                        _infoRow('Hire Amount', gc['HireAmount']),
                        _infoRow('Advance Amount', gc['AdvanceAmount']),
                        _infoRow('Delivery Address', gc['DeliveryAddress']),
                        _infoRow('Freight Charge', gc['FreightCharge']),
                        _infoRow('Payment Method', gc['PaymentDetails']),
                        const SizedBox(height: 16),
                        // Edit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _editGC(gc),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit GC'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90E2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ].where((w) => w != null).cast<Widget>().toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  void _editGC(Map<String, dynamic> gc) {
    // Get company ID from IdController
    final idController = Get.find<IdController>();
    final companyId = idController.companyId.value;
    
    if (companyId.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Company ID not found. Please login again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Check if we already have a controller (e.g., when coming back from another screen)
    final gcController = Get.put(GCFormController(), permanent: false);
    
    // Reset the form before populating with new data
    gcController.clearForm();
    
    // Set edit mode before populating the form
    gcController.isEditMode.value = true;
    gcController.editingGcNumber.value = gc['GcNumber']?.toString() ?? '';
    gcController.editingCompanyId.value = companyId;

    // Populate form with existing GC data
    _populateFormWithGCData(gcController, gc, companyId);

    // Navigate to GC form screen
    Get.to(
      () => const GCFormScreen(),
      preventDuplicates: false,
    )?.then((_) {
      // Don't dispose the controller here as it might still be in use
      // The controller will be properly managed by GetX's dependency injection
    });
  }

  void _populateFormWithGCData(GCFormController controller, Map<String, dynamic> gc, String companyId) {
    // Store the GC number and company ID for update operation
    controller.gcNumberCtrl.text = gc['GcNumber']?.toString() ?? '';
    
    // Set edit mode flag (we'll add this to the controller)
    controller.isEditMode.value = true;
    controller.editingGcNumber.value = gc['GcNumber']?.toString() ?? '';
    controller.editingCompanyId.value = companyId;

    // Populate all available fields from the GC data
    controller.selectedBranch.value = gc['Branch']?.toString() ?? 'Select Branch';
    
    // Handle dates
    if (gc['GcDate'] != null) {
      try {
        final gcDate = DateTime.parse(gc['GcDate'].toString());
        controller.gcDate.value = gcDate;
        controller.gcDateCtrl.text = controller.formatDate(gcDate);
      } catch (e) {
        // Handle date parsing error
      }
    }
    
    if (gc['DeliveryDate'] != null) {
      try {
        final deliveryDate = DateTime.parse(gc['DeliveryDate'].toString());
        controller.deliveryDate.value = deliveryDate;
        controller.deliveryDateCtrl.text = controller.formatDate(deliveryDate);
      } catch (e) {
        // Handle date parsing error
      }
    }

    // Vehicle details
    controller.selectedTruck.value = gc['TruckNumber']?.toString() ?? 'Select Truck';
    controller.truckNumberCtrl.text = gc['TruckNumber']?.toString() ?? '';
    controller.truckTypeCtrl.text = gc['TruckType']?.toString() ?? '';
    controller.poNumberCtrl.text = gc['PoNumber']?.toString() ?? '';
    controller.tripIdCtrl.text = gc['TripId']?.toString() ?? '';

    // Location details
    controller.fromCtrl.text = gc['TruckFrom']?.toString() ?? '';
    controller.toCtrl.text = gc['TruckTo']?.toString() ?? '';

    // Parties details
    controller.selectedBroker.value = gc['BrokerName']?.toString() ?? 'Select Broker';
    controller.brokerNameCtrl.text = gc['BrokerName']?.toString() ?? '';
    controller.selectedDriver.value = gc['DriverName']?.toString() ?? '';
    controller.driverNameCtrl.text = gc['DriverName']?.toString() ?? '';
    controller.driverPhoneCtrl.text = gc['DriverPhoneNumber']?.toString() ?? '';

    // Consignor details
    controller.selectedConsignor.value = gc['ConsignorName']?.toString() ?? 'Select Consignor';
    controller.consignorNameCtrl.text = gc['ConsignorName']?.toString() ?? '';
    controller.consignorGstCtrl.text = gc['ConsignorGst']?.toString() ?? '';
    controller.consignorAddressCtrl.text = gc['ConsignorAddress']?.toString() ?? '';
    
    // Consignee details
    final consigneeAddress = gc['ConsigneeAddress']?.toString() ?? '';
    controller.selectedConsignee.value = gc['ConsigneeName']?.toString() ?? 'Select Consignee';
    controller.consigneeNameCtrl.text = gc['ConsigneeName']?.toString() ?? '';
    controller.consigneeGstCtrl.text = gc['ConsigneeGst']?.toString() ?? '';
    controller.consigneeAddressCtrl.text = consigneeAddress;
    
    // Goods details - using correct field names from the API response
    final weight = gc['ActualWeightKgs']?.toString() ?? ''; // Using ActualWeightKgs instead of Weight
    final natureOfGoods = gc['GoodContain']?.toString() ?? ''; // Using GoodContain for nature of goods
    final methodOfPkg = (gc['MethodofPkg']?.toString() ?? '').isNotEmpty 
        ? gc['MethodofPkg'].toString() 
        : 'Boxes';
        
    print('Nature of goods from API: $natureOfGoods'); // Debug log
    
    // Update weight
    controller.weightCtrl.text = weight;
    
    // Update nature of goods in both controllers
    controller.natureOfGoodsCtrl.text = natureOfGoods;
    controller.natureGoodsCtrl.text = natureOfGoods;
    
    // Update package method - convert to title case for consistency
    final formattedMethod = (methodOfPkg?.isNotEmpty ?? false)
        ? '${methodOfPkg![0].toUpperCase()}${methodOfPkg.substring(1).toLowerCase()}'
        : 'Boxes';
    controller.methodPackageCtrl.text = formattedMethod;
    controller.selectedPackageMethod.value = formattedMethod;
    
    // Update other goods fields
    controller.packagesCtrl.text = gc['NumberofPkg']?.toString() ?? '';
    controller.actualWeightCtrl.text = weight; // Using the same weight value
    
    // Set billing address to consignee's address
    controller.billingAddressCtrl.text = consigneeAddress;
    
    // Pre-fill KM and Rate BEFORE selecting weight so calculation has all inputs
    controller.actualWeightCtrl.text = gc['ActualWeightKgs']?.toString() ?? '';
    controller.kmCtrl.text = gc['km']?.toString() ?? '';
    controller.rateCtrl.text = gc['Rate']?.toString() ?? '';

    // Auto-select the appropriate weight bracket (e.g., 0-250, 251-500) for the given actual weight
    if (weight.isNotEmpty) {
      controller.selectWeightForActualWeight(weight);
    } else {
      controller.selectedWeight.value = null;
      controller.calculateRate();
    }

    // Force update the UI
    controller.update();

    // Charges details
    controller.hireAmountCtrl.text = gc['HireAmount']?.toString() ?? '';
    controller.advanceAmountCtrl.text = gc['AdvanceAmount']?.toString() ?? '';
    controller.deliveryAddressCtrl.text = gc['DeliveryAddress']?.toString() ?? '';
    // If backend has a stored total, keep it only if calculation didn't produce one
    if ((controller.freightChargeCtrl.text).isEmpty) {
      controller.freightChargeCtrl.text = gc['FreightCharge']?.toString() ?? '';
    }
    controller.selectedPayment.value = gc['PaymentDetails']?.toString() ?? 'Cash';

    // Additional fields that might be available
    controller.customInvoiceCtrl.text = gc['CustInvNo']?.toString() ?? '';
    controller.invValueCtrl.text = gc['InvValue']?.toString() ?? '';
    controller.ewayBillCtrl.text = gc['EInv']?.toString() ?? '';
    
    // Handle E-way bill date
    if (gc['EInvDate'] != null) {
      try {
        final ewayDate = DateTime.parse(gc['EInvDate'].toString());
        controller.ewayBillDate.value = ewayDate;
        controller.ewayBillDateCtrl.text = controller.formatDate(ewayDate);
      } catch (e) {
        // Handle date parsing error
      }
    }
    
    // Handle E-way bill expiry date
    if (gc['Eda'] != null) {
      try {
        final ewayExpDate = DateTime.parse(gc['Eda'].toString());
        controller.ewayExpired.value = ewayExpDate;
        controller.ewayExpiredCtrl.text = controller.formatDate(ewayExpDate);
      } catch (e) {
        // Handle date parsing error
      }
    }
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}