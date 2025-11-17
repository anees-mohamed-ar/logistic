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
  final TextEditingController _pageController = TextEditingController(text: '1');

  // Table view mode
  bool _isCardView = false;

  int get totalGCs => filteredGcList.length;
  double get totalHireAmount =>
      filteredGcList.fold(0, (sum, gc) => sum + _parseDouble(gc['HireAmount']));
  double get totalAdvanceAmount =>
      filteredGcList.fold(0, (sum, gc) => sum + _parseDouble(gc['AdvanceAmount']));
  double get totalFreightCharge =>
      filteredGcList.fold(0, (sum, gc) => sum + _parseDouble(gc['FreightCharge']));

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
    _totalGCsAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _totalHireAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _totalAdvanceAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _totalFreightAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
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
        return gc.values.any((value) =>
        value?.toString().toLowerCase().contains(_searchQuery) ?? false);
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
      end: totalHireAmount,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _totalAdvanceAnim = Tween<double>(
      begin: 0,
      end: totalAdvanceAmount,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _totalFreightAnim = Tween<double>(
      begin: 0,
      end: totalFreightCharge,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
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
      final fileName = 'GC_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${downloadDir.path}/$fileName';

      debugPrint('Generating Excel file to: $filePath');

      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
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
      final excel.Sheet sheet = workbook['GC_Report'];

      // Define headers
      final headers = [
        'GC Number',
        'Date',
        'Truck',
        'PO Number',
        'Trip ID',
        'Broker',
        'Driver',
        'Consignor',
        'Consignee',
        'Packages',
        'Weight (kg)',
        'Rate',
        'Hire Amount',
        'Advance',
        'Freight',
      ];

      final fieldKeys = [
        'GcNumber',
        'GcDate',
        'TruckNumber',
        'PoNumber',
        'TripId',
        'BrokerName',
        'DriverName',
        'ConsignorName',
        'ConsigneeName',
        'NumberofPkg',
        'ActualWeightKgs',
        'Rate',
        'HireAmount',
        'AdvanceAmount',
        'FreightCharge',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
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

          // Format currency fields
          if (['HireAmount', 'AdvanceAmount', 'FreightCharge'].contains(key)) {
            value = _parseDouble(value);
            final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
            cell.value = excel.DoubleCellValue(value);
            cell.cellStyle = excel.CellStyle(
              fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
              fontSize: 11,
              numberFormat: excel.NumFormat.standard_2,
            );
          } else {
            // Handle null values and convert to string
            final displayValue = value?.toString() ?? '';
            final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
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

      // Show success message
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    try {
      // Create Excel workbook
      final excel.Excel workbook = excel.Excel.createExcel();
      final excel.Sheet sheet = workbook['GC_Report'];

      // Define headers
      final headers = [
        'GC Number',
        'Date',
        'Truck',
        'PO Number',
        'Trip ID',
        'Broker',
        'Driver',
        'Consignor',
        'Consignee',
        'Packages',
        'Weight (kg)',
        'Rate',
        'Hire Amount',
        'Advance',
        'Freight',
      ];

      final fieldKeys = [
        'GcNumber',
        'GcDate',
        'TruckNumber',
        'PoNumber',
        'TripId',
        'BrokerName',
        'DriverName',
        'ConsignorName',
        'ConsigneeName',
        'NumberofPkg',
        'ActualWeightKgs',
        'Rate',
        'HireAmount',
        'AdvanceAmount',
        'FreightCharge',
      ];

      // Add headers
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
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

          // Format currency fields
          if (['HireAmount', 'AdvanceAmount', 'FreightCharge'].contains(key)) {
            value = _parseDouble(value);
            final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
            cell.value = excel.DoubleCellValue(value);
            cell.cellStyle = excel.CellStyle(
              fontFamily: excel.getFontFamily(excel.FontFamily.Calibri),
              fontSize: 11,
              numberFormat: excel.NumFormat.standard_2,
            );
          } else {
            // Handle null values and convert to string
            final displayValue = value?.toString() ?? '';
            final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
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

      // Get temporary directory for sharing
      final directory = await getTemporaryDirectory();
      final fileName = 'GC_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      // Save file
      final fileBytes = workbook.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Share the file
        final xFile = XFile(filePath);
        await Share.shareXFiles([xFile], text: 'GC Report Export');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file shared: $fileName')),
        );
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      print('Excel share error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final bottomPadding = isMobile ? 80.0 : 24.0;

    return Scaffold(
      appBar: _buildAppBar(isMobile),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: RefreshIndicator(
          onRefresh: fetchGCList,
          child: isLoading
              ? _buildLoadingState()
              : error != null
                  ? _buildErrorState()
                  : _buildMainContent(isMobile, isTablet),
        ),
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
      backgroundColor: const Color(0xFF1E2A44),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading GC Report...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchGCList,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          const SliverToBoxAdapter(
            child: _EmptyState(),
          )
        else if (_isCardView && isMobile)
          _buildCardView()
        else
          _buildTableView(isMobile),
      ],
    );
  }

  Widget _buildSummaryCards(bool isMobile, bool isTablet) {
    final cards = [
      _SummaryCardData('Total GCs', _totalGCsAnim, Icons.assignment, const Color(0xFF3B82F6), true),
      _SummaryCardData('Total Hire', _totalHireAnim, Icons.currency_rupee, const Color(0xFF10B981), false),
      _SummaryCardData('Total Advance', _totalAdvanceAnim, Icons.account_balance_wallet, const Color(0xFFF59E0B), false),
      _SummaryCardData('Total Freight', _totalFreightAnim, Icons.local_shipping, const Color(0xFF8B5CF6), false),
    ];

    if (isMobile) {
      return SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _buildAnimatedSummaryCard(cards[i], isMobile),
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
        itemBuilder: (context, i) => _buildAnimatedSummaryCard(cards[i], isMobile),
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
                cardData.color.withOpacity(0.02)
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SliverList _buildCardView() {
    final int itemCount = filteredGcList.length;
    final int totalPages = itemCount == 0 ? 1 : (itemCount / _rowsPerPage).ceil();
    _currentPage = _currentPage.clamp(0, totalPages - 1);
    final int startIndex = _currentPage * _rowsPerPage;
    final int endIndex = math.min(startIndex + _rowsPerPage, itemCount);
    final List<Map<String, dynamic>> pageData = filteredGcList.sublist(
      startIndex,
      endIndex,
    );

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
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
        },
        childCount: pageData.length + 1,
      ),
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
                  child: Text(
                    'GC #${gc['GcNumber'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            _buildCardRow('Driver', gc['DriverName']),
            _buildCardRow('Broker', gc['BrokerName']),
            _buildCardRow('Consignor', gc['ConsignorName']),
            _buildCardRow('Consignee', gc['ConsigneeName']),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAmountChip(
                    'Hire',
                    _formatCurrency(_parseDouble(gc['HireAmount'])),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAmountChip(
                    'Advance',
                    _formatCurrency(_parseDouble(gc['AdvanceAmount'])),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAmountChip(
                    'Freight',
                    _formatCurrency(_parseDouble(gc['FreightCharge'])),
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRow(String label, dynamic value) {
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
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChip(String label, String amount, Color color) {
    // Create darker variants of the color for text
    final darkerColor = Color.alphaBlend(Colors.black.withOpacity(0.3), color);
    final evenDarkerColor = Color.alphaBlend(Colors.black.withOpacity(0.5), color);
    
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
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: evenDarkerColor,
              height: 1.1,
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
      'PO Number',
      'Trip ID',
      'Broker',
      'Driver',
      'Consignor',
      'Consignee',
      'Packages',
      'Weight (kg)',
      'Rate',
      'Hire Amount',
      'Advance',
      'Freight',
    ];

    final fieldKeys = [
      'GcNumber',
      'GcDate',
      'TruckNumber',
      'PoNumber',
      'TripId',
      'BrokerName',
      'DriverName',
      'ConsignorName',
      'ConsigneeName',
      'NumberofPkg',
      'ActualWeightKgs',
      'Rate',
      'HireAmount',
      'AdvanceAmount',
      'FreightCharge',
    ];

    // Pagination calculations
    final int itemCount = filteredGcList.length;
    final int totalPages = itemCount == 0 ? 1 : (itemCount / _rowsPerPage).ceil();
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
              color: const Color(0xFF1E3A8A).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'GC Entries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const Spacer(),
                Text(
                  'Showing ${startIndex + 1}–$endIndex of $itemCount entries',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - (isMobile ? 24 : 32),
              ),
              child: DataTable(
                headingRowHeight: 56,
                dataRowHeight: 56,
                headingRowColor: MaterialStateProperty.all(
                  Colors.grey.shade50,
                ),
                columns: columns
                    .map((c) => DataColumn(
                  label: Expanded(
                    child: Text(
                      c,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ))
                    .toList(),
                rows: pageData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final Color? rowColor = index % 2 == 0
                      ? Colors.white
                      : Colors.grey[50]; // Changed from shade25 to [50]
                  return DataRow(
                    color: MaterialStateProperty.all(rowColor),
                    cells: fieldKeys.map((key) {
                      String displayValue = item[key]?.toString() ?? '';

                      // Format currency fields
                      if (['HireAmount', 'AdvanceAmount', 'FreightCharge'].contains(key)) {
                        displayValue = _formatCurrency(_parseDouble(item[key]));
                      }

                      return DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            displayValue,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: ['HireAmount', 'AdvanceAmount', 'FreightCharge'].contains(key)
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: ['HireAmount', 'AdvanceAmount', 'FreightCharge'].contains(key)
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.black87,
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
                    .map((v) => DropdownMenuItem<int>(
                  value: v,
                  child: Text('$v'),
                ))
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
                    onPressed: _currentPage > 0 ? () => goToPage(_currentPage - 1) : null,
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
                      .map((v) => DropdownMenuItem<int>(
                    value: v,
                    child: Text('$v'),
                  ))
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
                  backgroundColor: _currentPage > 0 ? Colors.grey.shade100 : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0 ? () => goToPage(_currentPage - 1) : null,
                tooltip: 'Previous page',
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage > 0 ? Colors.grey.shade100 : null,
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1
                    ? () => goToPage(_currentPage + 1)
                    : null,
                tooltip: 'Next page',
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage < totalPages - 1 ? Colors.grey.shade100 : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages - 1
                    ? () => goToPage(totalPages - 1)
                    : null,
                tooltip: 'Last page',
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage < totalPages - 1 ? Colors.grey.shade100 : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// Helper classes
class _SummaryCardData {
  final String label;
  final Animation<double> animation;
  final IconData icon;
  final Color color;
  final bool isCount;

  _SummaryCardData(this.label, this.animation, this.icon, this.color, this.isCount);
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
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}