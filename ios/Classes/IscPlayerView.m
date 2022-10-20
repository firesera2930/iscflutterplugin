//
//  IscPlayerView.m
//  iscflutterplugin
//
//  Created by windyfat on 2020/5/7.
//

#import "IscPlayerView.h"
#import "WFVideoHeader.h"

#import <hatomplayer_core/HatomplayerCore.h>

@import Photos;

@interface IscPlayerView ()<HatomPlayerDelegate>

@property(nonatomic, strong)NSString * videoUrl;        // 预览URL
@property(nonatomic, strong)NSString * talkUrl;         // 对讲URL

@property(nonatomic, strong)NSMutableDictionary * playHeaders;
@property(nonatomic, strong)PlayConfig * config;    // 播放器配置
@property(nonatomic, strong)HatomPlayer * player;       // 海康播放组件

@property (nonatomic, assign) BOOL isPlaying;       // 播放状态
@property (nonatomic, assign) BOOL isRecording;     // 录像状态
@property (nonatomic, assign)WFHikVideoPlayType playType;   // 视频播放类型,分为预览和回放
@property (nonatomic, copy) NSString * recordPath;      // 录像保存路径


@property (nonatomic, assign) BOOL isTalkPlaying;       // 语音对讲开启状态
@end

@implementation IscPlayerView{

    // IscPlayerView 创建后的标识
    int64_t _viewId;
    NSNumber * _mPlayerStatus;
    NSNumber * _mTalkStatus;
    // 消息回调
    FlutterMethodChannel* _channel;
    FlutterEventChannel * _eventChannel;
    FlutterEventSink _eventSink;
}

- (instancetype)initWithWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    if ([super init]) {

        NSString* channelName = [NSString stringWithFormat:@"plugin_isc_player_%ld", viewId];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        __weak __typeof__(self) weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall *  call, FlutterResult  result) {
            [weakSelf onMethodCall:call result:result];
        }];

         NSString* eventChannelName = @"event_isc_player";
         _eventChannel = [FlutterEventChannel eventChannelWithName:eventChannelName  binaryMessenger:messenger];
         [_eventChannel setStreamHandler:self];

        HatomPlayerSDK * playerSDK = [[HatomPlayerSDK alloc] init:@"" printLog:NO];

        self.isRecording = NO;
        self.isPlaying = NO;
        self.playType = WF_VIDEO_IDLE;

        _mPlayerStatus = [NSNumber numberWithInt:WF_IDLE];

    }
    return self;
}

- (void)registNotifications {
    // 注册前后台切换通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{

    // 开始预览
    if ([[call method] isEqualToString:@"startRealPlay"]) {
        [self startToPreview:call result:result];
    } if ([[call method] isEqualToString:@"changeStream"]) {        // 码流平滑切换

        result(@{@"ret" : @(NO),
                 @"msg" : @"iOS端暂未实现"
               });

    } if ([[call method] isEqualToString:@"startPlayback"]) {       // 开始回放
        [self startPlayBack:call result:result];
    } if ([[call method] isEqualToString:@"seekAbsPlayback"]) {         // 按绝对时间回放定位
        [self seekPlayBack:call result:result];
    } if ([[call method] isEqualToString:@"getOSDTime"]) {      // 查询当前播放时间戳接口
        long time = [self.player getOSDTime];
        if (!time) {
            time = -1;
        }
        NSString * res = [NSString stringWithFormat:@"%lu", time];
        result(@{@"ret" : res});

    } if ([[call method] isEqualToString:@"pause"]) {       // 暂停回放

        result([self pausePlayBackVideo]);

    } if ([[call method] isEqualToString:@"resume"]) {          // 恢复回放

        result([self resumePlayBackVideo]);

    } if ([[call method] isEqualToString:@"stopPlay"]) {          // 停止播放
        [self stopPreview:call result:result];

    } if ([[call method] isEqualToString:@"startVoiceTalk"]) {          // 开启语音对讲
        [self startVoiceTalk:call result:result];

    } if ([[call method] isEqualToString:@"stopVoiceTalk"]) {          // 关闭语音对讲
        [self stopVoiceTalk:call result:result];

    } if ([[call method] isEqualToString:@"capturePicture"]) {          // 抓图

        result([self capturePicture]);

    } if ([[call method] isEqualToString:@"startRecord"]) {          // 开启本地录像
        [self startRecord:call result:result];

    } if ([[call method] isEqualToString:@"stopRecord"]) {          // 关闭本地录像

        [self stopRecord:call result:result];

    } if ([[call method] isEqualToString:@"enableSound"]) {          // 声音控制
        NSDictionary * dict = call.arguments;
        BOOL enable = [dict[@"enable"] boolValue];
        result([self enableSound:enable]);

    } if ([[call method] isEqualToString:@"onResume"]) {          //

        result(@{@"ret" : @(NO),
          @"msg" : @"iOS端暂未实现"
        });

    } if ([[call method] isEqualToString:@"onPause"]) {          //

        result(@{@"ret" : @(NO),
          @"msg" : @"iOS端暂未实现"
        });
    } if ([[call method] isEqualToString:@"getVersion"]) {  // 查询SDK版本
        [self getVersion:call result:result];
    } if ([[call method] isEqualToString:@"createFolder"]) {    // 创建相册
        NSDictionary * dict = call.arguments;
        // 相册名称
        NSString * folderName = dict[@"folderPath"];
        [self createFolder:folderName];
        result(@YES);
    } else {
        //其他方法的回调
        result(FlutterMethodNotImplemented);
    }
}

