import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'dart:async';
import 'dart:convert';
import 'api_config.dart'; // Assuming ApiConfig file with baseUrl
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:logistic/widgets/searchable_dropdown.dart';

class UpdateTransitPage extends StatefulWidget {
  const UpdateTransitPage({Key? key}) : super(key: key);

  @override
  State<UpdateTransitPage> createState() => _UpdateTransitPageState();
}

class _UpdateTransitPageState extends State<UpdateTransitPage> {
  List<String> gcNumbers = [];
  String? selectedGcNumber;
  Map<String, dynamic>? gcDetails;
  bool isGcDetailsExpanded = true;

  final List<DateTime?> transitDates = List.filled(8, null);
  final List<TextEditingController> placeControllers = List.generate(
    8,
    (_) => TextEditingController(),
  );

  final TextEditingController reportRemarksController = TextEditingController();
  DateTime? unloadedDate;
  TimeOfDay? unloadedTime;
  final TextEditingController unloadedRemarksController =
      TextEditingController();
  DateTime? receiptDate;
  TimeOfDay? receiptTime;
  final TextEditingController receiptRemarksController =
      TextEditingController();

  bool isSaving = false;
  bool isLoadingGc = false;
  int lastEditableTransitIndex = 7;
  bool isReportRemarksEditable = true;
  bool isUnloadedDateEditable = true;
  bool isUnloadedTimeEditable = true;
  bool isUnloadedRemarksEditable = true;
  bool isReceiptDateEditable = true;
  bool isReceiptTimeEditable = true;
  bool isReceiptRemarksEditable = true;

  @override
  void initState() {
    super.initState();
    fetchGcNumbers();
  }

  Future<void> fetchGcNumbers() async {
    setState(() {
      isLoadingGc = true;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/gc/gcList/search'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          gcNumbers = data
              .map((item) => item['GcNumber']?.toString() ?? '')
              .where((gc) => gc.isNotEmpty)
              .toList();
          if (gcNumbers.isNotEmpty) {
            selectedGcNumber = gcNumbers[0];
            fetchGcDetails(selectedGcNumber!);
          }
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to fetch GC numbers: ${response.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error fetching GC numbers: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isLoadingGc = false;
      });
    }
  }

  Future<void> fetchGcDetails(String gcNumber) async {
    setState(() {
      isLoadingGc = true;
      gcDetails = null;
      lastEditableTransitIndex = 7;
      for (var ctrl in placeControllers) {
        ctrl.clear();
      }
      transitDates.fillRange(0, 8, null);
      reportRemarksController.clear();
      unloadedRemarksController.clear();
      receiptRemarksController.clear();
      unloadedDate = null;
      unloadedTime = null;
      receiptDate = null;
      receiptTime = null;
    });

    try {
      print('Fetching GC details for: $gcNumber');
      
      // First, try to get the GC details directly by GC number
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/gc/search?GcNumber=$gcNumber'),
      );

      if (response.statusCode == 200) {
        print('GC search response: ${response.body}');
        
        final responseData = jsonDecode(response.body);
        
        if (responseData is List && responseData.isNotEmpty) {
          // If we got a list, take the first item
          final gcData = responseData[0];
          
          if (gcData is Map<String, dynamic>) {
            setState(() {
              gcDetails = gcData;
              _processGcDetails();
            });
            return;
          }
        } 
        
        // If direct search didn't work, try getting by ID
        if (responseData is List && responseData.isNotEmpty && responseData[0]['Id'] != null) {
          final gcId = responseData[0]['Id'];
          print('Fetching GC details by ID: $gcId');
          
          final detailResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/gc/search/$gcId'),
          );
          
          if (detailResponse.statusCode == 200) {
            print('GC details response: ${detailResponse.body}');
            final detailData = jsonDecode(detailResponse.body);
            
            if (detailData is List && detailData.isNotEmpty) {
              setState(() {
                gcDetails = detailData[0];
                _processGcDetails();
              });
              return;
            }
          }
        }
        
        throw Exception('Invalid GC data format received');
      } else {
        throw Exception('Failed to fetch GC details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchGcDetails: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch GC details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoadingGc = false);
    }
  }
  
