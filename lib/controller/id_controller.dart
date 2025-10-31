import 'package:get/get.dart';

class IdController extends GetxController {
  var userId = ''.obs;
  var companyId = ''.obs;
  var branchId = ''.obs;
  var fileName = ''.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var companyName = ''.obs;
  var bloodGroup = ''.obs;
  var phoneNumber = ''.obs;
  var userRole = ''.obs; // Added user role field

  // NEW: RxBool to signal when GC usage data needs a refresh.
  var gcDataNeedsRefresh = false.obs;
  
  // Profile picture timestamp for cache busting
  var profilePictureTimestamp = DateTime.now().millisecondsSinceEpoch.obs;

  void setUserId(String id) {
    userId.value = id;
  }

  void setCompanyId(String id) {
    companyId.value = id;
  }

  void setFileName(String? name) {
    fileName.value = name ?? '';
  }

  void setUserName(String name) {
    userName.value = name;
  }

  void setUserEmail(String email) {
    userEmail.value = email;
  }

  void setCompanyName(String name) {
    companyName.value = name;
  }

  void setBloodGroup(String group) {
    bloodGroup.value = group;
  }

  void setPhoneNumber(String number) {
    phoneNumber.value = number;
  }

  void setBranchId(String id) {
    branchId.value = id;
  }

  // Update profile picture timestamp to force refresh
  void updateProfilePictureTimestamp() {
    profilePictureTimestamp.value = DateTime.now().millisecondsSinceEpoch;
  }

  // Clear all user data on logout
  void clearUserData() {
    userId.value = '';
    companyId.value = '';
    branchId.value = '';
    fileName.value = '';
    userName.value = '';
    userEmail.value = '';
    companyName.value = '';
    bloodGroup.value = '';
    phoneNumber.value = '';
    userRole.value = '';
    gcDataNeedsRefresh.value = false; // Also reset the flag
    profilePictureTimestamp.value = DateTime.now().millisecondsSinceEpoch;
  }

  void setAllUserData(Map<String, dynamic> userData) {
    userId.value = userData['userId']?.toString() ?? '';
    companyId.value = userData['company_id']?.toString() ?? '';
    branchId.value =
        userData['branch_id']?.toString() ??
        userData['branchId']?.toString() ??
        '';
    fileName.value = userData['filename']?.toString() ?? '';
    userName.value = userData['userName']?.toString() ?? '';
    userEmail.value = userData['userEmail']?.toString() ?? '';
    companyName.value = userData['companyName']?.toString() ?? '';
    bloodGroup.value = userData['bloodGroup']?.toString() ?? '';
    phoneNumber.value = userData['phoneNumber']?.toString() ?? '';
    userRole.value =
        userData['user_role']?.toString() ??
        'user'; // Default to 'user' if not specified
  }

  void clear() {
    userId.value = '';
    companyId.value = '';
    branchId.value = '';
    fileName.value = '';
    userName.value = '';
    userEmail.value = '';
    companyName.value = '';
    bloodGroup.value = '';
    phoneNumber.value = '';
    gcDataNeedsRefresh.value = false;
    profilePictureTimestamp.value = DateTime.now().millisecondsSinceEpoch;
  }
}
