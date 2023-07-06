import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_community/login.dart';
import 'package:smart_community/utils.dart';

class AccountPassword extends StatelessWidget {
  const AccountPassword({super.key});

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('修改密码')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _PasswordForm(),
              ],
            ),
          ),
        ),
      );
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm();

  @override
  State<_PasswordForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_PasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _fields = ['password', 'passwordConfirm', 'oldPassword'];
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    _controllers = {
      for (final String i in _fields) i: TextEditingController(),
    };
    super.initState();
  }

  @override
  void dispose() {
    for (final TextEditingController element in _controllers.values) {
      element.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _controllers['oldPassword'],
              decoration: const InputDecoration(
                labelText: '原密码',
                hintText: '请输入原密码',
              ),
              validator: passwordValidator,
              obscureText: true,
            ),
            TextFormField(
              controller: _controllers['password'],
              decoration: const InputDecoration(
                labelText: '新密码',
                hintText: '请输入新密码',
              ),
              validator: passwordValidator,
              obscureText: true,
            ),
            TextFormField(
              controller: _controllers['passwordConfirm'],
              decoration: const InputDecoration(
                labelText: '确认密码',
                hintText: '请再次输入新密码',
              ),
              validator: (final String? value) {
                final String? result = passwordValidator(value);
                if (result != null) {
                  return result;
                }
                if (value != _controllers['password']!.text) {
                  return '两次输入密码不一致';
                }
                return null;
              },
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onSubmitPressed,
              child: const Text('确认修改'),
            ),
          ],
        ),
      );

  void _onSubmitPressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Map<String, String> body = {
      for (final MapEntry<String, TextEditingController> i
          in _controllers.entries)
        i.key: i.value.text
    };
    pb
        .collection('users')
        .update(pb.authStore.model.id, body: body)
        .then(
          (final RecordModel value) => SharedPreferences.getInstance()
              .then((final SharedPreferences prefs) {
            pb.authStore.clear();
            prefs.clear();
            showSuccess(context, '修改成功');
            return navGoto(context, const Login());
          }),
        )
        .catchError(_onError);
  }

  void _onError(final error) {
    if (error.statusCode == 0) {
      showError(context, '网络错误');
    } else if (error.statusCode == 400) {
      showError(context, '原密码错误');
    } else {
      showException(context, error);
    }
  }
}
