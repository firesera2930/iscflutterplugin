#flutter相关不混淆
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# isc插件库混淆配置
-keep class com.king.**{*;}
-keep interface com.king.**{*;}

-dontwarn android.support.annotation.Keep
# 保留类内部使用@keep注解的成员变量
-keep @android.support.annotation.Keep class **{
@android.support.annotation.Keep <fields>;
}
# natvie 方法不混淆
-keepclasseswithmembernames class * {
native <methods>;
}
# 海康威视视频取流播放相关库的混淆配置
-keep class org.MediaPlayer.PlayM4.** {*;}
-keep class com.hikvision.netsdk.** {*;}
-keep class com.hikvision.audio.** {*;}
-keep class hik.common.isms.hpsclient.** {*;}
-keep class com.hikvision.open.hikvideoplayer.** {*;}