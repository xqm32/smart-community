import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class PropertyFamily extends StatefulWidget {
  const PropertyFamily({
    required this.communityId,
    super.key,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<PropertyFamily> createState() => _PropertyFamilyState();
}

class _PropertyFamilyState extends State<PropertyFamily> {
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _userFields = ['name'];
  Map<String, TextEditingController> _userControllers = {};
  final List<String> _fields = ['name', 'phone', 'relation'];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['填写信息', '物业审核', '审核通过'];
  final Map<String, int> _stateIndex = {
    'reviewing': 1,
    'rejected': 1,
    'verified': 2
  };
  int _index = 1;

  final RecordService _service = pb.collection('families');
  static const String _expand = 'userId';

  RecordModel? _record;

  @override
  void initState() {
    _formKeys = List.generate(
      _steps.length,
      (final int index) => GlobalKey<FormState>(),
    );
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
    for (final TextEditingController i in _userControllers.values) {
      i.dispose();
    }
    for (final TextEditingController i in _controllers.values) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('家人审核'),
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

  void _setRecord(final RecordModel record) {
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

  void Function() _onPressed(final String state) => () {
        if (!_formKeys[_index].currentState!.validate()) {
          return;
        }

        final Map<String, dynamic> body = {
          'state': state,
        };
        _service
            .update(_record!.id, body: body, expand: _expand)
            .then(_setRecord)
            .catchError((final error) => showException(context, error));
        if (state == 'verified') {
          showSuccess(context, '已通过');
        } else if (state == 'rejected') {
          showInfo(context, '已驳回', Colors.red);
        }
      };

  Widget _form({required final int index}) => Form(
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
              controller: _controllers['name'],
              decoration: const InputDecoration(
                labelText: '家人姓名',
              ),
            ),
            TextFormField(
              readOnly: true,
              controller: _controllers['phone'],
              decoration: const InputDecoration(
                labelText: '手机号',
              ),
            ),
            TextFormField(
              readOnly: true,
              controller: _controllers['relation'],
              decoration: const InputDecoration(
                labelText: '关系',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onPressed('verified'),
              child: const Text('通过'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _onPressed('rejected'),
              child: const Text('驳回', style: TextStyle(color: Colors.red)),
            ),
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
            title: const Text('删除家人'),
            content: const Text('确定要删除该家人吗？'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  navPop(context, 'Cancel');
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  _service.delete(_record!.id).then((final value) {
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
