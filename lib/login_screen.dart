import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logistic/controller/login_controller.dart';
import 'package:logistic/controller/id_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(IdController());
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo and Title (unchanged)
              Animate(
                effects: const [ScaleEffect()],
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A44).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_shipping_rounded, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Logistics GC',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ground Control System',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 48),

              // Login Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      const Text('Sign In', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      const Text(
                        'Access your account',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),

                      // Backend IP Field
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: controller.ipController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Backend IP',
                          prefixIcon: Icon(Icons.dns),
                        ),
                        validator: controller.validateIp,
                      ),

                      // Email Field
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: controller.validateEmail,
                      ),

                      // Password Field
                      const SizedBox(height: 16),
                      Obx(
                        () => TextFormField(
                          controller: controller.passwordController,
                          obscureText: !controller.isPasswordVisible.value,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          ),
                          validator: controller.validatePassword,
                        ),
                      ),

                      // Forgot Password
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              controller.handleSocialLogin('Forgot Password'),
                          child: const Text('Forgot Password?'),
                        ),
                      ),

                      // Login Button
                      const SizedBox(height: 24),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.handleLogin,
                            child: controller.isLoading.value
                                ? const CircularProgressIndicator()
                                : const Text('Sign In'),
                          ),
                        ),
                      ),

                      // Social Login Divider
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('OR'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      // Social Login Buttons
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () =>
                                controller.handleSocialLogin('Google'),
                            icon: const Icon(
                              Icons.g_mobiledata,
                              color: Color(0xFFDB4437),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () =>
                                controller.handleSocialLogin('Apple'),
                            icon: const Icon(Icons.apple),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Sign Up Prompt
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => controller.handleSocialLogin('Sign Up'),
                child: const Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    children: [
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
