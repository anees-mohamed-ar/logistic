import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/widgets/custom_drawer.dart';
// import 'package:logistic/controller/id_controller.dart';
import 'package:logistic/routes.dart';
// import 'custom_app_bar.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool showDrawer;
  final bool showBackButton;
  final Widget? floatingActionButton;

  const MainLayout({
    Key? key,
    required this.title,
    required this.child,
    this.actions,
    this.showAppBar = true,
    this.showDrawer = true,
    this.showBackButton = true,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final idController = Get.find<IdController>();
    
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFF1E2A44),
              foregroundColor: Colors.white,
              title: Text(title),
              automaticallyImplyLeading: false,
              leading: Builder(
                builder: (context) {
                  if (showBackButton) {
                    return IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Get.back();
                        } else {
                          Get.offAllNamed(AppRoutes.home);
                        }
                      },
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    );
                  }
                },
              ),
              actions: actions,
            )
          : null,
      drawer: showDrawer ? const CustomDrawer() : null,
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}
