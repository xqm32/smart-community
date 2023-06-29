import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class SearchAction extends StatelessWidget {
  const SearchAction({
    super.key,
    required this.records,
    required this.test,
    required this.toElement,
  });

  final List<RecordModel> records;
  final bool Function(RecordModel, String) test;
  final Widget Function(RecordModel) toElement;

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
        viewSurfaceTintColor: Theme.of(context).colorScheme.background,
        isFullScreen: true,
        builder: (context, controller) => IconButton(
            onPressed: () => controller.openView(),
            icon: const Icon(Icons.search)),
        suggestionsBuilder: (context, controller) {
          final String input = controller.value.text;
          return records
              .where((element) => test(element, input))
              .map(toElement)
              .toList();
        });
  }
}

class RecordList extends StatelessWidget {
  const RecordList({
    super.key,
    required this.records,
    required this.itemBuilder,
  });

  final List<RecordModel> records;
  final Widget? Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: itemBuilder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
