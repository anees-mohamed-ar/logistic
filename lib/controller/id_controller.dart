import 'package:get/get.dart';

class IdController extends GetxController {
  var userId = ''.obs;
  var companyId = ''.obs;

  void setUserId(String id) {
    userId.value = id;
  }

  void setCompanyId(String id) {
    companyId.value = id;
  }

  void clear() {
    userId.value = '';
    companyId.value = '';
  }
}
