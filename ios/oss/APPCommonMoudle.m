//
//  APPCommonMoudle.m
//  Picker
//
//  Created by ns on 2020/4/17.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import "APPCommonMoudle.h"
#import "OSSManager.h"
@implementation APPCommonMoudle
RCT_EXPORT_MODULE();
- (dispatch_queue_t)methodQueue{
  return dispatch_get_main_queue();
}
//RCT_REMAP_METHOD(uploadFile,
//                 filePath:(NSString*)path
//                 findEventsWithResolver:(RCTPromiseResolveBlock)resolve
//                 rejecter:(RCTPromiseRejectBlock)reject){
//  [[OSSManager sharedSingleton] uploadFile:path complect:^(NSString * _Nonnull remotePath) {
//    if(remotePath){
//      resolve(remotePath);
//    }else{
//      reject(@"-1",@"上传失败",nil);
//    }
//  }];
//
//}


RCT_REMAP_METHOD(uploadFileArr,
                 fileArr:(NSArray*)paths
                 findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject){
  
  if(paths==nil || paths.count==0){
    reject(@"-1",@"传入为空",nil);
    return;
  }
  [[OSSManager sharedSingleton] uploadFileArr:paths complect:^(NSArray * _Nonnull arr) {
    if(arr==nil){
      reject(@"-2",@"有文件上传失败",nil);
    }else{
      resolve(arr);
    }
  }];
 
 
}

@end
