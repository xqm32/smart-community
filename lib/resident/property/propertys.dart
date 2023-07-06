import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/utils.dart';

class ResidentPropertys extends StatelessWidget {
  const ResidentPropertys({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  Widget build(final BuildContext context) => Manage(
        title: const Text('联系物业'),
        fetchRecords: fetchRecords,
        filter: keyFilter('name'),
        toElement: toElement,
      );

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    return pb.collection('propertys').getFullList(
          filter: filter,
          expand: 'userId',
          sort: '-created',
        );
  }

  Widget toElement(
    final BuildContext context,
    final void Function() refreshRecords,
    final RecordModel record,
  ) =>
      ListTile(
        title: Text(record.expand['userId']!.first.getStringValue('name')),
        subtitle: Text(
          record.expand['userId']!.first.getStringValue('phone'),
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        onTap: () {
          Clipboard.setData(ClipboardData(
              text: record.expand['userId']!.first.getStringValue('phone'),),);
          showSuccess(context, '已复制手机号到剪贴板');
        },
      );
}
