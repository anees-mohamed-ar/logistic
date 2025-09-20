import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:logistic/api_config.dart';
import 'dart:convert';


class GCReportPage extends StatefulWidget {
  const GCReportPage({Key? key}) : super(key: key);

  @override
  State<GCReportPage> createState() => _GCReportPageState();
}

class _GcDataSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final List<String> fieldKeys;

  _GcDataSource({required this.data, required this.fieldKeys});

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= data.length) return null;
    final item = data[index];
    return DataRow.byIndex(
      index: index,
      color: MaterialStateProperty.resolveWith<Color?>((states) {
        // Zebra striping for readability
        return index % 2 == 0 ? Colors.white : const Color(0xFFF7FAFF);
      }),
      cells: fieldKeys.map((key) {
        final value = item[key];
        return DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              value?.toString() ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}

class _GCReportPageState extends State<GCReportPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> gcList = [];
  bool isLoading = true;
  String? error;
  late AnimationController _controller;
  late Animation<double> _totalGCsAnim,
      _totalHireAnim,
      _totalAdvanceAnim,
      _totalFreightAnim;

  int get totalGCs => gcList.length;
  double get totalHireAmount =>
      gcList.fold(0, (sum, gc) => sum + _parseDouble(gc['HireAmount']));
  double get totalAdvanceAmount =>
      gcList.fold(0, (sum, gc) => sum + _parseDouble(gc['AdvanceAmount']));
  double get totalFreightCharge =>
      gcList.fold(0, (sum, gc) => sum + _parseDouble(gc['FreightCharge']));

  @override
  void initState() {
    super.initState();
    fetchGCList();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _totalGCsAnim = Tween<double>(begin: 0, end: 0).animate(_controller);
    _totalHireAnim = Tween<double>(begin: 0, end: 0).animate(_controller);
    _totalAdvanceAnim = Tween<double>(begin: 0, end: 0).animate(_controller);
    _totalFreightAnim = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
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
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          gcList = data.cast<Map<String, dynamic>>();
          isLoading = false;
          _totalGCsAnim = Tween<double>(
            begin: 0,
            end: totalGCs.toDouble(),
          ).animate(_controller);
          _totalHireAnim = Tween<double>(
            begin: 0,
            end: totalHireAmount,
          ).animate(_controller);
          _totalAdvanceAnim = Tween<double>(
            begin: 0,
            end: totalAdvanceAmount,
          ).animate(_controller);
          _totalFreightAnim = Tween<double>(
            begin: 0,
            end: totalFreightCharge,
          ).animate(_controller);
        });
        _controller.forward(from: 0);
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

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GC Report'),
        backgroundColor: const Color(0xFF1E2A44),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView(
                    children: [
                      _buildSummaryCards(isSmallScreen),
                      const SizedBox(height: 20),
                      const Text(
                        'GC Entries',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPaginatedTable(isSmallScreen),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards(bool isSmallScreen) {
    final cards = [
      _animatedSummaryCard(
        'Total GCs',
        _totalGCsAnim,
        Icons.assignment,
        Colors.blue,
      ),
      _animatedSummaryCard(
        'Total Hire',
        _totalHireAnim,
        Icons.currency_rupee,
        Colors.green,
      ),
      _animatedSummaryCard(
        'Total Advance',
        _totalAdvanceAnim,
        Icons.account_balance_wallet,
        Colors.orange,
      ),
      _animatedSummaryCard(
        'Total Freight',
        _totalFreightAnim,
        Icons.local_shipping,
        Colors.purple,
      ),
    ];
    return Container(
      constraints: const BoxConstraints(maxHeight: 140),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) => cards[i],
      ),
    );
  }

  Widget _animatedSummaryCard(
    String label,
    Animation<double> anim,
    IconData icon,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label.contains('Total GCs')
                    ? anim.value.toInt().toString()
                    : anim.value.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  int _rowsPerPage = 10;
  int _currentPage = 0;
  final TextEditingController _pageController = TextEditingController(text: '1');

  Widget _buildPaginatedTable(bool isSmallScreen) {
    if (gcList.isEmpty) {
      return const Center(child: Text('No GC data available.'));
    }

    final columns = [
      'GC Number',
      'GC Date',
      'Truck Number',
      'PO Number',
      'Trip ID',
      'Broker Name',
      'Driver Name',
      'Consignor Name',
      'Consignee Name',
      'Number of Packages',
      'Actual Weight (kg)',
      'Rate',
      'Hire Amount',
      'Advance Amount',
      'Freight Charge',
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
    final int itemCount = gcList.length;
    final int totalPages = itemCount == 0 ? 1 : (itemCount / _rowsPerPage).ceil();
    _currentPage = _currentPage.clamp(0, totalPages - 1);
    final int startIndex = _currentPage * _rowsPerPage;
    final int endIndex = math.min(startIndex + _rowsPerPage, itemCount);
    final List<Map<String, dynamic>> pageData = gcList.sublist(
      startIndex,
      endIndex,
    );

    void goToPage(int page) {
      if (page >= 0 && page < totalPages) {
        setState(() {
          _currentPage = page;
          _pageController.text = (page + 1).toString();
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontally scrollable table only
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: math.max(constraints.maxWidth, 1000),
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFE3E8F0),
                ),
                columns: columns
                    .map((c) => DataColumn(
                          label: Text(
                            c,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
                rows: pageData.map((item) {
                  final rowIndex = pageData.indexOf(item);
                  final Color? rowColor = rowIndex % 2 == 0
                      ? Colors.white
                      : const Color(0xFFF7FAFF);
                  return DataRow(
                    color: MaterialStateProperty.all(rowColor),
                    cells: fieldKeys.map((key) {
                      return DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            item[key]?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
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

        // Fixed footer controls (do not scroll with horizontal table)
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Rows per page selector
              Row(
                children: [
                  const Text('Rows per page:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _rowsPerPage,
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
                ],
              ),

              const SizedBox(width: 16),

              // Page navigation
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: _currentPage > 0 ? () => goToPage(0) : null,
                    tooltip: 'First page',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed:
                        _currentPage > 0 ? () => goToPage(_currentPage - 1) : null,
                    tooltip: 'Previous page',
                  ),
                  const SizedBox(width: 8),
                  const Text('Page'),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _pageController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(),
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
                  Text(' of $totalPages'),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages - 1
                        ? () => goToPage(_currentPage + 1)
                        : null,
                    tooltip: 'Next page',
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: _currentPage < totalPages - 1
                        ? () => goToPage(totalPages - 1)
                        : null,
                    tooltip: 'Last page',
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Range info
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  itemCount == 0
                      ? 'No entries'
                      : 'Showing ${startIndex + 1}–$endIndex of $itemCount entries',
                  style: TextStyle(color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
