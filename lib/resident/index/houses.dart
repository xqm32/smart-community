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
  late Future<List<RecordModel>> _records;

  @override
  void initState() {
    _records = fetchRecords();
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
                    _records = fetchRecords();
                  }),
              icon: const Icon(Icons.refresh)),
          FutureBuilder(
            future: _records,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SearchAction(
                  records: snapshot.data!,
                  test: (element, input) =>
                      element.getStringValue('location').contains(input),
                  toElement: _toElement,
                );
              }
              return const Icon(Icons.search);
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RecordList(
                records: snapshot.data!,
                itemBuilder: (context, index) {
                  final element = snapshot.data!.elementAt(index);
                  return _toElement(element);
                });
          }
          return const LinearProgressIndicator();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          navPush(
            context,
            ResidentHouse(communityId: widget.communityId),
          ).then(
            (value) => setState(() {
              _records = fetchRecords();
            }),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    // 后端存在规则时可以移除「&& userId = "${pb.authStore.model!.id}"」
    final String filter =
        'communityId = "${widget.communityId}" && userId = "${pb.authStore.model!.id}"';
    return pb
        .collection('houses')
        .getFullList(filter: filter, sort: '-created');
  }

  Widget _toElement(RecordModel record) {
    return ListTile(
      title: Row(
        children: [
          Text(record.getStringValue('location')),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _recordState(record),
            ),
          )
        ],
      ),
      onTap: () {
        navPush(
          context,
          ResidentHouse(communityId: widget.communityId, recordId: record.id),
        ).then(
          (value) => setState(() {
            _records = fetchRecords();
          }),
        );
      },
    );
  }

  Widget _recordState(RecordModel record) {
    final state = record.getStringValue('state');
    if (state == 'reviewing') {
      return const Text('审核中', style: TextStyle(color: Colors.orange));
    } else if (state == 'verified') {
      return const Text('审核通过', style: TextStyle(color: Colors.green));
    } else if (state == 'rejected') {
      return const Text('审核未通过', style: TextStyle(color: Colors.red));
    }
    return const Text('未知状态');
  }
}