- (nonnull UIView *)view {
    return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

#pragma mark - 视频相关操作
/// 查询SDK版本号
- (void)getVersion:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString * version = [HatomPlayer getVersion];
    result(version);
}
/// 开启语音对讲
- (void)startVoiceTalk:(FlutterMethodCall *)call result:(FlutterResult)result {

    if (self.isTalkPlaying) {
        [self.player stopVoiceTalk];
    }
    NSDictionary *dict = call.arguments;
    self.talkUrl = dict[@"url"];

    self.isTalkPlaying = YES;

    [self.player setVoiceDataSource:self.talkUrl headers:self.playHeaders];

    [self.player setPlayConfig:self.config];

    [self.player startVoiceTalk];

    result(@{
        @"ret": @YES,
        @"msg": @""
    });
}

/// 关闭语音对讲
- (void)stopVoiceTalk:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (self.isTalkPlaying) {

        self.isTalkPlaying = NO;
        [self.player stopVoiceTalk];
    }

    result(@{@"ret" : @YES,
             @"msg" : @""
    });
}

/// 声音控制
/// @param enable yes开启，no关闭
- (NSDictionary *)enableSound:(BOOL)enable {
    int result = [self.player enableAudio:enable];
    return @{
        @"ret" : @(result == 0),
        @"msg" : @"声音控制说明,ret为true成功"
    };
}

/// 开始预览
- (void)startToPreview:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (self.isPlaying) {
        [self.player stop];
    }
    self.playType = WF_VIDEO_PREVIEW;
    self.isPlaying = YES;

    NSDictionary *dict = call.arguments;
    self.videoUrl = dict[@"url"];

    [self.player setDataSource:self.videoUrl headers:self.playHeaders];
    [self.player setPlayConfig:self.config];

    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [self.player setVideoWindow:self];
        [self.player start];
    });

    result(@{
        @"ret": @YES,
        @"msg": @""
    });
}

/// 停止预览
- (void)stopPreview:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (self.isPlaying) {
        self.isPlaying = NO;
        self.playType = WF_VIDEO_IDLE;

        [self.player stop];
    }

    result(@{
        @"ret": @YES,
        @"msg": @""
    });
}

// 抓图
- (NSDictionary *)capturePicture {
    if (!_isPlaying) {
        return @{
            @"code" : @"0",
            @"msg" : @"当前未播放视频"
        };
    }

    dispatch_semaphore_t signal = dispatch_semaphore_create(0);
   __block NSString * code = @"0";
   __block NSString * message = @"";
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusDenied) {
            message = @"无保存图片到相册的权限，不能抓图";

        } else {
            NSDictionary * dic = [self capture];
            code = dic[@"code"];
            message = dic[@"msg"];
        }
        dispatch_semaphore_signal(signal);
    }];
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    return @{@"ret" : [code isEqualToString:@"0"]?@(NO):@(YES),
             @"msg" : message};
}

