import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:smart_community/components/search.dart';

class Manage extends StatefulWidget {
  const Manage({
    super.key,
    this.title,
    required this.fetchRecords,
    this.onAddPressed,
    required this.toElement,
  });

  final Widget? title;
  final Future<List<RecordModel>> Function() fetchRecords;
  final Function(
    BuildContext context,
    void Function() refreshRecords,
  )? onAddPressed;
  final Widget Function(
    BuildContext context,
    void Function() refreshRecords,
    RecordModel record,
  ) toElement;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title,
        actions: [
          IconButton(
              onPressed: refreshRecords, icon: const Icon(Icons.refresh)),
          FutureBuilder(
            future: _records,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SearchAction(
                  records: snapshot.data!,
                  test: (record, input) =>
                      record.getStringValue('location').contains(input),
                  toElement: (record) =>
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
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RecordList(
                records: snapshot.data!,
                itemBuilder: (context, index) {
                  final record = snapshot.data!.elementAt(index);
                  return widget.toElement(context, refreshRecords, record);
                });
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
  }

  void refreshRecords() {
    setState(() {
      _records = widget.fetchRecords();
    });
  }
}
