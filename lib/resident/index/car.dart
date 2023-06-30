import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

// 居民端/首页/车辆管理
class ResidentCar extends StatefulWidget {
  const ResidentCar({
    super.key,
    required this.communityId,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<ResidentCar> createState() => _ResidentCarState();
}

class _ResidentCarState extends State<ResidentCar> {
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(3, (index) => GlobalKey<FormState>());

  final List<String> _fields = ['name', 'plate'];
  Map<String, TextEditingController> _controllers = {};

  int _index = 0;
  RecordModel? _record;

  @override
  void initState() {
    _controllers = {
      for (final i in _fields) i: TextEditingController(),
    };
    if (widget.recordId != null) {
      pb.collection('cars').getOne(widget.recordId!).then(_setRecord);
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
        title: const Text('车辆管理'),
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
            content: _carForm(index: 0),
          ),
          Step(
            isActive: _index >= 1,
            title: const Text('物业审核'),
            content: _carForm(index: 1),
          ),
          Step(
            isActive: _index >= 2,
            title: const Text('审核通过'),
            content: _carForm(index: 2),
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
      'state': 'reviewing',
    });

    pb
        .collection('cars')
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
      'state': 'reviewing',
    });

    pb
        .collection('cars')
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
      'state': 'reviewing',
    });

    pb
        .collection('cars')
        .update(_record!.id, body: body)
        .then(_setRecord)
        .catchError((error) => showException(context, error));
  }

  // 居民端/首页/车辆管理/删除车辆
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
              title: const Text('删除车辆'),
              content: const Text('确定要删除该车辆吗？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    pb.collection('cars').delete(_record!.id).then((value) {
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

  // 居民端/首页/车辆管理/填写信息
  Widget _carForm({required int index}) {
    return Form(
      key: _formKeys[index],
      child: Column(
        children: [
          TextFormField(
            controller: _controllers['name'],
            decoration: const InputDecoration(
              labelText: '名称',
              hintText: '请填写车辆名称',
            ),
            validator: notNullValidator('名称不能为空'),
          ),
          TextFormField(
            controller: _controllers['plate'],
            decoration: const InputDecoration(
              labelText: '车牌号',
              hintText: '请填写车牌号',
            ),
            validator: notNullValidator('车牌号不能为空'),
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
