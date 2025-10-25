import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/controller/id_controller.dart';
import 'routes.dart';
import 'package:logistic/widgets/gc_usage_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/api_config.dart'; // Assuming you have this file

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _showAllActions = false;

  // State for summary data
  List<Map<String, dynamic>> _gcList = [];
  bool _isSummaryLoading = true;
  String? _summaryError;
  late AnimationController _animationController;
  late Animation<double> _totalGCsAnim,
      _totalHireAnim,
      _totalAdvanceAnim,
      _totalFreightAnim;

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    // Initialize with default empty tweens
    _totalGCsAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _totalHireAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _totalAdvanceAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _totalFreightAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  void _updateAnimations() {
    final totalGCs = _gcList.length.toDouble();
    final totalHireAmount =
    _gcList.fold(0.0, (sum, gc) => sum + _parseDouble(gc['HireAmount']));
    final totalAdvanceAmount =
    _gcList.fold(0.0, (sum, gc) => sum + _parseDouble(gc['AdvanceAmount']));
    final totalFreightCharge =
    _gcList.fold(0.0, (sum, gc) => sum + _parseDouble(gc['FreightCharge']));

    setState(() {
      _totalGCsAnim = Tween<double>(begin: 0, end: totalGCs).animate(
          CurvedAnimation(
              parent: _animationController, curve: Curves.easeOutCubic));
      _totalHireAnim = Tween<double>(begin: 0, end: totalHireAmount).animate(
          CurvedAnimation(
              parent: _animationController, curve: Curves.easeOutCubic));
      _totalAdvanceAnim =
          Tween<double>(begin: 0, end: totalAdvanceAmount).animate(
              CurvedAnimation(
                  parent: _animationController, curve: Curves.easeOutCubic));
      _totalFreightAnim =
          Tween<double>(begin: 0, end: totalFreightCharge).animate(
              CurvedAnimation(
                  parent: _animationController, curve: Curves.easeOutCubic));
    });
    _animationController.forward(from: 0);
  }

  Future<void> _fetchSummaryData() async {
    if (!mounted) return;
    setState(() {
      _isSummaryLoading = true;
      _summaryError = null;
    });
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/gc/search');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _gcList = data.cast<Map<String, dynamic>>();
          _isSummaryLoading = false;
        });
        _updateAnimations();
      } else {
        if (!mounted) return;
        setState(() {
          _summaryError = 'Failed to load summary data';
          _isSummaryLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = 'An error occurred: $e';
        _isSummaryLoading = false;
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
    // Basic currency formatting for Indian Rupee
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Future<void> _checkGCAccessAndNavigate({bool toForm = false}) async {
    final idController = Get.find<IdController>();
    final userId = idController.userId.value;

    if (userId.isEmpty) {
      Get.snackbar(
        'Error',
        'User ID not found. Please login again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Get the existing controller or create a new one if it doesn't exist
      final gcFormController = Get.put(GCFormController(), permanent: true);
      final hasAccess = await gcFormController.checkGCAccess(userId);

      // Close loading dialog
      if (Get.isDialogOpen ?? false) Get.back();

      if (hasAccess) {
        // Navigate to appropriate screen based on the action
        if (toForm) {
          // Clear the form before navigating to it
          gcFormController.clearForm();
          // Navigate to GC form for new note
          final result = await Get.toNamed(AppRoutes.gcForm);

          // After returning from form, refresh the summary data
          if (result == 'success') {
            _fetchSummaryData();
          }
        } else {
          // Navigate to GC list
          Get.toNamed(AppRoutes.gcList);
        }
      } else {
        // Show error message if no access
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
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) Get.back();

      // Show error message
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

  // Initialize controllers
  final GCFormController gcFormController = Get.put(GCFormController());
  final IdController idController = Get.find<IdController>();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 700;
    final isAdmin = idController.userRole.value == 'admin';

    return MainLayout(
      title: 'Logistics Dashboard',
      showBackButton: false,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFF),
              Color(0xFFF1F5FE),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(context, isSmallScreen),
              const SizedBox(height: 32),

              // Summary Cards
              if (isAdmin) ...[
                _buildSummaryCards(isSmallScreen)
                  .animate()
                  .slideX(duration: 600.ms, begin: -0.2)
                  .fadeIn(duration: 800.ms),
              const SizedBox(height: 32)
              ],

              // Show GC Usage widget for all users when they don't have active/queued GC ranges
              Obx(() {
                return FutureBuilder<bool>(
                  future: gcFormController.checkGCAccess(idController.userId.value),
                  builder: (context, snapshot) {
                    // If we're still checking access, show a loading indicator
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // Show GCUsageWidget for all users
                    return const Column(
                      children: [
                        SizedBox(height: 32),
                        GCUsageWidget(),
                      ],
                    );
                  },
                );
              }),

              // Quick Actions Section
              _buildQuickActionsSection(context, isSmallScreen, isAdmin),
              const SizedBox(height: 32),

              // Dashboard Content Row
              if (!isSmallScreen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildNotificationsSection(),
                          const SizedBox(height: 24),
                          _buildRecentActivitySection(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildQuickStatsSection(),
                    ),
                  ],
                )
              else ...[
                _buildNotificationsSection(),
                const SizedBox(height: 24),
                _buildQuickStatsSection(),
                const SizedBox(height: 24),
                _buildRecentActivitySection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isSmallScreen) {
    final idController = Get.find<IdController>();
    final userName = idController.userName.value ?? 'User';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your logistics operations efficiently',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (!isSmallScreen)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isSmallScreen) {
    if (_isSummaryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_summaryError != null) {
      return Center(
          child: Text(_summaryError!, style: const TextStyle(color: Colors.red)));
    }

    final cards = [
      _buildSummaryCard(
        'Total GCs',
        _totalGCsAnim,
        Icons.assignment_outlined,
        const Color(0xFF4A90E2),
        isCount: true,
      ),
      _buildSummaryCard(
        'Total Hire',
        _totalHireAnim,
        Icons.local_shipping_outlined,
        const Color(0xFFFBBC05),
      ),
      _buildSummaryCard(
        'Total Advance',
        _totalAdvanceAnim,
        Icons.payments_outlined,
        const Color(0xFF34A853),
      ),
      _buildSummaryCard(
        'Total Freight',
        _totalFreightAnim,
        Icons.receipt_long_outlined,
        const Color(0xFFEA4335),
      ),
    ];

    if (isSmallScreen) {
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, index) => SizedBox(width: 180, child: cards[index]),
        ),
      );
    } else {
      return Row(
        children: cards
            .map((card) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: card,
            )))
            .toList(),
      );
    }
  }

  Widget _buildSummaryCard(
      String title,
      Animation<double> animation,
      IconData icon,
      Color color, {
        bool isCount = false,
      }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8 to 6
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
              Icon(icon, color: color, size: 18), // Reduced from 20 to 18
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Text(
                  isCount
                      ? animation.value.toInt().toString()
                      : _formatCurrency(animation.value),
                  style: const TextStyle(
                    fontSize: 22, // Reduced from 24 to 22
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A44),
                    height: 1.1, // Added to reduce line height
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11, // Reduced from 12 to 11
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.1, // Added to reduce line height
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
      BuildContext context, bool isSmallScreen, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A44),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAllActions = !_showAllActions;
                });
              },
              icon: Icon(_showAllActions ? Icons.view_list : Icons.grid_view,
                  size: 16),
              label: Text(_showAllActions ? 'Show Less' : 'View All'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4A90E2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionGrid(context, isSmallScreen, isAdmin),
      ],
    );
  }

  Widget _buildActionGrid(
      BuildContext context, bool isSmallScreen, bool isAdmin) {
    final primaryActions = [
      _ActionData(
        icon: Icons.note_add_outlined,
        title: 'New GC Note',
        subtitle: 'Create new goods',
        color: const Color(0xFF4A90E2),
        onTap: () => _checkGCAccessAndNavigate(toForm: true),
      ),
      _ActionData(
        icon: Icons.list_alt_outlined,
        title: 'GC List',
        subtitle: 'View all goods',
        color: const Color(0xFF34A853),
        onTap: () => Get.toNamed(AppRoutes.gcList),
      ),
      _ActionData(
        icon: Icons.update_outlined,
        title: 'Update Transit',
        subtitle: 'Track shipments',
        color: const Color(0xFF8E24AA),
        onTap: () => Get.toNamed(AppRoutes.updateTransit),
      ),
      _ActionData(
        icon: Icons.description_outlined,
        title: 'Temporary GC',
        subtitle: 'Quick fill forms',
        color: const Color(0xFFFF6F00),
        onTap: () => Get.toNamed(AppRoutes.temporaryGcList),
      ),
      if (isAdmin)
        _ActionData(
          icon: Icons.bar_chart_outlined,
          title: 'Reports',
          subtitle: 'View analytics',
          color: const Color(0xFF388E3C),
          onTap: () => Get.toNamed(AppRoutes.gcReport),
        ),
    ];

    final managementActions = isAdmin
        ? [
      _ActionData(
        icon: Icons.assignment_outlined,
        title: 'GC Assignment',
        subtitle: 'Assign GC ranges',
        color: const Color(0xFF8E24AA),
        onTap: () => Get.toNamed(AppRoutes.gcAssignment),
      ),
      _ActionData(
        icon: Icons.local_shipping_outlined,
        title: 'Truck Management',
        subtitle: 'Fleet operations',
        color: const Color(0xFF5D4037),
        onTap: () => Get.toNamed(AppRoutes.truckList),
      ),
      _ActionData(
        icon: Icons.speed_outlined,
        title: 'KM Management',
        subtitle: 'Distance tracking',
        color: const Color(0xFF00BFA5),
        onTap: () => Get.toNamed(AppRoutes.kmList),
      ),
      _ActionData(
        icon: Icons.location_on_outlined,
        title: 'Locations',
        subtitle: 'Manage locations',
        color: const Color(0xFF9C27B0),
        onTap: () => Get.toNamed(AppRoutes.locationList),
      ),
      _ActionData(
        icon: Icons.people_outline,
        title: 'Customers',
        subtitle: 'Customer management',
        color: const Color(0xFFFF9800),
        onTap: () => Get.toNamed(AppRoutes.customerList),
      ),
      _ActionData(
        icon: Icons.inventory_outlined,
        title: 'Suppliers',
        subtitle: 'Supplier management',
        color: const Color(0xFF795548),
        onTap: () => Get.toNamed(AppRoutes.supplierList),
      ),
      _ActionData(
        icon: Icons.person_outline,
        title: 'Drivers',
        subtitle: 'Driver management',
        color: const Color(0xFFEA4335),
        onTap: () => Get.toNamed(AppRoutes.driverManagement),
      ),
      _ActionData(
        icon: Icons.business_outlined,
        title: 'Consignors',
        subtitle: 'Consignor management',
        color: const Color(0xFF7B1FA2),
        onTap: () => Get.toNamed(AppRoutes.consignorList),
      ),
      _ActionData(
        icon: Icons.person_pin_outlined,
        title: 'Consignees',
        subtitle: 'Consignee management',
        color: const Color(0xFF0288D1),
        onTap: () => Get.toNamed(AppRoutes.consigneeList),
      ),
      _ActionData(
        icon: Icons.assignment_ind_outlined,
        title: 'Broker Management',
        subtitle: 'Broker operations',
        color: const Color(0xFF9C27B0),
        onTap: () => Get.toNamed(AppRoutes.brokerList),
      ),
      _ActionData(
        icon: Icons.scale_outlined,
        title: 'Weight Management',
        subtitle: 'Weight & rates',
        color: const Color(0xFF607D8B),
        onTap: () => Get.toNamed(AppRoutes.weightRateList),
      ),
      _ActionData(
        icon: Icons.receipt_long_outlined,
        title: 'GST Management',
        subtitle: 'Tax management',
        color: const Color(0xFF37474F),
        onTap: () => Get.toNamed(AppRoutes.gstList),
      ),
      _ActionData(
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'App configuration',
        color: const Color(0xFF757575),
        onTap: () => Get.toNamed(AppRoutes.settings),
      ),
    ]
        : [
      _ActionData(
        icon: Icons.settings_outlined,
        title: 'Settings',
        subtitle: 'App configuration',
        color: const Color(0xFF757575),
        onTap: () => Get.toNamed(AppRoutes.settings),
      ),
    ];

    // Show limited actions initially
    final actionsToShow =
    _showAllActions ? [...primaryActions, ...managementActions] : primaryActions;

    return Column(
      children: [
        // Action Cards Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isSmallScreen ? 1.1 : 1.2,
          children: actionsToShow
              .map((action) => _buildEnhancedActionCard(context, action))
              .toList(),
        ),

        // Show management section label when expanded and admin
        if (_showAllActions && managementActions.length > 1) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Management & Administration',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A90E2),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedActionCard(BuildContext context, _ActionData action) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action.icon,
                    size: 24,
                    color: action.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2A44),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  action.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    final notifications = [
      _NotificationData(
        icon: Icons.warning_amber_outlined,
        color: const Color(0xFFFF9800),
        title: 'E-Way Bills Expiring',
        message: '2 E-Way Bills expiring soon',
        time: '2 hours ago',
        isUrgent: true,
      ),
      _NotificationData(
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF4A90E2),
        title: 'Pending Deliveries',
        message: '5 GCs are pending delivery',
        time: '4 hours ago',
        isUrgent: false,
      ),
      _NotificationData(
        icon: Icons.build_outlined,
        color: const Color(0xFFEA4335),
        title: 'Maintenance Alert',
        message: '1 Vehicle needs maintenance',
        time: '6 hours ago',
        isUrgent: true,
      ),
    ];

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A44),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA4335).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Color(0xFFEA4335),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...notifications
                .map((notification) => _buildNotificationItem(notification)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(_NotificationData notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isUrgent
            ? notification.color.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: notification.isUrgent
            ? Border.all(color: notification.color.withOpacity(0.2))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              notification.icon,
              color: notification.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E2A44),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            notification.time,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A44),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem(
                'Active Routes', '24', Icons.route, const Color(0xFF4A90E2)),
            _buildStatItem('Drivers Available', '18', Icons.person,
                const Color(0xFF34A853)),
            _buildStatItem('Fuel Efficiency', '12.5 km/L',
                Icons.local_gas_station, const Color(0xFFFF9800)),
            _buildStatItem('On-Time Delivery', '94.2%', Icons.schedule,
                const Color(0xFF9C27B0)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2A44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final activities = [
      _ActivityData(
        gcNumber: 'GC-2023-001',
        route: 'Delhi to Mumbai',
        status: 'In Transit',
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF4A90E2),
        date: '2023-11-01',
        amount: '₹12,000',
        progress: 0.6,
      ),
      _ActivityData(
        gcNumber: 'GC-2023-002',
        route: 'Bangalore to Chennai',
        status: 'Delivered',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF34A853),
        date: '2023-10-28',
        amount: '₹9,500',
        progress: 1.0,
      ),
      _ActivityData(
        gcNumber: 'GC-2023-003',
        route: 'Hyderabad to Pune',
        status: 'Pending',
        icon: Icons.access_time_outlined,
        color: const Color(0xFFFBBC05),
        date: '2023-11-03',
        amount: '₹7,800',
        progress: 0.0,
      ),
    ];

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2A44),
              ),
            ),
            const SizedBox(height: 16),
            ...activities.map((activity) => _buildActivityItem(activity)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(_ActivityData activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.gcNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E2A44),
                      ),
                    ),
                    Text(
                      activity.amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Color(0xFF1E2A44),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.route,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: activity.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        activity.status,
                        style: TextStyle(
                          fontSize: 10,
                          color: activity.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (activity.progress > 0)
                      Expanded(
                        child: LinearProgressIndicator(
                          value: activity.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                          AlwaysStoppedAnimation<Color>(activity.color),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _ActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _NotificationData {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String time;
  final bool isUrgent;

  _NotificationData({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
    required this.isUrgent,
  });
}

class _ActivityData {
  final String gcNumber;
  final String route;
  final String status;
  final IconData icon;
  final Color color;
  final String date;
  final String amount;
  final double progress;

  _ActivityData({
    required this.gcNumber,
    required this.route,
    required this.status,
    required this.icon,
    required this.color,
    required this.date,
    required this.amount,
    required this.progress,
  });
}