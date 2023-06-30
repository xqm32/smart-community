import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/search.dart';
import 'package:smart_community/resident/index/house.dart';
import 'package:smart_community/utils.dart';

// 居民端/首页/房屋管理
class ResidentHouseList extends StatefulWidget {
  const ResidentHouseList({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  State<ResidentHouseList> createState() => _ResidentHouseListState();
}

class _ResidentHouseListState extends State<ResidentHouseList> {
  late Future<List<RecordModel>> houses;

  @override
  void initState() {
    houses = fetchHouses();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('房屋管理'),
        actions: [
          IconButton(
              onPressed: () => setState(() {
                    houses = fetchHouses();
                  }),
              icon: const Icon(Icons.refresh)),
          FutureBuilder(
            future: houses,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SearchAction(
                    records: snapshot.data!,
                    test: (element, input) =>
                        element.getStringValue('location').contains(input),
                    toElement: (element) => ResidentHouseItem(
                        communityId: widget.communityId, record: element));
              }
              return const Icon(Icons.search);
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: houses,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RecordList(
                records: snapshot.data!,
                itemBuilder: (context, index) {
                  final element = snapshot.data!.elementAt(index);
                  return ResidentHouseItem(
                      communityId: widget.communityId, record: element);
                });
          }
          return const LinearProgressIndicator();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            navPush(context, ResidentHouse(communityId: widget.communityId)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<RecordModel>> fetchHouses() {
    // 后端存在规则时可以移除「&& userId = "${pb.authStore.model!.id}"」
    final String filter =
        'communityId = "${widget.communityId}" && userId = "${pb.authStore.model!.id}"';
    return pb
        .collection('houses')
        .getFullList(filter: filter, sort: '-created');
  }
}

class ResidentHouseItem extends StatelessWidget {
  const ResidentHouseItem({
    super.key,
    required this.communityId,
    required this.record,
  });

  final String communityId;
  final RecordModel record;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Text(record.getStringValue('location')),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: record.getBoolValue('verified')
                  ? const Text(
                      '审核通过',
                      style: TextStyle(color: Colors.green),
                    )
                  : const Text('审核中'),
            ),
          )
        ],
      ),
      onTap: () => navPush(
          context, ResidentHouse(communityId: communityId, houesId: record.id)),
    );
  }
}
