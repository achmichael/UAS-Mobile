# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Flutter embedding
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Google Play Core (for Flutter)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep plugin classes
-keep class com.example.app_limiter_plugin.** { *; }
-keep class com.example.app_limiter.** { *; }

# Keep OverlayHandler and related classes
-keep class com.example.app_limiter_plugin.OverlayHandler { *; }
-keep class com.example.app_limiter_plugin.OverlayHandler$* { *; }
-keep class com.example.app_limiter_plugin.UsageStatsHandler { *; }
-keep class com.example.app_limiter_plugin.AppLimiterPlugin { *; }

# Keep method channels
-keepclassmembers class * {
    @io.flutter.embedding.engine.plugins.activity.ActivityAware *;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep background service
-keep class id.flutter.flutter_background_service.** { *; }

# Keep installed apps plugin
-keep class io.flutter.plugins.installedapps.** { *; }

# Keep app usage plugin  
-keep class io.github.itzmeanjan.app_usage.** { *; }

# Keep block app plugin
-keep class com.noorqidam.block_app.** { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Gson specific classes
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Keep data classes
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent stripping of inner classes in LayoutParams
-keepclassmembers class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

-keepclassmembers class * extends android.view.ViewGroup {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep WindowManager.LayoutParams
-keep class android.view.WindowManager$LayoutParams { *; }

# Keep FrameLayout
-keep class android.widget.FrameLayout { *; }
-keep class android.widget.FrameLayout$LayoutParams { *; }

# Keep TextView and Button
-keep class android.widget.TextView { *; }
-keep class android.widget.Button { *; }

# Prevent obfuscation of custom views
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}
