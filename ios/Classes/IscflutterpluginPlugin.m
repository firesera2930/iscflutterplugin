#import "IscflutterpluginPlugin.h"
#import "IscPlayerViewFactory.h"

@implementation IscflutterpluginPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
//  FlutterMethodChannel* channel = [FlutterMethodChannel
//      methodChannelWithName:@"iscflutterplugin"
//            binaryMessenger:[registrar messenger]];
//  IscflutterpluginPlugin* instance = [[IscflutterpluginPlugin alloc] init];
//  [registrar addMethodCallDelegate:instance channel:channel];
    
    [registrar registerViewFactory:[[IscPlayerViewFactory alloc] initWithMessenger:registrar.messenger] withId:@"plugin:isc_player"];
    
}

@end
