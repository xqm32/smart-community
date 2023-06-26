import 'package:flutter/material.dart';
import 'package:smart_community/utils.dart';
import 'package:smart_community/login.dart';

// 注册页面组件
class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // 使用 Center 将内容居中
      body: Center(
        // 外侧加入边距，这样显得好看些😊
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RegisterForm(),
            ],
          ),
        ),
      ),
    );
  }
}

// 注册表单组件
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // 参见 https://api.flutter.dev/flutter/widgets/Form-class.html#widgets.Form.1
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 参见 https://docs.flutter.dev/cookbook/forms/text-field-changes#2-use-a-texteditingcontroller
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  @override
  void dispose() {
    // 参见 https://docs.flutter.dev/cookbook/forms/text-field-changes#create-a-texteditingcontroller 中的 Note
    // 释放 controller 的资源
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 参见 https://github.com/pocketbase/dart-sdk#error-handling
    // TODO: 完善这里的页面导航
    void onRegisterPressed() {
      final body = <String, dynamic>{
        'username': _usernameController.text,
        'password': _passwordController.text,
        'passwordConfirm': _passwordConfirmController.text,
        'role': 'resident',
      };

      pb
          .collection('users')
          .create(body: body)
          .then((value) => navGoto(context, const Login()))
          .catchError((error) => showError(context, error));
    }

    // TODO: 表单验证
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              hintText: '请输入手机号',
            ),
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '请输入密码',
            ),
            // 隐藏密码
            obscureText: true,
          ),
          TextFormField(
            controller: _passwordConfirmController,
            decoration: const InputDecoration(
              labelText: '确认密码',
              hintText: '请再次输入密码',
            ),
            // 隐藏密码
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRegisterPressed,
            child: const Text('注册'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => navGoto(context, const Login()),
            child: const Text('登陆'),
          )
        ],
      ),
    );
  }
}
