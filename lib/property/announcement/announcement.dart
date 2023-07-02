import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

// 物业端/首页/通知公告
class PropertyAnnouncement extends StatefulWidget {
  const PropertyAnnouncement({
    super.key,
    required this.communityId,
    this.recordId,
  });

  final String communityId;
  final String? recordId;

  @override
  State<PropertyAnnouncement> createState() => _PropertyAnnouncementState();
}

class _PropertyAnnouncementState extends State<PropertyAnnouncement> {
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _fields = ['author', 'title', 'content'];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['发布公告', '修改公告'];
  int _index = 0;

  final service = pb.collection('announcements');

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
        title: const Text('通知公告'),
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

  void _setRecord(RecordModel value) {
    for (final i in _controllers.entries) {
      i.value.text = value.getStringValue(i.key);
    }
    setState(() {
      _record = value;
      _index = 1;
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

  // 物业端/首页/通知公告/填写信息
  Widget _form({required int index}) {
    return Form(
      key: _formKeys[index],
      child: Column(
        children: [
          TextFormField(
            controller: _controllers['author'],
            decoration: const InputDecoration(
              labelText: '作者',
              hintText: '请填写公告作者',
            ),
            validator: notNullValidator('作者不能为空'),
          ),
          TextFormField(
            controller: _controllers['title'],
            decoration: const InputDecoration(
              labelText: '标题',
              hintText: '请填写公告标题',
            ),
            validator: notNullValidator('标题不能为空'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers['content'],
            decoration: const InputDecoration(
              labelText: '内容',
              hintText: '请填写公告内容',
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            validator: notNullValidator('内容不能为空'),
            maxLines: null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onSubmitPressed,
            child: Text(['提交', '修改信息'].elementAt(_index)),
          )
        ],
      ),
    );
  }

  // 物业端/首页/通知公告/删除公告
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
              title: const Text('删除公告'),
              content: const Text('确定要删除该公告吗？'),
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
