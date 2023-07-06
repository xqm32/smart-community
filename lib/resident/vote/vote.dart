import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
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
    _formKeys = List.generate(
      _steps.length,
      (final int index) => GlobalKey<FormState>(),
    );
    _controllers = {
      for (final String i in _fields) i: TextEditingController(),
    };
    service.getOne(widget.recordId).then(_setRecord);
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
          title: const Text('支出投票管理'),
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
    final Map<String, dynamic> body = {};
    body.addAll({
      'userId': pb.authStore.model!.id,
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
            (final RecordModel value) =>
                service.getOne(widget.recordId).then(_setRecord),
          )
          .catchError((final error) => showException(context, error));
      showSuccess(context, '投票成功');
    } else {
      pb
          .collection('results')
          .update(_result!.id, body: _getBody())
          .then(
            (final RecordModel value) =>
                service.getOne(widget.recordId).then(_setRecord),
          )
          .catchError((final error) => showException(context, error));
      showSuccess(context, '修改成功');
    }
  }

  Widget _form({required final int index}) => Form(
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
                          const Text(
                            ' 至 ',
                            style: TextStyle(color: Colors.grey),
                          ),
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
            const SizedBox(height: 16),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: '选项'),
              value: _option,
              items: _record
                  ?.getStringValue('options')
                  .split('\n')
                  .map(
                    (final String e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: (final String? value) {
                setState(() {
                  _option = value;
                });
              },
              validator: FormBuilderValidators.required(errorText: '选项不能为空'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onSubmitPressed,
              child: Text(['提交', '修改信息'].elementAt(_index)),
            )
          ],
        ),
      );

  List<Widget>? _actionsBuilder(final context) {
    if (_result == null) {
      return null;
    }

    return [
      IconButton(
        onPressed: () => showDialog(
          context: context,
          builder: (final BuildContext context) => AlertDialog(
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
                  pb
                      .collection('results')
                      .delete(_result!.id)
                      .then((final value) {
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
