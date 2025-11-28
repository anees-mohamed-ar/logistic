import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logistic/controller/gc_history_controller.dart';

class GCHistoryPage extends StatelessWidget {
  GCHistoryPage({super.key});

  final GCHistoryController controller = Get.put(GCHistoryController());
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    controller.fetchHistory(page: controller.currentPage.value);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'GC Range History',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.visibleRanges.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error.value != null &&
              controller.visibleRanges.isEmpty) {
            return _buildErrorState(context);
          }

          return Column(
            children: [
              _buildQuickStats(context),
              _buildRangeTimeline(context),
              _buildFilterAndSearchRow(context),
              const SizedBox(height: 8),
              Expanded(
                child: controller.visibleRanges.isEmpty
                    ? _buildEmptyState(context)
                    : _buildRangesList(context),
              ),
              _buildPaginationBar(context),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Obx(() {
      final ranges = controller.sortedRanges;
      final active = ranges.where((r) => r['status'] == 'active').length;
      final queued = ranges.where((r) => r['status'] == 'queued').length;
      final expired = ranges.where((r) => r['status'] == 'expired').length;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Active',
                active.toString(),
                Icons.check_circle,
                Colors.white,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.white30),
            Expanded(
              child: _buildStatItem(
                'Queued',
                queued.toString(),
                Icons.schedule,
                Colors.white,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.white30),
            Expanded(
              child: _buildStatItem(
                'Expired',
                expired.toString(),
                Icons.block,
                Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeTimeline(BuildContext context) {
    return Obx(() {
      final rangesWithGaps = controller.rangesWithGaps;
      if (rangesWithGaps.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'GC Range Overview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rangesWithGaps.length,
                itemBuilder: (context, index) {
                  final item = rangesWithGaps[index];
                  final isGap = item['isGap'] == true;

                  return _buildTimelineBlock(item, isGap);
                },
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.green, 'Active'),
                _buildLegendItem(Colors.orange, 'Queued'),
                _buildLegendItem(Colors.red.shade400, 'Expired'),
                _buildLegendItem(Colors.grey.shade300, 'Available'),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTimelineBlock(Map<String, dynamic> item, bool isGap) {
    final fromGC = item['fromGC']?.toString() ?? '';
    final toGC = item['toGC']?.toString() ?? '';
    final total = item['totalGCs'] ?? 0;
    final status = item['status']?.toString().toLowerCase() ?? '';

    Color blockColor;
    IconData icon;

    if (isGap) {
      blockColor = Colors.grey.shade300;
      icon = Icons.info_outline;
    } else {
      blockColor = controller.statusColor(status);
      icon = controller.statusIcon(status);
    }

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: blockColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$fromGC-$toGC',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            isGap ? 'Available' : '$total GCs',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search user or GC range...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: controller.setSearchQuery,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('all', 'All'),
                const SizedBox(width: 8),
                _buildStatusChip('active', 'Active'),
                const SizedBox(width: 8),
                _buildStatusChip('queued', 'Queued'),
                const SizedBox(width: 8),
                _buildStatusChip('expired', 'Expired'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    return Obx(() {
      final selected = controller.statusFilter.value == value;
      final color = value == 'all' ? Colors.blue : controller.statusColor(value);

      return GestureDetector(
        onTap: () => controller.setStatusFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRangesList(BuildContext context) {
    return Obx(() {
      final ranges = controller.visibleRanges;
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ranges.length,
        itemBuilder: (context, index) {
          final range = ranges[index];
          return _buildRangeCard(context, range);
        },
      );
    });
  }

  Widget _buildRangeCard(BuildContext context, Map<String, dynamic> range) {
    final status = (range['status'] ?? '').toString();
    final statusColor = controller.statusColor(status);
    final percentage = (range['percentageUsed'] as num?)?.toDouble() ?? 0.0;
    final fromGC = range['fromGC']?.toString() ?? '';
    final toGC = range['toGC']?.toString() ?? '';
    final currentGC = range['currentGC']?.toString() ?? '';
    final userName = range['userName']?.toString() ?? 'Unknown';
    final usedGCs = range['usedGCs'] ?? 0;
    final remainingGCs = range['remainingGCs'] ?? 0;
    final totalGCs = range['totalGCs'] ?? 0;

    final assignedAt = range['assignedAt']?.toString();
    DateTime? assignedDate;
    if (assignedAt != null && assignedAt.isNotEmpty) {
      assignedDate = DateTime.tryParse(assignedAt);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              statusColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      controller.statusIcon(status),
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GC $fromGC → $toGC',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current: $currentGC',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricColumn(
                        'Used',
                        usedGCs.toString(),
                        Colors.green,
                        Icons.check_circle_outline,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildMetricColumn(
                        'Remaining',
                        remainingGCs.toString(),
                        Colors.orange,
                        Icons.hourglass_empty,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildMetricColumn(
                        'Total',
                        totalGCs.toString(),
                        const Color(0xFF4A90E2),
                        Icons.grid_view,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage.clamp(0, 100) / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (assignedDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.event, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      _dateFormatter.format(assignedDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationBar(BuildContext context) {
    return Obx(() {
      final page = controller.currentPage.value;
      final totalPages = controller.totalPages.value;

      if (totalPages <= 1) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page $page of $totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: page > 1
                      ? () => controller.fetchHistory(page: page - 1)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: page > 1 ? Colors.blue : Colors.grey[200],
                    foregroundColor: page > 1 ? Colors.white : Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: page < totalPages
                      ? () => controller.fetchHistory(page: page + 1)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: page < totalPages ? Colors.blue : Colors.grey[200],
                    foregroundColor: page < totalPages ? Colors.white : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No GC History Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'GC assignment history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error.value ?? 'Unknown error',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  controller.fetchHistory(page: controller.currentPage.value),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}