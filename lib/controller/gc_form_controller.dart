import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/models/km_location.dart';
import 'package:logistic/models/temporary_gc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, Directory;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class WeightRate {
  final int id;
  final String weight;
  final double below250;
  final double above250;

  WeightRate({
    required this.id,
    required this.weight,
    required this.below250,
    required this.above250,
  });

  factory WeightRate.fromJson(Map<String, dynamic> json) {
    return WeightRate(
      id: json['id'] as int,
      weight: json['weight'] as String,
      below250: double.tryParse(json['below250'].toString()) ?? 0.0,
      above250: double.tryParse(json['above250'].toString()) ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeightRate &&
        other.id == id &&
        other.weight == weight &&
        other.below250 == below250 &&
        other.above250 == above250;
  }

  @override
  int get hashCode =>
      id.hashCode ^ weight.hashCode ^ below250.hashCode ^ above250.hashCode;
}

class GCFormController extends GetxController {
  // NEW: Get an instance of IdController to trigger refreshes
  final IdController _idController = Get.find<IdController>();
  final Random _random = Random();

  // Preview attachment file
  Future<void> previewAttachment(String filename, BuildContext context) async {
    final url = '${ApiConfig.baseUrl}/gc/files/$filename';

    try {
      // Validate URL format
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('Invalid URL format: $url');
      }

      debugPrint('Attempting to preview attachment: $url');

      // Try url_launcher to open in external browser
      final canLaunch = await canLaunchUrlString(url);
      if (canLaunch) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
        debugPrint('Successfully launched URL with url_launcher');
        return;
      } else {
        throw Exception('URL cannot be launched: $url');
      }

    } catch (e) {
      debugPrint('Failed to preview attachment: $e');

      // Show error dialog with copy URL option
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Preview Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to open the attachment.'),
                const SizedBox(height: 8),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 16),
                const Text('Try copying the URL and opening it manually in your browser.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  final url = '${ApiConfig.baseUrl}/gc/files/$filename';
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied to clipboard')),
                    );
                  }
                },
                child: const Text('Copy URL'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Download attachment file to local storage
  Future<void> downloadAttachment(String filename, BuildContext context) async {
    Directory? downloadDir;

    try {
      final url = '${ApiConfig.baseUrl}/gc/files/$filename';

      // Validate URL format
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('Invalid URL format: $url');
      }

      debugPrint('Attempting to download attachment: $url');

      // Request storage permissions
      if (Platform.isAndroid) {
        debugPrint('Checking Android storage permission...');

        // First show explanation dialog
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs storage permission to download and save files to your device. '
              'Files will be saved to your Downloads folder.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (shouldRequest != true) {
          debugPrint('User cancelled permission request');
          return;
        }

        // Directly request permission - this will show the system permission dialog
        PermissionStatus status = await Permission.storage.request();

        debugPrint('WRITE_EXTERNAL_STORAGE permission result: $status');

        // If WRITE_EXTERNAL_STORAGE is denied, try MANAGE_EXTERNAL_STORAGE for Android 11+
        if (!status.isGranted) {
          debugPrint('WRITE_EXTERNAL_STORAGE denied, trying MANAGE_EXTERNAL_STORAGE...');
          status = await Permission.manageExternalStorage.request();
          debugPrint('MANAGE_EXTERNAL_STORAGE permission result: $status');
        }

        debugPrint('Final permission granted: ${status.isGranted}');
        debugPrint('Final permission denied: ${status.isDenied}');
        debugPrint('Final permission permanently denied: ${status.isPermanentlyDenied}');

        if (!status.isGranted) {
          debugPrint('Permission not granted, showing snackbar...');
          if (context.mounted) {
            // Check if permanently denied
            final permanentlyDenied = status.isPermanentlyDenied;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  permanentlyDenied
                      ? 'Storage permission is required to download files. Please enable it in app settings.'
                      : 'Storage permission is required to download files.',
                ),
                action: permanentlyDenied
                    ? SnackBarAction(
                        label: 'Settings',
                        onPressed: () async {
                          await openAppSettings();
                        },
                      )
                    : SnackBarAction(
                        label: 'Retry',
                        onPressed: () async {
                          // Retry download after user potentially grants permission
                          await downloadAttachment(filename, context);
                        },
                      ),
                duration: const Duration(seconds: 8),
              ),
            );
          }
          return;
        } else {
          debugPrint('Permission granted, proceeding with download...');
        }
      }

      // Get download directory
      if (Platform.isAndroid) {
        // Try Downloads folder first (Android 10 and below, or with MANAGE_EXTERNAL_STORAGE)
        downloadDir = Directory('/storage/emulated/0/Download');

        if (!await downloadDir.exists()) {
          // Fallback to external storage directory
          downloadDir = await getExternalStorageDirectory();

          if (downloadDir == null || !await downloadDir.exists()) {
            // Final fallback: app documents directory
            downloadDir = await getApplicationDocumentsDirectory();
          }
        }

        // Create Download subfolder in app documents if using app directory
        if (downloadDir != null && downloadDir.path.contains('app_flutter')) {
          downloadDir = Directory('${downloadDir.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
        }
      } else {
        // iOS and other platforms
        downloadDir = await getApplicationDocumentsDirectory();
        downloadDir = Directory('${downloadDir.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
      }

      if (downloadDir == null) {
        throw Exception('Could not access download directory');
      }

      // Create full file path
      final fileName = filename.split('/').last;
      final filePath = '${downloadDir.path}/$fileName';

      debugPrint('Downloading to: $filePath');

      // Show download progress dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading file...'),
              ],
            ),
          ),
        );
      }

      // Download file using Dio
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      // Close progress dialog
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        final location = downloadDir.path.contains('Download') || downloadDir.path.contains('Downloads')
            ? 'Downloads folder'
            : 'app storage';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded successfully to $location: $fileName')),
        );
      }

      debugPrint('Successfully downloaded file: $filePath');

    } catch (e) {
      debugPrint('Failed to download attachment: $e');

      // Close progress dialog if open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    }
  }

  // General Form State
  final formKey = GlobalKey<FormState>();
  final currentTab = 0.obs;
  final tabScrollController = ScrollController();
  final isLoading = false.obs;
  bool _tabScrollListenerAttached = false;

  // Access control
  final hasAccess = false.obs;
  final accessMessage = ''.obs;
  final isLoadingAccess = false.obs;

  // Shipment Tab Controllers
  final gcNumberCtrl = TextEditingController();
  final gcDate = Rxn<DateTime>();
  final gcDateCtrl = TextEditingController(); // For UI display of GC Date
  final eDaysCtrl = TextEditingController();
  final deliveryDate = Rxn<DateTime>();
  final deliveryDateCtrl =
      TextEditingController(); // For UI display of Delivery Date
  final poNumberCtrl = TextEditingController();
  final truckTypeCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final tripIdCtrl = TextEditingController();

  // Shipment Tab Observables (fetched data)
  final selectedBranch = 'Select Branch'.obs;
  final selectedBranchCode = ''.obs;
  final branchesLoading = false.obs;
  final branches = <String>['Select Branch'].obs;
  final branchCodeMap =
      <String, String>{}.obs; // Maps branch name to branch code
  final trucks = <String>['Select Truck'].obs;
  final selectedTruck = 'Select Truck'.obs;
  final trucksLoading = false.obs;
  final truckNumberCtrl =
      TextEditingController(); // To hold selected truck number for submission
  final truckNumbers = <String>[
    'Select Truck',
  ].obs; // For truck numbers dropdown
  final selectedBroker = 'Select Broker'.obs;
  final brokersLoading = false.obs;
  final brokers = <String>['Select Broker'].obs;
  final selectedConsignor = 'Select Consignor'.obs;
  final consignorsLoading = false.obs;
  final consignors = <String>['Select Consignor'].obs;
  final selectedConsignee = 'Select Consignee'.obs;
  final consigneesLoading = false.obs;
  final consignees = <String>['Select Consignee'].obs;
  final selectedBillTo = 'Select Bill To'.obs;
  final billTosLoading = false.obs;
  final billTos = <String>['Select Bill To'].obs;

  // Error states for dropdowns
  final branchesError = RxnString();
  final trucksError = RxnString();
  final brokersError = RxnString();
  final consignorsError = RxnString();
  final consigneesError = RxnString();
  final billTosError = RxnString();

  // Parties Tab Controllers
  final brokerNameCtrl = TextEditingController();
  final driverNameCtrl = TextEditingController();
  final driverPhoneCtrl = TextEditingController();
  final consignorNameCtrl = TextEditingController();

  // Goods Tab Controllers
  final weightCtrl = TextEditingController();
  final natureOfGoodsCtrl = TextEditingController();
  final consignorGstCtrl = TextEditingController();
  final consignorAddressCtrl = TextEditingController();
  final consigneeNameCtrl = TextEditingController();
  final consigneeGstCtrl = TextEditingController();
  final consigneeAddressCtrl = TextEditingController();
  final billToNameCtrl = TextEditingController();
  final billToGstCtrl = TextEditingController();
  final billToAddressCtrl = TextEditingController();

  // Parties Tab Observables (fetched data)
  final selectedDriver = ''.obs; // This will hold the selected driver name
  final driversLoading = false.obs;
  final driversError = RxnString();
  final drivers = <Map<String, dynamic>>[].obs; // Raw driver data from API
  final driverInfo =
      <String, Map<String, dynamic>>{}; // Map driver name -> details
  final consignorInfo =
      <String, Map<String, String>>{}; // Map consignor name -> details
  final consigneeInfo =
      <String, Map<String, String>>{}; // Map consignee name -> details
  final billToInfo =
      <String, Map<String, String>>{}; // Map bill to name -> details

  // Goods Tab Controllers
  final customInvoiceCtrl = TextEditingController();
  final invValueCtrl = TextEditingController();
  final ewayBillCtrl = TextEditingController();
  final ewayBillDate = Rxn<DateTime>();
  final ewayBillDateCtrl =
      TextEditingController(); // For UI display of Eway Bill Date
  final ewayExpired = Rxn<DateTime>();
  final ewayExpiredCtrl =
      TextEditingController(); // For UI display of Eway Expired Date
  final packagesCtrl = TextEditingController();
  final natureGoodsCtrl = TextEditingController();
  final methodPackageCtrl = TextEditingController();
  final actualWeightCtrl = TextEditingController();
  final kmCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  final fromLocationCtrl =
      TextEditingController(); // Used for KM lookup input (if separate from 'fromCtrl')
  final toLocationCtrl =
      TextEditingController(); // Used for KM lookup input (if separate from 'toCtrl')

  // Goods Tab Observables
  final isLoadingRates = false.obs;
  final weightRates = <WeightRate>[].obs;
  final RxString weightRatesError = RxString('');
  final selectedWeight = Rxn<WeightRate>();
  final RxString calculatedGoodsTotal =
      ''.obs; // Reactive total (rate * km) for Goods tab
  final RxList<KMLocation> kmLocations =
      <KMLocation>[].obs; // For KM data from API
  final RxBool isKmEditable =
      true.obs; // Controls if KM field can be edited manually
  final paymentOptions = ['To be billed', 'Paid', 'To pay'];
  final serviceOptions = ['Express', 'Standard', 'Pickup'];
  final packageMethods = ['Boxes', 'Cartons', 'Pallets', 'Bags', 'Barrels'];
  final selectedPayment = 'To be billed'.obs;
  final selectedService = 'Express'.obs;
  final selectedPackageMethod = 'Boxes'.obs;

  // Charges Tab Controllers
  final hireAmountCtrl = TextEditingController();
  final advanceAmountCtrl = TextEditingController();
  final deliveryAddressCtrl = TextEditingController();
  final freightChargeCtrl =
      TextEditingController(); // Represents total freight (auto-calculated)
  final billingAddressCtrl = TextEditingController();
  final deliveryInstructionsCtrl = TextEditingController();

  // Helper method to safely dispose controllers
  void _disposeIfMounted(TextEditingController? controller) {
    if (controller != null) {
      controller.dispose();
    }
  }

  Future<void> _showToast(
    String message, {
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color backgroundColor = const Color(0xFF323232),
    Color textColor = Colors.white,
  }) async {
    try {
      await Fluttertoast.showToast(
        msg: message,
        toastLength: toastLength,
        gravity: gravity,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
    } catch (e) {
      debugPrint('Toast failed: $e');
      debugPrint('Toast message: $message');
    }
  }

  // Charges Tab Observables
  final RxString balanceAmount = '0.00'.obs; // Reactive balance amount
  final gstPayerOptions = ['Consignor', 'Consignee', 'Transporter'];
  final selectedGstPayer = ''.obs; // Holds the currently selected GST payer

  String _normalizeGstPayerValue(String? value) {
    print('Normalizing GST payer: "$value" → "$value"');
    if (value == null) return '';
    final trimmed = value.trim();
    print('Normalizing GST payer: "$value" → "$trimmed"');
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    print('Normalizing GST payer: "$value" → "$trimmed" → "$lower"');
    if (lower.startsWith('select')) {
      return '';
    }

    for (final option in gstPayerOptions) {
      if (option.toLowerCase() == lower) {
        print('Normalization result: "$option"');
        return option;
      }
    }

    return '';
  }

  // Method to update GST Payer
  void onGstPayerSelected(String? newValue) {
    print('Raw GST payer selection: $newValue');
    final normalized = _normalizeGstPayerValue(newValue);
    print('Normalized GST payer: $normalized');
    selectedGstPayer.value = normalized;
  }

  // Edit Mode Variables
  final isEditMode = false.obs;
  final editingGcNumber = ''.obs;
  final editingCompanyId = ''.obs;

  // Format time for display
  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // Temporary GC Mode
  final isTemporaryMode = false.obs; // When true, save as temporary GC
  final isFillTemporaryMode = false.obs; // When true, filling a temporary GC
  final tempGcNumber = ''.obs; // Store temp GC number when filling
  final tempGcPreview = ''.obs;
  final Rx<DateTime?> lockedAt = Rx<DateTime?>(null);

  // Timer related variables for temporary GC lock
  static const Duration lockDuration = Duration(minutes: 10);
  final Rx<Duration> remainingTime = Duration.zero.obs;
  final RxBool isSessionActive = false.obs;
  final RxInt extensionCountdown = 10.obs;
  Timer? _timer;
  Timer? _confirmationTimer;
  bool _isShowingDialog = false;

  // File attachment variables
  final RxList<Map<String, dynamic>> attachedFiles = <Map<String, dynamic>>[].obs;
  final RxBool isPickingFiles = false.obs;

  // Existing attachments variables (for editing GCs)
  final RxList<Map<String, dynamic>> existingAttachments = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingAttachments = false.obs;
  final RxString attachmentsError = ''.obs;

  // ... rest of the code remains the same ...
  // Start the lock timer based on lockedAt timestamp
  void startLockTimer() {
    _timer?.cancel();
    _confirmationTimer?.cancel();

    if (!isFillTemporaryMode.value || lockedAt.value == null) {
      print('No lockedAt timestamp found, cannot start timer');
      isSessionActive.value = false;
      return;
    }

    void updateTimer() {
      final now = DateTime.now();
      final expiry = lockedAt.value!.add(lockDuration);
      remainingTime.value = expiry.isAfter(now)
          ? expiry.difference(now)
          : Duration.zero;

      isSessionActive.value = remainingTime.value > Duration.zero;

      if (remainingTime.value <= Duration.zero) {
        _timer?.cancel();
        isSessionActive.value = false;
        _showTimeExtensionDialog();
      }
    }

    updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => updateTimer());
  }

  // Show time extension dialog with auto-close after 10 seconds
  Future<void> _showTimeExtensionDialog() async {
    if (_isShowingDialog) return;
    if (!isFillTemporaryMode.value) return;
    _isShowingDialog = true;

    bool userResponded = false;
    extensionCountdown.value = 10;

    _confirmationTimer?.cancel();
    _confirmationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isFillTemporaryMode.value) {
        timer.cancel();
        return;
      }

      if (extensionCountdown.value > 0) {
        extensionCountdown.value--;
      }

      if (extensionCountdown.value <= 0 && !userResponded) {
        timer.cancel();
        _isShowingDialog = false;
        if (Get.isDialogOpen ?? false) {
          Get.back(); // Close form automatically when timer elapses
        }
      }
    });

    final result =
        await Get.dialog<bool>(
          WillPopScope(
            onWillPop: () async => false, // Prevent back button
            child: AlertDialog(
              title: const Text('Time Expired'),
              content: const Text(
                'Your time is up! Would you like to extend your session?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    userResponded = true;
                    _confirmationTimer?.cancel();
                    extensionCountdown.value = 0;
                    Get.back(result: false);
                  },
                  child: Obx(() => Text('No (${extensionCountdown.value}s)')),
                ),
                TextButton(
                  onPressed: () {
                    userResponded = true;
                    _confirmationTimer?.cancel();
                    extensionCountdown.value = 0;
                    Get.back(result: true);
                  },
                  child: const Text('Yes'),
                ),
              ],
            ),
          ),
          barrierDismissible: false,
        ) ??
        false;

    _isShowingDialog = false;
    _confirmationTimer?.cancel();

    if (result) {
      // Extend time - attempt to lock again and restart timer from server timestamp
      await _extendTemporaryGcLock();
    } else {
      // Close form
      Get.back();
    }
  }

  Future<void> _extendTemporaryGcLock() async {
    try {
      final tempNumber = tempGcNumber.value;
      if (tempNumber.isEmpty) {
        lockedAt.value = DateTime.now();
        startLockTimer();
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/temporary-gc/lock/$tempNumber'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _idController.userId.value}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lockedAtStr = data['lockedAt'];
        lockedAt.value = lockedAtStr != null
            ? DateTime.tryParse(lockedAtStr.toString()) ?? DateTime.now()
            : DateTime.now();
        startLockTimer();
      } else {
        throw Exception('Failed to extend lock (${response.statusCode})');
      }
    } catch (e) {
      print('Error extending temporary GC lock: $e');
      lockedAt.value = DateTime.now();
      startLockTimer();
    }
  }

  String _generateTempGcNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    final randomValue = _random
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    return 'TEMP-$timestamp-$randomValue';
  }

  void prepareTemporaryGcForm() {
    final number = _generateTempGcNumber();
    gcNumberCtrl.text = number;
    tempGcPreview.value = number;
    // Set lockedAt timestamp to current time when creating new temporary GC
    lockedAt.value = DateTime.now();
  }

  void loadTemporaryGc(TemporaryGC tempGC) {
    // Branch
    if (tempGC.branch != null) selectedBranch.value = tempGC.branch!;
    if (tempGC.branchCode != null)
      selectedBranchCode.value = tempGC.branchCode!;

    // GC date
    if (tempGC.gcDate != null) {
      try {
        final parsed = DateTime.parse(tempGC.gcDate!);
        gcDate.value = parsed;
        gcDateCtrl.text = DateFormat('dd-MMM-yyyy').format(parsed);
      } catch (_) {}
    }

    // E-days and delivery date
    if (tempGC.eda != null && tempGC.eda!.isNotEmpty) {
      eDaysCtrl.text = tempGC.eda!;
      updateDeliveryDateFromInputs();
    }

    if (tempGC.deliveryDate != null) {
      try {
        final parsed = DateTime.parse(tempGC.deliveryDate!);
        deliveryDate.value = parsed;
        deliveryDateCtrl.text = DateFormat('dd-MMM-yyyy').format(parsed);
      } catch (_) {}
    }

    // Truck details
    if (tempGC.truckNumber != null && tempGC.truckNumber!.isNotEmpty) {
      selectedTruck.value = tempGC.truckNumber!;
      truckNumberCtrl.text = tempGC.truckNumber!;
    }
    if (tempGC.truckType != null) {
      truckTypeCtrl.text = tempGC.truckType!;
    }
    if (tempGC.truckFrom != null) {
      fromCtrl.text = tempGC.truckFrom!;
    }
    if (tempGC.truckTo != null) {
      toCtrl.text = tempGC.truckTo!;
    }

    // Broker and driver
    if (tempGC.brokerNameShow != null) {
      selectedBroker.value = tempGC.brokerNameShow!;
      brokerNameCtrl.text = tempGC.brokerNameShow!;
    }
    if (tempGC.driverNameShow != null) {
      selectedDriver.value = tempGC.driverNameShow!;
      driverNameCtrl.text = tempGC.driverNameShow!;
    }
    if (tempGC.driverPhoneNumber != null) {
      driverPhoneCtrl.text = tempGC.driverPhoneNumber!;
    }

    // Consignor / Consignee
    if (tempGC.consignorName != null) {
      selectedConsignor.value = tempGC.consignorName!;
      consignorAddressCtrl.text = tempGC.consignorAddress ?? '';
      consignorGstCtrl.text = tempGC.consignorGst ?? '';
    }
    if (tempGC.consigneeName != null) {
      selectedConsignee.value = tempGC.consigneeName!;
      consigneeAddressCtrl.text = tempGC.consigneeAddress ?? '';
      consigneeGstCtrl.text = tempGC.consigneeGst ?? '';
    }

    // Bill To details
    final billToName = tempGC.billToName ?? '';
    if (billToName.isNotEmpty) {
      selectedBillTo.value = billToName;
      billToNameCtrl.text = billToName;
      billToGstCtrl.text = tempGC.billToGst ?? '';
      billToAddressCtrl.text = tempGC.billToAddress ?? '';

      // Ensure dropdown data includes this bill-to entry even if not in fetched list yet
      billToInfo[billToName] = {
        'gst': billToGstCtrl.text,
        'address': billToAddressCtrl.text,
      };
      if (!billTos.contains(billToName)) {
        billTos.add(billToName);
      }
    } else {
      selectedBillTo.value = 'Select Bill To';
      billToNameCtrl.clear();
      billToGstCtrl.clear();
      billToAddressCtrl.clear();
    }

    // Goods info
    if (tempGC.goodContain != null) {
      natureGoodsCtrl.text = tempGC.goodContain!;
    }
    if (tempGC.numberofPkg != null) {
      packagesCtrl.text = tempGC.numberofPkg!;
    }
    if (tempGC.methodofPkg != null) {
      selectedPackageMethod.value = tempGC.methodofPkg!;
      methodPackageCtrl.text = tempGC.methodofPkg!;
    }
    if (tempGC.totalWeight != null) {
      actualWeightCtrl.text = tempGC.totalWeight!;
    }
    if (tempGC.totalRate != null) {
      rateCtrl.text = tempGC.totalRate!;
    }

    // Payment details
    if (tempGC.paymentDetails != null) {
      selectedPayment.value = tempGC.paymentDetails!;
    }
    if (tempGC.hireAmount != null) {
      hireAmountCtrl.text = tempGC.hireAmount!;
    }
    if (tempGC.advanceAmount != null) {
      advanceAmountCtrl.text = tempGC.advanceAmount!;
    }
    if (tempGC.balanceAmount != null) {
      balanceAmount.value = tempGC.balanceAmount!;
    }
    if (tempGC.freightCharge != null) {
      freightChargeCtrl.text = tempGC.freightCharge!;
    }
    print('Raw GST payer from DB: ${tempGC.serviceTax}');
    selectedGstPayer.value = _normalizeGstPayerValue(tempGC.serviceTax);
    print('Normalized GST payer after load: ${selectedGstPayer.value}');
    if (tempGC.custInvNo != null) customInvoiceCtrl.text = tempGC.custInvNo!;
    if (tempGC.invValue != null) invValueCtrl.text = tempGC.invValue!;
    if (tempGC.poNumber != null) poNumberCtrl.text = tempGC.poNumber!;
    if (tempGC.tripId != null) tripIdCtrl.text = tempGC.tripId!;
    if (tempGC.deliveryAddress != null)
      deliveryAddressCtrl.text = tempGC.deliveryAddress!;
    if (tempGC.deliveryFromSpecial != null)
      deliveryInstructionsCtrl.text = tempGC.deliveryFromSpecial!;
    if (tempGC.privateMark != null) remarksCtrl.text = tempGC.privateMark!;

    // Set lockedAt timestamp for timer
    if (tempGC.lockedAt != null) {
      try {
        lockedAt.value = DateTime.parse(tempGC.lockedAt! as String);
      } catch (e) {
        print('Error parsing lockedAt timestamp: $e');
        lockedAt.value = DateTime.now(); // Fallback to current time
      }
    } else {
      lockedAt.value =
          DateTime.now(); // Default to current time if not provided
    }
  }

  // Cancel all timers
  void _cancelTimers() {
    _timer?.cancel();
    _confirmationTimer?.cancel();
    _timer = null;
    _confirmationTimer = null;
  }

  @override
  void onInit() {
    super.onInit(); // Always call super.onInit() first

    // Attach listeners
    kmCtrl.addListener(calculateRate);
    fromCtrl.addListener(
      _handleLocationChange,
    ); // Listen to changes in 'From' field for KM lookup
    toCtrl.addListener(
      _handleLocationChange,
    ); // Listen to changes in 'To' field for KM lookup
    hireAmountCtrl.addListener(
      _updateBalanceAmount,
    ); // Listen for hire amount changes
    advanceAmountCtrl.addListener(
      _updateBalanceAmount,
    ); // Listen for advance amount changes

    // Add GST payer normalization for all GCs
    ever(selectedGstPayer, (value) {
      if (value.isNotEmpty) {
        selectedGstPayer.value = _normalizeGstPayerValue(value);
      }
    });

    // Start timer only in temporary mode
    ever<bool>(isTemporaryMode, (isTemp) {
      if (isTemp && lockedAt.value != null) {
        startLockTimer();
      }
    });

    ever<bool>(isFillTemporaryMode, (isFillTemp) {
      if (isFillTemp && lockedAt.value != null) {
        startLockTimer();
      }
    });

    // Fetch initial data for dropdowns and rates
    fetchBranches();
    fetchTrucks();
    fetchBrokers();
    fetchDrivers();
    fetchConsignors();
    fetchConsignees();
    fetchBillTos();
    fetchWeightRates();
    fetchKMLocations();
  }

  @override
  void onClose() {
    // Reset tab scroll listener flag
    _tabScrollListenerAttached = false;

    // Remove listeners
    kmCtrl.removeListener(calculateRate);
    fromCtrl.removeListener(_handleLocationChange);
    toCtrl.removeListener(_handleLocationChange);
    hireAmountCtrl.removeListener(_updateBalanceAmount);
    advanceAmountCtrl.removeListener(_updateBalanceAmount);

    // Cancel timers
    _cancelTimers();

    // Dispose controllers
    _disposeIfMounted(gcNumberCtrl);
    _disposeIfMounted(eDaysCtrl);
    _disposeIfMounted(poNumberCtrl);
    _disposeIfMounted(truckTypeCtrl);
    _disposeIfMounted(fromCtrl);
    _disposeIfMounted(toCtrl);
    _disposeIfMounted(tripIdCtrl);
    _disposeIfMounted(brokerNameCtrl);
    _disposeIfMounted(driverNameCtrl);
    _disposeIfMounted(driverPhoneCtrl);
    _disposeIfMounted(consignorNameCtrl);
    _disposeIfMounted(weightCtrl);
    _disposeIfMounted(natureOfGoodsCtrl);
    _disposeIfMounted(consignorGstCtrl);
    _disposeIfMounted(consignorAddressCtrl);
    _disposeIfMounted(consigneeNameCtrl);
    _disposeIfMounted(consigneeGstCtrl);
    _disposeIfMounted(consigneeAddressCtrl);
    _disposeIfMounted(billToNameCtrl);
    _disposeIfMounted(billToGstCtrl);
    _disposeIfMounted(billToAddressCtrl);
    _disposeIfMounted(customInvoiceCtrl);
    _disposeIfMounted(invValueCtrl);
    _disposeIfMounted(ewayBillCtrl);
    _disposeIfMounted(ewayBillDateCtrl);
    _disposeIfMounted(ewayExpiredCtrl);
    _disposeIfMounted(packagesCtrl);
    _disposeIfMounted(natureGoodsCtrl);
    _disposeIfMounted(methodPackageCtrl);
    _disposeIfMounted(actualWeightCtrl);
    _disposeIfMounted(kmCtrl);
    _disposeIfMounted(rateCtrl);
    _disposeIfMounted(remarksCtrl);
    _disposeIfMounted(fromLocationCtrl);
    _disposeIfMounted(toLocationCtrl);
    _disposeIfMounted(hireAmountCtrl);
    _disposeIfMounted(advanceAmountCtrl);
    _disposeIfMounted(deliveryAddressCtrl);
    _disposeIfMounted(freightChargeCtrl);
    _disposeIfMounted(billingAddressCtrl);
    _disposeIfMounted(deliveryInstructionsCtrl);
    tabScrollController.dispose();

    super.onClose(); // Always call super.onClose() last
  }

  /// Attach tab scroll centering listener once to avoid multiple subscriptions.
  void attachTabScrollListener(BuildContext context) {
    if (_tabScrollListenerAttached) return;
    _tabScrollListenerAttached = true;

    // Store context safely and check if mounted before using
    ever<int>(currentTab, (index) {
      try {
        // Check if context is still valid and mounted
        if (context.mounted) {
          final double estimatedTabWidth = 120.0;
          final double screenWidth = MediaQuery.of(context).size.width;
          double offset =
              (estimatedTabWidth * index) -
              (screenWidth / 2) +
              (estimatedTabWidth / 2);

          if (tabScrollController.hasClients) {
            final double maxScroll =
                tabScrollController.position.maxScrollExtent;
            offset = offset.clamp(0.0, maxScroll);
            tabScrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          }
        }
      } catch (e) {
        // Silently handle context errors
        print('Tab scroll listener error: $e');
      }
    });
  }

  void changeTab(int index) {
    // Allow immediate tab change for better UX
    currentTab.value = index;
  }

  void navigateToPreviousTab() {
    if (currentTab.value > 0) {
      currentTab.value--;
    }
  }

  void navigateToNextTab() {
    if (currentTab.value < 3) {
      currentTab.value++;
    } else {
      // Validate only when submitting on the last tab
      if (formKey.currentState?.validate() ?? false) {
        submitFormToBackend();
      } else {
        _showToast(
          'Please fill all required fields before submitting.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  void selectDate(
    BuildContext context,
    Rxn<DateTime> targetDate, {
    TextEditingController? textController,
    bool restrictToToday = false, // New parameter to control date restriction
  }) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: restrictToToday
          ? DateTime(now.year, now.month, now.day)
          : DateTime(2030), // Only restrict if specified
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4A90E2),
            onPrimary: Colors.white,
            surface: Color(0xFFF7F9FC),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      targetDate.value = picked;
      if (textController != null) {
        textController.text = DateFormat('dd-MMM-yyyy').format(picked);
      }
      // Re-compute delivery date in case GC date changed
      updateDeliveryDateFromInputs();
    }
  }

  /// Computes Delivery Date = GC Date + E-days and updates UI state.
  void updateDeliveryDateFromInputs() {
    final DateTime? gc = gcDate.value;
    final int eDays = int.tryParse(eDaysCtrl.text.trim()) ?? -1;
    if (gc != null && eDays >= 0) {
      final DateTime computed = gc.add(Duration(days: eDays));
      deliveryDate.value = computed;
      deliveryDateCtrl.text = DateFormat('dd-MMM-yyyy').format(computed);
    } else {
      // Clear if inputs are incomplete/invalid
      deliveryDate.value = null;
      deliveryDateCtrl.text = '';
    }
  }

  // API Call Methods

  // Handle branch selection
  void onBranchSelected(String? branch) {
    if (branch == null || branch.isEmpty || branch == 'Select Branch') {
      selectedBranch.value = 'Select Branch';
      selectedBranchCode.value = '';
      return;
    }
    selectedBranch.value = branch;
    selectedBranchCode.value = branchCodeMap[branch] ?? '';
  }

  Future<void> fetchBranches() async {
    try {
      branchesLoading.value = true;
      branchesError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/location/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          // Clear existing data
          branches.clear();
          branchCodeMap.clear();

          // Add default option
          branches.add('Select Branch');

          // Process each branch
          for (var branch in decoded) {
            final name = (branch['branchName'] ?? branch['BranchName'] ?? '')
                .toString();
            final code = (branch['branchCode'] ?? branch['BranchCode'] ?? '')
                .toString();

            if (name.isNotEmpty && code.isNotEmpty) {
              branches.add(name);
              branchCodeMap[name] = code;
            }
          }

          // Remove duplicates and sort
          branches.value = branches.toSet().toList()
            ..sort((a, b) => a == 'Select Branch' ? -1 : a.compareTo(b));
        }
      }
    } catch (e) {
      branchesError.value = 'Failed to load branches. Tap to retry.';
    } finally {
      branchesLoading.value = false;
    }
  }

  Future<void> fetchTrucks() async {
    try {
      trucksLoading.value = true;
      trucksError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/truckmaster/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final list = decoded
              .map(
                (e) =>
                    (e['vechileNumber'] ?? e['vehicleNumber'] ?? '').toString(),
              )
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();

          truckNumbers
            ..clear()
            ..addAll(['Select Truck', ...list]);

          // Also update the trucks list for backward compatibility
          trucks
            ..clear()
            ..addAll(['Select Truck', ...list]);

          if (!truckNumbers.contains(selectedTruck.value)) {
            selectedTruck.value = 'Select Truck';
          }
        } else {
          trucksError.value = 'Unexpected response format';
        }
      } else {
        trucksError.value = 'Failed to load trucks (${response.statusCode})';
      }
    } catch (e) {
      trucksError.value = 'Failed to load trucks. Tap to retry.';
    } finally {
      trucksLoading.value = false;
    }
  }

  Future<void> fetchBrokers() async {
    try {
      brokersLoading.value = true;
      brokersError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/broker/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          final names = decoded
              .map((e) => (e['brokerName'] ?? '').toString())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList();
          brokers
            ..clear()
            ..addAll(['Select Broker', ...names]);
          if (!brokers.contains(selectedBroker.value)) {
            selectedBroker.value =
                'Select Broker'; // Reset if old value not found
          }
        } else {
          brokersError.value = 'Unexpected brokers response format';
        }
      } else {
        brokersError.value = 'Failed to load brokers: Tap to retry.';
      }
    } catch (e) {
      final errorMsg = 'Failed to load brokers: Tap to retry.';
      brokersError.value = errorMsg;
    } finally {
      brokersLoading.value = false;
    }
  }

  Future<void> fetchDrivers() async {
    try {
      driversLoading.value = true;
      driversError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/driver/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        driverInfo.clear();
        final driverNames = <String>{};

        for (final driver in decoded) {
          final name = (driver['driverName'] ?? '').toString();
          if (name.isEmpty) continue;

          driverNames.add(name);
          driverInfo[name] = {
            'phoneNumber': (driver['phoneNumber'] ?? '').toString(),
            'dlNumber': (driver['dlNumber'] ?? '').toString(),
            'address': (driver['driverAddress'] ?? '').toString(),
          };
        }

        // Clear and update the drivers list with the new data
        drivers.assignAll(decoded.cast<Map<String, dynamic>>());

        // Force UI update by triggering a change in the observable list
        drivers.refresh();

        if (driverNames.isEmpty) {
          driversError.value = 'No drivers found';
        }
      } else {
        final errorMsg = 'Failed to load drivers: Tap to retry.';
        driversError.value = errorMsg;
        _showToast(
          errorMsg,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      final errorMsg = 'Failed to load drivers: Tap to retry.';
      driversError.value = errorMsg;
      _showToast(
        errorMsg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      driversLoading.value = false;
    }
  }

  Future<void> fetchConsignors() async {
    try {
      consignorsLoading.value = true;
      consignorsError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/consignor/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          consignorInfo.clear();
          final names = <String>{};
          for (final e in decoded) {
            final name = (e['consignorName'] ?? '').toString();
            if (name.isEmpty) continue;
            names.add(name);
            consignorInfo[name] = {
              'gst': (e['gst'] ?? '').toString(),
              'address': (e['address'] ?? '').toString(),
              'location': (e['location'] ?? '').toString(),
            };
          }
          consignors
            ..clear()
            ..addAll(['Select Consignor', ...names.toList()]);
          if (!consignors.contains(selectedConsignor.value)) {
            selectedConsignor.value =
                'Select Consignor'; // Reset if old value not found
          }
          if (names.isEmpty) {
            consignorsError.value = 'No consignors found';
          }
        } else {
          consignorsError.value = 'Unexpected response format';
        }
      }
    } catch (e) {
      consignorsError.value = 'Failed to load consignors. Tap to retry.';
    } finally {
      consignorsLoading.value = false;
    }
  }

  Future<void> fetchConsignees() async {
    try {
      consigneesLoading.value = true;
      consigneesError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/consignee/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          consigneeInfo.clear();
          final names = <String>{};
          for (final e in decoded) {
            final name = (e['consigneeName'] ?? '').toString();
            if (name.isEmpty) continue;
            names.add(name);
            consigneeInfo[name] = {
              'gst': (e['gst'] ?? '').toString(),
              'address': (e['address'] ?? '').toString(),
              'location': (e['location'] ?? '').toString(),
            };
          }
          consignees
            ..clear()
            ..addAll(['Select Consignee', ...names.toList()]);
          if (!consignees.contains(selectedConsignee.value)) {
            selectedConsignee.value =
                'Select Consignee'; // Reset if old value not found
          }
          if (names.isEmpty) {
            consigneesError.value = 'No consignees found';
          }
        } else {
          consigneesError.value = 'Unexpected response format';
        }
      }
    } catch (e) {
      consigneesError.value = 'Failed to load consignees. Tap to retry.';
    } finally {
      consigneesLoading.value = false;
    }
  }

  Future<void> fetchBillTos() async {
    try {
      billTosLoading.value = true;
      billTosError.value = null;
      final url = Uri.parse('${ApiConfig.baseUrl}/consignee/search');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          billToInfo.clear();
          final names = <String>{};
          for (final e in decoded) {
            final name = (e['consigneeName'] ?? '').toString();
            if (name.isEmpty) continue;
            names.add(name);
            billToInfo[name] = {
              'gst': (e['gst'] ?? '').toString(),
              'address': (e['address'] ?? '').toString(),
              'location': (e['location'] ?? '').toString(),
            };
          }
          final currentBillTo = billToNameCtrl.text.trim();
          if (currentBillTo.isNotEmpty && currentBillTo != 'Select Bill To') {
            names.add(currentBillTo);
            billToInfo.putIfAbsent(
              currentBillTo,
              () => {
                'gst': billToGstCtrl.text,
                'address': billToAddressCtrl.text,
              },
            );
          }
          billTos
            ..clear()
            ..addAll(['Select Bill To', ...names.toList()]);
          if (!billTos.contains(selectedBillTo.value)) {
            selectedBillTo.value =
                'Select Bill To'; // Reset if old value not found
          }
          if (names.isEmpty) {
            billTosError.value = 'No bill to entries found';
          }
        } else {
          billTosError.value = 'Unexpected response format';
        }
      }
    } catch (e) {
      billTosError.value = 'Failed to load bill to entries. Tap to retry.';
    } finally {
      billTosLoading.value = false;
    }
  }

  void onBillToSelected(String? value) {
    if (value == null || value.isEmpty) {
      return;
    }

    selectedBillTo.value = value;
    billToNameCtrl.text = value;

    final info = billToInfo[value];
    if (info != null) {
      billToGstCtrl.text = info['gst'] ?? '';
      billToAddressCtrl.text = info['address'] ?? '';
    } else {
      billToGstCtrl.clear();
      billToAddressCtrl.clear();
    }

    if (value == 'Select Bill To') {
      return;
    }

    // Ensure consignee lists know about this selection
    if (!consignees.contains(value)) {
      consignees.add(value);
    }

    if (info != null && !consigneeInfo.containsKey(value)) {
      consigneeInfo[value] = {
        'gst': info['gst'] ?? '',
        'address': info['address'] ?? '',
        'location': info['location'] ?? '',
      };
    }

    selectedConsignee.value = value;
    consigneeNameCtrl.text = value;

    final consigneeDetails = consigneeInfo[value] ?? info;
    if (consigneeDetails != null) {
      final gst = consigneeDetails['gst'] ?? '';
      final address = consigneeDetails['address'] ?? '';
      final location = consigneeDetails['location'] ?? '';

      consigneeGstCtrl.text = gst;
      consigneeAddressCtrl.text = address;

      final destination = location.isNotEmpty ? location : address;
      toCtrl.text = destination;
      billingAddressCtrl.text = address;
    }
  }

  Future<void> fetchWeightRates() async {
    try {
      isLoadingRates.value = true;
      weightRatesError.value = '';
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/weight_to_rate/search'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        weightRates.assignAll(
          data.map((item) => WeightRate.fromJson(item)).toList(),
        );
        if (weightRates.isEmpty) {
          weightRatesError.value = 'No weight rates found';
        }
        if (isEditMode.value && selectedWeight.value == null) {
          final wStr = actualWeightCtrl.text.trim();
          if (wStr.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 100), () {
              selectWeightForActualWeight(wStr);
            });
          }
        }
      } else {
        weightRatesError.value = 'Failed to load weight rates. Tap to retry.';
      }
    } catch (e) {
      weightRatesError.value = 'Failed to load weight rates. Tap to retry.';
    } finally {
      isLoadingRates.value = false;
    }
  }

  Future<void> fetchKMLocations() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/km/search'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        kmLocations.assignAll(
          data.map((json) => KMLocation.fromJson(json)).toList(),
        );
      } else {
        _showToast(
          'Failed to load KM locations: ${response.statusCode}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      _showToast(
        'Error fetching KM locations: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _handleLocationChange() {
    final from = fromCtrl.text.trim();
    final to = toCtrl.text.trim();

    if (from.isNotEmpty && to.isNotEmpty) {
      updateKM(from, to);
    } else {
      kmCtrl.clear();
      isKmEditable.value = true;
      calculateRate();
    }
  }

  void updateKM(String from, String to) {
    final match = kmLocations.firstWhereOrNull(
      (loc) =>
          loc.from.toLowerCase() == from.toLowerCase() &&
          loc.to.toLowerCase() == to.toLowerCase(),
    );

    if (match != null) {
      kmCtrl.text = match.km;
      isKmEditable.value = false;
    } else {
      kmCtrl.clear();
      isKmEditable.value = true;
    }
    calculateRate();
  }

  void calculateRate() {
    final km = double.tryParse(kmCtrl.text) ?? 0.0;

    if (km <= 0) {
      freightChargeCtrl.clear();
      calculatedGoodsTotal.value = '';
      return;
    }

    if (selectedWeight.value != null) {
      final baseRate = km <= 250
          ? selectedWeight.value!.below250
          : selectedWeight.value!.above250;

      rateCtrl.text = baseRate.toStringAsFixed(2);

      final totalFreight = baseRate * km;
      freightChargeCtrl.text = totalFreight.toStringAsFixed(2);
      calculatedGoodsTotal.value = totalFreight.toStringAsFixed(2);
      return;
    }

    final existingRate = double.tryParse(rateCtrl.text);
    if (existingRate != null && existingRate > 0) {
      final totalFreight = existingRate * km;
      freightChargeCtrl.text = totalFreight.toStringAsFixed(2);
      calculatedGoodsTotal.value = totalFreight.toStringAsFixed(2);
      return;
    }

    freightChargeCtrl.clear();
    calculatedGoodsTotal.value = '';
  }

  void onWeightSelected(WeightRate? weight) {
    selectedWeight.value = weight;
    if (weight != null) {
      actualWeightCtrl.text = weight.weight;
    } else {
      actualWeightCtrl.clear();
    }
    calculateRate();
  }

  void selectWeightForActualWeight(String weightStr) {
    final rate = pickWeightRateForActualWeight(weightStr);
    selectedWeight.value = rate;
    if (rate != null) {
      actualWeightCtrl.text = rate.weight;
    } else {
      actualWeightCtrl.clear();
    }
    calculateRate();
  }

  WeightRate? pickWeightRateForActualWeight(String weightStr) {
    final cleanedInput = weightStr.trim().toLowerCase();
    final actualRaw = double.tryParse(
      cleanedInput.replaceAll(RegExp(r'[^0-9\.]'), ''),
    );

    WeightRate? exactTextMatch;
    WeightRate? containsTextMatch;
    WeightRate? numericMatch;

    for (final wr in weightRates) {
      final labelRaw = wr.weight;
      final label = labelRaw.trim().toLowerCase();

      if (label == cleanedInput) {
        exactTextMatch = wr;
        break;
      }

      if (label.contains(cleanedInput) || cleanedInput.contains(label)) {
        containsTextMatch ??= wr;
      }

      if (actualRaw != null) {
        final candidates = <double>{
          actualRaw,
          actualRaw / 1000.0,
          actualRaw * 1000.0,
        };

        final labelNum = double.tryParse(
          label.replaceAll(RegExp(r'[^0-9\.]'), ''),
        );
        if (labelNum != null) {
          for (final actual in candidates) {
            if ((labelNum - actual).abs() < 0.0001) {
              numericMatch ??= wr;
              break;
            }
          }
        }

        final dash = RegExp(r'^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)$');
        final plus = RegExp(r'^(\d+(?:\.\d+)?)\s*\+$');
        final above = RegExp(r'^(?:above|>)\s*(\d+(?:\.\d+)?)$');
        final below = RegExp(r'^(?:below|<)\s*(\d+(?:\.\d+)?)$');
        final eqNum = RegExp(r'^(\d+(?:\.\d+)?)$');

        RegExpMatch? m;
        if ((m = dash.firstMatch(label)) != null) {
          final low = double.tryParse(m!.group(1)!) ?? double.negativeInfinity;
          final high = double.tryParse(m.group(2)!) ?? double.infinity;
          for (final actual in candidates) {
            if (actual >= low && actual <= high) {
              numericMatch ??= wr;
              break;
            }
          }
        } else if ((m = plus.firstMatch(label)) != null) {
          final base = double.tryParse(m!.group(1)!) ?? double.negativeInfinity;
          for (final actual in candidates) {
            if (actual >= base) {
              numericMatch ??= wr;
              break;
            }
          }
        } else if ((m = above.firstMatch(label)) != null) {
          final th = double.tryParse(m!.group(1)!) ?? double.negativeInfinity;
          for (final actual in candidates) {
            if (actual > th) {
              numericMatch ??= wr;
              break;
            }
          }
        } else if ((m = below.firstMatch(label)) != null) {
          final th = double.tryParse(m!.group(1)!) ?? double.infinity;
          for (final actual in candidates) {
            if (actual <= th) {
              numericMatch ??= wr;
              break;
            }
          }
        } else if ((m = eqNum.firstMatch(label)) != null) {
          final num = double.tryParse(m!.group(1)!) ?? double.nan;
          for (final actual in candidates) {
            if ((num - actual).abs() < 0.0001) {
              numericMatch ??= wr;
              break;
            }
          }
        }
      }
    }

    return exactTextMatch ?? numericMatch ?? containsTextMatch;
  }

  void _updateBalanceAmount() {
    try {
      final hireAmount = double.tryParse(hireAmountCtrl.text) ?? 0;
      final advanceAmount = double.tryParse(advanceAmountCtrl.text) ?? 0;
      final balance = hireAmount - advanceAmount;
      balanceAmount.value = balance.toStringAsFixed(2);
    } catch (e) {
      balanceAmount.value = '0.00';
    }
  }

  Future<String?> fetchNextGCNumber(String userId) async {
    try {
      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;
      final nextGcUri =
          Uri.parse(
            '${ApiConfig.baseUrl}/gc-management/next-gc-number',
          ).replace(
            queryParameters: {
              'userId': userId,
              'companyId': companyId,
              if (branchId.isNotEmpty) 'branchId': branchId,
            },
          );

      final response = await http.get(
        nextGcUri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['nextGC']['nextGC'].toString();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching next GC number: $e');
      return null;
    }
  }

  Future<bool> checkGCAccess(String userId) async {
    try {
      isLoadingAccess.value = true;

      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;

      final activeRangesResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/gc-management/check-active-ranges/$userId',
        ).replace(
          queryParameters: {
            'companyId': companyId,
            if (branchId.isNotEmpty) 'branchId': branchId,
          },
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (activeRangesResponse.statusCode == 200) {
        final activeRangesData = jsonDecode(activeRangesResponse.body);
        if (activeRangesData['hasActiveRanges'] == true) {
          hasAccess.value = true;
          accessMessage.value = 'Active GC range found';
          isLoadingAccess.value = false;
          return true;
        }
      }

      final usageUri =
          Uri.parse('${ApiConfig.baseUrl}/gc-management/usage/$userId').replace(
            queryParameters: {
              'companyId': companyId,
              if (branchId.isNotEmpty) 'branchId': branchId,
            },
          );
      final usageResponse = await http.get(
        usageUri,
        headers: {'Content-Type': 'application/json'},
      );

      if (usageResponse.statusCode == 200) {
        final usageData = jsonDecode(usageResponse.body);
        if (usageData['success'] == true) {
          final rawData = usageData['data'];
          Iterable<Map<String, dynamic>> ranges = const [];

          if (rawData is List) {
            ranges = rawData.whereType<Map<String, dynamic>>();
          } else if (rawData is Map) {
            ranges = rawData.entries
                .where(
                  (entry) =>
                      entry.key is String &&
                      (entry.key as String).isNotEmpty &&
                      entry.key != 'companyId' &&
                      entry.key != 'branchId' &&
                      entry.value is Map,
                )
                .map((entry) =>
                    (entry.value as Map).cast<String, dynamic>());
          }

          final hasQueuedRange = ranges.any(
            (range) => range['status'] == 'queued',
          );

          if (hasQueuedRange) {
            hasAccess.value = true;
            accessMessage.value = 'Queued GC range found';
            isLoadingAccess.value = false;
            return true;
          }
        }
      }

      hasAccess.value = false;
      accessMessage.value =
          'No active or queued GC ranges found. Please contact admin.';
      return false;
    } catch (e) {
      hasAccess.value = false;
      accessMessage.value = 'Error checking GC access: $e';
      return false;
    } finally {
      isLoadingAccess.value = false;
    }
  }

  void clearForm() {
    formKey.currentState?.reset();

    gcNumberCtrl.clear();
    gcDateCtrl.clear();
    eDaysCtrl.clear();
    deliveryDateCtrl.clear();
    truckNumberCtrl.clear();
    truckTypeCtrl.clear();
    fromCtrl.clear();
    toCtrl.clear();
    poNumberCtrl.clear();
    tripIdCtrl.clear();
    driverNameCtrl.clear();
    driverPhoneCtrl.clear();
    consignorNameCtrl.clear();
    consignorGstCtrl.clear();
    consignorAddressCtrl.clear();
    consigneeNameCtrl.clear();
    consigneeGstCtrl.clear();
    consigneeAddressCtrl.clear();
    billToNameCtrl.clear();
    billToGstCtrl.clear();
    billToAddressCtrl.clear();
    customInvoiceCtrl.clear();
    invValueCtrl.clear();
    ewayBillCtrl.clear();
    ewayBillDateCtrl.clear();
    ewayExpiredCtrl.clear();
    packagesCtrl.clear();
    natureGoodsCtrl.clear();
    methodPackageCtrl.clear();
    actualWeightCtrl.clear();
    kmCtrl.clear();
    rateCtrl.clear();
    remarksCtrl.clear();
    hireAmountCtrl.clear();
    advanceAmountCtrl.clear();
    deliveryAddressCtrl.clear();
    freightChargeCtrl.clear();
    billingAddressCtrl.clear();
    deliveryInstructionsCtrl.clear();

    gcDate.value = null;
    deliveryDate.value = null;
    ewayBillDate.value = null;
    ewayExpired.value = null;
    balanceAmount.value = '0.00';

    selectedTruck.value = 'Select Truck';
    selectedBroker.value = 'Select Broker';
    selectedDriver.value = '';
    selectedConsignor.value = 'Select Consignor';
    selectedConsignee.value = 'Select Consignee';
    selectedBillTo.value = 'Select Bill To';
    selectedPayment.value = 'To be billed';
    selectedService.value = 'Express';
    selectedGstPayer.value = '';
    selectedPackageMethod.value = 'Boxes';

    selectedWeight.value = null;

    isEditMode.value = false;
    editingGcNumber.value = '';
    editingCompanyId.value = '';

    calculatedGoodsTotal.value = '';

    // Clear attached files and existing attachments
    attachedFiles.clear();
    existingAttachments.clear();
    attachmentsError.value = '';
  }

  // Initialize editing mode for a GC
  Future<void> initializeEditMode(String gcNumber, String companyId) async {
    isEditMode.value = true;
    editingGcNumber.value = gcNumber;
    editingCompanyId.value = companyId;

    // Fetch existing attachments for this GC
    await fetchExistingAttachments(gcNumber);
  }

  String formatDate(DateTime date) {
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  Future<void> checkGCUsageAndWarn(String userId) async {
    if (userId.isEmpty) {
      debugPrint('checkGCUsageAndWarn: User ID is empty');
      return;
    }

    try {
      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;
      final url = Uri.parse('${ApiConfig.baseUrl}/gc-management/gc-usage')
          .replace(
            queryParameters: {
              'userId': userId,
              'companyId': companyId,
              if (branchId.isNotEmpty) 'branchId': branchId,
            },
          );
      debugPrint('Fetching GC usage from: $url');

      final response = await http.get(url);
      debugPrint('GC usage response status: ${response.statusCode}');
      debugPrint('GC usage response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Parsed GC usage data: $data');

        if (data['success'] == true && data['data'] is List) {
          final usageList = data['data'] as List;

          final activeRange = usageList.cast<Map<String, dynamic>>().firstWhere(
            (item) => item['status']?.toString().toLowerCase() == 'active',
            orElse: () => <String, dynamic>{},
          );

          if (activeRange.isNotEmpty) {
            final remaining = (activeRange['remainingGCs'] ?? 0) as int;
            final hasQueuedRange = usageList.any(
              (item) => item['status'] == 'queued',
            );

            if (remaining <= 5 && !hasQueuedRange) {
              final message =
                  'Warning: Only $remaining GCs remaining in your current range (${activeRange['fromGC']}-${activeRange['toGC']}).\n\n'
                  '⚠️ No queued GC range available. Please contact admin to assign a new range.\n\n'
                  'Please request a new range soon!';

              if (Get.isDialogOpen != true) {
                Get.dialog(
                  AlertDialog(
                    title: const Text(
                      'Low GC Balance',
                      style: TextStyle(color: Colors.orange),
                    ),
                    content: Text(message),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                  barrierDismissible: false,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking GC usage: $e');
    }
  }

  // Helper method to check if the current user can edit the GC
  Future<Map<String, dynamic>> _checkLockStatus(String gcNumber) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/temporary-gc/check-lock/$gcNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isLocked = data['isLocked'] == true;
        final String? lockedByUserId = data['lockedByUserId']?.toString();
        final String currentUserId = _idController.userId.value;
        final bool isLockedByCurrentUser = lockedByUserId == currentUserId;

        debugPrint('Lock status check:');
        debugPrint('- isLocked: $isLocked');
        debugPrint('- lockedByUserId: $lockedByUserId');
        debugPrint('- currentUserId: $currentUserId');
        debugPrint('- isLockedByCurrentUser: $isLockedByCurrentUser');

        // If locked by current user, allow editing
        if (isLockedByCurrentUser) {
          debugPrint('GC is locked by current user - allowing edit');
          return {
            'canEdit': true,
            'isLocked': false,
            'lockedBy': 'You',
            'lockedByUserId': lockedByUserId,
            'currentUserId': currentUserId,
            'lockedAt': data['lockedAt'],
            'lockedAgo': data['lockedAgo'],
          };
        }

        // If locked by someone else
        if (isLocked) {
          debugPrint('GC is locked by another user');
          return {
            'canEdit': false,
            'isLocked': true,
            'lockedBy': data['lockedBy'] ?? 'Another user',
            'lockedByUserId': lockedByUserId,
            'currentUserId': currentUserId,
            'lockedAt': data['lockedAt'],
            'lockedAgo': data['lockedAgo'],
          };
        }

        // Not locked at all
        debugPrint('GC is not locked');
        return {
          'canEdit': true,
          'isLocked': false,
          'lockedBy': null,
          'lockedByUserId': null,
          'currentUserId': currentUserId,
          'lockedAt': null,
          'lockedAgo': null,
        };
      }

      // If we can't determine the lock status, be permissive
      return {
        'canEdit': true, // Allow editing if we can't check lock status
        'isLocked': false,
        'error': response.statusCode == 404
            ? 'Temporary GC not found'
            : 'Failed to check lock status',
      };
    } catch (e) {
      debugPrint('Error checking lock status: $e');
      // Be permissive on error to avoid blocking the user
      return {
        'canEdit': true,
        'isLocked': false,
        'error': 'Connection error: $e',
      };
    }
  }

  Future<void> submitFormToBackend() async {
    if (!formKey.currentState!.validate()) return;

    // For temporary GCs, verify the lock status before submission
    if (isFillTemporaryMode.value && tempGcNumber.value.isNotEmpty) {
      debugPrint('Checking lock status for GC: ${tempGcNumber.value}');
      final lockStatus = await _checkLockStatus(tempGcNumber.value);

      // Debug log the lock status
      debugPrint('Lock status for submission:');
      lockStatus.forEach((key, value) {
        debugPrint('  $key: $value');
      });

      // Only block submission if explicitly told we can't edit
      if (lockStatus['canEdit'] == false) {
        final lockedBy = lockStatus['lockedBy'] ?? 'another user';
        final lockedAgo = lockStatus['lockedAgo'] != null
            ? ' (${lockStatus['lockedAgo']})'
            : '';

        _showToast(
          'Cannot submit: The GC is currently in use by $lockedBy$lockedAgo',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }

      // If we get here, we can proceed with submission
      debugPrint(
        'Proceeding with form submission - lock status allows editing',
      );
      debugPrint('Current user ID: ${lockStatus['currentUserId']}');
      debugPrint('Locked by user ID: ${lockStatus['lockedByUserId']}');
    }

    isLoading.value = true;

    final Map<String, dynamic> data = {
      'Branch': selectedBranch.value,
      'BranchCode': selectedBranchCode.value,
      'GcNumber': gcNumberCtrl.text,
      'GcDate': gcDate.value?.toIso8601String(),
      'TruckNumber': selectedTruck.value,
      'vechileNumber': selectedTruck.value,
      'TruckType': truckTypeCtrl.text,
      'BrokerNameShow': selectedBroker.value,
      'BrokerName': selectedBroker.value,
      'TruckFrom': fromCtrl.text,
      'TruckTo': toCtrl.text,
      'PaymentDetails': selectedPayment.value,
      'DeliveryDate': deliveryDate.value?.toIso8601String(),
      'EBillDate': ewayBillDate.value?.toIso8601String(),
      'EBillExpDate': ewayExpired.value?.toIso8601String(),
      'DriverNameShow': selectedDriver.value,
      'DriverName': selectedDriver.value,
      'DriverPhoneNumber': driverPhoneCtrl.text,
      'Consignor': selectedConsignor.value,
      'ConsignorName': selectedConsignor.value,
      'ConsignorAddress': consignorAddressCtrl.text,
      'ConsignorGst': consignorGstCtrl.text,
      'Consignee': selectedConsignee.value,
      'ConsigneeName': selectedConsignee.value,
      'ConsigneeAddress': consigneeAddressCtrl.text,
      'ConsigneeGst': consigneeGstCtrl.text,
      'BillTo': selectedBillTo.value,
      'BillToName': selectedBillTo.value == 'Select Bill To'
          ? ''
          : selectedBillTo.value,
      'BillToAddress': selectedBillTo.value == 'Select Bill To'
          ? ''
          : billToAddressCtrl.text,
      'BillToGst': selectedBillTo.value == 'Select Bill To'
          ? ''
          : billToGstCtrl.text,
      'CustInvNo': customInvoiceCtrl.text,
      'InvValue': invValueCtrl.text,
      'EInv': ewayBillCtrl.text,
      'EInvDate': ewayBillDate.value?.toIso8601String(),
      'Eda': eDaysCtrl.text,
      'NumberofPkg': packagesCtrl.text,
      'MethodofPkg': selectedPackageMethod.value,
      'ActualWeightKgs': actualWeightCtrl.text,
      'km': kmCtrl.text,
      'PrivateMark': remarksCtrl.text,
      'GoodContain': natureGoodsCtrl.text,
      'Rate': rateCtrl.text,
      'Total': calculatedGoodsTotal.value,
      'PoNumber': poNumberCtrl.text,
      'TripId': tripIdCtrl.text,
      'DeliveryFromSpecial': deliveryInstructionsCtrl.text,
      'DeliveryAddress': deliveryAddressCtrl.text,
      // Ensure the GST Payer value is properly capitalized for the backend
      'ServiceTax': () {
        final normalizedGstPayer = _normalizeGstPayerValue(
          selectedGstPayer.value,
        );
        return normalizedGstPayer.isNotEmpty ? normalizedGstPayer : 'Consignor';
      }(),
      'TotalRate': rateCtrl.text,
      'TotalWeight': actualWeightCtrl.text,
      'HireAmount': hireAmountCtrl.text,
      'AdvanceAmount': advanceAmountCtrl.text,
      'BalanceAmount': balanceAmount.value,
      'FreightCharge': freightChargeCtrl.text,
      'Charges': 'FTL',
      'CompanyId': _idController.companyId.value,
      'branch_id': _idController.branchId.value,
      'isTemporary': isTemporaryMode.value,
    };

    try {
      final Uri url;
      final http.Response response;
      final userId = _idController.userId.value;
      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;

      print('GC Form Debug - userId: $userId');
      print('GC Form Debug - companyId: $companyId');
      print('GC Form Debug - branchId: $branchId');

      if (userId.isEmpty) {
        throw Exception('User ID not found. Please login again.');
      }

      if (companyId == null || companyId.isEmpty || companyId == 'undefined') {
        throw Exception('Company ID not found. Please login again.');
      }

      // Check if we have attached files
      final hasFiles = attachedFiles.isNotEmpty;

      if (isEditMode.value && editingGcNumber.value.isNotEmpty) {
        // Handle GC update (with or without files)
        if (hasFiles) {
          final request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/gc/updateGC/${editingGcNumber.value}').replace(
            queryParameters: {
              'userId': userId,
              'companyId': _idController.companyId.value,
              if (_idController.branchId.value.isNotEmpty)
                'branchId': _idController.branchId.value,
            },
          ));
          data.forEach((key, value) {
            if (value != null) {
              request.fields[key] = value.toString();
            }
          });

          // Add files
          for (int i = 0; i < attachedFiles.length; i++) {
            final file = attachedFiles[i];
            final filePath = file['path'];
            if (filePath != null && filePath is String && filePath.isNotEmpty) {
              request.files.add(
                await http.MultipartFile.fromPath(
                  'attachments',
                  filePath,
                  filename: file['name'],
                ),
              );
            }
          }

          final streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        } else {
          url = Uri.parse(
            '${ApiConfig.baseUrl}/gc/updateGC/${editingGcNumber.value}',
          ).replace(
            queryParameters: {
              'userId': userId,
              'companyId': _idController.companyId.value,
              if (_idController.branchId.value.isNotEmpty)
                'branchId': _idController.branchId.value,
            },
          );
          response = await http.put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
        }
      } else {
        // Handle GC creation (with or without files)
        if (hasFiles) {
          final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/gc/add').replace(
            queryParameters: {
              'userId': userId,
              'companyId': _idController.companyId.value,
              if (_idController.branchId.value.isNotEmpty)
                'branchId': _idController.branchId.value,
            },
          ));

          // Add form data
          data.forEach((key, value) {
            if (value != null) {
              request.fields[key] = value.toString();
            }
          });

          // Add files
          for (int i = 0; i < attachedFiles.length; i++) {
            final file = attachedFiles[i];
            final filePath = file['path'];
            if (filePath != null && filePath is String && filePath.isNotEmpty) {
              request.files.add(
                await http.MultipartFile.fromPath(
                  'attachments',
                  filePath,
                  filename: file['name'],
                ),
              );
            }
          }

          final streamedResponse = await request.send();
          response = await http.Response.fromStream(streamedResponse);
        } else if (isTemporaryMode.value) {
          data['userId'] = userId;
          data['companyId'] = companyId;
          data['branchId'] = branchId;
          url = Uri.parse('${ApiConfig.baseUrl}/temporary-gc/create');
          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
        }
        // Handle filling temporary GC (User completes and converts)
        else if (isFillTemporaryMode.value && tempGcNumber.value.isNotEmpty) {
          try {
            data['actualGcNumber'] = gcNumberCtrl.text;
            data['userId'] = userId;
            data['companyId'] = companyId;
            data['branchId'] = branchId;

            // Double-check lock status right before submission
            final lockStatus = await _checkLockStatus(tempGcNumber.value);
            if (lockStatus['isLocked'] == true) {
              throw Exception('Lost lock on the temporary GC. Please try again.');
            }

            // Convert the temporary GC to a real GC
            url = Uri.parse(
              '${ApiConfig.baseUrl}/temporary-gc/convert/${tempGcNumber.value}',
            );
            response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(data),
            );

            if (response.statusCode != 200) {
              throw Exception(
                'Failed to convert temporary GC: ${response.statusCode}',
              );
            }

            final responseData = jsonDecode(response.body);
            if (responseData['success'] != true) {
              throw Exception(
                responseData['message'] ?? 'Failed to convert temporary GC',
              );
            }
            // The submit-gc endpoint is already called in the backend during conversion
            // No need to call it again from the frontend
            // Release the lock after successful conversion
            await http
                .post(
                  Uri.parse('${ApiConfig.baseUrl}/temporary-gc/release-lock'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'gcNumber': tempGcNumber.value,
                    'userId': userId,
                    'force': true, // Add force flag to ensure release
                  }),
                )
                .catchError((e) {
                  debugPrint('Error releasing lock: $e');
                  // Return a dummy response to satisfy the type system
                  // The actual response doesn't matter since we're in an error case
                  return http.Response('', 200);
                });
          } catch (e) {
            // Attempt to release the lock on error
            try {
              await http.post(
                Uri.parse('${ApiConfig.baseUrl}/temporary-gc/release-lock'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'gcNumber': tempGcNumber.value,
                  'userId': userId,
                  'force': true,
                }),
              );
            } catch (releaseError) {
              debugPrint('Error releasing lock after error: $releaseError');
            }
            rethrow; // Re-throw the original error
          }
        }
        // Handle regular GC creation
        else {
          final url = Uri.parse('${ApiConfig.baseUrl}/gc/add').replace(
            queryParameters: {
              'userId': userId,
              'companyId': _idController.companyId.value,
              if (_idController.branchId.value.isNotEmpty)
                'branchId': _idController.branchId.value,
            },
          );

          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
        }
      }

      isLoading.value = false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        String message;
        if (isTemporaryMode.value) {
          final responseData = jsonDecode(response.body);
          final tempGcNum =
              responseData['data']?['temp_gc_number'] ?? 'Unknown';
          message = 'Temporary GC created: $tempGcNum';
        } else if (isFillTemporaryMode.value) {
          message = 'GC created successfully from template!';
        } else if (isEditMode.value) {
          message = 'GC updated successfully!';
        } else {
          message = 'GC created successfully!';
        }

        _showToast(
          message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFF4A90E2),
          textColor: Colors.white,
        );

        // If a new GC was created, signal the GCUsageWidget to refresh
        if (!isEditMode.value && !isTemporaryMode.value) {
          _idController.gcDataNeedsRefresh.value = true;
        }

        clearForm();

        // Reset temporary modes
        isTemporaryMode.value = false;
        isFillTemporaryMode.value = false;
        tempGcNumber.value = '';

        Get.until((route) => route.isFirst);
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      isLoading.value = false;
      final operation = isEditMode.value ? 'update' : 'create';
      _showToast(
        'Failed to $operation GC: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // File attachment methods
  Future<void> pickFiles(BuildContext context) async {
    try {
      isPickingFiles.value = true;

      // First try multiple file selection
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        int addedCount = 0;
        for (final file in result.files) {
          if (file.size > 10 * 1024 * 1024) { // 10MB limit
            _showToast(
              'File "${file.name}" is too large. Maximum size is 10MB.',
              backgroundColor: Colors.red,
            );
            continue;
          }

          // Check if file already exists
          final existingIndex = attachedFiles.indexWhere(
            (f) => f['name'] == file.name && f['size'] == file.size
          );

          if (existingIndex >= 0) {
            _showToast(
              'File "${file.name}" is already attached.',
              backgroundColor: Colors.orange,
            );
            continue;
          }

          attachedFiles.add({
            'name': file.name,
            'path': file.path,
            'size': file.size,
            'extension': file.extension,
            'bytes': file.bytes,
          });
          addedCount++;
        }

        if (addedCount > 0) {
          _showToast(
            'Added $addedCount file(s) successfully.',
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (e) {
      print('Multiple file selection failed: $e');

      // Check if this is the specific dart:io error
      if (e.toString().contains('dart io') || e.toString().contains('multiple file')) {
        // Fall back to single file selection
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
            withData: false,
            withReadStream: false,
          );

          if (result != null && result.files.isNotEmpty) {
            final file = result.files.first;

            if (file.size > 10 * 1024 * 1024) {
              _showToast(
                'File "${file.name}" is too large. Maximum size is 10MB.',
                backgroundColor: Colors.red,
              );
              return;
            }

            // Check if file already exists
            final existingIndex = attachedFiles.indexWhere(
              (f) => f['name'] == file.name && f['size'] == file.size
            );

            if (existingIndex >= 0) {
              _showToast(
                'File "${file.name}" is already attached.',
                backgroundColor: Colors.orange,
              );
              return;
            }

            attachedFiles.add({
              'name': file.name,
              'path': file.path,
              'size': file.size,
              'extension': file.extension,
              'bytes': file.bytes,
            });

            _showToast(
              'Added "${file.name}" successfully.',
              backgroundColor: Colors.green,
            );
          }
        } catch (fallbackError) {
          print('Single file selection also failed: $fallbackError');
          _showToast(
            'Failed to pick files. This platform may not support file selection.',
            backgroundColor: Colors.red,
          );
        }
      } else {
        // Some other error occurred
        _showToast(
          'Failed to pick files. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      isPickingFiles.value = false;
    }
  }

  void removeFile(int index) {
    if (index >= 0 && index < attachedFiles.length) {
      final fileName = attachedFiles[index]['name'];
      attachedFiles.removeAt(index);
      _showToast(
        'Removed "$fileName"',
        backgroundColor: Colors.blue,
      );
    }
  }

  void clearAllFiles() {
    final count = attachedFiles.length;
    attachedFiles.clear();
    if (count > 0) {
      _showToast(
        'Removed all $count file(s)',
        backgroundColor: Colors.blue,
      );
    }
  }

  // Fetch existing attachments for editing GCs
  Future<void> fetchExistingAttachments(String gcNumber) async {
    try {
      isLoadingAttachments.value = true;
      attachmentsError.value = '';
      existingAttachments.clear();

      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;

      if (companyId.isEmpty) {
        attachmentsError.value = 'Company ID not found';
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/gc/attachments/$gcNumber').replace(
        queryParameters: {
          'companyId': companyId,
          if (branchId.isNotEmpty) 'branchId': branchId,
        },
      );

      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final attachments = data['data']['attachments'] as List<dynamic>? ?? [];
          existingAttachments.assignAll(
            attachments.map((attachment) => {
              'name': attachment['originalName']?.toString() ?? 'Unknown',
              'filename': attachment['filename']?.toString() ?? '',
              'size': attachment['size'] ?? 0,
              'type': attachment['mimeType']?.toString() ?? 'unknown',
              'uploadedAt': attachment['uploadDate']?.toString() ?? '',
              'uploadedBy': attachment['uploadedBy']?.toString() ?? '',
            }).toList(),
          );
        }
      } else {
        attachmentsError.value = 'Failed to fetch attachments';
      }
    } catch (e) {
      attachmentsError.value = 'Error fetching attachments: $e';
      debugPrint('Error fetching attachments: $e');
    } finally {
      isLoadingAttachments.value = false;
    }
  }

}
