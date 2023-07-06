import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/announcements.dart';
import 'package:smart_community/components/manage.dart';
import 'package:smart_community/property/announcement/Announcement.dart';
import 'package:smart_community/utils.dart';

class PropertyAnnouncements extends StatelessWidget {
  const PropertyAnnouncements({
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
      onAddPressed: onAddPressed,
    );

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "$communityId"';
    return pb
        .collection('announcements')
        .getFullList(filter: filter, sort: '-created');
  }

  void onAddPressed(final BuildContext context, final void Function() refreshRecords) {
    navPush(
      context,
      PropertyAnnouncement(communityId: communityId),
    ).then((final value) => refreshRecords());
  }

  Widget toElement(
    final BuildContext context,
    final void Function() refreshRecords,
    final RecordModel record,
  ) => Announcement(
      record: record,
      onTap: () {
        navPush(
          context,
          PropertyAnnouncement(communityId: communityId, recordId: record.id),
        ).then((final value) => refreshRecords());
      },
    );
}
