# Proguard rules for Sentinel SDK library build
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

-keep class com.sentinel.sdk.SentinelSDK { *; }
-keep class com.sentinel.sdk.SentinelSDK$* { *; }
-keep class com.sentinel.sdk.models.** { *; }
-keep class com.sentinel.sdk.collectors.** { *; }
-keep class com.sentinel.sdk.security.** { *; }
