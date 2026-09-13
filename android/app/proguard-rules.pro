# ========================================================
# MediRemind ProGuard / R8 Shrinking & Obfuscation Rules
# ========================================================

# Flutter Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Kotlin Reflection & Metadata
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Firebase (Auth, Core, Firestore)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }

# SQLite (sqflite)
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Flutter Local Notifications & Alarm Receivers
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Service

# Desugaring Java 8+ APIs
-dontwarn java.time.**
-dontwarn java.lang.invoke.**
