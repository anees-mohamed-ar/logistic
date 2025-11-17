import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/api_config.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/id_controller.dart';

class GCPdfGenerator {
  static Future<Uint8List> generatePDF(GCFormController controller) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    // Load logo image
    final logoData = await rootBundle.load('logo.jpg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Fetch branches dynamically
    final branches = await _fetchBranches();
    final selectedBranch = controller.selectedBranch.value;

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
                // Title at the top
                pw.Center(
                  child: pw.Text(
                    'Consignment Note',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                _buildHeader(
                  font,
                  boldFont,
                  controller,
                  logoImage,
                  branches,
                  selectedBranch,
                ),
                pw.SizedBox(height: 5),
                _buildMainContent(font, boldFont, controller),
                pw.Spacer(),
                _buildFooter(
                  font,
                  boldFont,
                  controller,
                  copyTitle: copy['title'] as String,
                ),
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
    pw.ImageProvider logoImage,
    List<Map<String, dynamic>> branches,
    String selectedBranch,
  ) {
    // Extract branch code from the selected branch
    String branchCode = '';
    if (selectedBranch.isNotEmpty && branches.isNotEmpty) {
      final selectedBranchData = branches.firstWhere(
        (branch) => branch['branch_name']?.toString() == selectedBranch,
        orElse: () => {},
      );
      branchCode = selectedBranchData['branch_code']?.toString() ?? '';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // LEFT SECTION: Logo and Company Info
            pw.Expanded(
              flex: 3,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 45,
                    height: 45,
                    // decoration: pw.BoxDecoration(
                    //   shape: pw.BoxShape.circle,
                    //   border: pw.Border.all(width: 1.5),
                    // ),
                    child: pw.ClipOval(
                      child: pw.Image(
                        logoImage,
                        fit: pw.BoxFit.cover,
                        width: 45,
                        height: 45,
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
                              'Head Office : ',
                              style: pw.TextStyle(font: font, fontSize: 9),
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
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                        pw.Text(
                          'Phone          : 044 - 45575675',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.SizedBox(height: 3),
                        _buildDynamicBranches(branches, selectedBranch, font),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(width: 10),

            // CENTER SECTION: Empty space (Jurisdiction moved to footer)
            pw.Container(width: 70),

            pw.SizedBox(width: 10),

            // RIGHT SECTION: The bordered table
            pw.Container(
              width: 280,
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
              child: pw.Column(
                children: [
                  // Row 1: GC No (left) | Date (right)
                  pw.Container(
                    height: 18,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide(width: 1)),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Text(
                                  'GC No.',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8.5,
                                  ),
                                ),
                                pw.SizedBox(width: 4),
                                pw.Text(
                                  ': ',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8.5,
                                  ),
                                ),
                                pw.Text(
                                  controller.gcNumberCtrl.text,
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8,
                                  ),
                                ),
                                pw.Text(
                                  ' / ',
                                  style: pw.TextStyle(font: font, fontSize: 8),
                                ),
                                pw.Text(
                                  '25-26',
                                  style: pw.TextStyle(font: font, fontSize: 8),
                                ),
                                if (branchCode.isNotEmpty) ...[
                                  pw.Text(
                                    ' / ',
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.Text(
                                    branchCode,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        pw.Container(
                          width: 130,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: pw.Row(
                            children: [
                              pw.Text(
                                'Date   :   ',
                                style: pw.TextStyle(font: font, fontSize: 8.5),
                              ),
                              pw.Text(
                                controller.gcDateCtrl.text,
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
                  ),

                  // Row 2: GSTIN (left) | From (right)
                  pw.Container(
                    height: 36,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide(width: 1)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'GSTIN :',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8.5,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  '33AAGPP5677A1ZS',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.Container(
                          width: 130,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                'From',
                                style: pw.TextStyle(font: font, fontSize: 8.5),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                controller.fromCtrl.text,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Row 3: PAN No (left) | To (right)
                  pw.Container(
                    height: 30,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide(width: 1)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'PAN No.: ',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8.5,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'AAGPP5677A',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.Container(
                          width: 130,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                'To',
                                style: pw.TextStyle(font: font, fontSize: 8.5),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                controller.toCtrl.text,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Row 4: SAC No (left) | ETA (right)
                  pw.Container(
                    height: 44,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              border: pw.Border(right: pw.BorderSide(width: 1)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'SAC No.: ',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 8.5,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  '996511',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.Container(
                          width: 130,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                'ETA',
                                style: pw.TextStyle(font: font, fontSize: 8.5),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Days : ${controller.eDaysCtrl.text}',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8.5,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Date : ${controller.deliveryDateCtrl.text.isNotEmpty ? controller.deliveryDateCtrl.text : '-'}',
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 8.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Row 5: Truck No (full width, label and value in one line)
                  pw.Container(
                    height: 18,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Truck No. : ',
                          style: pw.TextStyle(font: font, fontSize: 8.5),
                        ),
                        pw.Text(
                          controller.truckNumberCtrl.text,
                          style: pw.TextStyle(font: boldFont, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
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
        pw.Text(
          "OWNER'S RISK",
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
            color: PdfColors.red,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Received goods as detailed below for transportation subject to condition overleaf',
          style: pw.TextStyle(font: font, fontSize: 9),
        ),
        pw.SizedBox(height: 5),

        // Table 1: Consignor, Bill To, Consignee (3 columns)
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Row(
            children: [
              // Consignor
              pw.Expanded(
                child: pw.Container(
                  height: 77,
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: pw.BorderSide(width: 1)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            ..._buildPayerSelection('Consignor', boldFont),
                            pw.TextSpan(
                              text: ' :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.consignorNameCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 9),
                              // style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'Address :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.consignorAddressCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.Spacer(),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'GSTIN NO :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.consignorGstCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bill To
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
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'Bill To :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.billToNameCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'Address :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.billToAddressCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.Spacer(),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'GSTIN NO :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.billToGstCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
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
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            ..._buildPayerSelection('Consignee', boldFont),
                            pw.TextSpan(
                              text: ' :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.consigneeNameCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 10),
                              // style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'Address :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.consigneeAddressCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      pw.Spacer(),
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: 'GSTIN NO :  ',
                              style: pw.TextStyle(font: boldFont, fontSize: 10),
                            ),
                            pw.TextSpan(
                              text: controller.consigneeGstCtrl.text,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ],
                        ),
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
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
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
                        height: 15,
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
                                  border: pw.Border(
                                    right: pw.BorderSide(width: 1),
                                  ),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    'Number of packages',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
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
                                  border: pw.Border(
                                    right: pw.BorderSide(width: 1),
                                  ),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    'Method of packages',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
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
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
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
                        height: 36,
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 12,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(
                                    right: pw.BorderSide(width: 1),
                                  ),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    controller.packagesCtrl.text,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 12,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(
                                    right: pw.BorderSide(width: 1),
                                  ),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    controller.methodPackageCtrl.text,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
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
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 8,
                                    ),
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
                flex: 3,
                child: pw.Column(
                  children: [
                    // Invoice section
                    pw.Container(
                      height: 26,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1)),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(width: 1),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Invoice No.:',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    controller.customInvoiceCtrl.text,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 6.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Date',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    controller.gcDateCtrl.text,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 6.5,
                                    ),
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
                      height: 26,
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 2,
                              ),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(width: 1),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'E-way Billing',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    controller.ewayBillCtrl.text,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 6.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 2,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Exp Date',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    controller.ewayExpiredCtrl.text,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 6.5,
                                    ),
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
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
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
                                border: pw.Border(
                                  right: pw.BorderSide(width: 1),
                                ),
                              ),
                              child: pw.Column(
                                children: [
                                  pw.Container(
                                    height: 22,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border(
                                        bottom: pw.BorderSide(width: 1),
                                      ),
                                    ),
                                    child: pw.Center(
                                      child: pw.Text(
                                        'Actual Weight Kgs.',
                                        style: pw.TextStyle(
                                          font: boldFont,
                                          fontSize: 7.5,
                                        ),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Center(
                                      child: pw.Text(
                                        controller.actualWeightCtrl.text,
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 9,
                                        ),
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
                                    border: pw.Border(
                                      bottom: pw.BorderSide(width: 1),
                                    ),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text(
                                      'Private Marks',
                                      style: pw.TextStyle(
                                        font: boldFont,
                                        fontSize: 7.5,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Center(
                                    child: pw.Text(
                                      'O / R',
                                      style: pw.TextStyle(
                                        font: font,
                                        fontSize: 9,
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
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 3,
                              ),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(width: 1),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Charges for',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Container(
                                    width: double.infinity,
                                    child: pw.Text(
                                      'FTL',
                                      style: pw.TextStyle(
                                        font: font,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 3,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Value of',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 8,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Container(
                                    width: double.infinity,
                                    child: pw.Text(
                                      controller.invValueCtrl.text,
                                      style: pw.TextStyle(
                                        font: font,
                                        fontSize: 8,
                                      ),
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
                    pw.Container(
                      height: 50,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(right: pw.BorderSide(width: 1)),
                      ),
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Center(
                            child: pw.Text(
                              'Delivery from & Special Instructions',
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 7.5,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            controller.deliveryInstructionsCtrl.text,
                            style: pw.TextStyle(font: font, fontSize: 7),
                            maxLines: 2,
                            overflow: pw.TextOverflow.clip,
                          ),
                          pw.Spacer(),
                          pw.Divider(height: 1),
                          pw.SizedBox(height: 1),
                          pw.RichText(
                            text: pw.TextSpan(
                              style: pw.TextStyle(font: font, fontSize: 9.5),
                              children: [
                                pw.TextSpan(text: 'GSTIN to be paid by : '),
                                ..._buildGstPayerSelection(
                                  'Consignor',
                                  controller.selectedGstPayer.value,
                                  font,
                                ),
                                pw.TextSpan(
                                  text: ' / ',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 9.5,
                                  ),
                                ),
                                ..._buildGstPayerSelection(
                                  'Consignee',
                                  controller.selectedGstPayer.value,
                                  font,
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
                                border: pw.Border(
                                  right: pw.BorderSide(width: 1),
                                ),
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
                                border: pw.Border(
                                  right: pw.BorderSide(width: 1),
                                ),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'FREIGHT TO PAY Rs.          P.',
                                  style: pw.TextStyle(
                                    font: boldFont,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Payment section
                          pw.Expanded(
                            flex: 4,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                vertical: 2,
                              ),
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    'Payment',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7.5,
                                    ),
                                  ),
                                  pw.Text(
                                    'Frieght Receipt',
                                    style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                    ),
                                  ),
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
                                border: pw.Border(
                                  right: pw.BorderSide(width: 1),
                                ),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '"Certified that the credit of Input Tax Charged on Goods and Services used in Supplying of GTA Services has not been Taken in view of Notification Issued under Goods & Service Tax"',
                                  style: pw.TextStyle(font: font, fontSize: 9),
                                  textAlign: pw.TextAlign.justify,
                                ),
                              ),
                            ),
                          ),
                          // Freight breakdown column
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(width: 1),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceAround,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'Frieght per Ton. C.M.',
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                        ),
                                      ),
                                      pw.Container(
                                        width: 35,
                                        height: 1,
                                        color: PdfColors.black,
                                      ),
                                    ],
                                  ),
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'Surcharges (Goods/Tax)',
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                        ),
                                      ),
                                      pw.Container(
                                        width: 35,
                                        height: 1,
                                        color: PdfColors.black,
                                      ),
                                    ],
                                  ),
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'Hamali',
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                        ),
                                      ),
                                      pw.Container(
                                        width: 35,
                                        height: 1,
                                        color: PdfColors.black,
                                      ),
                                    ],
                                  ),
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'Risk Charges',
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                        ),
                                      ),
                                      pw.Container(
                                        width: 35,
                                        height: 1,
                                        color: PdfColors.black,
                                      ),
                                    ],
                                  ),
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'St. Charges',
                                        style: pw.TextStyle(
                                          font: font,
                                          fontSize: 8,
                                        ),
                                      ),
                                      pw.Container(
                                        width: 35,
                                        height: 1,
                                        color: PdfColors.black,
                                      ),
                                    ],
                                  ),
                                  pw.Container(
                                    height: 1,
                                    width: double.infinity,
                                    color: PdfColors.black,
                                  ),
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'Total',
                                        style: pw.TextStyle(
                                          font: boldFont,
                                          fontSize: 8,
                                        ),
                                      ),
                                      pw.Container(
                                        width: 35,
                                        height: 1,
                                        color: PdfColors.black,
                                      ),
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
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Receipt / Bill No.',
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 7.5,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: PdfColors.black,
                                  ),
                                  pw.SizedBox(height: 14),
                                  pw.Text(
                                    'Date',
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 7.5,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: PdfColors.black,
                                  ),
                                  pw.SizedBox(height: 14),
                                  pw.Text(
                                    'Amount',
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 7.5,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: PdfColors.black,
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
      ],
    );
  }

  static pw.Widget _buildFooter(
    pw.Font font,
    pw.Font boldFont,
    GCFormController controller, {
    required String copyTitle,
  }) {
    // Get GC creator's booking officer name from the controller
    // This shows who created the GC, not who is viewing it
    final bookingOfficerName = controller.gcBookingOfficerName.value;

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Container(width: 150, height: 0.5, child: pw.Divider()),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Signature of Consignor or his Agent',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  copyTitle,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: PdfColors.red,
                  ),
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // User name
                  pw.Text(
                    bookingOfficerName.isNotEmpty
                        ? bookingOfficerName
                        : 'Booking Officer',
                    style: pw.TextStyle(font: boldFont, fontSize: 7),
                  ),
                  pw.SizedBox(height: 1),
                  // Space for seal image (smaller bordered box)
                  pw.Container(
                    width: 60,
                    height: 30,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        width: 0.5,
                        color: PdfColors.grey400,
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Seal',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 6,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  // Divider line for signature
                  pw.Container(width: 120, height: 0.5, child: pw.Divider()),
                  pw.Text(
                    'Signature of Booking Officer',
                    style: pw.TextStyle(font: font, fontSize: 7),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        // Subject to Chennai Jurisdiction at the bottom
        pw.Center(
          child: pw.Text(
            'Subject to Chennai Jurisdiction',
            style: pw.TextStyle(font: font, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCheckboxWithLabel(
    String label,
    pw.Font font, {
    bool isChecked = false,
  }) {
    const String checkmarkSvg =
        '<svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" fill="none" stroke="#00AA00" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>';

    return pw.Row(
      children: [
        pw.Container(
          alignment: pw.Alignment.center,
          width: 12,
          height: 12,
          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.9)),
          child: isChecked
              ? pw.SvgImage(
                  svg: checkmarkSvg,
                  width: 10,
                  height: 10,
                  fit: pw.BoxFit.contain,
                )
              : null,
        ),
        pw.SizedBox(width: 2),
        isChecked
            ? pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
                child: pw.Text(
                  label,
                  style: pw.TextStyle(font: font, fontSize: 7.5),
                ),
              )
            : pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7.5)),
      ],
    );
  }

  static Future<List<Map<String, dynamic>>> _fetchBranches() async {
    try {
      final idController = Get.find<IdController>();
      final companyId = idController.companyId.value;

      if (companyId.isEmpty) {
        debugPrint('⚠️ Company ID is empty, returning empty branches list');
        return [];
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/branch/company/$companyId');
      debugPrint('🔍 Fetching branches from: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('✅ Fetched ${data.length} branches');
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ Failed to fetch branches: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching branches: $e');
      return [];
    }
  }

  static pw.Widget _buildDynamicBranches(
    List<Map<String, dynamic>> branches,
    String selectedBranch,
    pw.Font font,
  ) {
    if (branches.isEmpty) {
      return pw.Row(
        children: [
          pw.Text(
            'Branch Office :',
            style: pw.TextStyle(font: font, fontSize: 9),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            'No branches available',
            style: pw.TextStyle(font: font, fontSize: 7),
          ),
        ],
      );
    }

    // Split branches into rows (max 3 per row for better spacing)
    final List<List<Map<String, dynamic>>> branchRows = [];
    for (int i = 0; i < branches.length; i += 3) {
      branchRows.add(
        branches.sublist(i, i + 3 > branches.length ? branches.length : i + 3),
      );
    }

    // Calculate equal column width for grid alignment
    const double labelWidth = 78.0; // Width for "Branch Office :" label
    const double availableWidth = 400.0; // Available width for branches
    const double columnWidth =
        availableWidth / 3; // Equal width per column (100px each)

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (int rowIndex = 0; rowIndex < branchRows.length; rowIndex++)
          pw.Padding(
            padding: pw.EdgeInsets.only(
              bottom: rowIndex < branchRows.length - 1 ? 2 : 0,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Label or spacer
                pw.SizedBox(
                  width: labelWidth,
                  child: rowIndex == 0
                      ? pw.Text(
                          'Branch Office :',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        )
                      : pw.SizedBox(),
                ),
                // Grid columns for branches
                for (int i = 0; i < 3; i++)
                  pw.SizedBox(
                    width: columnWidth,
                    child: i < branchRows[rowIndex].length
                        ? _buildCheckboxWithLabel(
                            branchRows[rowIndex][i]['branch_name']
                                    ?.toString()
                                    .toUpperCase() ??
                                'UNKNOWN',
                            font,
                            isChecked:
                                branchRows[rowIndex][i]['branch_name']
                                    ?.toString() ==
                                selectedBranch,
                          )
                        : pw.SizedBox(), // Empty cell for alignment
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper to draw a vector-based checkmark to avoid font issues.
  static pw.WidgetSpan _buildPdfCheck(bool checked) {
    // SVG path for a proper checkmark stroke in green.
    const String checkmarkSvg =
        '<svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" fill="none" stroke="#00AA00" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>';
    return pw.WidgetSpan(
      child: pw.Container(
        alignment: pw.Alignment.center,
        width: 12,
        height: 12,
        margin: const pw.EdgeInsets.only(right: 4),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
        child: checked
            ? pw.SvgImage(
                svg: checkmarkSvg,
                width: 10,
                height: 10,
                fit: pw.BoxFit.contain,
              )
            : null,
      ),
    );
  }

  // Helper for Consignor/Consignee selection with checkbox and strike-through
  static List<pw.InlineSpan> _buildPayerSelection(
    String option,
    pw.Font boldFont,
  ) {
    return [
      pw.TextSpan(
        text: option,
        style: pw.TextStyle(font: boldFont, fontSize: 10),
      ),
    ];
  }

  static List<pw.InlineSpan> _buildGstPayerSelection(
    String option,
    String selectedValue,
    pw.Font font,
  ) {
    final bool isSelected = selectedValue == option;
    final bool strikeThrough = selectedValue.isNotEmpty && !isSelected;

    return [
      _buildPdfCheck(isSelected),
      if (isSelected) ...[
        pw.WidgetSpan(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: pw.BoxDecoration(
              color: PdfColors.green100,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Text(
              option,
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                decoration: strikeThrough
                    ? pw.TextDecoration.lineThrough
                    : pw.TextDecoration.none,
                decorationColor: PdfColors.black,
                decorationThickness: 1.5,
              ),
            ),
          ),
        ),
      ] else ...[
        pw.TextSpan(
          text: option,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            decoration: strikeThrough
                ? pw.TextDecoration.lineThrough
                : pw.TextDecoration.none,
            decorationColor: PdfColors.black,
            decorationThickness: 1.5,
          ),
        ),
      ],
    ];
  }

  static Future<void> showPdfPreview(
    BuildContext context,
    GCFormController controller,
  ) async {
    print('Date from form :${controller.gcDateCtrl.text}');
    print('Delivery address : ${controller.deliveryAddressCtrl.text}');
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

      await Printing.sharePdf(bytes: pdfData, filename: gcNumber);
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
              await Printing.sharePdf(bytes: pdfData, filename: displayName);
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
          Printing.sharePdf(bytes: pdfData, filename: displayName);
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
