class DutyPoint {
  final int id;
  final String name;

  DutyPoint({
    required this.id,
    required this.name,
  });

  factory DutyPoint.fromJson(Map<String, dynamic> json) {
    return DutyPoint(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  static List<DutyPoint> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => DutyPoint.fromJson(json)).toList();
  }
}
