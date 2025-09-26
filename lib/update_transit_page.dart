import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:async';
import 'dart:convert';
import 'api_config.dart'; // Assuming ApiConfig file with baseUrl

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

  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController reportRemarksController = TextEditingController();
  DateTime? unloadedDate;
  TimeOfDay? unloadedTime;
  final TextEditingController unloadedRemarksController = TextEditingController();
  DateTime? receiptDate;
  TimeOfDay? receiptTime;
  final TextEditingController receiptRemarksController = TextEditingController();

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

  // Theme constants
  static const Color primaryColor = Color(0xFF1E2A44);
  static const Color secondaryColor = Color(0xFF2E3A59);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

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
          selectedGcNumber = null;
          gcDetails = null;
        });
      } else {
        _showErrorSnackbar('Failed to fetch GC numbers: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching GC numbers: $e');
    } finally {
      setState(() {
        isLoadingGc = false;
      });
    }
  }

  Future<void> fetchGcDetails(String gcNumber) async {
    setState(() {
      gcDetails = null;
      lastEditableTransitIndex = 7;
      _clearAllFields();
    });

    try {
      print('Fetching GC details for: $gcNumber');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/gc/search?GcNumber=$gcNumber'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is List && responseData.isNotEmpty) {
          final gcData = responseData.firstWhere(
                (item) => item is Map<String, dynamic> &&
                item['GcNumber']?.toString() == gcNumber,
            orElse: () => responseData[0],
          );

          if (gcData is Map<String, dynamic>) {
            setState(() {
              gcDetails = gcData;
              _processGcDetails();
            });
            return;
          }
        }

        if (responseData is List && responseData.isNotEmpty && responseData[0]['Id'] != null) {
          final gcId = responseData[0]['Id'];
          final detailResponse = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/gc/search/$gcId'),
          );

          if (detailResponse.statusCode == 200) {
            final detailData = jsonDecode(detailResponse.body);
            if (detailData is List && detailData.isNotEmpty) {
              final specificGcData = detailData.firstWhere(
                    (item) => item is Map<String, dynamic> &&
                    item['GcNumber']?.toString() == gcNumber,
                orElse: () => detailData[0],
              );

              setState(() {
                gcDetails = specificGcData;
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
      setState(() {
        gcDetails = null;
      });
      _showErrorSnackbar('Failed to fetch GC details: ${e.toString()}');
    }
  }

  void _clearAllFields() {
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
  }

  void _processGcDetails() {
    if (gcDetails == null) return;

    isGcDetailsExpanded = true;

    try {
      // Parse transit dates and places
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

      // Parse other dates and fields
      if (gcDetails!.containsKey('UnloadedDate') &&
          gcDetails!['UnloadedDate'] != null) {
        unloadedDate = DateTime.tryParse(gcDetails!['UnloadedDate'].toString());
      }

      if (gcDetails!.containsKey('NewReceiptDate') &&
          gcDetails!['NewReceiptDate'] != null) {
        receiptDate = DateTime.tryParse(gcDetails!['NewReceiptDate'].toString());
      }

      reportRemarksController.text = gcDetails!['ReportRemarks']?.toString() ?? '';
      unloadedRemarksController.text = gcDetails!['UnloadedRemark']?.toString() ?? '';
      receiptRemarksController.text = gcDetails!['ReceiptRemarks']?.toString() ?? '';

      final now = DateTime.now();
      isUnloadedDateEditable = unloadedDate == null || unloadedDate!.isAfter(now);
      isReceiptDateEditable = receiptDate == null || receiptDate!.isAfter(now);

    } catch (e) {
      print('Error processing GC details: $e');
      _showErrorSnackbar('Error processing GC details: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: errorColor,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: successColor,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  String formatDateIndian(DateTime? date) {
    if (date == null) return 'Select Date';
    return DateFormat('dd-MM-yyyy').format(date);
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

  Future<void> pickDate(int index, BuildContext context) async {
    if (index > lastEditableTransitIndex) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: transitDates[index] ?? transitDates[0] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        receiptTime = picked;
      });
    }
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
      _showErrorSnackbar('Please select a valid GC number');
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
            : '',
        'Day2': transitDates[1] != null ? formatDate(transitDates[1]) : null,
        'Day2Place': placeControllers[1].text.isNotEmpty
            ? placeControllers[1].text
            : '',
        'Day3': transitDates[2] != null ? formatDate(transitDates[2]) : null,
        'Day3Place': placeControllers[2].text.isNotEmpty
            ? placeControllers[2].text
            : '',
        'Day4': transitDates[3] != null ? formatDate(transitDates[3]) : null,
        'Day4Place': placeControllers[3].text.isNotEmpty
            ? placeControllers[3].text
            : '',
        'Day5': transitDates[4] != null ? formatDate(transitDates[4]) : null,
        'Day5Place': placeControllers[4].text.isNotEmpty
            ? placeControllers[4].text
            : '',
        'Day6': transitDates[5] != null ? formatDate(transitDates[5]) : null,
        'Day6Place': placeControllers[5].text.isNotEmpty
            ? placeControllers[5].text
            : '',
        'Day7': transitDates[6] != null ? formatDate(transitDates[6]) : null,
        'Day7Place': placeControllers[6].text.isNotEmpty
            ? placeControllers[6].text
            : '',
        'Day8': transitDates[7] != null ? formatDate(transitDates[7]) : null,
        'Day8Place': placeControllers[7].text.isNotEmpty
            ? placeControllers[7].text
            : '',
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
        'Success': '1',
      };

      payload.removeWhere((key, value) => value == null);

      final url = '${ApiConfig.baseUrl}/gc/update/${gcDetails!['Id']}/${gcDetails!['GcNumber']}';
      print('Sending PUT request to: $url');

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

      if (response.statusCode == 200) {
        await fetchGcDetails(selectedGcNumber!);
        _showSuccessSnackbar('Transit details updated successfully');
      } else {
        throw Exception('Failed to update: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating transit details: $e');
      _showErrorSnackbar('Failed to update transit details: ${e.toString()}');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<String?> _showSearchPicker({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String current,
  }) async {
    List<String> filtered = List<String>.from(items);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select $title',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: primaryColor),
                          onPressed: () {
                            searchCtrl.clear();
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          hintText: 'Search GC Numbers...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onChanged: (q) {
                          setState(() {
                            final query = q.trim().toLowerCase();
                            filtered = items
                                .where((e) => e.toLowerCase().contains(query))
                                .toList();
                          });
                        },
                      ),
                    ),
                  ),
                  // List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No GC numbers found',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final val = filtered[index];
                        final selected = val == current;
                        return Container(
                          decoration: BoxDecoration(
                            color: selected ? primaryColor.withOpacity(0.1) : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              val,
                              style: TextStyle(
                                color: selected ? primaryColor : Colors.black87,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(Icons.check_circle, color: primaryColor)
                                : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              searchCtrl.clear();
                              Navigator.of(ctx).pop(val);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchCtrl.dispose();
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Update Transit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Download PDF',
              onPressed: downloadPDF,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GC Selection Card
              _buildSectionCard(
                title: 'GC Selection',
                icon: Icons.search,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildGcSelector(),
                    if (isLoadingGc) ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: primaryColor),
                            SizedBox(height: 16),
                            Text('Loading GC details...', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // GC Details Card
              if (gcDetails != null) ...[
                _buildGcDetailsCard(),
                const SizedBox(height: 20),
              ],

              // Transit Details Card
              _buildSectionCard(
                title: 'Transit Journey',
                icon: Icons.route,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTransitDays(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Remarks Section
              _buildSectionCard(
                title: 'Report Remarks',
                icon: Icons.note_alt,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildRemarksField(
                      controller: reportRemarksController,
                      hintText: 'Enter report remarks...',
                      enabled: isReportRemarksEditable,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Unloaded Details Card
              _buildSectionCard(
                title: 'Unloaded Details',
                icon: Icons.local_shipping,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildUnloadedDetails(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Receipt Details Card
              _buildSectionCard(
                title: 'Receipt Details',
                icon: Icons.receipt_long,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildReceiptDetails(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildGcSelector() {
    return InkWell(
      onTap: gcNumbers.isEmpty ? null : () async {
        final selected = await _showSearchPicker(
          context: context,
          title: 'GC Number',
          items: gcNumbers,
          current: selectedGcNumber ?? '',
        );
        if (selected != null) {
          setState(() {
            selectedGcNumber = selected;
            isGcDetailsExpanded = true;
            gcDetails = null;
          });
          fetchGcDetails(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: backgroundColor,
        ),
        child: Row(
          children: [
            Icon(
              Icons.description,
              color: primaryColor.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GC Number',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (selectedGcNumber?.isEmpty ?? true) ? 'Tap to select GC Number' : selectedGcNumber!,
                    style: TextStyle(
                      fontSize: 16,
                      color: (selectedGcNumber?.isEmpty ?? true) ? Colors.grey[500] : primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: primaryColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGcDetailsCard() {
    return Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isGcDetailsExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              isGcDetailsExpanded = expanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline, color: accentColor, size: 20),
          ),
          title: const Text(
            'GC Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          subtitle: Text(
            'GC Number: ${gcDetails!['GcNumber'] ?? 'N/A'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildDetailGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailGrid() {
    final details = [
      {'label': 'Truck Number', 'value': gcDetails!['TruckNumber']},
      {'label': 'Driver Name', 'value': gcDetails!['DriverNameShow']},
      {'label': 'Branch', 'value': gcDetails!['Branch']},
      {'label': 'Broker Name', 'value': gcDetails!['BrokerNameShow']},
      {'label': 'Challan Number', 'value': gcDetails!['LcNo']},
      {'label': 'Consignor Name', 'value': gcDetails!['ConsignorName']},
      {'label': 'Consignor GST', 'value': gcDetails!['ConsignorGst']},
      {'label': 'Consignee Name', 'value': gcDetails!['ConsigneeName']},
      {'label': 'Consignee GST', 'value': gcDetails!['ConsigneeGst']},
      {'label': 'From', 'value': gcDetails!['TruckFrom']},
      {'label': 'To', 'value': gcDetails!['TruckTo']},
      {'label': 'Delivery Address', 'value': gcDetails!['DeliveryAddress']},
      {'label': 'Bill Number', 'value': gcDetails!['CustInvNo']},
      {'label': 'Payment Details', 'value': gcDetails!['PaymentDetails']},
      {'label': 'Hire Amount', 'value': gcDetails!['HireAmount']},
      {'label': 'Advance Amount', 'value': gcDetails!['AdvanceAmount']},
    ];

    return Column(
      children: details.map((detail) => _buildDetailRow(detail['label']!, detail['value'])).toList(),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryColor,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
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

  Widget _buildTransitDays() {
    // Disable editing if receipt date is present
    final isReceiptPresent = receiptDate != null;
    
    return Column(
      children: List.generate(8, (i) {
        final isEditable = i <= lastEditableTransitIndex && !isReceiptPresent;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEditable ? cardColor : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEditable ? primaryColor.withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isEditable ? primaryColor : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Day ${i + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEditable ? primaryColor : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateSelector(
                    date: transitDates[i],
                    onTap: isEditable ? () => pickDate(i, context) : null,
                    enabled: isEditable,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPlaceField(i, isEditable),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateSelector({
    required DateTime? date,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 120,  // Minimum width to fit the date
        maxWidth: 140,  // Maximum width to prevent taking too much space
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48, // Fixed height to match other form fields
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: enabled ? backgroundColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? primaryColor.withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: enabled ? primaryColor : Colors.grey.shade500,
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  formatDateIndian(date),
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled ? Colors.black87 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceField(int index, bool enabled) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? primaryColor.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: TextFormField(
        controller: placeControllers[index],
        enabled: enabled,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey.shade600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Place',
          labelStyle: TextStyle(
            color: enabled ? primaryColor.withOpacity(0.7) : Colors.grey.shade500,
            fontSize: 12,
          ),
          isDense: true, // Reduces the height of the input field
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 4.0, left: 8.0), // Reduced padding around icon
            child: Icon(
              Icons.place,
              color: enabled ? primaryColor.withOpacity(0.7) : Colors.grey.shade500,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 20, maxHeight: 20), // Tighter constraints for icon
          border: InputBorder.none,
          filled: true,
          fillColor: enabled ? backgroundColor : Colors.grey.shade100,
        ),
        onChanged: (value) {
          setState(() {
            if (value.trim() == gcDetails?['TruckTo']?.trim()) {
              lastEditableTransitIndex = index;
              for (int j = index + 1; j < 8; j++) {
                transitDates[j] = null;
                placeControllers[j].clear();
              }
            } else if (lastEditableTransitIndex == index &&
                value.trim() != gcDetails?['TruckTo']?.trim()) {
              lastEditableTransitIndex = 7;
            }
          });
        },
      ),
    );
  }

  Widget _buildRemarksField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? primaryColor.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        readOnly: !enabled,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey.shade600,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          filled: true,
          fillColor: enabled ? backgroundColor : Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildUnloadedDetails() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(
                date: unloadedDate,
                onTap: isUnloadedDateEditable ? () => pickUnloadedDate(context) : null,
                enabled: isUnloadedDateEditable,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeSelector(
                time: unloadedTime,
                onTap: isUnloadedTimeEditable ? () => pickUnloadedTime(context) : null,
                enabled: isUnloadedTimeEditable,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRemarksField(
          controller: unloadedRemarksController,
          hintText: 'Enter unloaded remarks...',
          enabled: isUnloadedRemarksEditable,
        ),
      ],
    );
  }

  Widget _buildReceiptDetails() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(
                date: receiptDate,
                onTap: isReceiptDateEditable ? () => pickReceiptDate(context) : null,
                enabled: isReceiptDateEditable,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeSelector(
                time: receiptTime,
                onTap: isReceiptTimeEditable ? () => pickReceiptTime(context) : null,
                enabled: isReceiptTimeEditable,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRemarksField(
          controller: receiptRemarksController,
          hintText: 'Enter receipt remarks...',
          enabled: isReceiptRemarksEditable,
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required TimeOfDay? time,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? backgroundColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? primaryColor.withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: enabled ? primaryColor : Colors.grey.shade500,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatTime(time),
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.black87 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSaving
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isSaving ? null : saveTransit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isSaving
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Saving...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 20),
            SizedBox(width: 8),
            Text(
              'Save Transit Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}