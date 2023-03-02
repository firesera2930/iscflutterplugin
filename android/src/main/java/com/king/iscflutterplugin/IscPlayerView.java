package com.king.iscflutterplugin;


import android.content.Context;
import android.graphics.SurfaceTexture;
import android.text.TextUtils;
import android.util.Log;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.hikvision.hatomplayer.DefaultHatomPlayer;
import com.hikvision.hatomplayer.HatomPlayer;
import com.hikvision.hatomplayer.HatomPlayerSDK;
import com.hikvision.hatomplayer.PlayCallback.Status;
import com.hikvision.hatomplayer.PlayCallback;
import com.hikvision.hatomplayer.PlayConfig;
import com.hikvision.hatomplayer.core.HeaderParams;
import com.hikvision.hatomplayer.core.JPEGData;
import com.hikvision.hatomplayer.core.Quality;
import com.king.iscflutterplugin.utils.AppGlobalUtils;
import com.king.iscflutterplugin.utils.ThreadUtils;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;


/**
 * @author ljb
 * @des
 * @date 2020/4/27
 */
public class IscPlayerView extends TextureView implements PlatformView, MethodChannel.MethodCallHandler, TextureView.SurfaceTextureListener, PlayCallback.PlayStatusCallback, PlayCallback.VoiceTalkCallback {

    static class Config {
        /**
         * 预览地址
         */
        static String mUrl;
        /**
         * 回放开始时间
         */
        static String mStartTime;
        /**
         * 回放结束时间
         */
        static String mStopTime;
        /**
         * 回放定位时间
         */
        static String mSeekTime;
        /**
         * 截图,录像保存地址
         */
        static String mPath;

        /**
         * 播放类型,1:预览,2:回放
         */
        static int mPlayType = 0;
    }

    /**
     * 播放器
     */
    private final HatomPlayer mPlayer;

    /**
     * 视频播放状态,默认闲置
     */
    private int mPlayerStatus = PlayerStatus.IDLE;

    /**
     * 语音对讲状态,默认闲置
     */
    private int mTalkStatus = PlayerStatus.IDLE;
    /**
     * 通道
     */
    private final MethodChannel methodChannel;
    private boolean mEnable;
    boolean init = false;

    public IscPlayerView(Context context, int viewId, Object args, BinaryMessenger messenger) {
        super(context);
        //初始化SDK
        if (!init) {
            init = HatomPlayerSDK.init(AppGlobalUtils.getApplication(), "", true);
        }
        setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        setSurfaceTextureListener(this);
        mPlayer = new DefaultHatomPlayer();
        //注册
        methodChannel = new MethodChannel(messenger, "plugin_isc_player_" + viewId);
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        ThreadUtils.runOnSubThread(() -> {
            handleCall(methodCall, result);
        });
//        new Thread() {
//            @Override
//            public void run() {
//                handleCall(methodCall, result);
//            }
//        }.start();
    }

    private void handleCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            //开始预览
            case "startRealPlay":
                Config.mPlayType = 1;
                Config.mUrl = methodCall.argument("url");
                callResult(result, startRealPlay());
                break;

            //码流平滑切换
            case "changeStream":
                Config.mUrl = methodCall.argument("url");
                callResult(result, changeStream());
                break;

            //开始回放
            case "startPlayback":
                Config.mPlayType = 2;
                Config.mUrl = methodCall.argument("url");
                Config.mStartTime = methodCall.argument("startTime");
                Config.mStopTime = methodCall.argument("stopTime");
                callResult(result, startPlayback());
                break;

            //按绝对时间回放定位
            case "seekAbsPlayback":
                Config.mSeekTime = methodCall.argument("seekTime");
                callResult(result, seekAbsPlayback());
                break;

            //查询当前播放时间戳接口
            case "getOSDTime":
                callResult(result, getOSDTime());
                break;

            //暂停回放
            case "pause":
                callResult(result, pause());
                break;

            //恢复回放
            case "resume":
                callResult(result, resume());
                break;

            //停止播放
            case "stopPlay":
                callResult(result, stopPlay());
                break;

            //开启语音对讲
            case "startVoiceTalk":
                Config.mUrl = methodCall.argument("url");
                callResult(result, startVoiceTalk());
                break;

            //关闭语音对讲
            case "stopVoiceTalk":
                callResult(result, stopVoiceTalk());
                break;

            //预览/回放 抓图
            case "capturePicture":
                Config.mPath = methodCall.argument("path");
                callResult(result, capturePicture());
                break;

            //预览/回放 抓图 返回图片
            case "screenshot":
                Config.mPath = methodCall.argument("path");
                callResult(result, screenshot());
                break;

            //开启本地录像
            case "startRecord":
                Config.mPath = methodCall.argument("path");
                callResult(result, startRecord());
                break;

            // 关闭本地录像
            case "stopRecord":
                callResult(result, stopRecord());
                break;

            //声音控制
            case "enableSound":
                mEnable = methodCall.argument("enable");
                callResult(result, enableSound());
                break;

            case "onResume":
                onResume();
                callResult(result, true);
                break;

