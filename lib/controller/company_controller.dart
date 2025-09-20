import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logistic/api_config.dart';

class Company {
  final int id;
  final String companyName;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? gst;
  final String? state;
  final String? country;
  final String? website;
  final String? contactPerson;

  Company({
    required this.id,
    required this.companyName,
    this.address,
    this.phoneNumber,
    this.email,
    this.gst,
    this.state,
    this.country,
    this.website,
    this.contactPerson,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      companyName: json['companyName'] as String,
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      gst: json['gst'],
      state: json['state'],
      country: json['country'],
      website: json['website'],
      contactPerson: json['contactPerson'],
    );
  }
}

class CompanyController extends GetxController {
  final String baseUrl = '${ApiConfig.baseUrl}/company';
  final companies = <Company>[].obs;
  final isLoading = false.obs;
  final error = RxString('');
  final selectedCompany = Rx<Company?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    try {
      error.value = '';
      isLoading.value = true;
      final response = await http.get(
        Uri.parse('$baseUrl/search'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        companies.value = data.map((json) => Company.fromJson(json)).toList();
        
        // Select the first company by default if available
        if (companies.isNotEmpty) {
          selectedCompany.value = companies.first;
        }
      } else {
        final errorMsg = json.decode(response.body)['message'] ?? 'Failed to load companies';
        error.value = errorMsg;
        Get.snackbar('Error', errorMsg);
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
      Get.snackbar('Error', error.value);
    } finally {
      isLoading.value = false;
    }
  }
}
