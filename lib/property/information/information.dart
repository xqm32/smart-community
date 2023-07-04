import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

// 物业端/首页/小区信息配置
class PropertyInformation extends StatefulWidget {
  const PropertyInformation({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  State<PropertyInformation> createState() => _PropertyInformationState();
}

class _PropertyInformationState extends State<PropertyInformation> {
  List<GlobalKey<FormState>> _formKeys = [];

  final List<String> _fields = ['name', 'struct', 'parking'];
  Map<String, TextEditingController> _controllers = {};

  final List<String> _steps = ['配置信息', '修改信息'];
  int _index = 0;

  final service = pb.collection('communities');

  RecordModel? _record;

  @override
  void initState() {
    _formKeys = List.generate(_steps.length, (index) => GlobalKey<FormState>());
    _controllers = {
      for (final i in _fields) i: TextEditingController(),
    };
    service.getOne(widget.communityId).then(_setRecord);
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
        title: const Text('小区信息配置'),
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
    final index = record.getStringValue('struct').isNotEmpty &&
            record.getStringValue('parking').isNotEmpty
        ? 1
        : 0;
    for (final i in _controllers.entries) {
      i.value.text = record.getStringValue(i.key);
    }
    setState(() {
      _record = record;
      _index = index;
    });
  }

  Map<String, dynamic> _getBody() {
    final Map<String, dynamic> body = {
      for (final i in _controllers.entries) i.key: i.value.text
    };
    body.addAll({
      'userId': pb.authStore.model!.id,
      'communityId': widget.communityId,
    });

    return body;
  }

  void _onSubmitPressed() {
    if (!_formKeys[_index].currentState!.validate()) {
      return;
    }

    service
        .update(_record!.id, body: _getBody())
        .then(_setRecord)
        .catchError((error) => showException(context, error));
  }

  // 物业端/首页/小区信息配置/填写信息
  Widget _form({required int index}) {
    return Form(
      key: _formKeys[index],
      child: Column(
        children: [
          TextFormField(
            controller: _controllers['name'],
            decoration: const InputDecoration(
              labelText: '小区名',
              hintText: '请填写小区名',
            ),
            validator: notNullValidator('小区名不能为空'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers['struct'],
            decoration: const InputDecoration(
              labelText: '小区架构',
              hintText: '请填写小区架构',
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            validator: notNullValidator('小区架构不能为空'),
            maxLines: 16,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers['parking'],
            decoration: const InputDecoration(
              labelText: '车位架构',
              hintText: '请填写车位架构',
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            validator: notNullValidator('车位架构不能为空'),
            maxLines: 16,
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
      TextButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              surfaceTintColor: Theme.of(context).colorScheme.background,
              children: [
                SimpleDialogOption(
                  onPressed: () {
                    onPressed('struct').then((value) => {navPop(context)});
                  },
                  child: const Text('导入小区架构'),
                ),
                SimpleDialogOption(
                  onPressed: () {
                    onPressed('parking').then((value) => {navPop(context)});
                  },
                  child: const Text('导入车位架构'),
                ),
              ],
            );
          },
        ),
        child: const Text('导入信息', style: TextStyle(color: Colors.green)),
      )
    ];
  }

  Future<void> onPressed(String field) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: <String>['json'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null) {
      final string = await file.readAsString();
      _controllers[field]!.text = string;
    }
  }
}
