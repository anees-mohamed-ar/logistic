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
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF7F9FC),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _checkAndNavigateToGCForm,
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add GC'),
      ),
    );
  }

  Future<void> _checkAndNavigateToGCForm() async {
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
      return;
    }

    final gcFormController = Get.put(GCFormController());
    final hasAccess = await gcFormController.checkGCAccess(userId);
    
    if (hasAccess) {
      Get.to(() => const GCFormScreen());
    } else {
      Fluttertoast.showToast(
        msg: gcFormController.accessMessage.value,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GC Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Goods Consignment List', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E2A44),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${filteredGcList.length} GCs',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: searchController,
            onChanged: filterSearchResults,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by GC Number, Truck, Driver, etc...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: () {
                        searchController.clear();
                        filterSearchResults('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54, width: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }
    
    if (error != null) {
      return _buildErrorState();
    }
    
    if (filteredGcList.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildGCList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E2A44)),
          SizedBox(height: 16),
          Text(
            'Loading GC records...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchGCList,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                searchController.text.isNotEmpty ? Icons.search_off : Icons.description,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchController.text.isNotEmpty ? 'No matching GCs found' : 'No GC records available',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchController.text.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'GC records will appear here once created',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (searchController.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  searchController.clear();
                  filterSearchResults('');
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2A44),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGCList() {
    return RefreshIndicator(
      onRefresh: fetchGCList,
      color: const Color(0xFF1E2A44),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredGcList.length,
        itemBuilder: (context, index) {
          final gc = filteredGcList[index];
          return _buildGCCard(gc, index);
        },
      ),
    );
  }

  Widget _buildGCCard(Map<String, dynamic> gc, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            tilePadding: EdgeInsets.zero,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: EdgeInsets.zero,
          title: _buildCardHeader(gc),
          subtitle: _buildCardSubtitle(gc),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A44).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.expand_more,
              color: Color(0xFF1E2A44),
            ),
          ),
          children: [
            _buildCardDetails(gc),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> gc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A44),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            gc['GcNumber'] ?? 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gc['TruckNumber'] ?? 'No Truck',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              if (gc['DriverName']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  'Driver: ${gc['DriverName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardSubtitle(Map<String, dynamic> gc) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _buildInfoChip(Icons.business, gc['Branch']),
          const SizedBox(width: 8),
          if (gc['GcDate']?.toString().isNotEmpty == true)
            _buildInfoChip(Icons.calendar_today, _formatDisplayDate(gc['GcDate'])),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails(Map<String, dynamic> gc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Information Section
          _buildDetailSection(
            'Trip Information',
            Icons.local_shipping,
            [
              _infoRow('PO Number', gc['PoNumber']),
              _infoRow('Trip ID', gc['TripId']),
              _infoRow('Distance (KM)', gc['km']),
              _infoRow('Route', '${gc['TruckFrom'] ?? ''} → ${gc['TruckTo'] ?? ''}'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Parties Information Section
          _buildDetailSection(
            'Parties Information',
            Icons.people,
            [
              _infoRow('Broker', gc['BrokerName']),
              _infoRow('Consignor', gc['ConsignorName']),
              _infoRow('Consignor GST', gc['ConsignorGst']),
              _infoRow('Consignor Address', gc['ConsignorAddress']),
              _infoRow('Consignee', gc['ConsigneeName']),
              _infoRow('Consignee GST', gc['ConsigneeGst']),
              _infoRow('Consignee Address', gc['ConsigneeAddress']),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Goods Information Section
          _buildDetailSection(
            'Goods Information',
            Icons.inventory,
            [
              _infoRow('Packages', gc['NumberofPkg']),
              _infoRow('Package Method', gc['MethodofPkg']),
              _infoRow('Actual Weight (kg)', gc['ActualWeightKgs']),
              _infoRow('Goods Description', gc['GoodContain']),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Financial Information Section
          _buildDetailSection(
            'Financial Details',
            Icons.account_balance_wallet,
            [
              _infoRow('Rate', gc['Rate']),
              _infoRow('Hire Amount', gc['HireAmount']),
              _infoRow('Advance Amount', gc['AdvanceAmount']),
              _infoRow('Freight Charge', gc['FreightCharge']),
              _infoRow('Payment Method', gc['PaymentDetails']),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Edit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _editGC(gc),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit GC Record'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    final validChildren = children.where((child) => child is! SizedBox || child.height != 0).toList();
    
    if (validChildren.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1E2A44)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: validChildren,
          ),
        ),
      ],
    );
  }

  String _formatDisplayDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  // [Previous methods remain the same: _editGC and _populateFormWithGCData]
  void _editGC(Map<String, dynamic> gc) {
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

    final gcController = Get.put(GCFormController(), permanent: false);
    gcController.clearForm();
    gcController.isEditMode.value = true;
    gcController.editingGcNumber.value = gc['GcNumber']?.toString() ?? '';
    gcController.editingCompanyId.value = companyId;

    if (gcController.weightRates.isEmpty) {
      gcController.fetchWeightRates().then((_) {
        _populateFormWithGCData(gcController, gc, companyId);
      });
    } else {
      _populateFormWithGCData(gcController, gc, companyId);
    }

    Get.to(
      () => const GCFormScreen(),
      preventDuplicates: false,
    );
  }

  void _populateFormWithGCData(GCFormController controller, Map<String, dynamic> gc, String companyId) {
    controller.gcNumberCtrl.text = gc['GcNumber']?.toString() ?? '';
    controller.isEditMode.value = true;
    controller.editingGcNumber.value = gc['GcNumber']?.toString() ?? '';
    controller.editingCompanyId.value = companyId;

    controller.selectedBranch.value = gc['Branch']?.toString() ?? 'Select Branch';
    
    if (gc['GcDate'] != null) {
      try {
        final gcDate = DateTime.parse(gc['GcDate'].toString());
        controller.gcDate.value = gcDate;
        controller.gcDateCtrl.text = controller.formatDate(gcDate);
      } catch (e) {}
    }
    
    if (gc['DeliveryDate'] != null) {
      try {
        final deliveryDate = DateTime.parse(gc['DeliveryDate'].toString());
        controller.deliveryDate.value = deliveryDate;
        controller.deliveryDateCtrl.text = controller.formatDate(deliveryDate);
      } catch (e) {}
    }

    controller.selectedTruck.value = gc['TruckNumber']?.toString() ?? 'Select Truck';
    controller.truckNumberCtrl.text = gc['TruckNumber']?.toString() ?? '';
    controller.truckTypeCtrl.text = gc['TruckType']?.toString() ?? '';
    controller.poNumberCtrl.text = gc['PoNumber']?.toString() ?? '';
    controller.tripIdCtrl.text = gc['TripId']?.toString() ?? '';

    controller.fromCtrl.text = gc['TruckFrom']?.toString() ?? '';
    controller.toCtrl.text = gc['TruckTo']?.toString() ?? '';

    controller.selectedBroker.value = gc['BrokerName']?.toString() ?? 'Select Broker';
    controller.brokerNameCtrl.text = gc['BrokerName']?.toString() ?? '';
    controller.selectedDriver.value = gc['DriverName']?.toString() ?? '';
    controller.driverNameCtrl.text = gc['DriverName']?.toString() ?? '';
    controller.driverPhoneCtrl.text = gc['DriverPhoneNumber']?.toString() ?? '';

    controller.selectedConsignor.value = gc['ConsignorName']?.toString() ?? 'Select Consignor';
    controller.consignorNameCtrl.text = gc['ConsignorName']?.toString() ?? '';
    controller.consignorGstCtrl.text = gc['ConsignorGst']?.toString() ?? '';
    controller.consignorAddressCtrl.text = gc['ConsignorAddress']?.toString() ?? '';
    
    final consigneeAddress = gc['ConsigneeAddress']?.toString() ?? '';
    controller.selectedConsignee.value = gc['ConsigneeName']?.toString() ?? 'Select Consignee';
    controller.consigneeNameCtrl.text = gc['ConsigneeName']?.toString() ?? '';
    controller.consigneeGstCtrl.text = gc['ConsigneeGst']?.toString() ?? '';
    controller.consigneeAddressCtrl.text = consigneeAddress;
    
    final weight = gc['ActualWeightKgs']?.toString() ?? '';
    final natureOfGoods = gc['GoodContain']?.toString() ?? '';
    final methodOfPkg = (gc['MethodofPkg']?.toString() ?? '').isNotEmpty 
        ? gc['MethodofPkg'].toString() 
        : 'Boxes';
        
    controller.weightCtrl.text = weight;
    controller.natureOfGoodsCtrl.text = natureOfGoods;
    controller.natureGoodsCtrl.text = natureOfGoods;
    
    final formattedMethod = (methodOfPkg?.isNotEmpty ?? false)
        ? '${methodOfPkg![0].toUpperCase()}${methodOfPkg.substring(1).toLowerCase()}'
        : 'Boxes';
    controller.methodPackageCtrl.text = formattedMethod;
    controller.selectedPackageMethod.value = formattedMethod;
    
    controller.packagesCtrl.text = gc['NumberofPkg']?.toString() ?? '';
    controller.actualWeightCtrl.text = weight;
    controller.remarksCtrl.text = gc['PrivateMark']?.toString() ?? '';
    controller.billingAddressCtrl.text = consigneeAddress;
    
    controller.actualWeightCtrl.text = gc['ActualWeightKgs']?.toString() ?? '';
    controller.kmCtrl.text = gc['km']?.toString() ?? '';
    controller.rateCtrl.text = gc['Rate']?.toString() ?? '';

    if (weight.isNotEmpty) {
      controller.selectWeightForActualWeight(weight);
    } else {
      controller.selectedWeight.value = null;
      controller.calculateRate();
    }

    controller.update();

    controller.hireAmountCtrl.text = gc['HireAmount']?.toString() ?? '';
    controller.advanceAmountCtrl.text = gc['AdvanceAmount']?.toString() ?? '';
    controller.deliveryAddressCtrl.text = gc['DeliveryAddress']?.toString() ?? '';
    if ((controller.freightChargeCtrl.text).isEmpty) {
      controller.freightChargeCtrl.text = gc['FreightCharge']?.toString() ?? '';
    }
    controller.selectedPayment.value = gc['PaymentDetails']?.toString() ?? 'Cash';

    controller.customInvoiceCtrl.text = gc['CustInvNo']?.toString() ?? '';
    controller.deliveryInstructionsCtrl.text = gc['DeliveryFromSpecial']?.toString() ?? '';
    controller.invValueCtrl.text = gc['InvValue']?.toString() ?? '';
    controller.ewayBillCtrl.text = gc['EInv']?.toString() ?? '';
    
    if (gc['EInvDate'] != null) {
      try {
        final ewayDate = DateTime.parse(gc['EInvDate'].toString());
        controller.ewayBillDate.value = ewayDate;
        controller.ewayBillDateCtrl.text = controller.formatDate(ewayDate);
      } catch (e) {}
    }
    
    controller.eDaysCtrl.text = gc['Eda']?.toString() ?? '';

    if (gc['EBillExpDate'] != null) {
      try {
        final ewayExpDate = DateTime.parse(gc['EBillExpDate'].toString());
        controller.ewayExpired.value = ewayExpDate;
        controller.ewayExpiredCtrl.text = controller.formatDate(ewayExpDate);
      } catch (e) {}
    }
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}