import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/announcements.dart';
import 'package:smart_community/resident/announcement/Announcement.dart';
import 'package:smart_community/resident/announcement/announcements.dart';
import 'package:smart_community/resident/car/cars.dart';
import 'package:smart_community/resident/family/families.dart';
import 'package:smart_community/resident/house/houses.dart';
import 'package:smart_community/resident/problem/problems.dart';
import 'package:smart_community/resident/property/propertys.dart';
import 'package:smart_community/resident/verify/verify.dart';
import 'package:smart_community/resident/vote/votes.dart';
import 'package:smart_community/utils.dart';

class ResidentIndex extends StatefulWidget {
  const ResidentIndex({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  State<ResidentIndex> createState() => _ResidentIndexState();
}

class _ResidentIndexState extends State<ResidentIndex> {
  late Future<List<RecordModel>> announcements;

  String? _state;

  @override
  void initState() {
    announcements = pb.collection('announcements').getFullList(
          filter: 'communityId = "${widget.communityId}"',
          sort: '-created',
        );
    fetchRecord();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant final ResidentIndex oldWidget) {
    announcements = pb.collection('announcements').getFullList(
          filter: 'communityId = "${widget.communityId}"',
          sort: '-created',
        );
    fetchRecord();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(final BuildContext context) {
    final Map<String?, Text> label = {
      null: const Text('您还未入住该小区'),
      'reviewing': const Text(
        '您的账号正在审核中，请耐心等待',
        style: TextStyle(color: Colors.purple),
      ),
      'rejected': const Text(
        '您的账号未通过审核',
        style: TextStyle(color: Colors.red),
      ),
    };
    final Map<String?, Text> hint = {
      null: const Text('入住小区'),
      'reviewing': const Text('查看状态'),
      'rejected': const Text('查看状态'),
    };

    if (_state != 'verified') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            label[_state]!,
            TextButton(
              onPressed: () async {
                await navPush(
                  context,
                  ResidentVerify(communityId: widget.communityId),
                );
                fetchRecord();
              },
              child: hint[_state]!,
            ),
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
              builder: (
                final BuildContext context,
                final AsyncSnapshot<List<RecordModel>> snapshot,
              ) {
                if (snapshot.hasData) {
                  return ResidentIndexAnnouncement(
                    announcements: snapshot.data!,
                  );
                }
                return const ResidentIndexAnnouncement(announcements: []);
              },
            ),
            const Divider(height: 8),
            ResidentIndexService(
              communityId: widget.communityId,
            ),
            const Divider(height: 8),
            FutureBuilder(
              future: announcements,
              builder: (
                final BuildContext context,
                final AsyncSnapshot<List<RecordModel>> snapshot,
              ) {
                if (snapshot.hasData) {
                  return ResidentIndexAnnouncements(
                    communityId: widget.communityId,
                    announcements: snapshot.data!,
                  );
                }
                return ResidentIndexAnnouncements(
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

  void fetchRecord() {
    final String residentsFilter =
        'communityId = "${widget.communityId}" && userId = "${pb.authStore.model!.id}"';

    pb.collection('residents').getFullList(filter: residentsFilter).then(
      (final List<RecordModel> value) {
        setState(() {
          _state =
              value.isNotEmpty ? value.first.getStringValue('state') : null;
        });
      },
    );
  }
}

class ResidentIndexAnnouncement extends StatelessWidget {
  const ResidentIndexAnnouncement({
    required this.announcements,
    super.key,
  });

  final List<RecordModel> announcements;

  @override
  Widget build(final BuildContext context) => ListTile(
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
            ResidentAnnouncement(recordId: announcements.first.id),
          ),
          child: const Text('查看'),
        ),
      );
}

class ResidentIndexService extends StatelessWidget {
  const ResidentIndexService({
    required this.communityId,
    super.key,
  });

  final String communityId;

  @override
  Widget build(final BuildContext context) => Column(
        children: [
          Row(
            children: [
              ResidentIndexServiceIcon(
                onPressed: () =>
                    navPush(context, ResidentVerify(communityId: communityId)),
                icon: Icons.person,
                text: '实名认证',
                color: Colors.orange,
              ),
              ResidentIndexServiceIcon(
                onPressed: () =>
                    navPush(context, ResidentHouses(communityId: communityId)),
                icon: Icons.home,
                text: '房屋管理',
                color: Colors.green,
              ),
              ResidentIndexServiceIcon(
                onPressed: () =>
                    navPush(context, ResidentCars(communityId: communityId)),
                icon: Icons.car_rental,
                text: '车辆管理',
                color: Colors.blue,
              ),
              ResidentIndexServiceIcon(
                onPressed: () => navPush(
                  context,
                  ResidentFamilies(communityId: communityId),
                ),
                icon: Icons.people,
                text: '家人管理',
                color: Colors.purple,
              ),
            ],
          ),
          Row(
            children: [
              ResidentIndexServiceIcon(
                onPressed: () => navPush(
                  context,
                  ResidentProblems(communityId: communityId),
                ),
                icon: Icons.question_mark,
                text: '问题上报',
                color: Colors.cyan,
              ),
              ResidentIndexServiceIcon(
                onPressed: () =>
                    navPush(context, ResidentVotes(communityId: communityId)),
                icon: Icons.how_to_vote,
                text: '预算支出投票',
                color: Colors.indigo,
              ),
              ResidentIndexServiceIcon(
                onPressed: () => navPush(
                  context,
                  ResidentPropertys(communityId: communityId),
                ),
                icon: Icons.phone,
                text: '联系物业',
                color: Colors.lightGreen,
              ),
              ResidentIndexServiceIcon(
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

class ResidentIndexServiceIcon extends StatelessWidget {
  const ResidentIndexServiceIcon({
    required this.onPressed,
    required this.icon,
    required this.text,
    super.key,
    this.color,
  });

  final void Function() onPressed;
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(final BuildContext context) => Expanded(
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

class ResidentIndexAnnouncements extends StatelessWidget {
  const ResidentIndexAnnouncements({
    required this.communityId,
    required this.announcements,
    super.key,
  });

  final String communityId;
  final List<RecordModel> announcements;

  @override
  Widget build(final BuildContext context) => Expanded(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.newspaper),
              title: const Text('通知公告'),
              trailing: TextButton(
                onPressed: () => navPush(
                  context,
                  ResidentAnnouncements(communityId: communityId),
                ),
                child: const Text('更多'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (final BuildContext context, final int index) {
                  final RecordModel record = announcements[index];
                  return Announcement(
                    record: record,
                    onTap: () {
                      navPush(
                        context,
                        ResidentAnnouncement(recordId: record.id),
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
