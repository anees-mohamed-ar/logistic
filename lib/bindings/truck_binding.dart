import 'package:get/get.dart';
import 'package:logistic/controller/truck_controller.dart';

class TruckBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TruckController>(() => TruckController());
  }
}
