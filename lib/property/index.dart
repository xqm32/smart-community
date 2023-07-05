import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/announcements.dart';
import 'package:smart_community/property/announcement/Announcement.dart';
import 'package:smart_community/property/announcement/announcements.dart';
import 'package:smart_community/property/car/cars.dart';
import 'package:smart_community/property/family/families.dart';
import 'package:smart_community/property/house/houses.dart';
import 'package:smart_community/property/information/information.dart';
import 'package:smart_community/property/problem/problems.dart';
import 'package:smart_community/property/resident/residents.dart';

import 'package:smart_community/utils.dart';

class PropertyIndex extends StatefulWidget {
  const PropertyIndex({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  State<PropertyIndex> createState() => _PropertyIndexState();
}

class _PropertyIndexState extends State<PropertyIndex> {
  late Future<List<RecordModel>> announcements;

  String? _state;

  @override
  void initState() {
    announcements = pb.collection('announcements').getFullList(
        filter: 'communityId = "${widget.communityId}"', sort: '-created');

    final residentsFilter =
        'communityId = "${widget.communityId}" && userId = "${pb.authStore.model!.id}"';

    pb.collection('propertys').getFullList(filter: residentsFilter).then(
      (value) {
        setState(() {
          _state =
              value.isNotEmpty ? value.first.getStringValue('state') : null;
        });
      },
    );

    super.initState();
  }

  @override
  void didUpdateWidget(covariant PropertyIndex oldWidget) {
    announcements = pb.collection('announcements').getFullList(
        filter: 'communityId = "${widget.communityId}"', sort: '-created');

    final residentsFilter =
        'communityId = "${widget.communityId}" && userId = "${pb.authStore.model!.id}"';

    pb.collection('propertys').getFullList(filter: residentsFilter).then(
      (value) {
        setState(() {
          _state =
              value.isNotEmpty ? value.first.getStringValue('state') : null;
        });
      },
    );

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '您没有管理该小区的权限',
              style: TextStyle(color: Colors.red),
            )
          ],
        ),
      );
    } else if (_state != 'verified') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_state == 'reviewing')
              const Text(
                '您的账号正在审核中，请耐心等待',
                style: TextStyle(color: Colors.purple),
              )
            else if (_state == 'rejected')
              const Text(
                '您的账号未通过审核',
                style: TextStyle(color: Colors.red),
              )
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            FutureBuilder(
              future: announcements,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return PropertyIndexAnnouncement(
                    communityId: widget.communityId,
                    announcements: snapshot.data!,
                  );
                }
                return PropertyIndexAnnouncement(
                  communityId: widget.communityId,
                  announcements: const [],
                );
              },
            ),
            const Divider(height: 8),
            PropertyIndexService(
              communityId: widget.communityId,
            ),
            const Divider(height: 8),
            FutureBuilder(
              future: announcements,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return PropertyIndexAnnouncements(
                    communityId: widget.communityId,
                    announcements: snapshot.data!,
                  );
                }
                return PropertyIndexAnnouncements(
                  communityId: widget.communityId,
                  announcements: const [],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyIndexAnnouncement extends StatelessWidget {
  const PropertyIndexAnnouncement({
    super.key,
    required this.communityId,
    required this.announcements,
  });

  final String communityId;
  final List<RecordModel> announcements;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications),
      title: announcements.isEmpty
          ? const Text('暂无通知')
          : Text(
              announcements.first.getStringValue('title'),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
      trailing: TextButton(
        onPressed: () => navPush(
          context,
          PropertyAnnouncement(
            communityId: communityId,
            recordId: announcements.first.id,
          ),
        ),
        child: const Text('编辑'),
      ),
    );
  }
}

class PropertyIndexService extends StatelessWidget {
  const PropertyIndexService({
    super.key,
    required this.communityId,
  });

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            PropertyIndexServiceIcon(
              onPressed: () =>
                  navPush(context, PropertyResidents(communityId: communityId)),
              icon: Icons.person,
              text: '居民管理',
              color: Colors.orange,
            ),
            PropertyIndexServiceIcon(
              onPressed: () =>
                  navPush(context, PropertyHouses(communityId: communityId)),
              icon: Icons.home,
              text: '房屋审核',
              color: Colors.green,
            ),
            PropertyIndexServiceIcon(
              onPressed: () =>
                  navPush(context, PropertyCars(communityId: communityId)),
              icon: Icons.car_rental,
              text: '车辆审核',
              color: Colors.blue,
            ),
            PropertyIndexServiceIcon(
              onPressed: () =>
                  navPush(context, PropertyFamilies(communityId: communityId)),
              icon: Icons.people,
              text: '家人审核',
              color: Colors.purple,
            ),
          ],
        ),
        Row(
          children: [
            PropertyIndexServiceIcon(
              onPressed: () =>
                  navPush(context, PropertyProblems(communityId: communityId)),
              icon: Icons.question_mark,
              text: '事件处置',
              color: Colors.cyan,
            ),
            PropertyIndexServiceIcon(
              onPressed: () {},
              icon: Icons.how_to_vote,
              text: '支出投票管理',
              color: Colors.indigo,
            ),
            PropertyIndexServiceIcon(
              onPressed: () => navPush(
                  context, PropertyInformation(communityId: communityId)),
              icon: Icons.settings,
              text: '小区信息配置',
              color: Colors.lightGreen,
            ),
            PropertyIndexServiceIcon(
              onPressed: () {},
              icon: Icons.more_horiz,
              text: '更多服务',
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class PropertyIndexServiceIcon extends StatelessWidget {
  const PropertyIndexServiceIcon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    this.color,
  });

  final void Function() onPressed;
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            iconSize: 50,
            color: color,
          ),
          Text(text),
        ],
      ),
    );
  }
}

class PropertyIndexAnnouncements extends StatelessWidget {
  const PropertyIndexAnnouncements({
    super.key,
    required this.communityId,
    required this.announcements,
  });

  final String communityId;
  final List<RecordModel> announcements;

  @override
  Widget build(BuildContext context) {
    // 参见 https://stackoverflow.com/questions/45669202/how-to-add-a-listview-to-a-column-in-flutter

    return Expanded(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.newspaper),
            title: const Text('通知公告'),
            trailing: TextButton(
              onPressed: () => navPush(
                context,
                PropertyAnnouncements(communityId: communityId),
              ),
              child: const Text('更多'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final record = announcements[index];
                return Announcement(
                  record: record,
                  onTap: () {
                    navPush(
                      context,
                      PropertyAnnouncement(
                          communityId: communityId, recordId: record.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
