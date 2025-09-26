import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logistic/controller/gc_form_controller.dart';

class GCPdfGenerator {
  // --- CORE PDF GENERATION LOGIC ---
  static Future<Uint8List> generatePDF(GCFormController controller) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(font, boldFont, controller),
              pw.SizedBox(height: 5),
              _buildMainContent(font, boldFont, controller),
              pw.Spacer(),
              _buildFooter(font, boldFont, controller),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // --- HEADER SECTION ---
  static pw.Widget _buildHeader(pw.Font font, pw.Font boldFont, GCFormController controller) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Left Section - Company Info
            pw.Expanded(
              flex: 3,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo/Icon
                  pw.Container(
                    width: 45,
                    height: 45,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(width: 1.5),
                    ),
                    child: pw.Center(
                      child: pw.Text('श्री', 
                        style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.blue900)),
                    ),
                  ),
                  
                  // Company Details
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Company Name
                        pw.Text('Sri Krishna Carrying Corporation', 
                          style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.red)),
                        
                        // Address
                        pw.SizedBox(height: 2),
                        pw.Row(children: [
                          pw.Text('Head Office', style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.Container(
                            width: 8, height: 8, 
                            margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                          ),
                          pw.Expanded(
                            child: pw.Text('CHENNAI - 402, Paneer Nagar, \n3rd Floor, Mogappair, Chennai - 600 037.', 
                              style: pw.TextStyle(font: font, fontSize: 8)),
                          ),
                        ]),
                        
                        // Phone
                        pw.Text('Phone : 044 - 45575675', 
                          style: pw.TextStyle(font: font, fontSize: 8)),
                        
                        // Branch Offices
                        pw.SizedBox(height: 3),
                        pw.Row(children: [
                          pw.Text('Branch Office :', 
                            style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.SizedBox(width: 5),
                          _buildCheckboxWithLabel('MUMBAI', font),
                          pw.SizedBox(width: 8),
                          _buildCheckboxWithLabel('BELLARY', font),
                          pw.SizedBox(width: 8),
                          _buildCheckboxWithLabel('BHARUCH', font),
                        ]),
                        
                        // Owner Risk
                        pw.SizedBox(height: 2),
                        pw.Row(children: [
                          pw.Text("OWNER'S RISK", 
                            style: pw.TextStyle(font: boldFont, fontSize: 8)),
                          pw.SizedBox(width: 10),
                          _buildCheckboxWithLabel('KRISHNAPATNAM', font),
                          pw.SizedBox(width: 8),
                          _buildCheckboxWithLabel('SRI KALAHASTI', font),
                        ]),
                      ],
                    ),
                  ),
                ]
              ),
            ),
            
            // Middle Section - Document Title
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Subject to Chennai Jurisdiction', 
                    style: pw.TextStyle(font: font, fontSize: 8), 
                    textAlign: pw.TextAlign.center
                  ),
                  pw.Text('Consignment Note', 
                    style: pw.TextStyle(font: font, fontSize: 8), 
                    textAlign: pw.TextAlign.center
                  ),
                ]
              ),
            ),
            
            // Right Section - Document Details
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Truck Number
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Truck No.', 
                            style: pw.TextStyle(font: font, fontSize: 8)),
                          pw.Row(children: [
                            pw.Text('No : ', 
                              style: pw.TextStyle(font: font, fontSize: 8)),
                            pw.Text(controller.gcNumberCtrl.text, 
                              style: pw.TextStyle(font: boldFont, fontSize: 9)),
                          ]),
                        ],
                      ),
                    ),
                    
                    // Document Details
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('Date : ', controller.gcDateCtrl.text, font, height: 12),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('GSTIN : ', '33AAGPP5677A1ZS', font),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('From : ', controller.fromCtrl.text, font, height: 12),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('PAN No : ', 'AAGPP5677A', font),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('To : ', controller.toCtrl.text, font, height: 12),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('SAC No.:', '996511', font),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('ETA : ', controller.eDaysCtrl.text, font, height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- MAIN CONTENT SECTION ---
  static pw.Widget _buildMainContent(pw.Font font, pw.Font boldFont, GCFormController controller) {
    return pw.Column(
      children: [
        // Main grid table
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.0), // Label column for Consignor
            1: pw.FlexColumnWidth(3.0), // Value column for Consignor
            2: pw.FlexColumnWidth(2.0), // Label column for Consignee
            3: pw.FlexColumnWidth(3.0), // Value column for Consignee
            4: pw.FlexColumnWidth(2.5), // Additional column
          },
          children: [
            // Row 1: Consignor/Consignee
            pw.TableRow(children: [
              _buildAddressLabelCell('Consignor', boldFont, font),
              _buildAddressValueCell(
                controller.consignorNameCtrl.text, 
                controller.consignorAddressCtrl.text, 
                controller.consignorGstCtrl.text, 
                font
              ),
              _buildAddressLabelCell('Consignee', boldFont, font),
              _buildAddressValueCell(
                controller.consigneeNameCtrl.text, 
                controller.consigneeAddressCtrl.text, 
                controller.consigneeGstCtrl.text, 
                font
              ),
              _buildCellWithChildren([
                pw.Text('Invoice No.:', 
                  style: pw.TextStyle(font: boldFont, fontSize: 9)),
                pw.Text('1. ${controller.customInvoiceCtrl.text}', 
                  style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Text('2. ', style: pw.TextStyle(font: font, fontSize: 9)),
                pw.SizedBox(height: 5),
                pw.Text('Date:', 
                  style: pw.TextStyle(font: boldFont, fontSize: 9)),
                pw.Text('1. ${controller.gcDateCtrl.text}', 
                  style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Text('2. ', style: pw.TextStyle(font: font, fontSize: 9)),
              ]),
            ]),
            
            // Row 2: Headers
            pw.TableRow(children: [
              _buildCell('Number of\npackages', boldFont),
              _buildCell('Method of\npackages', boldFont),
              _buildCell('Nature of goods said to Contain', boldFont),
              _buildCell('Actual Weight\nKgs.', boldFont),
              _buildCell('Private Marks', boldFont),
            ]),
            
            // Row 3: Data
            pw.TableRow(children: [
              _buildCell(controller.packagesCtrl.text, font, align: pw.TextAlign.center),
              _buildCell(controller.methodPackageCtrl.text, font, align: pw.TextAlign.center),
              _buildCell(controller.natureGoodsCtrl.text, font, align: pw.TextAlign.center),
              _buildCell(controller.actualWeightCtrl.text, font, align: pw.TextAlign.center),
              _buildCell('O / R', font, align: pw.TextAlign.center),
            ]),
            
            // Row 4: E-way Bill and other info
            pw.TableRow(children: [
              _buildCell('Charges for\nFTL', boldFont),
              _buildCell('Value of\n${controller.invValueCtrl.text}', font, 
                align: pw.TextAlign.center),
              _buildCellWithChildren([
                pw.Text('E-way Billing:', 
                  style: pw.TextStyle(font: boldFont, fontSize: 8)),
                pw.Text('1. ${controller.ewayBillCtrl.text}', 
                  style: pw.TextStyle(font: font, fontSize: 8)),
                pw.Text('2. ', style: pw.TextStyle(font: font, fontSize: 8)),
                pw.SizedBox(height: 3),
                pw.Text('Exp. Date:', 
                  style: pw.TextStyle(font: boldFont, fontSize: 8)),
                pw.Text('1. ${controller.ewayExpiredCtrl.text}', 
                  style: pw.TextStyle(font: font, fontSize: 8)),
                pw.Text('2. ', style: pw.TextStyle(font: font, fontSize: 8)),
              ]),
              pw.Container(),
              pw.Container(),
            ]),
          ],
        ),
        
        // Charges Table
        _buildChargesTable(font, boldFont, controller),
      ],
    );
  }

  // --- CHARGES TABLE ---
  static pw.Widget _buildChargesTable(pw.Font font, pw.Font boldFont, GCFormController controller) {
    return pw.Table(
      border: pw.TableBorder.all(width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5), // Delivery instructions
        1: pw.FlexColumnWidth(2.5), // "Not responsible" box
        2: pw.FlexColumnWidth(2.0), // Charges list
        3: pw.FlexColumnWidth(2.0), // FREIGHT TO PAY
        4: pw.FlexColumnWidth(2.5), // Payment section
      },
      children: [
        pw.TableRow(
          children: [
            // Delivery Instructions
            pw.Container(
              height: 80,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                'Delivery from & Special Instructions\n\n${controller.deliveryInstructionsCtrl.text}', 
                style: pw.TextStyle(font: boldFont, fontSize: 9)
              ),
            ),
            
            // Not Responsible Box
            pw.Container(
              height: 80,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5, color: PdfColors.red)
                    ),
                    child: pw.Text(
                      'Not responsible for leakage or Breakage', 
                      style: pw.TextStyle(
                        font: boldFont, 
                        fontSize: 8, 
                        color: PdfColors.red
                      ), 
                      textAlign: pw.TextAlign.center
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '"Certified that the credit of Input Tax Charged on Goods and Services used in Supplying of GTA Services has not been Taken in view of Notification Issued under Goods & Service Tax"',
                    style: pw.TextStyle(font: font, fontSize: 7), 
                    textAlign: pw.TextAlign.justify
                  ),
                ],
              ),
            ),
            
            // Charges List
            pw.Container(
              height: 80,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Frieght per Ton. C.M.', 
                    style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text('Surcharges (Goods/Tax)', 
                    style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text('Hamali', 
                    style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text('Risk Charges', 
                    style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text('St. Charges', 
                    style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text('Total', 
                    style: pw.TextStyle(font: boldFont, fontSize: 9)),
                ],
              ),
            ),
            
            // Freight to Pay
            pw.Container(
              height: 80,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FREIGHT TO PAY', 
                    style: pw.TextStyle(font: boldFont, fontSize: 8)),
                  pw.Text('Rs.             P.', 
                    style: pw.TextStyle(font: boldFont, fontSize: 8)),
                ],
              ),
            ),
            
            // Payment Section
            pw.Container(
              height: 80,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment', 
                        style: pw.TextStyle(font: boldFont, fontSize: 8)),
                      pw.Text('Frieght Receipt', 
                        style: pw.TextStyle(font: boldFont, fontSize: 8)),
                    ]
                  ),
                  pw.Text('Receipt / Bill No.', 
                    style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text('Date', 
                    style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text('Amount', 
                    style: pw.TextStyle(font: font, fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FOOTER SECTION ---
  static pw.Widget _buildFooter(pw.Font font, pw.Font boldFont, GCFormController controller) {
    return pw.Column(
      children: [
        pw.Row(children: [
          pw.Text('GSTIN to be paid by : Consignor / Consignee', 
            style: pw.TextStyle(font: font, fontSize: 8))
        ]),
        pw.SizedBox(height: 25),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Consignor Signature
            pw.Column(children: [
              pw.Container(width: 150, height: 0.5, child: pw.Divider()),
              pw.SizedBox(height: 2),
              pw.Text('Signature of Consignor or his Agent', 
                style: pw.TextStyle(font: font, fontSize: 8)),
            ]),
            
            // Document Type
            pw.Text('Consignee Copy', 
              style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.red)),
            
            // Booking Officer Signature
            pw.Column(children: [
              pw.Container(width: 150, height: 0.5, child: pw.Divider()),
              pw.SizedBox(height: 2),
              pw.Text('Signature of Booking Officer', 
                style: pw.TextStyle(font: font, fontSize: 8)),
            ]),
          ],
        ),
      ],
    );
  }

  // ===== HELPER WIDGETS =====
  
  // Address Label Cell
  static pw.Widget _buildAddressLabelCell(String title, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: 80,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Text('$title:', 
            style: pw.TextStyle(font: boldFont, fontSize: 9)),
          pw.Text('Address:', 
            style: pw.TextStyle(font: font, fontSize: 8)),
          pw.Text('GSTIN. No:', 
            style: pw.TextStyle(font: font, fontSize: 8)),
        ]
      )
    );
  }

  // Address Value Cell
  static pw.Widget _buildAddressValueCell(String name, String address, String gstin, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: 80,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          pw.Text(name, 
            style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Text(address, 
            style: pw.TextStyle(font: font, fontSize: 8)),
          pw.Text(gstin, 
            style: pw.TextStyle(font: font, fontSize: 8)),
        ]
      )
    );
  }

  // General Purpose Cell
  static pw.Widget _buildCell(String text, pw.Font font, 
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3), 
      child: pw.Text(
        text, 
        style: pw.TextStyle(font: font, fontSize: 8), 
        textAlign: align
      )
    );
  }

  // Cell with specific height
  static pw.Widget _buildCellWithHeight(String text, pw.Font font, double height, 
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      height: height,
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text, 
        style: pw.TextStyle(font: font, fontSize: 8), 
        textAlign: align
      )
    );
  }

  // Cell with multiple children
  static pw.Widget _buildCellWithChildren(List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3), 
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, 
        children: children
      )
    );
  }

  // Empty cell with specific height
  static pw.Widget _buildEmptyCell(double height) {
    return pw.Container(height: height);
  }

  // Checkbox with label
  static pw.Widget _buildCheckboxWithLabel(String label, pw.Font font) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8, 
          height: 8, 
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5))
        ),
        pw.SizedBox(width: 2),
        pw.Text(
          label, 
          style: pw.TextStyle(font: font, fontSize: 7)
        )
      ]
    );
  }

  // Field row with label and value
  static pw.Widget _buildFieldRow(String label, String value, pw.Font font, 
      {double height = 15}) {
    return pw.Container(
      height: height, 
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1), 
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start, 
        children: [
          pw.Text(
            label, 
            style: pw.TextStyle(font: font, fontSize: 8)
          ),
          pw.SizedBox(width: 2),
          pw.Text(
            value, 
            style: pw.TextStyle(font: font, fontSize: 8)
          )
        ]
      )
    );
  }

  // ===== ACTION METHODS =====
  
  // Show PDF Preview
  static Future<void> showPdfPreview(
      BuildContext context, GCFormController controller) async {
    final pdfData = await generatePDF(controller);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PDFPreviewScreen(pdfData: pdfData),
      ),
    );
  }

  // Save PDF to Device
  static Future<void> savePdfToDevice(GCFormController controller) async {
    final pdfData = await generatePDF(controller);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/gc_note.pdf');
    await file.writeAsBytes(pdfData);
    
    // TODO: Implement file saving logic
    // This is platform-specific and would require platform channels
    // or a package like share_plus for saving files
  }

  // Share PDF
  static Future<void> sharePdf(GCFormController controller) async {
    final pdfData = await generatePDF(controller);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/gc_note.pdf');
    await file.writeAsBytes(pdfData);
    
    // TODO: Implement share functionality
    // This would typically use the share_plus package
  }

  // Print PDF
  static Future<void> printPdf(GCFormController controller) async {
    final pdfData = await generatePDF(controller);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
    );
  }
}

// PDF Preview Screen
class PDFPreviewScreen extends StatelessWidget {
  final Uint8List pdfData;

  const PDFPreviewScreen({super.key, required this.pdfData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GC Note Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async => pdfData,
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfData,
      ),
    );
  }
}
