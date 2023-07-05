import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_community/property/property.dart';
import 'package:smart_community/register.dart';
import 'package:smart_community/resident/resident.dart';
import 'package:smart_community/utils.dart';


class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}


class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _fields = ['username', 'password'];
  Map<String, TextEditingController> _controllers = {};

  String _role = 'resident';

  @override
  void initState() {
    _controllers = {
      for (final i in _fields) i: TextEditingController(),
    };

    SharedPreferences.getInstance().then((prefs) {
      final username = prefs.getString('username');
      final password = prefs.getString('password');
      final selectedRole = prefs.getString('role');

      if (username == null || password == null || selectedRole == null) {
        return;
      } else {
        _login(username, password, selectedRole);
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    for (var i in _controllers.values) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _roleChoice(),
          TextFormField(
            controller: _controllers['username'],
            decoration: const InputDecoration(
              labelText: '用户名',
              hintText: '请输入用户名',
            ),
            validator: usernameValidator,
          ),
          TextFormField(
            controller: _controllers['password'],
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
            ),
            validator: passwordValidator,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onLoginPressed,
            child: const Text('登陆'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => navGoto(context, const Register()),
            child: const Text('注册'),
          )
        ],
      ),
    );
  }

  void _onLoginPressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _login(
      _controllers['username']!.text,
      _controllers['password']!.text,
      _role,
    );
  }

  void _login(String username, String password, String selectedRole) {
    pb
        .collection('users')
        .authWithPassword(username, password)
        .then((record) => _didLogin(record, username, password, selectedRole))
        .catchError(_onError);
  }

  void _didLogin(
    RecordAuth record,
    String username,
    String password,
    String selectedRole,
  ) {
    final role = record.record!.getListValue('role');

    if (!role.contains(selectedRole)) {
      SharedPreferences.getInstance().then((prefs) {
        if (prefs.containsKey('role')) {
          prefs.clear();
          showError(context, '角色令牌过期');
        } else {
          showError(context, '角色不匹配');
        }
      });

      return;
    }

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('username', username);
      prefs.setString('password', password);
      prefs.setString('role', selectedRole);
    });

    if (selectedRole == 'resident') {
      navGoto(context, const Resident());
    } else if (selectedRole == 'property') {
      navGoto(context, const Property());
    }
  }

  void _onError(error) {
    SharedPreferences.getInstance().then((prefs) {
      if (error.statusCode == 0) {
        showError(context, '网络错误');
      } else if (error.statusCode == 400) {
        if (prefs.containsKey('username') || prefs.containsKey('password')) {
          prefs.clear();
          showError(context, '用户令牌过期');
        } else {
          showError(context, '用户名或密码错误');
        }
      } else {
        showException(context, error);
      }
    });
  }

  Widget _roleChoice() {
    return SegmentedButton(
      segments: const [
        ButtonSegment(
          value: 'resident',
          label: Text('居民'),
        ),
        ButtonSegment(
          value: 'property',
          label: Text('物业'),
        ),
      ],
      selected: {_role},
      onSelectionChanged: (value) => setState(() => _role = value.first),
    );
  }
}
