import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logistic/controller/gc_form_controller.dart';
import 'package:logistic/widgets/main_layout.dart';
import 'package:logistic/controller/id_controller.dart';
import 'routes.dart';
import 'package:logistic/widgets/gc_usage_widget.dart';
import 'package:logistic/config/flavor_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/api_config.dart';
import 'package:logistic/controller/feature_flag_controller.dart';
import 'package:logistic/controller/dashboard_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _showAllActions = false;
  bool _showAllRecentActivity = false;
  bool _isCheckingGcAccess = false; // Prevents overlapping GC access checks

  // State for summary data
  List<Map<String, dynamic>> _gcList = [];
  bool _isSummaryLoading = true;
  String? _summaryError;
  late AnimationController _animationController;
  late Animation<double> _totalGCsAnim,
      _totalHireAnim,
      _totalAdvanceAnim,
      _totalFreightAnim;
  late final IdController _idController;

  @override
  void initState() {
    super.initState();
    _idController = Get.find<IdController>();
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _totalHireAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _totalAdvanceAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _totalFreightAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  void _updateAnimations() {
    final totalGCs = _gcList.length.toDouble();
    final totalHireAmount = _gcList.fold(
      0.0,
      (sum, gc) => sum + _parseDouble(gc['HireAmount']),
    );
    final totalAdvanceAmount = _gcList.fold(
      0.0,
      (sum, gc) => sum + _parseDouble(gc['AdvanceAmount']),
    );
    final totalFreightCharge = _gcList.fold(
      0.0,
      (sum, gc) => sum + _parseDouble(gc['FreightCharge']),
    );

    // Debug logging for displayed count
    debugPrint('🏠 [HomePage] Updating animations with GC count: $totalGCs');

    setState(() {
      _totalGCsAnim = Tween<double>(begin: 0, end: totalGCs).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );
      _totalHireAnim = Tween<double>(begin: 0, end: totalHireAmount).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );
      _totalAdvanceAnim = Tween<double>(begin: 0, end: totalAdvanceAmount)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
      _totalFreightAnim = Tween<double>(begin: 0, end: totalFreightCharge)
          .animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );
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
        if (!mounted) return;
        final List<dynamic> data = jsonDecode(response.body);

        // Debug logging to identify count discrepancy
        debugPrint('🏠 [HomePage] API Response received: ${data.length} GCs');
        debugPrint(
          '🏠 [HomePage] Raw response body length: ${response.body.length}',
        );
        debugPrint(
          '🏠 [HomePage] First few GCs: ${data.take(3).map((gc) => gc['GcNumber'] ?? 'Unknown').toList()}',
        );

        // Check for null or invalid records
        final validData = data
            .where((item) => item != null && item is Map)
            .toList();
        debugPrint(
          '🏠 [HomePage] Valid GCs after filtering: ${validData.length}',
        );

        if (validData.length != data.length) {
          debugPrint(
            '🏠 [HomePage] Found ${data.length - validData.length} null/invalid records',
          );
        }

        setState(() {
          _gcList = validData.cast<Map<String, dynamic>>();
          _isSummaryLoading = false;
        });

        debugPrint('🏠 [HomePage] Final GC list length: ${_gcList.length}');
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

  Future<void> _handleRefresh() async {
    await _fetchSummaryData();
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

    // If a check is already running, ignore additional taps
    if (_isCheckingGcAccess) {
      return;
    }
    _isCheckingGcAccess = true;

    if (userId.isEmpty) {
      Get.snackbar(
        'Error',
        'User ID not found. Please login again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _isCheckingGcAccess = false;
      return;
    }

    // Show loading indicator with a modern card-style loader
    Get.dialog(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Checking GC Access',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2A44),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifying your access to create a new GC...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Get the existing controller or create a new one if it doesn't exist
      final gcFormController = Get.put(GCFormController(), permanent: true);

      // Add a small delay to show the progress indicator
      await Future.delayed(const Duration(seconds: 2));

      // Add timeout to prevent infinite loading
      final hasAccess = await Future.any([
        gcFormController.checkGCAccess(userId),
        Future.delayed(
          const Duration(seconds: 10),
          () => throw TimeoutException('GC access check timed out'),
        ),
      ]);

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
        // Show error message if no access as a dialog
        Get.defaultDialog(
          title: 'Access Denied',
          middleText: gcFormController.accessMessage.value,
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          buttonColor: Colors.red,
          onConfirm: () {
            Get.back();
          },
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) Get.back();

      // Show error message
      final errorMessage = e is TimeoutException
          ? 'GC access check timed out. Please try again.'
          : 'Failed to check GC access: $e';

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } finally {
      // Ensure the re-entrancy flag is always cleared
      _isCheckingGcAccess = false;
    }
  }

  // Initialize controllers
  final GCFormController gcFormController = Get.put(GCFormController());
  final IdController idController = Get.find<IdController>();
  final DashboardController dashboardController = Get.put(
    DashboardController(),
  );

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 700;
    final isAdmin = idController.userRole.value == 'admin';
    final isUser = idController.userRole.value == 'user';

    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmationDialog();
      },
      child: MainLayout(
        title: 'Logistics Dashboard',
        showBackButton: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FAFF), Color(0xFFF1F5FE)],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            displacement: 32,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(context, isSmallScreen),
                  const SizedBox(height: 24),

                  // Summary Cards - Hidden for admin users
                  if (!isAdmin && !isUser) ...[
                    _buildSummaryCards(isSmallScreen)
                        .animate()
                        .slideX(duration: 600.ms, begin: -0.2)
                        .fadeIn(duration: 800.ms),
                    const SizedBox(height: 24),
                  ],

                  // GC Usage Widget
                  Obx(() {
                    return FutureBuilder<bool>(
                      future: gcFormController.checkGCAccess(
                        idController.userId.value,
                      ),
                      builder: (context, snapshot) {
                        // If we're still checking access, show a loading indicator
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        // Show GCUsageWidget for all users
                        return const GCUsageWidget();
                      },
                    );
                  }),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  _buildQuickActionsSection(context, isSmallScreen, isAdmin),
                  const SizedBox(height: 24),

                  // Dashboard Content Row
                  if (!isSmallScreen)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              _buildRecentActivitySection(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildQuickStatsSection()),
                      ],
                    )
                  else ...[
                    const SizedBox(height: 24),
                    _buildQuickStatsSection(),
                    const SizedBox(height: 24),
                    _buildRecentActivitySection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    final flavor = FlavorConfig.instance.flavor;
    final companyName = FlavorConfig.instance.name;
    final logoPath = flavor == Flavor.cargo
        ? 'uploads/cargo.png'
        : 'uploads/carrying.jpg';

    return (await Get.dialog<bool>(
          AlertDialog(
            title: Row(
              children: [
                Image.asset(
                  logoPath,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.business,
                      size: 40,
                      color: FlavorConfig.instance.primaryColor,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Exit App',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A44),
                        ),
                      ),
                      Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to exit the app?',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  Widget _buildWelcomeSection(BuildContext context, bool isSmallScreen) {
    final idController = Get.find<IdController>();
    final userName = idController.userName.value ?? 'User';
    final flavor = FlavorConfig.instance.flavor;

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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  flavor == Flavor.cargo
                      ? 'uploads/cargo2.png'
                      : 'uploads/carrying.jpg',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  flavor == Flavor.cargo
                      ? 'uploads/cargo2.png'
                      : 'uploads/carrying.jpg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
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
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _summaryError!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchSummaryData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final cards = [
      _buildSummaryCard(
        'Total GCs',
        _totalGCsAnim,
        Icons.assignment_outlined,
        Theme.of(context).primaryColor,
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
          padding: EdgeInsets.zero,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) => SizedBox(width: 180, child: cards[index]),
        ),
      );
    } else {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: card,
                ),
              ),
            )
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2A44),
                    height: 1.1,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    bool isSmallScreen,
    bool isAdmin,
  ) {
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
              icon: Icon(
                _showAllActions ? Icons.view_list : Icons.grid_view,
                size: 16,
              ),
              label: Text(_showAllActions ? 'Show Less' : 'View All'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
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
    BuildContext context,
    bool isSmallScreen,
    bool isAdmin,
  ) {
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

    // Common management actions accessible to both admin and normal users
    final commonManagementActions = [
      _ActionData(
        icon: Icons.person_outline,
        title: 'Drivers',
        subtitle: 'Driver management',
        color: const Color(0xFFEA4335),
        onTap: () => Get.toNamed(AppRoutes.driverManagement),
      ),
      _ActionData(
        icon: Icons.business_center_outlined,
        title: 'Consignors',
        subtitle: 'Consignor management',
        color: const Color(0xFFFF7043),
        onTap: () => Get.toNamed(AppRoutes.consignorList),
      ),
      _ActionData(
        icon: Icons.person_pin_outlined,
        title: 'Consignees',
        subtitle: 'Consignee management',
        color: const Color(0xFF0288D1),
        onTap: () => Get.toNamed(AppRoutes.consigneeList),
      ),
    ];

    // Additional management actions only for admin users
    final managementActions = isAdmin
        ? [
            _ActionData(
              icon: Icons.assignment_outlined,
              title: 'GC Assignment',
              subtitle: 'Assign GC ranges',
              color: const Color(0xFF8E24AA),
              onTap: () => Get.toNamed(AppRoutes.gcAssignment),
            ),
            if (FeatureFlagController.to.isGcHistoryEnabled.value)
              _ActionData(
                icon: Icons.history_toggle_off,
                title: 'GC History',
                subtitle: 'Usage overview',
                color: const Color(0xFF0097A7),
                onTap: () => Get.toNamed(AppRoutes.gcHistory),
              ),
            _ActionData(
              icon: Icons.local_shipping_outlined,
              title: 'Truck Management',
              subtitle: 'Fleet operations',
              color: const Color(0xFF5D4037),
              onTap: () => Get.toNamed(AppRoutes.truckList),
            ),
            if (FeatureFlagController.to.isKmManagementEnabled.value)
              _ActionData(
                icon: Icons.speed_outlined,
                title: 'KM Management',
                subtitle: 'Distance tracking',
                color: const Color(0xFF00BFA5),
                onTap: () => Get.toNamed(AppRoutes.kmList),
              ),
            if (FeatureFlagController.to.isLocationEnabled.value)
              _ActionData(
                icon: Icons.location_on_outlined,
                title: 'Locations',
                subtitle: 'Manage locations',
                color: const Color(0xFF9C27B0),
                onTap: () => Get.toNamed(AppRoutes.locationList),
              ),
            if (FeatureFlagController.to.isCustomerManagementEnabled.value)
              _ActionData(
                icon: Icons.people_outline,
                title: 'Customers',
                subtitle: 'Customer management',
                color: const Color(0xFFFF9800),
                onTap: () => Get.toNamed(AppRoutes.customerList),
              ),
            if (FeatureFlagController.to.isSupplierManagementEnabled.value)
              _ActionData(
                icon: Icons.inventory_outlined,
                title: 'Suppliers',
                subtitle: 'Supplier management',
                color: const Color(0xFF795548),
                onTap: () => Get.toNamed(AppRoutes.supplierList),
              ),
            _ActionData(
              icon: Icons.business_outlined,
              title: 'Branch Management',
              subtitle: 'Manage branches',
              color: const Color(0xFF9C27B0),
              onTap: () => Get.toNamed(AppRoutes.branchList),
            ),
            _ActionData(
              icon: Icons.assignment_ind_outlined,
              title: 'Broker Management',
              subtitle: 'Broker operations',
              color: const Color(0xFF9C27B0),
              onTap: () => Get.toNamed(AppRoutes.brokerList),
            ),
            _ActionData(
              icon: Icons.people_alt_outlined,
              title: 'User Management',
              subtitle: 'User administration',
              color: const Color(0xFF8BC34A),
              onTap: () => Get.toNamed(AppRoutes.userManagement),
            ),
            if (FeatureFlagController.to.isWeightManagementEnabled.value)
              _ActionData(
                icon: Icons.scale_outlined,
                title: 'Weight Management',
                subtitle: 'Weight & rates',
                color: const Color(0xFF607D8B),
                onTap: () => Get.toNamed(AppRoutes.weightRateList),
              ),
            if (FeatureFlagController.to.isGstEnabled.value)
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
    final actionsToShow = _showAllActions
        ? [...primaryActions, ...commonManagementActions, ...managementActions]
        : primaryActions;

    return Column(
      children: [
        // Action Cards Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isSmallScreen ? 0.95 : 1.0,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, size: 22, color: action.color),
                ),
                const SizedBox(height: 8),
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E2A44),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
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
                    'Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (dashboardController.isLoading.value)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    InkWell(
                      onTap: () => dashboardController.refreshData(),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (dashboardController.error.value.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFDC2626),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dashboardController.error.value,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'GCs',
                        dashboardController.totalGCs.value,
                        Icons.description,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'Drivers',
                        dashboardController.totalDrivers.value,
                        Icons.person,
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'Trucks',
                        dashboardController.totalTrucks.value,
                        Icons.local_shipping,
                        const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: OdometerNumber(value: value, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Obx(() {
      final recentGCs = dashboardController.recentGCs;
      final displayItems = _showAllRecentActivity
          ? recentGCs
          : recentGCs.take(3).toList();

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
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
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (recentGCs.length > 3)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllRecentActivity = !_showAllRecentActivity;
                        });
                      },
                      icon: Icon(
                        _showAllRecentActivity
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 16,
                      ),
                      label: Text(
                        _showAllRecentActivity ? 'Show Less' : 'Show More',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (dashboardController.isLoading.value)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (recentGCs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ...displayItems.map((gc) => _buildRecentGCItem(gc)),
                    if (!_showAllRecentActivity && recentGCs.length > 3)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllRecentActivity = true;
                            });
                          },
                          icon: const Icon(Icons.expand_more, size: 16),
                          label: Text('Show ${recentGCs.length - 3} more'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  String _cleanName(String name) {
    return name.replaceAll('"', '').trim();
  }

  Widget _buildRecentGCItem(Map<String, dynamic> gc) {
    final gcNumber = gc['GcNumber']?.toString() ?? 'Unknown';
    final fromLocation = gc['TruckFrom']?.toString() ?? 'Unknown';
    final toLocation = gc['TruckTo']?.toString() ?? 'Unknown';
    final date = gc['GcDate']?.toString() ?? '';
    final consignorName = _cleanName(
      gc['ConsignorName']?.toString() ?? 'Unknown',
    );
    final consigneeName = _cleanName(
      gc['ConsigneeName']?.toString() ?? 'Unknown',
    );

    // Determine if this GC was recently updated vs created
    final createdAt = gc['created_at']?.toString();
    final updatedAt = gc['updated_at']?.toString();
    final isUpdated =
        createdAt != null && updatedAt != null && updatedAt != createdAt;
    final displayDate = (isUpdated ? updatedAt : date) ?? date;

    String formattedDate = 'Unknown date';
    if (displayDate.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(displayDate);
        formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        formattedDate = displayDate;
      }
    }

    return InkWell(
      onTap: () {
        // Navigate to GC list page with GC ID parameter
        final gcId = gc['Id']?.toString() ?? '';
        if (gcId.isNotEmpty) {
          Get.toNamed('/gc_list', arguments: {'highlightGcId': gcId});
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      gcNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isUpdated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: const Text(
                          'Updated',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Text(
                          'Created',
                          style: TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$fromLocation → $toLocation',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          consignorName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.grey.shade200,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          consigneeName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple odometer-style rolling number made of individual digit wheels.
// Each digit animates when it changes, similar to a kilometer counter.
class OdometerNumber extends StatefulWidget {
  final int value;
  final Color color;

  const OdometerNumber({super.key, required this.value, required this.color});

  @override
  State<OdometerNumber> createState() => _OdometerNumberState();
}

class _OdometerNumberState extends State<OdometerNumber> {
  late List<int> _previousDigits;
  late List<int> _currentDigits;
  late int _displayValue;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
    _currentDigits = _getDigits(_displayValue);
    _previousDigits = List.from(_currentDigits);
  }

  List<int> _getDigits(int value) {
    return value
        .clamp(0, 999999)
        .toString()
        .padLeft(4, '0')
        .split('')
        .map((d) => int.parse(d))
        .toList();
  }

  @override
  void didUpdateWidget(OdometerNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _startStepping(widget.value);
    }
  }

  void _startStepping(int targetValue) {
    _stepTimer?.cancel();

    if (targetValue == _displayValue) return;

    final int direction = targetValue > _displayValue ? 1 : -1;
    final int distance = (targetValue - _displayValue).abs();

    // Faster steps for large jumps, slower for small changes
    final int stepMs = distance <= 10
        ? 500
        : distance <= 50
        ? 100
        : distance <= 100
        ? 40
        : 10;

    _stepTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      if (_displayValue == targetValue) {
        timer.cancel();
        return;
      }

      setState(() {
        _previousDigits = _getDigits(_displayValue);
        _displayValue += direction;
        _currentDigits = _getDigits(_displayValue);
      });
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.color.withOpacity(0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_currentDigits.length, (index) {
          return _OdometerDigit(
            currentDigit: _currentDigits[index],
            previousDigit: _previousDigits[index],
            color: widget.color,
          );
        }),
      ),
    );
  }
}

class _OdometerDigit extends StatefulWidget {
  final int currentDigit;
  final int previousDigit;
  final Color color;

  const _OdometerDigit({
    required this.currentDigit,
    required this.previousDigit,
    required this.color,
  });

  @override
  State<_OdometerDigit> createState() => _OdometerDigitState();
}

class _OdometerDigitState extends State<_OdometerDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _displayDigit;

  @override
  void initState() {
    super.initState();
    _displayDigit = widget.currentDigit;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(_OdometerDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDigit != widget.currentDigit) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Top half highlight (optional)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 23.5,
              left: 0,
              right: 0,
              height: 1,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
            // Animated digits with true drum roll
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final progress = _animation.value;
                final offset = (1 - progress) * 48; // slide up

                return Stack(
                  children: [
                    // Previous digit sliding out
                    Positioned(
                      top: offset - 48,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: Center(
                        child: Text(
                          widget.previousDigit.toString(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    // Current digit sliding in
                    Positioned(
                      top: offset,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: Center(
                        child: Text(
                          widget.currentDigit.toString(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MechanicalRoller extends StatelessWidget {
  final int previousDigit;
  final int currentDigit;
  final double progress;
  final Color color;

  const _MechanicalRoller({
    required this.previousDigit,
    required this.currentDigit,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate rotation for smooth rolling effect
    int diff = currentDigit - previousDigit;
    if (diff < 0) diff += 10;

    final rotations = diff * progress;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002) // Perspective
        ..rotateX(rotations * math.pi * 0.2), // Rotate on X-axis
      child: Center(
        child: _buildDigitText(((previousDigit + rotations) % 10).floor()),
      ),
    );
  }

  Widget _buildDigitText(int digit) {
    return Text(
      digit.toString(),
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.0,
        shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 4)],
        fontFeatures: const [FontFeature.tabularFigures()],
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
