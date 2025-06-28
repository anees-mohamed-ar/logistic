import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class GCReportPage extends StatefulWidget {
  const GCReportPage({Key? key}) : super(key: key);

  @override
  State<GCReportPage> createState() => _GCReportPageState();
}

class _GCReportPageState extends State<GCReportPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> gcList = [];
  bool isLoading = true;
  String? error;
  int rowsPerPage = 10;
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildPaginatedTable(bool isSmallScreen) {
    if (gcList.isEmpty) {
      return const Center(child: Text('No GC data available.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
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
        int pageCount = (gcList.length / rowsPerPage).ceil();
        int currentPage = 0;
        PageController pageController = PageController();

        Widget buildTablePage(int page) {
          final start = page * rowsPerPage;
          final end = (start + rowsPerPage).clamp(0, gcList.length);
          final pageRows = gcList.sublist(start, end);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFE3E8F0),
              ),
              dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue.withOpacity(0.08);
                }
                return null;
              }),
              columns: [
                for (final col in columns)
                  DataColumn(
                    label: Text(
                      col,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
              rows: [
                for (int i = 0; i < pageRows.length; i++)
                  DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>((
                      Set<MaterialState> states,
                    ) {
                      if (i % 2 == 0) {
                        return Colors.white;
                      } else {
                        return const Color(0xFFF1F5FB);
                      }
                    }),
                    cells: [
                      for (final key in fieldKeys)
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              pageRows[i][key]?.toString() ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: PageView.builder(
                controller: pageController,
                itemCount: pageCount,
                itemBuilder: (context, page) => buildTablePage(page),
              ),
            ),
            if (pageCount > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < pageCount; i++)
                    GestureDetector(
                      onTap: () => pageController.jumpToPage(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.5),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
