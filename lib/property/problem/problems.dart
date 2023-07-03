import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/property/problem/problem.dart';
import 'package:smart_community/utils.dart';

// 物业端/首页/事件处置
class PropertyProblems extends StatelessWidget {
  const PropertyProblems({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Manage(
      title: const Text('事件处置'),
      fetchRecords: fetchRecords,
      filter: keyFilter('name'),
      toElement: toElement,
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    const String expand = 'userId';
    return pb.collection('problems').getFullList(
          expand: expand,
          filter: filter,
          sort: '-created',
        );
  }

  Widget toElement(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) {
    final userName = record.expand['userId']!.first.getStringValue('name');

    return ListTile(
      title: Text(record.getStringValue('title')),
      subtitle: RichText(
        text: TextSpan(
          children: [
            if (userName.isNotEmpty)
              TextSpan(
                  text: '$userName  ',
                  style: TextStyle(color: Theme.of(context).primaryColor)),
            TextSpan(
              text: getDateTime(record.created),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      trailing: _recordState(record),
      onTap: () {
        navPush(
          context,
          PropertyProblem(communityId: communityId, recordId: record.id),
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
    return const Text(
      '未知状态',
      style: TextStyle(
        color: Colors.grey,
        fontSize: fontSize,
      ),
    );
  }
}
