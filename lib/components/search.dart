import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class SearchAction extends StatelessWidget {
  const SearchAction({
    required this.records,
    required this.filter,
    required this.toElement,
    super.key,
    this.builder,
  });

  final List<RecordModel> records;
  final bool Function(RecordModel record, String input) filter;
  final Widget Function(RecordModel record) toElement;
  final Widget Function(BuildContext context, SearchController controller)?
      builder;

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      viewSurfaceTintColor: Theme.of(context).colorScheme.background,
      isFullScreen: true,
      builder: builder ??
          (BuildContext context, SearchController controller) => IconButton(
                onPressed: () => controller.openView(),
                icon: const Icon(Icons.search),
              ),
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        final String input = controller.value.text;
        return records
            .where((RecordModel record) => filter(record, input))
            .map(toElement)
            .toList();
      },
    );
  }
}

class RecordList extends StatelessWidget {
  const RecordList({
    required this.records,
    required this.itemBuilder,
    super.key,
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
