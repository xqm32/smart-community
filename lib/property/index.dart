import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/announcements.dart';
import 'package:smart_community/property/announcement/Announcement.dart';
import 'package:smart_community/property/announcement/announcements.dart';
import 'package:smart_community/property/car/cars.dart';

import 'package:smart_community/utils.dart';

// 物业端/首页
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

  @override
  void initState() {
    announcements = pb.collection('announcements').getFullList(
        filter: 'communityId = "${widget.communityId}"', sort: '-created');
    super.initState();
  }

  @override
  void didUpdateWidget(covariant PropertyIndex oldWidget) {
    announcements = pb.collection('announcements').getFullList(
        filter: 'communityId = "${widget.communityId}"', sort: '-created');
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
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

// 物业端/首页/通知
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

// 物业端/首页/服务
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
              onPressed: () {},
              icon: Icons.person,
              text: '居民管理',
              color: Colors.orange,
            ),
            PropertyIndexServiceIcon(
              onPressed: () {},
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
              onPressed: () {},
              icon: Icons.people,
              text: '家人审核',
              color: Colors.purple,
            ),
          ],
        ),
        Row(
          children: [
            PropertyIndexServiceIcon(
              onPressed: () {},
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
              onPressed: () {},
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

// 物业端/首页/服务/图标
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

// 物业端/首页/新闻
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
    // ListView 在 Column 中需要有确定的高度
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
