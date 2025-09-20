class StateModel {
  final int id;
  final String name;
  final String code;
  final String tin;

  StateModel({
    required this.id,
    required this.name,
    required this.code,
    required this.tin,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      tin: json['tin'].toString(),
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
