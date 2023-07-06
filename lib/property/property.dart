import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_community/components/search.dart';
import 'package:smart_community/account/account.dart';
import 'package:smart_community/property/index.dart';
import 'package:smart_community/utils.dart';

class Property extends StatefulWidget {
  const Property({super.key});

  @override
  State<Property> createState() => _PropertyState();
}

class _PropertyState extends State<Property> {
  late Future<List<RecordModel>> communities;

  late Future<RecordModel> community;

  String? communityId;

  int _index = 0;

  @override
  void initState() {
    communities = pb.collection('communities').getFullList();
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      if (prefs.containsKey('communityId')) {
        fetchCommunity(prefs.getString('communityId')!);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物业端'),
        actions: [
          FutureBuilder(
            future: communities,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<RecordModel>> snapshot,
            ) {
              if (snapshot.hasData) {
                return SearchAction(
                  builder: _searchActionBuilder,
                  records: snapshot.data!,
                  filter: (RecordModel element, String input) =>
                      element.getStringValue('name').contains(input),
                  toElement: (RecordModel element) => ListTile(
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
        ],
      ),
      body: [
        communityId != null
            ? PropertyIndex(communityId: communityId!)
            : FutureBuilder(
                future: communities,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<RecordModel>> snapshot,
                ) {
                  if (snapshot.hasData) {
                    return RecordList(
                      records: snapshot.data!,
                      itemBuilder: (BuildContext context, int index) {
                        final RecordModel element =
                            snapshot.data!.elementAt(index);
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
        onTap: (int index) {
          setState(() {
            _index = index;
          });
        },
      ),
    );
  }

  void fetchCommunity(String id) {
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      prefs.setString('communityId', id);
      setState(
        () {
          communityId = id;
          community = pb.collection('communities').getOne(communityId!);
        },
      );
    });
  }

  Widget _searchActionBuilder(context, controller) {
    return TextButton(
      onPressed: () => controller.openView(),
      child: communityId != null
          ? FutureBuilder(
              future: community,
              builder:
                  (BuildContext context, AsyncSnapshot<RecordModel> snapshot) {
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
