package com.king.iscflutterplugin;

import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

/**
 * @author ljb
 * @des
 * @date 2020/4/27
 */
public class IscPlayerViewFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;

    public IscPlayerViewFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        return new IscPlayerView(context, viewId, args, this.messenger);
    }
}
