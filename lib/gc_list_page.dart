import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class GCListPage extends StatefulWidget {
  const GCListPage({Key? key}) : super(key: key);

  @override
  State<GCListPage> createState() => _GCListPageState();
}

class _GCListPageState extends State<GCListPage> {
  List<Map<String, dynamic>> gcList = [];
  bool isLoading = true;
  String? error;

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
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          gcList = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GC List'),
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          : ListView.builder(
              itemCount: gcList.length,
              itemBuilder: (context, index) {
                final gc = gcList[index];
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
                    title: Text(
                      gc['GcNumber'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  Widget? _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
