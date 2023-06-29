import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/search.dart';
import 'package:smart_community/property/property.dart';
import 'package:smart_community/resident/resident.dart';
import 'package:smart_community/utils.dart';

class Community extends StatefulWidget {
  final String role;

  const Community({super.key, required this.role});

  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  late Future<List<RecordModel>> communities;

  void _selectCommunity(context, communityId) {
    if (widget.role == 'resident') {
      navPush(context, Resident(communityId: communityId));
    } else if (widget.role == 'property') {
      navPush(context, Property(communityId: communityId));
    } else {
      showError(context, '未知角色');
    }
  }

  @override
  void initState() {
    communities = pb.collection('communities').getFullList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择小区'),
        actions: [
          FutureBuilder(
            future: communities,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SearchAction(
                    records: snapshot.data!,
                    test: (element, input) =>
                        element.getStringValue('name').contains(input),
                    toElement: (element) => ListTile(
                        title: Text(element.getStringValue('name')),
                        onTap: () => _selectCommunity(context, element.id)));
              }
              return const Icon(Icons.search);
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: communities,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RecordList(
              records: snapshot.data!,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      snapshot.data!.elementAt(index).getStringValue('name')),
                  onTap: () => _selectCommunity(
                      context, snapshot.data!.elementAt(index).id),
                );
              },
            );
          }
          return const LinearProgressIndicator();
        },
      ),
    );
  }
}
