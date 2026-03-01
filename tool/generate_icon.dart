// Generate a 1024x1024 app icon PNG for MDF Academy
// Run: dart run tool/generate_icon.dart

import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Fill with gradient-like solid primary color #6C63FF
  final primary = img.ColorRgba8(108, 99, 255, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);
  final accent = img.ColorRgba8(0, 191, 166, 255);

  // Fill background
  img.fill(image, color: primary);

  // Draw rounded rect effect with corner radius
  // Simple approach: Fill entire image with primary and add a book + cap in white

  // Draw a simple centered "M" letter representation
  // Draw open book shape (two rectangles)
  final cx = size ~/ 2;
  final cy = size ~/ 2 - 30;

  // Left page
  img.fillRect(
    image,
    x1: cx - 200,
    y1: cy - 120,
    x2: cx - 10,
    y2: cy + 120,
    color: white,
  );

  // Right page (slightly darker white for depth)
  final lightWhite = img.ColorRgba8(240, 240, 255, 255);
  img.fillRect(
    image,
    x1: cx + 10,
    y1: cy - 120,
    x2: cx + 200,
    y2: cy + 120,
    color: lightWhite,
  );

  // Spine
  img.fillRect(
    image,
    x1: cx - 10,
    y1: cy - 120,
    x2: cx + 10,
    y2: cy + 120,
    color: img.ColorRgba8(220, 220, 255, 255),
  );

  // Graduation cap (triangle on top)
  // Draw as a filled triangle
  final capY = cy - 170;
  _fillTriangle(
    image,
    cx,
    capY - 40,
    cx - 130,
    capY + 20,
    cx + 130,
    capY + 20,
    accent,
  );

  // Cap button
  img.fillCircle(
    image,
    x: cx,
    y: capY - 40,
    radius: 10,
    color: img.ColorRgba8(255, 215, 0, 255),
  );

  // "MDF" text at bottom — draw using simple pixel blocks
  // Instead, just leave the icon clean with book + cap

  // Save
  final pngBytes = img.encodePng(image);
  File('assets/icons/app_icon.png').writeAsBytesSync(pngBytes);
  print('Generated assets/icons/app_icon.png (${pngBytes.length} bytes)');
}

void _fillTriangle(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  int x3,
  int y3,
  img.Color color,
) {
  // Simple scanline triangle fill
  final minY = [y1, y2, y3].reduce(min);
  final maxY = [y1, y2, y3].reduce(max);

  for (int y = minY; y <= maxY; y++) {
    final xs = <int>[];
    _addEdgeX(xs, x1, y1, x2, y2, y);
    _addEdgeX(xs, x2, y2, x3, y3, y);
    _addEdgeX(xs, x3, y3, x1, y1, y);

    if (xs.length >= 2) {
      xs.sort();
      for (int x = xs.first; x <= xs.last; x++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}

void _addEdgeX(List<int> xs, int x1, int y1, int x2, int y2, int y) {
  if ((y1 <= y && y <= y2) || (y2 <= y && y <= y1)) {
    if (y1 == y2) return;
    final x = x1 + (y - y1) * (x2 - x1) ~/ (y2 - y1);
    xs.add(x);
  }
}
