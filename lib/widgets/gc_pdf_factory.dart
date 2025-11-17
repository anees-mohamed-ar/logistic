import 'package:flutter/material.dart';
import 'package:logistic/config/flavor_config.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/widgets/gc_pdf.dart' as cargo;
import 'package:logistic/widgets/gc_pdf_carrying.dart' as carrying;

/// Factory class to create the appropriate PDF generator based on the company flavor
class GCPdfFactory {
  /// Show PDF preview using the appropriate generator
  static Future<void> showPdfPreview(
    BuildContext context,
    GCFormController controller,
  ) async {
    switch (FlavorConfig.instance.flavor) {
      case Flavor.cargo:
        await cargo.GCPdfGenerator.showPdfPreview(context, controller);
        break;
      case Flavor.carrying:
        await carrying.GCPdfGenerator.showPdfPreview(context, controller);
        break;
    }
  }

  /// Save PDF to device using the appropriate generator
  static Future<String> savePdfToDevice(GCFormController controller) async {
    switch (FlavorConfig.instance.flavor) {
      case Flavor.cargo:
        return await cargo.GCPdfGenerator.savePdfToDevice(controller);
      case Flavor.carrying:
        return await carrying.GCPdfGenerator.savePdfToDevice(controller);
    }
  }

  /// Share PDF using the appropriate generator
  static Future<void> sharePdf(GCFormController controller) async {
    switch (FlavorConfig.instance.flavor) {
      case Flavor.cargo:
        await cargo.GCPdfGenerator.sharePdf(controller);
        break;
      case Flavor.carrying:
        await carrying.GCPdfGenerator.sharePdf(controller);
        break;
    }
  }

  /// Print PDF using the appropriate generator
  static Future<void> printPdf(GCFormController controller) async {
    switch (FlavorConfig.instance.flavor) {
      case Flavor.cargo:
        await cargo.GCPdfGenerator.printPdf(controller);
        break;
      case Flavor.carrying:
        await carrying.GCPdfGenerator.printPdf(controller);
        break;
    }
  }
}
