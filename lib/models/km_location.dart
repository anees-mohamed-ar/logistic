class KMLocation {
  final int id;
  final String from;
  final String to;
  final String km;

  KMLocation({
    required this.id,
    required this.from,
    required this.to,
    required this.km,
  });

  factory KMLocation.fromJson(Map<String, dynamic> json) {
    return KMLocation(
      id: json['id'],
      from: json['from'],
      to: json['to'],
      km: json['km'],
    );
  }
}
