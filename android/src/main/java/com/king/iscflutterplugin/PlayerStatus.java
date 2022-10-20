package com.king.iscflutterplugin;

public interface PlayerStatus {
    /**
     * 闲置状态
     */
    int IDLE = 0;
    /**
     * 加载中状态
     */
    int LOADING = 1;
    /**
     * 播放成功
     */
    int SUCCESS = 2;
    /**
     * 暂时停止播放
     */
    int STOPPING = 3;
    /**
     * 播放失败
     */
    int FAILED = 4;
    /**
     * 播放过程中出现异常
     */
    int EXCEPTION = 5;
    /**
     * 回放结束
     */
    int FINISH = 6;
}
