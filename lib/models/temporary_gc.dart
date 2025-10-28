class TemporaryGC {
  static const _unset = Object();
  final int id;
  final String tempGcNumber;
  final int createdByUserId;
  final DateTime createdAt;
  final bool isLocked;
  final int? lockedByUserId;
  final DateTime? lockedAt;
  final bool isConverted;
  final String? convertedGcNumber;
  final int? convertedByUserId;
  final DateTime? convertedAt;

  // GC Form Fields
  final String? branchCode;
  final String? branch;
  final String? gcDate;
  final String? truckNumber;
  final String? vechileNumber;
  final String? truckType;
  final String? brokerNameShow;
  final String? brokerName;
  final String? tripId;
  final String? poNumber;
  final String? truckFrom;
  final String? truckTo;
  final String? paymentDetails;
  final String? lcNo;
  final String? deliveryDate;
  final String? eBillDate;
  final String? eBillExpDate;
  final String? driverNameShow;
  final String? driverName;
  final String? driverPhoneNumber;
  final String? consignor;
  final String? consignorName;
  final String? consignorAddress;
  final String? consignorGst;
  final String? consignee;
  final String? consigneeName;
  final String? consigneeAddress;
  final String? consigneeGst;
  final String? billTo;
  final String? billToName;
  final String? billToAddress;
  final String? billToGst;
  final String? custInvNo;
  final String? invValue;
  final String? eInv;
  final String? eInvDate;
  final String? eda;
  final String? numberofPkg;
  final String? methodofPkg;
  final String? totalRate;
  final String? totalWeight;
  final String? rate;
  final String? km;
  final String? km2;
  final String? km3;
  final String? km4;
  final String? actualWeightKgs;
  final String? total;
  final String? privateMark;
  final String? privateMark2;
  final String? privateMark3;
  final String? privateMark4;
  final String? charges;
  final String? charges2;
  final String? charges3;
  final String? charges4;
  final String? numberofPkg2;
  final String? methodofPkg2;
  final String? rate2;
  final String? total2;
  final String? actualWeightKgs2;
  final String? numberofPkg3;
  final String? methodofPkg3;
  final String? rate3;
  final String? total3;
  final String? actualWeightKgs3;
  final String? numberofPkg4;
  final String? methodofPkg4;
  final String? rate4;
  final String? total4;
  final String? actualWeightKgs4;
  final String? goodContain;
  final String? goodContain2;
  final String? goodContain3;
  final String? goodContain4;
  final String? deliveryFromSpecial;
  final String? deliveryAddress;
  final String? serviceTax;
  final String? receiptBillNo;
  final String? receiptBillNoAmount;
  final String? receiptBillNoDate;
  final String? challanBillNoDate;
  final String? challanBillAmount;
  final String? hireAmount;
  final String? advanceAmount;
  final String? balanceAmount;
  final String? freightCharge;
  final String? companyId;

  TemporaryGC({
    required this.id,
    required this.tempGcNumber,
    required this.createdByUserId,
    required this.createdAt,
    required this.isLocked,
    this.lockedByUserId,
    this.lockedAt,
    required this.isConverted,
    this.convertedGcNumber,
    this.convertedByUserId,
    this.convertedAt,
    this.branchCode,
    this.branch,
    this.gcDate,
    this.truckNumber,
    this.vechileNumber,
    this.truckType,
    this.brokerNameShow,
    this.brokerName,
    this.tripId,
    this.poNumber,
    this.truckFrom,
    this.truckTo,
    this.paymentDetails,
    this.lcNo,
    this.deliveryDate,
    this.eBillDate,
    this.eBillExpDate,
    this.driverNameShow,
    this.driverName,
    this.driverPhoneNumber,
    this.consignor,
    this.consignorName,
    this.consignorAddress,
    this.consignorGst,
    this.consignee,
    this.consigneeName,
    this.consigneeAddress,
    this.consigneeGst,
    this.billTo,
    this.billToName,
    this.billToAddress,
    this.billToGst,
    this.custInvNo,
    this.invValue,
    this.eInv,
    this.eInvDate,
    this.eda,
    this.numberofPkg,
    this.methodofPkg,
    this.totalRate,
    this.totalWeight,
    this.rate,
    this.km,
    this.km2,
    this.km3,
    this.km4,
    this.actualWeightKgs,
    this.total,
    this.privateMark,
    this.privateMark2,
    this.privateMark3,
    this.privateMark4,
    this.charges,
    this.charges2,
    this.charges3,
    this.charges4,
    this.numberofPkg2,
    this.methodofPkg2,
    this.rate2,
    this.total2,
    this.actualWeightKgs2,
    this.numberofPkg3,
    this.methodofPkg3,
    this.rate3,
    this.total3,
    this.actualWeightKgs3,
    this.numberofPkg4,
    this.methodofPkg4,
    this.rate4,
    this.total4,
    this.actualWeightKgs4,
    this.goodContain,
    this.goodContain2,
    this.goodContain3,
    this.goodContain4,
    this.deliveryFromSpecial,
    this.deliveryAddress,
    this.serviceTax,
    this.receiptBillNo,
    this.receiptBillNoAmount,
    this.receiptBillNoDate,
    this.challanBillNoDate,
    this.challanBillAmount,
    this.hireAmount,
    this.advanceAmount,
    this.balanceAmount,
    this.freightCharge,
    this.companyId,
  });

  factory TemporaryGC.fromJson(Map<String, dynamic> json) {
    return TemporaryGC(
      id: json['id'] as int,
      tempGcNumber: json['temp_gc_number'] as String,
      createdByUserId: json['created_by_user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      isLocked: json['is_locked'] == 1,
      lockedByUserId: json['locked_by_user_id'] as int?,
      lockedAt: json['locked_at'] != null ? DateTime.parse(json['locked_at'] as String) : null,
      isConverted: json['is_converted'] == 1,
      convertedGcNumber: json['converted_gc_number'] as String?,
      convertedByUserId: json['converted_by_user_id'] as int?,
      convertedAt: json['converted_at'] != null ? DateTime.parse(json['converted_at'] as String) : null,
      branchCode: json['BranchCode'] as String?,
      branch: json['Branch'] as String?,
      gcDate: json['GcDate'] as String?,
      truckNumber: json['TruckNumber'] as String?,
      vechileNumber: json['vechileNumber'] as String?,
      truckType: json['TruckType'] as String?,
      brokerNameShow: json['BrokerNameShow'] as String?,
      brokerName: json['BrokerName'] as String?,
      tripId: json['TripId'] as String?,
      poNumber: json['PoNumber'] as String?,
      truckFrom: json['TruckFrom'] as String?,
      truckTo: json['TruckTo'] as String?,
      paymentDetails: json['PaymentDetails'] as String?,
      lcNo: json['LcNo'] as String?,
      deliveryDate: json['DeliveryDate'] as String?,
      eBillDate: json['EBillDate'] as String?,
      eBillExpDate: json['EBillExpDate'] as String?,
      driverNameShow: json['DriverNameShow'] as String?,
      driverName: json['DriverName'] as String?,
      driverPhoneNumber: json['DriverPhoneNumber'] as String?,
      consignor: json['Consignor'] as String?,
      consignorName: json['ConsignorName'] as String?,
      consignorAddress: json['ConsignorAddress'] as String?,
      consignorGst: json['ConsignorGst'] as String?,
      consignee: json['Consignee'] as String?,
      consigneeName: json['ConsigneeName'] as String?,
      consigneeAddress: json['ConsigneeAddress'] as String?,
      consigneeGst: json['ConsigneeGst'] as String?,
      billTo: json['BillTo'] as String?,
      billToName: json['BillToName'] as String?,
      billToAddress: json['BillToAddress'] as String?,
      billToGst: json['BillToGst'] as String?,
      custInvNo: json['CustInvNo'] as String?,
      invValue: json['InvValue'] as String?,
      eInv: json['EInv'] as String?,
      eInvDate: json['EInvDate'] as String?,
      eda: json['Eda'] as String?,
      numberofPkg: json['NumberofPkg'] as String?,
      methodofPkg: json['MethodofPkg'] as String?,
      totalRate: json['TotalRate'] as String?,
      totalWeight: json['TotalWeight'] as String?,
      rate: json['Rate'] as String?,
      km: json['km'] as String?,
      km2: json['km2'] as String?,
      km3: json['km3'] as String?,
      km4: json['km4'] as String?,
      actualWeightKgs: json['ActualWeightKgs'] as String?,
      total: json['Total'] as String?,
      privateMark: json['PrivateMark'] as String?,
      privateMark2: json['PrivateMark2'] as String?,
      privateMark3: json['PrivateMark3'] as String?,
      privateMark4: json['PrivateMark4'] as String?,
      charges: json['Charges'] as String?,
      charges2: json['Charges2'] as String?,
      charges3: json['Charges3'] as String?,
      charges4: json['Charges4'] as String?,
      numberofPkg2: json['NumberofPkg2'] as String?,
      methodofPkg2: json['MethodofPkg2'] as String?,
      rate2: json['Rate2'] as String?,
      total2: json['Total2'] as String?,
      actualWeightKgs2: json['ActualWeightKgs2'] as String?,
      numberofPkg3: json['NumberofPkg3'] as String?,
      methodofPkg3: json['MethodofPkg3'] as String?,
      rate3: json['Rate3'] as String?,
      total3: json['Total3'] as String?,
      actualWeightKgs3: json['ActualWeightKgs3'] as String?,
      numberofPkg4: json['NumberofPkg4'] as String?,
      methodofPkg4: json['MethodofPkg4'] as String?,
      rate4: json['Rate4'] as String?,
      total4: json['Total4'] as String?,
      actualWeightKgs4: json['ActualWeightKgs4'] as String?,
      goodContain: json['GoodContain'] as String?,
      goodContain2: json['GoodContain2'] as String?,
      goodContain3: json['GoodContain3'] as String?,
      goodContain4: json['GoodContain4'] as String?,
      deliveryFromSpecial: json['DeliveryFromSpecial'] as String?,
      deliveryAddress: json['DeliveryAddress'] as String?,
      serviceTax: json['ServiceTax'] as String?,
      receiptBillNo: json['ReceiptBillNo'] as String?,
      receiptBillNoAmount: json['ReceiptBillNoAmount'] as String?,
      receiptBillNoDate: json['ReceiptBillNoDate'] as String?,
      challanBillNoDate: json['ChallanBillNoDate'] as String?,
      challanBillAmount: json['ChallanBillAmount'] as String?,
      hireAmount: json['HireAmount'] as String?,
      advanceAmount: json['AdvanceAmount'] as String?,
      balanceAmount: json['BalanceAmount'] as String?,
      freightCharge: json['FreightCharge'] as String?,
      companyId: json['CompanyId'] as String?,
    );
  }

  TemporaryGC copyWith({
    bool? isLocked,
    Object? lockedByUserId = _unset,
    Object? lockedAt = _unset,
  }) {
    return TemporaryGC(
      id: id,
      tempGcNumber: tempGcNumber,
      createdByUserId: createdByUserId,
      createdAt: createdAt,
      isLocked: isLocked ?? this.isLocked,
      lockedByUserId: lockedByUserId == _unset
          ? this.lockedByUserId
          : lockedByUserId as int?,
      lockedAt:
          lockedAt == _unset ? this.lockedAt : lockedAt as DateTime?,
      isConverted: isConverted,
      convertedGcNumber: convertedGcNumber,
      convertedByUserId: convertedByUserId,
      convertedAt: convertedAt,
      branchCode: branchCode,
      branch: branch,
      gcDate: gcDate,
      truckNumber: truckNumber,
      vechileNumber: vechileNumber,
      truckType: truckType,
      brokerNameShow: brokerNameShow,
      brokerName: brokerName,
      tripId: tripId,
      poNumber: poNumber,
      truckFrom: truckFrom,
      truckTo: truckTo,
      paymentDetails: paymentDetails,
      lcNo: lcNo,
      deliveryDate: deliveryDate,
      eBillDate: eBillDate,
      eBillExpDate: eBillExpDate,
      driverNameShow: driverNameShow,
      driverName: driverName,
      driverPhoneNumber: driverPhoneNumber,
      consignor: consignor,
      consignorName: consignorName,
      consignorAddress: consignorAddress,
      consignorGst: consignorGst,
      consignee: consignee,
      consigneeName: consigneeName,
      consigneeAddress: consigneeAddress,
      consigneeGst: consigneeGst,
      custInvNo: custInvNo,
      invValue: invValue,
      eInv: eInv,
      eInvDate: eInvDate,
      eda: eda,
      numberofPkg: numberofPkg,
      methodofPkg: methodofPkg,
      totalRate: totalRate,
      totalWeight: totalWeight,
      rate: rate,
      km: km,
      km2: km2,
      km3: km3,
      km4: km4,
      actualWeightKgs: actualWeightKgs,
      total: total,
      privateMark: privateMark,
      privateMark2: privateMark2,
      privateMark3: privateMark3,
      privateMark4: privateMark4,
      charges: charges,
      charges2: charges2,
      charges3: charges3,
      charges4: charges4,
      numberofPkg2: numberofPkg2,
      methodofPkg2: methodofPkg2,
      rate2: rate2,
      total2: total2,
      actualWeightKgs2: actualWeightKgs2,
      numberofPkg3: numberofPkg3,
      methodofPkg3: methodofPkg3,
      rate3: rate3,
      total3: total3,
      actualWeightKgs3: actualWeightKgs3,
      numberofPkg4: numberofPkg4,
      methodofPkg4: methodofPkg4,
      rate4: rate4,
      total4: total4,
      actualWeightKgs4: actualWeightKgs4,
      goodContain: goodContain,
      goodContain2: goodContain2,
      goodContain3: goodContain3,
      goodContain4: goodContain4,
      deliveryFromSpecial: deliveryFromSpecial,
      deliveryAddress: deliveryAddress,
      serviceTax: serviceTax,
      receiptBillNo: receiptBillNo,
      receiptBillNoAmount: receiptBillNoAmount,
      receiptBillNoDate: receiptBillNoDate,
      challanBillNoDate: challanBillNoDate,
      challanBillAmount: challanBillAmount,
      hireAmount: hireAmount,
      advanceAmount: advanceAmount,
      balanceAmount: balanceAmount,
      freightCharge: freightCharge,
      companyId: companyId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BranchCode': branchCode,
      'Branch': branch,
      'GcDate': gcDate,
      'TruckNumber': truckNumber,
      'vechileNumber': vechileNumber,
      'TruckType': truckType,
      'BrokerNameShow': brokerNameShow,
      'BrokerName': brokerName,
      'TripId': tripId,
      'PoNumber': poNumber,
      'TruckFrom': truckFrom,
      'TruckTo': truckTo,
      'PaymentDetails': paymentDetails,
      'LcNo': lcNo,
      'DeliveryDate': deliveryDate,
      'EBillDate': eBillDate,
      'EBillExpDate': eBillExpDate,
      'DriverNameShow': driverNameShow,
      'DriverName': driverName,
      'DriverPhoneNumber': driverPhoneNumber,
      'Consignor': consignor,
      'ConsignorName': consignorName,
      'ConsignorAddress': consignorAddress,
      'ConsignorGst': consignorGst,
      'Consignee': consignee,
      'ConsigneeName': consigneeName,
      'ConsigneeAddress': consigneeAddress,
      'ConsigneeGst': consigneeGst,
      'BillTo': billTo,
      'BillToName': billToName,
      'BillToAddress': billToAddress,
      'BillToGst': billToGst,
      'CustInvNo': custInvNo,
      'InvValue': invValue,
      'EInv': eInv,
      'EInvDate': eInvDate,
      'Eda': eda,
      'NumberofPkg': numberofPkg,
      'MethodofPkg': methodofPkg,
      'TotalRate': totalRate,
      'TotalWeight': totalWeight,
      'Rate': rate,
      'km': km,
      'km2': km2,
      'km3': km3,
      'km4': km4,
      'ActualWeightKgs': actualWeightKgs,
      'Total': total,
      'PrivateMark': privateMark,
      'PrivateMark2': privateMark2,
      'PrivateMark3': privateMark3,
      'PrivateMark4': privateMark4,
      'Charges': charges,
      'Charges2': charges2,
      'Charges3': charges3,
      'Charges4': charges4,
      'NumberofPkg2': numberofPkg2,
      'MethodofPkg2': methodofPkg2,
      'Rate2': rate2,
      'Total2': total2,
      'ActualWeightKgs2': actualWeightKgs2,
      'NumberofPkg3': numberofPkg3,
      'MethodofPkg3': methodofPkg3,
      'Rate3': rate3,
      'Total3': total3,
      'ActualWeightKgs3': actualWeightKgs3,
      'NumberofPkg4': numberofPkg4,
      'MethodofPkg4': methodofPkg4,
      'Rate4': rate4,
      'Total4': total4,
      'ActualWeightKgs4': actualWeightKgs4,
      'GoodContain': goodContain,
      'GoodContain2': goodContain2,
      'GoodContain3': goodContain3,
      'GoodContain4': goodContain4,
      'DeliveryFromSpecial': deliveryFromSpecial,
      'DeliveryAddress': deliveryAddress,
      'ServiceTax': serviceTax,
      'ReceiptBillNo': receiptBillNo,
      'ReceiptBillNoAmount': receiptBillNoAmount,
      'ReceiptBillNoDate': receiptBillNoDate,
      'ChallanBillNoDate': challanBillNoDate,
      'ChallanBillAmount': challanBillAmount,
      'HireAmount': hireAmount,
      'AdvanceAmount': advanceAmount,
      'BalanceAmount': balanceAmount,
      'FreightCharge': freightCharge,
      'CompanyId': companyId,
    };
  }
}
