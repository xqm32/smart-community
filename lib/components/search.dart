import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class SearchAction extends StatelessWidget {
  const SearchAction({
    super.key,
    required this.records,
    required this.test,
    required this.toElement,
    this.builder,
  });

  final List<RecordModel> records;
  final bool Function(RecordModel record, String input) test;
  final Widget Function(RecordModel record) toElement;
  final Widget Function(BuildContext context, SearchController controller)? builder;

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
        viewSurfaceTintColor: Theme.of(context).colorScheme.background,
        isFullScreen: true,
        builder: builder ??
            (context, controller) => IconButton(
                onPressed: () => controller.openView(),
                icon: const Icon(Icons.search)),
        suggestionsBuilder: (context, controller) {
          final String input = controller.value.text;
          return records
              .where((record) => test(record, input))
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
