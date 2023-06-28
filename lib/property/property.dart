import 'package:flutter/material.dart';

import '../utils.dart';

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
    Text('通知'),
    Text('设置'),
  ];

  int _selectedIndex = 0;

  String communityName = '物业端';

  @override
  void initState() {
    pb.collection('communities').getOne(widget.communityId).then((value) {
      setState(() {
        communityName = value.getStringValue('name');
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(communityName),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '通知',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
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
