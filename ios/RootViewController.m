//
//  RootViewController.m
//  Picker
//
//  Created by ns on 2020/3/2.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import "RootViewController.h"
#import <TZImagePickerController.h>
#import "TZImageUploadOperation.h"
#import "CompressImageTool.h"
@interface RootViewController ()<TZImagePickerControllerDelegate>
@property(nonatomic,strong)TZImagePickerController* imagePickerVc;
@property(nonatomic,strong)UIImageView* imageView;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation RootViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
  [self.view addSubview:imageView];
  _imageView = imageView;
  
  UIButton* but = [UIButton buttonWithType:UIButtonTypeCustom];
  but.frame= CGRectMake(100, 200, 100, 50);
  but.backgroundColor = [UIColor redColor];
  [but addTarget:self action:@selector(clearCache) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:but];
  
}

-(void)viewDidAppear:(BOOL)animated{
  self.view.backgroundColor = [UIColor whiteColor];
  TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:6 delegate:self];
  
  //选取图片
//  imagePickerVc.allowPickingOriginalPhoto = YES;
//  // 是否允许显示视频
//  imagePickerVc.allowPickingVideo = NO;
//  // 是否允许显示图片
//  imagePickerVc.allowPickingImage = YES;
  
  // 选取视频
    imagePickerVc.allowPickingOriginalPhoto = NO;
    // 是否允许显示视频
    imagePickerVc.allowPickingVideo = YES;
    // 是否允许显示图片
    imagePickerVc.allowPickingImage = NO;
  
  
  imagePickerVc.allowCameraLocation = NO;
  imagePickerVc.sortAscendingByModificationDate = NO;
  imagePickerVc.modalPresentationStyle = UIModalPresentationOverFullScreen;
  imagePickerVc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:imagePickerVc animated:YES completion:nil];
  
}


- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
  self.operationQueue = [[NSOperationQueue alloc] init];
  self.operationQueue.maxConcurrentOperationCount = 1;
  
  for (NSInteger i = 0; i < assets.count; i++) {
    PHAsset *asset = assets[i];
    [[TZImageManager manager] requestImageDataForAsset:asset completion:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
      
      
      NSString* fileName = [NSString stringWithFormat:@"%@",[asset valueForKey:@"filename"]];
      
      if(isSelectOriginalPhoto){
        NSString *filePath = [NSTemporaryDirectory()stringByAppendingPathComponent:fileName];
        BOOL result =[imageData writeToFile:filePath  atomically:YES]; // 保存成功会返回YES
        if(result){
          NSLog(@"图片保存成功");
        }
        
      }else{
        NSArray* arr = [fileName componentsSeparatedByString:@"."];
        NSString* name = [NSString stringWithFormat:@"%@.jpg",arr.firstObject];
        NSString *filePath = [NSTemporaryDirectory()stringByAppendingPathComponent:name];
        BOOL result =[[CompressImageTool zipNSDataWithImage:[UIImage imageWithData:imageData]] writeToFile:filePath   atomically:YES]; // 保存成功会返回YES
        if(result){
          NSLog(@"图片保存成功");
        }
      }
    } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
      
    }];
    
  }
  
  
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(PHAsset *)asset{
  
  // open this code to send video / 打开这段代码发送视频
  [[TZImageManager manager] getVideoOutputPathWithAsset:asset presetName:AVAssetExportPresetMediumQuality success:^(NSString *outputPath) {
    // NSData *data = [NSData dataWithContentsOfFile:outputPath];
    NSArray* arr = [outputPath componentsSeparatedByString:@"/"];
    NSString* name = [NSString stringWithFormat:@"%@.png",arr.lastObject];
    NSString *filePath = [NSTemporaryDirectory()stringByAppendingPathComponent:name];
    BOOL result =[UIImagePNGRepresentation(coverImage) writeToFile:filePath   atomically:YES]; // 保存成功会返回YES
    if (result == YES) {
      NSLog(@"视频封面保存成功");
    }
    
    NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
    // Export completed, send video here, send by outputPath or NSData
    // 导出完成，在这里写上传代码，通过路径或者通过NSData上传
  } failure:^(NSString *errorMessage, NSError *error) {
    NSLog(@"视频导出失败:%@,error:%@",errorMessage, error);
  }];
}

- (BOOL)isAssetCanSelect:(PHAsset *)asset{
  if(asset.mediaType ==  PHAssetMediaTypeVideo){
    NSTimeInterval duration = asset.duration;
    return  duration<= 120;
  }
  
  return YES;
}

- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker{
  NSLog(@"cancel");
  
}


-(void)clearCache{
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:NSTemporaryDirectory()];
  for (NSString *fileName in enumerator) {
      [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] error:nil];
  }
}
@end
