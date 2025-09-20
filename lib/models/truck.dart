class Truck {
  // ID from the backend (truckMasterId in the response)
  final int? id;
  final String ownerName;
  final String ownerAddress;
  final String? ownerMobileNumber;
  final String? ownerEmail;
  final String? ownerPanNumber;
  // Vehicle number is the primary key for updates
  final String vechileNumber;
  final String? typeofVechile;
  final double? lorryWeight;
  final double? unladenWeight;
  final double? overWeight;
  final String? engineeNumber;
  final String? chaseNumber;
  final String? roadTaxNumber;
  final String? roadTaxExpDate;
  final String? bankName;
  final String? branchName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? ifscCode;
  final String? micrCode;
  final String? branchCode;
  final String? insurance;
  final String? insuranceExpDate;
  final String? fcDate;
  final String? companyId;

  Truck({
    this.id,
    required this.ownerName,
    required this.ownerAddress,
    required this.ownerMobileNumber,
    this.ownerEmail,
    this.ownerPanNumber,
    required this.vechileNumber,
    this.typeofVechile,
    this.lorryWeight,
    this.unladenWeight,
    this.overWeight,
    this.engineeNumber,
    this.chaseNumber,
    this.roadTaxNumber,
    this.roadTaxExpDate,
    this.bankName,
    this.branchName,
    this.accountNumber,
    this.accountHolderName,
    this.ifscCode,
    this.micrCode,
    this.branchCode,
    this.insurance,
    this.insuranceExpDate,
    this.fcDate,
    this.companyId,
  });

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      // Map truckMasterId to id
      id: json['truckMasterId'],
      ownerName: json['ownerName'] ?? '',
      ownerAddress: json['ownerAddress'] ?? '',
      ownerMobileNumber: json['ownerMobileNumber']?.toString(),
      ownerEmail: json['ownerEmail'],
      ownerPanNumber: json['ownerPanNumber'],
      vechileNumber: json['vechileNumber'] ?? '',
      typeofVechile: json['typeofVechile'],
      lorryWeight: json['lorryWeight'] != null ? double.tryParse(json['lorryWeight'].toString()) : null,
      unladenWeight: json['unladenWeight'] != null ? double.tryParse(json['unladenWeight'].toString()) : null,
      overWeight: json['overWeight'] != null ? double.tryParse(json['overWeight'].toString()) : null,
      engineeNumber: json['engineeNumber'],
      chaseNumber: json['chaseNumber'],
      roadTaxNumber: json['roadTaxNumber'],
      roadTaxExpDate: json['roadTaxExpDate'],
      bankName: json['bankName'],
      branchName: json['branchName'],
      accountNumber: json['accountNumber'],
      accountHolderName: json['accountHolderName'],
      ifscCode: json['ifscCode'],
      micrCode: json['micrCode'],
      branchCode: json['branchCode'],
      insurance: json['insurance'],
      insuranceExpDate: json['insuranceExpDate'],
      fcDate: json['fcDate'],
      // Handle both CompanyId and companyId for backward compatibility
      companyId: json['CompanyId']?.toString() ?? json['companyId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'truckMasterId': id, // Use truckMasterId for the backend
      'ownerName': ownerName,
      'ownerAddress': ownerAddress,
      'ownerMobileNumber': ownerMobileNumber?.isNotEmpty == true ? ownerMobileNumber : null,
      'ownerEmail': ownerEmail,
      'ownerPanNumber': ownerPanNumber,
      'vechileNumber': vechileNumber, // This is our primary key for updates
      'typeofVechile': typeofVechile,
      'lorryWeight': lorryWeight,
      'unladenWeight': unladenWeight,
      'overWeight': overWeight,
      'engineeNumber': engineeNumber,
      'chaseNumber': chaseNumber,
      'roadTaxNumber': roadTaxNumber,
      'roadTaxExpDate': roadTaxExpDate,
      'bankName': bankName,
      'branchName': branchName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'ifscCode': ifscCode,
      'micrCode': micrCode,
      'branchCode': branchCode,
      'insurance': insurance,
      'insuranceExpDate': insuranceExpDate,
      'fcDate': fcDate,
      'CompanyId': companyId,
    };
  }
}
