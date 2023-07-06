import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/resident/vote/Vote.dart';
import 'package:smart_community/utils.dart';

class ResidentVotes extends StatelessWidget {
  const ResidentVotes({
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
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    return pb.collection('votes').getFullList(filter: filter, sort: '-created');
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
          ResidentVote(communityId: communityId, recordId: record.id),
        ).then((value) => refreshRecords());
      },
    );
  }

  Widget _recordState(RecordModel record) {
    late Future<List<RecordModel>> result =
        pb.collection('results').getFullList(
              filter:
                  'voteId = "${record.id}" && userId = "${pb.authStore.model!.id}"',
            );
    final start = record.getStringValue('start');
    final end = record.getStringValue('end');
    const double fontSize = 16;

    return FutureBuilder(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return _recordStateText(start, end, fontSize);
          } else {
            return const Text(
              '已投票',
              style: TextStyle(
                color: Colors.blue,
                fontSize: fontSize,
              ),
            );
          }
        } else {
          return const Text(
            '加载中',
            style: TextStyle(
              color: Colors.grey,
              fontSize: fontSize,
            ),
          );
        }
      },
    );
  }

  Widget _recordStateText(String start, String end, double fontSize) {
    if (start.isNotEmpty &&
        DateTime.now().toLocal().isBefore(DateTime.parse(start))) {
      return Text(
        '未开始',
        style: TextStyle(
          color: Colors.purple,
          fontSize: fontSize,
        ),
      );
    } else if (end.isNotEmpty &&
        DateTime.now().toLocal().isAfter(DateTime.parse(end))) {
      return Text(
        '已结束',
        style: TextStyle(
          color: Colors.red,
          fontSize: fontSize,
        ),
      );
    } else {
      return Text(
        '进行中',
        style: TextStyle(
          color: Colors.green,
          fontSize: fontSize,
        ),
      );
    }
  }
}
