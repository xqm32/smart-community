import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/resident/problem/problem.dart';
import 'package:smart_community/utils.dart';

class ResidentProblems extends StatelessWidget {
  const ResidentProblems({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  Widget build(final BuildContext context) => Manage(
        title: const Text('问题上报'),
        fetchRecords: fetchRecords,
        filter: keyFilter('title'),
        toElement: toElement,
        onAddPressed: onAddPressed,
      );

  Future<List<RecordModel>> fetchRecords() {
    final String filter =
        'communityId = "$communityId" && userId = "${pb.authStore.model!.id}"';
    return pb
        .collection('problems')
        .getFullList(filter: filter, sort: '-created');
  }

  void onAddPressed(
    final BuildContext context,
    final void Function() refreshRecords,
  ) {
    navPush(
      context,
      ResidentProblem(communityId: communityId),
    ).then((final value) => refreshRecords());
  }

  Widget toElement(
    final BuildContext context,
    final void Function() refreshRecords,
    final RecordModel record,
  ) {
    final String remark = record.getStringValue('remark');

    return ListTile(
      title: Text(record.getStringValue('title')),
      subtitle: RichText(
        text: TextSpan(
          children: [
            if (remark.isNotEmpty)
              TextSpan(
                text: '$remark  ',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
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
          ResidentProblem(communityId: communityId, recordId: record.id),
        ).then((final value) => refreshRecords());
      },
    );
  }

  Widget _recordState(final RecordModel record) {
    final String state = record.getStringValue('state');
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
