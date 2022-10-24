import 'package:flutter/material.dart';
import 'package:iscflutterplugin/iscflutterplugin.dart';
import 'package:iscflutterplugin_example/video_play_back.dart';
import 'package:iscflutterplugin_example/video_real_play.dart';

void main() => runApp(MaterialApp(
      home: HomePage(),
    ));

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    //初始化配置
    ArtemisConfig.host = "222.77.181.13:35443";
    ArtemisConfig.appKey = "29352046";
    ArtemisConfig.appSecret = "vVJtyMhN4O8PxSE6U7I7";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '海康isc播放器插件,支持android/ios',
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        return VideoRealPlayPage();
                      },
                    ),
                  );
                },
                child: Text('实时预览'),
              ),
            ),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        return VideoPlayBackPage();
                      },
                    ),
                  );
                },
                child: Text('视频回放'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
