import 'package:intl/intl.dart';

class GstModel {
  final String? id;
  final String hsn;
  final DateTime date;
  final double cgst;
  final double igst;
  final double sgst;
  final String companyId;

  GstModel({
    this.id,
    required this.hsn,
    required this.date,
    required this.cgst,
    required this.igst,
    required this.sgst,
    required this.companyId,
  });

  factory GstModel.fromJson(Map<String, dynamic> json) {
    String? dateStr = json['date']?.toString();
    DateTime parsedDate;
    
    try {
      // Try parsing the date string (could be in different formats)
      if (dateStr?.contains('T') ?? false) {
        // Handle ISO format: 2025-09-12T18:30:00.000Z
        parsedDate = DateTime.parse(dateStr!);
      } else {
        // Handle YYYY-MM-DD format
        parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
      }
    } catch (e) {
      // Fallback to current date if parsing fails
      parsedDate = DateTime.now();
    }

    return GstModel(
      id: json['id']?.toString(),
      hsn: json['HSN']?.toString() ?? '',
      date: parsedDate,
      cgst: double.tryParse(json['cgst']?.toString() ?? '0') ?? 0.0,
      igst: double.tryParse(json['igst']?.toString() ?? '0') ?? 0.0,
      sgst: double.tryParse(json['sgst']?.toString() ?? '0') ?? 0.0,
      companyId: json['CompanyId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'HSN': hsn,
      'date': DateFormat('yyyy-MM-dd').format(date), // Format as YYYY-MM-DD for MySQL
      'cgst': cgst.toString(),
      'igst': igst.toString(),
      'sgst': sgst.toString(),
      'CompanyId': companyId,
    };
  }

  GstModel copyWith({
    String? id,
    String? hsn,
    DateTime? date,
    double? cgst,
    double? igst,
    double? sgst,
    String? companyId,
  }) {
    return GstModel(
      id: id ?? this.id,
      hsn: hsn ?? this.hsn,
      date: date ?? this.date,
      cgst: cgst ?? this.cgst,
      igst: igst ?? this.igst,
      sgst: sgst ?? this.sgst,
      companyId: companyId ?? this.companyId,
    );
  }
}
