import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:smart_community/resident/account/account.dart';
import 'package:smart_community/resident/index/index.dart';

import 'package:smart_community/utils.dart';

// 参见 https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html
// 居民端页面组件
class Resident extends StatefulWidget {
  // 小区 ID
  final String communityId;

  const Resident({super.key, required this.communityId});

  @override
  State<Resident> createState() => _ResidentState();
}

class _ResidentState extends State<Resident> {
  int _index = 0;

  late Future<RecordModel> communityName;
  late Future<List<RecordModel>> notifications;

  @override
  void initState() {
    super.initState();

    // 参见 https://docs.flutter.dev/cookbook/networking/fetch-data
    communityName = pb.collection('communities').getOne(widget.communityId);
    notifications = pb.collection('notifications').getFullList(
          filter: 'communityId = "${widget.communityId}"',
          sort: '-created',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 参见 https://docs.flutter.dev/cookbook/networking/fetch-data#complete-example
        // FutureBuilder 确实比 setState 好用
        title: FutureBuilder(
          future: communityName,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.getStringValue('name'));
            } else if (snapshot.hasError) {
              showException(context, snapshot.error);
            }
            return const Text('加载中');
          },
        ),
      ),
      body: [
        // 首页
        FutureBuilder(
          future: notifications,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ResidentIndex(
                communityId: widget.communityId,
                notifications: snapshot.data!,
              );
            } else if (snapshot.hasError) {
              showException(context, snapshot.error);
            }
            // 使用进度条会使得切换页面时出现闪现的黑条，因此这里直接用一个空容器占位
            // return const LinearProgressIndicator();
            return Container();
          },
        ),
        // 我的
        const ResidentAccount(),
      ].elementAt(_index),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _index,
        onTap: (index) {
          setState(() {
            _index = index;
          });
        },
      ),
    );
  }
}
