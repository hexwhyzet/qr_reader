import 'dart:convert';

import '../common/user.dart';
import 'duty_point.dart';

class Incident {
  final int id;
  final String name;
  final String description;
  final String status;
  final String displayStatus;
  final int level;
  final bool isCritical;
  final User? author;
  final User? responsibleUser;
  final DutyPoint? point;
  final DateTime createdAt;
  final bool isAccepted;

  Incident({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.displayStatus,
    required this.level,
    required this.isCritical,
    this.author,
    this.responsibleUser,
    this.point,
    required this.createdAt,
    required this.isAccepted,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      displayStatus: json['display_status'],
      level: json['level'],
      isCritical: json['is_critical'],
      author: json['author'] != null ? User.fromJson(json['author']) : null,
      responsibleUser: json['responsible_user'] != null
          ? User.fromJson(json['responsible_user'])
          : null,
      point: json['point'] != null ? DutyPoint.fromJson(json['point']) : null,
      createdAt: DateTime.parse(json['created_at']), // Parse created_at
      isAccepted: json['is_accepted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
      'display_status': displayStatus,
      'level': level,
      'is_critical': isCritical,
      'author': author?.toJson(),
      'responsible_user': responsibleUser?.toJson(),
      'point': point?.toJson(),
      'created_at': createdAt.toIso8601String(), // Serialize createdAt
      'is_accepted': isAccepted,
    };
  }

  static List<Incident> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Incident.fromJson(json)).toList();
  }
}
