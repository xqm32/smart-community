import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/property/vote/Vote.dart';
import 'package:smart_community/utils.dart';

class PropertyVotes extends StatelessWidget {
  const PropertyVotes({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Manage(
      title: const Text('支出投票管理'),
      fetchRecords: fetchRecords,
      filter: keyFilter('title'),
      toElement: toElement,
      onAddPressed: onAddPressed,
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    return pb.collection('votes').getFullList(filter: filter, sort: '-created');
  }

  void onAddPressed(BuildContext context, void Function() refreshRecords) {
    navPush(
      context,
      PropertyVote(communityId: communityId),
    ).then((value) => refreshRecords());
  }

  Widget toElement(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) {
    return ListTile(
      title: Text(record.getStringValue('title')),
      subtitle: RichText(
        text: TextSpan(
          children: [
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
          PropertyVote(communityId: communityId, recordId: record.id),
        ).then((value) => refreshRecords());
      },
    );
  }

  Widget _recordState(RecordModel record) {
    final start = record.getStringValue('start');
    final end = record.getStringValue('end');
    const double fontSize = 16;

    if (start.isNotEmpty &&
        DateTime.now().toLocal().isBefore(DateTime.parse(start))) {
      return const Text(
        '未开始',
        style: TextStyle(
          color: Colors.purple,
          fontSize: fontSize,
        ),
      );
    } else if (end.isNotEmpty &&
        DateTime.now().toLocal().isAfter(DateTime.parse(end))) {
      return const Text(
        '已结束',
        style: TextStyle(
          color: Colors.red,
          fontSize: fontSize,
        ),
      );
    } else {
      return const Text(
        '进行中',
        style: TextStyle(
          color: Colors.green,
          fontSize: fontSize,
        ),
      );
    }
  }
}
