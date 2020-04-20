package com.picker;

import android.os.Bundle;
import android.os.PersistableBundle;
import android.util.Log;

import androidx.annotation.Nullable;

import com.facebook.react.ReactActivity;
import com.luck.picture.lib.config.PictureMimeType;
import com.luck.picture.lib.tools.PictureFileUtils;
import com.picker.oss.OSSManager;
import com.picker.zzImagePicker.ZZImagePicker;

public class MainActivity extends ReactActivity {
  private static final String TAG = "MainActivity";
  private OSSManager ossManager = null;
  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  @Override
  protected String getMainComponentName() {
    return "Picker";
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    Log.d(TAG, "onCreate: onCreate: onCreate: onCreate: onCreate: ");
    ossManager = new OSSManager(this);
    ossManager.config();
  }

}
