import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

///海康isc平台,认证配置,如果需要自行和海康的isc平台交互,
///比如获取预览地址,云台控制等等,就需要配置该项
class ArtemisConfig {
  static String? host;
  static String? appKey;
  static String? appSecret;

  ///根据路径生成认证header
  ///
  ///海康isc平台采用AK/SK认证,需要生成生成必要的秘钥放到header中
  ///
  /// 'url' 接口请求地址 比如[previewURLs],[controlling]..等
  ///
  static Map<String, dynamic> createHeaders(String url) {
    assert(ArtemisConfig.host != null);
    assert(ArtemisConfig.appKey != null);
    assert(ArtemisConfig.appSecret != null);

    var httpHeaders = "POST\n*/*\napplication/json\n";
    var customHeaders = "x-ca-key:${ArtemisConfig.appKey}\n";
    var msg = httpHeaders + customHeaders + url;
    var secretBytes = utf8.encode(ArtemisConfig.appSecret!);
    var messageBytes = utf8.encode(msg);
    var digest = Hmac(sha256, secretBytes).convert(messageBytes);
    var signature = base64Encode(digest.bytes);

    Map<String, dynamic> headers = Map();
    headers["Accept"] = "*/*";
    headers["Content-Type"] = "application/json";
    headers["X-Ca-Key"] = ArtemisConfig.appKey;
    headers["X-Ca-Signature"] = signature;
    headers["X-Ca-Signature-Headers"] = "x-ca-key";
    return headers;
  }
}

const String ARTEMIS_PATH = "/artemis";

///预览url地址
const String previewURLsV1 = "$ARTEMIS_PATH/api/video/v1/cameras/previewURLs";

///预览url地址,isc平台1.4以上版本
const String previewURLsV2 = "$ARTEMIS_PATH/api/video/v2/cameras/previewURLs";

///回放url地址
const String playbackURLsV1 = "$ARTEMIS_PATH/api/video/v1/cameras/playbackURLs";

///回放url地址,isc平台1.4以上版本
const String playbackURLsV2 = "$ARTEMIS_PATH/api/video/v2/cameras/playbackURLs";

///云台控制
const String controllingV1 = "$ARTEMIS_PATH/api/video/v1/ptzs/controlling";

///语音对讲url
const String talkURLsV1 = "$ARTEMIS_PATH/api/video/v1/cameras/talkURLs";

///语音对讲url地址,isc平台1.4以上版本
const String talkURLsV2 = "$ARTEMIS_PATH/api/video/v2/cameras/talkURLs";

