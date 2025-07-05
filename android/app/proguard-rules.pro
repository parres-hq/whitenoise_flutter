# Flutter Rust Bridge
-keep class com.github.dart_lang.jni.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes in the rust package
-keep class com.example.whitenoise.** { *; }

# Prevent stripping of Rust library native methods
-keep class * {
    @com.github.dart_lang.jni.* <methods>;
}

# Keep JNI classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod 