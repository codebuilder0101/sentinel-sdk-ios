# ProGuard consumer rules for Sentinel SDK

# Keep Sentinel models and their serializable properties
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

-keep class com.sentinel.sdk.models.** { *; }
-keepclassmembers class com.sentinel.sdk.models.** {
    *** Companion;
    *** serializer(...);
}

# Keep kotlinx.serialization generated serializer classes
-keepclassmembers class * {
    @kotlinx.serialization.SerialName <fields>;
}

-keep class * implements kotlinx.serialization.KSerializer {
    <init>(...);
}
