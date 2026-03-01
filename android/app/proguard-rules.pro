# ─── Flutter / Dart ───
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ─── Firebase Messaging ───
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ─── Gson / JSON serialization ───
-keepattributes Signature
-keepattributes *Annotation*

# ─── OkHttp (used by some Flutter plugins) ───
-dontwarn okhttp3.**
-dontwarn okio.**

# ─── WebView ───
-keep class android.webkit.** { *; }
-dontwarn android.webkit.**

# ─── Flutter Secure Storage ───
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ─── Keep Parcelable / Serializable ───
-keep class * implements android.os.Parcelable { *; }
-keep class * implements java.io.Serializable { *; }

# ─── Prevent stripping of R8-required annotations ───
-keepattributes RuntimeVisibleAnnotations
