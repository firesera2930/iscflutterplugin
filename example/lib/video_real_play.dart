import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iscflutterplugin/iscflutterplugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

///预览
class VideoRealPlayPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _VideoRealPlayPageState();
  }
}

class _VideoRealPlayPageState extends State<VideoRealPlayPage> {
  late Iscflutterplugin _controller;
  late String _previewUrl;

  var cameraCode = '93e888ed7e104174b55842045d804a21';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('实时预览'),
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.black,
            child: IscPlayerWidget(
              onCreated: _onCreated,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                child: Column(
                  children: <Widget>[
                    Container(
                        width: double.infinity,
                        child: ElevatedButton(
                            child: Text("预览"), onPressed: _preview)),
                    Container(
                        width: double.infinity,
                        child: ElevatedButton(
                            child: Text("停止预览"), onPressed: _stop)),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                          child: Text("码流平滑切换(仅支持Android)"),
                          onPressed: _changeStream),
                    ),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                          child: Text("抓拍(需存储权限)"), onPressed: _capture),
                    ),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                          child: Text(
                              _isRecording ? "结束录像(需存储权限)" : "开始录像(需存储权限)"),
                          onPressed: _record),
                    ),
                    Container(
                        width: double.infinity,
                        child: ElevatedButton(
                            child: Text("云台"), onPressed: _ptzs)),
                    Container(
                      width: double.infinity,
                      child:
                          ElevatedButton(child: Text("语音对讲"), onPressed: _talk),
                    ),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                          child: Text("获取版本号"), onPressed: _getVersion),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  ///创建成功回调
  void _onCreated(controller) {
    _controller = controller;
  }

  ///停止播放
  void _stop() {
    _controller.stopPlay();
  }

  ///切换码流
  void _changeStream() async {
    var ret = await _controller.changeStream(_previewUrl);
    print('码流切换 : $ret');
  }

  ///云台控制
  void _ptzs() async {
    //开始云台控制
    var ret = await IscApi.ptzControl(cameraCode, 0, 'ZOOM_OUT');
    print('开始云台控制 : $ret');
    sleep(Duration(milliseconds: 100));
    //停止云台控制
    var ret1 = await IscApi.ptzControl(cameraCode, 1, 'ZOOM_OUT');
    print('停止云台控制 : $ret1');
  }

  var _isRecording = false;

  ///录像
  void _record() async {
    String path = '';

    if (defaultTargetPlatform == TargetPlatform.android) {
      //申请权限
      _requestPermission();
      // //图片保存路径
      path =
          '${(await getExternalStorageDirectory())?.path}/${DateTime.now().toString()}.mp4';
    }
    print('path = $path');

    if (_isRecording) {
      var ret = await _controller.stopRecord();
      if (ret['ret']) {
        _isRecording = false;
      }
      print('结束录像 : $ret');
    } else {
      var ret = await _controller.startRecord(path);
      if (ret['ret']) {
        _isRecording = true;
      }
      print('开始录像 : $ret');
    }
    setState(() {});
  }

  ///抓拍
  void _capture() async {
    String path = '';
    //抓拍
    if (defaultTargetPlatform == TargetPlatform.android) {
      //申请权限
      _requestPermission();
      //图片保存路径
      path =
          '${(await getExternalStorageDirectory())?.path}/${DateTime.now().toString()}.jpg';
    }
    var ret = await _controller.capturePicture(path);
    print('path = $path');
    print('抓拍 : $ret');
  }

  ///预览
  void _preview() async {
    //获取预览地址
    Map ret = await IscApi.getPreviewURL(
      cameraIndexCode: cameraCode,
      version: 1,
      isHttps: true,
    );
    _previewUrl = ret['data']['url'];
    print('预览地址 = $_previewUrl');
    //设置播放器状态回调
    _controller.setStatusCallback((status, type) {
      if (type == 'STATUS_PLAYER') {
        print('播放器状态 = ${_controller.getStatusMessage(status)}');
      } else if (type == 'STATUS_TALK') {
        print('语音对讲状态 = ${_controller.getStatusMessage(status)}');
      }
    });
    //开始预览
    _controller.startRealPlay(_previewUrl);
  }

  ///申请权限
  void _requestPermission() async {
    if (await Permission.storage.request().isGranted) {
      print('已授权');
    }
  }

  ///语音对讲
  void _talk() async {
    //获取语音对讲地址
    Map ret = await IscApi.getTalkUrl(
      cameraIndexCode: cameraCode,
      version: 1,
    );
    final _talkUrl = ret['data']['url'];
    print('语音对讲地址 = $_talkUrl');
  }

  void _getVersion() async {
    print('当前SDK版本为:${await _controller.getVersion()}');
  }
}
