import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/search.dart';

class Manage extends StatefulWidget {
  const Manage({
    required this.title,
    required this.fetchRecords,
    required this.toElement,
    required this.filter,
    super.key,
    this.onAddPressed,
  });

  final Widget title;
  final Future<List<RecordModel>> Function() fetchRecords;

  final bool Function(RecordModel record, String input) filter;
  final Widget Function(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) toElement;
  final Function(
    BuildContext context,
    void Function() refreshRecords,
  )? onAddPressed;

  @override
  State<Manage> createState() => _ManageState();
}

class _ManageState extends State<Manage> {
  late Future<List<RecordModel>> _records;

  @override
  void initState() {
    _records = widget.fetchRecords();
    super.initState();
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
      appBar: AppBar(
        title: widget.title,
        actions: [
          IconButton(
            onPressed: refreshRecords,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
          FutureBuilder(
            future: _records,
            builder: (
              final BuildContext context,
              final AsyncSnapshot<List<RecordModel>> snapshot,
            ) {
              if (snapshot.hasData) {
                return SearchAction(
                  records: snapshot.data!,
                  filter: widget.filter,
                  toElement: (final RecordModel record) =>
                      widget.toElement(context, refreshRecords, record),
                );
              }
              return const Icon(Icons.search);
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: _records,
        builder:
            (final BuildContext context, final AsyncSnapshot<List<RecordModel>> snapshot) {
          if (snapshot.hasData) {
            return RecordList(
              records: snapshot.data!,
              itemBuilder: (final BuildContext context, final int index) {
                final RecordModel record = snapshot.data!.elementAt(index);
                return widget.toElement(context, refreshRecords, record);
              },
            );
          }
          return const LinearProgressIndicator();
        },
      ),
      floatingActionButton: widget.onAddPressed != null
          ? FloatingActionButton(
              onPressed: () => widget.onAddPressed!(context, refreshRecords),
              child: const Icon(Icons.add),
            )
          : null,
    );

  void refreshRecords() {
    setState(() {
      _records = widget.fetchRecords();
    });
  }
}
