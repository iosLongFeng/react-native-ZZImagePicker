package com.picker;

import android.os.Bundle;
import android.os.PersistableBundle;

import androidx.annotation.Nullable;

import com.facebook.react.ReactActivity;
import com.luck.picture.lib.config.PictureMimeType;
import com.luck.picture.lib.tools.PictureFileUtils;

public class MainActivity extends ReactActivity {

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  @Override
  protected String getMainComponentName() {
    return "Picker";
  }

  @Override
  public void onCreate(@Nullable Bundle savedInstanceState, @Nullable PersistableBundle persistentState) {
    super.onCreate(savedInstanceState, persistentState);
    PictureFileUtils.deleteCacheDirFile(this, PictureMimeType.ofImage());
    PictureFileUtils.deleteCacheDirFile(this, PictureMimeType.ofVideo());
    //清除所有缓存实例：压缩，缩小，视频，音频所生成的临时文件
    PictureFileUtils.deleteAllCacheDirFile(this);
  }
}
