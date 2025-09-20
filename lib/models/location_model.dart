class Location {
  final String? id;
  final String branchName;
  final String branchCode;
  final String branchPincode;
  final String address;
  final String contactPerson;
  final String email;
  final String phoneNumber;
  final String companyId;

  Location({
    this.id,
    required this.branchName,
    required this.branchCode,
    required this.branchPincode,
    required this.address,
    required this.contactPerson,
    required this.email,
    required this.phoneNumber,
    required this.companyId,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id']?.toString(),
      branchName: json['branchName'] ?? '',
      branchCode: json['branchCode'] ?? '',
      branchPincode: json['branchPincode'] ?? '000',
      address: json['address'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      companyId: json['CompanyId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'branchName': branchName,
      'branchCode': branchCode,
      'branchPincode': branchPincode,
      'address': address,
      'contactPerson': contactPerson,
      'email': email,
      'phoneNumber': phoneNumber,
      'CompanyId': companyId,
    };
    
    // Only include id if it's not null
    if (id != null) {
      data['id'] = id;
    }
    
    return data;
  }
}
