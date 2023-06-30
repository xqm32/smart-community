import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:smart_community/utils.dart';

// 居民端/首页/房屋管理
class ResidentHouse extends StatefulWidget {
  const ResidentHouse({
    super.key,
    required this.communityId,
    this.houesId,
  });

  final String communityId;
  final String? houesId;

  @override
  State<ResidentHouse> createState() => _ResidentHouseState();
}

class _ResidentHouseState extends State<ResidentHouse> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _fields = ['location'];
  Map<String, TextEditingController> _controllers = {};

  int _index = 0;
  RecordModel? _house;

  @override
  void initState() {
    _controllers = {
      for (final i in _fields) i: TextEditingController(),
    };
    if (widget.houesId != null) {
      pb.collection('houses').getOne(widget.houesId!).then(_setHouse);
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
            content: _houseForm(),
          ),
          Step(
            isActive: _index >= 1,
            title: const Text('物业审核'),
            content: _houseAudit(),
          ),
          Step(
            isActive: _index >= 2,
            title: const Text('审核通过'),
            content: _housePassed(),
          )
        ],
      ),
    );
  }

  void _setHouse(RecordModel value) {
    int next = 1;
    if (value.getBoolValue('verified')) {
      next = 2;
    }

    setState(() {
      _house = value;
      _index = next;
    });
  }

  void _onContinuePressed() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> body = {
      for (final i in _controllers.entries) i.key: i.value.text
    };
    body.addAll({
      'userId': pb.authStore.model!.id,
      'communityId': widget.communityId,
    });

    pb
        .collection('houses')
        .create(body: body)
        .then(_setHouse)
        .catchError((error) => showException(context, error));
  }

  // 居民端/首页/房屋管理/删除房屋
  List<Widget>? _actionsBuilder(context) {
    if (_house == null || _index < 1) {
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
                    pb.collection('houses').delete(_house!.id);
                    Navigator.pop(context, 'OK');
                    navPop(context);
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
  Widget _houseForm() {
    return Form(
      key: _formKey,
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
          ElevatedButton(
              onPressed: _onContinuePressed, child: const Text('下一步')),
        ],
      ),
    );
  }

  // 居民端/首页/房屋管理/物业审核
  Widget _houseAudit() {
    return Column(
      children: [
        ListTile(title: Text('房屋地址：${_house?.getStringValue('location')}')),
        ListTile(title: Text('提交时间：${_house?.created.split(' ')[0]}')),
      ],
    );
  }

// 居民端/首页/房屋管理/审核通过
  Widget _housePassed() {
    return Column(
      children: [
        ListTile(title: Text('房屋地址：${_house?.getStringValue('location')}')),
        ListTile(title: Text('提交时间：${_house?.created.split(' ')[0]}')),
        ListTile(title: Text('通过时间：${_house?.updated.split(' ')[0]}')),
      ],
    );
  }
}
