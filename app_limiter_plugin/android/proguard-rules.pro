# Keep all plugin classes and their members
-keep class com.example.app_limiter_plugin.** { *; }
-keepclassmembers class com.example.app_limiter_plugin.** { *; }

# Keep OverlayHandler and its inner classes - CRITICAL for release builds
-keep class com.example.app_limiter_plugin.OverlayHandler { *; }
-keep class com.example.app_limiter_plugin.OverlayHandler$* { *; }
-keepclassmembers class com.example.app_limiter_plugin.OverlayHandler { *; }
-keepclassmembers class com.example.app_limiter_plugin.OverlayHandler$* { *; }

# Keep FocusInterceptLayout inner class
-keep class com.example.app_limiter_plugin.OverlayHandler$FocusInterceptLayout { *; }
-keepclassmembers class com.example.app_limiter_plugin.OverlayHandler$FocusInterceptLayout {
    <init>(android.content.Context);
    public *;
}

# Keep UsageStatsHandler
-keep class com.example.app_limiter_plugin.UsageStatsHandler { *; }
-keepclassmembers class com.example.app_limiter_plugin.UsageStatsHandler { *; }

# Keep AppLimiterPlugin
-keep class com.example.app_limiter_plugin.AppLimiterPlugin { *; }
-keepclassmembers class com.example.app_limiter_plugin.AppLimiterPlugin { *; }

# Keep method channel handlers - CRITICAL
-keepclassmembers class com.example.app_limiter_plugin.** {
    public void handleMethodCall(io.flutter.plugin.common.MethodCall, io.flutter.plugin.common.MethodChannel$Result);
    public void onAttachedToEngine(io.flutter.embedding.engine.plugins.FlutterPlugin$FlutterPluginBinding);
    public void onDetachedFromEngine(io.flutter.embedding.engine.plugins.FlutterPlugin$FlutterPluginBinding);
    public void onAttachedToActivity(io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding);
    public void onDetachedFromActivity();
    public void onDetachedFromActivityForConfigChanges();
    public void onReattachedToActivityForConfigChanges(io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding);
}

# Keep FlutterPlugin interface implementations
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin {
    public <init>();
    public void onAttachedToEngine(**);
    public void onDetachedFromEngine(**);
}

# Keep ActivityAware interface implementations
-keep class * implements io.flutter.embedding.engine.plugins.activity.ActivityAware {
    public <init>();
    public void onAttachedToActivity(**);
    public void onDetachedFromActivity();
    public void onDetachedFromActivityForConfigChanges();
    public void onReattachedToActivityForConfigChanges(**);
}

# Keep all View subclasses used in overlay
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(...);
}

# Keep WindowManager and related classes
-keep class android.view.WindowManager { *; }
-keep class android.view.WindowManager$* { *; }
-keep class android.view.WindowManager$LayoutParams { *; }

# Keep WeakReference
-keep class java.lang.ref.WeakReference { *; }

# Prevent removal of used methods
-keepclassmembers class com.example.app_limiter_plugin.OverlayHandler {
    void showCustomOverlay(java.lang.String);
    void hideOverlay();
    boolean hasOverlayPermission();
    boolean requestOverlayPermission();
    void updateActivity(android.app.Activity);
    void handleActivityResult(int, int, android.content.Intent);
}