            case "onPause":
                onPause();
                callResult(result, true);
                break;

            case "getVersion":
                callResult(result, HatomPlayerSDK.getVersion());
                break;

            default:
                ThreadUtils.runOnUiThread(result::notImplemented);
        }

    }

    private void callResult(MethodChannel.Result result, Object o) {
        HashMap<String, Object> ret = new HashMap<>(16);
        ret.put("ret", o);
        ThreadUtils.runOnUiThread(() -> {
            result.success(ret);
        });
    }

    /**
     * 开始实时预览
     */
    private boolean startRealPlay() {
        mPlayerStatus = PlayerStatus.LOADING;
        updateStatus();

        SurfaceTexture texture = getSurfaceTexture();
        if (texture == null) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
        mPlayer.setSurfaceTexture(texture);
        mPlayer.setPlayStatusCallback(this);
        if (TextUtils.isEmpty(Config.mUrl)) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
        try {
            PlayConfig playConfig = new PlayConfig();
            playConfig.secretKey = null;
            playConfig.privateData = false;
            playConfig.hardDecode = false;
            playConfig.waterConfig = null;
            mPlayer.setPlayConfig(playConfig);
            mPlayer.setDataSource(Config.mUrl, null);
            mPlayer.start();
            return true;
        } catch (Exception e) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
    }

    /**
     * 码流平滑切换
     */
    private boolean changeStream() {
        mPlayerStatus = PlayerStatus.LOADING;
        updateStatus();

        SurfaceTexture texture = getSurfaceTexture();
        if (texture == null) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
        mPlayer.setSurfaceTexture(texture);
        mPlayer.setPlayStatusCallback(this);
        if (TextUtils.isEmpty(Config.mUrl)) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
        try {
            PlayConfig playConfig = new PlayConfig();
            playConfig.secretKey = null;
            playConfig.privateData = false;
            playConfig.hardDecode = false;
            playConfig.waterConfig = null;
            mPlayer.setPlayConfig(playConfig);
            mPlayer.setDataSource(Config.mUrl, null);
            mPlayer.changeStream(Quality.MAIN_STREAM_HIGH);
            return true;
        } catch (Exception e) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
    }

    /**
     * 开始回放
     */
    private boolean startPlayback() {
        mPlayerStatus = PlayerStatus.LOADING;
        updateStatus();

        SurfaceTexture texture = getSurfaceTexture();
        if (texture == null) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
        mPlayer.setSurfaceTexture(texture);
        mPlayer.setPlayStatusCallback(this);
        if (TextUtils.isEmpty(Config.mUrl)) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
        try {
            PlayConfig playConfig = new PlayConfig();
            playConfig.secretKey = null;
            playConfig.privateData = false;
            playConfig.hardDecode = false;
            playConfig.waterConfig = null;

            HashMap<String, String> header = new HashMap();
            header.put(HeaderParams.START_TIME, Config.mStartTime);
            header.put(HeaderParams.END_TIME, Config.mStopTime);
            mPlayer.setPlayConfig(playConfig);
            mPlayer.setDataSource(Config.mUrl, header);
            mPlayer.start();
            return true;
        } catch (Exception e) {
            onPlayerStatus(Status.FAILED, "-1");
            return false;
        }
    }

    /**
     * 按绝对时间回放定位
     */
    private boolean seekAbsPlayback() {
        mPlayerStatus = PlayerStatus.LOADING;
        updateStatus();

        try {
            mPlayer.seekPlayback(Config.mSeekTime);
        } catch (Exception e) {
            onPlayerStatus(Status.FAILED, "-1");
        }
        return true;
    }

    /**
     * 查询当前播放时间戳接口
     *
     * @return
     */
    private long getOSDTime() {
        return mPlayer.getOSDTime();
    }

    /**
     * 暂停回放
     */
    private boolean pause() {
        try {
            mPlayer.pause();
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 恢复回放
     *
     * @return
     */
    private boolean resume() {
        try {
            mPlayer.resume();
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 停止播放
     */
    private boolean stopPlay() {
        try {
            mPlayer.stop();
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 开启对讲
     */
    private boolean startVoiceTalk() {
        mTalkStatus = PlayerStatus.LOADING;
        updateTalkStatus();

        if (TextUtils.isEmpty(Config.mUrl)) {
            onTalkStatus(Status.FAILED, "-1");
            return false;
        }

        try {
            PlayConfig playConfig = new PlayConfig();
            mPlayer.setPlayConfig(playConfig);
            mPlayer.setVoiceDataSource(Config.mUrl, null);
            mPlayer.startVoiceTalk();
            return true;
        } catch (Exception e) {
            onTalkStatus(Status.FAILED, "-1");
            return false;
        }
    }


    /**
     * 关闭语音对讲
     *
     * @return
     */
    private boolean stopVoiceTalk() {
        try {
            mPlayer.stopVoiceTalk();
            return true;
        } catch (Exception e) {
            return false;
        }
    }


    /**
     * 预览/回放抓图
     *
     * @return
     */
    private boolean capturePicture() {
        try {
            mPlayer.screenshot(Config.mPath, "");
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 预览/回放抓图
     *
     * @return
     */
    private byte[] screenshot(){
        try {
            JPEGData jpegData = mPlayer.screenshot();
            return jpegData.mJpegBuffer;
        } catch (Exception e) {
            return null;
        }
    }


    /**
     * 开启本地录像
     *
     * @return
     */
    private boolean startRecord() {
        try {
            //不进行转码，只能使用视频SDK进行播放。
            //mPlayer.startRecord(Config.mPath);

            // 转码后，录像文件可以正常使用播放器播放，
            mPlayer.startRecordAndConvert(Config.mPath);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 关闭本地录像
     *
     * @return
     */
    private boolean stopRecord() {
        try {
            mPlayer.stopRecord();
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 声音控制
     *
     * @return
     */
    private boolean enableSound() {
        try {
            return mPlayer.enableAudio(mEnable) == 0;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 生命周期管理
     */
    private void onResume() {
        // 注意:APP前后台切换时 SurfaceTextureListener可能在有某些 华为手机 上不会回调，例如：华为P20，所以我们在这里手动调用
        if (isAvailable()) {
            onSurfaceTextureAvailable(getSurfaceTexture(), getWidth(), getHeight());
        }
    }

    /**
     * 生命周期管理
     */
    private void onPause() {
        // 注意:APP前后台切换时 SurfaceTextureListener可能在有某些 华为手机 上不会回调，例如：华为P20，所以我们在这里手动调用
        if (isAvailable()) {
            onSurfaceTextureDestroyed(getSurfaceTexture());
        }
    }


    /**
     * 更新播放器状态
     */
    private void updateStatus() {
        ThreadUtils.runOnUiThread(() -> {
            Map<String, Object> ret = new HashMap<>(16);
            ret.put("status", mPlayerStatus);
            if (mPlayerStatus == PlayerStatus.FAILED) {
                ret.put("error", -1);
            }
            //上传播放器状态
            methodChannel.invokeMethod("onPlayerStatusCallback", ret);
        });
    }

    /**
     * 更新语音对讲状态
     */
    private void updateTalkStatus() {
        ThreadUtils.runOnUiThread(() -> {
            Map<String, Object> ret = new HashMap<>(16);
            ret.put("status", mTalkStatus);
            if (mTalkStatus == PlayerStatus.FAILED) {
                ret.put("error", -1);
            }
            //上传播放器状态
            methodChannel.invokeMethod("onTalkStatusCallback", ret);
        });
    }

    @Override
    public void onPlayerStatus(Status status, String i) {
        ThreadUtils.runOnUiThread(() -> {
            switch (status) {
                //播放成功
                case SUCCESS:
                    mPlayerStatus = PlayerStatus.SUCCESS;
                    setKeepScreenOn(true);//保持亮屏
                    break;
                //播放失败
                case FAILED:
                    mPlayerStatus = PlayerStatus.FAILED;
                    break;
                //录像回放结束
                case FINISH:
                    mPlayerStatus = PlayerStatus.FINISH;
                    break;
                //取流异常
                case EXCEPTION:
                    mPlayerStatus = PlayerStatus.EXCEPTION;
                    mPlayer.stop();
                    break;
                //异常
                default:
                    mPlayerStatus = PlayerStatus.IDLE;
                    mPlayer.stop();
            }
            updateStatus();
        });
    }

    @Override
    public void onTalkStatus(Status status, String i) {
        ThreadUtils.runOnUiThread(() -> {
            switch (status) {
                //成功
                case SUCCESS:
                    mTalkStatus = PlayerStatus.SUCCESS;
                    setKeepScreenOn(true);//保持亮屏
                    break;
                //失败
                case FAILED:
                    mTalkStatus = PlayerStatus.FAILED;
                    break;
                //结束
                case FINISH:
                    mTalkStatus = PlayerStatus.FINISH;
                    break;
                //异常
                case EXCEPTION:
                    mTalkStatus = PlayerStatus.EXCEPTION;
                    mPlayer.stop();
                    break;
                //空闲
                default:
                    mTalkStatus = PlayerStatus.IDLE;
                    mPlayer.stop();
            }
            updateTalkStatus();
        });
    }

    @Override
    public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
        //恢复处于暂停播放状态的窗口
        if (mPlayerStatus == PlayerStatus.STOPPING) {
            switch (Config.mPlayType) {
                case 1:
                    startRealPlay();
                    break;
                case 2:
                    startPlayback();
                    break;
                default:
            }

        }
    }

    @Override
    public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {

    }

    @Override
    public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
        if (mPlayerStatus == PlayerStatus.SUCCESS) {
            //暂停播放，再次进入时恢复播放
            mPlayerStatus = PlayerStatus.STOPPING;
            updateStatus();
            mPlayer.stop();
        }
        return false;
    }

    @Override
    public void onSurfaceTextureUpdated(SurfaceTexture surface) {

    }


    @Override
    public View getView() {
        return this;
    }

    @Override
    public void dispose() {
        mPlayer.stop();
    }

}
