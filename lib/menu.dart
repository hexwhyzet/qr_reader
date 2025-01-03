import 'package:flutter/material.dart';
import 'package:qr_reader/appbar.dart';
import 'package:qr_reader/qr_mini_app.dart';
import 'package:qr_reader/request.dart';
import 'package:qr_reader/settings.dart';

import 'canteen_manager_mini_app.dart';
import 'canteen_mini_app.dart';

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

    try {
      if (response != null &&
          response.containsKey('success') &&
          response['success']) {
        if (response['groups'].contains('QR Guard') &&
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                info.icon,
                size: 48.0,
                color: info.isAvailable ? Colors.green : Colors.grey,
              ),
              SizedBox(height: 8.0),
              Text(info.title, textAlign: TextAlign.center,),
              Text(
                info.isAvailable ? 'Доступно' : 'Недоступно',
                style: TextStyle(
                  color: info.isAvailable ? Colors.green : Colors.grey,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