/// 抓拍
- (NSDictionary *)capture {
    if (!_isPlaying) {
        return @{
            @"code" : @"0",
            @"msg" : @"当前未播放视频"
        };
    }
    NSData * imgData = [self.player screenshoot];
    UIImage * img = [[UIImage alloc] initWithData:imgData];
    UIImageWriteToSavedPhotosAlbum(img, self, nil, nil);    // 保存图片到相册
    return @{
        @"code" : @"1",
        @"msg" : @"抓图成功，并保存到系统相册"
    };
    // 生成图片路径
//    NSString *documentDirectorie = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//    NSString *filePath = [documentDirectorie stringByAppendingFormat:@"/%.f.jpg", [NSDate date].timeIntervalSince1970];
//    int result = [self.player screenshoot:filePath thumbnail:filePath];
//    if (result != 0) {
//        NSString *message = [NSString stringWithFormat:@"抓图失败，错误码是 0x%d", result];
//        return @{
//            @"code" : @"0",
//            @"msg" : message
//        };
//    }
//    else {
//        dispatch_semaphore_t signal = dispatch_semaphore_create(0);
//        __block NSString * code = @"0";
//        __block NSString * message = @"";
//        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//            [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:filePath]];
//        } completionHandler:^(BOOL success, NSError * _Nullable error) {
//
//            if (success) {
//                message = @"抓图成功，并保存到系统相册";
//                code = @"1";
//            }
//            else {
//                message = @"保存到系统相册失败";
//                code = @"0";
//            }
//            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
//            dispatch_semaphore_signal(signal);
//        }];
//        dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
//        return @{@"code" : code,
//                 @"msg" : message
//        };
//    }
}

- (BOOL)isExistFolder:(NSString *)folderName {
    //首先获取用户手动创建相册的集合
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];

    __block BOOL isExisted = NO;
    //对获取到集合进行遍历
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        //folderName是我们写入照片的相册
        if ([assetCollection.localizedTitle isEqualToString:folderName])  {
            isExisted = YES;
        }
    }];

    return isExisted;
}

- (void)createFolder:(NSString *)folderName {
    if (![self isExistFolder:folderName]) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            //添加HUD文件夹
            [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:folderName];

        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSLog(@"创建相册文件夹成功!");
            } else {
                NSLog(@"创建相册文件夹失败:%@", error);
            }
        }];
    }
}

/// 开始录像
- (void)startRecord:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (!_isPlaying) {
        NSString * msg = @"未播放视频，不能录像";
        result( @{@"ret" : @(NO),
                 @"msg" : msg
        });
        return;
    }
    _isRecording = YES;

    dispatch_semaphore_t signal = dispatch_semaphore_create(0);
    __block NSString * code = @"0";
    __block NSString * message = @"";
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {

        if (status == PHAuthorizationStatusDenied) {
            code = @"0";
            message = @"无保存录像到相册的权限，不能录像";
        }
        else {
            NSDictionary * dic = [self startRecord];
            code = dic[@"code"];
            message = dic[@"msg"];
        }
        dispatch_semaphore_signal(signal);
    }];
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    result( @{@"ret" : [code isEqualToString:@"0"]?@(NO):@(YES),
             @"msg" : message
    });
}

/// 开始录像
- (NSDictionary *)startRecord {
    if (!_isPlaying) {
        NSString * msg = @"未播放视频，不能录像";
        return @{@"code" : @"0",
                 @"msg" : msg
        };
    }

    NSString * code = @"0";
    NSString * message = @"";
    // 生成视频路径
    NSString *documentDirectorie = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *filePath = [documentDirectorie stringByAppendingFormat:@"/%.f.mp4", [NSDate date].timeIntervalSince1970];
    _recordPath = [filePath copy];
    int result = [self.player startRecordAndConvert:filePath];
    if (result == 0) {
        code = @"1";
        message = @"";
    } else {
        message = [NSString stringWithFormat:@"开始录像失败，错误码是 0x%d", result];
        code = @"0";
    }
    return @{@"code" : code,
             @"msg" : message
    };
}

/// 结束录像
- (void)stopRecord:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary * dic = [self stopRecord];
    NSString *  code = dic[@"code"];
    NSString * message = dic[@"msg"];
    result( @{@"ret" : [code isEqualToString:@"0"]?@(NO):@(YES),
             @"msg" : message
    });
}

