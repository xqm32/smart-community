import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_community/login.dart';
import 'package:smart_community/account/information.dart';
import 'package:smart_community/account/password.dart';
import 'package:smart_community/utils.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  RecordModel? record = pb.authStore.model;

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (record != null)
                AccountAvatar(
                  record: record!,
                  onTap: () async {
                    const XTypeGroup typeGroup = XTypeGroup(
                      label: 'images',
                      extensions: <String>['jpg', 'png'],
                    );
                    final XFile? file = await openFile(
                      acceptedTypeGroups: <XTypeGroup>[typeGroup],
                    );
                    if (file != null) {
                      final Uint8List bytes = await file.readAsBytes();
                      await pb.collection('users').update(
                        record!.id,
                        files: [
                          MultipartFile.fromBytes(
                            'avatar',
                            bytes,
                            filename: file.name,
                          )
                        ],
                      );
                      setState(() {
                        record = pb.authStore.model;
                      });
                    }
                  },
                ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.person),
                onTap: () async {
                  await navPush(context, const AccountInformation());
                  setState(() {
                    record = pb.authStore.model;
                  });
                },
                title: const Text('修改信息'),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.lock),
                onTap: () => navPush(context, const AccountPassword()),
                title: const Text('修改密码'),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.info),
                onTap: () => showDialog(
                  context: context,
                  builder: (final context) => Dialog(
                    surfaceTintColor: Theme.of(context).colorScheme.background,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          about(),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('关闭'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                title: const Text('关于我们'),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                onTap: () {
                  pb.authStore.clear();
                  SharedPreferences.getInstance()
                      .then((final SharedPreferences prefs) {
                    prefs.clear().then(
                          (final bool value) => navGoto(context, const Login()),
                        );
                  });
                },
                title: const Text('退出登陆', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      );

  Widget about() {
    late final Future<List<RecordModel>> data =
        pb.collection('about').getFullList(sort: '-created');
    return FutureBuilder(
      future: data,
      builder: (final context, final snapshot) {
        if (snapshot.hasData) {
          final List<RecordModel> list = snapshot.data!;
          if (list.isNotEmpty) {
            return MarkdownBody(data: list.first.getStringValue('content'));
          } else {
            return const Text('暂无信息');
          }
        } else {
          return const Text('加载中');
        }
      },
    );
  }
}

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    required this.record,
    required this.onTap,
    super.key,
  });

  final RecordModel record;
  final void Function() onTap;

  @override
  Widget build(final BuildContext context) {
    final String avatar = record.getStringValue('avatar');

    NetworkImage? image;
    Widget? avatarText;

    if (avatar.isNotEmpty) {
      image = NetworkImage(pb.getFileUrl(record, avatar).toString());
    } else {
      avatarText = const Text('头像');
    }

    return ListTile(
      // onTap: onTap,
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: image,
            radius: 32,
            child: avatarText,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.getStringValue('name'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '用户名：${record.getStringValue('username')}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              )
            ],
          ),
        ],
      ),
      trailing: TextButton(
        onPressed: onTap,
        child: const Text('更换头像'),
      ),
    );
  }
}
