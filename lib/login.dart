import 'package:flutter/material.dart';
import 'package:qr_reader/request.dart';
import 'package:qr_reader/secure_storage.dart';

import 'alert.dart';
import 'appbar.dart';
import 'menu.dart';

class AuthChecker extends StatefulWidget {
  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  late Future<bool> _authSetup;

  @override
  void initState() {
    super.initState();
    _checkAuthToken();

    _authSetup = asyncSetup(); // initState has to be sync
  }

  Future<bool> asyncSetup() async {
    await setupDioInterceptors(
      getToken: tokenStorage.getToken,
      getRefreshToken: refreshStorage.getToken,
      saveToken: tokenStorage.saveToken,
      saveRefreshToken: refreshStorage.saveToken,
      onUnauthorized: () {
        logout();
      },
    );
    await _checkAuthToken();
    return true;
  }

  void logout() {
    setState(() {
      tokenStorage.deleteToken();
      refreshStorage.deleteToken();
      _isAuthenticated = false;
    });
  }

  Future<void> _checkAuthToken() async {
    Map<String, dynamic>? response = await sendRequest('GET', 'whoami');

    try {
      if (response != null &&
          response.containsKey('success') &&
          response['success']) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print(e);
    }

    logout();
  }

  void _onLogin() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authSetup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_isAuthenticated) {
          return MenuScreen(logout);
        }
        return LoginScreen(onLoginSuccess: _onLogin);
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  LoginScreen({required this.onLoginSuccess});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      Map<String, dynamic>? response = await sendRequest('POST', 'token/',
          body: {'username': username, 'password': password});

      if (response != null && response.containsKey('access')) {
        tokenStorage.saveToken(response['access']);
        refreshStorage.saveToken(response['refresh']);
        onLoginSuccess();
      } else {
        await raiseErrorFlushbar(context, "Произошла ошибка запроса");
      }
    } else {
      raiseErrorFlushbar(context, "Пароль и логин должны быть заполнены");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}
