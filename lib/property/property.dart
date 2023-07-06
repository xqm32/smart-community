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
    SharedPreferences.getInstance().then((final SharedPreferences prefs) {
      if (prefs.containsKey('communityId')) {
        fetchCommunity(prefs.getString('communityId')!);
      }
    });

    super.initState();
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('物业端'),
        actions: [
          FutureBuilder(
            future: communities,
            builder: (
              final BuildContext context,
              final AsyncSnapshot<List<RecordModel>> snapshot,
            ) {
              if (snapshot.hasData) {
                return SearchAction(
                  builder: _searchActionBuilder,
                  records: snapshot.data!,
                  filter: (final RecordModel element, final String input) =>
                      element.getStringValue('name').contains(input),
                  toElement: (final RecordModel element) => ListTile(
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
        if (communityId != null) PropertyIndex(communityId: communityId!) else FutureBuilder(
                future: communities,
                builder: (
                  final BuildContext context,
                  final AsyncSnapshot<List<RecordModel>> snapshot,
                ) {
                  if (snapshot.hasData) {
                    return RecordList(
                      records: snapshot.data!,
                      itemBuilder: (final BuildContext context, final int index) {
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
        onTap: (final int index) {
          setState(() {
            _index = index;
          });
        },
      ),
    );

  void fetchCommunity(final String id) {
    SharedPreferences.getInstance().then((final SharedPreferences prefs) {
      prefs.setString('communityId', id);
      setState(
        () {
          communityId = id;
          community = pb.collection('communities').getOne(communityId!);
        },
      );
    });
  }

  Widget _searchActionBuilder(final context, final controller) => TextButton(
      onPressed: () => controller.openView(),
      child: communityId != null
          ? FutureBuilder(
              future: community,
              builder:
                  (final BuildContext context, final AsyncSnapshot<RecordModel> snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!.getStringValue('name'));
                }
                return Container();
              },
            )
          : const Text('请选择小区'),
    );
}
