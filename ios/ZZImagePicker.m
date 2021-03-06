//
//  ZZImagePicker.m
//  Picker
//
//  Created by ns on 2020/3/3.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import "ZZImagePicker.h"
#import <TZImagePickerController.h>
#import "CompressImageTool.h"
#import <SVProgressHUD.h>
@interface ZZImagePicker()<TZImagePickerControllerDelegate>
@property(nonatomic,strong)TZImagePickerController* imagePickerVc;
/**
 保存Promise的resolve block
 */
@property (nonatomic, copy) RCTPromiseResolveBlock resolveBlock;
/**
 保存Promise的reject block
 */
@property (nonatomic, copy) RCTPromiseRejectBlock rejectBlock;

@property (nonatomic, assign) int maxVideoTime;

@property(nonatomic,strong)NSMutableDictionary<NSString*,PHAsset*>*assetDic;
@end
@implementation ZZImagePicker



RCT_REMAP_METHOD(pickPhoto,
                 options:(NSDictionary *)options
                 showImagePickerResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  _imagePickerVc = nil;
  self.resolveBlock = resolve;
  self.rejectBlock = reject;
  int imageCount = [options[@"imageCount"] intValue];
  bool useCamera = [options[@"useCamera"] boolValue];
  bool selectOriginal = [options[@"selectOriginal"] boolValue];
  [self imagePickerVc].allowPickingImage = YES;
  [self imagePickerVc].allowPickingVideo = NO;
  [self imagePickerVc].allowPickingOriginalPhoto = selectOriginal;
  [self imagePickerVc].maxImagesCount = imageCount;
  [self imagePickerVc].allowTakePicture = useCamera;
  [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:[self imagePickerVc] animated:YES completion:nil];
  
}

RCT_REMAP_METHOD(pickVideo,
                 options:(NSDictionary *)options
                 showVideoPickerResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  _imagePickerVc = nil;
  self.resolveBlock = resolve;
  self.rejectBlock = reject;
  bool useCamera = [options[@"useCamera"] boolValue];
  int maxVideoTime = [options[@"maxVideoTime"] intValue];
  self.maxVideoTime = maxVideoTime;
  [self imagePickerVc].allowPickingImage = NO;
  [self imagePickerVc].allowPickingVideo = YES;
  [self imagePickerVc].allowTakeVideo = useCamera;
  [self imagePickerVc].videoMaximumDuration = maxVideoTime;
  [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:[self imagePickerVc] animated:YES completion:nil];
  
}

RCT_REMAP_METHOD(zipVideo,
                 options:(NSString *)zipUrl
                 zipVideoPickerResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {

  NSLog(@"zipVideo");
 
  [[TZImageManager manager] getVideoOutputPathWithAsset:_assetDic[zipUrl] presetName:AVAssetExportPresetMediumQuality success:^(NSString *outputPath) {
    resolve(outputPath);
    NSLog(@"压缩成功   %@",outputPath);
   
  } failure:^(NSString *errorMessage, NSError *error) {
    reject(@"-10",@"压缩失败",nil);
  }];

}


-(TZImagePickerController *)imagePickerVc{
  if(_imagePickerVc==nil){
    _imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
    _imagePickerVc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    _imagePickerVc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    _imagePickerVc.sortAscendingByModificationDate = NO;
    _imagePickerVc.allowCameraLocation = NO;
    _imagePickerVc.preferredLanguage = @"zh-Hans";
    _maxVideoTime = 120;
    _assetDic = [NSMutableDictionary dictionary];
  }
  return _imagePickerVc;
}

+(void)clearCache{
  
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:NSTemporaryDirectory()];
  for (NSString *fileName in enumerator) {
    [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] error:nil];
  }
}

