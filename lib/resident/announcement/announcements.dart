import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/announcements.dart';
import 'package:smart_community/components/manage.dart';
import 'package:smart_community/resident/announcement/announcement.dart';
import 'package:smart_community/utils.dart';

class ResidentAnnouncements extends StatelessWidget {
  const ResidentAnnouncements({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  Widget build(final BuildContext context) => Manage(
        title: const Text('通知公告'),
        fetchRecords: fetchRecords,
        filter: keyFilter('title'),
        toElement: toElement,
      );

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    return pb
        .collection('announcements')
        .getFullList(filter: filter, sort: '-created');
  }

  Widget toElement(
    final BuildContext context,
    final void Function() refreshRecords,
    final RecordModel record,
  ) =>
      Announcement(
        record: record,
        onTap: () {
          navPush(
            context,
            ResidentAnnouncement(recordId: record.id),
          ).then((final value) => refreshRecords());
        },
      );
}
