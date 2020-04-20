package com.picker.oss;

import android.content.Context;
import android.util.Log;

import com.alibaba.sdk.android.oss.ClientException;
import com.alibaba.sdk.android.oss.OSS;
import com.alibaba.sdk.android.oss.OSSClient;
import com.alibaba.sdk.android.oss.ServiceException;
import com.alibaba.sdk.android.oss.callback.OSSCompletedCallback;
import com.alibaba.sdk.android.oss.common.auth.OSSAuthCredentialsProvider;
import com.alibaba.sdk.android.oss.common.auth.OSSCredentialProvider;
import com.alibaba.sdk.android.oss.internal.OSSAsyncTask;
import com.alibaba.sdk.android.oss.model.PutObjectRequest;
import com.alibaba.sdk.android.oss.model.PutObjectResult;
import com.facebook.react.bridge.ReadableArray;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;


public class OSSManager {
    private static final String TAG = "OSSManager";
    private OSS oss = null;
    private Context context;
    private String bucket = null;
    private String endpoint = null;
    private String prefix = null;
    public OSSManager(Context context){
        this.context = context;
    }

    public void config() {
        String url = "http://dev.blitzcrank.beiru168.com/api/v1/sts";
        OkHttpClient okHttpClient = new OkHttpClient();
        final Request request = new Request.Builder()
                .url(url)
                .get()//默认就是GET请求，可以不写
                .build();
        Call call = okHttpClient.newCall(request);
        call.enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                Log.d(TAG, "onFailure: ");
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String configInfo = response.body().string();
                Log.d(TAG, "onResponse: " + configInfo);
                try {
                    JSONObject jsonObject = null;
                    jsonObject = new JSONObject(configInfo);

                    if (jsonObject != null) {
                        int code = jsonObject.getInt("code");
                        if (code == 200) {
                            JSONObject data = jsonObject.getJSONObject("data");
                            configOSS(data);
                        }

                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }

            }
        });

    }

    private void configOSS(JSONObject config) throws JSONException {
        String bucket = config.getString("bucket");
        String endpoint = config.getString("endpoint");
        endpoint = endpoint.replace("http://","");
        String prefix = config.getString("prefix");
        String stsUrl = config.getString("stsUrl");
        stsUrl = "http://dev.blitzcrank.beiru168.com"+stsUrl;
        this.bucket = bucket;
        this.endpoint = endpoint;
        this.prefix = prefix;
        Log.d(TAG, "onResponse: " + stsUrl);
        OSSCredentialProvider credentialProvider = new OSSAuthCredentialsProvider(stsUrl);
        oss = new OSSClient( this.context,endpoint, credentialProvider);
    }

    public void uploadFileArr(ReadableArray arr,OSSCallback ossCallback){
        if(oss==null){
            this.config();
            ossCallback.onResult(null);
            return;
        }
        final int length = arr.size();
        final HashMap<String,String> hashMap = new HashMap<String, String>();
        final ArrayList<String> arrayList= new ArrayList<String>();
        for (int i = 0; i < length; i++) {
            String path = arr.getString(i);
            int start = path.lastIndexOf(".");
            String typeName = path.substring(start + 1);
            String uuid = UUID.randomUUID().toString().replace("-","");
            String objectName = this.prefix+"/"+ uuid+"."+typeName;
            PutObjectRequest put = new PutObjectRequest(this.bucket, objectName, path.replace("file://",""));
            OSSAsyncTask task = oss.asyncPutObject(put, new OSSCompletedCallback<PutObjectRequest, PutObjectResult>() {
                @Override
                public void onSuccess(PutObjectRequest request, PutObjectResult result) {
                    String remotepath = "https://"+bucket+"."+endpoint+"/"+objectName;
                    hashMap.put(path,remotepath);
                    if(hashMap.size()==length){
                        boolean haveFailure = false;
                        for (int j = 0; j < length; j++) {
                            String remotePath = hashMap.get(arr.getString(j));
                            if(remotePath.length()==0){
                                haveFailure = true;
                                break;
                            }
                            arrayList.add(remotePath);
                        }
                        if(haveFailure){
                            Log.d(TAG, "onFailure: ");
                            ossCallback.onResult(null);
                        }else{
                            Log.d(TAG, "onSuccess: "+arrayList.toString());
                            ossCallback.onResult(arrayList);
                        }
                    }
                }

                @Override
                public void onFailure(PutObjectRequest request, ClientException clientException, ServiceException serviceException) {
                    hashMap.put(path,"");
                    if(hashMap.size() == length){
                        ossCallback.onResult(null);
                        Log.d(TAG, "onFailure: ");
                    }
                }
            });

        }

    }

    public interface OSSCallback{
        public void onResult(ArrayList<String> list);
    }


}


