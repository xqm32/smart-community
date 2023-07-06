import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class ResidentVote extends StatefulWidget {
  const ResidentVote({
    required this.communityId,
    required this.recordId,
    super.key,
  });

  final String communityId;
  final String recordId;

  @override
  State<ResidentVote> createState() => _ResidentVoteState();
}

class _ResidentVoteState extends State<ResidentVote> {
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _fields = ['title', 'content', 'options', 'start', 'end'];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['投票', '查看投票'];
  int _index = 0;

  final RecordService service = pb.collection('votes');

  RecordModel? _record;
  RecordModel? _result;
  String? _option;

  @override
  void initState() {
    _formKeys =
        List.generate(_steps.length, (int index) => GlobalKey<FormState>());
    _controllers = {
      for (final String i in _fields) i: TextEditingController(),
    };
    service.getOne(widget.recordId).then(_setRecord);
    super.initState();
  }

  @override
  void dispose() {
    for (TextEditingController i in _controllers.values) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支出投票管理'),
        actions: _actionsBuilder(context),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _index,
        controlsBuilder: (BuildContext context, ControlsDetails details) =>
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
  }

  void _setRecord(RecordModel record) async {
    int index = 0;
    RecordModel? result;

    final String resultsFilter =
        'voteId = "${widget.recordId}" && userId = "${pb.authStore.model!.id}"';
    final List<RecordModel> results =
        await pb.collection('results').getFullList(filter: resultsFilter);
    if (results.isNotEmpty) {
      result = results.first;
      index = 1;
    }

    for (final MapEntry<String, TextEditingController> i
        in _controllers.entries) {
      i.value.text = record.getStringValue(i.key);
    }
    setState(() {
      _record = record;
      _index = index;
      _result = result;
      _option = result?.getStringValue('option');
    });
  }

  Map<String, dynamic> _getBody() {
    // final Map<String, dynamic> body = {
    //   for (final i in _controllers.entries) i.key: i.value.text
    // };
    final Map<String, dynamic> body = {};
    body.addAll({
      'userId': pb.authStore.model!.id,
      // 'communityId': widget.communityId,
      'voteId': widget.recordId,
      'option': _option,
    });

    return body;
  }

  void _onSubmitPressed() {
    if (!_formKeys[_index].currentState!.validate()) {
      return;
    }

    if (_index == 0) {
      pb
          .collection('results')
          .create(body: _getBody())
          .then(
            (RecordModel value) =>
                service.getOne(widget.recordId).then(_setRecord),
          )
          .catchError((error) => showException(context, error));
    } else {
      pb
          .collection('results')
          .update(_result!.id, body: _getBody())
          .then(
            (RecordModel value) =>
                service.getOne(widget.recordId).then(_setRecord),
          )
          .catchError((error) => showException(context, error));
    }
  }

  Widget _form({required int index}) {
    return Form(
      key: _formKeys[index],
      child: Column(
        children: [
          if (_record != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                          _record!.getStringValue('start'),
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const Text(' 至 ', style: TextStyle(color: Colors.grey)),
                        Text(
                          _record!.getStringValue('end'),
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
            ),
          // TextFormField(
          //   controller: _controllers['title'],
          //   decoration: const InputDecoration(
          //     labelText: '标题',
          //     hintText: '请填写投票标题',
          //   ),
          //   validator: notNullValidator('标题不能为空'),
          // ),
          // const SizedBox(height: 16),
          // TextFormField(
          //   controller: _controllers['content'],
          //   decoration: const InputDecoration(
          //     labelText: '内容',
          //     hintText: '请填写投票内容',
          //     border: OutlineInputBorder(),
          //     floatingLabelBehavior: FloatingLabelBehavior.always,
          //   ),
          //   validator: notNullValidator('内容不能为空'),
          //   maxLines: null,
          // ),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            decoration: const InputDecoration(labelText: '选项'),
            value: _option,
            items: _record
                ?.getStringValue('options')
                .split('\n')
                .map(
                  (String e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _option = value;
              });
            },
            validator: notNullValidator('选项不能为空'),
          ),
          // const SizedBox(height: 16),
          // TextFormField(
          //   controller: _controllers['start'],
          //   decoration: const InputDecoration(
          //     labelText: '起始时间',
          //     hintText: '请填写起始时间',
          //   ),
          // ),
          // const SizedBox(height: 16),
          // TextFormField(
          //   controller: _controllers['end'],
          //   decoration: const InputDecoration(
          //     labelText: '结束时间',
          //     hintText: '请填写结束时间',
          //   ),
          // ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onSubmitPressed,
            child: Text(['提交', '修改信息'].elementAt(_index)),
          )
        ],
      ),
    );
  }

  List<Widget>? _actionsBuilder(context) {
    if (_result == null) {
      return null;
    }

    return [
      IconButton(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              surfaceTintColor: Theme.of(context).colorScheme.background,
              title: const Text('删除投票'),
              content: const Text('确定要删除该投票吗？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    navPop(context, 'Cancel');
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    pb.collection('results').delete(_result!.id).then((value) {
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
