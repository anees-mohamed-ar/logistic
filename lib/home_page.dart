import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/controller/id_controller.dart';
import 'routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 700;
    final idController = Get.find<IdController>();
    final isAdmin = idController.userRole.value == 'admin';

    return MainLayout(
        title: 'Logistics Dashboard',
        showBackButton: false,
        child: Container(
        color: const Color(0xFFF7F9FC),
    child: LayoutBuilder(
    builder: (context, constraints) {
    return SingleChildScrollView(
    child: ConstrainedBox(
    constraints: BoxConstraints(minHeight: constraints.maxHeight),
    child: SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Summary Cards
    _buildSummaryCards(isSmallScreen),
    // const SizedBox(height: 24),
    // // Search & Filter
    // Row(
    // children: [
    // Expanded(
    // child: TextField(
    // decoration: InputDecoration(
    // hintText: 'Search GC, Vehicle, Driver... ',
    // prefixIcon: const Icon(Icons.search),
    // filled: true,
    // fillColor: Colors.white,
    // contentPadding: const EdgeInsets.symmetric(
    // vertical: 0,
    // horizontal: 16,
    // ),
    // border: OutlineInputBorder(
    // borderRadius: BorderRadius.circular(10),
    // borderSide: BorderSide.none,
    // ),
    // ),
    // ),
    // ),
    // const SizedBox(width: 12),
    // ElevatedButton.icon(
    // onPressed: () {},
    // icon: const Icon(Icons.filter_alt),
    // label: const Text('Filter'),
    // style: ElevatedButton.styleFrom(
    // backgroundColor: theme.primaryColor,
    // foregroundColor: Colors.white,
    // padding: const EdgeInsets.symmetric(
    // horizontal: 18,
    // vertical: 14,
    // ),
    // shape: RoundedRectangleBorder(
    // borderRadius: BorderRadius.circular(10),
    // ),
    // ),
    // ),
    // ],
    // ),
    const SizedBox(height: 24),
    // Quick Actions
    const Text(
    'Quick Actions',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E2A44),
    ),
    ),
    const SizedBox(height: 16),
    GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isSmallScreen ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        // Operations
        _buildActionCard(
          context,
          icon: Icons.note_add,
          title: 'New GC Note',
          color: const Color(0xFF4A90E2),
          onTap: () => Get.toNamed(AppRoutes.gcForm),
        ),
        _buildActionCard(
          context,
          icon: Icons.list_alt,
          title: 'GC List',
          color: const Color(0xFF34A853),
          onTap: () => Get.toNamed(AppRoutes.gcList),
        ),
        _buildActionCard(
          context,
          icon: Icons.update,
          title: 'Update Transit',
          color: const Color(0xFF8E24AA),
          onTap: () => Get.toNamed(AppRoutes.updateTransit),
        ),
        if (isAdmin)
          _buildActionCard(
            context,
            icon: Icons.bar_chart,
            title: 'Reports',
            color: const Color(0xFF388E3C),
            onTap: () => Get.toNamed(AppRoutes.gcReport),
          ),

        // Fleet
        if (isAdmin)
          _buildActionCard(
            context,
            icon: Icons.local_shipping,
            title: 'Truck Management',
            color: const Color(0xFF5D4037),
            onTap: () => Get.toNamed(AppRoutes.truckList),
          ),

        // Masters (Admin)
        if (isAdmin) ...[
          _buildActionCard(
            context,
            icon: Icons.speed,
            title: 'KM Management',
            color: const Color(0xFF00BFA5),
            onTap: () => Get.toNamed(AppRoutes.kmList),
          ),
          _buildActionCard(
            context,
            icon: Icons.location_on,
            title: 'Locations',
            color: const Color(0xFF9C27B0),
            onTap: () => Get.toNamed(AppRoutes.locationList),
          ),
          _buildActionCard(
            context,
            icon: Icons.people,
            title: 'Customers',
            color: const Color(0xFFFF9800),
            onTap: () => Get.toNamed(AppRoutes.customerList),
          ),
          _buildActionCard(
            context,
            icon: Icons.inventory,
            title: 'Suppliers',
            color: const Color(0xFF795548),
            onTap: () => Get.toNamed(AppRoutes.supplierList),
          ),
          _buildActionCard(
            context,
            icon: Icons.people,
            title: 'Drivers',
            color: const Color(0xFFEA4335),
            onTap: () => Get.toNamed(AppRoutes.driverManagement),
          ),
          _buildActionCard(
            context,
            icon: Icons.business,
            title: 'Consignors',
            color: const Color(0xFF7B1FA2),
            onTap: () => Get.toNamed(AppRoutes.consignorList),
          ),
          _buildActionCard(
            context,
            icon: Icons.person,
            title: 'Consignees',
            color: const Color(0xFF0288D1),
            onTap: () => Get.toNamed(AppRoutes.consigneeList),
          ),
          _buildActionCard(
            context,
            icon: Icons.assignment,
            title: 'Broker Management',
            color: const Color(0xFF9C27B0),
            onTap: () => Get.toNamed(AppRoutes.brokerList),
          ),
          _buildActionCard(
            context,
            icon: Icons.scale,
            title: 'Weight Management',
            color: const Color(0xFF607D8B),
            onTap: () => Get.toNamed(AppRoutes.weightRateList),
          ),
          _buildActionCard(
            context,
            icon: Icons.receipt,
            title: 'GST Management',
            color: const Color(0xFF607D8B),
            onTap: () => Get.toNamed(AppRoutes.gstList),
          ),
        ],

        // Utilities
        _buildActionCard(
          context,
          icon: Icons.settings,
          title: 'Settings',
          color: const Color(0xFF757575),
          onTap: () {},
        ),
      ],
    ),
    const SizedBox(height: 24),
    // Notifications/Alerts
    _buildNotificationsSection(),
    const SizedBox(height: 24),
    // Recent Activity
    const Text(
    'Recent Activity',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E2A44),
    ),
    ),
    const SizedBox(height: 8),
    _buildRecentActivityList(constraints),
    ],
    ),
    ),
    ),
    );
    },
    ),)
    );
  }

  Widget _buildSummaryCards(bool isSmallScreen) {
    final cards = [
      _buildSummaryCard(
        'Total GCs',
        '120',
        Icons.assignment,
        const Color(0xFF4A90E2),
      ),
      _buildSummaryCard(
        'In Transit',
        '32',
        Icons.local_shipping,
        const Color(0xFFFBBC05),
      ),
      _buildSummaryCard(
        'Delivered',
        '70',
        Icons.check_circle,
        const Color(0xFF34A853),
      ),
      _buildSummaryCard(
        'Pending',
        '18',
        Icons.access_time,
        const Color(0xFFEA4335),
      ),
    ];
    if (!isSmallScreen) {
      cards.add(
        _buildSummaryCard(
          'Revenue',
          '₹2.5L',
          Icons.attach_money,
          const Color(0xFF388E3C),
        ),
      );
    }
    if (isSmallScreen) {
      return SizedBox(
        height: 110,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: cards.map((c) => SizedBox(width: 160, child: c)).toList(),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: cards,
      );
    }
  }

  Widget _buildSummaryCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    // Example notifications, replace with real data
    final notifications = [
      {
        'icon': Icons.warning,
        'color': Colors.orange,
        'msg': '2 E-Way Bills expiring soon!',
      },
      {
        'icon': Icons.local_shipping,
        'color': Colors.blue,
        'msg': '5 GCs are pending delivery.',
      },
      {
        'icon': Icons.error,
        'color': Colors.red,
        'msg': '1 Vehicle needs maintenance.',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Notifications & Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2A44),
          ),
        ),
        const SizedBox(height: 10),
        ...notifications.map(
              (n) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            child: ListTile(
              leading: Icon(n['icon'] as IconData, color: n['color'] as Color),
              title: Text(n['msg'] as String),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(BoxConstraints constraints) {
    // Example data, replace with real data
    final activities = [
      {
        'gcNumber': 'GC-2023-001',
        'route': 'Delhi to Mumbai',
        'status': 'In Transit',
        'icon': Icons.local_shipping,
        'color': const Color(0xFF4A90E2),
        'date': '2023-11-01',
        'amount': '₹12,000',
      },
      {
        'gcNumber': 'GC-2023-002',
        'route': 'Bangalore to Chennai',
        'status': 'Delivered',
        'icon': Icons.check_circle,
        'color': const Color(0xFF34A853),
        'date': '2023-10-28',
        'amount': '₹9,500',
      },
      {
        'gcNumber': 'GC-2023-003',
        'route': 'Hyderabad to Pune',
        'status': 'Pending',
        'icon': Icons.access_time,
        'color': const Color(0xFFFBBC05),
        'date': '2023-11-03',
        'amount': '₹7,800',
      },
    ];
    return SizedBox(
      height: 180,
      child: ListView.builder(
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final a = activities[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (a['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(a['icon'] as IconData, color: a['color'] as Color),
              ),
              title: Text(
                a['gcNumber'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['route'] as String),
                  Text('Date: ${a['date']}'),
                ],
              ),
              trailing: SizedBox(
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(
                        a['status'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: (a['color'] as Color).withOpacity(0.1),
                      labelStyle: TextStyle(color: a['color'] as Color),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a['amount'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