///isc平台网络请求辅助类
class IscApi {
  ///获取预览地址
  ///
  /// 'cameraIndexCode' 监控点唯一标识
  ///
  /// 'streamType' 码流类型,0主码流,1子码流
  ///
  /// version 1表示isc1.3版本及以前,2表示isc1.4版本及以后
  ///
  /// transmode 协议类型( 0-udp，1-tcp),默认为tcp，在protocol设置为rtsp或者rtmp时有效
  ///
  /// isHttps 是否使用https请求,需要根据实际情况选择参数,
  ///
  /// protocol 取流协议（应用层协议），
  /// “hik”:HIK私有协议，使用视频SDK进行播放时，传入此类型；
  /// “rtsp”:RTSP协议；
  /// “rtmp”:RTMP协议；
  /// “hls”:HLS协议（HLS协议只支持海康SDK协议、EHOME协议、ONVIF协议接入的设备；只支持H264视频编码和AAC音频编码）。
  /// 参数不填，默认为HIK协议
  ///
  /// isHttps是否为https请求
  static Future<dynamic> getPreviewURL({
    required String cameraIndexCode,
    int streamType = 1,
    int transmode = 1,
    String protocol = '',
    int version = 2,
    bool isHttps = false,
  }) async {
    if (cameraIndexCode == null || cameraIndexCode.isEmpty) {
      return;
    }
    //根据版本切换地址,isc1.4之后用v2版本
    var previewURLs = previewURLsV2;
    if (version == 1) {
      previewURLs = previewURLsV1;
    }
    var headers = ArtemisConfig.createHeaders(previewURLs);

    ///根据实际服务器情况选用http或https
    String url = 'http://${ArtemisConfig.host}$previewURLs';
    if (isHttps) {
      url = 'https://${ArtemisConfig.host}$previewURLs';
    }

    Map body = Map();
    body['cameraIndexCode'] = cameraIndexCode;
    body['streamType'] = streamType;
    body['transmode'] = transmode;
    if (protocol.isNotEmpty) {
      body['protocol'] = protocol;
    }

    Dio dio = Dio();
    //增加日志
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    // 忽略SSL认证
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
    };
    dio.options.headers.addAll(headers);
    Response response = await dio.post(url, data: body);
    return response.data;
  }

  /// 获取回放地址url
  ///
  /// cameraIndexCode：摄像头标识
  ///
  /// beginTime：开始时间(ISO8601格式：yyyy-MM-dd’T’HH:mm:ss.SSSXXX，例如北京时间：2017-06-14T00:00:00.000+08:00)
  ///
  /// endTime：结束时间(ISO8601格式：yyyy-MM-dd’T’HH:mm:ss.SSSXXX，例如北京时间：2017-06-15T00:00:00.000+08:00)
  ///
  /// recordLocation: 存储类型 0,中心存储  1,设备存储
  ///
  /// version：1是海康SDK1.3版本，默认是2海康SDK1.4版本
  ///
  /// isHttps是否为https请求
  static Future<dynamic> getPlaybackUrl({
    String? cameraIndexCode,
    String? beginTime,
    String? endTime,
    int recordLocation = 0,
    int version = 2,
    bool isHttps = false,
  }) async {
    if (cameraIndexCode == null || cameraIndexCode.isEmpty) {
      return;
    }

    ///根据版本切换地址,isc1.4之后用v2版本
    var playbackURLs = playbackURLsV2;
    if (version == 1) {
      playbackURLs = playbackURLsV1;
    }
    var headers = ArtemisConfig.createHeaders(playbackURLs);

    ///根据实际服务器情况选用http或https

    String url = 'http://${ArtemisConfig.host}$playbackURLs';
    if (isHttps) {
      url = 'https://${ArtemisConfig.host}$playbackURLs';
    }

    Map body = Map();
    body['cameraIndexCode'] = cameraIndexCode;
    body['beginTime'] = beginTime;
    body['endTime'] = endTime;
    body['recordLocation'] = recordLocation;

    Dio dio = Dio();
    dio.interceptors.add(LogInterceptor(requestBody: true));

    // 忽略SSL认证
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
    };
    dio.options.headers.addAll(headers);
    Response response = await dio.post(url, data: body);
    return response.data;
  }

  /// 云台控制
  ///
  /// 'cameraIndexCode' 监控点唯一标识
  ///
  /// 'action' 行为:0开始,1停止
  ///
  /// 'command' 命令:不区分大小写
  ///
  /// 说明：
  ///
  /// LEFT 左转
  ///
  /// RIGHT右转
  ///
  /// UP 上转
  ///
  /// DOWN 下转
  ///
  /// ZOOM_IN 焦距变大
  ///
  /// ZOOM_OUT 焦距变小
  ///
  /// LEFT_UP 左上
  ///
  /// LEFT_DOWN 左下
  ///
  /// RIGHT_UP 右上
  ///
  /// RIGHT_DOWN 右下
  ///
  /// FOCUS_NEAR 焦点前移
  ///
  /// FOCUS_FAR 焦点后移
  ///
  /// IRIS_ENLARGE 光圈扩大
  ///
  /// IRIS_REDUCE 光圈缩小
  ///
  /// 以下命令presetIndex不可为空
  ///
  /// GOTO_PRESET到预置点
  ///
  /// isHttps是否为https请求
  static Future<dynamic> ptzControl(
    String cameraIndexCode,
    int action,
    String command, {
    bool isHttps = false,
  }) async {
    if (cameraIndexCode == null || cameraIndexCode.isEmpty) {
      return;
    }
    var headers = ArtemisConfig.createHeaders(controllingV1);

    ///根据实际服务器情况选用http或https
    String url = 'http://${ArtemisConfig.host}$controllingV1';
    if (isHttps) {
      url = 'https://${ArtemisConfig.host}$controllingV1';
    }

    Map body = Map();
    body['cameraIndexCode'] = cameraIndexCode;
    body['action'] = action;
    body['command'] = command;

    Dio dio = Dio();
    dio.interceptors.add(LogInterceptor(requestBody: true));

    // 忽略SSL认证
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
    };
    dio.options.headers.addAll(headers);
    Response response = await dio.post(url, data: body);
    return response.data;
  }

  ///语音对讲,一般直接使用预览url即可,无需单独请求
  /// 'cameraIndexCode' 监控点唯一标识
  ///
  /// version 1表示isc1.3版本及以前,2表示isc1.4版本及以后
  ///
  /// transmode 协议类型( 0-udp，1-tcp),默认为tcp，
  ///
  /// isHttps 是否使用https请求,需要根据实际情况选择参数,
  ///
  /// isHttps是否为https请求
  static Future<dynamic> getTalkUrl({
    required String cameraIndexCode,
    int transmode = 1,
    int version = 2,
    bool isHttps = false,
  }) async {
    if (cameraIndexCode == null || cameraIndexCode.isEmpty) {
      return;
    }

    ///根据版本切换地址,isc1.4之后用v2版本
    var talkURLs = talkURLsV2;
    if (version == 1) {
      talkURLs = talkURLsV1;
    }
    var headers = ArtemisConfig.createHeaders(talkURLs);

    ///根据实际服务器情况选用http或https
    String url = 'http://${ArtemisConfig.host}$talkURLs';
    if (isHttps) {
      url = 'https://${ArtemisConfig.host}$talkURLs';
    }

    Map body = Map();
    body['cameraIndexCode'] = cameraIndexCode;
    body['transmode'] = transmode;

    Dio dio = Dio();
    dio.interceptors.add(LogInterceptor(requestBody: true));

    // 忽略SSL认证
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
    };
    dio.options.headers.addAll(headers);
    Response response = await dio.post(url, data: body);
    return response.data;
  }
}
