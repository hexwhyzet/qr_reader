class DutyRole {
  final int id;
  final String name;

  DutyRole({
    required this.id,
    required this.name,
  });

  factory DutyRole.fromJson(Map<String, dynamic> json) {
    return DutyRole(
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
}
