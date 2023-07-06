import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class Announcement extends StatelessWidget {
  const Announcement({
    required this.record,
    required this.onTap,
    super.key,
  });

  final RecordModel record;
  final void Function() onTap;

  @override
  Widget build(final BuildContext context) {
    final String author = record.getStringValue('author');

    return ListTile(
      title: Text(record.getStringValue('title')),
      subtitle: RichText(
        text: TextSpan(
          children: [
            if (author.isNotEmpty)
              TextSpan(
                text: '$author  ',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            TextSpan(
              text: getDateTime(record.created),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}
