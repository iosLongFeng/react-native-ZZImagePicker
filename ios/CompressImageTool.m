//
//  CompressImageTool.m
//  QSY553
//
//  Created by 龙丰 on 2018/8/14.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CompressImageTool.h"

@implementation CompressImageTool
//压缩图片
+(NSData *)zipNSDataWithImage:(UIImage *)sourceImage{
    //进行图像尺寸的压缩
    CGSize imageSize = sourceImage.size;//取出要压缩的image尺寸
    CGFloat width = imageSize.width;    //图片宽度
    CGFloat height = imageSize.height;  //图片高度
    //1.宽高大于1280(宽高比不按照2来算，按照1来算)
    if (width>1000||height>1000) {
        if (width>height) {
            CGFloat scale = height/width;
            width = 1000;
            height = width*scale;
        }else{
            CGFloat scale = width/height;
            height = 1000;
            width = height*scale;
        }
    //2.宽大于1280高小于1280
    }else if(width>1000||height<1000){
        CGFloat scale = height/width;
        width = 1000;
        height = width*scale;
    //3.宽小于1280高大于1280
    }else if(width<1000||height>1000){
        CGFloat scale = width/height;
        height = 1000;
        width = height*scale;
    //4.宽高都小于1280
    }else{
    }
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    [sourceImage drawInRect:CGRectMake(0,0,width,height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //进行图像的画面质量压缩
    NSData *data=UIImageJPEGRepresentation(newImage, 1.0);
    if (data.length>100*1024) {
        if (data.length>1024*1024) {//1M以及以上
            data=UIImageJPEGRepresentation(newImage, 0.7);
        }else if (data.length>512*1024) {//0.5M-1M
            data=UIImageJPEGRepresentation(newImage, 0.8);
        }else if (data.length>200*1024) {
            //0.25M-0.5M
            data=UIImageJPEGRepresentation(newImage, 0.9);
        }
    }
    return data;
}

+(NSData *)zipNSDataToJPG:(UIImage *)sourceImage{
  return UIImageJPEGRepresentation(sourceImage, 1.0);
}

@end
