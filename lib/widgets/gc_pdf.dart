import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logistic/controller/gc_form_controller.dart';

class GCPdfGenerator {
  static Future<Uint8List> generatePDF(GCFormController controller) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    // Create three copies with different headers
    final copies = [
      {'title': 'CONSIGNOR COPY', 'color': PdfColors.blue900},
      {'title': 'CONSIGNEE COPY', 'color': PdfColors.green800},
      {'title': 'DRIVER COPY', 'color': PdfColors.red800},
    ];

    for (var copy in copies) {
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
                _buildFooter(font, boldFont, controller, copyTitle: copy['title'] as String),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      pw.Font font,
      pw.Font boldFont,
      GCFormController controller,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 45,
                    height: 45,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(width: 1.5),
                      color: PdfColors.blue900,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'श्री',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 18,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Sri Krishna Carrying Corporation',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 16,
                            color: PdfColors.red,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Head Office',
                              style: pw.TextStyle(font: font, fontSize: 8),
                            ),
                            pw.Container(
                              width: 8,
                              height: 8,
                              margin: const pw.EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(width: 0.5),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                'CHENNAI - 402, Paneer Nagar, 3rd Floor, Mogappair, Chennai - 600 037.',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                            ),
                          ],
                        ),
                        pw.Text(
                          'Phone : 044 - 45575675',
                          style: pw.TextStyle(font: font, fontSize: 8),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Branch Office :',
                              style: pw.TextStyle(font: font, fontSize: 8),
                            ),
                            pw.SizedBox(width: 5),
                            _buildCheckboxWithLabel('MUMBAI', font),
                            pw.SizedBox(width: 8),
                            _buildCheckboxWithLabel('BELLARY', font),
                            pw.SizedBox(width: 8),
                            _buildCheckboxWithLabel('BHARUCH', font),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          children: [
                            pw.Text(
                              "OWNER'S RISK",
                              style: pw.TextStyle(font: boldFont, fontSize: 8),
                            ),
                            pw.SizedBox(width: 10),
                            _buildCheckboxWithLabel('KRISHNAPATNAM', font),
                            pw.SizedBox(width: 8),
                            _buildCheckboxWithLabel('SRI KALAHASTI', font),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Column(
                children: [
                  pw.Text(
                    'Subject to Chennai Jurisdiction',
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'Consignment Note',
                    style: pw.TextStyle(font: font, fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Table(
                      border: pw.TableBorder(bottom: pw.BorderSide(width: 1)),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(3),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.all(2),
                              child: pw.Row(
                                children: [
                                  pw.Text(
                                    'Truck No : ',
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.Text(
                                    controller.truckNumberCtrl.text,
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(2),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    'GC No : ',
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.Text(
                                    '${controller.gcNumberCtrl.text}  / 25-26',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow(
                      'Date',
                      controller.gcDateCtrl.text,
                      font,
                    ),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('GSTIN', '33AAGPP5677A1ZS', font),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('PAN No', 'AAGPP5677A', font),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('SAC No ', '996511', font),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow(
                      'From',
                      controller.fromCtrl.text,
                      font,
                      isAddress: true,
                    ),

                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow(
                      'To',
                      controller.toCtrl.text,
                      font,
                      isAddress: true,
                    ),

                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow(
                      'ETA ',
                      controller.eDaysCtrl.text,
                      font,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMainContent(
      pw.Font font,
      pw.Font boldFont,
      GCFormController controller,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Table 1: Consignor, Consignee
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
          ),
          child: pw.Row(
            children: [
              // Consignor
              pw.Expanded(
                child: pw.Container(
                  height: 75,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(width: 1)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Consignor',
                        style: pw.TextStyle(font: boldFont, fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        controller.consignorNameCtrl.text,
                        style: pw.TextStyle(font: font, fontSize: 8),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Address',
                        style: pw.TextStyle(font: boldFont, fontSize: 8),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        controller.consignorAddressCtrl.text,
                        style: pw.TextStyle(font: font, fontSize: 7),
                        maxLines: 2,
                      ),
                      pw.Spacer(),
                      pw.Text(
                        'GSTIN. No  ${controller.consignorGstCtrl.text}',
                        style: pw.TextStyle(font: boldFont, fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ),
              // Consignee
              pw.Expanded(
                child: pw.Container(
                  height: 75,
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Consignee',
                        style: pw.TextStyle(font: boldFont, fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        controller.consigneeNameCtrl.text,
                        style: pw.TextStyle(font: font, fontSize: 8),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Address',
                        style: pw.TextStyle(font: boldFont, fontSize: 8),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        controller.consigneeAddressCtrl.text,
                        style: pw.TextStyle(font: font, fontSize: 7),
                        maxLines: 2,
                      ),
                      pw.Spacer(),
                      pw.Text(
                        'GSTIN. No  ${controller.consigneeGstCtrl.text}',
                        style: pw.TextStyle(font: boldFont, fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table 2: Package details and Invoice/E-way section side by side
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side: Package details
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(width: 1)),
                  ),
                  child: pw.Column(
                    children: [
                      // Headers
                      pw.Container(
                        height: 20,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1)),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 12,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(right: pw.BorderSide(width: 1)),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    'Number of packages',
                                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 12,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(right: pw.BorderSide(width: 1)),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    'Method of packages',
                                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 20,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Center(
                                  child: pw.Text(
                                    'Nature of goods said to Contain',
                                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Values
                      pw.Container(
                        height: 60,
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 12,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(right: pw.BorderSide(width: 1)),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    controller.packagesCtrl.text,
                                    style: pw.TextStyle(font: font, fontSize: 8),
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 12,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(right: pw.BorderSide(width: 1)),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    controller.methodPackageCtrl.text,
                                    style: pw.TextStyle(font: font, fontSize: 8),
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 20,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Center(
                                  child: pw.Text(
                                    controller.natureGoodsCtrl.text,
                                    style: pw.TextStyle(font: font, fontSize: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right side: Invoice and E-way section
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  children: [
                    // Invoice section
                    pw.Container(
                      height: 40,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1)),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Invoice No.:',
                                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    '1. ${controller.customInvoiceCtrl.text}',
                                    style: pw.TextStyle(font: font, fontSize: 6.5),
                                  ),
                                  pw.Text(
                                    '2.',
                                    style: pw.TextStyle(font: font, fontSize: 6.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Date',
                                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    controller.gcDateCtrl.text,
                                    style: pw.TextStyle(font: font, fontSize: 6.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // E-way section
                    pw.Container(
                      height: 40,
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'E-way Billing',
                                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    '1. ${controller.ewayBillCtrl.text}',
                                    style: pw.TextStyle(font: font, fontSize: 6.5),
                                  ),
                                  pw.Text(
                                    '2.',
                                    style: pw.TextStyle(font: font, fontSize: 6.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Exp. Date',
                                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    controller.ewayExpiredCtrl.text,
                                    style: pw.TextStyle(font: font, fontSize: 6.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Combined section: Left side (stacked tables) and Right side (certificate/freight)
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // LEFT SIDE: Stacked tables
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  children: [
                    // Row 1: Actual Weight and Private Marks
                    pw.Container(
                      height: 48,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(width: 1),
                          bottom: pw.BorderSide(width: 1),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          // Actual Weight
                          pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)),
                              ),
                              child: pw.Column(
                                children: [
                                  pw.Container(
                                    height: 22,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                                    ),
                                    child: pw.Center(
                                      child: pw.Text(
                                        'Actual Weight\nKgs.',
                                        style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Center(
                                      child: pw.Text(
                                        controller.actualWeightCtrl.text,
                                        style: pw.TextStyle(font: font, fontSize: 9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Private Marks
                          pw.Expanded(
                            flex: 1,
                            child: pw.Column(
                              children: [
                                pw.Container(
                                  height: 22,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border(bottom: pw.BorderSide(width: 1)),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text(
                                      'Private Marks',
                                      style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Center(
                                    child: pw.Text(
                                      'O / R',
                                      style: pw.TextStyle(font: font, fontSize: 9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Row 2: Charges for and Value of
                    pw.Container(
                      height: 33,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(width: 1),
                          bottom: pw.BorderSide(width: 1),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: [
                                  pw.Text('Charges for', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                                  pw.SizedBox(height: 2),
                                  pw.Container(
                                    width: double.infinity,
                                    child: pw.Text(
                                      'FTL',
                                      style: pw.TextStyle(font: font, fontSize: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: [
                                  pw.Text('Value of', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                                  pw.SizedBox(height: 2),
                                  pw.Container(
                                    width: double.infinity,
                                    child: pw.Text(
                                      controller.invValueCtrl.text,
                                      style: pw.TextStyle(font: font, fontSize: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Row 3: Delivery Instructions

                    // Row 3: Delivery Instructions
                    pw.Container(
                      height: 50,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(right: pw.BorderSide(width: 1)),
                      ),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Center( // Center the title
                            child: pw.Text(
                              'Delivery from & Special Instructions',
                              style: pw.TextStyle(font: boldFont, fontSize: 7.5),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            controller.deliveryInstructionsCtrl.text,
                            style: pw.TextStyle(font: font, fontSize: 7),
                            maxLines: 2, // Allowing up to 2 lines might be better for wrapping
                            overflow: pw.TextOverflow.clip,
                          ),
                          pw.Spacer(),
                          pw.Divider(height: 1), // Add a divider line
                          pw.SizedBox(height: 1),  // Add a small space after the divider
                          pw.Text(
                            'GSTIN to be paid by : Consignor / Consignee',
                            style: pw.TextStyle(font: font, fontSize: 7.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT SIDE: Certificate and Freight section
              pw.Expanded(
                flex: 9,
                child: pw.Column(
                  children: [
                    // Header row
                    pw.Container(
                      height: 22,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1)),
                      ),
                      child: pw.Row(
                        children: [
                          // Not responsible for leakage
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(2),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'Not responsible for leakage or Breakage',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8,
                                    color: PdfColors.red,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          // Freight to pay
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(2),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'FREIGHT TO PAY Rs.          P.',
                                  style: pw.TextStyle(font: boldFont, fontSize: 8),
                                ),
                              ),
                            ),
                          ),
                          // Payment section
                          pw.Expanded(
                            flex: 4,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text('Payment', style: pw.TextStyle(font: boldFont, fontSize: 7.5)),
                                  pw.Text('Frieght Receipt', style: pw.TextStyle(font: boldFont, fontSize: 7)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content row
                    pw.Container(
                      height: 110,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Certificate column
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(6),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '"Certified that the credit of Input Tax Charged on Goods and Services used in Supplying of GTA Services has not been Taken in view of Notification Issued under Goods & Service Tax"',
                                  style: pw.TextStyle(font: font, fontSize: 7),
                                  textAlign: pw.TextAlign.justify,
                                ),
                              ),
                            ),
                          ),
                          // Freight breakdown column
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(right: pw.BorderSide(width: 1)),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Frieght per Ton. C.M.', style: pw.TextStyle(font: font, fontSize: 8)),
                                      pw.Container(width: 35, height: 1, color: PdfColors.black),
                                    ],
                                  ),
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Surcharges (Goods/Tax)', style: pw.TextStyle(font: font, fontSize: 8)),
                                      pw.Container(width: 35, height: 1, color: PdfColors.black),
                                    ],
                                  ),
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Hamali', style: pw.TextStyle(font: font, fontSize: 8)),
                                      pw.Container(width: 35, height: 1, color: PdfColors.black),
                                    ],
                                  ),
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Risk Charges', style: pw.TextStyle(font: font, fontSize: 8)),
                                      pw.Container(width: 35, height: 1, color: PdfColors.black),
                                    ],
                                  ),
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('St. Charges', style: pw.TextStyle(font: font, fontSize: 8)),
                                      pw.Container(width: 35, height: 1, color: PdfColors.black),
                                    ],
                                  ),
                                  pw.Container(height: 1, width: double.infinity, color: PdfColors.black),
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('Total', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                                      pw.Container(width: 35, height: 1, color: PdfColors.black),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Receipt column
                          pw.Expanded(
                            flex: 4,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: [
                                  pw.Text('Receipt / Bill No.', style: pw.TextStyle(font: font, fontSize: 7.5)),
                                  pw.SizedBox(height: 6),
                                  pw.Container(width: double.infinity, height: 1, color: PdfColors.black),
                                  pw.SizedBox(height: 14),
                                  pw.Text('Date', style: pw.TextStyle(font: font, fontSize: 7.5)),
                                  pw.SizedBox(height: 6),
                                  pw.Container(width: double.infinity, height: 1, color: PdfColors.black),
                                  pw.SizedBox(height: 14),
                                  pw.Text('Amount', style: pw.TextStyle(font: font, fontSize: 7.5)),
                                  pw.SizedBox(height: 6),
                                  pw.Container(width: double.infinity, height: 1, color: PdfColors.black),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(
      pw.Font font,
      pw.Font boldFont,
      GCFormController controller, {
        required String copyTitle,
      }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          children: [
            pw.Container(width: 150, height: 0.5, child: pw.Divider()),
            pw.SizedBox(height: 2),
            pw.Text(
              'Signature of Consignor or his Agent',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ],
        ),
        pw.Text(
          copyTitle,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 12,
            color: PdfColors.red,
          ),
        ),
        pw.Column(
          children: [
            pw.Container(width: 150, height: 0.5, child: pw.Divider()),
            pw.SizedBox(height: 2),
            pw.Text(
              'Signature of Booking Officer',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFieldRow(
      String label,
      String value,
      pw.Font font, {
        double height = 15,
        bool isAddress = false,
        int maxLines = 1,
      }) {
    return pw.Container(
      height: isAddress ? 30 : height,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 50,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 4),
            child: pw.Text(
              ':',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: isAddress ? 7 : 8,
                lineSpacing: 1.1,
              ),
              maxLines: isAddress ? 2 : maxLines,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckboxWithLabel(String label, pw.Font font) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        ),
        pw.SizedBox(width: 2),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7)),
      ],
    );
  }

  static Future<void> showPdfPreview(
      BuildContext context,
      GCFormController controller,
      ) async {
    final pdfData = await generatePDF(controller);
    final gcNumber = controller.gcNumberCtrl.text.isNotEmpty
        ? controller.gcNumberCtrl.text
        : 'preview';
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PDFPreviewScreen(pdfData: pdfData, filename: 'GC_$gcNumber.pdf'),
        ),
      );
    }
  }

  static Future<String> savePdfToDevice(GCFormController controller) async {
    try {
      final pdfData = await generatePDF(controller);
      final directory = await getApplicationDocumentsDirectory();

      String gcNumber = controller.gcNumberCtrl.text.trim();
      if (gcNumber.isEmpty) {
        gcNumber = 'GC_${DateTime.now().millisecondsSinceEpoch}';
      } else if (!gcNumber.toUpperCase().startsWith('GC_')) {
        gcNumber = 'GC_$gcNumber';
      }

      if (!gcNumber.toLowerCase().endsWith('.pdf')) {
        gcNumber = '$gcNumber.pdf';
      }

      final file = File('${directory.path}/$gcNumber');
      await file.writeAsBytes(pdfData);
      print('PDF saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      rethrow;
    }
  }

  static Future<void> sharePdf(GCFormController controller) async {
    try {
      final pdfData = await generatePDF(controller);

      String gcNumber = controller.gcNumberCtrl.text.trim();
      if (gcNumber.isEmpty) {
        gcNumber = 'GC_${DateTime.now().millisecondsSinceEpoch}.pdf';
      } else {
        if (!gcNumber.toUpperCase().startsWith('GC_')) {
          gcNumber = 'GC_$gcNumber';
        }
        if (!gcNumber.toLowerCase().endsWith('.pdf')) {
          gcNumber = '$gcNumber.pdf';
        }
      }

      await Printing.sharePdf(
        bytes: pdfData,
        filename: gcNumber,
      );
    } catch (e) {
      print('Error sharing PDF: $e');
      rethrow;
    }
  }

  static Future<void> printPdf(GCFormController controller) async {
    try {
      final pdfData = await generatePDF(controller);

      String docName = 'GC_${controller.gcNumberCtrl.text.trim()}.pdf';
      if (docName == 'GC_.pdf') {
        docName = 'GC_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: docName,
      );
    } catch (e) {
      print('Error printing PDF: $e');
      rethrow;
    }
  }
}

class PDFPreviewScreen extends StatelessWidget {
  final Uint8List pdfData;
  final String filename;

  const PDFPreviewScreen({
    Key? key,
    required this.pdfData,
    required this.filename,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gcNumber = GCFormController().gcNumberCtrl.text.trim();

    String displayName = 'document.pdf';
    if (filename.isNotEmpty) {
      displayName = filename.split('/').last;
    } else if (gcNumber.isNotEmpty) {
      displayName = 'GC_$gcNumber';
      if (!displayName.toLowerCase().endsWith('.pdf')) {
        displayName = '$displayName.pdf';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Preview - $displayName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfData,
                filename: displayName,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async => await Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async => pdfData,
              name: displayName,
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfData,
        onShared: (context) {
          Printing.sharePdf(
            bytes: pdfData,
            filename: displayName,
          );
        },
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: displayName,
      ),
    );
  }
}