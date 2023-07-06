import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/utils.dart';

class PropertyInformation extends StatefulWidget {
  const PropertyInformation({
    required this.communityId,
    super.key,
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

  final RecordService service = pb.collection('communities');

  RecordModel? _record;

  @override
  void initState() {
    _formKeys = List.generate(
      _steps.length,
      (final int index) => GlobalKey<FormState>(),
    );
    _controllers = {
      for (final String i in _fields) i: TextEditingController(),
    };
    service.getOne(widget.communityId).then(_setRecord);
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
          title: const Text('小区信息配置'),
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
    final int index = record.getStringValue('struct').isNotEmpty &&
            record.getStringValue('parking').isNotEmpty
        ? 1
        : 0;
    for (final MapEntry<String, TextEditingController> i
        in _controllers.entries) {
      i.value.text = record.getStringValue(i.key);
    }
    setState(() {
      _record = record;
      _index = index;
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
        .catchError((final error) => showException(context, error));
    showSuccess(context, '提交成功');
  }

  Widget _form({required final int index}) => Form(
        key: _formKeys[index],
        child: Column(
          children: [
            TextFormField(
              controller: _controllers['name'],
              decoration: const InputDecoration(
                labelText: '小区名',
                hintText: '请填写小区名',
              ),
              validator: FormBuilderValidators.required(errorText: '小区名不能为空'),
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
              validator: FormBuilderValidators.required(errorText: '小区架构不能为空'),
              maxLines: null,
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
              validator: FormBuilderValidators.required(errorText: '车位架构不能为空'),
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

  List<Widget>? _actionsBuilder(final context) {
    if (_record == null) {
      return null;
    }

    return [
      TextButton(
        onPressed: () => showDialog(
          context: context,
          builder: (final BuildContext context) => SimpleDialog(
            surfaceTintColor: Theme.of(context).colorScheme.background,
            children: [
              SimpleDialogOption(
                onPressed: () {
                  onPressed('struct').then((final value) => {navPop(context)});
                },
                child: const Text('导入小区架构'),
              ),
              SimpleDialogOption(
                onPressed: () {
                  onPressed('parking').then((final value) => {navPop(context)});
                },
                child: const Text('导入车位架构'),
              ),
            ],
          ),
        ),
        child: const Text('导入信息', style: TextStyle(color: Colors.green)),
      )
    ];
  }

  Future<void> onPressed(final String field) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'JSON',
      extensions: <String>['json'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null) {
      final String string = await file.readAsString();
      _controllers[field]!.text = string;
    }
  }
}
