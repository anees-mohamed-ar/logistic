import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/truck_controller.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/models/truck.dart';
import 'package:logistic/views/truck/truck_form_page.dart';
import 'package:logistic/views/truck/truck_attachments_page.dart';
import 'package:logistic/widgets/custom_app_bar.dart';

enum TruckSortBy {
  vehicleNumber,
  ownerName,
  dateAdded,
  insuranceExpiry,
  roadTaxExpiry,
}

enum TruckFilterBy { all, insuranceExpiringSoon, taxExpiringSoon, activeOnly }

class TruckListPage extends StatefulWidget {
  const TruckListPage({super.key});

  @override
  State<TruckListPage> createState() => _TruckListPageState();
}

class _TruckListPageState extends State<TruckListPage> {
  final TruckController controller = Get.put(TruckController());
  final searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  TruckSortBy _currentSort = TruckSortBy.vehicleNumber;
  bool _sortAscending = true;
  TruckFilterBy _currentFilter = TruckFilterBy.all;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    controller.fetchTrucks();

    searchController.addListener(() {
      _applyFiltersAndSort();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          controller.hasMore.value &&
          !controller.isLoading.value) {
        controller.loadMore();
      }
    });
  }

  void _applyFiltersAndSort() {
    var trucks = controller.trucks.toList();

    // Apply search
    final query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      trucks = trucks.where((truck) {
        return truck.vechileNumber.toLowerCase().contains(query) ||
            (truck.ownerName?.toLowerCase().contains(query) ?? false) ||
            (truck.ownerMobileNumber?.contains(query) ?? false) ||
            (truck.engineeNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply filters
    final now = DateTime.now();
    switch (_currentFilter) {
      case TruckFilterBy.insuranceExpiringSoon:
        trucks = trucks.where((truck) {
          if (truck.insuranceExpDate == null) return false;
          final expDate = DateTime.tryParse(truck.insuranceExpDate!);
          if (expDate == null) return false;
          final daysUntilExpiry = expDate.difference(now).inDays;
          return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
        }).toList();
        break;
      case TruckFilterBy.taxExpiringSoon:
        trucks = trucks.where((truck) {
          if (truck.roadTaxExpDate == null) return false;
          final expDate = DateTime.tryParse(truck.roadTaxExpDate!);
          if (expDate == null) return false;
          final daysUntilExpiry = expDate.difference(now).inDays;
          return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
        }).toList();
        break;
      case TruckFilterBy.activeOnly:
        trucks = trucks.where((truck) {
          final hasValidInsurance = _isDateValid(truck.insuranceExpDate);
          final hasValidTax = _isDateValid(truck.roadTaxExpDate);
          return hasValidInsurance || hasValidTax;
        }).toList();
        break;
      case TruckFilterBy.all:
        break;
    }

    // Apply sorting
    trucks.sort((a, b) {
      int comparison = 0;
      switch (_currentSort) {
        case TruckSortBy.vehicleNumber:
          comparison = a.vechileNumber.compareTo(b.vechileNumber);
          break;
        case TruckSortBy.ownerName:
          comparison = (a.ownerName ?? '').compareTo(b.ownerName ?? '');
          break;
        case TruckSortBy.dateAdded:
          comparison = (a.id ?? 0).compareTo(b.id ?? 0);
          break;
        case TruckSortBy.insuranceExpiry:
          final aDate = DateTime.tryParse(a.insuranceExpDate ?? '');
          final bDate = DateTime.tryParse(b.insuranceExpDate ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          comparison = aDate.compareTo(bDate);
          break;
        case TruckSortBy.roadTaxExpiry:
          final aDate = DateTime.tryParse(a.roadTaxExpDate ?? '');
          final bDate = DateTime.tryParse(b.roadTaxExpDate ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          comparison = aDate.compareTo(bDate);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    controller.visibleTrucks.value = trucks;
  }

  bool _isDateValid(String? dateStr) {
    if (dateStr == null) return false;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    return date.isAfter(DateTime.now());
  }

  int _getDaysUntilExpiry(String? dateStr) {
    if (dateStr == null) return -999;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return -999;
    return date.difference(DateTime.now()).inDays;
  }

  Color _getExpiryColor(int days) {
    if (days < 0) return Colors.red;
    if (days <= 7) return Colors.red;
    if (days <= 30) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSortOption(TruckSortBy.vehicleNumber, 'Vehicle Number'),
            _buildSortOption(TruckSortBy.ownerName, 'Owner Name'),
            _buildSortOption(TruckSortBy.dateAdded, 'Date Added'),
            _buildSortOption(TruckSortBy.insuranceExpiry, 'Insurance Expiry'),
            _buildSortOption(TruckSortBy.roadTaxExpiry, 'Road Tax Expiry'),
            const Divider(height: 32),
            SwitchListTile(
              title: const Text('Ascending Order'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() {
                  _sortAscending = value;
                  _applyFiltersAndSort();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(TruckSortBy sortBy, String label) {
    return RadioListTile<TruckSortBy>(
      title: Text(label),
      value: sortBy,
      groupValue: _currentSort,
      activeColor: const Color(0xFF1E2A44),
      onChanged: (value) {
        setState(() {
          _currentSort = value!;
          _applyFiltersAndSort();
        });
        Navigator.pop(context);
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter By',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption(
              TruckFilterBy.all,
              'All Trucks',
              Icons.local_shipping,
            ),
            _buildFilterOption(
              TruckFilterBy.insuranceExpiringSoon,
              'Insurance Expiring Soon (30 days)',
              Icons.warning_amber,
            ),
            _buildFilterOption(
              TruckFilterBy.taxExpiringSoon,
              'Road Tax Expiring Soon (30 days)',
              Icons.receipt_long,
            ),
            _buildFilterOption(
              TruckFilterBy.activeOnly,
              'Active Trucks Only',
              Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(TruckFilterBy filter, String label, IconData icon) {
    return RadioListTile<TruckFilterBy>(
      title: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
      value: filter,
      groupValue: _currentFilter,
      activeColor: const Color(0xFF1E2A44),
      onChanged: (value) {
        setState(() {
          _currentFilter = value!;
          _applyFiltersAndSort();
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Truck Management'),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.visibleTrucks.isEmpty &&
            controller.searchQuery.value.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty &&
            controller.visibleTrucks.isEmpty &&
            controller.searchQuery.value.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.fetchTrucks,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2A44),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search trucks...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                _applyFiltersAndSort();
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter and Sort Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showFilterOptions,
                          icon: const Icon(Icons.filter_list, size: 18),
                          label: Text(
                            _getFilterLabel(),
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E2A44),
                            side: BorderSide(
                              color: _currentFilter != TruckFilterBy.all
                                  ? const Color(0xFF1E2A44)
                                  : Colors.grey.shade300,
                              width: _currentFilter != TruckFilterBy.all
                                  ? 2
                                  : 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showSortOptions,
                          icon: Icon(
                            _sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 18,
                          ),
                          label: Text(
                            _getSortLabel(),
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E2A44),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _isGridView = !_isGridView;
                            });
                          },
                          icon: Icon(
                            _isGridView ? Icons.list : Icons.grid_view,
                            size: 20,
                          ),
                          color: const Color(0xFF1E2A44),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  // Results count
                  if (controller.visibleTrucks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${controller.visibleTrucks.length} truck(s) found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Trucks List/Grid
            Expanded(
              child: controller.visibleTrucks.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () async {
                        await controller.refreshTrucks();
                        _applyFiltersAndSort();
                      },
                      child: _isGridView ? _buildGridView() : _buildListView(),
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(() => const TruckFormPage());
          if (result == true) {
            _applyFiltersAndSort();
          }
        },
        backgroundColor: const Color(0xFF1E2A44),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Truck', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _getFilterLabel() {
    switch (_currentFilter) {
      case TruckFilterBy.all:
        return 'All';
      case TruckFilterBy.insuranceExpiringSoon:
        return 'Insurance';
      case TruckFilterBy.taxExpiringSoon:
        return 'Tax';
      case TruckFilterBy.activeOnly:
        return 'Active';
    }
  }

  String _getSortLabel() {
    switch (_currentSort) {
      case TruckSortBy.vehicleNumber:
        return 'Vehicle #';
      case TruckSortBy.ownerName:
        return 'Owner';
      case TruckSortBy.dateAdded:
        return 'Date';
      case TruckSortBy.insuranceExpiry:
        return 'Insurance';
      case TruckSortBy.roadTaxExpiry:
        return 'Tax';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchController.text.isNotEmpty ||
                    _currentFilter != TruckFilterBy.all
                ? Icons.search_off
                : Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            searchController.text.isNotEmpty ||
                    _currentFilter != TruckFilterBy.all
                ? 'No trucks match your criteria'
                : 'No trucks added yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchController.text.isNotEmpty ||
                    _currentFilter != TruckFilterBy.all
                ? 'Try adjusting your filters'
                : 'Add your first truck to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount:
          controller.visibleTrucks.length + (controller.hasMore.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= controller.visibleTrucks.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final truck = controller.visibleTrucks[index];
        return _buildTruckCard(truck);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: controller.visibleTrucks.length,
      itemBuilder: (context, index) {
        final truck = controller.visibleTrucks[index];
        return _buildTruckGridCard(truck);
      },
    );
  }

  Widget _buildTruckCard(Truck truck) {
    final insuranceDays = _getDaysUntilExpiry(truck.insuranceExpDate);
    final taxDays = _getDaysUntilExpiry(truck.roadTaxExpDate);
    final hasWarning = insuranceDays <= 30 || taxDays <= 30;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasWarning
            ? BorderSide(color: Colors.orange.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          Get.put(GCFormController());
          final result = await Get.to(() => TruckFormPage(truck: truck));
          if (result == true) {
            _applyFiltersAndSort();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A44).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF1E2A44),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          truck.vechileNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2A44),
                          ),
                        ),
                        if (truck.typeofVechile != null)
                          Text(
                            truck.typeofVechile!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasWarning)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Owner Info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      truck.ownerName ?? 'No owner',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (truck.ownerMobileNumber != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      truck.ownerMobileNumber!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Expiry Status
              Row(
                children: [
                  Expanded(
                    child: _buildExpiryChip(
                      'Insurance',
                      insuranceDays,
                      Icons.shield,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildExpiryChip(
                      'Road Tax',
                      taxDays,
                      Icons.receipt_long,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.attach_file,
                    label: 'Files',
                    color: Colors.blue,
                    onPressed: () {
                      Get.to(
                        () => TruckAttachmentsPage(
                          vechileNumber: truck.vechileNumber,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.green,
                    onPressed: () async {
                      final result = await Get.to(
                        () => TruckFormPage(truck: truck),
                      );
                      if (result == true) {
                        _applyFiltersAndSort();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTruckGridCard(Truck truck) {
    final insuranceDays = _getDaysUntilExpiry(truck.insuranceExpDate);
    final taxDays = _getDaysUntilExpiry(truck.roadTaxExpDate);
    final hasWarning = insuranceDays <= 30 || taxDays <= 30;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasWarning
            ? BorderSide(color: Colors.orange.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          Get.put(GCFormController());
          final result = await Get.to(() => TruckFormPage(truck: truck));
          if (result == true) {
            _applyFiltersAndSort();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Warning
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2A44).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF1E2A44),
                      size: 20,
                    ),
                  ),
                  if (hasWarning)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Vehicle Number
              Text(
                truck.vechileNumber,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A44),
                ),
              ),
              if (truck.typeofVechile != null) ...[
                const SizedBox(height: 2),
                Text(
                  truck.typeofVechile!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              // Owner
              Text(
                truck.ownerName ?? 'No owner',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Status Indicators
              Column(
                children: [
                  _buildCompactExpiryStatus('Insurance', insuranceDays),
                  const SizedBox(height: 4),
                  _buildCompactExpiryStatus('Tax', taxDays),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiryChip(String label, int days, IconData icon) {
    final color = _getExpiryColor(days);
    String status;

    if (days < 0) {
      status = 'Expired';
    } else if (days == 0) {
      status = 'Today';
    } else if (days <= 7) {
      status = '$days days';
    } else if (days <= 30) {
      status = '$days days';
    } else {
      status = 'Valid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactExpiryStatus(String label, int days) {
    final color = _getExpiryColor(days);
    String status;

    if (days < 0) {
      status = 'Expired';
    } else if (days <= 30) {
      status = '$days days';
    } else {
      status = 'Valid';
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
      ),
    );
  }
}
