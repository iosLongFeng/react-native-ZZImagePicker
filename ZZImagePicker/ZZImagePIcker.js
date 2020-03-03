import {NativeModules, Dimensions} from 'react-native';
const {ZZImagePicker} = NativeModules;

export default {
  /**
   * 选取图片
   * @param imageCount 图片数量
   * @param useCamera  是否使用拍照
   * @param selectOriginal  是否开启原图
   * @returns {Promise}
   */
  pickPhoto(imageCount = 1, useCamera = true, selectOriginal = true) {
    return ZZImagePicker.pickPhoto({imageCount, useCamera, selectOriginal});
  },
  /**
   * 选取视频
   * @param maxVideoTime 视频时间，单位秒
   * @param useCamera    是否要拍摄
   * @returns {Promise}
   */
  pickVideo(maxVideoTime = 120, useCamera = true) {
    return ZZImagePicker.pickVideo({maxVideoTime, useCamera});
  },
};
