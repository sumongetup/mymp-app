# Flutter ships its own rules; these keep the plugins' entry points, which
# R8 cannot see are called from the engine.
-keep class io.flutter.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn io.flutter.embedding.**
