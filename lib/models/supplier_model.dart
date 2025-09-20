class Supplier {
  final String? id;
  final String supplierName;
  final String address;
  final String state;
  final String location;
  final String district;
  final String contact;
  final String phoneNumber;
  final String mobileNumber;
  final String gst;
  final String panNumber;
  final String msmeNumber;
  final String email;
  final String cinNumber;
  final String compType;
  final String industrialType;
  final String fax;
  final String companyId;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String micrCode;
  final String bankName;
  final String branchCode;
  final String branchName;
  final String supplierNo;
  final double subTotal;

  Supplier({
    this.id,
    required this.supplierName,
    required this.address,
    required this.state,
    required this.location,
    required this.district,
    required this.contact,
    required this.phoneNumber,
    required this.mobileNumber,
    required this.gst,
    required this.panNumber,
    required this.msmeNumber,
    required this.email,
    required this.cinNumber,
    required this.compType,
    required this.industrialType,
    required this.fax,
    required this.companyId,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.micrCode,
    required this.bankName,
    required this.branchCode,
    required this.branchName,
    required this.supplierNo,
    this.subTotal = 0.0,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString(),
      supplierName: json['supplierName'] ?? '',
      address: json['address'] ?? '',
      state: json['state'] ?? '',
      location: json['location'] ?? '',
      district: json['district'] ?? '',
      contact: json['contact'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      gst: json['gst'] ?? '',
      panNumber: json['panNumber'] ?? '',
      msmeNumber: json['msmeNumber'] ?? '',
      email: json['email'] ?? '',
      cinNumber: json['cinNumber'] ?? '',
      compType: json['compType'] ?? '',
      industrialType: json['industrialType'] ?? '',
      fax: json['fax'] ?? '',
      companyId: json['companyId'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      micrCode: json['micrCode'] ?? '',
      bankName: json['bankName'] ?? '',
      branchCode: json['branchCode'] ?? '',
      branchName: json['branchName'] ?? '',
      supplierNo: json['supplierNo'] ?? '',
      subTotal: (json['subTotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierName': supplierName,
      'address': address,
      'state': state,
      'location': location,
      'district': district,
      'contact': contact,
      'phoneNumber': phoneNumber,
      'mobileNumber': mobileNumber,
      'gst': gst,
      'panNumber': panNumber,
      'msmeNumber': msmeNumber,
      'email': email,
      'cinNumber': cinNumber,
      'compType': compType,
      'industrialType': industrialType,
      'fax': fax,
      'companyId': companyId,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'micrCode': micrCode,
      'bankName': bankName,
      'branchCode': branchCode,
      'branchName': branchName,
      'supplierNo': supplierNo,
      'subTotal': subTotal,
    };
  }

  Supplier copyWith({
    String? id,
    String? supplierName,
    String? address,
    String? state,
    String? location,
    String? district,
    String? contact,
    String? phoneNumber,
    String? mobileNumber,
    String? gst,
    String? panNumber,
    String? msmeNumber,
    String? email,
    String? cinNumber,
    String? compType,
    String? industrialType,
    String? fax,
    String? companyId,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? micrCode,
    String? bankName,
    String? branchCode,
    String? branchName,
    String? supplierNo,
    double? subTotal,
  }) {
    return Supplier(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      address: address ?? this.address,
      state: state ?? this.state,
      location: location ?? this.location,
      district: district ?? this.district,
      contact: contact ?? this.contact,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      gst: gst ?? this.gst,
      panNumber: panNumber ?? this.panNumber,
      msmeNumber: msmeNumber ?? this.msmeNumber,
      email: email ?? this.email,
      cinNumber: cinNumber ?? this.cinNumber,
      compType: compType ?? this.compType,
      industrialType: industrialType ?? this.industrialType,
      fax: fax ?? this.fax,
      companyId: companyId ?? this.companyId,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      micrCode: micrCode ?? this.micrCode,
      bankName: bankName ?? this.bankName,
      branchCode: branchCode ?? this.branchCode,
      branchName: branchName ?? this.branchName,
      supplierNo: supplierNo ?? this.supplierNo,
      subTotal: subTotal ?? this.subTotal,
    );
  }
}
