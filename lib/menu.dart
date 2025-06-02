import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:qr_reader/alert.dart';
import 'package:qr_reader/appbar.dart';
import 'package:qr_reader/qr_mini_app.dart';
import 'package:qr_reader/request.dart';
import 'package:qr_reader/settings.dart';

import 'canteen_manager_mini_app.dart';
import 'canteen_mini_app.dart';
import 'dispatch_mini_app.dart';

class _IconInfo {
  final IconData icon;
  final String title;
  final bool isAvailable;
  final Widget screen;

  _IconInfo(
      {required this.icon,
      required this.title,
      required this.isAvailable,
      required this.screen});
}

class ChangePasswordScreen extends StatelessWidget {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Необходимо сменить пароль'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Старый пароль',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Новый пароль',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final oldPass = oldPasswordController.text;
                  final newPass = newPasswordController.text;

                  if (oldPass.isEmpty || newPass.isEmpty) {
                    raiseErrorFlushbar(context, "Заполните оба поля");
                    return;
                  }

                  try {
                    Map<String, dynamic>? response = await sendRequest(
                        'POST', 'auth/change_password/', body: {
                      'old_password': oldPass,
                      'new_password': newPass
                    });


                  } on DioException catch (e) {
                    print(e.error);
                    print(e.message);
                    print(e.response);
                    if (e.response?.data["error"] != null) {
                      raiseErrorFlushbar(context, e.response?.data["error"]);
                    } else if (e.response?.data["old_password"] != null) {
                      raiseErrorFlushbar(context, "Старый пароль неправильный");
                    }
                  }

                  Navigator.pop(context);
                  raiseSuccessFlushbar(context, "Пароль изменён");
                },
                child: const Text('Сменить пароль'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MenuScreen(this.onLogout, {super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<void> _menuSetup;

  List<_IconInfo> _iconInfo = [];

  @override
  void initState() {
    super.initState();
    _menuSetup = asyncSetup(); // initState has to be sync
  }

  Future<void> asyncSetup() async {
    Map<String, dynamic>? response = await sendRequest('GET', 'whoami');

    bool isQrServiceAvailable = false;
    bool isCanteenServiceAvailable = false;
    bool isCanteenManagerAvailable = false;
    bool isDispatchAvailable = true;

    try {
      if (response != null && response['must_change_password']) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
        );
      }

      if (response != null &&
          response.containsKey('success') &&
          response['success']) {
        if (response['groups'].contains('qr_guard') &&
            response['extra'].containsKey('guard_id')) {
          await config.code
              .setSetting(response['extra']['guard_id'].toString());
          isQrServiceAvailable = true;
        }
        if (response['groups'].contains('canteen_employee')) {
          isCanteenServiceAvailable = true;
        }
        if (response['groups'].contains('canteen_manager')) {
          isCanteenManagerAvailable = true;
        }
      }
    } catch (e) {
      print("Failed to parse whoiam request: $e");
    }

    if (response != null) {
      config.userId.setSetting(response['id'].toString());
    }

    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();

    if (token != null) {
      sendRequest('POST', 'register_notification_token',
          body: {'notification_token': token});
    }

    _iconInfo = [
      _IconInfo(
          icon: Icons.fastfood,
          title: 'Столовая',
          isAvailable: isCanteenServiceAvailable,
          screen: const CanteenMiniApp()),
      _IconInfo(
          icon: Icons.fastfood,
          title: 'Столовая (менеджер)',
          isAvailable: isCanteenManagerAvailable,
          screen: const CanteenManagerMiniApp()),
      _IconInfo(
          icon: Icons.qr_code,
          title: 'Обход',
          isAvailable: isQrServiceAvailable,
          screen: QRMiniApp()),
      _IconInfo(
          icon: Icons.warning_amber_outlined,
          title: 'Диспетчеризация',
          isAvailable: isDispatchAvailable,
          screen: IncidentMiniApp()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _menuSetup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(context, widget.onLogout),
          body: IconGrid(columns: 3, iconInfo: _iconInfo),
        );
      },
    );
  }
}

class IconGrid extends StatelessWidget {
  final int columns;
  final List<_IconInfo> iconInfo;

  IconGrid({Key? key, required this.columns, required this.iconInfo})
      : super(key: key);

  void _onIconPressed(BuildContext context, _IconInfo info) {
    if (info.isAvailable) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => info.screen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: iconInfo.length,
      itemBuilder: (context, index) {
        final info = iconInfo[index];
        return GestureDetector(
          onTap: () => _onIconPressed(context, info),
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  info.icon,
                  size: 48.0,
                  color: info.isAvailable ? Colors.green : Colors.grey,
                ),
                SizedBox(height: 8.0),
                AutoSizeText(
                  info.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  wrapWords: false,
                ),
                Expanded(
                  child: AutoSizeText(
                    info.isAvailable ? 'Доступно' : 'Недоступно',
                    style: TextStyle(
                      color: info.isAvailable ? Colors.green : Colors.grey,
                    ),
                    maxLines: 2,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
