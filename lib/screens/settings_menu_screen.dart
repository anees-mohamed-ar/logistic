import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/routes.dart';

class SettingsMenuScreen extends StatelessWidget {
  const SettingsMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          _buildMenuItem(
            context,
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => Get.toNamed(AppRoutes.changePassword),
          ),
          // // _buildSectionHeader('Appearance'),
          // // _buildMenuItem(
          // //   context,
          // //   icon: Icons.dark_mode_outlined,
          // //   title: 'Theme',
          // //   trailing: const Text('System'), // You can make this dynamic
          // //   onTap: () {
          // //     // TODO: Implement theme change
          // //   },
          // // ),
          // _buildSectionHeader('About'),
          // _buildMenuItem(
          //   context,
          //   icon: Icons.info_outline,
          //   title: 'About App',
          //   onTap: () {
          //     // TODO: Show about dialog
          //     _showAboutDialog(context);
          //   },
          // ),
          // _buildMenuItem(
          //   context,
          //   icon: Icons.help_outline,
          //   title: 'Help & Support',
          //   onTap: () {
          //     // TODO: Navigate to help & support
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Logistic App',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 50),
      children: const [
        SizedBox(height: 16),
        Text('A comprehensive logistics management solution.'),
      ],
    );
  }
}
