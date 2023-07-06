import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class ResidentProblem extends StatefulWidget {
  const ResidentProblem({
    required this.communityId,
    super.key,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<ResidentProblem> createState() => _ResidentProblemState();
}

class _ResidentProblemState extends State<ResidentProblem> {
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _fields = ['type', 'title', 'content'];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['填写信息', '事件处理', '处理完毕'];
  final Map<String, int> _stateIndex = {'pending': 1, 'finished': 2};
  int _index = 0;

  final List<String> _fileFields = ['photo'];
  Map<String, Uint8List?> _files = {};
  Map<String, String?> _filenames = {};

  final RecordService service = pb.collection('problems');

  RecordModel? _record;

  @override
  void initState() {
    _formKeys = List.generate(
      _steps.length,
      (final int index) => GlobalKey<FormState>(),
    );
    _controllers = {
      for (final String i in _fields) i: TextEditingController(),
    };
    _files = {
      for (final String i in _fileFields) i: null,
    };
    _filenames = {
      for (final String i in _fileFields) i: null,
    };
    if (widget.recordId != null) {
      service.getOne(widget.recordId!).then(_setRecord);
    }
    super.initState();
  }

  @override
  void dispose() {
    for (final TextEditingController i in _controllers.values) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('问题上报'),
          actions: _actionsBuilder(context),
        ),
        body: Stepper(
          type: StepperType.horizontal,
          currentStep: _index,
          controlsBuilder:
              (final BuildContext context, final ControlsDetails details) =>
                  Container(),
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

  void _setRecord(final RecordModel record) async {
    final String state = record.getStringValue('state');
    for (final MapEntry<String, TextEditingController> i
        in _controllers.entries) {
      i.value.text = record.getStringValue(i.key);
    }
    final Map images = {};
    for (final String i in _fileFields) {
      final String filename = record.getStringValue(i);
      if (filename.isNotEmpty) {
        final Response resp =
            await get(pb.getFileUrl(record, record.getStringValue(i)));
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
      for (final MapEntry<String, TextEditingController> i
          in _controllers.entries)
        i.key: i.value.text
    };
    body.addAll({
      'userId': pb.authStore.model!.id,
      'communityId': widget.communityId,
      'state': 'pending',
    });

    return body;
  }

  void _onSubmitPressed() {
    if (!_formKeys[_index].currentState!.validate()) {
      return;
    }

    final List<MultipartFile> files = [
      for (final MapEntry<String, Uint8List?> i in _files.entries)
        if (i.value != null && _filenames[i.key] != null)
          MultipartFile.fromBytes(i.key, i.value!, filename: _filenames[i.key])
    ];

    if (_index == 0) {
      service
          .create(body: _getBody(), files: files)
          .then(_setRecord)
          .catchError((final error) => showException(context, error));
      showSuccess(context, '提交成功');
    } else {
      service
          .update(_record!.id, body: _getBody(), files: files)
          .then(_setRecord)
          .catchError((final error) => showException(context, error));
      showSuccess(context, '修改成功');
    }
  }

  Widget _imageForm(
    final String field,
    final String labelText,
    final String hintText,
    final void Function(String filename, Uint8List bytes) update,
  ) =>
      Column(
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

  Widget _form({required final int index}) => Form(
        key: _formKeys[index],
        child: Column(
          children: [
            TextFormField(
              controller: _controllers['type'],
              decoration: const InputDecoration(
                labelText: '类型',
                hintText: '请填写问题类型',
              ),
              validator: FormBuilderValidators.required(errorText: '类型不能为空'),
            ),
            TextFormField(
              controller: _controllers['title'],
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '请填写问题标题',
              ),
              validator: FormBuilderValidators.required(errorText: '标题不能为空'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers['content'],
              decoration: const InputDecoration(
                labelText: '内容',
                hintText: '请填写问题内容',
                border: OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              validator: FormBuilderValidators.required(errorText: '内容不能为空'),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            _imageForm('photo', '请上传问题照片', '选择问题照片',
                (final String filename, final Uint8List bytes) {
              setState(() {
                _files['photo'] = bytes;
                _filenames['photo'] = filename;
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

  List<Widget>? _actionsBuilder(final context) {
    if (_record == null) {
      return null;
    }

    return [
      IconButton(
        onPressed: () => showDialog(
          context: context,
          builder: (final BuildContext context) => AlertDialog(
            surfaceTintColor: Theme.of(context).colorScheme.background,
            title: const Text('删除问题'),
            content: const Text('确定要删除该问题吗？'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  navPop(context, 'Cancel');
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  service.delete(_record!.id).then((final value) {
                    navPop(context, 'OK');
                    navPop(context);
                  });
                },
                child: const Text('确认'),
              ),
            ],
          ),
        ),
        icon: const Icon(
          Icons.delete_outline,
          color: Colors.red,
        ),
      )
    ];
  }
}
