import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class Announcement extends StatelessWidget {
  const Announcement({
    super.key,
    required this.record,
    required this.onTap,
  });

  final RecordModel record;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final author = record.getStringValue('author');

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
