import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:logistic/api_config.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class GCReportPage extends StatefulWidget {
  const GCReportPage({Key? key}) : super(key: key);

  @override
  State<GCReportPage> createState() => _GCReportPageState();
}

class _GCReportPageState extends State<GCReportPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> gcList = [];
  List<Map<String, dynamic>> filteredGcList = [];
  bool isLoading = true;
  String? error;
  late AnimationController _controller;
  late Animation<double> _totalGCsAnim,
      _totalHireAnim,
      _totalAdvanceAnim,
      _totalFreightAnim;
  late final IdController _idController;

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination
  int _rowsPerPage = 10;
  int _currentPage = 0;
  final TextEditingController _pageController = TextEditingController(
    text: '1',
  );

  // Table view mode
  bool _isCardView = false;

  // Calculate meaningful metrics
  int get totalGCs => filteredGcList.length;
  int get totalWithAttachments => filteredGcList
      .where((gc) => (gc['attachment_count'] as int? ?? 0) > 0)
      .length;
  int get totalPaid => filteredGcList
      .where((gc) => (gc['PaymentDetails']?.toString().isNotEmpty ?? false))
      .length;
  double get avgWeight => filteredGcList.isEmpty
      ? 0.0
      : filteredGcList.fold(
              0.0,
              (sum, gc) => sum + _parseDouble(gc['ActualWeightKgs']),
            ) /
            filteredGcList.length;

  @override
  void initState() {
    super.initState();
    _idController = Get.find<IdController>();
    fetchGCList();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _setupAnimations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _totalGCsAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _totalHireAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _totalAdvanceAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _totalFreightAnim = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterData();
      _currentPage = 0;
      _pageController.text = '1';
    });
  }

  void _filterData() {
    if (_searchQuery.isEmpty) {
      filteredGcList = List.from(gcList);
    } else {
      filteredGcList = gcList.where((gc) {
        return gc.values.any(
          (value) =>
              value?.toString().toLowerCase().contains(_searchQuery) ?? false,
        );
      }).toList();
    }
    _updateAnimations();
  }

  void _updateAnimations() {
    _totalGCsAnim = Tween<double>(
      begin: 0,
      end: totalGCs.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _totalHireAnim = Tween<double>(
      begin: 0,
      end: totalWithAttachments.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _totalAdvanceAnim = Tween<double>(
      begin: 0,
      end: totalPaid.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _totalFreightAnim = Tween<double>(
      begin: 0,
      end: avgWeight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  Future<void> fetchGCList() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final companyId = _idController.companyId.value;
      final branchId = _idController.branchId.value;
      final uri = Uri.parse('${ApiConfig.baseUrl}/gc/search').replace(
        queryParameters: {
          'companyId': companyId,
          if (branchId.isNotEmpty) 'branchId': branchId,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          gcList = data.cast<Map<String, dynamic>>();
          filteredGcList = List.from(gcList);
          isLoading = false;
        });
        _updateAnimations();
      } else {
        setState(() {
          error = 'Failed to load GC report: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load GC report: $e';
        isLoading = false;
      });
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    try {
      return double.parse(value.toString());
    } catch (_) {
      return 0.0;
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Future<void> _downloadExcel() async {
    if (filteredGcList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    Directory? downloadDir;

    try {
      debugPrint('📊 Starting Excel export process...');

      // Request storage permissions
      if (Platform.isAndroid) {
        debugPrint('Checking Android storage permission...');

        // First show explanation dialog
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs storage permission to download and save Excel files to your device. '
              'Files will be saved to your Downloads folder.',
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
          debugPrint(
            'WRITE_EXTERNAL_STORAGE denied, trying MANAGE_EXTERNAL_STORAGE...',
          );
          status = await Permission.manageExternalStorage.request();
          debugPrint('MANAGE_EXTERNAL_STORAGE permission result: $status');
        }

        debugPrint('Final permission granted: ${status.isGranted}');
        debugPrint('Final permission denied: ${status.isDenied}');
        debugPrint(
          'Final permission permanently denied: ${status.isPermanentlyDenied}',
        );

        if (!status.isGranted) {
          debugPrint('Permission not granted, showing snackbar...');
          if (mounted) {
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
                          await _downloadExcel();
                        },
                      ),
                duration: const Duration(seconds: 8),
              ),
            );
          }
          return;
        } else {
          debugPrint('Permission granted, proceeding with Excel generation...');
        }
      }

      // Get download directory
      if (Platform.isAndroid) {
        // Try Downloads folder first (Android 10 and below, or with MANAGE_EXTERNAL_STORAGE)
        downloadDir = Directory('/storage/emulated/0/Download');

        if (!await downloadDir.exists()) {
          // Fallback to external storage directory
          final externalDir = await getExternalStorageDirectory();

          if (externalDir != null && await externalDir.exists()) {
            downloadDir = externalDir;
          } else {
            // Final fallback: app documents directory
            downloadDir = await getApplicationDocumentsDirectory();
          }
        }

        // Create Download subfolder in app documents if using app directory
        if (downloadDir.path.contains('app_flutter')) {
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

      // Create full file path
      final fileName =
          'GC_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${downloadDir.path}/$fileName';

      debugPrint('Generating Excel file to: $filePath');

      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating Excel file...'),
              ],
            ),
          ),
        );
      }

      // Create Excel workbook
      final excel.Excel workbook = excel.Excel.createExcel();

      // Remove all default sheets and create our custom sheet
      workbook.delete('Sheet1');

      final excel.Sheet sheet = workbook['GC_Report'];

      // Ensure no other sheets exist
      final sheetNames = workbook.sheets.keys.toList();
      for (final sheetName in sheetNames) {
        if (sheetName != 'GC_Report') {
          workbook.delete(sheetName);
        }
      }

      // Define headers
      final headers = [
        'GC Number',
        'Date',
        'Truck',
        'Truck Type',
        'From',
        'To',
        'Driver',
        'Consignor',
        'Consignee',
        'Packages',
        'Weight (kg)',
        'Delivery Date',
        'Payment',
        'Invoice',
        'E-Way',
      ];

      final fieldKeys = [
        'GcNumber',
        'GcDate',
        'TruckNumber',
        'TruckType',
        'TruckFrom',
        'TruckTo',
        'DriverName',
        'ConsignorName',
        'ConsigneeName',
        'NumberofPkg',
        'ActualWeightKgs',
        'DeliveryDate',
        'PaymentDetails',
        'invoice_attachment',
        'e_way_attachment',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = excel.TextCellValue(headers[i]);
        // Make header bold
        cell.cellStyle = excel.CellStyle(
          fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
          bold: true,
          fontSize: 12,
        );
      }

      // Add data rows
      for (int rowIndex = 0; rowIndex < filteredGcList.length; rowIndex++) {
        final gc = filteredGcList[rowIndex];
        for (int colIndex = 0; colIndex < fieldKeys.length; colIndex++) {
          final key = fieldKeys[colIndex];
          dynamic value = gc[key];

          // Format date fields
          if (['GcDate', 'DeliveryDate'].contains(key)) {
            final displayValue = _formatDate(value?.toString() ?? '');
            final cell = sheet.cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            );
            cell.value = excel.TextCellValue(displayValue);
            cell.cellStyle = excel.CellStyle(
              fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
              fontSize: 11,
            );
          }
          // Format invoice and e-way attachment status
          else if (['invoice_attachment', 'e_way_attachment'].contains(key)) {
            final hasAttachment =
                value?.toString().isNotEmpty == true &&
                value?.toString() != 'null';
            final displayValue = hasAttachment ? 'Yes' : 'No';
            final cell = sheet.cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            );
            cell.value = excel.TextCellValue(displayValue);
            cell.cellStyle = excel.CellStyle(
              fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
              fontSize: 11,
              horizontalAlign: excel.HorizontalAlign.Center,
            );
          } else {
            // Handle null values and convert to string
            final displayValue = value?.toString() ?? '';
            final cell = sheet.cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            );
            cell.value = excel.TextCellValue(displayValue);
            cell.cellStyle = excel.CellStyle(
              fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
              fontSize: 11,
            );
          }
        }
      }

      // Auto-fit columns (approximate width based on content)
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15.0); // Set reasonable width
      }

      // Save file
      final fileBytes = workbook.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        debugPrint('✅ Successfully saved Excel file: $filePath');
      } else {
        throw Exception('Failed to encode Excel file');
      }

      // Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show success message with open location button
      if (mounted) {
        final location =
            downloadDir.path.contains('Download') ||
                downloadDir.path.contains('Downloads')
            ? 'Downloads folder'
            : 'app storage';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Excel file downloaded successfully to $location: $fileName',
            ),
            action: SnackBarAction(
              label: 'Open Location',
              onPressed: () => _openFileLocation(filePath),
            ),
            duration: const Duration(
              seconds: 5,
            ), // Keep it visible longer for action
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Excel download error: $e');

      // Close progress dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _shareExcel() async {
    if (filteredGcList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    // Show loading dialog while generating Excel
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating Excel file...'),
          ],
        ),
      ),
    );

    try {
      // Create Excel workbook
      final excel.Excel workbook = excel.Excel.createExcel();

      // Remove all default sheets and create our custom sheet
      workbook.delete('Sheet1');

      final excel.Sheet sheet = workbook['GC_Report'];

      // Ensure no other sheets exist
      final sheetNames = workbook.sheets.keys.toList();
      for (final sheetName in sheetNames) {
        if (sheetName != 'GC_Report') {
          workbook.delete(sheetName);
        }
      }

      // Define headers
      final headers = [
        'GC Number',
        'Date',
        'Truck',
        'Truck Type',
        'From',
        'To',
        'Driver',
        'Consignor',
        'Consignee',
        'Packages',
        'Weight (kg)',
        'Delivery Date',
        'Payment',
        'Invoice',
        'E-Way',
      ];

      final fieldKeys = [
        'GcNumber',
        'GcDate',
        'TruckNumber',
        'TruckType',
        'TruckFrom',
        'TruckTo',
        'DriverName',
        'ConsignorName',
        'ConsigneeName',
        'NumberofPkg',
        'ActualWeightKgs',
        'DeliveryDate',
        'PaymentDetails',
        'invoice_attachment',
        'e_way_attachment',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = excel.TextCellValue(headers[i]);
        // Make header bold
        cell.cellStyle = excel.CellStyle(
          fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
          bold: true,
          fontSize: 12,
        );
      }

      // Add data rows
      for (int rowIndex = 0; rowIndex < filteredGcList.length; rowIndex++) {
        final gc = filteredGcList[rowIndex];
        for (int colIndex = 0; colIndex < fieldKeys.length; colIndex++) {
          final key = fieldKeys[colIndex];
          dynamic value = gc[key];

          // Format date fields
          if (['GcDate', 'DeliveryDate'].contains(key)) {
            final displayValue = _formatDate(value?.toString() ?? '');
            final cell = sheet.cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            );
            cell.value = excel.TextCellValue(displayValue);
            cell.cellStyle = excel.CellStyle(
              fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
              fontSize: 11,
            );
          }
          // Format invoice and e-way attachment status
          else if (['invoice_attachment', 'e_way_attachment'].contains(key)) {
            final hasAttachment =
                value?.toString().isNotEmpty == true &&
                value?.toString() != 'null';
            final displayValue = hasAttachment ? 'Yes' : 'No';
            final cell = sheet.cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            );
            cell.value = excel.TextCellValue(displayValue);
            cell.cellStyle = excel.CellStyle(
              fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
              fontSize: 11,
              horizontalAlign: excel.HorizontalAlign.Center,
            );
          } else {
            // Handle null values and convert to string
            final displayValue = value?.toString() ?? '';
            final cell = sheet.cell(
              excel.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1,
              ),
            );
            cell.value = excel.TextCellValue(displayValue);
            cell.cellStyle = excel.CellStyle(
              fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
              fontSize: 11,
            );
          }
        }
      }

      // Get temporary directory for sharing
      final directory = await getTemporaryDirectory();
      final fileName =
          'GC_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      // Auto-fit columns for better readability
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15.0); // Set reasonable width
      }

      // Save file
      final fileBytes = workbook.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Close loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Share the file
        final xFile = XFile(filePath);
        await Share.shareXFiles([xFile], text: 'GC Report Export');

        // Clean up temporary file after sharing (whether successful or cancelled)
        try {
          if (await file.exists()) {
            await file.delete();
            debugPrint('Temporary file deleted: $filePath');
          }
        } catch (e) {
          debugPrint('Failed to delete temporary file: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Excel file ready for sharing: $fileName')),
          );
        }
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Excel share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      appBar: _buildAppBar(isMobile),
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: fetchGCList,
        child: isLoading
            ? _buildLoadingState()
            : error != null
            ? _buildErrorState()
            : _buildMainContent(isMobile, isTablet),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      title: Text(
        'GC Report',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 18 : 20,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Always show view toggle in app bar for both mobile and desktop
        IconButton(
          icon: Icon(_isCardView ? Icons.table_chart : Icons.view_agenda),
          onPressed: () => setState(() => _isCardView = !_isCardView),
          tooltip: _isCardView ? 'Switch to Table View' : 'Switch to Card View',
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _downloadExcel,
          tooltip: 'Download Excel',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareExcel,
          tooltip: 'Share Excel',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: fetchGCList,
          tooltip: 'Refresh Data',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading GC Report...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchGCList,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isMobile, bool isTablet) {
    return CustomScrollView(
      slivers: [
        // Summary Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: _buildSummaryCards(isMobile, isTablet),
          ),
        ),

        // Search and Controls
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12.0 : 16.0,
              vertical: 8.0,
            ),
            child: _buildSearchAndControls(isMobile),
          ),
        ),

        // Data Table/Cards
        if (filteredGcList.isEmpty)
          const SliverToBoxAdapter(child: _EmptyState())
        else if (_isCardView && isMobile)
          _buildCardView()
        else
          _buildTableView(isMobile),
      ],
    );
  }

  Widget _buildSummaryCards(bool isMobile, bool isTablet) {
    final primary = Theme.of(context).primaryColor;
    final cards = [
      _SummaryCardData(
        'Total GCs',
        _totalGCsAnim,
        Icons.assignment,
        primary,
        true,
      ),
      _SummaryCardData(
        'With Attachments',
        _totalHireAnim,
        Icons.attach_file,
        const Color(0xFF10B981),
        true,
      ),
      _SummaryCardData(
        'Paid GCs',
        _totalAdvanceAnim,
        Icons.payments,
        const Color(0xFFF59E0B),
        true,
      ),
      _SummaryCardData(
        'Avg Weight (kg)',
        _totalFreightAnim,
        Icons.monitor_weight,
        const Color(0xFF8B5CF6),
        false,
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) =>
              _buildAnimatedSummaryCard(cards[i], isMobile),
        ),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 2 : 4,
          childAspectRatio: isTablet ? 2.5 : 2.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: cards.length,
        itemBuilder: (context, i) =>
            _buildAnimatedSummaryCard(cards[i], isMobile),
      );
    }
  }

  Widget _buildAnimatedSummaryCard(_SummaryCardData cardData, bool isMobile) {
    return AnimatedBuilder(
      animation: cardData.animation,
      builder: (context, child) => Card(
        elevation: 2,
        shadowColor: cardData.color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: isMobile ? 160 : null,
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardData.color.withOpacity(0.08),
                cardData.color.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardData.color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cardData.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      cardData.icon,
                      color: cardData.color,
                      size: isMobile ? 18 : 22,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.trending_up,
                    color: cardData.color.withOpacity(0.6),
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                cardData.isCount
                    ? cardData.animation.value.toInt().toString()
                    : _formatCurrency(cardData.animation.value),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 16 : 20,
                  color: cardData.color,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cardData.label,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndControls(bool isMobile) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search GC records...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${filteredGcList.length} records',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            if (isMobile && filteredGcList.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${filteredGcList.length} records found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SliverList _buildCardView() {
    final int itemCount = filteredGcList.length;
    final int totalPages = itemCount == 0
        ? 1
        : (itemCount / _rowsPerPage).ceil();
    _currentPage = _currentPage.clamp(0, totalPages - 1);
    final int startIndex = _currentPage * _rowsPerPage;
    final int endIndex = math.min(startIndex + _rowsPerPage, itemCount);
    final List<Map<String, dynamic>> pageData = filteredGcList.sublist(
      startIndex,
      endIndex,
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == pageData.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPaginationControls(totalPages, true),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _buildGCCard(pageData[index]),
        );
      }, childCount: pageData.length + 1),
    );
  }

  Widget _buildGCCard(Map<String, dynamic> gc) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showGCOptions(gc),
                    child: Text(
                      'GC #${gc['GcNumber'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    gc['TruckNumber'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCardRow('Date', gc['GcDate']),
            _buildCardRow('Truck Type', gc['TruckType']),
            _buildCardRow(
              'Route',
              '${gc['TruckFrom'] ?? 'N/A'} → ${gc['TruckTo'] ?? 'N/A'}',
            ),
            _buildCardRow('Driver', gc['DriverName']),
            _buildCardRow('Consignor', gc['ConsignorName']),
            _buildCardRow('Consignee', gc['ConsigneeName']),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Packages',
                    gc['NumberofPkg']?.toString() ?? '0',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    'Weight',
                    '${gc['ActualWeightKgs'] ?? '0'} kg',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    'Payment',
                    (gc['PaymentDetails']?.toString().isEmpty ?? true)
                        ? 'Pending'
                        : gc['PaymentDetails'],
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Invoice and E-Way attachment status
            Row(
              children: [
                Expanded(
                  child: _buildAttachmentChip(
                    (gc['invoice_attachment']?.toString().isNotEmpty ??
                            false) &&
                        gc['invoice_attachment']?.toString() != 'null',
                    'invoice_attachment',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttachmentChip(
                    (gc['e_way_attachment']?.toString().isNotEmpty ?? false) &&
                        gc['e_way_attachment']?.toString() != 'null',
                    'e_way_attachment',
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()), // Spacer for alignment
              ],
            ),
            const SizedBox(height: 8),
            // Attachments row - clickable
            if ((gc['attachment_count'] as int? ?? 0) > 0)
              InkWell(
                onTap: () => _navigateToAttachments(gc),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${gc['attachment_count']} attachment(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewInGCList(gc),
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: const Text('View in List'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Download button hidden
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRow(String label, dynamic value) {
    // Format date specifically for GcDate
    String displayValue = value?.toString() ?? 'N/A';
    if (label == 'Date' && displayValue != 'N/A') {
      displayValue = _formatDate(displayValue);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format date properly
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';

    try {
      // Try to parse the date string
      DateTime date;

      // Handle different date formats
      if (dateString.contains('T')) {
        // ISO format: 2024-01-15T10:30:00.000Z
        date = DateTime.parse(dateString);
      } else if (dateString.contains('-')) {
        // Simple format: 2024-01-15
        date = DateTime.parse(dateString);
      } else if (dateString.contains('/')) {
        // Format like 15/01/2024
        final parts = dateString.split('/');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        } else {
          return dateString; // Return original if can't parse
        }
      } else {
        return dateString; // Return original if format is unknown
      }

      // Format to DD/MM/YYYY
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      // If parsing fails, return original string
      return dateString;
    }
  }

  // Helper method to open file location
  Future<void> _openFileLocation(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Copy filename to clipboard for easy searching
        final fileName = filePath.split('/').last;
        await Clipboard.setData(ClipboardData(text: fileName));

        // Show brief toast that filename was copied
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Filename copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        if (Platform.isWindows) {
          // For Windows, open the folder and select the file
          await Process.run('explorer', ['/select,', filePath]);
        } else if (Platform.isAndroid) {
          // For Android, prioritize opening the Downloads folder to avoid app selection issues
          bool fileOpened = false;

          // First try to open the Downloads folder using MediaStore content URI
          try {
            final downloadsUri = Uri.parse(
              'content://com.android.externalstorage.documents/document/primary%3ADownload',
            );
            if (await canLaunchUrl(downloadsUri)) {
              await launchUrl(downloadsUri);
              fileOpened = true;
            }
          } catch (e) {
            debugPrint('Downloads folder opening failed: $e');
          }

          // If folder opening fails, try file-specific content URI (may highlight file)
          if (!fileOpened) {
            try {
              final encodedFileName = Uri.encodeComponent(fileName);
              final fileContentUri = Uri.parse(
                'content://com.android.externalstorage.documents/document/primary%3ADownload%2F$encodedFileName',
              );

              if (await canLaunchUrl(fileContentUri)) {
                await launchUrl(fileContentUri);
                fileOpened = true;
              }
            } catch (e) {
              debugPrint('File-specific content URI failed: $e');
            }
          }

          // Final fallback: show file path dialog with highlighting info
          if (!fileOpened) {
            _showFilePathDialog(filePath, showHighlightInfo: true);
          }
        } else if (Platform.isIOS) {
          // For iOS, try to open the parent directory
          final directory = file.parent;
          final uri = Uri.directory(directory.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        } else {
          // Fallback: try to open the parent directory
          final directory = file.parent;
          final uri = Uri.directory(directory.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening file location: $e');
      // Show file path dialog as fallback
      _showFilePathDialog(filePath);
    }
  }

  // Helper method to show file path in a dialog
  void _showFilePathDialog(String filePath, {bool showHighlightInfo = false}) {
    if (mounted) {
      final fileName = filePath.split('/').last;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('File Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showHighlightInfo
                      ? 'Your file has been saved to this location:'
                      : 'Your Excel file has been saved to:',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    filePath,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (showHighlightInfo) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Look for this file:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  showHighlightInfo
                      ? 'Open your file manager app, navigate to the Downloads folder, and look for the highlighted file above.'
                      : 'Please open your file manager app and navigate to this location to find your file.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    // Create darker variants of the color for text
    final darkerColor = Color.alphaBlend(Colors.black.withOpacity(0.3), color);
    final evenDarkerColor = Color.alphaBlend(
      Colors.black.withOpacity(0.5),
      color,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: darkerColor,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: evenDarkerColor,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentChip(bool hasAttachment, String type) {
    final isInvoice = type == 'invoice_attachment';
    final color = hasAttachment ? Colors.green : Colors.red;
    final icon = isInvoice ? Icons.receipt : Icons.description;
    final text = hasAttachment ? 'Yes' : 'No';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildTableView(bool isMobile) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 16.0),
        child: _buildPaginatedTable(isMobile),
      ),
    );
  }

  Widget _buildPaginatedTable(bool isMobile) {
    if (filteredGcList.isEmpty) {
      return const SizedBox.shrink();
    }

    final columns = [
      'GC Number',
      'Date',
      'Truck',
      'Truck Type',
      'From',
      'To',
      'Driver',
      'Consignor',
      'Consignee',
      'Packages',
      'Weight (kg)',
      'Delivery Date',
      'Payment',
      'Invoice',
      'E-Way',
    ];

    final fieldKeys = [
      'GcNumber',
      'GcDate',
      'TruckNumber',
      'TruckType',
      'TruckFrom',
      'TruckTo',
      'DriverName',
      'ConsignorName',
      'ConsigneeName',
      'NumberofPkg',
      'ActualWeightKgs',
      'DeliveryDate',
      'PaymentDetails',
      'invoice_attachment',
      'e_way_attachment',
    ];

    // Pagination calculations
    final int itemCount = filteredGcList.length;
    final int totalPages = itemCount == 0
        ? 1
        : (itemCount / _rowsPerPage).ceil();
    _currentPage = _currentPage.clamp(0, totalPages - 1);
    final int startIndex = _currentPage * _rowsPerPage;
    final int endIndex = math.min(startIndex + _rowsPerPage, itemCount);
    final List<Map<String, dynamic>> pageData = filteredGcList.sublist(
      startIndex,
      endIndex,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'GC Entries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  'Showing ${startIndex + 1}–$endIndex of $itemCount entries',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Scrollable table with fixed GC number column
          Row(
            children: [
              // Fixed GC number column
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 56,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'GC Number',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Data rows
                    ...pageData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final Color? rowColor = index % 2 == 0
                          ? Colors.white
                          : Colors.grey[50];

                      return Container(
                        height: 56,
                        color: rowColor,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: () => _showGCOptions(item),
                          child: Text(
                            item['GcNumber']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              // Scrollable other columns
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth:
                          MediaQuery.of(context).size.width -
                          152, // Account for fixed column
                    ),
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowHeight: 56,
                      dataRowHeight: 56,
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade50,
                      ),
                      columns: columns
                          .skip(1)
                          .map(
                            // Skip GC number column
                            (c) => DataColumn(
                              label: Expanded(
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      rows: pageData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final Color? rowColor = index % 2 == 0
                            ? Colors.white
                            : Colors.grey[50];
                        return DataRow(
                          color: MaterialStateProperty.all(rowColor),
                          onSelectChanged: (selected) {
                            if (selected == true) {
                              _showGCOptions(item);
                            }
                          },
                          cells: fieldKeys.skip(1).map((key) {
                            // Skip GC number field
                            String displayValue = item[key]?.toString() ?? '';

                            // Format date fields
                            if (key == 'GcDate' || key == 'DeliveryDate') {
                              displayValue = _formatDate(displayValue);
                            }
                            // Format invoice and e-way attachment status
                            else if (key == 'invoice_attachment' ||
                                key == 'e_way_attachment') {
                              final hasAttachment =
                                  displayValue.isNotEmpty &&
                                  displayValue != 'null';
                              displayValue = hasAttachment ? 'Yes' : 'No';
                            }
                            // Format payment details with better styling
                            else if (key == 'PaymentDetails') {
                              displayValue = displayValue.isEmpty
                                  ? 'Pending'
                                  : displayValue;
                            }

                            return DataCell(
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 140,
                                ),
                                child:
                                    key == 'invoice_attachment' ||
                                        key == 'e_way_attachment'
                                    ? _buildAttachmentChip(
                                        displayValue == 'Yes',
                                        key,
                                      )
                                    : Text(
                                        displayValue,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Pagination controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50], // Changed from shade25 to [50]
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: _buildPaginationControls(totalPages, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages, bool isMobile) {
    void goToPage(int page) {
      if (page >= 0 && page < totalPages) {
        setState(() {
          _currentPage = page;
          _pageController.text = (page + 1).toString();
        });
      }
    }

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              const Text('Rows per page:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _rowsPerPage,
                items: const [5, 10, 20, 50]
                    .map(
                      (v) => DropdownMenuItem<int>(value: v, child: Text('$v')),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _rowsPerPage = v;
                      _currentPage = 0;
                      _pageController.text = '1';
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${_currentPage + 1} of $totalPages',
                style: const TextStyle(fontSize: 14),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => goToPage(_currentPage - 1)
                        : null,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages - 1
                        ? () => goToPage(_currentPage + 1)
                        : null,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Rows per page selector
          Row(
            children: [
              const Text(
                'Rows per page:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  underline: const SizedBox(),
                  items: const [5, 10, 20, 50, 100]
                      .map(
                        (v) =>
                            DropdownMenuItem<int>(value: v, child: Text('$v')),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _rowsPerPage = v;
                        _currentPage = 0;
                        _pageController.text = '1';
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Page navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 0 ? () => goToPage(0) : null,
                tooltip: 'First page',
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage > 0
                      ? Colors.grey.shade100
                      : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => goToPage(_currentPage - 1)
                    : null,
                tooltip: 'Previous page',
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage > 0
                      ? Colors.grey.shade100
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Page',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: _pageController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (value) {
                    final p = int.tryParse(value) ?? 1;
                    if (p >= 1 && p <= totalPages) {
                      goToPage(p - 1);
                    } else {
                      _pageController.text = (_currentPage + 1).toString();
                    }
                  },
                ),
              ),
              Text(
                ' of $totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1
                    ? () => goToPage(_currentPage + 1)
                    : null,
                tooltip: 'Next page',
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage < totalPages - 1
                      ? Colors.grey.shade100
                      : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages - 1
                    ? () => goToPage(totalPages - 1)
                    : null,
                tooltip: 'Last page',
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage < totalPages - 1
                      ? Colors.grey.shade100
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Feature-rich action methods
  void _navigateToAttachments(Map<String, dynamic> gc) {
    final gcNumber = gc['GcNumber']?.toString() ?? '';
    final gcId = gc['Id']?.toString() ?? '';

    if (gcNumber.isEmpty) {
      Get.snackbar(
        'Error',
        'GC Number not found',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Navigate to attachments page
    Get.toNamed(
      '/gc_attachments',
      arguments: {
        'gcNumber': gcNumber,
        'gcId': gcId,
        'companyId': _idController.companyId.value,
        'branchId': _idController.branchId.value,
      },
    );
  }

  void _showGCOptions(Map<String, dynamic> gc) {
    final gcNumber = gc['GcNumber']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GC #$gcNumber Options',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.blue),
              title: const Text('View in GC List'),
              subtitle: const Text('Highlight in GC list view'),
              onTap: () {
                Navigator.of(context).pop();
                _viewInGCList(gc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.green),
              title: const Text('View Attachments'),
              subtitle: const Text('See all attached files'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToAttachments(gc);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _viewInGCList(Map<String, dynamic> gc) {
    final gcId = gc['Id']?.toString() ?? '';
    final gcNumber = gc['GcNumber']?.toString() ?? '';

    if (gcId.isEmpty) {
      Get.snackbar(
        'Error',
        'GC ID not found',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.snackbar(
      'Opening GC List',
      'Navigating to GC #$gcNumber...',
      backgroundColor: Theme.of(context).primaryColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    // Navigate to GC list with highlighting
    Get.toNamed('/gc_list', arguments: {'highlightGcId': gcId});
  }
}

// Helper classes
class _SummaryCardData {
  final String label;
  final Animation<double> animation;
  final IconData icon;
  final Color color;
  final bool isCount;

  _SummaryCardData(
    this.label,
    this.animation,
    this.icon,
    this.color,
    this.isCount,
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No GC Records Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria or check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
