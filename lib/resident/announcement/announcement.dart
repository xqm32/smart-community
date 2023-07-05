import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';


class ResidentAnnouncement extends StatefulWidget {
  const ResidentAnnouncement({
    super.key,
    this.recordId,
  });

  final String? recordId;

  @override
  State<ResidentAnnouncement> createState() => _ResidentAnnouncementState();
}

class _ResidentAnnouncementState extends State<ResidentAnnouncement> {
  final service = pb.collection('announcements');

  RecordModel? _record;

  @override
  void initState() {
    if (widget.recordId != null) {
      service.getOne(widget.recordId!).then(_setRecord);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知公告'),
      ),
      body: _record != null
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _record!.getStringValue('title'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          _record!.getStringValue('author'),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          getDateTime(_record!.created),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MarkdownBody(
                        data: _record!.getStringValue('content'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const LinearProgressIndicator(),
    );
  }

  void _setRecord(RecordModel record) {
    setState(() {
      _record = record;
    });
  }
}
