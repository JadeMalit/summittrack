## Gson rules required by flutter_local_notifications 17.2.4.
# Gson uses generic type information stored in class-file signatures.
-keepattributes Signature

# Preserve annotations used by Gson adapters and serialized fields.
-keepattributes *Annotation*

-dontwarn sun.misc.**

# Keep adapter interfaces used through reflection.
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Preserve fields selected by @SerializedName while still allowing obfuscation.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain TypeToken generic signatures on R8 3.0 and newer.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
