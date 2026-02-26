/// Rewrites Moodle HTML content for display in the app.
class HtmlParser {
  HtmlParser._();

  /// Replace @@PLUGINFILE@@ placeholders in Moodle HTML with actual URLs.
  static String rewritePluginFileUrls(
    String html, {
    required String baseUrl,
    required String token,
    required int contextId,
    required String component,
    required String fileArea,
    int itemId = 0,
  }) {
    return html.replaceAll(
      '@@PLUGINFILE@@',
      '$baseUrl/webservice/pluginfile.php/$contextId/$component/$fileArea/$itemId?token=$token',
    );
  }

  /// Extract YouTube video IDs from HTML content.
  static List<String> extractYoutubeIds(String html) {
    final regex = RegExp(
      r'(?:youtube\.com\/(?:embed\/|watch\?v=)|youtu\.be\/)([\w-]+)',
      caseSensitive: false,
    );
    return regex.allMatches(html).map((m) => m.group(1)!).toList();
  }

  /// Extract Vimeo video IDs from HTML content.
  static List<String> extractVimeoIds(String html) {
    final regex = RegExp(
      r'vimeo\.com\/(?:video\/)?(\d+)',
      caseSensitive: false,
    );
    return regex.allMatches(html).map((m) => m.group(1)!).toList();
  }

  /// Extract plain text from HTML.
  static String stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .trim();
  }

  /// Check if content contains embedded video.
  static bool hasEmbeddedVideo(String html) {
    return html.contains('youtube.com') ||
        html.contains('youtu.be') ||
        html.contains('vimeo.com') ||
        html.contains('<video');
  }
}
