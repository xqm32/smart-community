import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:smart_community/config.dart';

final PocketBase pb = PocketBase(baseUrl);

Future<dynamic> navPush(final context, final widget) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final BuildContext context) => widget,
      ),
    );

void navPop(final context, [final dynamic result]) {
  Navigator.of(context).pop(result);
}

Future<dynamic> navGoto(final context, final widget) =>
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (final BuildContext context) => widget),
      (final Route route) => false,
    );

void showException(final context, final error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
}

void showError(final context, final error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$error'),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

void showSuccess(final context, final error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$error'),
      backgroundColor: Colors.green,
    ),
  );
}

String? usernameValidator(final String? value) {
  if (value == null || value.isEmpty || value.length < 3) {
    return '用户名长度至少为 3';
  } else {
    return null;
  }
}

String? passwordValidator(final String? value) {
  if (value == null || value.isEmpty || value.length < 8) {
    return '密码长度至少为 8';
  } else {
    return null;
  }
}

String? Function(String?) notNullValidator(final String message) =>
    (final String? value) {
      if (value == null || value.isEmpty) {
        return message;
      } else {
        return null;
      }
    };

String getDate(final String formattedString) {
  final DateTime datetime = DateTime.parse(formattedString).toLocal();
  return datetime.toIso8601String().split('T')[0];
}

String getDateTime(final String formattedString) {
  final DateTime datetime = DateTime.parse(formattedString).toLocal();
  return datetime.toIso8601String().replaceAll('T', ' ').split('.')[0];
}

bool Function(RecordModel, String) keyFilter(final String primaryKey) =>
    (final RecordModel record, final String input) =>
        input.split(' ').every((final String element) {
          if (element.contains(':')) {
            final List<String> elements =
                element.replaceFirst(':', ' ').split(' ');
            final String key = elements.first;
            final String value = elements.last;

            if (key == 'after') {
              final DateTime? datetime = DateTime.tryParse(value);
              return datetime != null
                  ? DateTime.parse(record.created).toLocal().isAfter(datetime)
                  : false;
            } else if (key == 'before') {
              final DateTime? datetime = DateTime.tryParse(value);
              return datetime != null
                  ? DateTime.parse(record.created).toLocal().isBefore(datetime)
                  : false;
            } else if (key == 'userName') {
              return record.expand['userId']?.first
                      .getStringValue('name')
                      .contains(value) ??
                  false;
            } else if (key == 'userPhone') {
              return record.expand['userId']?.first
                      .getStringValue('phone')
                      .contains(value) ??
                  false;
            } else {
              return record.getStringValue(key).contains(value);
            }
          } else {
            return record.getStringValue(primaryKey).contains(element);
          }
        });

void pickImage({
  required final void Function(String filename, Uint8List bytes) update,
}) async {
  const XTypeGroup typeGroup = XTypeGroup(
    label: 'images',
    extensions: <String>['jpg', 'png'],
  );
  final XFile? file =
      await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
  if (file != null) {
    final Uint8List bytes = await file.readAsBytes();

    update(file.name, bytes);
  }
}
