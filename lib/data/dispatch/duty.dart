import 'dart:convert';

import '../common/user.dart';
import 'duty_role.dart';

class Duty {
  final int id;
  final String date;
  final User user;
  final DutyRole role;
  final DateTime start;
  final DateTime end;
  final bool isOpened;

  Duty({
    required this.id,
    required this.date,
    required this.user,
    required this.role,
    required this.start,
    required this.end,
    required this.isOpened,
  });

  factory Duty.fromJson(Map<String, dynamic> json) {
    return Duty(
      id: json['id'],
      date: json['date'],
      user: User.fromJson(json['user']),
      role: DutyRole.fromJson(json['role']),
      start: DateTime.parse(json['start_datetime']),
      end: DateTime.parse(json['end_datetime']),
      isOpened: json['is_opened'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'user': user.toJson(),
      'role': role.toJson(),
      'is_opened': isOpened,
    };
  }

  static List<Duty> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Duty.fromJson(json)).toList();
  }
}