#pragma mark - TZImagePickerControllerDelegate
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
  NSMutableArray* pathes = [NSMutableArray arrayWithCapacity:assets.count];
  NSUInteger count = assets.count;
  for (NSInteger i = 0; i < count; i++) {
    PHAsset *asset = assets[i];
    [[TZImageManager manager] requestImageDataForAsset:asset completion:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
      NSString* fileName = [NSString stringWithFormat:@"%@",[asset valueForKey:@"filename"]];
      fileName = [fileName lowercaseString];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      if(isSelectOriginalPhoto){
        NSString *filePath = [NSTemporaryDirectory()stringByAppendingPathComponent:fileName];
        [fileManager removeItemAtPath:filePath error:nil];
        BOOL result =[imageData writeToFile:filePath  atomically:YES]; // 保存成功会返回YES
        if(result){
          NSLog(@"图片保存成功");
          [pathes addObject:filePath];
          if(pathes.count == count){
            self.resolveBlock(pathes);
            self.resolveBlock = nil;
          }
        }else{
          if(self.rejectBlock){
            self.rejectBlock(@"-1", @"图片保存失败", nil);
            self.rejectBlock = nil;
          }
          
        }
        
      }else{
        NSArray* arr = [fileName componentsSeparatedByString:@"."];
        NSString* name = [NSString stringWithFormat:@"%@.jpg",arr.firstObject];
        NSString *filePath = [NSTemporaryDirectory()stringByAppendingPathComponent:name];
        [fileManager removeItemAtPath:filePath error:nil];
        BOOL result =[[CompressImageTool zipNSDataWithImage:[UIImage imageWithData:imageData]] writeToFile:filePath   atomically:YES]; // 保存成功会返回YES
        if(result){
          NSLog(@"图片保存成功");
          [pathes addObject:filePath];
          if(pathes.count == count){
            self.resolveBlock(pathes);
            self.resolveBlock = nil;
          }
        }else{
          if(self.rejectBlock){
            self.rejectBlock(@"-1", @"图片保存失败", nil);
            self.rejectBlock = nil;
          }
        }
      }
    } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
      if(error){
        if(self.rejectBlock){
          self.rejectBlock(@"-2", @"原图获取失败", nil);
          self.rejectBlock = nil;
        }
      }
      
    }];
    
  }
  
  
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(PHAsset *)outAsset{
  
  PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
  options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
  PHImageManager *manager = [PHImageManager defaultManager];
  [manager requestAVAssetForVideo:outAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
    AVURLAsset *urlAsset = (AVURLAsset *)asset;
    NSURL *url = urlAsset.URL;

    NSLog(@"%@",url.absoluteString);
    NSArray* arr = [url.path componentsSeparatedByString:@"/"];
    NSString* videoName = arr.lastObject;
    arr = [videoName componentsSeparatedByString:@"."];
    NSString* timeStamp = [self getNowTimeTimestamp];
    NSString* name = [NSString stringWithFormat:@"%@_cover.png",timeStamp];
    videoName = [NSString stringWithFormat:@"%@_video.mp4",timeStamp];
    NSString *filePath = [NSTemporaryDirectory()stringByAppendingPathComponent:name];
    BOOL result =[UIImagePNGRepresentation(coverImage) writeToFile:filePath   atomically:YES]; // 保存成功会返回YES
    if (result == YES) {
      NSLog(@"视频封面保存成功");
      NSLog(@"视频导出到本地完成,沙盒路径为:%@",url.absoluteString);
      self.resolveBlock(@{@"coverImage":filePath,@"videoPath":url.absoluteString});
      self.resolveBlock = nil;
      [self->_assetDic setValue:outAsset forKey:url.absoluteString];
    }else{
      if(self.rejectBlock){
        self.rejectBlock(@"-5", @"封面保存失败", nil);
        self.rejectBlock = nil;
      }
    }
  }];
  // open this code to send video / 打开这段代码发送视频
//  [[TZImageManager manager] getVideoOutputPathWithAsset:asset presetName:AVAssetExportPresetMediumQuality success:^(NSString *outputPath) {
//    // NSData *data = [NSData dataWithContentsOfFile:outputPath];
//    NSArray* arr = [outputPath componentsSeparatedByString:@"/"];
//    NSString* videoName = arr.lastObject;
//    arr = [videoName componentsSeparatedByString:@"."];
//    NSString* timeStamp = [self getNowTimeTimestamp];
//    NSString* name = [NSString stringWithFormat:@"%@_cover.png",timeStamp];
//    videoName = [NSString stringWithFormat:@"%@_video.mp4",timeStamp];
//    NSString *filePath = [NSTemporaryDirectory()stringByAppendingPathComponent:name];
//    NSString *videoPath = [NSTemporaryDirectory()stringByAppendingPathComponent:videoName];
//
//
//    //[[NSFileManager defaultManager] moveItemAtURL:outputPath toURL:videoPath error:nil];
//    BOOL result =[UIImagePNGRepresentation(coverImage) writeToFile:filePath   atomically:YES]; // 保存成功会返回YES
//    if (result == YES) {
//      NSLog(@"视频封面保存成功");
//      NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
//      self.resolveBlock(@{@"coverImage":filePath,@"videoPath":outputPath});
//      self.resolveBlock = nil;
//    }else{
//      if(self.rejectBlock){
//        self.rejectBlock(@"-5", @"封面保存失败", nil);
//        self.rejectBlock = nil;
//      }
//    }
//    [SVProgressHUD dismiss];
//  } failure:^(NSString *errorMessage, NSError *error) {
//    NSLog(@"视频导出失败:%@,error:%@",errorMessage, error);
//    if(self.rejectBlock){
//      self.rejectBlock(@"-4", @"视频导出失败", nil);
//      self.rejectBlock = nil;
//    }
//    [SVProgressHUD dismiss];
//  }];
}

- (BOOL)isAssetCanSelect:(PHAsset *)asset{
  if(asset.mediaType ==  PHAssetMediaTypeVideo){
    NSTimeInterval duration = asset.duration;
    return  duration<= self.maxVideoTime;
  }
  
  return YES;
}

- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker{
  NSLog(@"cancel");
  if(self.rejectBlock){
    self.rejectBlock(@"-3", @"用户取消选择", nil);
    self.rejectBlock = nil;
  }
  
}


-(NSString *)getNowTimeTimestamp{
  
  NSDate *datenow = [NSDate date];//现在时间,你可以输出来看下是什么格式
  
  NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
  
  return timeSp;
  
}

#pragma mark - react module
RCT_EXPORT_MODULE();

-(dispatch_queue_t)methodQueue{
  return dispatch_get_main_queue();
}
@end
