import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_community/components/search.dart';
import 'package:smart_community/account/account.dart';
import 'package:smart_community/resident/index/index.dart';
import 'package:smart_community/utils.dart';

// 居民端
class Resident extends StatefulWidget {
  const Resident({super.key});

  @override
  State<Resident> createState() => _ResidentState();
}

class _ResidentState extends State<Resident> {
  // 小区列表
  late Future<List<RecordModel>> communities;
  // 当前选择的小区
  late Future<RecordModel> community;

  // 当前选择的小区 ID
  String? communityId;
  // 底部导航栏索引
  int _index = 0;

  @override
  void initState() {
    communities = pb.collection('communities').getFullList();
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey('communityId')) {
        fetchCommunity(prefs.getString('communityId')!);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('居民端'), actions: [
        // 右上角选择小区按钮
        FutureBuilder(
          future: communities,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SearchAction(
                builder: _searchActionBuilder,
                records: snapshot.data!,
                test: (element, input) =>
                    element.getStringValue('name').contains(input),
                toElement: (element) => ListTile(
                  title: Text(element.getStringValue('name')),
                  onTap: () {
                    fetchCommunity(element.id);
                    navPop(context);
                  },
                ),
              );
            }
            return Container();
          },
        )
      ]),
      body: [
        // 居民端/首页
        communityId != null
            ? ResidentIndex(communityId: communityId!)
            : FutureBuilder(
                future: communities,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return RecordList(
                      records: snapshot.data!,
                      itemBuilder: (context, index) {
                        final element = snapshot.data!.elementAt(index);
                        return ListTile(
                          title: Text(element.getStringValue('name')),
                          onTap: () => fetchCommunity(element.id),
                        );
                      },
                    );
                  }
                  return Container();
                },
              ),

        // 居民端/我的
        const Account(),
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

  // 选择小区
  void fetchCommunity(String id) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('communityId', id);
      setState(
        () {
          communityId = id;
          community = pb.collection('communities').getOne(communityId!);
        },
      );
    });
  }

  // 右上角选择小区按钮
  Widget _searchActionBuilder(context, controller) {
    return TextButton(
      onPressed: () => controller.openView(),
      // 没有选择小区时显示「请选择小区」，有小区时显示小区名
      child: communityId != null
          ? FutureBuilder(
              future: community,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!.getStringValue('name'));
                }
                return Container();
              },
            )
          : const Text('请选择小区'),
    );
  }
}