/// 停止录像
- (NSDictionary *)stopRecord {
    if (!_isRecording) {
        NSString * msg = @"当前录像已经停止，无法重复停止";
        return @{@"code" : @"0",
                 @"msg" : msg
        };
    }
    // 停止录像
    int res = [self.player stopRecord];
    if (res == 0) {
        _isRecording = NO;

        dispatch_semaphore_t signal = dispatch_semaphore_create(0);
        __block NSString * code = @"0";
        __block NSString * message = @"";
        //可在自定义recordPath路径下取录像文件
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:_recordPath]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                message = @"录像成功，并保存到系统相册";
                code = @"1";
            } else {
                message = @"保存到系统相册失败";
                code = @"0";
            }
            dispatch_semaphore_signal(signal);
        }];
        dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
        return @{@"code" : code,
                 @"msg" : message
        };
    } else {
        NSString *message = [NSString stringWithFormat:@"停止录像失败，错误码是 0x%d", res];
        return @{@"code" : @"0",
                 @"msg" : message
        };
    }
}


/// 开始回放
- (void)startPlayBack:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (self.isPlaying) {
        [self.player stop];
    }
    self.playType = WF_VIDEO_PLAYBACK;
    self.isPlaying = YES;

    NSDictionary *dict = call.arguments;
    NSString * playBackUrl = dict[@"url"];
    NSString * startTime = dict[@"startTime"];
    NSString * endTime = dict[@"stopTime"];
    [self.playHeaders setObject:startTime forKey:@"startTime"];
    [self.playHeaders setObject:endTime forKey:@"endTime"];

    [self.player setDataSource:playBackUrl headers:self.playHeaders];
    [self.player setPlayConfig:self.config];

    // 为避免卡顿，开启预览可以放到子线程中，在应用中灵活处理
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [self.player setVideoWindow:self];
        [self.player start];
    });
    result( @{@"ret" : @(YES),
             @"msg" : @""
    });
}

/// 指定时间快进
- (void)seekPlayBack:(FlutterMethodCall *)call result:(FlutterResult)result {
    if (self.playType == WF_VIDEO_PLAYBACK) {
        //获取参数
        NSDictionary * dict = call.arguments;
        NSString * seekTime = dict[@"seekTime"];

        int res = [self.player seekPlayback:seekTime];
        result( @{@"ret" : @(res == 0),
                 @"msg" : @""
        });
    }
    result( @{@"ret" : @(NO),
             @"msg" : @"只有回放视频才支持快进"
    });
}

/// 暂停回放
- (NSDictionary *)pausePlayBackVideo {
    if (!self.isPlaying) {
        return @{@"ret" : @(NO),
                 @"msg" : @"视频已经暂停"
        };
    }
    int res = [self.player pause];
    if (res == 0) {
        self.isPlaying = NO;
        return @{@"ret" : @(YES),
                 @"msg" : @"暂停回放成功"
        };
    } else {
        return @{@"ret" : @(NO),
                 @"msg" : @"暂停回放失败"
        };
    }
}

/// 恢复回放
- (NSDictionary *)resumePlayBackVideo {
    if (self.isPlaying) {
        return @{@"ret" : @(NO),
                 @"msg" : @"视频正在播放"
        };
    }
    int res = [self.player resume];
    if (res == 0) {
        self.isPlaying = YES;
        return @{@"ret" : @(YES),
                 @"msg" : @"继续播放成功"
        };
    } else {
        return @{@"ret" : @(NO),
                 @"msg" : @"继续播放失败"
        };
    }
}

/// 停止预览或回放
- (void)stopPlayVideo {
    self.isPlaying = NO;
    self.playType = WF_VIDEO_IDLE;

    [self.player stop];
}

