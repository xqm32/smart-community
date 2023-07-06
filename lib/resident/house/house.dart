import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class ResidentHouse extends StatefulWidget {
  const ResidentHouse({
    required this.communityId,
    super.key,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<ResidentHouse> createState() => _ResidentHouseState();
}

class _ResidentHouseState extends State<ResidentHouse> {
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _fields = ['location'];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['填写信息', '物业审核', '审核通过'];
  final Map<String, int> _stateIndex = {'reviewing': 1, 'verified': 2};
  int _index = 0;

  final RecordService service = pb.collection('houses');

  RecordModel? _record;
  Map<String, dynamic>? _struct;
  String? _building;
  String? _floor;
  String? _room;

  @override
  void initState() {
    _formKeys = List.generate(
      _steps.length,
      (final int index) => GlobalKey<FormState>(),
    );
    _controllers = {
      for (final String i in _fields) i: TextEditingController(),
    };

    pb
        .collection('communities')
        .getOne(widget.communityId)
        .then((final RecordModel value) {
      final String struct = value.getStringValue('struct');

      setState(() {
        _struct = struct.isNotEmpty
            ? jsonDecode(struct) as Map<String, dynamic>
            : null;
      });

      if (widget.recordId != null) {
        service.getOne(widget.recordId!).then(_setRecord);
      }
    });

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
          title: const Text('房屋管理'),
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
    final String state = record.getStringValue('state');
    for (final MapEntry<String, TextEditingController> i
        in _controllers.entries) {
      i.value.text = record.getStringValue(i.key);
    }

    String? building = record.getStringValue('building');
    String? floor = record.getStringValue('floor');
    String? room = record.getStringValue('room');
    if (_struct == null || !_struct!.containsKey(building)) {
      building = null;
      floor = null;
      room = null;
    } else if (!_struct![building]!.containsKey(floor)) {
      floor = null;
      room = null;
    } else if (!_struct![building]![floor]!.contains(room)) {
      room = null;
    }

    setState(() {
      _record = record;
      _index = _stateIndex[state] ?? 0;
      _building = building;
      _floor = floor;
      _room = room;
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
      'state': 'reviewing',
      'building': _building,
      'floor': _floor,
      'room': _room,
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
          .catchError((final error) => showException(context, error));
      showSuccess(context, '提交成功');
    } else {
      service
          .update(_record!.id, body: _getBody())
          .then(_setRecord)
          .catchError((final error) => showException(context, error));
      showSuccess(context, '修改成功');
    }
  }

  Widget _form({required final int index}) => Form(
        key: _formKeys[index],
        child: Column(
          children: [
            TextFormField(
              controller: _controllers['location'],
              decoration: const InputDecoration(
                labelText: '地址',
                hintText: '请填写房屋地址',
              ),
              validator: FormBuilderValidators.required(errorText: '地址不能为空'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: '楼幢'),
                    value: _building,
                    items: _struct?.keys
                        .map(
                          (final String e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (final String? value) {
                      setState(() {
                        _building = value;
                        _floor = null;
                        _room = null;
                      });
                    },
                    validator:
                        FormBuilderValidators.required(errorText: '楼层不能为空'),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: '楼层'),
                    value: _floor,
                    items: (_struct?[_building] as Map<String, dynamic>?)
                        ?.keys
                        .map(
                          (final String e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (final String? value) {
                      setState(() {
                        _floor = value;
                        _room = null;
                      });
                    },
                    validator:
                        FormBuilderValidators.required(errorText: '楼层不能为空'),
                  ),
                ),
              ],
            ),
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: '房间号'),
              value: _room,
              items: (_struct?[_building]?[_floor] as List?)
                  ?.map(
                    (final e) => DropdownMenuItem(
                      value: e as String,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: (final String? value) {
                setState(() {
                  _room = value;
                });
              },
              validator: FormBuilderValidators.required(errorText: '房间不能为空'),
            ),
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
            title: const Text('删除房屋'),
            content: const Text('确定要删除该房屋吗？'),
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
