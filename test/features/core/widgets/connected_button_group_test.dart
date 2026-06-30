import 'package:atril/features/core/widgets/connected_button_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConnectedButtonGroup emits single selection changes', (tester) async {
    Set<String>? selection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectedButtonGroup<String>(
            buttons: const [
              ButtonGroupItem(value: 'title', label: Text('Title')),
              ButtonGroupItem(value: 'artist', label: Text('Artist')),
            ],
            selected: const {'title'},
            onSelectionChanged: (value) => selection = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Artist'));
    await tester.pump();

    expect(selection, {'artist'});
  });

  testWidgets('ConnectedButtonGroup supports multi-selection and disabled buttons', (tester) async {
    final changes = <Set<String>>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectedButtonGroup<String>(
            buttons: const [
              ButtonGroupItem(value: 'title', label: Text('Title')),
              ButtonGroupItem(value: 'artist', label: Text('Artist')),
              ButtonGroupItem(value: 'key', label: Text('Key'), enabled: false),
            ],
            selected: const {'title'},
            multiSelectionEnabled: true,
            onSelectionChanged: changes.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Artist'));
    await tester.tap(find.text('Key'));
    await tester.pump();

    expect(changes, [
      {'title', 'artist'},
    ]);
  });

  testWidgets('ConnectedButtonGroup can clear the final selection when allowed', (tester) async {
    Set<String>? selection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectedButtonGroup<String>(
            buttons: const [ButtonGroupItem(value: 'title', label: Text('Title'))],
            selected: const {'title'},
            emptySelectionAllowed: true,
            onSelectionChanged: (value) => selection = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Title'));
    await tester.pump();

    expect(selection, isEmpty);
  });
}