  void _processGcDetails() {
    if (gcDetails == null) return;
    
    isGcDetailsExpanded = true;
    
    try {
      // Parse transit dates
      for (int i = 1; i <= 8; i++) {
        final dayKey = 'Day$i';
        final placeKey = 'Day${i}Place';
        
        if (gcDetails!.containsKey(dayKey) && gcDetails![dayKey] != null) {
          try {
            transitDates[i-1] = DateTime.tryParse(gcDetails![dayKey].toString());
          } catch (e) {
            print('Error parsing date for $dayKey: ${gcDetails![dayKey]}');
          }
        }
        
        if (gcDetails!.containsKey(placeKey)) {
          placeControllers[i-1].text = gcDetails![placeKey]?.toString() ?? '';
          
          // Check if this is the destination
          if (placeControllers[i-1].text.trim().isNotEmpty &&
              gcDetails!.containsKey('TruckTo') &&
              placeControllers[i-1].text.trim().toLowerCase() == 
              gcDetails!['TruckTo']?.toString().trim().toLowerCase()) {
            lastEditableTransitIndex = i-1;
          }
        }
      }

      // Set first location to TruckFrom if empty
      if (placeControllers[0].text.isEmpty && 
          gcDetails!.containsKey('TruckFrom') &&
          gcDetails!['TruckFrom'] != null) {
        placeControllers[0].text = gcDetails!['TruckFrom'].toString();
      }

      // Parse other dates
      if (gcDetails!.containsKey('UnloadedDate') && 
          gcDetails!['UnloadedDate'] != null) {
        unloadedDate = DateTime.tryParse(gcDetails!['UnloadedDate'].toString());
      }
      
      if (gcDetails!.containsKey('NewReceiptDate') && 
          gcDetails!['NewReceiptDate'] != null) {
        receiptDate = DateTime.tryParse(gcDetails!['NewReceiptDate'].toString());
      }
      
      // Parse remarks
      reportRemarksController.text = gcDetails!['ReportRemarks']?.toString() ?? '';
      unloadedRemarksController.text = gcDetails!['UnloadedRemark']?.toString() ?? '';
      receiptRemarksController.text = gcDetails!['ReceiptRemarks']?.toString() ?? '';
      
      // Disable fields if dates are in the past
      final now = DateTime.now();
      isUnloadedDateEditable = unloadedDate == null || unloadedDate!.isAfter(now);
      isReceiptDateEditable = receiptDate == null || receiptDate!.isAfter(now);
      
    } catch (e) {
      print('Error processing GC details: $e');
      Get.snackbar(
        'Error',
        'Error processing GC details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String formatDateIndian(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Future<void> pickDate(int index, BuildContext context) async {
    if (index > lastEditableTransitIndex) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: transitDates[index] ?? transitDates[0] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        transitDates[index] = picked;
        for (int i = index + 1; i <= lastEditableTransitIndex; i++) {
          transitDates[i] = picked.add(Duration(days: i - index));
        }
      });
    }
  }

  Future<void> pickUnloadedDate(BuildContext context) async {
    if (!isUnloadedDateEditable) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: unloadedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        unloadedDate = picked;
      });
    }
  }

  Future<void> pickUnloadedTime(BuildContext context) async {
    if (!isUnloadedTimeEditable) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: unloadedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        unloadedTime = picked;
      });
    }
  }

  Future<void> pickReceiptDate(BuildContext context) async {
    if (!isReceiptDateEditable) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: receiptDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        receiptDate = picked;
      });
    }
  }

  Future<void> pickReceiptTime(BuildContext context) async {
    if (!isReceiptTimeEditable) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: receiptTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        receiptTime = picked;
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm:ss').format(dt);
  }

  void downloadPDF() async {
    final pdf = pw.Document();

    // Sample data (replace with actual input variables)
    final String companyName = 'iMatrix Technologies Pvt Ltd';
    final String companyAddress =
        'iMatrix Technologies Pvt Ltd #R-76 M M D A Colony, Arumbakkam, Chennai - 600 106';
    final String gcNumberText = '411308';
    final String fromText = 'Palakkad';
    final String toText = 'KGF';
    final String consigneeText = 'TATA ADVANCED KOLAR KGF';
    final String consigneeAddressText = 'KGF';
    final String consignorText = 'Beml Ltd Palakkad';
    final String consignorAddress = 'Palakkad';
    final String branchCodeText = 'PKD';
    final String gcDateText = '03-03-2025';
    final String truckNumberText = 'KA 01 AQ 0209';
    final String numberOfPackageText = '9';
    final String methodOfText = 'nos';
    final int weightInt = 5;
    final String privateMarkText = 'O/R FTL';
    final String chargedText = 'O/R FTL';
    final String specialInstructionText = '';
    final String natureGoodText = 'WHEEL ASSY';
    final String natureGoodText2 = '';
    final String natureGoodText3 = '';
    final String natureGoodText4 = '';
    final String receiptNumberText = 'INV00010';
    final String receiptDateText = '2025-04-04';
    final String freightText = '15461.25';
    final List<String> footerLabels = ['CONSIGNOR COPY', 'TRANSPORT COPY'];

    // Function to create a page with specified footer label
    pw.Widget buildPage(String footerLabel) {
      return pw.Container(
        margin: const pw.EdgeInsets.all(37), // Margin as per Kotlin (37 units)
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 2.2), // Border width as per Kotlin
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Table
            pw.Table(
              columnWidths: {
                // 0: pw.FlexColumnWidth(2),
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(2),
              },
              border: pw.TableBorder.all(width: 0), // No border
              children: [
                pw.TableRow(
                  children: [
                    // pw.Container(), // Empty cell for left side
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            companyName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            companyAddress,
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            'Received goods as detailed below for the transportation subject to condition printed overleaf',
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 1),
                      child: pw.Table(
                        columnWidths: {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(1),
                        },
                        border: pw.TableBorder.all(width: 0), // No border
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Center(
                                child: pw.Text(
                                  'No :',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Center(
                                child: pw.Text(
                                  ' $gcNumberText',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Center(
                                child: pw.Text(
                                  'Date :',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Center(
                                child: pw.Text(
                                  fromText,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Center(
                                child: pw.Text(
                                  'To :',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Center(
                                child: pw.Text(
                                  toText,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10), // Spacing between sections
            // Consignor and Consignee Table
            pw.Table(
              columnWidths: {
                0: pw.FlexColumnWidth(50),
                1: pw.FlexColumnWidth(50),
              },
              border: pw.TableBorder.all(width: 0), // No border except bottom
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      height: 40,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1)),
                      ),
                      padding: const pw.EdgeInsets.only(
                        left: 15,
                        top: 5,
                        bottom: 5,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Consignor: $consignorText',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'Address: $consignorAddress',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      height: 40,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1)),
                      ),
                      padding: const pw.EdgeInsets.only(
                        left: 15,
                        top: 5,
                        bottom: 5,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Consignee: $consigneeText',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'Address: $consigneeAddressText',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10), // Spacing between sections
            // Booking and Lorry Details Table
            pw.Padding(
              padding: const pw.EdgeInsets.only(
                left: 90,
                right: 100,
                bottom: 10,
              ),
              child: pw.Table(
                columnWidths: {
                  0: pw.FlexColumnWidth(25),
                  1: pw.FlexColumnWidth(25),
                  2: pw.FlexColumnWidth(25),
                  3: pw.FlexColumnWidth(25),
                },
                border: pw.TableBorder(
                  bottom: pw.BorderSide(width: 0.5),
                ), // Thin bottom border for separation
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Booking Office: $branchCodeText',
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Lorry No: $truckNumberText',
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'OWNER\'S RISK',
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Date: $gcDateText',
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10), // Spacing between sections
            // Package Details Table
            pw.Table(
              columnWidths: {
                0: pw.FixedColumnWidth(99),
                1: pw.FixedColumnWidth(102),
                2: pw.FixedColumnWidth(250),
                3: pw.FixedColumnWidth(102),
                4: pw.FixedColumnWidth(102),
                5: pw.FixedColumnWidth(102),
              },
              border: pw.TableBorder.all(width: 0), // No border
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      height: 30,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'No of PKG',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 30,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Method of PKG',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 30,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Nature of goods said to contain',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 30,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Actual Weight Kgs',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 30,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Private',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 30,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Charged for',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Container(
                      height: 80,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        numberOfPackageText,
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 80,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        methodOfText,
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 80,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '$natureGoodText\n$natureGoodText2\n$natureGoodText3\n$natureGoodText4',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 80,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '$weightInt',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 80,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        privateMarkText,
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 80,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        chargedText,
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10), // Spacing between sections
            // Disclaimer Table
            pw.Table(
              columnWidths: {
                0: pw.FixedColumnWidth(95),
                1: pw.FixedColumnWidth(58),
                2: pw.FixedColumnWidth(74),
                3: pw.FixedColumnWidth(123),
              },
              border: pw.TableBorder.all(width: 0), // No border
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      height: 20,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Not Responsible for Leakage or Breakage',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      height: 20,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'FREIGHT PAID / DUE',
                        style: pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 20,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'FREIGHT TO PAY',
                        style: pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      height: 20,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Payment Freight Receipt',
                        style: pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // pw.SizedBox(height: 10), // Spacing between sections

            // Main Charges Table
            pw.Table(
              columnWidths: {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(0.2),
                4: pw.FlexColumnWidth(1.2),
                5: pw.FlexColumnWidth(0.2),
                6: pw.FlexColumnWidth(3),
              },
              border: pw.TableBorder.all(width: 0),
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      height: 40,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Delivery from & Special Instruction\n$specialInstructionText',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Freight per Qtl./C.M.',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Table(
                        columnWidths: {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(1),
                        },
                        border: pw.TableBorder.all(width: 0),
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Container(
                                height: 25,
                                child: pw.Text(
                                  'Receipt/ Bill No:',
                                  style: pw.TextStyle(fontSize: 8),
                                ),
                              ),
                              pw.Container(
                                height: 25,
                                child: pw.Text(
                                  receiptNumberText,
                                  style: pw.TextStyle(fontSize: 8),
                                ),
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Container(
                                height: 25,
                                child: pw.Text(
                                  'Date:',
                                  style: pw.TextStyle(fontSize: 8),
                                ),
                              ),
                              pw.Container(
                                height: 25,
                                child: pw.Text(
                                  receiptDateText,
                                  style: pw.TextStyle(fontSize: 8),
                                ),
                              ),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Container(
                                height: 25,
                                child: pw.Text(
                                  'Amount:',
                                  style: pw.TextStyle(fontSize: 8),
                                ),
                              ),
                              pw.Container(
                                height: 25,
                                child: pw.Text(
                                  freightText,
                                  style: pw.TextStyle(fontSize: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Container(),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Surcharges(Goods/Tax)',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Container(),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Hamali',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Container(),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Rish Charges',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Container(
                      height: 40,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'GST Tax to be paid By: Consignor:',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'St. Charges',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Container(),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Total',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Container(),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10), // Spacing between sections
            // Spacer Table
            pw.Table(
              columnWidths: {0: pw.FlexColumnWidth(100)},
              border: pw.TableBorder.all(width: 0),
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      height: footerLabel == 'CONSIGNOR COPY' ? 76 : 55,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('', style: pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
              ],
            ),

            // Signature Table
            pw.Table(
              columnWidths: {
                0: pw.FlexColumnWidth(33),
                1: pw.FlexColumnWidth(33),
                2: pw.FlexColumnWidth(33),
              },
              border: pw.TableBorder.all(width: 0), // No border
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Signature of Consignor or his Agent:',
                        style: pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        footerLabel,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        'Signature of Booking Officer:',
                        style: pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Add both pages (CONSIGNOR COPY and TRANSPORT COPY)
    for (var label in footerLabels) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape, // Rotated A4 as per Kotlin
          margin: pw.EdgeInsets.zero,
          build: (context) => buildPage(label),
        ),
      );
    }

    // Render the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> saveTransit() async {
    if (selectedGcNumber == null ||
        gcDetails == null ||
        gcDetails!['Id'] == null) {
      Get.snackbar(
        'Error',
        'Please select a valid GC number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final payload = {
        'Day1': transitDates[0] != null ? formatDate(transitDates[0]) : null,
        'Day1Place': placeControllers[0].text.isNotEmpty
            ? placeControllers[0].text
            : null,
        'Day2': transitDates[1] != null ? formatDate(transitDates[1]) : null,
        'Day2Place': placeControllers[1].text.isNotEmpty
            ? placeControllers[1].text
            : null,
        'Day3': transitDates[2] != null ? formatDate(transitDates[2]) : null,
        'Day3Place': placeControllers[2].text.isNotEmpty
            ? placeControllers[2].text
            : null,
        'Day4': transitDates[3] != null ? formatDate(transitDates[3]) : null,
        'Day4Place': placeControllers[3].text.isNotEmpty
            ? placeControllers[3].text
            : null,
        'Day5': transitDates[4] != null ? formatDate(transitDates[4]) : null,
        'Day5Place': placeControllers[4].text.isNotEmpty
            ? placeControllers[4].text
            : null,
        'Day6': transitDates[5] != null ? formatDate(transitDates[5]) : null,
        'Day6Place': placeControllers[5].text.isNotEmpty
            ? placeControllers[5].text
            : null,
        'Day7': transitDates[6] != null ? formatDate(transitDates[6]) : null,
        'Day7Place': placeControllers[6].text.isNotEmpty
            ? placeControllers[6].text
            : null,
        'Day8': transitDates[7] != null ? formatDate(transitDates[7]) : null,
        'Day8Place': placeControllers[7].text.isNotEmpty
            ? placeControllers[7].text
            : null,
        'ReceiptRemarks': receiptRemarksController.text.isNotEmpty
            ? receiptRemarksController.text
            : null,
        'ReportRemarks': reportRemarksController.text.isNotEmpty
            ? reportRemarksController.text
            : null,
        'ReportDate': reportRemarksController.text.isNotEmpty
            ? formatDate(DateTime.now())
            : null,
        'UnloadedDate': unloadedDate != null ? formatDate(unloadedDate) : null,
        'NewReceiptDate': receiptDate != null ? formatDate(receiptDate) : null,
        'UnloadedRemark': unloadedRemarksController.text.isNotEmpty
              ? unloadedRemarksController.text
            : null,
      };

      // Add Success field to payload
      payload['Success'] = '1';
      
      // Log the request for debugging
      print('Sending update request to backend:');
      print('URL: ${ApiConfig.baseUrl}/gc/update/${gcDetails!['Id']}/${gcDetails!['GcNumber']}');
      print('Body: $payload');

      // Validate payload
      if (gcDetails!['Id'] == null || gcDetails!['GcNumber'] == null) {
        throw Exception('Invalid GC details: Missing ID or GC Number');
      }

      // Remove null values from payload
      payload.removeWhere((key, value) => value == null);

      final url = '${ApiConfig.baseUrl}/gc/update/${gcDetails!['Id']}/${gcDetails!['GcNumber']}';
      print('Sending PUT request to: $url');
      print('Payload: $payload');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Refresh the GC details after successful update
        await fetchGcDetails(selectedGcNumber!);
        
        Get.snackbar(
          'Success',
          'Transit details updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      } else {
        throw Exception('Failed to update transit details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating transit details: $e');
      Get.snackbar(
        'Error',
        'Failed to update transit details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    for (final ctrl in placeControllers) {
      ctrl.dispose();
    }
    reportRemarksController.dispose();
    unloadedRemarksController.dispose();
    receiptRemarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Transit'),
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF',
            onPressed: downloadPDF,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select GC Number',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E2A44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SearchableDropdown<String>(
                    label: 'GC Number',
                    value: selectedGcNumber,
                    items: gcNumbers
                        .map<DropdownMenuItem<String>>(
                          (gc) => DropdownMenuItem(
                            value: gc,
                            child: Text(gc),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedGcNumber = val;
                          isGcDetailsExpanded = true;
                        });
                        fetchGcDetails(val);
                      }
                    },
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),
                  if (isLoadingGc)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E2A44),
                      ),
                    )
                  else if (gcDetails != null) ...[
                    ExpansionTile(
                      title: Text(
                        'GC Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF1E2A44),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      initiallyExpanded: isGcDetailsExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          isGcDetailsExpanded = expanded;
                        });
                      },
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      childrenPadding: const EdgeInsets.all(12),
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.white,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Truck Number',
                                gcDetails!['TruckNumber'],
                              ),
                              _buildDetailRow(
                                'Driver Name',
                                gcDetails!['DriverNameShow'],
                              ),
                              _buildDetailRow(
                                'Palakkad Booking',
                                gcDetails!['Branch'],
                              ),
                              _buildDetailRow(
                                'Broker Name',
                                gcDetails!['BrokerNameShow'],
                              ),
                              _buildDetailRow(
                                'Challan Number',
                                gcDetails!['LcNo'],
                              ),
                              _buildDetailRow(
                                'Consignor Name',
                                gcDetails!['ConsignorName'],
                              ),
                              _buildDetailRow(
                                'Consignor GST',
                                gcDetails!['ConsignorGst'],
                              ),
                              _buildDetailRow(
                                'Consignee Name',
                                gcDetails!['ConsigneeName'],
                              ),
                              _buildDetailRow(
                                'Consignee GST',
                                gcDetails!['ConsigneeGst'],
                              ),
                              _buildDetailRow('From', gcDetails!['TruckFrom']),
                              _buildDetailRow('To', gcDetails!['TruckTo']),
                              _buildDetailRow(
                                'Delivery Address',
                                gcDetails!['DeliveryAddress'],
                              ),
                              _buildDetailRow(
                                'Bill Number',
                                gcDetails!['CustInvNo'],
                              ),
                              _buildDetailRow(
                                'Payment Details',
                                gcDetails!['PaymentDetails'],
                              ),
                              _buildDetailRow(
                                'Hire Amount',
                                gcDetails!['HireAmount'],
                              ),
                              _buildDetailRow(
                                'Advance Amount',
                                gcDetails!['AdvanceAmount'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Transit Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E2A44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 8,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Builder(
                        builder: (BuildContext innerContext) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Day ${i + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E2A44),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: GestureDetector(
                                      onTap: i <= lastEditableTransitIndex
                                          ? () => pickDate(i, innerContext)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: i <= lastEditableTransitIndex
                                                ? const Color(0xFF1E2A44)
                                                : Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: i <= lastEditableTransitIndex
                                              ? Colors.white
                                              : Colors.grey.shade200,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              color: Color(0xFF1E2A44),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                formatDateIndian(
                                                  transitDates[i],
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      i <=
                                                          lastEditableTransitIndex
                                                      ? Colors.black
                                                      : Colors.grey.shade600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: placeControllers[i],
                                      enabled: i <= lastEditableTransitIndex,
                                      decoration: InputDecoration(
                                        labelText: 'Place',
                                        prefixIcon: const Icon(
                                          Icons.place,
                                          color: Color(0xFF1E2A44),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1E2A44),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1E2A44),
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: i <= lastEditableTransitIndex
                                            ? Colors.white
                                            : Colors.grey.shade200,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.trim() ==
                                              gcDetails?['TruckTo']?.trim()) {
                                            lastEditableTransitIndex = i;
                                            for (int j = i + 1; j < 8; j++) {
                                              transitDates[j] = null;
                                              placeControllers[j].clear();
                                            }
                                          } else if (lastEditableTransitIndex ==
                                                  i &&
                                              value.trim() !=
                                                  gcDetails?['TruckTo']
                                                      ?.trim()) {
                                            lastEditableTransitIndex = 7;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Report Remarks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E2A44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reportRemarksController,
                    maxLines: 3,
                    readOnly: !isReportRemarksEditable,
                    decoration: InputDecoration(
                      hintText: 'Enter remarks...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E2A44)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E2A44)),
                      ),
                      filled: true,
                      fillColor: isReportRemarksEditable
                          ? Colors.white
                          : Colors.grey.shade200,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Unloaded Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E2A44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (BuildContext innerContext) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: isUnloadedDateEditable
                                      ? () => pickUnloadedDate(innerContext)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isUnloadedDateEditable
                                            ? const Color(0xFF1E2A44)
                                            : Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isUnloadedDateEditable
                                          ? Colors.white
                                          : Colors.grey.shade200,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF1E2A44),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            formatDateIndian(unloadedDate),
                                            style: TextStyle(
                                              color: isUnloadedDateEditable
                                                  ? Colors.black
                                                  : Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: isUnloadedTimeEditable
                                      ? () => pickUnloadedTime(innerContext)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isUnloadedTimeEditable
                                            ? const Color(0xFF1E2A44)
                                            : Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isUnloadedTimeEditable
                                          ? Colors.white
                                          : Colors.grey.shade200,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Color(0xFF1E2A44),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            formatTime(unloadedTime),
                                            style: TextStyle(
                                              color: isUnloadedTimeEditable
                                                  ? Colors.black
                                                  : Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: unloadedRemarksController,
                            maxLines: 3,
                            readOnly: !isUnloadedRemarksEditable,
                            decoration: InputDecoration(
                              hintText: 'Unloaded remarks...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1E2A44),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1E2A44),
                                ),
                              ),
                              filled: true,
                              fillColor: isUnloadedRemarksEditable
                                  ? Colors.white
                                  : Colors.grey.shade200,
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Receipt Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1E2A44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (BuildContext innerContext) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: isReceiptDateEditable
                                      ? () => pickReceiptDate(innerContext)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isReceiptDateEditable
                                            ? const Color(0xFF1E2A44)
                                            : Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isReceiptDateEditable
                                          ? Colors.white
                                          : Colors.grey.shade200,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF1E2A44),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            formatDateIndian(receiptDate),
                                            style: TextStyle(
                                              color: isReceiptDateEditable
                                                  ? Colors.black
                                                  : Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: isReceiptTimeEditable
                                      ? () => pickReceiptTime(innerContext)
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isReceiptTimeEditable
                                            ? const Color(0xFF1E2A44)
                                            : Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: isReceiptTimeEditable
                                          ? Colors.white
                                          : Colors.grey.shade200,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Color(0xFF1E2A44),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            formatTime(receiptTime),
                                            style: TextStyle(
                                              color: isReceiptTimeEditable
                                                  ? Colors.black
                                                  : Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: receiptRemarksController,
                            maxLines: 3,
                            readOnly: !isReceiptRemarksEditable,
                            decoration: InputDecoration(
                              hintText: 'Receipt remarks...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1E2A44),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1E2A44),
                                ),
                              ),
                              filled: true,
                              fillColor: isReceiptRemarksEditable
                                  ? Colors.white
                                  : Colors.grey.shade200,
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveTransit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E2A44),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2A44),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
