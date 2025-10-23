import 'package:get/get.dart';
import 'package:logistic/splash_screen.dart';
import 'package:logistic/home_page.dart';
import 'package:logistic/models/truck.dart';
import 'package:logistic/update_transit_page.dart';
import 'package:logistic/views/consignor/consignor_list_page.dart';
import 'package:logistic/views/consignee/consignee_list_page.dart';
import 'package:logistic/views/admin/user_management_page.dart';
import 'package:logistic/views/admin/driver_management_page.dart';
import 'package:logistic/login_screen.dart';
import 'package:logistic/gc_form_screen.dart';
import 'package:logistic/gc_report_page.dart';
import 'package:logistic/gc_list_page.dart';
import 'package:logistic/views/gst/gst_form_page.dart';
import 'package:logistic/views/km/km_form_page.dart';
import 'package:logistic/views/km/km_list_page.dart';
import 'package:logistic/views/location/location_list_page.dart';
import 'package:logistic/views/location/location_form_page.dart';
import 'package:logistic/views/customer/customer_list_page.dart';
import 'package:logistic/views/customer/customer_form_page.dart';
import 'package:logistic/views/supplier/supplier_form_page.dart';
import 'package:logistic/views/supplier/supplier_list_page.dart';
import 'package:logistic/views/supplier/supplier_form_page.dart';
import 'package:logistic/views/gst/gst_list_page.dart';
// import 'package:logistic/views/gst/gst_form_page.dart';
import 'package:logistic/views/broker/broker_list_page.dart';
import 'package:logistic/views/broker/add_edit_broker_page.dart';
import 'package:logistic/views/weight_rate/weight_rate_list_page.dart';
import 'package:logistic/views/weight_rate/add_edit_weight_rate_page.dart';
import 'package:logistic/screens/settings_menu_screen.dart';
import 'package:logistic/screens/settings_screen.dart';
import 'package:logistic/views/truck/truck_list_page.dart';
import 'package:logistic/views/truck/truck_form_page.dart';
import 'package:logistic/bindings/truck_binding.dart';
import 'package:logistic/register_screen.dart';
import 'package:logistic/gc_assignment_page.dart';
import 'package:logistic/screens/settings_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String gcForm = '/gc_form';
  static const String gcList = '/gc_list';
  static const String gcReport = '/gc_report';
  static const String updateTransit = '/update_transit';
  static const String consignorList = '/consignor_list';
  static const String consigneeList = '/consignee_list';
  static const String userManagement = '/user_management';
  static const String driverManagement = '/driver_management';
  static const String kmList = '/km_list';
  static const String settings = '/settings';
  static const String changePassword = '/settings/change-password';
  static const String kmForm = '/km_form';
  static const String locationList = '/location_list';
  static const String locationForm = '/location_form';
  static const String customerList = '/customer_list';
  static const String customerForm = '/customer_form';
  static const String supplierList = '/supplier_list';
  static const String supplierForm = '/supplier_form';
  static const String gstList = '/gst_list';
  static const String gstForm = '/gst_form';
  static const String brokerList = '/broker_list';
  static const String brokerForm = '/broker_form';
  static const String weightRateList = '/weight_rate_list';
  static const String weightRateForm = '/weight_rate_form';
  static const String weightRateEdit = '/weight_rate_edit';
  static const String truckList = '/truck_list';
  static const String truckForm = '/truck_form';
  static const String gcAssignment = '/gc_assignment';

  static final routes = [
    GetPage(
      name: splash, 
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: login, 
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: home, 
      page: () => const HomePage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: gcForm, 
      page: () => const GCFormScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: kmList,
      page: () => KMListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsMenuScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: changePassword,
      page: () => const ChangePasswordScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: gcList, 
      page: () => const GCListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: gcReport, 
      page: () => const GCReportPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: updateTransit, 
      page: () => const UpdateTransitPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: consignorList, 
      page: () => ConsignorListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: consigneeList, 
      page: () => ConsigneeListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: userManagement, 
      page: () => const UserManagementPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: driverManagement, 
      page: () => const DriverManagementPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: kmList, 
      page: () => KMListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: kmForm, 
      page: () => const KMFormPage(),
      transition: Transition.rightToLeft,
    ),
    // GST Form page commented out as it's not currently used
    // GetPage(
    //   name: gstForm, 
    //   page: () => GSTFormPage(),
    //   transition: Transition.rightToLeft,
    // ),
    GetPage(
      name: brokerList, 
      page: () => BrokerListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: brokerForm, 
      page: () => AddEditBrokerPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: weightRateList, 
      page: () => WeightRateListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: weightRateForm, 
      page: () => AddEditWeightRatePage.create(Get.arguments),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: weightRateEdit, 
      page: () => AddEditWeightRatePage.create(Get.arguments),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: locationList,
      page: () => LocationListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: locationForm,
      page: () => LocationFormPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: customerList, 
      page: () => CustomerListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: customerForm, 
      page: () => const CustomerFormPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: supplierList,
      page: () =>  SupplierListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: supplierForm, 
      page: () => const SupplierFormPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: gstList, 
      page: () => GstListPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: gstForm, 
      page: () {
        final gst = Get.arguments;
        return gst != null 
            ? GstFormPage(gst: gst)
            : const GstFormPage();
      },
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: gcAssignment,
      page: () => const GCAssignmentPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: truckList, 
      page: () => TruckListPage(),
      binding: TruckBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: truckForm,
      page: () {
        final truck = Get.arguments as Truck?;
        print('🚚 Navigating to truck form with truck: ${truck?.vechileNumber} (ID: ${truck?.id})');
        return truck != null
            ? TruckFormPage(truck: truck)
            : const TruckFormPage();
      },
      binding: TruckBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
