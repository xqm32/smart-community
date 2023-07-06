import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/property/vote/Vote.dart';
import 'package:smart_community/utils.dart';

class PropertyVotes extends StatelessWidget {
  const PropertyVotes({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  Widget build(final BuildContext context) => Manage(
        title: const Text('支出投票管理'),
        fetchRecords: fetchRecords,
        filter: keyFilter('title'),
        toElement: toElement,
        onAddPressed: onAddPressed,
      );

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    return pb.collection('votes').getFullList(filter: filter, sort: '-created');
  }

  void onAddPressed(
    final BuildContext context,
    final void Function() refreshRecords,
  ) {
    navPush(
      context,
      PropertyVote(communityId: communityId),
    ).then((final value) => refreshRecords());
  }

  Widget toElement(
    final BuildContext context,
    final void Function() refreshRecords,
    final RecordModel record,
  ) =>
      ListTile(
        title: Text(record.getStringValue('title')),
        subtitle: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: getDate(record.getStringValue('start')),
                style: const TextStyle(color: Colors.grey),
              ),
              const TextSpan(
                text: ' 至 ',
                style: TextStyle(color: Colors.grey),
              ),
              TextSpan(
                text: getDate(record.getStringValue('end')),
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
          ).then((final value) => refreshRecords());
        },
      );

  Widget _recordState(final RecordModel record) {
    final String start = record.getStringValue('start');
    final String end = record.getStringValue('end');
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
