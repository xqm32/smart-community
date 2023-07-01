import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/resident/announcement/Announcement.dart';
import 'package:smart_community/utils.dart';

// 居民端/首页/通知公告
class ResidentAnnouncements extends StatelessWidget {
  const ResidentAnnouncements({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Manage(
      title: const Text('通知公告'),
      fetchRecords: fetchRecords,
      toElement: toElement,
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    return pb
        .collection('announcements')
        .getFullList(filter: filter, sort: '-created');
  }
  Widget toElement(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) {
    return ListTile(
      title: Text(record.getStringValue('title')),
      subtitle: Text(record.created.split('.')[0]),
      onTap: () {
        navPush(
          context,
          ResidentAnnouncement(recordId: record.id),
        ).then((value) => refreshRecords());
      },
    );
  }
}
