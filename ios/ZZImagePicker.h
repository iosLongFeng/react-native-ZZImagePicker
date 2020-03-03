//
//  ZZImagePicker.h
//  Picker
//
//  Created by ns on 2020/3/3.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface ZZImagePicker : NSObject<RCTBridgeModule>
+(void)clearCache;
@end

NS_ASSUME_NONNULL_END
