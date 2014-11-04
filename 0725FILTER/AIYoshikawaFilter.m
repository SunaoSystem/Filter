//
//  AIYoshikawaFilter.m
//  0725FILTER
//
//  Created by 鈴木 龍彦 on 2014/10/27.
//  Copyright (c) 2014年 鈴木 龍彦. All rights reserved.
//

#import "AIYoshikawaFilter.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "GPUImageYSKWMultiplyBlendFilter.h"

@implementation AIYoshikawaFilter

-(UIImage*)pass:(UIImage*)sourceImage{
    
    UIImage* passImage;
    
    passImage = [self yoshikawaFilter:sourceImage];
    
    return passImage;

}

- (UIImage *)resizedImage:(UIImage *)image width:(CGFloat)width height:(CGFloat)height
{
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    [image drawInRect:CGRectMake(0.0, 0.0, width, height)];
    
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resizedImage;
}


- (UIImage*)yoshikawaFilter:(UIImage*)sourceImage{

    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    GPUImagePicture *blurPicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    GPUImageGaussianBlurFilter *blurFilter = [GPUImageGaussianBlurFilter new];
    GPUImageGaussianBlurFilter *blurFilter_02 = [GPUImageGaussianBlurFilter new];
    GPUImageColorInvertFilter *invertFilter = [GPUImageColorInvertFilter new];
    GPUImageSaturationFilter *saturationCutFilter = [GPUImageSaturationFilter new];
    GPUImageOpacityFilter *opacityFilter = [GPUImageOpacityFilter new];
    GPUImageOverlayBlendFilter *blendFilter = [GPUImageOverlayBlendFilter new];
    
    GPUImageToneCurveFilter *toneCurveFilter = [GPUImageToneCurveFilter new];
    [toneCurveFilter setPointsWithACV:@"yskwtonecirve"];
    GPUImageSaturationFilter *saturationFilter = [GPUImageSaturationFilter new];
    GPUImageHardLightBlendFilter *hardLightFilter = [GPUImageHardLightBlendFilter new];
    GPUImageBrightnessFilter *brightnessFilter = [GPUImageBrightnessFilter new];
    GPUImageContrastFilter *contrastFilter = [GPUImageContrastFilter new];
    
    GPUImageLinearBurnBlendFilter *linearBurnBlendFilter = [GPUImageLinearBurnBlendFilter new];
    
    GPUImagePicture *linearBlendBase;
    
    GPUImageYSKWMultiplyBlendFilter *hueFilter = [GPUImageYSKWMultiplyBlendFilter new];
    
    
    //---
    /*
    
    NSArray *red = [NSArray arrayWithObjects:
                    [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                    [NSValue valueWithCGPoint:CGPointMake(25. /255, 53./255)],
                    [NSValue valueWithCGPoint:CGPointMake(84./255, 141./255)],
                    [NSValue valueWithCGPoint:CGPointMake(148./255, 191./255)],
                    [NSValue valueWithCGPoint:CGPointMake(173./255, 212./255)],
                    [NSValue valueWithCGPoint:CGPointMake(204./255, 222./255)],
                    [NSValue valueWithCGPoint:CGPointMake(239./255, 242./255)],
                    [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)], nil];
    
    NSArray *green
    = [NSArray arrayWithObjects:
                      [NSValue valueWithCGPoint:CGPointMake(0.0,	  15. /255)],
                      [NSValue valueWithCGPoint:CGPointMake(33. /255, 66. /255)],
                      [NSValue valueWithCGPoint:CGPointMake(79. /255, 141./255)],
                      [NSValue valueWithCGPoint:CGPointMake(148./255, 217./255)],
                      [NSValue valueWithCGPoint:CGPointMake(199./255, 233./255)],
                      [NSValue valueWithCGPoint:CGPointMake(247./255, 242./255)],
                      [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)], nil];
    
    NSArray *blue = [NSArray arrayWithObjects:
                     [NSValue valueWithCGPoint:CGPointMake(0,		  60./255)],
                     [NSValue valueWithCGPoint:CGPointMake(31./255,  90./255)],
                     [NSValue valueWithCGPoint:CGPointMake(90./255, 143./255)],
                     [NSValue valueWithCGPoint:CGPointMake(148./255, 186./255)],
                     [NSValue valueWithCGPoint:CGPointMake(197./255, 212./255)],
                     [NSValue valueWithCGPoint:CGPointMake(1.0, 230./255)], nil];
    
    [toneCurveFilter setRedControlPoints:red];
    [toneCurveFilter setGreenControlPoints:green];
    [toneCurveFilter setBlueControlPoints:blue];
     
    */
    
    [blurFilter setBlurRadiusInPixels:70.0];
    [blurFilter_02 setBlurRadiusInPixels:70.0];
    [saturationCutFilter setSaturation:0];
    [saturationFilter setSaturation:0.8];
    [brightnessFilter setBrightness:0.08];
    [contrastFilter setContrast:1.11];
    
    
    //---
    
    
    // filter connections!
    
    
    //ぼかしイメージ作成
    
    [blurPicture addTarget:blurFilter];//ぼかし
    [blurFilter addTarget:blurFilter_02];//ぼかし
    [blurFilter_02 addTarget:invertFilter];//階調の反転
    [invertFilter addTarget:saturationCutFilter];//色相
    [saturationCutFilter addTarget:opacityFilter];//彩度
    [blurPicture processImage];
    
    /*[opacityFilter useNextFrameForImageCapture];
    UIImage* blurImage = [opacityFilter imageFromCurrentFramebuffer];*/
    
    [saturationCutFilter useNextFrameForImageCapture];
     UIImage* blurImage = [saturationCutFilter imageFromCurrentFramebuffer];

    //ぼかしイメージとsourceImageをブレンド
    
    GPUImagePicture *secondPicture = [[GPUImagePicture alloc] initWithImage:blurImage];
    
    [imagePicture addTarget:blendFilter];
    [imagePicture processImage];
    [secondPicture addTarget:blendFilter];
    [secondPicture processImage];
    
    [blendFilter useNextFrameForImageCapture];
    UIImage* blendImage = [blendFilter imageFromCurrentFramebufferWithOrientation:blurImage.imageOrientation];
    
    GPUImagePicture *blendPicture = [[GPUImagePicture alloc] initWithImage:blendImage];
    
    
    [blendPicture addTarget:toneCurveFilter];//トーンカーブ
    [toneCurveFilter addTarget:saturationFilter];//彩度
    //[saturationFilter addTarget:hardLightFilter];//ハードライト(？)
    [blendPicture processImage];
    [saturationFilter useNextFrameForImageCapture];
    UIImage* afterToneCurveImage = [saturationFilter imageFromCurrentFramebuffer];
    
    UIImage *blendBase = [UIImage imageNamed:@"Base-iPad.png"];
    blendBase = [self resizedImage:blendBase width:sourceImage.size.width height:sourceImage.size.height];
    
    GPUImagePicture *afterToneCurvePicture = [[GPUImagePicture alloc] initWithImage:afterToneCurveImage];
    GPUImagePicture *noisePicture = [[GPUImagePicture alloc] initWithImage:blendBase];
    
    [afterToneCurvePicture addTarget:hardLightFilter];
    [afterToneCurvePicture processImage];
    [noisePicture addTarget:hardLightFilter];
    [noisePicture processImage];
    
    [hardLightFilter useNextFrameForImageCapture];
    
    UIImage* linearBlendImage = [hardLightFilter imageFromCurrentFramebufferWithOrientation:afterToneCurveImage.imageOrientation];
    
    GPUImagePicture *linearBlendPicture = [[GPUImagePicture alloc] initWithImage:linearBlendImage];
    
    [linearBlendPicture addTarget:brightnessFilter];//明るさ
    [brightnessFilter addTarget:contrastFilter];//コントラスト
    [contrastFilter addTarget:hueFilter];//カラーを乗算
     
    [linearBlendPicture processImage];
    [hueFilter useNextFrameForImageCapture];
    UIImage* outputImage = [hueFilter imageFromCurrentFramebuffer];
    
    //UIImage* outputImage = blendImage;
    
    /*
    [blendPicture addTarget:toneCurveFilter];
    [blendPicture processImage];
    [contrastFilter useNextFrameForImageCapture];
    UIImage *outputImage = [ imageFromCurrentFramebuffer];
    */
    
    return outputImage;
}

@end
