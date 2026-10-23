# Camera Pigeon - keep ALL generated classes and their members
-keep class dev.flutter.pigeon.** { *; }
-keepclassmembers class dev.flutter.pigeon.** { *; }

# Camera plugin native classes
-keep class io.flutter.plugins.camera.** { *; }
-keepclassmembers class io.flutter.plugins.camera.** { *; }

# Prevent stripping of interface implementations used by Pigeon
-keep interface dev.flutter.pigeon.camera_android.** { *; }
-keepclasseswithmembers class * {
    @dev.flutter.pigeon.* <methods>;
}
# ═══════════════════════════════════════════════════════════════
# TensorFlow Lite - GPU Delegate (CRITICAL - fixes R8 error)
# ═══════════════════════════════════════════════════════════════
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options$GpuBackend { *; }
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.**

# ═══════════════════════════════════════════════════════════════
# Facebook Audience Network SDK
# infer-annotations are compileOnly deps, not needed at runtime
# ═══════════════════════════════════════════════════════════════
-dontwarn com.facebook.infer.annotation.**