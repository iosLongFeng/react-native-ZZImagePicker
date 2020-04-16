package com.picker.zzImagePicker;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.media.MediaMetadataRetriever;
import android.media.ThumbnailUtils;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import androidx.annotation.NonNull;

import com.bumptech.glide.Glide;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;

import com.luck.picture.lib.PictureSelector;
import com.luck.picture.lib.config.PictureConfig;
import com.luck.picture.lib.config.PictureMimeType;
import com.luck.picture.lib.entity.LocalMedia;
import com.luck.picture.lib.listener.OnResultCallbackListener;
import com.luck.picture.lib.tools.PictureFileUtils;
import com.picker.R;
import com.vincent.videocompressor.VideoCompress;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.ref.WeakReference;
import java.net.URISyntaxException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Locale;

import io.microshow.rxffmpeg.RxFFmpegCommandList;
import io.microshow.rxffmpeg.RxFFmpegInvoke;
import io.microshow.rxffmpeg.RxFFmpegSubscriber;

import static android.app.Activity.RESULT_OK;
import static android.provider.MediaStore.Video.Thumbnails.MINI_KIND;

public class ZZImagePicker extends ReactContextBaseJavaModule {
    private static final String TAG = "ZZImagePicker";
    private Promise mPickerPromise;
    private ReactApplicationContext reactContext;
    private LoadingDialog loadingDialog;
    private MyRxFFmpegSubscriber myRxFFmpegSubscriber;

    public ZZImagePicker(@NonNull ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        reactContext.addActivityEventListener(mActivityEventListener);


    }

    @NonNull
    @Override
    public String getName() {
        return "ZZImagePicker";
    }

    @ReactMethod
    public void pickPhoto(ReadableMap options, Promise promise) {
        this.mPickerPromise = promise;
        int imageCount = options.getInt("imageCount");
        boolean useCamera = options.getBoolean("useCamera");
        boolean selectOriginal = options.getBoolean("selectOriginal");
        PictureSelector.create(getCurrentActivity())
                .openGallery(PictureMimeType.ofImage())
                .isCamera(useCamera)
                .maxSelectNum(imageCount)
                .isOriginalImageControl(selectOriginal)
                .enableCrop(false)
                .compress(true)
                .loadImageEngine(GlideEngine.createGlideEngine())
                .forResult(PictureConfig.CHOOSE_REQUEST);


    }

    @ReactMethod
    public void pickVideo(ReadableMap options, Promise promise) {
        this.mPickerPromise = promise;
        int maxVideoTime = options.getInt("maxVideoTime");
        boolean useCamera = options.getBoolean("useCamera");
        PictureSelector.create(getCurrentActivity())
                .openGallery(PictureMimeType.ofVideo())
                .isCamera(useCamera)
                .maxSelectNum(1)
                .videoMaxSecond(maxVideoTime)
                .recordVideoSecond(maxVideoTime)
                .loadImageEngine(GlideEngine.createGlideEngine())
                .forResult(PictureConfig.REQUEST_CAMERA);


    }

