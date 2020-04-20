package com.picker.oss;

import android.util.Log;

import androidx.annotation.NonNull;

import com.alibaba.sdk.android.oss.OSS;
import com.alibaba.sdk.android.oss.common.OSSLog;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;

import java.util.ArrayList;

public class APPCommonMoudle extends ReactContextBaseJavaModule {
    private static final String TAG = "APPCommonMoudle";
    private OSSManager ossManager = null;
    public APPCommonMoudle(@NonNull ReactApplicationContext reactContext) {
        super(reactContext);
        ossManager = new OSSManager(reactContext);
        ossManager.config();
        OSSLog.enableLog();

    }

    @NonNull
    @Override
    public String getName() {
        return "APPCommonMoudle";
    }

    @ReactMethod
    public void uploadFileArr(ReadableArray arr, Promise promise){
        Log.d(TAG, "uploadFileArr: ");
        if(arr==null || arr.size()==0){
            promise.reject("-1","传入上传列表为空");
            return;
        }
        ossManager.uploadFileArr(arr, new OSSManager.OSSCallback() {
            @Override
            public void onResult(ArrayList<String> list) {
                if(list == null){
                    promise.reject("-2","有文件上传失败");
                }else{

                    promise.resolve(Arguments.fromArray(list));
                }
            }
        });
    }
}
