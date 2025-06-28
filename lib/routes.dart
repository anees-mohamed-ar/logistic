import 'package:get/get.dart';
import 'package:logistic/home_page.dart';
import 'package:logistic/update_transit_page.dart';
import 'login_screen.dart';
import 'gc_form_screen.dart';


class AppRoutes {
  static const String login = '/login';
  static const String gcForm = '/gc_form';
  static const String home = '/home';
  static const String gcList = '/gcList';
  static const String gcReport = '/gcReport';
  static const String updateTransit = '/updateTransit';

  static final routes = [
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: gcForm, page: () => const GCFormScreen()),
    GetPage(name: updateTransit, page: () => const UpdateTransitPage()),
  ];
}
