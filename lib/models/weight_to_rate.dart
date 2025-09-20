class WeightToRate {
  final int? id;
  final String weight;
  final double below250;
  final double above250;

  WeightToRate({
    this.id,
    required this.weight,
    required this.below250,
    required this.above250,
  });

  factory WeightToRate.fromJson(Map<String, dynamic> json) {
    print('WeightToRate.fromJson: $json');
    
    // Helper function to parse the value to double
    double parseValue(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        // Remove any non-numeric characters except decimal point
        final numericString = value.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(numericString) ?? 0.0;
      }
      return 0.0;
    }

    return WeightToRate(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      weight: json['weight']?.toString() ?? '',
      below250: parseValue(json['below250']),
      above250: parseValue(json['above250']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight': weight,
      'below250': below250,
      'above250': above250,
    };
  }

  WeightToRate copyWith({
    int? id,
    String? weight,
    double? below250,
    double? above250,
  }) {
    return WeightToRate(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      below250: below250 ?? this.below250,
      above250: above250 ?? this.above250,
    );
  }
}
