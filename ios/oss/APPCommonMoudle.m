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
RCT_REMAP_METHOD(uploadFile,
                 filePath:(NSString*)path
                 findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject){
  [[OSSManager sharedSingleton] uploadFile:path complect:^(NSString * _Nonnull remotePath) {
    if(remotePath){
      resolve(remotePath);
    }else{
      reject(@"-1",@"上传失败",nil);
    }
  }];
 
}


RCT_REMAP_METHOD(uploadFileArr,
                 fileArr:(NSArray*)paths
                 findEventsWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject){
  
  NSMutableArray *imageURLs= [NSMutableArray array];
  NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithCapacity:paths.count];
  dispatch_group_t group = dispatch_group_create();
  for (NSString *path in paths) {
      dispatch_group_enter(group);
      [[OSSManager sharedSingleton] uploadFile:path complect:^(NSString * _Nonnull remotePath) {
       if(remotePath){
         //resolve(remotePath);
         dic[path] = remotePath;
       }else{
        // reject(@"-1",@"上传失败",nil);
         dic[path] = @"";
       }
        dispatch_group_leave(group);
     }];
      
  }
  dispatch_group_notify(group,dispatch_get_main_queue(),^{
    NSLog(@"上传完成");
    for (NSString* path in paths) {
      [imageURLs addObject: dic[path]];
    }
    resolve(imageURLs);
  });
 
 
}

@end
