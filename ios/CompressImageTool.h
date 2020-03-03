//
//  CompressImageTool.h
//  QSY553
//
//  Created by 龙丰 on 2018/8/14.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface CompressImageTool : NSObject

+(NSData *)zipNSDataWithImage:(UIImage *)sourceImage;
+(NSData *)zipNSDataToJPG:(UIImage *)sourceImage;
@end
