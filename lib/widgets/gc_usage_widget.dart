import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/id_controller.dart';


class GCUsageWidget extends StatefulWidget {
  const GCUsageWidget({super.key});

  @override
  State<GCUsageWidget> createState() => _GCUsageWidgetState();
}

class _GCUsageWidgetState extends State<GCUsageWidget> {
  bool _isLoading = true;
  List<GCUsageData> _usageData = [];
  String? _errorMessage;

  // Get the IdController instance
  final IdController _idController = Get.find<IdController>();
  // Worker to manage the `ever` listener subscription
  late Worker _gcDataRefreshWorker;

  @override
  void initState() {
    super.initState();
    _fetchGCUsage();

    // Listen for changes in _idController.gcDataNeedsRefresh
    _gcDataRefreshWorker = ever(_idController.gcDataNeedsRefresh, (bool needsRefresh) {
      if (needsRefresh) {
        _fetchGCUsage(); // Re-fetch data
        _idController.gcDataNeedsRefresh.value = false; // Reset the flag
      }
    });
  }

  @override
  void dispose() {
    _gcDataRefreshWorker.dispose(); // Dispose the worker to prevent memory leaks
    super.dispose();
  }

  Future<void> _fetchGCUsage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _idController.userId.value;

      if (userId.isEmpty) {
        setState(() {
          _errorMessage = 'User ID not found';
          _isLoading = false;
        });
        return;
      }

      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final response = await dio.get('/gc-management/gc-usage?userId=$userId');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];

          // Filter for active and queued status only
          // Filter and sort data to show active first, then queued by assignment time
          final filteredData = data
              .where((item) => item['status'] == 'active' || item['status'] == 'queued')
              .map((item) => GCUsageData.fromJson(item))
              .toList()
              ..sort((a, b) {
                // Sort active items first
                if (a.status == 'active' && b.status != 'active') return -1;
                if (a.status != 'active' && b.status == 'active') return 1;
                
                // For items with the same status, sort by assignedAt (oldest first)
                return a.assignedAt.compareTo(b.assignedAt);
              });

          setState(() {
            _usageData = filteredData;
            _isLoading = false;
          });
        } else {
          setState(() {
            // This handles cases where API returns success:true but data is empty or null
            _usageData = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch data. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load GC usage: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 700;

    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_errorMessage != null) {
      return const SizedBox.shrink(); // Don't show anything if there's an error
    }

    if (_usageData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.blue.shade100, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.blue, size: 24.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Active GC Ranges',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        "You don't have any active GC ranges to create GCs. Please contact admin to get GC ranges assigned.",
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 14.0,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _fetchGCUsage,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade800,
                    side: BorderSide(color: Colors.blue.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My GC Allocation',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A44),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _fetchGCUsage,
              tooltip: 'Refresh',
              color: const Color(0xFF4A90E2),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isSmallScreen)
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _usageData.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: _buildUsageCard(_usageData[index]),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _usageData.length == 1 ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
            ),
            itemCount: _usageData.length,
            itemBuilder: (_, index) => _buildUsageCard(_usageData[index]),
          ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildUsageCard(GCUsageData usage) {
    final statusColor = usage.status == 'active'
        ? const Color(0xFF34A853)
        : const Color(0xFF4A90E2);

    final statusText = usage.status == 'active' ? 'Active' : 'Queued';

    return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 400,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        usage.status == 'active'
                            ? Icons.assignment_turned_in_outlined
                            : Icons.schedule_outlined,
                        color: statusColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GC: ${usage.fromGC}-${usage.toGC}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A44),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${usage.status == 'active' ? 'Last used GC' : 'Current GC'}: ${usage.currentGC}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Usage Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBox(
                      'Total',
                      usage.totalGCs.toString(),
                      Icons.format_list_numbered,
                      const Color(0xFF4A90E2),
                    ),
                    _buildStatBox(
                      'Used',
                      usage.usedGCs.toString(),
                      Icons.check_circle_outline,
                      const Color(0xFF34A853),
                    ),
                    _buildStatBox(
                      'Remaining',
                      usage.remainingGCs.toString(),
                      Icons.pending_outlined,
                      const Color(0xFFFBBC05),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Usage Progress',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${usage.percentageUsed.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: usage.percentageUsed / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class GCUsageData {
  final String userName;
  final String? branchCode;
  final String fromGC;
  final String toGC;
  final String currentGC;
  final int totalGCs;
  final int usedGCs;
  final int remainingGCs;
  final double percentageUsed;
  final String status;
  final String assignedAt;

  GCUsageData({
    required this.userName,
    this.branchCode,
    required this.fromGC,
    required this.toGC,
    required this.currentGC,
    required this.totalGCs,
    required this.usedGCs,
    required this.remainingGCs,
    required this.percentageUsed,
    required this.status,
    required this.assignedAt,
  });

  factory GCUsageData.fromJson(Map<String, dynamic> json) {
    return GCUsageData(
      userName: json['userName'] ?? '',
      branchCode: json['branchCode'],
      fromGC: json['fromGC']?.toString() ?? '',
      toGC: json['toGC']?.toString() ?? '',
      currentGC: json['currentGC']?.toString() ?? '',
      totalGCs: json['totalGCs'] ?? 0,
      usedGCs: json['usedGCs'] ?? 0,
      remainingGCs: json['remainingGCs'] ?? 0,
      percentageUsed: (json['percentageUsed'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      assignedAt: json['assignedAt'] ?? '',
    );
  }
}