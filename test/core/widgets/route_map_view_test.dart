import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodbridge/core/widgets/route_map_view.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RouteMapView Live Animated Route Tests', () {
    testWidgets('renders fallback painter and essential controls in test environment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteMapView(
              pickupAddress: 'Camp, Pune',
              destinationAddress: 'Asha Shelter, Sadar Bazar',
              etaText: 'ETA: 6 min • 2.1 km',
              pickupLocation: LatLng(18.5204, 73.8567),
              destinationLocation: LatLng(18.5300, 73.8650),
              courierLocation: LatLng(18.5250, 73.8600),
            ),
          ),
        ),
      );

      expect(find.byType(RouteMapView), findsOneWidget);
      expect(find.byIcon(Icons.two_wheeler), findsOneWidget);
      expect(find.text('ETA: 6 min • 2.1 km'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.fit_screen_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('re-centers and zooms in/out upon tapping map control buttons', (tester) async {
      bool refreshed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteMapView(
              onRefresh: () {
                refreshed = true;
              },
            ),
          ),
        ),
      );

      final zoomInBtn = find.byTooltip('Zoom In');
      final zoomOutBtn = find.byTooltip('Zoom Out');
      final fitBoundsBtn = find.byTooltip('Fit Entire Route');
      final refreshBtn = find.byTooltip('Refresh Route');

      expect(zoomInBtn, findsOneWidget);
      expect(zoomOutBtn, findsOneWidget);
      expect(fitBoundsBtn, findsOneWidget);
      expect(refreshBtn, findsOneWidget);

      await tester.tap(zoomInBtn);
      await tester.pump();

      await tester.tap(zoomOutBtn);
      await tester.pump();

      await tester.tap(fitBoundsBtn);
      await tester.pump();

      await tester.tap(refreshBtn);
      await tester.pump();
      expect(refreshed, isTrue);
    });
  });
}