    @ReactMethod
    public void zipVideo(String path, Promise promise) throws IOException {
        String PACKAGE_NAME = reactContext.getPackageName();
        String compressDir = Environment.getExternalStorageDirectory().toString() + "/Android/data/" + PACKAGE_NAME + "/files/videos/";
        checkFolderExists(compressDir);
        Calendar now = new GregorianCalendar();
        SimpleDateFormat simpleDate = new SimpleDateFormat("yyyyMMddHHmmss", Locale.getDefault());
        String fileName = simpleDate.format(now.getTime());
        final String compressVideoPath = compressDir + fileName + ".mp4";
        path = path.replaceAll("file://", "");
        File file = new File(path);
        FileInputStream fis = new FileInputStream(file);
        long size = fis.available();
        if(size<= 1024*1024*10){
            //Log.i(TAG, "压缩开始压缩开始压缩开始" );
            VideoCompress.compressVideoMedium(path, compressVideoPath, new VideoCompress.CompressListener() {
                @Override
                public void onStart() {
                    Log.i(TAG, "onStart: ");
                }

                @Override
                public void onSuccess() {
                    Log.i(TAG, "压缩成功" + compressVideoPath);
                    promise.resolve("file://"+compressVideoPath);



                }

                @Override
                public void onFail() {
                    loadingDialog.dismiss();

                    Log.i(TAG, "onFail:");
                    ZZImagePicker.this.mPickerPromise.reject("-6", "压缩视频失败");
                    promise.reject("-10","压缩失败");

                }

                @Override
                public void onProgress(float percent) {

                }
            });

        }else{
            //Log.i(TAG, "压缩开始压缩开始压缩开始" );
            VideoCompress.compressVideoLow(path, compressVideoPath, new VideoCompress.CompressListener() {
                @Override
                public void onStart() {
                    Log.i(TAG, "onStart: ");
                }

                @Override
                public void onSuccess() {

                    File file = new File(compressVideoPath);
                    FileInputStream fis = null;
                    try {
                        fis = new FileInputStream(file);
                        long size = fis.available();
                        if(size >= 1024*1024*5){
                            zipVideo(compressVideoPath,promise);
                        }else{
                            Log.i(TAG, "压缩成功" + compressVideoPath);
                            promise.resolve("file://"+compressVideoPath);
                        }

                    } catch (IOException e) {
                        e.printStackTrace();
                    }

                }

                @Override
                public void onFail() {
                    loadingDialog.dismiss();

                    Log.i(TAG, "onFail:");
                    ZZImagePicker.this.mPickerPromise.reject("-6", "压缩视频失败");
                    promise.reject("-10","压缩失败");

                }

                @Override
                public void onProgress(float percent) {

                }
            });
        }

//        Log.i(TAG, "压缩输出压缩输出压缩输出压缩输出压缩输出" + compressVideoPath);
//
//        String text = "ffmpeg -y -i " + path + " -b 2097k -r 30 -vcodec libx264 -preset superfast "+compressVideoPath;
//
//        String[] commands = text.split(" ");
//
//        myRxFFmpegSubscriber = new MyRxFFmpegSubscriber();
//
//        //开始执行FFmpeg命令
//        RxFFmpegInvoke.getInstance()
//                .runCommandRxJava(commands)
//                .subscribe(myRxFFmpegSubscriber);


    }

    public static class MyRxFFmpegSubscriber extends RxFFmpegSubscriber {


        @Override
        public void onFinish() {
            Log.d(TAG, "onFinish: 压缩成功");
        }

        @Override
        public void onProgress(int progress, long progressTime) {
            Log.d(TAG, "onProgress: 压缩成功");
        }

        @Override
        public void onCancel() {
            Log.d(TAG, "onCancel: 压缩成功");
        }

        @Override
        public void onError(String message) {
            Log.d(TAG, "onError: 压缩成功");
        }
    }




