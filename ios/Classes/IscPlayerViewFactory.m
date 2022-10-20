//
//  IscPlayerViewFactory.m
//  iscflutterplugin
//
//  Created by windyfat on 2020/5/7.
//

#import "IscPlayerViewFactory.h"
#import "IscPlayerView.h"

@implementation IscPlayerViewFactory{
    NSObject<FlutterBinaryMessenger>*_messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messager{
    self = [super init];
    if (self) {
        _messenger = messager;
    }
    return self;
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    //args 为flutter 传过来的参数
    IscPlayerView * playerView = [[IscPlayerView alloc] initWithWithFrame:frame viewIdentifier:viewId arguments:args binaryMessenger:_messenger];
    return playerView;
}

@end
