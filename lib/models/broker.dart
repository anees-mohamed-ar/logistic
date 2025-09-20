class Broker {
  final int? id;
  final String brokerName;
  final String brokerAddress;
  final String district;
  final String state;
  final String country;
  final String? dateofBirth;
  final double commissionPercentage;
  final String email;
  final String bloodGroup;
  final String phoneNumber;
  final String mobileNumber;
  final String panNumber;
  final int companyId;

  Broker({
    this.id,
    required this.brokerName,
    required this.brokerAddress,
    required this.district,
    required this.state,
    required this.country,
    this.dateofBirth,
    required this.commissionPercentage,
    required this.email,
    required this.bloodGroup,
    required this.phoneNumber,
    required this.mobileNumber,
    required this.panNumber,
    required this.companyId,
  });

  factory Broker.fromJson(Map<String, dynamic> json) {
    return Broker(
      id: json['brokerId'],
      brokerName: json['brokerName'] ?? '',
      brokerAddress: json['brokerAddress'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      dateofBirth: json['dateofBirth'],
      commissionPercentage: json['commissionPercentage'] is double 
          ? json['commissionPercentage'] 
          : double.tryParse(json['commissionPercentage']?.toString() ?? '0') ?? 0.0,
      email: json['email'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      panNumber: json['panNumber'] ?? '',
      companyId: json['CompanyId'] is int 
          ? json['CompanyId'] 
          : int.tryParse(json['CompanyId']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'brokerId': id,
      'brokerName': brokerName,
      'brokerAddress': brokerAddress,
      'district': district,
      'state': state,
      'country': country,
      'dateofBirth': dateofBirth,
      'commissionPercentage': commissionPercentage is double 
          ? commissionPercentage 
          : double.tryParse(commissionPercentage.toString()) ?? 0.0,
      'email': email,
      'bloodGroup': bloodGroup,
      'phoneNumber': phoneNumber,
      'mobileNumber': mobileNumber,
      'panNumber': panNumber,
      'CompanyId': companyId is int 
          ? companyId 
          : int.tryParse(companyId.toString()) ?? 0,
    };
  }
}
