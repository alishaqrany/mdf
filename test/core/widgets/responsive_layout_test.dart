import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mdf_app/core/widgets/responsive_layout.dart';

void main() {
  // Helper to pump a widget within a MediaQuery of a given width.
  Widget wrapWithSize(Widget child, {required double width, double height = 800}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: Scaffold(body: child),
      ),
    );
  }

  // ─────────────────────────────────────
  // ResponsiveBuilder
  // ─────────────────────────────────────
  group('ResponsiveBuilder', () {
    testWidgets('shows mobile widget on narrow screen (< 600)',
        (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const ResponsiveBuilder(
          mobile: Text('Mobile'),
          tablet: Text('Tablet'),
          desktop: Text('Desktop'),
        ),
        width: 599,
      ));

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('shows tablet widget on medium screen (600–1023)',
        (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const ResponsiveBuilder(
          mobile: Text('Mobile'),
          tablet: Text('Tablet'),
          desktop: Text('Desktop'),
        ),
        width: 800,
      ));

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('shows desktop widget on wide screen (>= 1024)',
        (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const ResponsiveBuilder(
          mobile: Text('Mobile'),
          tablet: Text('Tablet'),
          desktop: Text('Desktop'),
        ),
        width: 1200,
      ));

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);
    });

    testWidgets('falls back to mobile when tablet is null on medium screen',
        (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const ResponsiveBuilder(
          mobile: Text('Mobile'),
          // tablet is null
          desktop: Text('Desktop'),
        ),
        width: 800,
      ));

      expect(find.text('Mobile'), findsOneWidget);
    });

    testWidgets('falls back to tablet when desktop is null on wide screen',
        (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const ResponsiveBuilder(
          mobile: Text('Mobile'),
          tablet: Text('Tablet'),
          // desktop is null
        ),
        width: 1200,
      ));

      expect(find.text('Tablet'), findsOneWidget);
    });

    testWidgets('falls back to mobile when both tablet and desktop are null on wide screen',
        (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const ResponsiveBuilder(
          mobile: Text('Mobile'),
          // tablet and desktop both null
        ),
        width: 1200,
      ));

      expect(find.text('Mobile'), findsOneWidget);
    });

    testWidgets('boundary: width exactly 600 is tablet', (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const ResponsiveBuilder(
          mobile: Text('Mobile'),
          tablet: Text('Tablet'),
          desktop: Text('Desktop'),
        ),
        width: 600,
      ));

      expect(find.text('Tablet'), findsOneWidget);
    });

    testWidgets('boundary: width exactly 1024 is desktop', (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const ResponsiveBuilder(
          mobile: Text('Mobile'),
          tablet: Text('Tablet'),
          desktop: Text('Desktop'),
        ),
        width: 1024,
      ));

      expect(find.text('Desktop'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────
  // MasterDetailLayout
  // ─────────────────────────────────────
  group('MasterDetailLayout', () {
    testWidgets('shows only master on narrow screen', (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const MasterDetailLayout(
          master: Text('Master'),
          detail: Text('Detail'),
        ),
        width: 500,
      ));

      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Detail'), findsNothing);
    });

    testWidgets('shows master and detail on wide screen', (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const MasterDetailLayout(
          master: Text('Master'),
          detail: Text('Detail'),
          masterWidth: 200,
        ),
        width: 800,
      ));

      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
    });

    testWidgets('shows placeholder when detail is null on wide screen',
        (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const MasterDetailLayout(master: Text('Master')),
        width: 800,
      ));

      expect(find.text('Master'), findsOneWidget);
      // The placeholder text is in Arabic
      expect(find.text('اختر عنصراً من القائمة'), findsOneWidget);
    });

    testWidgets('uses Row for layout on wide screen', (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const MasterDetailLayout(
          master: Text('Master'),
          detail: Text('Detail'),
          masterWidth: 200,
        ),
        width: 800,
      ));

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('has a VerticalDivider between master and detail',
        (tester) async {
      await tester.pumpWidget(wrapWithSize(
        const MasterDetailLayout(
          master: Text('Master'),
          detail: Text('Detail'),
          masterWidth: 200,
        ),
        width: 800,
      ));

      expect(find.byType(VerticalDivider), findsOneWidget);
    });
  });

  // ─────────────────────────────────────
  // ResponsiveLayout static helpers
  // ─────────────────────────────────────
  group('ResponsiveLayout static helpers', () {
    testWidgets('isMobile returns true for width < 600', (tester) async {
      late bool result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.isMobile(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, isTrue);
    });

    testWidgets('isTablet returns true for width 600–1023', (tester) async {
      late bool result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.isTablet(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, isTrue);
    });

    testWidgets('isDesktop returns true for width >= 1024', (tester) async {
      late bool result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.isDesktop(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, isTrue);
    });

    testWidgets('gridColumns returns 2 for mobile', (tester) async {
      late int result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.gridColumns(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, 2);
    });

    testWidgets('gridColumns returns 3 for tablet', (tester) async {
      late int result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.gridColumns(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, 3);
    });

    testWidgets('gridColumns returns 4 for desktop', (tester) async {
      late int result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.gridColumns(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, 4);
    });

    testWidgets('sideWidth returns full width for mobile', (tester) async {
      late double result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.sideWidth(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, 400);
    });

    testWidgets('sideWidth returns 280 for tablet', (tester) async {
      late double result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.sideWidth(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, 280);
    });

    testWidgets('sideWidth returns 320 for desktop', (tester) async {
      late double result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.sideWidth(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, 320);
    });

    testWidgets('contentMaxWidth returns 800 for desktop', (tester) async {
      late double result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.contentMaxWidth(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, 800);
    });

    testWidgets('contentMaxWidth returns infinity for non-desktop',
        (tester) async {
      late double result;
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(builder: (context) {
            result = ResponsiveLayout.contentMaxWidth(context);
            return const SizedBox();
          }),
        ),
      ));
      expect(result, double.infinity);
    });
  });
}
