import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/announcements.dart';
import 'package:smart_community/components/manage.dart';
import 'package:smart_community/property/announcement/Announcement.dart';
import 'package:smart_community/utils.dart';

// 物业端/首页/通知公告
class PropertyAnnouncements extends StatelessWidget {
  const PropertyAnnouncements({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Manage(
      title: const Text('通知公告'),
      fetchRecords: fetchRecords,
      filter: keyFilter('title'),
      toElement: toElement,
      onAddPressed: onAddPressed,
    );
  }

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    return pb
        .collection('announcements')
        .getFullList(filter: filter, sort: '-created');
  }

  void onAddPressed(BuildContext context, void Function() refreshRecords) {
    navPush(
      context,
      PropertyAnnouncement(communityId: communityId),
    ).then((value) => refreshRecords());
  }

  Widget toElement(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) {
    return Announcement(
      record: record,
      onTap: () {
        navPush(
          context,
          PropertyAnnouncement(communityId: communityId, recordId: record.id),
        ).then((value) => refreshRecords());
      },
    );
  }
}
