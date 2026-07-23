# =====================================================================
# flutter_checkin_sdk consumer ProGuard/R8 rules
# =====================================================================
# These rules are automatically applied to any app that consumes this
# plugin and enables code shrinking (minify). They fix a crash that
# happens ONLY in release builds with R8 full mode
# (android.enableR8.fullMode=true):
#
#   java.lang.Class cannot be cast to java.lang.reflect.ParameterizedType
#
# In full mode R8 strips the generic `Signature` attribute from every
# class that is not explicitly kept. The GetID (Checkin.com) SDK relies
# on generic-type reflection (Retrofit/Gson/Moshi) to (de)serialize its
# network models, so the stripped signatures make it fail at runtime.

# --- Keep attributes required for reflective (de)serialization ---
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations,AnnotationDefault
-keepattributes Exceptions

# --- GetID (Checkin.com) SDK + models (reflection based) ---
-keep class com.sdk.getidlib.** { *; }
-keep interface com.sdk.getidlib.** { *; }
-keep enum com.sdk.getidlib.** { *; }
-keep class ee.getid.** { *; }
-keep interface ee.getid.** { *; }
-keep enum ee.getid.** { *; }
-dontwarn com.sdk.getidlib.**
-dontwarn ee.getid.**

# --- This plugin bridge ---
-keep class com.checkin.flutter_checkin_sdk.** { *; }

# --- Gson (full-mode required rules) ---
-keep,allowobfuscation,allowshrinking,allowoptimization class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking,allowoptimization class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# --- Retrofit (full-mode required rules) ---
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response
-if interface * { @retrofit2.http.* public *** *(...); }
-keep,allowoptimization,allowshrinking,allowobfuscation class <1>
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

# --- Moshi (full-mode required rule) ---
-keep,allowobfuscation,allowshrinking class com.squareup.moshi.JsonAdapter
-keep class com.squareup.moshi.** { *; }
-keepclasseswithmembers class * {
    @com.squareup.moshi.* <methods>;
}
-dontwarn com.squareup.moshi.**

# --- OkHttp / Okio (transitive deps of the SDK) ---
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**

# --- Kotlin metadata & coroutines ---
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings { <fields>; }

# --- Optional transitive deps referenced by the SDK (Apache Tika / StAX) ---
-dontwarn javax.xml.stream.**
-dontwarn org.apache.tika.**
