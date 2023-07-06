import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class ResidentVerify extends StatefulWidget {
  const ResidentVerify({
    super.key,
    required this.communityId,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<ResidentVerify> createState() => _ResidentVerifyState();
}

class _ResidentVerifyState extends State<ResidentVerify> {
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _fields = [];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['填写信息', '物业审核', '审核通过'];
  final Map<String, int> _stateIndex = {
    'reviewing': 1,
    'rejected': 1,
    'verified': 2,
  };
  int _index = 0;

  final List<String> _fileFields = ['idCard'];
  Map<String, Uint8List?> _files = {};
  Map<String, String?> _filenames = {};

  final service = pb.collection('residents');

  RecordModel? _record;

  @override
  void initState() {
    _formKeys = List.generate(_steps.length, (index) => GlobalKey<FormState>());
    _controllers = {
      for (final i in _fields) i: TextEditingController(),
    };
    _files = {
      for (final i in _fileFields) i: null,
    };
    _filenames = {
      for (final i in _fileFields) i: null,
    };
    final residentsFilter =
        'communityId = "${widget.communityId}" && userId = "${pb.authStore.model!.id}"';
    pb.collection('residents').getFullList(filter: residentsFilter).then(
      (value) {
        if (value.isNotEmpty) {
          _setRecord(value.first);
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    for (var i in _controllers.values) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实名认证'),
        actions: _actionsBuilder(context),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _index,
        controlsBuilder: (context, details) => Container(),
        steps: [
          for (int i = 0; i < _steps.length; ++i)
            Step(
              isActive: _index >= i,
              title: Text(_steps.elementAt(i)),
              content: _form(index: i),
            ),
        ],
      ),
    );
  }

  void _setRecord(RecordModel record) async {
    final state = record.getStringValue('state');
    for (final i in _controllers.entries) {
      i.value.text = record.getStringValue(i.key);
    }
    final images = {};
    for (final i in _fileFields) {
      final filename = record.getStringValue(i);
      if (filename.isNotEmpty) {
        final resp = await get(pb.getFileUrl(record, record.getStringValue(i)));
        images[i] = resp.bodyBytes;
      }
    }
    setState(() {
      _record = record;
      for (final i in images.keys) {
        _files[i] = images[i];
      }
      _index = _stateIndex[state] ?? 0;
    });
  }

  Map<String, dynamic> _getBody() {
    final Map<String, dynamic> body = {
      for (final i in _controllers.entries) i.key: i.value.text
    };
    body.addAll({
      'userId': pb.authStore.model!.id,
      'communityId': widget.communityId,
      'state': 'reviewing',
    });

    return body;
  }

  void _onSubmitPressed() {
    if (!_formKeys[_index].currentState!.validate()) {
      return;
    }

    final files = [
      for (final i in _files.entries)
        if (i.value != null && _filenames[i.key] != null)
          MultipartFile.fromBytes(i.key, i.value!, filename: _filenames[i.key])
    ];

    if (_index == 0) {
      service
          .create(body: _getBody(), files: files)
          .then(_setRecord)
          .catchError((error) => showException(context, error));
    } else {
      service
          .update(_record!.id, body: _getBody(), files: files)
          .then(_setRecord)
          .catchError((error) => showException(context, error));
    }
  }

  List<Widget>? _actionsBuilder(context) {
    if (_record == null) {
      return null;
    }

    return [
      IconButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              surfaceTintColor: Theme.of(context).colorScheme.background,
              title: const Text('删除认证'),
              content: const Text('确定要删除该认证吗？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    navPop(context, 'Cancel');
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    service.delete(_record!.id).then((value) {
                      navPop(context, 'OK');
                      navPop(context);
                    });
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        ),
        icon: const Icon(
          Icons.delete_outline,
          color: Colors.red,
        ),
      )
    ];
  }

  Widget _imageForm(
    String field,
    String labelText,
    String hintText,
    void Function(String filename, Uint8List bytes) update,
  ) {
    return Column(
      children: [
        Container(
          decoration: _files[field] != null
              ? null
              : BoxDecoration(border: Border.all(color: Colors.grey)),
          height: 160,
          child: _files[field] != null
              ? Image.memory(
                  _files[field]!,
                )
              : Center(child: Text(labelText)),
        ),
        TextButton(
          onPressed: () {
            pickImage(update: update);
          },
          child: Text(hintText),
        ),
      ],
    );
  }

  Widget _form({required int index}) {
    return Form(
      key: _formKeys[index],
      child: Column(
        children: [
          _imageForm('idCard', '请上传身份证照片', '选择身份证照片', (filename, bytes) {
            setState(() {
              _files['idCard'] = bytes;
              _filenames['idCard'] = filename;
            });
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onSubmitPressed,
            child: Text(['提交', '修改信息', '修改信息'].elementAt(_index)),
          )
        ],
      ),
    );
  }
}
