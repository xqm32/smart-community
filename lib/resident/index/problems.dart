import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/resident/index/problem.dart';
import 'package:smart_community/utils.dart';

// 居民端/首页/问题上报
class ResidentProblemList extends StatelessWidget {
  const ResidentProblemList({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Manage(
      title: const Text('问题上报'),
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
        .collection('problems')
        .getFullList(filter: filter, sort: '-created');
  }

  void onAddPressed(BuildContext context, void Function() refreshRecords) {
    navPush(
      context,
      ResidentProblem(communityId: communityId),
    ).then((value) => refreshRecords());
  }

  Widget toElement(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) {
    return ListTile(
      title: Text(record.getStringValue('title')),
      subtitle: Row(
        children: [
          Text(record.created.split(' ')[0]),
          const SizedBox(width: 16),
          record.getStringValue('state') == 'processing'
              ? Text(
                  '由${record.getStringValue('remark')}处理',
                  style: const TextStyle(color: Colors.grey),
                )
              : const SizedBox(width: 0),
        ],
      ),
      trailing: _recordState(record),
      onTap: () {
        navPush(
          context,
          ResidentProblem(communityId: communityId, recordId: record.id),
        ).then((value) => refreshRecords());
      },
    );
  }

  Widget _recordState(RecordModel record) {
    final state = record.getStringValue('state');
    const double fontSize = 16;

    if (state == 'pending') {
      return const Text(
        '等待处理',
        style: TextStyle(
          color: Colors.grey,
          fontSize: fontSize,
        ),
      );
    } else if (state == 'processing') {
      return const Text(
        '处理中',
        style: TextStyle(
          color: Colors.purple,
          fontSize: fontSize,
        ),
      );
    } else if (state == 'finished') {
      return const Text(
        '处理完毕',
        style: TextStyle(
          color: Colors.green,
          fontSize: fontSize,
        ),
      );
    }
    return const Text('未知状态');
  }
}
