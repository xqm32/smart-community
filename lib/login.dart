import 'package:flutter/material.dart';
import 'package:smart_community/utils.dart';

// 登陆页面组件
class Login extends StatelessWidget {
  const Login({super.key});

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
              LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

// 登陆表单组件
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // 参见 https://api.flutter.dev/flutter/widgets/Form-class.html#widgets.Form.1
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 参见 https://docs.flutter.dev/cookbook/forms/text-field-changes#2-use-a-texteditingcontroller
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // 参见 https://docs.flutter.dev/cookbook/forms/text-field-changes#create-a-texteditingcontroller 中的 Note
    // 释放 controller 的资源
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 参见 https://github.com/pocketbase/dart-sdk#error-handling
    // TODO: 完善这里的页面导航
    void onLoginPressed() {
      pb
          .collection('users')
          .authWithPassword(_usernameController.text, _passwordController.text)
          .then((value) => navPush(context, const Text('登陆成功')))
          .catchError((error) => navPush(context, Text('$error')));
    }

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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onLoginPressed,
            child: const Text('登陆'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            child: const Text('注册'),
          )
        ],
      ),
    );
  }
}
