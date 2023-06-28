import 'package:flutter/material.dart';

import 'package:smart_community/property/property.dart';
import 'package:smart_community/resident/resident.dart';
import 'package:smart_community/utils.dart';

class Community extends StatefulWidget {
  final String role;

  const Community({super.key, required this.role});

  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  List<DropdownMenuEntry> communities = [];
  String? communityId;
  String? errorText;

  void _onArrowPressed() {
    if (communityId == null) {
      setState(() {
        errorText = '请选择小区';
      });
    } else {
      // 参见 https://dart.dev/language/pattern-types#null-assert
      // 已经判断 community 不为 null，因此这里使用 ! 来断言
      if (widget.role == 'resident') {
        navPush(context, Resident(communityId: communityId!));
      } else if (widget.role == 'property') {
        navPush(context, Property(communityId: communityId!));
      } else {
        showError(context, '未知角色');
      }
    }
  }

  @override
  void initState() {
    // 初始化下拉菜单，Flutter 中调用属性的方法也会刷新组件
    pb.collection('communities').getFullList().then((value) {
      setState(() {
        for (final i in value) {
          communities.add(DropdownMenuEntry(
            value: i.id,
            label: i.getStringValue('name'),
          ));
        }
      });
    }).catchError((error) {
      showException(context, '$error');
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择小区'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              DropdownMenu(
                label: const Text('小区'),
                dropdownMenuEntries: communities,
                // 这是一个 Bug，DropDownMenu 无法适应父组件的宽度，参见 https://github.com/flutter/flutter/issues/125199
                // 采用一个 workaround，强制规定宽度为 300
                width: 300,
                onSelected: (value) {
                  setState(() {
                    communityId = value;
                  });
                },
                errorText: errorText,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onArrowPressed,
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
