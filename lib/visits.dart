import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum PointType {
  defaultType('default'),
  fireExtinguisher('fire_extinguisher');

  final String label;

  const PointType(this.label);

  static PointType fromString(String label) {
    return values.firstWhere(
      (v) => v.label == label,
      orElse: () => PointType.defaultType,
    );
  }
}

class Point {
  final String name;
  final PointType pointType;
  final DateTime? expirationDate;
  final bool hasFireExtinguisher;

  Point({
    required this.name,
    required this.pointType,
    this.expirationDate,
    this.hasFireExtinguisher = false,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      name: json['name'],
      pointType: PointType.fromString(json['point_type']),
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'])
          : null,
    );
  }

  bool isExpired() {
    if (expirationDate == null) return false;
    DateTime today = DateTime.now();
    DateTime currentDate = DateTime(today.year, today.month, today.day);
    return !currentDate.isBefore(expirationDate!);
  }

  @override
  String toString() {
    return 'Point(name: $name, pointType: ${pointType.name}, '
        'expirationDate: ${expirationDate?.toIso8601String()}, '
        'hasFireExtinguisher: $hasFireExtinguisher)';
  }
}

class Visit {
  final Point point;
  final DateTime _timestamp;

  Visit(this.point, int timestamp)
      : _timestamp =
            DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: false);

  String timeAgo() {
    Duration diff = DateTime.now().toUtc().difference(_timestamp);
    return formatTimeAgo(diff.inSeconds);
  }

  @override
  String toString() {
    return 'Visit at: ${_timestamp.toIso8601String()}';
  }
}

String formatTimeAgo(int seconds) {
  if (seconds < 60) {
    return 'менее минуты назад';
  } else if (seconds < 3600) {
    int minutes = seconds ~/ 60;
    return '$minutes ${pluralize(minutes, [
          'минуту',
          'минуты',
          'минут'
        ])} назад';
  } else if (seconds < 86400) {
    int hours = seconds ~/ 3600;
    return '$hours ${pluralize(hours, ['час', 'часа', 'часов'])} назад';
  } else {
    int days = seconds ~/ 86400;
    return '$days ${pluralize(days, ['день', 'дня', 'дней'])} назад';
  }
}

// Helper function to determine the correct form of the noun
String pluralize(int number, List<String> forms) {
  int n = number % 100;
  if (n > 10 && n < 20) {
    return forms[2];
  } else {
    switch (n % 10) {
      case 1:
        return forms[0];
      case 2:
      case 3:
      case 4:
        return forms[1];
      default:
        return forms[2];
    }
  }
}

class VisitStorage {
  final List<Visit> _visits = [];

  VisitStorage();

  void addVisit(Visit visit) {
    _visits.add(visit);
  }

  void clear() {
    _visits.clear();
  }

  List<Visit> get visits => List.unmodifiable(_visits);

  @override
  String toString() {
    return _visits.map((v) => v.toString()).join(', ');
  }
}

class VisitListWidget extends StatefulWidget {
  final VisitStorage storage;

  VisitListWidget({required this.storage});

  @override
  _VisitListWidgetState createState() => _VisitListWidgetState();
}

class _VisitListWidgetState extends State<VisitListWidget> {
  Timer? _timer;

  void addVisit(Visit visit) {
    setState(() {
      widget.storage.addVisit(visit);
    });
  }

  @override
  void initState() {
    super.initState();
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatExpiration(Point point) {
    String result = 'Срок годности ${point.expirationDate!.toIso8601String().split('T').first}';
    if (point.isExpired()) {
      result += ' истек!';
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      shrinkWrap: true,
      reverse: true,
      itemCount: widget.storage.visits.length + 1,
      itemBuilder: (context, index) {
        if (index == widget.storage.visits.length) {
          return const ListTile(); // Extra empty tie for scroll to top
        }

        bool isExpired = widget.storage.visits.reversed.elementAt(index).point.isExpired();

        return ListTile(
          visualDensity: VisualDensity.compact,
          horizontalTitleGap: 10,
          leading:
              widget.storage.visits.reversed.elementAt(index).point.pointType ==
                      PointType.fireExtinguisher
                  ? const Icon(
                      Icons.fire_extinguisher,
                      color: Colors.red,
                      size: 35,
                    )
                  : null,
          title: Text(
            style: TextStyle(fontSize: 15),
            widget.storage.visits.reversed.elementAt(index).point.name,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                style: TextStyle(fontSize: 13),
                widget.storage.visits.reversed.elementAt(index).timeAgo(),
              ),
              if (widget.storage.visits.reversed.elementAt(index).point.expirationDate != null)
                Text(
                  _formatExpiration(widget.storage.visits.reversed.elementAt(index).point),
                  style: TextStyle(
                    fontSize: 13,
                    color: isExpired ? Colors.red : Colors.black,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
