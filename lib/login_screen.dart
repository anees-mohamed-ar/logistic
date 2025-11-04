import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:logistic/controller/login_controller.dart';
import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/routes.dart';

class AnimatedTruck extends StatefulWidget {
  const AnimatedTruck({Key? key}) : super(key: key);

  @override
  State<AnimatedTruck> createState() => _AnimatedTruckState();
}

class _AnimatedTruckState extends State<AnimatedTruck> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  static const double truckWidth = 50.0; // Width of the truck icon

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6), // Slightly faster for better loop
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Calculate position
        // Start with truck just off-screen left to off-screen right
        // The truck's left edge will be at -truckWidth when animation starts (value = 0)
        // The truck's left edge will be at screenWidth when animation ends (value = 1)
        double x = _animation.value * (screenWidth + truckWidth) - 210.0;
        
        // When animation starts (value = 0): x = -truckWidth (just off-screen left)
        // When animation ends (value = 1): x = screenWidth (just off-screen right)
        
        return Transform.translate(
          offset: Offset(x, 0),
          child: const Icon(
            Icons.local_shipping_rounded,
            size: 50,
            color: Color(0xFF1E2A44),
          ),
        );
      },
    );
  }
}

class MovingWind extends StatefulWidget {
  const MovingWind({Key? key}) : super(key: key);

  @override
  State<MovingWind> createState() => _MovingWindState();
}

class _MovingWindState extends State<MovingWind> with SingleTickerProviderStateMixin {
  late AnimationController _windController;

  @override
  void initState() {
    super.initState();
    
    _windController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _windController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _windController,
      builder: (context, child) {
        return CustomPaint(
          painter: MovingWindPainter(_windController.value),
          size: const Size(double.infinity, 60),
        );
      },
    );
  }
}

class MovingWindPainter extends CustomPainter {
  final double progress;
  
  MovingWindPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final windPaint = Paint()
      ..color = const Color(0xFF1E2A44).withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Create multiple wind lines at different positions
    final windLines = [
      {'y': size.height * 0.2, 'length': 25.0, 'speed': 1.0},
      {'y': size.height * 0.4, 'length': 20.0, 'speed': 1.2},
      {'y': size.height * 0.6, 'length': 30.0, 'speed': 0.8},
      {'y': size.height * 0.8, 'length': 15.0, 'speed': 1.1},
    ];

    for (var line in windLines) {
      final y = line['y'] as double;
      final length = line['length'] as double;
      final speed = line['speed'] as double;
      
      // Calculate moving position (right to left)
      final totalWidth = size.width + length + 50;
      final x = size.width + 25 - (progress * speed * totalWidth) % totalWidth;
      
      // Draw wind line
      canvas.drawLine(
        Offset(x, y),
        Offset(x - length, y),
        windPaint,
      );
      
      // Draw additional segments for longer wind effect
      canvas.drawLine(
        Offset(x - length - 10, y),
        Offset(x - length - 25, y),
        windPaint..color = const Color(0xFF1E2A44).withOpacity(0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MovingRoad extends StatefulWidget {
  const MovingRoad({Key? key}) : super(key: key);

  @override
  State<MovingRoad> createState() => _MovingRoadState();
}

class _MovingRoadState extends State<MovingRoad> with SingleTickerProviderStateMixin {
  late AnimationController _roadController;

  @override
  void initState() {
    super.initState();
    
    _roadController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _roadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _roadController,
          builder: (context, child) {
            return SizedBox(
              width: constraints.maxWidth,
              child: CustomPaint(
                painter: MovingRoadPainter(_roadController.value),
                size: Size(constraints.maxWidth, 6),
              ),
            );
          },
        );
      },
    );
  }
}

class MovingRoadPainter extends CustomPainter {
  final double progress;
  
  MovingRoadPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2A44).withOpacity(0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFF1E2A44).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw road base - extend slightly beyond screen edges for full coverage
    canvas.drawLine(
      Offset(-100, size.height / 2),  // Start 100px left of screen
      Offset(size.width + 100, size.height / 2),  // End 100px right of screen
      paint,
    );

