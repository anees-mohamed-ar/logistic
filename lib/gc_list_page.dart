import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:logistic/gc_form_screen.dart';
import 'api_config.dart';

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
                label: const Text('Clear search'),
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
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _navigateToEditGc(gc),
                      tooltip: 'Edit GC',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                        // Add more fields as needed
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

  void _navigateToEditGc(Map<String, dynamic> gcData) {
    // Convert the GC data to match the form's expected format
    final formData = {
      'gcNumber': gcData['GcNumber'],
      'gcDate': gcData['GcDate'],
      'branch': gcData['Branch'],
      'truckNumber': gcData['TruckNumber'],
      'poNumber': gcData['PoNumber'],
      'tripId': gcData['TripId'],
      'brokerName': gcData['BrokerName'],
      'driverName': gcData['DriverName'],
      'driverPhone': gcData['DriverPhoneNumber'],
      'consignorName': gcData['ConsignorName'],
      'consignorGst': gcData['ConsignorGst'],
      'consignorAddress': gcData['ConsignorAddress'],
      'consigneeName': gcData['ConsigneeName'],
      'consigneeGst': gcData['ConsigneeGst'],
      'consigneeAddress': gcData['ConsigneeAddress'],
      'numberOfPackages': gcData['NumberofPkg'],
      'packageMethod': gcData['MethodofPkg'],
      'actualWeight': gcData['ActualWeightKgs'],
      'rate': gcData['Rate'],
      'distance': gcData['km'],
      'hireAmount': gcData['HireAmount'],
      'advanceAmount': gcData['AdvanceAmount'],
      'deliveryAddress': gcData['DeliveryAddress'],
      'freightCharge': gcData['FreightCharge'],
      'paymentMethod': gcData['PaymentDetails'],
      // Add other fields as needed
    };

    Get.to(() => const GCFormScreen(), arguments: {'gcData': formData, 'isEditMode': true});
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