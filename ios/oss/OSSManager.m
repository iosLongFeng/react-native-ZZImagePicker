//
//  OSSManager.m
//  Picker
//
//  Created by ns on 2020/4/17.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import "OSSManager.h"
#import <AliyunOSSiOS/OSSService.h>
@interface OSSManager()
@property (nonatomic, strong) OSSClient *client;
@property (nonatomic, copy) NSString* bucket;
@property (nonatomic, copy) NSString* endpoint;
@property (nonatomic, copy) NSString* prefix;
@end

@implementation OSSManager
+ (instancetype)sharedSingleton {
  static OSSManager *_sharedSingleton = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    //不能再使用alloc方法
    //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
    _sharedSingleton = [[super allocWithZone:NULL] init];
  });
  return _sharedSingleton;
}

-(void)config{
  [OSSLog enableLog];
  NSString* url = @"http://dev.blitzcrank.beiru168.com/api/v1/sts";
  NSURLSessionTask* task = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if(!error){
        NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"result = %@",str);
        NSDictionary* dic = [self dictionaryWithJsonString:str];
        if(dic && [dic[@"code"] intValue] == 200){
          [self configOSS:dic];
        }
      }
    });
  }];
  [task resume];
}

-(void)configOSS:(NSDictionary*)configDic{
  NSDictionary* data = configDic[@"data"];
  self.bucket = data[@"bucket"];
  self.endpoint = data[@"endpoint"];
  self.endpoint = [self.endpoint stringByReplacingOccurrencesOfString:@"http://" withString:@""];
  self.prefix = data[@"prefix"];
  NSString* sts = [NSString stringWithFormat:@"http://dev.blitzcrank.beiru168.com%@",data[@"stsUrl"]];
  OSSAuthCredentialProvider *credentialProvider = [[OSSAuthCredentialProvider alloc] initWithAuthServerUrl:sts];
  OSSClientConfiguration *cfg = [[OSSClientConfiguration alloc] init];
  cfg.maxRetryCount = 3;
  cfg.timeoutIntervalForRequest = 15;
  cfg.isHttpdnsEnable = NO;
  cfg.crc64Verifiable = YES;
  cfg.maxConcurrentRequestCount = 5;
  _client = [[OSSClient alloc] initWithEndpoint:data[@"endpoint"] credentialProvider:credentialProvider clientConfiguration:cfg];
}

-(void)uploadFile:(NSString*)filePath complect:(void(^)(NSString *))block{
  if(filePath == nil || _client==nil){
    block(nil);
    return;
  }
  NSString* fileType = [filePath pathExtension];
  NSString* name = [NSString stringWithFormat:@"%@.%@",[self uuidString],fileType];
  OSSPutObjectRequest * put = [OSSPutObjectRequest new];
  put.bucketName = self.bucket;
  put.objectKey = [NSString stringWithFormat:@"%@/%@",self.prefix,name];
  put.uploadingFileURL = [NSURL URLWithString:filePath];
  put.isAuthenticationRequired=true;
  OSSTask * putTask = [_client putObject:put];
  [putTask continueWithBlock:^id(OSSTask *task) {
    if (!task.error) {
      NSLog(@"upload object success!");
      NSString* remotePath = [NSString stringWithFormat:@"https://%@.%@/%@/%@",self.bucket,self.endpoint,self.prefix,name];
      NSLog(@"服务器地址为 %@",remotePath);
      block(remotePath);
    } else {
      NSLog(@"upload object failed, error: %@" , task.error);
      block(nil);
    }
    
    return nil;
  }];
}

-(void)uploadFileArr:(NSArray*)paths complect:(void(^)(NSArray *))block{
  if(_client==nil){
    block(nil);
    [self config];
    return;
  }
  NSMutableArray *imageURLs= [NSMutableArray array];
  NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithCapacity:paths.count];
  dispatch_group_t group = dispatch_group_create();
  for (NSString *path in paths) {
      dispatch_group_enter(group);
      [self uploadFile:path complect:^(NSString * _Nonnull remotePath) {
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
    bool haveFailure = false;
    for (NSString* path in paths) {
      if(path.length==0){
        haveFailure = true;
        break;
      }
      [imageURLs addObject: dic[path]];
    }
    if(haveFailure){
       block(nil);
    }else{
      block(imageURLs);
    }
    
  });
  
}



- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
  if (jsonString == nil) {
    return nil;
  }
  
  NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  NSError *err;
  NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                      options:NSJSONReadingMutableContainers
                                                        error:&err];
  if(err)
  {
    NSLog(@"json解析失败：%@",err);
    return nil;
  }
  return dic;
}

-(NSString *)uuidString{
  NSString *uuid = [[NSUUID UUID] UUIDString];
  uuid =  [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
  return uuid;
}



@end