#pragma mark - HatomPlayerDelegate
/// 播放状态回调方法
/// @param status 播放状态
/// @param errorCode 错误码，只有在 status 状态为： FAILED 、EXCEPTION 才有值 ,其他 status 值为 -1
- (void)onPlayerStatus:(PlayStatus)status errorCode:(NSString *)errorCode {
    NSLog(@"onPlayerStatus:%lu, errorCode:%@", status, errorCode);

    switch (status) {
        case SUCCESS: {
            NSLog(@"视频播放成功");
//            self.isPlaying = YES;
            _mPlayerStatus = [NSNumber numberWithInt:WF_SUCCESS];
            // 关闭声音
            [self.player enableAudio:NO];
        }
            break;
        case FAILED: {
            NSLog(@"视频播放失败");
            _mPlayerStatus = [NSNumber numberWithInt:WF_FAILED];
            // 关闭视频
            // TODO:
            if (self.isRecording) {
                //如果在录像，先关闭录像
                [self stopRecord];
            }
            // 关闭播放
            [self.player stop];
        }
            break;
        case EXCEPTION: {
            NSLog(@"视频播放异常");
            _mPlayerStatus = [NSNumber numberWithInt:WF_EXCEPTION];
            if (self.isRecording) {
                //如果在录像，先关闭录像
                [self stopRecord];
            }
            // 关闭播放
            [self.player stop];
        }
            break;
        case FINISH: {
            NSLog(@"视频播放结束");
            _mPlayerStatus = [NSNumber numberWithInt:WF_FINISH];
        }
            break;
        default:
            break;
    }
    NSDictionary * ret = @{@"status" : _mPlayerStatus};
    [_channel invokeMethod:@"onPlayerStatusCallback" arguments:ret];
}

/// 播放状态回调方法
/// @param status 播放状态
/// @param errorCode 错误码，只有在 status 状态为： FAILED 、EXCEPTION 才有值 ,其他 status 值为 -1
- (void)onTalkStatus:(PlayStatus)status errorCode:(NSString *)errorCode {
    NSLog(@"onTalkStatus:%lu, errorCode:%@", status, errorCode);
    NSString * msg;
    switch (status) {
        case SUCCESS:
            NSLog(@"开启语音对讲");
            _mTalkStatus = [NSNumber numberWithInt:WF_SUCCESS];
            if (self.isTalkPlaying) {
                msg = @"开启对讲成功";
            } else {
                msg = @"关闭对讲成功";
            }
            break;
        case FAILED:
            NSLog(@"语音对讲失败");
            _mTalkStatus = [NSNumber numberWithInt:WF_FAILED];
            msg = @"对讲失败";
            break;
        case EXCEPTION:
            NSLog(@"语音对讲异常");
            _mTalkStatus = [NSNumber numberWithInt:WF_EXCEPTION];
            msg = @"对讲异常";
            break;
        case FINISH:
            NSLog(@"语音对讲结束");
            _mTalkStatus = [NSNumber numberWithInt:WF_FINISH];
            msg = @"对讲结束";
            break;
        default:
            msg = @"";
            break;
    }
    NSDictionary * ret = @{@"status" : _mTalkStatus, @"msg": msg};
    [_channel invokeMethod:@"onTalkStatusCallback" arguments:ret];
}



#pragma mark - Notification Method
- (void)applicationWillResignActive {
//    if (_isRecording) {
//        [self stopRecord];
//    }
//    if (_isPlaying) {
//        if (self.playType == WF_VIDEO_PREVIEW) {
//            [self stopPlayVideo];
//        } else {
//            [self pausePlayBackVideo];
//        }
//
//    }
}

- (void)applicationDidBecomeActive {
//    if (self.videoUrl.length > 0) {
//        // 为避免卡顿，开启预览可以放到子线程中，在应用中灵活处理
//        dispatch_sync(dispatch_get_global_queue(0, 0), ^{
//            [self.player setVideoWindow:self];
//            [self.player start];
//        });
//    }

//    if (_isPlayBackBegining) {
//        [self resumePlayBackVideo];
//    }
}

#pragma mark - 懒加载
- (NSMutableDictionary *)playHeaders {
    if (!_playHeaders) {
        _playHeaders = [NSMutableDictionary dictionary];
//        [_playHeaders setObject:@"" forKey:@"token"];
    }
    return _playHeaders;
}

- (PlayConfig *)config {
    if (!_config) {
        _config = [[PlayConfig alloc] init];
    }
    return _config;
}

- (HatomPlayer *)player {
    if (!_player) {
        _player = [[DefaultHatomPlayer alloc] init];
        _player.delegate = self;
    }
    return _player;
}
@end