    // Draw moving road dashes (right to left movement)
    const dashWidth = 12.0;
    const dashSpacing = 18.0;
    const totalDashLength = dashWidth + dashSpacing;
    
    // Calculate offset for smooth movement from right to left
    final offset = (progress * totalDashLength * 2) % totalDashLength;
    
    // Draw dashes that extend beyond screen edges for smooth animation
    for (double x = size.width + dashWidth + 100 - offset; 
         x > -dashWidth - 100; 
         x -= totalDashLength) {
      canvas.drawLine(
        Offset(x - dashWidth, size.height / 2 - 1),
        Offset(x, size.height / 2 - 1),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(IdController());
    final controller = Get.find<LoginController>();
    final emailFocus = FocusNode();
    final passwordFocus = FocusNode();
    void _submitForm() {
      controller.handleLogin();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                
                // Enhanced Animated Truck Logo
                SizedBox(
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Static background gradient
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.8,
                              colors: [
                                const Color(0xFF1E2A44).withOpacity(0.05),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(70),
                          ),
                        ),
                      ),
                      
                      // Moving wind effects (behind truck)
                      const Positioned.fill(
                        child: MovingWind(),
                      ),
                      
                      // Moving Road with dashes
                      const Positioned(
                        bottom: 35,
                        left: 0,
                        right: 0,
                        child: MovingRoad(),
                      ),
                      
                      // Animated Truck (positioned on road)
                      Positioned(
                        bottom: 25,
                        left: 0,
                        right: 0,
                        height: 50, // Match the truck size
                        child: const AnimatedTruck(),
                      ),
                    ],
                  ),
                ),
                
                // App Title with subtle animation
                const SizedBox(height: 16),
                const Text(
                  'Logistics GC',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ).animate().fadeIn(duration: const Duration(milliseconds: 600))
                 .slideY(begin: 0.3, end: 0),
                
                // const SizedBox(height: 8),
                // const Text(
                //   'Ground Control System',
                //   style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                // ).animate().fadeIn(
                //   delay: const Duration(milliseconds: 200),
                //   duration: const Duration(milliseconds: 600),
                // ).slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 48),

                // Login Form (keeping original form code)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        const Text('Sign In',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text(
                          'Access your account',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),

                        // Backend IP Field
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: controller.ipController,
                          decoration: InputDecoration(
                            labelText: 'Backend Server',
                            hintText: 'Enter server URL or IP',
                            prefixIcon: const Icon(Icons.dns_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => emailFocus.requestFocus(),
                          validator: controller.validateIp,
                        ),

                        // Email Field
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: controller.emailController,
                          focusNode: emailFocus,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                          validator: controller.validateEmail,
                        ),

                        // Password Field
                        const SizedBox(height: 16),
                        Obx(
                              () => TextFormField(
                            controller: controller.passwordController,
                            focusNode: passwordFocus,
                            obscureText: !controller.isPasswordVisible.value,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      controller.isPasswordVisible.value
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: controller.togglePasswordVisibility,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  if (controller.passwordController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      onPressed: _submitForm,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitForm(),
                            validator: controller.validatePassword,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        Obx(
                              () => SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E2A44),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 600),
                ).slideY(begin: 0.3, end: 0),

                // Sign Up Prompt
                const SizedBox(height: 24),
                // TextButton(
                //   onPressed: () => Get.toNamed(AppRoutes.register),
                //   child: const Text.rich(
                //     TextSpan(
                //       text: "Don't have an account? ",
                //       children: [
                //         TextSpan(
                //           text: 'Sign Up',
                //           style: TextStyle(fontWeight: FontWeight.bold),
                //         ),
                //       ],
                //     ),
                //   ),
                // ).animate().fadeIn(
                //   delay: const Duration(milliseconds: 600),
                //   duration: const Duration(milliseconds: 600),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}