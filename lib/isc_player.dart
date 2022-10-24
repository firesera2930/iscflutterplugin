part of isc;



///海康isc播放器widget,
///可单独使用,直接将预览地址传入即可
///控件大小按照父控件计算
class IscPlayerWidget extends StatefulWidget {
  final IscPlayerCreatedCallback? onCreated;

  IscPlayerWidget({
    Key? key,
    @required this.onCreated,
  });

  @override
  State<StatefulWidget> createState() {
    return _IscPlayerWidgetState();
  }
}

class _IscPlayerWidgetState extends State<IscPlayerWidget>
    with WidgetsBindingObserver {
  Iscflutterplugin? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {

      ///安卓的onPause,IOS的viewDidLoad
      case AppLifecycleState.inactive:
        break;

      ///安卓的onStop,IOS的viewWillDisappear,viewDidDisappear
      case AppLifecycleState.paused:
        _controller?.onPause();
        break;

      ///安卓的onResume,IOS的viewWillAppear,viewDidAppear
      case AppLifecycleState.resumed:
        _controller?.onResume();
        break;

      ///安卓的onDestroy,IOS的dealloc
      case AppLifecycleState.detached:
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return _createNativeView();
  }

  ///创建nativeview
  Widget _createNativeView() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'plugin:isc_player',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'plugin:isc_player',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return Text("当前插件仅支持Android和iOS");
    }
  }

  ///平台view创建后的回调
  Future<void> _onPlatformViewCreated(id) async {
    _controller = Iscflutterplugin.init(id);
    widget.onCreated!(_controller);
  }
}
