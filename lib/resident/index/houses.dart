import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:smart_community/components/manage.dart';

import 'package:smart_community/resident/index/house.dart';
import 'package:smart_community/utils.dart';

// 居民端/首页/房屋管理
class ResidentHouseList extends StatelessWidget {
  const ResidentHouseList({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Manage(
      fetchRecords: fetchRecords,
      onAddPressed: onAddPressed,
      toElement: toElement,
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    // 后端存在规则时可以移除「&& userId = "${pb.authStore.model!.id}"」
    final String filter =
        'communityId = "$communityId" && userId = "${pb.authStore.model!.id}"';
    return pb
        .collection('houses')
        .getFullList(filter: filter, sort: '-created');
  }

  void onAddPressed(BuildContext context, void Function() refreshRecords) {
    navPush(
      context,
      ResidentHouse(communityId: communityId),
    ).then((value) => refreshRecords());
  }

  Widget toElement(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) {
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
          ResidentHouse(communityId: communityId, recordId: record.id),
        ).then((value) => refreshRecords());
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
