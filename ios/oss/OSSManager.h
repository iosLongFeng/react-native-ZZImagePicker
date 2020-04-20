//
//  OSSManager.h
//  Picker
//
//  Created by ns on 2020/4/17.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OSSManager : NSObject
+ (instancetype)sharedSingleton;
-(void)config;
//-(void)uploadFile:(NSString*)filePath complect:(void(^)(NSString *))block;
-(void)uploadFileArr:(NSArray*)fielArr complect:(void(^)(NSArray *))block;
@end

NS_ASSUME_NONNULL_END
