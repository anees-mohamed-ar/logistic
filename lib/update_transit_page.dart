import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'dart:convert';
import 'api_config.dart'; // Assuming ApiConfig file with baseUrl
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/gc/search/gcnum?gcNumber=$gcNumber'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          setState(() {
            gcDetails = data[0] as Map<String, dynamic>;
            isGcDetailsExpanded = true;

            if (gcDetails!.containsKey('Day1')) {
              final dateStr = gcDetails!['Day1'];
              if (dateStr != null) {
                final date = DateTime.tryParse(dateStr);
                transitDates[0] = date;
                for (int i = 1; i < 8; i++) {
                  transitDates[i] = date != null
                      ? date.add(Duration(days: i))
                      : null;
                }
              }
            }

            for (int i = 0; i < 8; i++) {
              final placeKey = 'Day${i + 1}Place';
              if (gcDetails!.containsKey(placeKey)) {
                placeControllers[i].text = gcDetails![placeKey] ?? '';
                if (placeControllers[i].text.trim() ==
                    gcDetails!['TruckTo']?.trim()) {
                  lastEditableTransitIndex = i;
                }
              }
            }

            if (placeControllers[0].text.isEmpty &&
                gcDetails!['TruckFrom'] != null) {
              placeControllers[0].text = gcDetails!['TruckFrom'];
            }
          });
        }
      }
    } finally {
      setState(() => isLoadingGc = false);
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
    final String companyName = 'GLOBE TRANSPORT CORPORATION';
    final String companyAddress =
        'NO 40, 4th Floor, Lakshmi Complex K.R.Road, Fort, Bangalore- 560002';
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
        'ReceiptTime': receiptTime != null ? formatTime(receiptTime) : null,
        'UnloadedTime': unloadedTime != null ? formatTime(unloadedTime) : null,
        'ReportTime': reportRemarksController.text.isNotEmpty
            ? formatTime(TimeOfDay.now())
            : null,
        'Success': true,
      };

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/gc/update/${gcDetails!['Id']}/$selectedGcNumber',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Transit details saved successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to save transit details: ${response.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error saving transit details: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
                  DropdownButtonFormField<String>(
                    value: selectedGcNumber,
                    hint: const Text('Select GC Number'),
                    items: gcNumbers
                        .map(
                          (gc) => DropdownMenuItem(value: gc, child: Text(gc)),
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E2A44)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E2A44)),
                      ),
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
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
