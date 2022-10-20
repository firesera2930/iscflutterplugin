package com.king.iscflutterplugin;


import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.PluginRegistry;

/**
 * IscflutterpluginPlugin
 */
public class IscflutterpluginPlugin implements FlutterPlugin {

    /**
     * 新版插件加载
     *
     * @param flutterPluginBinding
     */
    @Override
    public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
        //播放器注册
        flutterPluginBinding.getPlatformViewRegistry().registerViewFactory("plugin:isc_player", new IscPlayerViewFactory(flutterPluginBinding.getBinaryMessenger()));
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
    }

    /**
     * 旧版插件加载
     *
     * @param registrar
     */
    public static void registerWith(PluginRegistry.Registrar registrar) {
        //播放器注册
        registrar.platformViewRegistry().registerViewFactory("plugin:isc_player", new IscPlayerViewFactory(registrar.messenger()));
    }
}
