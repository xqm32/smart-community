import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/property/resident/resident.dart';
import 'package:smart_community/utils.dart';

class PropertyResidents extends StatelessWidget {
  const PropertyResidents({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Manage(
      title: const Text('居民管理'),
      fetchRecords: fetchRecords,
      filter: keyFilter('name'),
      toElement: toElement,
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    const String expand = 'userId';
    return pb.collection('residents').getFullList(
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
    final userPhone = record.expand['userId']!.first.getStringValue('phone');

    return ListTile(
      title: Text(userName),
      subtitle: RichText(
        text: TextSpan(
          children: [
            if (userPhone.isNotEmpty)
              TextSpan(
                  text: '$userPhone  ',
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
          PropertyResident(communityId: communityId, recordId: record.id),
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
          color: Colors.purple,
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
    return const Text(
      '未知状态',
      style: TextStyle(
        color: Colors.grey,
        fontSize: fontSize,
      ),
    );
  }
}
