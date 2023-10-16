library isc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'isc_http.dart';
part 'isc_player.dart';

///闲置状态
const IDLE = 0;

///加载中状态
const int LOADING = 1;

///播放成功
const int SUCCESS = 2;

///暂时停止播放
const int STOPPING = 3;

///播放失败
const int FAILED = 4;

///播放过程中出现异常
const int EXCEPTION = 5;

///回放结束
const int FINISH = 6;

///播放器创建成功的回调
typedef void IscPlayerCreatedCallback(Iscflutterplugin? controller);

///播放器/语音对讲状态监听回调
///status 状态 回调状态
///
///statusType 回调类型
///STATUS_PLAYER 播放器回调
///STATUS_TALK 语音对讲回调
typedef void IscPlayerStatusCallback(int status, String statusType);

///播放器控制器
///如需扩展,参考海康isc平台 sdk播放器文档
class Iscflutterplugin {
  late MethodChannel _channel;

  Iscflutterplugin.init(int id) {
    _channel = MethodChannel('plugin_isc_player_$id');
  }

  ///获取当前海康SDK版本号
  Future<dynamic> getVersion() async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod('getVersion');
    }
  }

  ///开始预览
  ///预览开始前,需要设置播放器状态回调[setStatusCallback]
  ///liveRtspUrl 预览地址
  Future<dynamic> startRealPlay(String liveRtspUrl) async {
    return await _channel.invokeMethod('startRealPlay', <String, dynamic>{
      "url": liveRtspUrl,
    });
  }

  ///码流平滑切换
  ///需注意该方法仅在Android平台上生效,IOS不支持
  ///必须预览成功后才可调用
  ///liveRtspUrl 预览地址
  Future<dynamic> changeStream(String liveRtspUrl) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _channel.invokeMethod('changeStream', <String, dynamic>{
        "url": liveRtspUrl,
      });
    }
  }

  ///开始回放
  ///回放开始前,需要设置播放器状态回调[setStatusCallback]
  ///startTime 开始时间 格式为 yyyy-MMdd'T'HH:mm:ss.SSSZ
  ///stopTime 结束时间 格式为 yyyy-MMdd'T'HH:mm:ss.SSSZ
  Future<dynamic> startPlayback(
    String liveRtspUrl,
    String startTime,
    String stopTime,
  ) async {
    //ios设备需要将时间转为时间戳
    // if (defaultTargetPlatform == TargetPlatform.iOS) {
    //   DateTime start = DateTime.parse(startTime);
    //   DateTime end = DateTime.parse(stopTime);
    //   startTime = (start.millisecondsSinceEpoch / 1000).toString();
    //   stopTime = (end.millisecondsSinceEpoch / 1000).toString();
    // }
    return await _channel.invokeMethod('startPlayback', <String, dynamic>{
      "url": liveRtspUrl,
      "startTime": startTime,
      "stopTime": stopTime,
    });
  }

  ///按绝对时间回放定位
  ///seekTime 定位时间  格式为 yyyy-MMdd'T'HH:mm:ss.SSSZ
  Future<dynamic> seekAbsPlayback(String seekTime) async {
    //ios设备需要将时间转为时间戳
    // if (defaultTargetPlatform == TargetPlatform.iOS) {
    //   DateTime seek = DateTime.parse(seekTime);
    //   seekTime = (seek.millisecondsSinceEpoch / 1000).toString();
    // }
    return await _channel.invokeMethod('seekAbsPlayback', <String, dynamic>{
      "seekTime": seekTime,
    });
  }

  ///查询当前播放时间戳接口
  Future<dynamic> getOSDTime() async {
    Map? ret = await _channel.invokeMethod('getOSDTime');

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String time = ret!['ret'];
      if ("-1" != time) {
        DateTime res = DateTime.fromMillisecondsSinceEpoch(int.parse(time + '000'));
        return res;
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      int time = ret!['ret'];
      if (time > 0) {
        return DateTime.fromMillisecondsSinceEpoch(time);
      }
    }
    return;
  }

  ///暂停回放
  Future<dynamic> pause() async {
    return await _channel.invokeMethod('pause');
  }

  ///恢复回放
  Future<dynamic> resume() async {
    return await _channel.invokeMethod('resume');
  }

  ///停止播放,包括预览和回放
  Future<dynamic> stopPlay() async {
    return await _channel.invokeMethod('stopPlay');
  }

  ///开启语音对讲
  ///语音开始前,需要设置播放器状态回调[setStatusCallback]
  ///liveRtspUrl 预览地址
  Future<dynamic> startVoiceTalk(String liveRtspUrl) async {
    return await _channel.invokeMethod('startVoiceTalk', <String, dynamic>{
      "url": liveRtspUrl,
    });
  }

  ///关闭语音对讲
  Future<dynamic> stopVoiceTalk() async {
    return await _channel.invokeMethod('stopVoiceTalk');
  }

  ///预览/回放 抓图
  ///必须预览/回放成功后才可调用
  ///bitmapPath 图片本地存储路径
  Future<dynamic> capturePicture(String bitmapPath) async {
    return await _channel.invokeMethod('capturePicture', <String, dynamic>{
      "path": bitmapPath,
    });
  }

  ///预览/回放 抓图获取图片
  ///必须预览/回放成功后才可调用
  ///bitmapPath 图片本地存储路径
  Future<dynamic> screenshot() async {
    return await _channel.invokeMethod('screenshot');
  }

  ///开启本地录像
  ///必须预览/回放成功后才可调用
  ///mediaFilePath 视频本地存储路径
  Future<dynamic> startRecord(String mediaFilePath) async {
    return await _channel.invokeMethod('startRecord', <String, dynamic>{
      "path": mediaFilePath,
    });
  }

  ///关闭本地录像
  ///必须预览/回放成功后才可调用
  Future<dynamic> stopRecord() async {
    return await _channel.invokeMethod('stopRecord');
  }

  ///声音控制
  ///必须预览/回放成功后才可调用
  Future<dynamic> enableSound(bool enable) async {
    return await _channel.invokeMethod('enableSound', <String, dynamic>{
      "enable": enable,
    });
  }

  ///生命周期回调
  ///注意:APP前后台切换时 华为手机 上不会回调生命周期方法，例如：华为P20，可以在这里手动调用
  Future<dynamic> onResume() async {
    return await _channel.invokeMethod('onResume');
  }

  ///生命周期回调
  ///注意:APP前后台切换时 华为手机 上不会回调生命周期方法，例如：华为P20，可以在这里手动调用
  Future<dynamic> onPause() async {
    return await _channel.invokeMethod('onPause');
  }

  ///设置播放器/语音对讲回调监听
  ///该回调全局只需设置一次即可
  void setStatusCallback(IscPlayerStatusCallback callback) {
    _channel.setMethodCallHandler((methodCall) async {
      Map? arg = methodCall.arguments;
      switch (methodCall.method) {
        case "onPlayerStatusCallback":
          int status = arg!['status'];
          callback(status, 'STATUS_PLAYER');
          break;
        case "onTalkStatusCallback":
          int status = arg!['status'];
          callback(status, 'STATUS_TALK');
          break;
        default:
      }
    });
  }

  ///转化错误码信息
  String? getStatusMessage(int status) {
    String? msg;
    switch (status) {
      case IDLE:
        msg = "闲置状态";
        break;
      case LOADING:
        msg = "加载中状态";
        break;
      case SUCCESS:
        msg = "播放成功";
        break;
      case STOPPING:
        msg = "暂时停止播放";
        break;
      case FAILED:
        msg = "播放失败";
        break;
      case EXCEPTION:
        msg = "播放过程中出现异常";
        break;
      case FINISH:
        msg = "回放结束";
        break;
    }
    return msg;
  }
}
