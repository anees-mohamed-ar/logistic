class Branch {
  final int branchId;
  final String branchName;
  final String branchCode;
  final int companyId;
  final String companyName;
  final String? address;
  final String? phone;
  final String? email;
  final String status;

  Branch({
    required this.branchId,
    required this.branchName,
    required this.branchCode,
    required this.companyId,
    required this.companyName,
    this.address,
    this.phone,
    this.email,
    required this.status,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: json['branch_id'] as int,
      branchName: json['branch_name'] as String,
      branchCode: json['branch_code'] as String,
      companyId: json['company_id'] as int,
      companyName: json['company_name'] as String,
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchId,
      'branch_name': branchName,
      'branch_code': branchCode,
      'company_id': companyId,
      'company_name': companyName,
      'address': address,
      'phone': phone,
      'email': email,
      'status': status,
    };
  }
}
