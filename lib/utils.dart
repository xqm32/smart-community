import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

// PocketBase 实例
final pb = PocketBase('http://127.0.0.1:8090');

void navPush(context, widget) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => widget,
  ));
}

void navPop(context) {
  Navigator.of(context).pop();
}

void navGoto(context, widget) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => widget),
    (route) => false,
  );
}

void showException(context, error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
}

// 参见 https://api.flutter.dev/flutter/material/SnackBar-class.html
void showError(context, error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('$error'),
    backgroundColor: Theme.of(context).colorScheme.error,
  ));
}

// 参见 https://docs.flutter.dev/cookbook/forms/validation
String? usernameValidator(String? value) {
  if (value == null || value.isEmpty || value.length < 3) {
    return '用户名长度至少为 3';
  } else {
    return null;
  }
}

String? passwordValidator(String? value) {
  if (value == null || value.isEmpty || value.length < 8) {
    return '密码长度至少为 8';
  } else {
    return null;
  }
}

String? Function(String?) notNullValidator(String message) {
  return (String? value) {
    if (value == null || value.isEmpty) {
      return message;
    } else {
      return null;
    }
  };
}
