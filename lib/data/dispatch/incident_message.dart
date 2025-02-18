import 'dart:convert';

import '../common/user.dart';

class MessageContent {
  final String? text;
  final String? photoUrl;
  final String? videoUrl;
  final String? audioUrl;

  MessageContent({
    required this.text,
    required this.photoUrl,
    required this.videoUrl,
    required this.audioUrl,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      text: json['text'],
      photoUrl: json['photo'],
      videoUrl: json['video'],
      audioUrl: json['audio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'photo': photoUrl,
      'video': videoUrl,
      'audio': audioUrl,
    };
  }
}

class IncidentMessage {
  final int id;
  final User? user;
  final String createdAt;
  final String type;
  final MessageContent contentObject;

  IncidentMessage({
    required this.id,
    this.user,
    required this.createdAt,
    required this.type,
    required this.contentObject,
  });

  factory IncidentMessage.fromJson(Map<String, dynamic> json) {
    return IncidentMessage(
      id: json['id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      createdAt: json['created_at'],
      type: json['message_type'],
      contentObject: MessageContent.fromJson(json['content']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'created_at': createdAt,
      'message_type': type,
      'content_object': contentObject.toJson(),
    };
  }

  static List<IncidentMessage> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => IncidentMessage.fromJson(json)).toList();
  }
}
