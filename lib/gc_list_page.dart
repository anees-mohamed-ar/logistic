import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:logistic/gc_form_screen.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'api_config.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GCListPage extends StatefulWidget {
  const GCListPage({Key? key}) : super(key: key);

  @override
  State<GCListPage> createState() => _GCListPageState();
}

class _GCListPageState extends State<GCListPage> {
  List<Map<String, dynamic>> gcList = [];
  List<Map<String, dynamic>> filteredGcList = [];
  bool isLoading = true;
  String? error;
  final searchController = TextEditingController();

  // Filter state
  String? selectedBranchFilter;
  String? selectedPaymentFilter;
  String? selectedTruckTypeFilter;
  DateTimeRange? dateRangeFilter;

  // Sort state
  String sortBy = 'GcDate'; // Default sort
  bool sortAscending = false; // Default descending (newest first)

  // Available options for filters
  List<String> branches = [];
  List<String> paymentMethods = [];
  List<String> truckTypes = [];

  @override
  void initState() {
    super.initState();
    fetchGCList();
  }

  Future<void> fetchGCList() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/gc/search');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);
        if (decodedData is List) {
          setState(() {
            gcList = List<Map<String, dynamic>>.from(decodedData.whereType<Map<String, dynamic>>());
            _extractFilterOptions();
            _applyFiltersAndSort();
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Failed to load GC list: Unexpected data format';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load GC list: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load GC list: $e';
        isLoading = false;
      });
    }
  }

  void _extractFilterOptions() {
    // Extract unique values for filter dropdowns
    branches = gcList
        .map((gc) => gc['Branch']?.toString())
        .where((b) => b != null && b.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    paymentMethods = gcList
        .map((gc) => gc['PaymentDetails']?.toString())
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    truckTypes = gcList
        .map((gc) => gc['TruckType']?.toString())
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> result = List.from(gcList);

    // Apply search filter
    if (searchController.text.isNotEmpty) {
      final query = searchController.text.toLowerCase();
      result = result.where((gc) {
        return (gc['GcNumber']?.toString().toLowerCase().contains(query) ?? false) ||
            (gc['TruckNumber']?.toString().toLowerCase().contains(query) ?? false) ||
            (gc['PoNumber']?.toString().toLowerCase().contains(query) ?? false) ||
            (gc['TripId']?.toString().toLowerCase().contains(query) ?? false) ||
            (gc['DriverName']?.toString().toLowerCase().contains(query) ?? false) ||
            (gc['ConsignorName']?.toString().toLowerCase().contains(query) ?? false) ||
            (gc['Branch']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply branch filter
    if (selectedBranchFilter != null) {
      result = result.where((gc) => gc['Branch']?.toString() == selectedBranchFilter).toList();
    }

    // Apply payment filter
    if (selectedPaymentFilter != null) {
      result = result.where((gc) => gc['PaymentDetails']?.toString() == selectedPaymentFilter).toList();
    }

    // Apply truck type filter
    if (selectedTruckTypeFilter != null) {
      result = result.where((gc) => gc['TruckType']?.toString() == selectedTruckTypeFilter).toList();
    }

    // Apply date range filter
    if (dateRangeFilter != null) {
      result = result.where((gc) {
        final gcDate = gc['GcDate']?.toString();
        if (gcDate == null || gcDate.isEmpty) return false;
        try {
          final date = DateTime.parse(gcDate);
          return date.isAfter(dateRangeFilter!.start.subtract(const Duration(days: 1))) &&
              date.isBefore(dateRangeFilter!.end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Apply sorting
    result.sort((a, b) {
      dynamic aValue = a[sortBy];
      dynamic bValue = b[sortBy];

      // Handle null values
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return sortAscending ? -1 : 1;
      if (bValue == null) return sortAscending ? 1 : -1;

      // Parse dates for date fields
      if (sortBy == 'GcDate' || sortBy == 'DeliveryDate' || sortBy == 'created_at') {
        try {
          final aDate = DateTime.parse(aValue.toString());
          final bDate = DateTime.parse(bValue.toString());
          return sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        } catch (e) {
          return 0;
        }
      }

      // Parse numbers for numeric fields
      if (sortBy == 'HireAmount' || sortBy == 'FreightCharge' || sortBy == 'AdvanceAmount' || sortBy == 'km') {
        try {
          final aNum = double.parse(aValue.toString());
          final bNum = double.parse(bValue.toString());
          return sortAscending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
        } catch (e) {
          return 0;
        }
      }

      // String comparison for other fields
      final comparison = aValue.toString().compareTo(bValue.toString());
      return sortAscending ? comparison : -comparison;
    });

    setState(() {
      filteredGcList = result;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter & Sort',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Sort Section
                      const Text(
                        'Sort By',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSortChip('GC Date', 'GcDate', setModalState),
                          _buildSortChip('Created Date', 'created_at', setModalState),
                          _buildSortChip('GC Number', 'GcNumber', setModalState),
                          _buildSortChip('Delivery Date', 'DeliveryDate', setModalState),
                          _buildSortChip('Hire Amount', 'HireAmount', setModalState),
                          _buildSortChip('Freight Charge', 'FreightCharge', setModalState),
                          _buildSortChip('Distance', 'km', setModalState),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Filter Section
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Branch Filter
                      _buildFilterDropdown(
                        'Branch',
                        selectedBranchFilter,
                        branches,
                            (value) => setModalState(() => selectedBranchFilter = value),
                      ),
                      const SizedBox(height: 16),

                      // Payment Method Filter
                      _buildFilterDropdown(
                        'Payment Method',
                        selectedPaymentFilter,
                        paymentMethods,
                            (value) => setModalState(() => selectedPaymentFilter = value),
                      ),
                      const SizedBox(height: 16),

                      // Truck Type Filter
                      _buildFilterDropdown(
                        'Truck Type',
                        selectedTruckTypeFilter,
                        truckTypes,
                            (value) => setModalState(() => selectedTruckTypeFilter = value),
                      ),
                      const SizedBox(height: 16),

                      // Date Range Filter
                      _buildDateRangeFilter(setModalState),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            selectedBranchFilter = null;
                            selectedPaymentFilter = null;
                            selectedTruckTypeFilter = null;
                            dateRangeFilter = null;
                            sortBy = 'GcDate';
                            sortAscending = false;
                          });
                          setState(() {});
                          _applyFiltersAndSort();
                        },
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          _applyFiltersAndSort();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2A44),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String field, StateSetter setModalState) {
    final isSelected = sortBy == field;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          if (sortBy == field) {
            sortAscending = !sortAscending;
          } else {
            sortBy = field;
            sortAscending = field == 'GcNumber'; // Ascending for GC Number, descending for others
          }
        });
      },
      selectedColor: const Color(0xFF1E2A44).withOpacity(0.2),
      checkmarkColor: const Color(0xFF1E2A44),
    );
  }

  Widget _buildFilterDropdown(
      String label,
      String? value,
      List<String> options,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text('All $label'),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('All $label'),
                ),
                ...options.map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                )),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GC Date Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: dateRangeFilter,
            );
            if (picked != null) {
              setModalState(() => dateRangeFilter = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateRangeFilter == null
                      ? 'Select date range'
                      : '${_formatDisplayDate(dateRangeFilter!.start.toString())} - ${_formatDisplayDate(dateRangeFilter!.end.toString())}',
                  style: TextStyle(
                    color: dateRangeFilter == null ? Colors.grey : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    if (dateRangeFilter != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setModalState(() => dateRangeFilter = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (selectedBranchFilter != null) count++;
    if (selectedPaymentFilter != null) count++;
    if (selectedTruckTypeFilter != null) count++;
    if (dateRangeFilter != null) count++;
    return count;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFF7F9FC),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _checkAndNavigateToGCForm,
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add GC'),
      ),
    );
  }

  Future<void> _checkAndNavigateToGCForm() async {
    final idController = Get.find<IdController>();
    final userId = idController.userId.value;

    if (userId.isEmpty) {
      Fluttertoast.showToast(
        msg: 'User ID not found. Please login again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final gcFormController = Get.put(GCFormController());

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final hasAccess = await gcFormController.checkGCAccess(userId);

      if (Get.isDialogOpen ?? false) Get.back();

      if (hasAccess) {
        Get.to(() => const GCFormScreen());
      } else {
        Get.snackbar(
          'Access Denied',
          gcFormController.accessMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'Error',
        'Failed to check GC access: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final activeFilters = _getActiveFilterCount();
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GC Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Goods Consignment List', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E2A44),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterBottomSheet,
              tooltip: 'Filter & Sort',
            ),
            if (activeFilters > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeFilters',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${filteredGcList.length} GCs',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: searchController,
            onChanged: (value) => _applyFiltersAndSort(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by GC Number, Truck, Driver, etc...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white70),
                onPressed: () {
                  searchController.clear();
                  _applyFiltersAndSort();
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white54, width: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (error != null) {
      return _buildErrorState();
    }

    if (filteredGcList.isEmpty) {
      return _buildEmptyState();
    }

    return _buildGCList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E2A44)),
          SizedBox(height: 16),
          Text(
            'Loading GC records...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchGCList,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                searchController.text.isNotEmpty || _getActiveFilterCount() > 0
                    ? Icons.search_off
                    : Icons.description,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchController.text.isNotEmpty || _getActiveFilterCount() > 0
                  ? 'No matching GCs found'
                  : 'No GC records available',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchController.text.isNotEmpty || _getActiveFilterCount() > 0
                  ? 'Try adjusting your filters or search criteria'
                  : 'GC records will appear here once created',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (searchController.text.isNotEmpty || _getActiveFilterCount() > 0)
              ElevatedButton.icon(
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    selectedBranchFilter = null;
                    selectedPaymentFilter = null;
                    selectedTruckTypeFilter = null;
                    dateRangeFilter = null;
                  });
                  _applyFiltersAndSort();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2A44),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGCList() {
    return RefreshIndicator(
      onRefresh: fetchGCList,
      color: const Color(0xFF1E2A44),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredGcList.length,
        itemBuilder: (context, index) {
          final gc = filteredGcList[index];
          return _buildGCCard(gc, index);
        },
      ),
    );
  }

  Widget _buildGCCard(Map<String, dynamic> gc, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: const ExpansionTileThemeData(
            tilePadding: EdgeInsets.zero,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: EdgeInsets.zero,
          title: _buildCardHeader(gc),
          subtitle: _buildCardSubtitle(gc),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditGC(gc))
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () => _editGC(gc),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit GC',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A44).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.expand_more,
                  color: Color(0xFF1E2A44),
                ),
              ),
            ],
          ),
          children: [
            _buildCardDetails(gc),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> gc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A44),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            gc['GcNumber'] ?? 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gc['TruckNumber'] ?? 'No Truck',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              if (gc['DriverName']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  'Driver: ${gc['DriverName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardSubtitle(Map<String, dynamic> gc) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _buildInfoChip(Icons.business, gc['Branch']),
          const SizedBox(width: 8),
          if (gc['GcDate']?.toString().isNotEmpty == true)
            _buildInfoChip(Icons.calendar_today, _formatDisplayDate(gc['GcDate'])),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails(Map<String, dynamic> gc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
            'Trip Information',
            Icons.local_shipping,
            [
              _infoRow('PO Number', gc['PoNumber']),
              _infoRow('Trip ID', gc['TripId']),
              _infoRow('Distance (KM)', gc['km']),
              _infoRow('Route', '${gc['TruckFrom'] ?? ''} → ${gc['TruckTo'] ?? ''}'),
            ],
          ),

          const SizedBox(height: 16),

          _buildDetailSection(
            'Parties Information',
            Icons.people,
            [
              _infoRow('Broker', gc['BrokerName']),
              _infoRow('Consignor', gc['ConsignorName']),
              _infoRow('Consignor GST', gc['ConsignorGst']),
              _infoRow('Consignor Address', gc['ConsignorAddress']),
              _infoRow('Consignee', gc['ConsigneeName']),
              _infoRow('Consignee GST', gc['ConsigneeGst']),
              _infoRow('Consignee Address', gc['ConsigneeAddress']),
            ],
          ),

          const SizedBox(height: 16),

          _buildDetailSection(
            'Goods Information',
            Icons.inventory,
            [
              _infoRow('Packages', gc['NumberofPkg']),
              _infoRow('Package Method', gc['MethodofPkg']),
              _infoRow('Actual Weight (kg)', gc['ActualWeightKgs']),
              _infoRow('Goods Description', gc['GoodContain']),
            ],
          ),

          const SizedBox(height: 16),

          _buildDetailSection(
            'Financial Details',
            Icons.account_balance_wallet,
            [
              _infoRow('Rate', gc['Rate']),
              _infoRow('Hire Amount', gc['HireAmount']),
              _infoRow('Advance Amount', gc['AdvanceAmount']),
              _infoRow('Freight Charge', gc['FreightCharge']),
              _infoRow('Payment Method', gc['PaymentDetails']),
            ],
          ),

          const SizedBox(height: 20),

          if (_canEditGC(gc))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _editGC(gc),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit GC Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    final validChildren = children.where((child) => child is! SizedBox || child.height != 0).toList();

    if (validChildren.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1E2A44)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: validChildren,
          ),
        ),
      ],
    );
  }

  String _formatDisplayDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  bool _canEditGC(Map<String, dynamic> gc) {
    final createdAt = gc['created_at']?.toString();
    if (createdAt == null || createdAt.isEmpty) return false;

    try {
      final createdDate = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now().toLocal();
      final difference = now.difference(createdDate);
      final hoursDifference = difference.inHours;
      final isWithin24Hours = hoursDifference < 24 ||
          (hoursDifference == 24 && difference.inMinutes % 60 == 0);

      debugPrint('GC ${gc['GcNumber']} - Created: $createdAt, '
          'Local: $createdDate, Now: $now, '
          'Diff: ${difference.inHours}h ${difference.inMinutes % 60}m, '
          'Can Edit: $isWithin24Hours');

      return isWithin24Hours;
    } catch (e) {
      debugPrint('Error parsing date for GC ${gc['GcNumber']}: $e');
      return false;
    }
  }

  void _editGC(Map<String, dynamic> gc) {
    if (!_canEditGC(gc)) {
      Fluttertoast.showToast(
        msg: 'Cannot edit: GC can only be edited within 24 hours of creation',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final idController = Get.find<IdController>();
    final companyId = idController.companyId.value;

    final gcController = Get.put(GCFormController(), permanent: false);
    gcController.clearForm();
    gcController.isEditMode.value = true;
    gcController.editingGcNumber.value = gc['GcNumber']?.toString() ?? '';
    gcController.editingCompanyId.value = companyId;

    if (gcController.weightRates.isEmpty) {
      gcController.fetchWeightRates().then((_) {
        _populateFormWithGCData(gcController, gc, companyId);
      });
    } else {
      _populateFormWithGCData(gcController, gc, companyId);
    }

    Get.to(
          () => const GCFormScreen(),
      preventDuplicates: false,
    );
  }

  void _populateFormWithGCData(GCFormController controller, Map<String, dynamic> gc, String companyId) {
    controller.gcNumberCtrl.text = gc['GcNumber']?.toString() ?? '';
    controller.isEditMode.value = true;
    controller.editingGcNumber.value = gc['GcNumber']?.toString() ?? '';
    controller.editingCompanyId.value = companyId;

    controller.selectedBranch.value = gc['Branch']?.toString() ?? 'Select Branch';

    if (gc['GcDate'] != null) {
      try {
        final gcDate = DateTime.parse(gc['GcDate'].toString());
        controller.gcDate.value = gcDate;
        controller.gcDateCtrl.text = controller.formatDate(gcDate);
      } catch (e) {}
    }

    if (gc['DeliveryDate'] != null) {
      try {
        final deliveryDate = DateTime.parse(gc['DeliveryDate'].toString());
        controller.deliveryDate.value = deliveryDate;
        controller.deliveryDateCtrl.text = controller.formatDate(deliveryDate);
      } catch (e) {}
    }

    controller.selectedTruck.value = gc['TruckNumber']?.toString() ?? 'Select Truck';
    controller.truckNumberCtrl.text = gc['TruckNumber']?.toString() ?? '';
    controller.truckTypeCtrl.text = gc['TruckType']?.toString() ?? '';
    controller.poNumberCtrl.text = gc['PoNumber']?.toString() ?? '';
    controller.tripIdCtrl.text = gc['TripId']?.toString() ?? '';

    controller.fromCtrl.text = gc['TruckFrom']?.toString() ?? '';
    controller.toCtrl.text = gc['TruckTo']?.toString() ?? '';

    controller.selectedBroker.value = gc['BrokerName']?.toString() ?? 'Select Broker';
    controller.brokerNameCtrl.text = gc['BrokerName']?.toString() ?? '';
    controller.selectedDriver.value = gc['DriverName']?.toString() ?? '';
    controller.driverNameCtrl.text = gc['DriverName']?.toString() ?? '';
    controller.driverPhoneCtrl.text = gc['DriverPhoneNumber']?.toString() ?? '';

    controller.selectedConsignor.value = gc['ConsignorName']?.toString() ?? 'Select Consignor';
    controller.consignorNameCtrl.text = gc['ConsignorName']?.toString() ?? '';
    controller.consignorGstCtrl.text = gc['ConsignorGst']?.toString() ?? '';
    controller.consignorAddressCtrl.text = gc['ConsignorAddress']?.toString() ?? '';

    final consigneeAddress = gc['ConsigneeAddress']?.toString() ?? '';
    controller.selectedConsignee.value = gc['ConsigneeName']?.toString() ?? 'Select Consignee';
    controller.consigneeNameCtrl.text = gc['ConsigneeName']?.toString() ?? '';
    controller.consigneeGstCtrl.text = gc['ConsigneeGst']?.toString() ?? '';
    controller.consigneeAddressCtrl.text = consigneeAddress;

    final weight = gc['ActualWeightKgs']?.toString() ?? '';
    final natureOfGoods = gc['GoodContain']?.toString() ?? '';
    final methodOfPkg = (gc['MethodofPkg']?.toString() ?? '').isNotEmpty
        ? gc['MethodofPkg'].toString()
        : 'Boxes';

    controller.weightCtrl.text = weight;
    controller.natureOfGoodsCtrl.text = natureOfGoods;
    controller.natureGoodsCtrl.text = natureOfGoods;

    final formattedMethod = (methodOfPkg?.isNotEmpty ?? false)
        ? '${methodOfPkg![0].toUpperCase()}${methodOfPkg.substring(1).toLowerCase()}'
        : 'Boxes';
    controller.methodPackageCtrl.text = formattedMethod;
    controller.selectedPackageMethod.value = formattedMethod;

    controller.packagesCtrl.text = gc['NumberofPkg']?.toString() ?? '';
    controller.actualWeightCtrl.text = weight;
    controller.remarksCtrl.text = gc['PrivateMark']?.toString() ?? '';
    controller.billingAddressCtrl.text = consigneeAddress;

    controller.actualWeightCtrl.text = gc['ActualWeightKgs']?.toString() ?? '';
    controller.kmCtrl.text = gc['km']?.toString() ?? '';
    controller.rateCtrl.text = gc['Rate']?.toString() ?? '';

    if (weight.isNotEmpty) {
      controller.selectWeightForActualWeight(weight);
    } else {
      controller.selectedWeight.value = null;
      controller.calculateRate();
    }

    controller.update();

    controller.hireAmountCtrl.text = gc['HireAmount']?.toString() ?? '';
    controller.advanceAmountCtrl.text = gc['AdvanceAmount']?.toString() ?? '';
    controller.deliveryAddressCtrl.text = gc['DeliveryAddress']?.toString() ?? '';
    if ((controller.freightChargeCtrl.text).isEmpty) {
      controller.freightChargeCtrl.text = gc['FreightCharge']?.toString() ?? '';
    }
    controller.selectedPayment.value = gc['PaymentDetails']?.toString() ?? 'Cash';

    controller.customInvoiceCtrl.text = gc['CustInvNo']?.toString() ?? '';
    controller.deliveryInstructionsCtrl.text = gc['DeliveryFromSpecial']?.toString() ?? '';
    controller.invValueCtrl.text = gc['InvValue']?.toString() ?? '';
    controller.ewayBillCtrl.text = gc['EInv']?.toString() ?? '';

    if (gc['EInvDate'] != null) {
      try {
        final ewayDate = DateTime.parse(gc['EInvDate'].toString());
        controller.ewayBillDate.value = ewayDate;
        controller.ewayBillDateCtrl.text = controller.formatDate(ewayDate);
      } catch (e) {}
    }

    controller.eDaysCtrl.text = gc['Eda']?.toString() ?? '';

    if (gc['EBillExpDate'] != null) {
      try {
        final ewayExpDate = DateTime.parse(gc['EBillExpDate'].toString());
        controller.ewayExpired.value = ewayExpDate;
        controller.ewayExpiredCtrl.text = controller.formatDate(ewayExpDate);
      } catch (e) {}
    }
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
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
}
