//
//  IscPlayerViewFactory.h
//  iscflutterplugin
//
//  Created by windyfat on 2020/5/7.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface IscPlayerViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messager;

@end

NS_ASSUME_NONNULL_END
