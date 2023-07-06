import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/property/house/house.dart';
import 'package:smart_community/utils.dart';

class PropertyHouses extends StatelessWidget {
  const PropertyHouses({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  Widget build(final BuildContext context) => Manage(
      title: const Text('房屋审核'),
      fetchRecords: fetchRecords,
      filter: keyFilter('location'),
      toElement: toElement,
    );

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    const String expand = 'userId';
    return pb.collection('houses').getFullList(
          expand: expand,
          filter: filter,
          sort: '-created',
        );
  }

  Widget toElement(
    final BuildContext context,
    final void Function() refreshRecords,
    final RecordModel record,
  ) {
    final String userName =
        record.expand['userId']!.first.getStringValue('name');

    return ListTile(
      title: Text(record.getStringValue('location')),
      subtitle: RichText(
        text: TextSpan(
          children: [
            if (userName.isNotEmpty)
              TextSpan(
                text: '$userName  ',
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
          PropertyHouse(communityId: communityId, recordId: record.id),
        ).then((final value) => refreshRecords());
      },
    );
  }

  Widget _recordState(final RecordModel record) {
    final String state = record.getStringValue('state');
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
