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

  static pw.Widget _buildCopyHeader(String title, PdfColor color, pw.Font boldFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 14,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
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
                                    'Truck No. ',
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
                    _buildFieldRow(
                      'From',
                      controller.fromCtrl.text,
                      font,
                      isAddress: true,
                    ),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('PAN No', 'AAGPP5677A', font),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow(
                      'To',
                      controller.toCtrl.text,
                      font,
                      isAddress: true,
                    ),
                    pw.Divider(height: 1, thickness: 1),
                    _buildFieldRow('SAC No ', '996511', font),
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
      children: [
        pw.Table(
          border: pw.TableBorder.all(width: 1),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.3),
            1: pw.FlexColumnWidth(1.7),
            2: pw.FlexColumnWidth(1.3),
            3: pw.FlexColumnWidth(1.7),
            4: pw.FlexColumnWidth(1.5),
            5: pw.FlexColumnWidth(2.0),
            6: pw.FlexColumnWidth(2.0),
          },
          children: [
            pw.TableRow(
              children: [
                _buildAddressLabelCell('Consignor', boldFont, font),
                _buildAddressValueCell(
                  controller.consignorNameCtrl.text,
                  controller.consignorAddressCtrl.text,
                  controller.consignorGstCtrl.text,
                  font,
                ),
                _buildAddressLabelCell('Consignee', boldFont, font),
                _buildAddressValueCell(
                  controller.consigneeNameCtrl.text,
                  controller.consigneeAddressCtrl.text,
                  controller.consigneeGstCtrl.text,
                  font,
                ),
                _buildCell('', font),
                _buildCell('', font),
                _buildCellWithChildren([
                  // Invoice Box
                  pw.Container(
                    width: 180,
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Invoice No.:',
                          style: pw.TextStyle(font: boldFont, fontSize: 9),
                        ),
                        pw.Text(
                          '1. ${controller.customInvoiceCtrl.text}',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.Text(
                          '2. ',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Date:',
                          style: pw.TextStyle(font: boldFont, fontSize: 9),
                        ),
                        pw.Text(
                          '1. ${controller.gcDateCtrl.text}',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.Text(
                          '2. ',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  // E-way Bill Box
                  pw.Container(
                    width: 180,
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'E-way Bill:',
                          style: pw.TextStyle(font: boldFont, fontSize: 9),
                        ),
                        pw.Text(
                          '1. ${controller.ewayBillCtrl.text}',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.Text(
                          '2. ',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Exp. Date:',
                          style: pw.TextStyle(font: boldFont, fontSize: 9),
                        ),
                        pw.Text(
                          '1. ${controller.ewayExpiredCtrl.text}',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.Text(
                          '2. ',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
            // Package Details Row
            pw.TableRow(
              children: [
                _buildCell(
                  'Number of\npackages',
                  boldFont,
                  align: pw.TextAlign.center,
                ),
                _buildCell(
                  'Method of\npackages',
                  boldFont,
                  align: pw.TextAlign.center,
                ),
                _buildCell(
                  'Nature of goods said to Contain',
                  boldFont,
                  align: pw.TextAlign.center,
                ),
                _buildCell(
                  'Actual Weight\nKgs.',
                  boldFont,
                  align: pw.TextAlign.center,
                ),
                _buildCell(
                  'Private Marks',
                  boldFont,
                  align: pw.TextAlign.center,
                ),
                _buildCell('Charges for', boldFont, align: pw.TextAlign.center),
                _buildCell('Value of', boldFont, align: pw.TextAlign.center),
              ],
            ),
            pw.TableRow(
              children: [
                _buildCell(
                  controller.packagesCtrl.text,
                  font,
                  align: pw.TextAlign.center,
                ),
                _buildCell(
                  controller.methodPackageCtrl.text,
                  font,
                  align: pw.TextAlign.center,
                ),
                _buildCell(
                  controller.natureGoodsCtrl.text,
                  font,
                  align: pw.TextAlign.center,
                ),
                _buildCell(
                  controller.actualWeightCtrl.text,
                  font,
                  align: pw.TextAlign.center,
                ),
                _buildCell('O / R', font, align: pw.TextAlign.center),
                _buildCell('FTL', font, align: pw.TextAlign.center),
                _buildCell(
                  controller.invValueCtrl.text,
                  font,
                  align: pw.TextAlign.center,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        _buildChargesTable(font, boldFont, controller),
      ],
    );
  }

  static pw.Widget _buildChargesTable(
      pw.Font font,
      pw.Font boldFont,
      GCFormController controller,
      ) {
    return pw.Table(
      border: pw.TableBorder.all(width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(2.5),
        2: pw.FlexColumnWidth(2.0),
        3: pw.FlexColumnWidth(2.0),
        4: pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              height: 100,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Delivery from & Special Instructions',
                    style: pw.TextStyle(font: boldFont, fontSize: 9),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(2),
                    child: pw.Text(
                      controller.deliveryInstructionsCtrl.text,
                      style: pw.TextStyle(font: font, fontSize: 9),
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    'GSTIN to paid by : Consignor / Consignee',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.Container(
              height: 100,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5, color: PdfColors.red),
                    ),
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
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '"Certified that the credit of Input Tax Charged on Goods and Services used in Supplying of GTA Services has not been Taken in view of Notification Issued under Goods & Service Tax"',
                    style: pw.TextStyle(font: font, fontSize: 7),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),
            pw.Container(
              height: 130,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 30.0, bottom: 2.0),
                    child: pw.Text(
                      'Frieght per Ton. C.M.',
                      style: pw.TextStyle(font: font, fontSize: 8, height: 1.3),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                    child: pw.Text(
                      'Surcharges (Goods/Tax)',
                      style: pw.TextStyle(font: font, fontSize: 8, height: 1.3),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                    child: pw.Text(
                      'Hamali',
                      style: pw.TextStyle(font: font, fontSize: 8, height: 1.3),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                    child: pw.Text(
                      'Risk Charges',
                      style: pw.TextStyle(font: font, fontSize: 8, height: 1.3),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                    child: pw.Text(
                      'St. Charges',
                      style: pw.TextStyle(font: font, fontSize: 8, height: 1.3),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                    child: pw.Text(
                      'Total',
                      style: pw.TextStyle(font: boldFont, fontSize: 9, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              height: 80,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FREIGHT TO PAY',
                    style: pw.TextStyle(font: boldFont, fontSize: 8),
                  ),
                  pw.Text(
                    'Rs.             P.',
                    style: pw.TextStyle(font: boldFont, fontSize: 8),
                  ),
                ],
              ),
            ),
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
                      pw.Text(
                        'Payment',
                        style: pw.TextStyle(font: boldFont, fontSize: 8),
                      ),
                      pw.Text(
                        'Frieght Receipt',
                        style: pw.TextStyle(font: boldFont, fontSize: 8),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Receipt / Bill No.',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                  pw.Text('Date', style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text(
                    'Amount',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
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

  static pw.Widget _buildAddressLabelCell(
      String title,
      pw.Font boldFont,
      pw.Font font,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: 140,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: 25,
            child: pw.Text(
              '$title:',
              style: pw.TextStyle(font: boldFont, fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 45,
            child: pw.Text(
              'Address:',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ),
          pw.Spacer(),
          pw.Container(
            height: 20,
            child: pw.Text(
              'GSTIN. No:',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAddressValueCell(
      String name,
      String address,
      String gstin,
      pw.Font font,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: 140,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: 25,
            child: pw.Text(name, style: pw.TextStyle(font: font, fontSize: 9)),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 45,
            child: pw.Text(
              address,
              style: pw.TextStyle(font: font, fontSize: 8),
              maxLines: 3,
            ),
          ),
          pw.Spacer(),
          pw.Container(
            height: 20,
            child: pw.Text(gstin, style: pw.TextStyle(font: font, fontSize: 8)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCell(
      String text,
      pw.Font font, {
        pw.TextAlign align = pw.TextAlign.left,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildCellWithChildren(List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: children,
      ),
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
              style: pw.TextStyle(
                font: font,
                fontSize: 8,
              ),
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