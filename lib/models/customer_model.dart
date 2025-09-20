class Customer {
  final String? id;
  final String customerName;
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

  Customer({
    this.id,
    required this.customerName,
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
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString(),
      customerName: json['customerName'] ?? '',
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
      companyId: json['CompanyId']?.toString() ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      micrCode: json['micrCode'] ?? '',
      bankName: json['bankName'] ?? '',
      branchCode: json['branchCode'] ?? '',
      branchName: json['branchName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'customerName': customerName,
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
      'CompanyId': companyId,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'micrCode': micrCode,
      'bankName': bankName,
      'branchCode': branchCode,
      'branchName': branchName,
    };
    
    if (id != null) {
      data['id'] = id;
    }
    
    return data;
  }
}
