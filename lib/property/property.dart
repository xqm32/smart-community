import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

// 参见 https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html
// 物业端页面组件
class Property extends StatefulWidget {
  // 小区 ID
  final String communityId;

  const Property({super.key, required this.communityId});

  @override
  State<Property> createState() => _PropertyState();
}

class _PropertyState extends State<Property> {
  // _selectedIndex 下标所指定的页面
  static const List<Widget> _widgetOptions = [
    Text('首页'),
    // Text('通知'),
    Text('设置'),
  ];

  int _selectedIndex = 0;

  late Future<RecordModel> communityName;

  @override
  void initState() {
    communityName = pb.collection('communities').getOne(widget.communityId);

    super.initState();
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
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.notifications),
          //   label: '通知',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
