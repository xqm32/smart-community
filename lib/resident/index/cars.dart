import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/resident/index/car.dart';
import 'package:smart_community/utils.dart';

// 居民端/首页/车辆管理
class ResidentCarList extends StatelessWidget {
  const ResidentCarList({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Manage(
      title: const Text('车辆管理'),
      fetchRecords: fetchRecords,
      onAddPressed: onAddPressed,
      toElement: toElement,
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    // 后端存在规则时可以移除「&& userId = "${pb.authStore.model!.id}"」
    final String filter =
        'communityId = "$communityId" && userId = "${pb.authStore.model!.id}"';
    return pb.collection('cars').getFullList(filter: filter, sort: '-created');
  }

  void onAddPressed(BuildContext context, void Function() refreshRecords) {
    navPush(
      context,
      ResidentCar(communityId: communityId),
    ).then((value) => refreshRecords());
  }

  Widget toElement(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) {
    return ListTile(
      title: Text(record.getStringValue('name')),
      subtitle: Text(record.getStringValue('plate')),
      trailing: _recordState(record),
      onTap: () {
        navPush(
          context,
          ResidentCar(communityId: communityId, recordId: record.id),
        ).then((value) => refreshRecords());
      },
    );
  }

  Widget _recordState(RecordModel record) {
    final state = record.getStringValue('state');
    const double fontSize = 16;

    if (state == 'reviewing') {
      return const Text(
        '审核中',
        style: TextStyle(
          color: Colors.orange,
          fontSize: fontSize,
        ),
      );
    } else if (state == 'verified') {
      return const Text(
        '审核通过',
        style: TextStyle(
          color: Colors.green,
          fontSize: fontSize,
        ),
      );
    } else if (state == 'rejected') {
      return const Text(
        '审核未通过',
        style: TextStyle(
          color: Colors.red,
          fontSize: fontSize,
        ),
      );
    }
    return const Text('未知状态');
  }
}
