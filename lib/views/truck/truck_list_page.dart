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

enum TruckFilterBy {
  all,
  insuranceExpired,
  insuranceExpiring7Days,
  insuranceExpiring30Days,
  taxExpired,
  taxExpiring7Days,
  taxExpiring30Days,
  bothExpiringSoon,
  noExpiryData,
  activeOnly,
}

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

  List<Truck> _allTrucks = [];
  List<Truck> _filteredTrucks = [];
  bool _isLoadingAll = false;

  // Statistics
  int _totalTrucks = 0;
  int _insuranceExpired = 0;
  int _insuranceExpiring30 = 0;
  int _taxExpired = 0;
  int _taxExpiring30 = 0;
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllTrucks();

    searchController.addListener(() {
      _applyFiltersAndSort();
    });

    _scrollController.addListener(() {
      // Remove infinite scroll since we're loading all data
    });
  }

  Future<void> _loadAllTrucks() async {
    setState(() {
      _isLoadingAll = true;
    });

    try {
      // Load all trucks from server
      await controller.fetchTrucks();

      // fetchTrucks already populates controller.trucks with full data
      _allTrucks = List<Truck>.from(controller.trucks);
      _applyFiltersAndSort();
    } catch (e) {
      print('Error loading trucks: $e');
    } finally {
      setState(() {
        _isLoadingAll = false;
      });
    }
  }

  void _calculateStatistics() {
    _totalTrucks = _allTrucks.length;
    _insuranceExpired = 0;
    _insuranceExpiring30 = 0;
    _taxExpired = 0;
    _taxExpiring30 = 0;
    _activeCount = 0;

    final now = DateTime.now();
    for (var truck in _allTrucks) {
      bool hasValidInsurance = false;
      bool hasValidTax = false;

      // Insurance stats
      if (truck.insuranceExpDate != null) {
        final expDate = DateTime.tryParse(truck.insuranceExpDate!);
        if (expDate != null) {
          final days = expDate.difference(now).inDays;
          if (days < 0) {
            _insuranceExpired++;
          } else {
            hasValidInsurance = true;
            if (days <= 30) {
              _insuranceExpiring30++;
            }
          }
        }
      }

      // Tax stats
      if (truck.roadTaxExpDate != null) {
        final expDate = DateTime.tryParse(truck.roadTaxExpDate!);
        if (expDate != null) {
          final days = expDate.difference(now).inDays;
          if (days < 0) {
            _taxExpired++;
          } else {
            hasValidTax = true;
            if (days <= 30) {
              _taxExpiring30++;
            }
          }
        }
      }

      // Active trucks have valid insurance OR valid tax
      if (hasValidInsurance || hasValidTax) {
        _activeCount++;
      }
    }
  }

  void _applyFiltersAndSort() {
    var trucks = List<Truck>.from(_allTrucks);

    // Apply search
    final query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      trucks = trucks.where((truck) {
        return truck.vechileNumber.toLowerCase().contains(query) ||
            (truck.ownerName?.toLowerCase().contains(query) ?? false) ||
            (truck.ownerMobileNumber?.contains(query) ?? false) ||
            (truck.engineeNumber?.toLowerCase().contains(query) ?? false) ||
            (truck.typeofVechile?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply filters
    final now = DateTime.now();
    switch (_currentFilter) {
      case TruckFilterBy.insuranceExpired:
        trucks = trucks.where((truck) {
          if (truck.insuranceExpDate == null) return false;
          final expDate = DateTime.tryParse(truck.insuranceExpDate!);
          if (expDate == null) return false;
          return expDate.isBefore(now);
        }).toList();
        break;

      case TruckFilterBy.insuranceExpiring7Days:
        trucks = trucks.where((truck) {
          if (truck.insuranceExpDate == null) return false;
          final expDate = DateTime.tryParse(truck.insuranceExpDate!);
          if (expDate == null) return false;
          final days = expDate.difference(now).inDays;
          return days >= 0 && days <= 7;
        }).toList();
        break;

      case TruckFilterBy.insuranceExpiring30Days:
        trucks = trucks.where((truck) {
          if (truck.insuranceExpDate == null) return false;
          final expDate = DateTime.tryParse(truck.insuranceExpDate!);
          if (expDate == null) return false;
          final days = expDate.difference(now).inDays;
          return days >= 0 && days <= 30;
        }).toList();
        break;

      case TruckFilterBy.taxExpired:
        trucks = trucks.where((truck) {
          if (truck.roadTaxExpDate == null) return false;
          final expDate = DateTime.tryParse(truck.roadTaxExpDate!);
          if (expDate == null) return false;
          return expDate.isBefore(now);
        }).toList();
        break;

      case TruckFilterBy.taxExpiring7Days:
        trucks = trucks.where((truck) {
          if (truck.roadTaxExpDate == null) return false;
          final expDate = DateTime.tryParse(truck.roadTaxExpDate!);
          if (expDate == null) return false;
          final days = expDate.difference(now).inDays;
          return days >= 0 && days <= 7;
        }).toList();
        break;

      case TruckFilterBy.taxExpiring30Days:
        trucks = trucks.where((truck) {
          if (truck.roadTaxExpDate == null) return false;
          final expDate = DateTime.tryParse(truck.roadTaxExpDate!);
          if (expDate == null) return false;
          final days = expDate.difference(now).inDays;
          return days >= 0 && days <= 30;
        }).toList();
        break;

      case TruckFilterBy.bothExpiringSoon:
        trucks = trucks.where((truck) {
          bool insuranceExpiring = false;
          bool taxExpiring = false;

          if (truck.insuranceExpDate != null) {
            final expDate = DateTime.tryParse(truck.insuranceExpDate!);
            if (expDate != null) {
              final days = expDate.difference(now).inDays;
              insuranceExpiring = days >= 0 && days <= 30;
            }
          }

          if (truck.roadTaxExpDate != null) {
            final expDate = DateTime.tryParse(truck.roadTaxExpDate!);
            if (expDate != null) {
              final days = expDate.difference(now).inDays;
              taxExpiring = days >= 0 && days <= 30;
            }
          }

          return insuranceExpiring && taxExpiring;
        }).toList();
        break;

      case TruckFilterBy.noExpiryData:
        trucks = trucks.where((truck) {
          return truck.insuranceExpDate == null || truck.roadTaxExpDate == null;
        }).toList();
        break;

      case TruckFilterBy.activeOnly:
        trucks = trucks.where((truck) {
          bool hasValidInsurance = false;
          bool hasValidTax = false;

          if (truck.insuranceExpDate != null) {
            final expDate = DateTime.tryParse(truck.insuranceExpDate!);
            if (expDate != null && expDate.isAfter(now)) {
              hasValidInsurance = true;
            }
          }

          if (truck.roadTaxExpDate != null) {
            final expDate = DateTime.tryParse(truck.roadTaxExpDate!);
            if (expDate != null && expDate.isAfter(now)) {
              hasValidTax = true;
            }
          }

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

    setState(() {
      _filteredTrucks = trucks;
      _calculateStatistics();
    });
  }

  int _getDaysUntilExpiry(String? dateStr) {
    if (dateStr == null) return -999;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return -999;
    return date.difference(DateTime.now()).inDays;
  }

  Color _getExpiryColor(int days) {
    if (days == -999) return Colors.grey;
    if (days < 0) return Colors.red.shade700;
    if (days <= 7) return Colors.red.shade600;
    if (days <= 30) return Colors.orange.shade600;
    return Colors.green.shade600;
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expiry Status Cards (compact)
              Row(
                children: [
                  Icon(Icons.sort, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Sort Trucks By',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSortOption(
                TruckSortBy.vehicleNumber,
                'Vehicle Number',
                Icons.pin,
              ),
              _buildSortOption(
                TruckSortBy.ownerName,
                'Owner Name',
                Icons.person,
              ),
              _buildSortOption(
                TruckSortBy.dateAdded,
                'Recently Added',
                Icons.access_time,
              ),
              _buildSortOption(
                TruckSortBy.insuranceExpiry,
                'Insurance Expiry',
                Icons.shield_outlined,
              ),
              _buildSortOption(
                TruckSortBy.roadTaxExpiry,
                'Road Tax Expiry',
                Icons.receipt_long_outlined,
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text(
                  'Ascending Order',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _sortAscending
                      ? 'A to Z, Oldest first'
                      : 'Z to A, Newest first',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: _sortAscending,
                activeColor: Theme.of(context).primaryColor,
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
      ),
    );
  }

  Widget _buildCompactExpiryChip(
    String label,
    int days,
    Color color,
    IconData icon,
  ) {
    String text;
    if (days == -999) {
      text = 'No data';
    } else if (days < 0) {
      text = '${days.abs()} days overdue';
    } else if (days == 0) {
      text = 'Expires today';
    } else {
      text = 'In $days days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(TruckSortBy sortBy, String label, IconData icon) {
    final isSelected = _currentSort == sortBy;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<TruckSortBy>(
        title: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade800,
              ),
            ),
          ],
        ),
        value: sortBy,
        groupValue: _currentSort,
        activeColor: Theme.of(context).primaryColor,
        onChanged: (value) {
          setState(() {
            _currentSort = value!;
            _applyFiltersAndSort();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filter Trucks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (_currentFilter != TruckFilterBy.all)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentFilter = TruckFilterBy.all;
                            _applyFiltersAndSort();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Filter based on all $_totalTrucks trucks',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                _buildFilterSection('General', [
                  _buildFilterOption(
                    TruckFilterBy.all,
                    'All Trucks',
                    Icons.local_shipping,
                    Theme.of(context).primaryColor,
                    'Show all trucks ($_totalTrucks)',
                  ),
                  _buildFilterOption(
                    TruckFilterBy.activeOnly,
                    'Active Trucks',
                    Icons.check_circle,
                    Colors.green,
                    'Valid insurance or tax ($_activeCount)',
                  ),
                  _buildFilterOption(
                    TruckFilterBy.noExpiryData,
                    'Missing Data',
                    Icons.info_outline,
                    Colors.grey,
                    'Incomplete expiry information',
                  ),
                ]),
                const SizedBox(height: 16),

                // Owner Info Card (compact)
                _buildFilterSection('Insurance Status', [
                  _buildFilterOption(
                    TruckFilterBy.insuranceExpired,
                    'Insurance Expired',
                    Icons.error,
                    Colors.red,
                    '$_insuranceExpired trucks - Action required!',
                  ),
                  _buildFilterOption(
                    TruckFilterBy.insuranceExpiring7Days,
                    'Expiring Within 7 Days',
                    Icons.warning_amber,
                    Colors.red.shade400,
                    'Urgent renewal needed',
                  ),
                  _buildFilterOption(
                    TruckFilterBy.insuranceExpiring30Days,
                    'Expiring Within 30 Days',
                    Icons.schedule,
                    Colors.orange,
                    '$_insuranceExpiring30 trucks',
                  ),
                ]),
                const SizedBox(height: 16),
                _buildFilterSection('Road Tax Status', [
                  _buildFilterOption(
                    TruckFilterBy.taxExpired,
                    'Road Tax Expired',
                    Icons.error,
                    Colors.red,
                    '$_taxExpired trucks - Action required!',
                  ),
                  _buildFilterOption(
                    TruckFilterBy.taxExpiring7Days,
                    'Expiring Within 7 Days',
                    Icons.warning_amber,
                    Colors.red.shade400,
                    'Urgent renewal needed',
                  ),
                  _buildFilterOption(
                    TruckFilterBy.taxExpiring30Days,
                    'Expiring Within 30 Days',
                    Icons.schedule,
                    Colors.orange,
                    '$_taxExpiring30 trucks',
                  ),
                ]),
                const SizedBox(height: 16),
                _buildFilterSection('Combined Status', [
                  _buildFilterOption(
                    TruckFilterBy.bothExpiringSoon,
                    'Both Expiring Soon',
                    Icons.priority_high,
                    Colors.deepOrange,
                    'Insurance & Tax within 30 days',
                  ),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildFilterOption(
    TruckFilterBy filter,
    String label,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final isSelected = _currentFilter == filter;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<TruckFilterBy>(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? color : Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        value: filter,
        groupValue: _currentFilter,
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onChanged: (value) {
          setState(() {
            _currentFilter = value!;
            _applyFiltersAndSort();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAll) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: const CustomAppBar(title: 'Truck Management'),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading all trucks...'),
            ],
          ),
        ),
      );
    }

    if (controller.error.isNotEmpty && _allTrucks.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: const CustomAppBar(title: 'Truck Management'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  controller.error.value,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAllTrucks,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const CustomAppBar(title: 'Truck Management'),
      body: Column(
        children: [
          // Quick Stats Bar
          if (_allTrucks.isNotEmpty) _buildQuickStatsBar(),

          // Search and Filter Bar (compact)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by vehicle, owner, phone...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              searchController.clear();
                              _applyFiltersAndSort();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: _buildActionChip(
                        icon: Icons.filter_list,
                        label: _getFilterLabel(),
                        isActive: _currentFilter != TruckFilterBy.all,
                        onPressed: _showFilterOptions,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionChip(
                        icon: _sortAscending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        label: _getSortLabel(),
                        isActive: false,
                        onPressed: _showSortOptions,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          size: 20,
                        ),
                        color: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                // Results count
                if (_filteredTrucks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_filteredTrucks.length} truck${_filteredTrucks.length != 1 ? 's' : ''} found',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_currentFilter != TruckFilterBy.all) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Filtered',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Trucks List/Grid
          Expanded(
            child: _filteredTrucks.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadAllTrucks();
                    },
                    color: Theme.of(context).primaryColor,
                    child: _isGridView ? _buildGridView() : _buildListView(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(() => const TruckFormPage());
          if (result == true) {
            await _loadAllTrucks();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Truck',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildQuickStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.85),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_shipping,
              label: 'Total',
              value: _totalTrucks.toString(),
              color: Colors.white,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle,
              label: 'Active',
              value: _activeCount.toString(),
              color: Colors.green.shade300,
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white24),
          Expanded(
            child: _buildStatItem(
              icon: Icons.warning_amber,
              label: 'Expiring',
              value: (_insuranceExpiring30 + _taxExpiring30).toString(),
              color: Colors.orange.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive
            ? Colors.white
            : Theme.of(context).primaryColor,
        backgroundColor: isActive
            ? Theme.of(context).primaryColor
            : Colors.transparent,
        side: BorderSide(
          color: isActive
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  String _getFilterLabel() {
    switch (_currentFilter) {
      case TruckFilterBy.all:
        return 'All Trucks';
      case TruckFilterBy.insuranceExpired:
        return 'Ins. Expired';
      case TruckFilterBy.insuranceExpiring7Days:
        return 'Ins. 7 Days';
      case TruckFilterBy.insuranceExpiring30Days:
        return 'Ins. 30 Days';
      case TruckFilterBy.taxExpired:
        return 'Tax Expired';
      case TruckFilterBy.taxExpiring7Days:
        return 'Tax 7 Days';
      case TruckFilterBy.taxExpiring30Days:
        return 'Tax 30 Days';
      case TruckFilterBy.bothExpiringSoon:
        return 'Both Expiring';
      case TruckFilterBy.noExpiryData:
        return 'No Data';
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
    final hasFilters =
        searchController.text.isNotEmpty || _currentFilter != TruckFilterBy.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.search_off : Icons.local_shipping_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'No Matching Trucks' : 'No Trucks Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters to find what you\'re looking for'
                  : 'Start by adding your first truck to the system',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    _currentFilter = TruckFilterBy.all;
                    _applyFiltersAndSort();
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _filteredTrucks.length,
      itemBuilder: (context, index) {
        final truck = _filteredTrucks[index];
        return _buildTruckCard(truck);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredTrucks.length,
      itemBuilder: (context, index) {
        final truck = _filteredTrucks[index];
        return _buildTruckGridCard(truck);
      },
    );
  }

  Widget _buildTruckCard(Truck truck) {
    final insuranceDays = _getDaysUntilExpiry(truck.insuranceExpDate);
    final taxDays = _getDaysUntilExpiry(truck.roadTaxExpDate);
    final insuranceColor = _getExpiryColor(insuranceDays);
    final taxColor = _getExpiryColor(taxDays);
    // Fixed border logic - only show border if actually expired or expiring soon
    final hasUrgentWarning =
        (insuranceDays >= 0 && insuranceDays < 7) ||
        (taxDays >= 0 && taxDays < 7) ||
        (insuranceDays < 0) ||
        (taxDays < 0);
    final hasWarning =
        (insuranceDays >= 7 && insuranceDays <= 30) ||
        (taxDays >= 7 && taxDays <= 30);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: hasUrgentWarning ? 4 : 2,
      shadowColor: hasUrgentWarning ? Colors.red.withOpacity(0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: hasUrgentWarning
            ? BorderSide(color: Colors.red.shade400, width: 2)
            : hasWarning
            ? BorderSide(color: Colors.orange.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          Get.put(GCFormController());
          final result = await Get.to(() => TruckFormPage(truck: truck));
          if (result == true) {
            await _loadAllTrucks();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          truck.vechileNumber,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (truck.typeofVechile != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              truck.typeofVechile!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasUrgentWarning)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.priority_high,
                        color: Colors.red.shade700,
                        size: 16,
                      ),
                    )
                  else if (hasWarning)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
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
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      truck.ownerName ?? 'No owner assigned',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (truck.ownerMobileNumber != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 14,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      truck.ownerMobileNumber!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildCompactExpiryChip(
                      'Insurance',
                      insuranceDays,
                      insuranceColor,
                      Icons.shield_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactExpiryChip(
                      'Road Tax',
                      taxDays,
                      taxColor,
                      Icons.receipt_long_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Action Buttons (unchanged layout, slightly tighter spacing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.to(
                          () => TruckAttachmentsPage(
                            vechileNumber: truck.vechileNumber,
                          ),
                        );
                      },
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: const Text(
                        'Documents',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Get.to(
                          () => TruckFormPage(truck: truck),
                        );
                        if (result == true) {
                          await _loadAllTrucks();
                        }
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Truck',
                    onPressed: () => _confirmDeleteTruck(truck.vechileNumber),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTruck(String vechileNumber) {
    if (vechileNumber.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid vehicle number',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.defaultDialog(
      title: 'Delete Truck',
      content: Text('Are you sure you want to delete $vechileNumber?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Get.back();
            final success = await controller.deleteTruck(vechileNumber);
            if (success) {
              await _loadAllTrucks();
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildTruckGridCard(Truck truck) {
    final insuranceDays = _getDaysUntilExpiry(truck.insuranceExpDate);
    final taxDays = _getDaysUntilExpiry(truck.roadTaxExpDate);
    // Fixed border logic
    final hasUrgentWarning =
        (insuranceDays >= 0 && insuranceDays < 7) ||
        (taxDays >= 0 && taxDays < 7) ||
        (insuranceDays < 0) ||
        (taxDays < 0);
    final hasWarning =
        (insuranceDays >= 7 && insuranceDays <= 30) ||
        (taxDays >= 7 && taxDays <= 30);

    return Card(
      elevation: hasUrgentWarning ? 4 : 2,
      shadowColor: hasUrgentWarning ? Colors.red.withOpacity(0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: hasUrgentWarning
            ? BorderSide(color: Colors.red.shade400, width: 2)
            : hasWarning
            ? BorderSide(color: Colors.orange.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          Get.put(GCFormController());
          final result = await Get.to(() => TruckFormPage(truck: truck));
          if (result == true) {
            await _loadAllTrucks();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  if (hasUrgentWarning)
                    Icon(
                      Icons.priority_high,
                      color: Colors.red.shade700,
                      size: 20,
                    )
                  else if (hasWarning)
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 0.3,
                ),
              ),

              if (truck.typeofVechile != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    truck.typeofVechile!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const Spacer(),

              // Owner
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        truck.ownerName ?? 'No owner',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Status Indicators
              _buildGridExpiryStatus('Insurance', insuranceDays),
              const SizedBox(height: 6),
              _buildGridExpiryStatus('Tax', taxDays),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedExpiryCard(
    String label,
    int days,
    Color color,
    IconData icon,
  ) {
    String status;
    String detail;
    if (days == -999) {
      status = 'No Data';
      detail = 'Update required';
    } else if (days < 0) {
      status = 'EXPIRED';
      detail = '${days.abs()} days ago';
    } else if (days == 0) {
      status = 'TODAY';
      detail = 'Expires today!';
    } else if (days <= 7) {
      status = '$days Days';
      detail = 'Urgent!';
    } else if (days <= 30) {
      status = '$days Days';
      detail = 'Renew soon';
    } else {
      status = 'Valid';
      detail = '$days days left';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 15,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            detail,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGridExpiryStatus(String label, int days) {
    final color = _getExpiryColor(days);
    String status;
    if (days == -999) {
      status = 'No data';
    } else if (days < 0) {
      status = 'Expired';
    } else if (days <= 30) {
      status = '$days days';
    } else {
      status = 'Valid';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
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
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
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
    );
  }
}
