import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:mdf_app/core/widgets/app_error_widget.dart';
import 'package:mdf_app/app/theme/colors.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    // easy_localization requires SharedPreferences + initialization
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // ─────────────────────────────────────
  // AppErrorWidget
  // ─────────────────────────────────────
  group('AppErrorWidget', () {
    testWidgets('renders error icon by default', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppErrorWidget(message: 'An error occurred')),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('displays provided message', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppErrorWidget(message: 'Something went wrong'),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('uses custom icon when provided', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppErrorWidget(
            message: 'No network',
            icon: Icons.wifi_off,
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('does NOT show retry button when onRetry is null',
        (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppErrorWidget(message: 'Error')),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows retry button when onRetry is provided',
        (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppErrorWidget(message: 'Error', onRetry: () {}),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        makeTestableWidget(
          AppErrorWidget(
            message: 'Error',
            onRetry: () => called = true,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(called, isTrue);
    });

    testWidgets('error icon uses AppColors.error', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppErrorWidget(message: 'Error')),
      );

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(icon.color, AppColors.error);
      expect(icon.size, 64);
    });

    testWidgets('is centered', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(const AppErrorWidget(message: 'Error')),
      );

      expect(find.byType(Center), findsWidgets);
    });
  });

  // ─────────────────────────────────────
  // AppEmptyWidget
  // ─────────────────────────────────────
  group('AppEmptyWidget', () {
    testWidgets('renders default inbox icon', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppEmptyWidget(message: 'No items yet'),
        ),
      );

      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
    });

    testWidgets('displays message text', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppEmptyWidget(message: 'Nothing to show'),
        ),
      );

      expect(find.text('Nothing to show'), findsOneWidget);
    });

    testWidgets('uses custom icon when provided', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppEmptyWidget(
            message: 'No results',
            icon: Icons.search_off,
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsNothing);
    });

    testWidgets('does NOT show action when null', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppEmptyWidget(message: 'Empty'),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('shows action widget when provided', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppEmptyWidget(
            message: 'No items',
            action: ElevatedButton(
              onPressed: () {},
              child: const Text('Add Item'),
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('tapping action widget triggers callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        makeTestableWidget(
          AppEmptyWidget(
            message: 'No items',
            action: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('Create'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Create'));
      expect(tapped, isTrue);
    });

    testWidgets('icon size is 80', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppEmptyWidget(message: 'Empty'),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_rounded));
      expect(icon.size, 80);
    });
  });
}
