import 'package:flutter/material.dart';

import 'package:smart_community/login.dart';
import 'package:smart_community/utils.dart';

class ResidentAccount extends StatelessWidget {
  const ResidentAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const ResidentAccountAvatar(),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.person),
              onTap: () {},
              title: const Text('修改信息'),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.lock),
              onTap: () {},
              title: const Text('修改密码'),
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: () {
                pb.authStore.clear();
                navGoto(context, const Login());
              },
              title: const Text('退出登陆', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class ResidentAccountAvatar extends StatelessWidget {
  const ResidentAccountAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final String avatar = pb.authStore.model.getStringValue('avatar');

    NetworkImage? image;
    Widget? avatarText;

    if (avatar.isNotEmpty) {
      image =
          NetworkImage(pb.getFileUrl(pb.authStore.model, avatar).toString());
    } else {
      avatarText = const Text('头像');
    }

    return ListTile(
      onTap: () {},
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
                pb.authStore.model.getStringValue('name'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '用户名：${pb.authStore.model.getStringValue('username')}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              )
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.navigate_next),
    );
  }
}
