import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:smart_community/utils.dart';

// 居民端/首页/房屋管理
class ResidentHouse extends StatefulWidget {
  const ResidentHouse({
    super.key,
    required this.communityId,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<ResidentHouse> createState() => _ResidentHouseState();
}

class _ResidentHouseState extends State<ResidentHouse> {
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(3, (index) => GlobalKey<FormState>());

  final List<String> _fields = ['location'];
  Map<String, TextEditingController> _controllers = {};

  int _index = 0;
  RecordModel? _record;

  @override
  void initState() {
    _controllers = {
      for (final i in _fields) i: TextEditingController(),
    };
    if (widget.recordId != null) {
      pb.collection('houses').getOne(widget.recordId!).then(_setRecord);
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
        title: const Text('房屋管理'),
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
            content: _houseForm(index: 0),
          ),
          Step(
            isActive: _index >= 1,
            title: const Text('物业审核'),
            content: _houseForm(index: 1),
          ),
          Step(
            isActive: _index >= 2,
            title: const Text('审核通过'),
            content: _houseForm(index: 2),
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
        .collection('houses')
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
        .collection('houses')
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
        .collection('houses')
        .update(_record!.id, body: body)
        .then(_setRecord)
        .catchError((error) => showException(context, error));
  }

  // 居民端/首页/房屋管理/删除房屋
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
              title: const Text('删除房屋'),
              content: const Text('确定要删除该房屋吗？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    pb.collection('houses').delete(_record!.id).then((value) {
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

  // 居民端/首页/房屋管理/填写信息
  Widget _houseForm({required int index}) {
    return Form(
      key: _formKeys[index],
      child: Column(
        children: [
          TextFormField(
            controller: _controllers['location'],
            decoration: const InputDecoration(
              labelText: '地址',
              hintText: '请填写房屋地址',
            ),
            validator: notNullValidator('地址不能为空'),
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
