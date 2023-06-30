import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

// 居民端/首页/问题上报
class ResidentProblem extends StatefulWidget {
  const ResidentProblem({
    super.key,
    required this.communityId,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<ResidentProblem> createState() => _ResidentProblemState();
}

class _ResidentProblemState extends State<ResidentProblem> {
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(3, (index) => GlobalKey<FormState>());

  final List<String> _fields = ['type', 'title', 'content'];
  Map<String, TextEditingController> _controllers = {};

  int _index = 0;
  RecordModel? _record;

  @override
  void initState() {
    _controllers = {
      for (final i in _fields) i: TextEditingController(),
    };
    if (widget.recordId != null) {
      pb.collection('problems').getOne(widget.recordId!).then(_setRecord);
    }
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
        title: const Text('问题上报'),
        actions: _actionsBuilder(context),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _index,
        controlsBuilder: (context, details) => Container(),
        steps: [
          Step(
            isActive: _index >= 0,
            title: const Text('填写信息'),
            content: _problemForm(index: 0),
          ),
          Step(
            isActive: _index >= 1,
            title: const Text('事件处理'),
            content: _problemForm(index: 1),
          ),
          Step(
            isActive: _index >= 2,
            title: const Text('处理完毕'),
            content: _problemForm(index: 2),
          )
        ],
      ),
    );
  }

  void _setRecord(RecordModel value) {
    int next = 1;
    final state = value.getStringValue('state');
    // 'reviewing' 和 'rejected' 均跳转至「物业审核」
    if (state == 'verified') {
      next = 2;
    }

    for (final i in _controllers.entries) {
      i.value.text = value.getStringValue(i.key);
    }

    setState(() {
      _record = value;
      _index = next;
    });
  }

  void _onCreatePressed() {
    if (!_formKeys[0].currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> body = {
      for (final i in _controllers.entries) i.key: i.value.text
    };
    body.addAll({
      'userId': pb.authStore.model!.id,
      'communityId': widget.communityId,
      'state': 'pending',
    });

    pb
        .collection('problems')
        .create(body: body)
        .then(_setRecord)
        .catchError((error) => showException(context, error));
  }

  void _onUpdatePressed() {
    if (!_formKeys[1].currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> body = {
      for (final i in _controllers.entries) i.key: i.value.text
    };
    body.addAll({
      'userId': pb.authStore.model!.id,
      'communityId': widget.communityId,
      'state': 'pending',
    });

    pb
        .collection('problems')
        .update(_record!.id, body: body)
        .then(_setRecord)
        .catchError((error) => showException(context, error));
  }

  void _onResubmitPressed() {
    if (!_formKeys[2].currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> body = {
      for (final i in _controllers.entries) i.key: i.value.text
    };
    body.addAll({
      'userId': pb.authStore.model!.id,
      'communityId': widget.communityId,
      'state': 'pending',
    });

    pb
        .collection('problems')
        .update(_record!.id, body: body)
        .then(_setRecord)
        .catchError((error) => showException(context, error));
  }

  // 居民端/首页/问题上报/删除问题
  List<Widget>? _actionsBuilder(context) {
    if (_record == null || _index < 1) {
      return null;
    }

    return [
      IconButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              surfaceTintColor: Theme.of(context).colorScheme.background,
              title: const Text('删除问题'),
              content: const Text('确定要删除该问题吗？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    pb.collection('problems').delete(_record!.id).then((value) {
                      Navigator.pop(context, 'OK');
                      navPop(context);
                    });
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        ),
        icon: const Icon(Icons.delete_outline),
      )
    ];
  }

  // 居民端/首页/问题上报/填写信息
  Widget _problemForm({required int index}) {
    return Form(
      key: _formKeys[index],
      child: Column(
        children: [
          TextFormField(
            controller: _controllers['type'],
            decoration: const InputDecoration(
              labelText: '类型',
              hintText: '请填写问题类型',
            ),
            validator: notNullValidator('类型不能为空'),
          ),
          TextFormField(
            controller: _controllers['title'],
            decoration: const InputDecoration(
              labelText: '标题',
              hintText: '请填写问题标题',
            ),
            validator: notNullValidator('标题不能为空'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers['content'],
            decoration: const InputDecoration(
              labelText: '内容',
              hintText: '请填写问题内容',
              border: OutlineInputBorder(),
            ),
            validator: notNullValidator('内容不能为空'),
            maxLines: 16,
          ),
          const SizedBox(height: 16),
          [
            ElevatedButton(
              onPressed: _onCreatePressed,
              child: const Text('提交'),
            ),
            ElevatedButton(
              onPressed: _onUpdatePressed,
              child: const Text('修改信息'),
            ),
            ElevatedButton(
              onPressed: _onResubmitPressed,
              child: const Text('修改信息'),
            ),
          ].elementAt(index),
        ],
      ),
    );
  }
}