    public static void clearCache(Context context) {
        Log.i(TAG, "clearCache: 111");
        PictureFileUtils.deleteCacheDirFile(context, PictureMimeType.ofImage());
        PictureFileUtils.deleteCacheDirFile(context, PictureMimeType.ofVideo());
        //清除所有缓存实例：压缩，缩小，视频，音频所生成的临时文件
        PictureFileUtils.deleteAllCacheDirFile(context);
        String PACKAGE_NAME = context.getPackageName();
        String dir = Environment.getExternalStorageDirectory().toString() + "/Android/data/" + PACKAGE_NAME + "/files/Pictures";
        File cutDir = new File(dir);
        Log.i(TAG, "clearCache: 222");
        if (cutDir != null) {
            Log.i(TAG, "clearCache: 3333");
            File[] files = cutDir.listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isFile()) {
                        Log.i(TAG, "clearCache: ");
                        file.delete();
                    }
                }
            }
        }

        dir = Environment.getExternalStorageDirectory().toString() + "/Android/data/" + PACKAGE_NAME + "/files/videos";
        cutDir = new File(dir);
        if (cutDir != null) {
            Log.i(TAG, "clearCache: ");
            File[] files = cutDir.listFiles();
            if (files != null) {
                for (File file : files) {
                    if (file.isFile()) {
                        Log.i(TAG, "clearCache: ");
                        file.delete();
                    }
                }
            }
        }

    }


    private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {
        @Override
        public void onActivityResult(Activity activity, int requestCode, int resultCode, final Intent data) {
            Log.i(TAG, "onActivityResult: 111");
            if (resultCode == RESULT_OK) {
                if (requestCode == PictureConfig.CHOOSE_REQUEST) {
                    Log.i(TAG, "onActivityResult: 222");
                    List<LocalMedia> selectList = PictureSelector.obtainMultipleResult(data);
                    // 例如 LocalMedia 里面返回五种path
                    // 1.media.getPath(); 原图path，但在Android Q版本上返回的是content:// Uri类型
                    // 2.media.getCutPath();裁剪后path，需判断media.isCut();切勿直接使用
                    // 3.media.getCompressPath();压缩后path，需判断media.isCompressed();切勿直接使用
                    // 4.media.getOriginalPath()); media.isOriginal());为true时此字段才有值
                    // 5.media.getAndroidQToPath();Android Q版本特有返回的字段，但如果开启了压缩或裁剪还是取裁剪或压缩路
                    //径；注意：.isAndroidQTransform(false);此字段将返回空
                    // 如果同时开启裁剪和压缩，则取压缩路径为准因为是先裁剪后压缩
                    WritableArray videoList = new WritableNativeArray();
                    for (LocalMedia media : selectList) {
                        Log.i(TAG, "压缩::" + media.getCompressPath());
                        Log.i(TAG, "原图::" + media.getPath());
                        Log.i(TAG, "裁剪::" + media.getCutPath());
                        Log.i(TAG, "是否开启原图::" + media.isOriginal());
                        Log.i(TAG, "原图路径::" + media.getOriginalPath());
                        Log.i(TAG, "图片大小:" + media.getSize());
                        Log.i(TAG, "Android Q 特有Path::" + media.getAndroidQToPath());
                        File file = new File(media.getCompressPath());
                        Log.i(TAG, "压缩图片大小:" + file.length());
                        if (media.isOriginal()) {
                            videoList.pushString("file://" + media.getPath());
                        } else {
                            videoList.pushString("file://" + media.getCompressPath());
                        }
                    }
                    ZZImagePicker.this.mPickerPromise.resolve(videoList);
                } else if (requestCode == PictureConfig.REQUEST_CAMERA) {
                    Log.i(TAG, "onActivityResult: 333");
                    loadingDialog = LoadingDialog.getInstance(getCurrentActivity());
                    loadingDialog.show();

                    List<LocalMedia> mVideoSelectList = PictureSelector.obtainMultipleResult(data);
                    WritableMap videoMap = new WritableNativeMap();
                    LocalMedia media = mVideoSelectList.get(0);
                    Log.i(TAG, "视频路径 " + media.getPath());

                    Calendar now = new GregorianCalendar();
                    SimpleDateFormat simpleDate = new SimpleDateFormat("yyyyMMddHHmmss", Locale.getDefault());
                    String fileName = simpleDate.format(now.getTime());
                    String dir = Environment.getExternalStorageDirectory().toString();
                    String PACKAGE_NAME = reactContext.getPackageName();
                    dir = Environment.getExternalStorageDirectory().toString() + "/Android/data/" + PACKAGE_NAME + "/files/Pictures/";
                    checkFolderExists(dir);

                    try {

//                                MediaMetadataRetriever media1 = new MediaMetadataRetriever();
//                                media1.setDataSource(media.getPath());
//                                Bitmap bitmap = media1.getFrameAtTime();
                        String videoPath = media.getPath();
                        if ((Build.VERSION.SDK_INT > Build.VERSION_CODES.P)) {
                            videoPath = media.getAndroidQToPath();
                        }

                        Bitmap bitmap = getVideoThumbnail(videoPath, MINI_KIND, 100, 100);
                        if (bitmap == null) {
                            Log.d(TAG, "onActivityResult: 获取封面图为空");
                        }
                        File file = new File(dir + fileName + ".jpg");
                        Log.i(TAG, "视频封面地址 " + file.toString());
                        FileOutputStream out = new FileOutputStream(file);
                        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out);
                        out.flush();
                        out.close();
                        videoMap.putString("coverImage", "file://" + file.toString());
                        videoMap.putString("videoPath", "file://" + videoPath);


                        ZZImagePicker.this.mPickerPromise.resolve(videoMap);
                    } catch (Exception e) {
                        e.printStackTrace();
                        ZZImagePicker.this.mPickerPromise.reject("-5", "获取视频封面失败");
                    } finally {

                        loadingDialog.dismiss();

                    }

                }

            } else {
                ZZImagePicker.this.mPickerPromise.reject("-3", "用户取消选择");
                Log.i(TAG, "PictureSelector Cancel");
            }

        }
    };

    private void checkFolderExists(String strFolder) {
        File file = new File(strFolder);
        if (!file.exists()) {
            file.mkdir();
        }

    }

    private Bitmap getVideoThumbnail(String videoPath, int kind, int width, int height) {
        Bitmap bitmap = null;
        // 获取视频的缩略图
        bitmap = ThumbnailUtils.createVideoThumbnail(videoPath, kind);
        if (width > 0 && height > 0) {
            bitmap = ThumbnailUtils.extractThumbnail(bitmap, width, height,
                    ThumbnailUtils.OPTIONS_RECYCLE_INPUT);
        }

        return bitmap;
    }


}
