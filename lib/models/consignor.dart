class Consignor {
  final String? id;
  final String consignorName;
  final String address;
  final String state;
  final String location;
  final String district;
  final String contact;
  final String phoneNumber;
  final String mobileNumber;
  final String gst;
  final String panNumber;
  final String? msmeNumber;
  final String email;
  final String? cinNumber;
  final String? compType;
  final String? industrialType;
  final String? fax;
  final String? companyId;

  Consignor({
    this.id,
    required this.consignorName,
    required this.address,
    required this.state,
    required this.location,
    required this.district,
    required this.contact,
    required this.phoneNumber,
    required this.mobileNumber,
    required this.gst,
    required this.panNumber,
    this.msmeNumber,
    required this.email,
    this.cinNumber,
    this.compType,
    this.industrialType,
    this.fax,
    this.companyId,
  });

  factory Consignor.fromJson(Map<String, dynamic> json) {
    return Consignor(
      id: json['id']?.toString(),
      consignorName: json['consignorName'] ?? '',
      address: json['address'] ?? '',
      state: json['state'] ?? '',
      location: json['location'] ?? '',
      district: json['district'] ?? '',
      contact: json['contact'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      gst: json['gst'] ?? '',
      panNumber: json['panNumber'] ?? '',
      msmeNumber: json['msmeNumber'],
      email: json['email'] ?? '',
      cinNumber: json['cinNumber'],
      compType: json['compType'],
      industrialType: json['industrialType'],
      fax: json['fax'],
      companyId: json['CompanyId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consignorName': consignorName,
      'address': address,
      'state': state,
      'location': location,
      'district': district,
      'contact': contact,
      'phoneNumber': phoneNumber,
      'mobileNumber': mobileNumber,
      'gst': gst,
      'panNumber': panNumber,
      if (msmeNumber != null) 'msmeNumber': msmeNumber,
      'email': email,
      if (cinNumber != null) 'cinNumber': cinNumber,
      if (compType != null) 'compType': compType,
      if (industrialType != null) 'industrialType': industrialType,
      if (fax != null) 'fax': fax,
      if (companyId != null) 'CompanyId': companyId,
    };
  }

  Consignor copyWith({
    String? consignorName,
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
  }) {
    return Consignor(
      consignorName: consignorName ?? this.consignorName,
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
    );
  }
}
