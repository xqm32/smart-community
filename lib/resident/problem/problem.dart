import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';


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
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _fields = ['type', 'title', 'content'];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['填写信息', '事件处理', '处理完毕'];
  final Map<String, int> _stateIndex = {'pending': 1, 'finished': 2};
  int _index = 0;

  final service = pb.collection('problems');

  RecordModel? _record;

  @override
  void initState() {
    _formKeys = List.generate(_steps.length, (index) => GlobalKey<FormState>());
    _controllers = {
      for (final i in _fields) i: TextEditingController(),
    };
    if (widget.recordId != null) {
      service.getOne(widget.recordId!).then(_setRecord);
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

  void _setRecord(RecordModel record) {
    final state = record.getStringValue('state');
    for (final i in _controllers.entries) {
      i.value.text = record.getStringValue(i.key);
    }
    setState(() {
      _record = record;
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
      'state': 'pending',
    });

    return body;
  }

  void _onSubmitPressed() {
    if (!_formKeys[_index].currentState!.validate()) {
      return;
    }

    if (_index == 0) {
      service
          .create(body: _getBody())
          .then(_setRecord)
          .catchError((error) => showException(context, error));
    } else {
      service
          .update(_record!.id, body: _getBody())
          .then(_setRecord)
          .catchError((error) => showException(context, error));
    }
  }

  
  Widget _form({required int index}) {
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
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            validator: notNullValidator('内容不能为空'),
            maxLines: null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onSubmitPressed,
            child: Text(['提交', '修改信息', '修改信息'].elementAt(_index)),
          )
        ],
      ),
    );
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
}
