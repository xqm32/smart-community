import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:smart_community/utils.dart';

// 居民房屋管理页面组件
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
  // 参见 https://api.flutter.dev/flutter/widgets/Form-class.html#widgets.Form.1
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 参见 https://docs.flutter.dev/cookbook/forms/text-field-changes#2-use-a-texteditingcontroller
  final TextEditingController _locationController = TextEditingController();

  int _index = 0;
  RecordModel? _house;

  void _setHouse(RecordModel value) {
    int next = 1;
    if (value.getBoolValue('Verified')) {
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
    
    // 提交的数据不包含 Verified 字段，会自动设置为 false
    final body = <String, dynamic>{
      "userId": pb.authStore.model!.id,
      "communityId": widget.communityId,
      "location": _locationController.text,
    };

    pb.collection('houses').create(body: body).then(_setHouse);
  }

  @override
  void initState() {
    if (widget.houesId != null) {
      pb.collection('houses').getOne(widget.houesId!).then(_setHouse);
    }

    super.initState();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加房屋')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _index,
        controlsBuilder: (context, details) => Container(),
        steps: [
          Step(
            isActive: _index >= 0,
            title: const Text('填写信息'),
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: '地址',
                      hintText: '请填写房屋地址',
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return '地址不能为空';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _onContinuePressed, child: const Text('下一步')),
                ],
              ),
            ),
          ),
          Step(
            isActive: _index >= 1,
            title: const Text('物业审核'),
            content: Column(
              children: [
                ListTile(
                    title: Text('房屋地址：${_house?.getStringValue('location')}')),
                ListTile(title: Text('提交时间：${_house?.created.split(' ')[0]}')),
              ],
            ),
          ),
          Step(
            isActive: _index >= 2,
            title: const Text('审核通过'),
            content: Column(
              children: [
                ListTile(
                    title: Text('房屋地址：${_house?.getStringValue('location')}')),
                ListTile(title: Text('提交时间：${_house?.created.split(' ')[0]}')),
                ListTile(title: Text('通过时间：${_house?.updated.split(' ')[0]}')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
