//
//  AIStampFilter.m
//  0725FILTER
//
//  Created by 鈴木 龍彦 on 2014/10/01.
//  Copyright (c) 2014年 鈴木 龍彦. All rights reserved.
//

#import "AIStampFilter.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

#include  <opencv2/opencv.hpp>
#include  <opencv2/highgui/ios.h>
#include  <opencv2/legacy/legacy.hpp>
#include  <opencv2/imgproc/imgproc.hpp>
#include  <opencv2/imgproc/imgproc_c.h>
#include  <opencv2/core/core.hpp>



@interface AIStampFilter (){
    
}

@end

@implementation AIStampFilter

-(UIImage*)pass:(UIImage*)sourceImage{
    
    UIImage* passImage;
    UIImage* edgeImage;
    
    //白黒変換
    passImage = [self monochromeFilter:sourceImage];
    //輪郭検出
    edgeImage = [self edgeDetectionFilter:passImage];
    //白黒画像と輪郭検出画像をブレンド
    passImage = [self blendingFilter:passImage secondSource:edgeImage];
    //調整・2値化
    passImage = [self bwAdjustmentFilter:passImage];
    
    return passImage;
}

-(UIImage*)monochromeFilter:(UIImage*)sourceImage{
    
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    //thirdFilter (白黒)
    GPUImageGrayscaleFilter *grayScaleFilter = [[GPUImageGrayscaleFilter alloc] init];
    
    //画像加工実行その1
    [imagePicture addTarget:grayScaleFilter];
    
    [grayScaleFilter useNextFrameForImageCapture];
    [imagePicture processImage];
    
    //outputImageに書き出し
    UIImage* outputImage = [grayScaleFilter imageFromCurrentFramebuffer];
    
    NSAssert(outputImage != nil, @"outputImageがnilじゃないはずがおかしいよ");
    return outputImage;
}

-(UIImage*)edgeDetectionFilter:(UIImage*)sourceImage{
    
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    //sobelEdge
    GPUImageSobelEdgeDetectionFilter *sobelEdgeDetectionFilter = [[GPUImageSobelEdgeDetectionFilter alloc]init];
    //色反転
    GPUImageColorInvertFilter *invertFilter = [[GPUImageColorInvertFilter alloc] init];
    
    [imagePicture addTarget:sobelEdgeDetectionFilter];
    [sobelEdgeDetectionFilter addTarget:invertFilter];
    
    [invertFilter useNextFrameForImageCapture];
    [imagePicture processImage];
    UIImage* outputImage = [invertFilter imageFromCurrentFramebuffer];
    
    return outputImage;
}

- (UIImage*)blendingFilter:(UIImage*)firstSourceImage secondSource:(UIImage*)secondSourceImage{
    
    GPUImagePicture *firstBlendSource = [[GPUImagePicture alloc] initWithImage:firstSourceImage];
    GPUImagePicture *secondBlendSource = [[GPUImagePicture alloc] initWithImage:secondSourceImage];
    
    GPUImageMultiplyBlendFilter* blendFilter = [[GPUImageMultiplyBlendFilter alloc] init];
    
    [firstBlendSource addTarget:blendFilter];
    [firstBlendSource processImage];
    [secondBlendSource addTarget:blendFilter];
    [secondBlendSource processImage];
    
    [blendFilter useNextFrameForImageCapture];
    UIImage* blendImage = [blendFilter imageFromCurrentFramebufferWithOrientation:secondSourceImage.imageOrientation];
    
    
    //self.imageView.image = blendImage;
    return blendImage;
}

-(UIImage*)bwAdjustmentFilter:(UIImage*)sourceImage{
    
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [brightnessFilter setBrightness:0.1];
    GPUImageContrastFilter *contrastFilter = [[GPUImageContrastFilter alloc]init];
    [contrastFilter setContrast:1.8];
    GPUImageUnsharpMaskFilter *blurFilter = [[GPUImageUnsharpMaskFilter alloc] init];
    [blurFilter setBlurRadiusInPixels:2.0];
    [blurFilter setIntensity:0.1];
    GPUImagePosterizeFilter *posterizeFilter=[[GPUImagePosterizeFilter alloc] init];
    //2値化
    [posterizeFilter setColorLevels:1];
    
    [imagePicture addTarget:contrastFilter];
    [contrastFilter addTarget:blurFilter];
    [blurFilter addTarget:brightnessFilter];
    [brightnessFilter addTarget:posterizeFilter];
    
    [imagePicture processImage];
    [posterizeFilter useNextFrameForImageCapture];
    UIImage* outputImage = [posterizeFilter imageFromCurrentFramebuffer];
    
    return outputImage;
}

@end
