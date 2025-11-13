import 'package:flutter/material.dart';
import 'package:qr_reader/request.dart';
import 'package:qr_reader/settings.dart';
import 'package:intl/intl.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({super.key});

  static final GlobalKey<_NotificationBadgeState> globalKey =
      GlobalKey<_NotificationBadgeState>();

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final userId = int.parse(await config.userId.getSetting() ?? '0');
      final response = await sendRequest("GET", "users/notifications/$userId/");
      final notifications = response as List<dynamic>;
      setState(() {
        _unreadCount = notifications.where((n) => n['is_seen'] == false).length;
      });
    } catch (error) {
      print('Error loading notification count: $error');
    }
  }

  void refreshUnreadCount() {
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Icon(
          Icons.notifications,
          size: 28,
          color: Colors.white,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoadingNotifications = true;
  late int userId;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      userId = int.parse(await config.userId.getSetting() ?? '0');
      final response = await sendRequest("GET", "users/notifications/$userId/");
      setState(() {
        notifications = response;
        isLoadingNotifications = false;
        _unreadCount = notifications.where((n) => n['is_seen'] == false).length;
      });
    } catch (error) {
      setState(() {
        isLoadingNotifications = false;
      });
      print('Error fetching notifications: $error');
    }
  }

  Future<void> _readNotification(int notificationId) async {
    try {
      userId = int.parse(await config.userId.getSetting() ?? '0');

      await sendRequest(
          "POST", "users/notifications/$userId/mark_as_read/$notificationId/");

      setState(() {
        // _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        final index =
            notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          notifications[index]['is_seen'] = true;
        }
      });

      await _loadNotifications(); // Обновляем список
    } catch (error) {
      setState(() {
        _unreadCount++;
      });
      print('Error marking notification as read: $error');
    }
  }

  Widget _buildReadButton(bool isSeen, int notificationId) {
    if (isSeen) {
      // Если уже прочитано - неактивная кнопка
      return FilledButton.tonal(
        onPressed: null,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.grey.shade600,
        ),
        child: const Text('Прочитано'),
      );
    } else {
      // Если не прочитано - активная кнопка
      return FilledButton.tonal(
        onPressed: () {
          _readNotification(notificationId);
        },
        style: FilledButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade100,
          foregroundColor: Colors.grey.shade800,
        ),
        child: const Text('Прочитать'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        toolbarHeight: 65,
        titleTextStyle: TextStyle(color: Theme.of(context).canvasColor),
        title: Text('Уведомления'),
      ),
      body: isLoadingNotifications
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text('Нет уведомлений'))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    var notification = notifications[index];

                    String title = notification['title'];
                    String text = notification['text'];
                    String source = notification['source'];

                    if (text.length > 500) {
                      text = "${text.substring(0, 500)}...";
                    }

                    String formattedDate = "";
                    if (notification['created_at'] != null) {
                      DateTime createdAt =
                          DateTime.parse(notification['created_at']);
                      formattedDate =
                          DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Заголовок: $title',
                                style: TextStyle(color: Colors.grey[700])),
                            Text('Источник: $source',
                                style: TextStyle(color: Colors.grey[700])),
                            Text('Дата: $formattedDate',
                                style: TextStyle(color: Colors.grey[700])),
                            Align(
                                alignment: Alignment.centerRight,
                                child: _buildReadButton(
                                    notification['is_seen'] ?? false,
                                    notification['id']))
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
