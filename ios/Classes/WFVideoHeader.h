//
//  WFVideoHeader.h
//  Pods
//
//  Created by windyfat on 2020/5/7.
//

#ifndef WFVideoHeader_h
#define WFVideoHeader_h

typedef NS_ENUM(NSUInteger, WFPTZControlDirection) {
    WFPTZControlDirectionUp,                // 上
    WFPTZControlDirectionDown,              // 下
    WFPTZControlDirectionLeft,              // 左
    WFPTZControlDirectionRight,             // 右
    WFPTZControlDirectionCenter,            // 中
};

typedef NS_ENUM(NSUInteger, WFHikVideoStatus) {
    WF_IDLE,                       // 闲置状态
    WF_LOADING,                    // 加载中状态
    WF_SUCCESS,                    // 播放成功
    WF_STOPPING,                   // 暂时停止播放
    WF_FAILED,                     // 播放失败
    WF_EXCEPTION,                  // 播放过程中出现异常
    WF_FINISH,                     // 回放结束
};

typedef NS_ENUM(NSUInteger, WFHikVideoPlayType) {
    WF_VIDEO_IDLE,                           // 闲置状态
    WF_VIDEO_PREVIEW,                       // 预览
    WF_VIDEO_PLAYBACK,                    // 回放
};

#endif /* WFVideoHeader_h */
