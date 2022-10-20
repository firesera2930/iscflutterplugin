import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iscflutterplugin/isc_http.dart';
import 'package:iscflutterplugin/isc_player.dart';
import 'package:iscflutterplugin/iscflutterplugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

///回放
class VideoPlayBackPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _VideoPlayBackPageState();
  }
}

class _VideoPlayBackPageState extends State<VideoPlayBackPage> {
  late Iscflutterplugin _controller;
  late String _previewUrl;
  var cameraCode = 'xxx';

  void _getOSDTime() async {
    var time = await _controller.getOSDTime();
    print('time = $time');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频回放'),
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
                      child:
                          ElevatedButton(child: Text("回放"), onPressed: _playBack),
                    ),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                          child: Text("指定回放开始时间位置"), onPressed: _seekTime),
                    ),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(child: Text("停止"), onPressed: _stop),
                    ),
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
                          child: Text('查询当前播放时间戳接口'), onPressed: _getOSDTime),
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

  /// 回放
  void _playBack() async {
    String beginTime = '2022-09-28T00:00:00.000+08:00';
    String endTime = '2022-09-28T23:59:59.000+08:00';

    Map ret = await IscApi.getPlaybackUrl(
        cameraIndexCode: cameraCode,
        beginTime: beginTime,
        endTime: endTime,
        recordLocation: 1,
        isHttps: true,
        version: 1);
    String url = ret['data']['url'];
    print(ret.toString());

    _controller.startPlayback(url, beginTime, endTime);
  }

  ///指定回放开始位置
  void _seekTime() async {
    String seekTime = '2022-09-28T14:00:00.000+08:00';
    _controller.seekAbsPlayback(seekTime);
  }

  ///申请权限
  void _requestPermission() async {
    if (await Permission.storage.request().isGranted) {
      print('已授权');
    }
  }
}
