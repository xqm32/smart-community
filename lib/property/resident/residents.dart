import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/manage.dart';
import 'package:smart_community/property/resident/resident.dart';
import 'package:smart_community/utils.dart';

class PropertyResidents extends StatefulWidget {
  const PropertyResidents({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  State<PropertyResidents> createState() => _PropertyResidentsState();
}

class _PropertyResidentsState extends State<PropertyResidents> {
  @override
  Widget build(final BuildContext context) => Manage(
        title: const Text('居民管理'),
        fetchRecords: fetchRecords,
        filter: keyFilter('name'),
        toElement: toElement,
        actions: [
          IconButton(
            onPressed: () => {
              upload()
                  .then((final value) => showSuccess(context, '导入成功，请点击刷新按钮'))
            },
            icon: const Icon(Icons.upload),
          ),
          IconButton(
            onPressed: () => {
              download().then((final value) => showSuccess(context, '导出成功'))
            },
            icon: const Icon(Icons.download),
          ),
        ],
      );

  Future<void> download() async {
    final List<RecordModel> records = await fetchRecords();

    final String fileName = '${widget.communityId}.json';
    final FileSaveLocation? result =
        await getSaveLocation(suggestedName: fileName);
    if (result == null) {
      return;
    }

    final List<Map<String, dynamic>> data = [];
    for (final i in records) {
      final u = i.expand['userId']!.first;
      data.add({
        'name': u.getStringValue('name'),
        'phone': u.getStringValue('phone'),
        'identity': u.getStringValue('identity'),
      });
    }

    final Uint8List fileData =
        Uint8List.fromList(JsonUtf8Encoder().convert(data));
    final XFile textFile = XFile.fromData(fileData, name: fileName);
    return textFile.saveTo(result.path);
  }

  Future<void> upload() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'json',
      extensions: <String>['json'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) {
      return;
    }

    final String content = await file.readAsString();
    final List<dynamic> data = jsonDecode(content);
    for (final i in data) {
      final test = await pb
          .collection('users')
          .getFullList(filter: 'identity = "${i['identity']}"');
      RecordModel record;
      if (test.isEmpty) {
        record = await pb.collection('users').create(
          body: {
            'username': i['identity'],
            'password': i['identity'].substring(10),
            'passwordConfirm': i['identity'].substring(10),
            'name': i['name'],
            'phone': i['phone'],
            'identity': i['identity'],
            'role': 'resident',
          },
        );
      } else {
        record = test.first;
      }
      pb.collection('residents').create(
        body: {
          'communityId': widget.communityId,
          'userId': record.id,
          'state': 'verified',
        },
      ).then((final value) {
        showSuccess(context, '导入完成，请点击刷新按钮');
      }).catchError((final error) {});
    }
    return Future(() {});
  }

  Future<List<RecordModel>> fetchRecords() {
    final String filter = 'communityId = "${widget.communityId}"';
    const String expand = 'userId';
    return pb.collection('residents').getFullList(
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
    final String userPhone =
        record.expand['userId']!.first.getStringValue('phone');

    return ListTile(
      title: Text(userName),
      subtitle: RichText(
        text: TextSpan(
          children: [
            if (userPhone.isNotEmpty)
              TextSpan(
                text: '$userPhone  ',
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
          PropertyResident(
            communityId: widget.communityId,
            recordId: record.id,
          ),
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
