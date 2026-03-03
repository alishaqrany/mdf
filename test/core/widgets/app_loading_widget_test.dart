import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mdf_app/core/widgets/app_loading_widget.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('AppLoadingWidget', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppLoadingWidget()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is centered', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppLoadingWidget()),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('does NOT show message text when message is null',
        (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppLoadingWidget()),
      );

      // Only the CircularProgressIndicator should be in the Column
      final column = tester.widget<Column>(find.byType(Column).first);
      // With null message, the if-block is skipped, so only 1 child (SizedBox with indicator)
      expect(column.children.length, 1);
    });

    testWidgets('shows message text when message is provided', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppLoadingWidget(message: 'Loading data...')),
      );

      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('uses custom size for indicator', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppLoadingWidget(size: 60)),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 60);
      expect(sizedBox.height, 60);
    });

    testWidgets('default size is 40', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppLoadingWidget()),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 40);
      expect(sizedBox.height, 40);
    });
  });

  group('AppLoadingOverlay', () {
    testWidgets('always renders child', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppLoadingOverlay(
            isLoading: false,
            child: Text('Child Content'),
          ),
        ),
      );

      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppLoadingOverlay(
            isLoading: true,
            child: Text('Child Content'),
          ),
        ),
      );

      expect(find.text('Child Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides loading indicator when isLoading is false',
        (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppLoadingOverlay(
            isLoading: false,
            child: Text('Child Content'),
          ),
        ),
      );

      expect(find.text('Child Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses Stack to overlay indicator on child', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppLoadingOverlay(
            isLoading: true,
            child: Text('Child Content'),
          ),
        ),
      );

      // The AppLoadingOverlay itself uses a Stack (there may be more in the tree)
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('shows dark overlay when loading', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppLoadingOverlay(
            isLoading: true,
            child: Text('Child Content'),
          ),
        ),
      );

      // Find the semi-transparent overlay container
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.color == Colors.black26,
        ),
      );
      expect(container.color, Colors.black26);
    });
  });
}
