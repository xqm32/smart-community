import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class PropertyProblem extends StatefulWidget {
  const PropertyProblem({
    required this.communityId,
    super.key,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<PropertyProblem> createState() => _PropertyProblemState();
}

class _PropertyProblemState extends State<PropertyProblem> {
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _userFields = ['name'];
  Map<String, TextEditingController> _userControllers = {};
  final List<String> _fields = ['type', 'title', 'content'];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['问题上报', '事件处理', '处理完毕'];
  final Map<String, int> _stateIndex = {
    'pending': 1,
    'processing': 1,
    'finished': 2,
  };
  int _index = 1;

  final RecordService _service = pb.collection('problems');
  static const String _expand = 'userId';

  RecordModel? _record;

  @override
  void initState() {
    _formKeys =
        List.generate(_steps.length, (int index) => GlobalKey<FormState>());
    _userControllers = {
      for (final String i in _userFields) i: TextEditingController(),
    };
    _controllers = {
      for (final String i in _fields) i: TextEditingController(),
    };

    if (widget.recordId != null) {
      _service.getOne(widget.recordId!, expand: _expand).then(_setRecord);
    }
    super.initState();
  }

  @override
  void dispose() {
    for (TextEditingController i in _userControllers.values) {
      i.dispose();
    }
    for (TextEditingController i in _controllers.values) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('事件处置'),
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

  void _setRecord(RecordModel record) {
    for (final MapEntry<String, TextEditingController> i
        in _controllers.entries) {
      i.value.text = record.getStringValue(i.key);
    }
    for (final MapEntry<String, TextEditingController> i
        in _userControllers.entries) {
      i.value.text = record.expand['userId']!.first.getStringValue(i.key);
    }

    final String state = record.getStringValue('state');
    setState(() {
      _record = record;
      _index = _stateIndex[state] ?? 0;
    });
  }

  void Function() _onPressed(String state) {
    return () {
      if (!_formKeys[_index].currentState!.validate()) {
        return;
      }

      final Map<String, dynamic> body = {
        'state': state,
      };
      _service
          .update(_record!.id, body: body, expand: _expand)
          .then(_setRecord)
          .catchError((error) => showException(context, error));
    };
  }

  Widget _form({required int index}) {
    return Form(
      key: _formKeys[index],
      child: Column(
        children: [
          TextFormField(
            readOnly: true,
            controller: _userControllers['name'],
            decoration: const InputDecoration(
              labelText: '姓名',
            ),
          ),
          TextFormField(
            readOnly: true,
            controller: _controllers['type'],
            decoration: const InputDecoration(
              labelText: '类型',
            ),
          ),
          TextFormField(
            readOnly: true,
            controller: _controllers['title'],
            decoration: const InputDecoration(
              labelText: '标题',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            controller: _controllers['content'],
            decoration: const InputDecoration(
              labelText: '内容',
              disabledBorder: OutlineInputBorder(),
            ),
            maxLines: null,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: _record != null
                ? null
                : BoxDecoration(border: Border.all(color: Colors.grey)),
            height: 160,
            child: _record != null
                ? Image.network(
                    pb
                        .getFileUrl(_record!, _record!.getStringValue('photo'))
                        .toString(),
                  )
                : const Text('用户未上传图片'),
          ),
          const Text('问题照片'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onPressed('finished'),
            child: const Text('处理完毕'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _onPressed('processing'),
            child: const Text('交于下级', style: TextStyle(color: Colors.orange)),
          ),
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
          builder: (BuildContext context) {
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
                    _service.delete(_record!.id).then((value) {
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
