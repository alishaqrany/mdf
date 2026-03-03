import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Performance-oriented image helper utilities.
///
/// Replaces raw [NetworkImage] with [CachedNetworkImageProvider]
/// for disk/memory caching, and provides safe fallback handling.
class ImageProviderHelper {
  ImageProviderHelper._();

  /// Returns a [CachedNetworkImageProvider] for the given URL,
  /// or null if the URL is null or empty.
  ///
  /// Usage:
  /// ```dart
  /// CircleAvatar(
  ///   backgroundImage: ImageProviderHelper.cached(url),
  /// )
  /// ```
  static ImageProvider? cached(String? url) {
    if (url == null || url.isEmpty) return null;
    return CachedNetworkImageProvider(url);
  }

  /// Returns a [DecorationImage] with caching, or null if URL is empty.
  static DecorationImage? decorationImage(
    String? url, {
    BoxFit fit = BoxFit.cover,
  }) {
    if (url == null || url.isEmpty) return null;
    return DecorationImage(
      image: CachedNetworkImageProvider(url),
      fit: fit,
    );
  }
}
