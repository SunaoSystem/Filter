//
//  AIaburaeFilter.m
//  0725FILTER
//
//  Created by 鈴木 龍彦 on 2014/09/30.
//  Copyright (c) 2014年 鈴木 龍彦. All rights reserved.
//

#import "AIaburaeFilter.h"

#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#include  <opencv2/opencv.hpp>
#include  <opencv2/highgui/ios.h>
#include  <opencv2/legacy/legacy.hpp>
#include  <opencv2/imgproc/imgproc.hpp>
#include  <opencv2/imgproc/imgproc_c.h>
#include  <opencv2/core/core.hpp>

@interface AIAburaeFilter (){
    
}

@end

@implementation AIAburaeFilter

#pragma mark pass

-(UIImage*)pass:(UIImage*)sourceImage{
    
    UIImage* passImage;
    //領域分割前の調整
    passImage = [self preFilter:sourceImage];
    //領域分割(openCV)
    passImage = [self pyrSegFilter:passImage];
    //色調整
    passImage = [self ajustmentFilter:passImage];

    return passImage;
}


//-----------------------------------------------

- (UIImage*)preFilter:(UIImage*)sourceImage{
    //領域分割前のフィルタ
    GPUImagePicture *sourcePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    //ぼかしフィルター宣言
    GPUImageBoxBlurFilter *ssBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    //ぼかし度の変更
    [ssBlurFilter setBlurRadiusInPixels:1];
    
    //ピクセレート（モザイク化)フィルター宣言
    GPUImagePixellateFilter *ssMosaicFilter = [[GPUImagePixellateFilter alloc] init];
    //[ssMosaicFilter setFractionalWidthOfAPixel:0.003]; //SewingFilter
    //[ssMosaicFilter setFractionalWidthOfAPixel:0.008]; //KnitFilter
    //[ssMosaicFilter setFractionalWidthOfAPixel:0.02];  //縫い目大きめのKnitFilter
    [ssMosaicFilter setFractionalWidthOfAPixel:0.00];  //AburaeFilter
    
    [sourcePicture addTarget:ssMosaicFilter];
    [ssMosaicFilter addTarget:ssBlurFilter];
    
    [ssBlurFilter useNextFrameForImageCapture];
    [sourcePicture processImage];
    
    UIImage* outputImage= [ssBlurFilter imageFromCurrentFramebuffer];
    
    return outputImage;
    
}

- (UIImage*)pyrSegFilter:(UIImage*)sourceImage{
    //ピラミッドレベル
    int level = 5;
    double threshold1,threshold2;
    IplImage *ipl_source, *ipl, *ipl_edit, *ipl_resize;
    CvMemStorage *storage=0;
    CvSeq *comp =0;
    //CvRect roi;
    
    
    //UIIMage→IplImage
    ipl_source = [self IplImageFromUIImage:sourceImage];
    ipl = cvCreateImage(cvSize(ipl_source->width & -(1 << level),ipl_source->height & -(1 << level)), IPL_DEPTH_8U, 3);
    ipl_resize = cvCreateImage(cvSize(ipl_source->width,ipl_source->height),IPL_DEPTH_8U, 3);
    cvResize(ipl_source, ipl);
    
    //出力用画像領域確保
    ipl_edit = cvCloneImage (ipl);
    storage = cvCreateMemStorage (0);
    //閾値設定
    threshold1 = 255.0;
    threshold2 = 5.0;
    
    
    //領域分割実行
    cvPyrSegmentation(ipl, ipl_edit, storage, &comp, level, threshold1, threshold2);
    
    //元の大きさに戻す
    cvResize(ipl_edit, ipl_resize);
    
    //IplImage→UIImage
    UIImage* outputImage = [self UIImageFromIplImage:ipl_resize];
    
    cvReleaseImage(&ipl);
    cvReleaseImage(&ipl_edit);
    cvReleaseMemStorage (&storage);
    
    return outputImage;
    
}

// UIImage -> IplImage
- (IplImage*)IplImageFromUIImage:(UIImage*)image {
    
    CGImageRef imageRef = image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    IplImage *iplimage = cvCreateImage(cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4 );
    
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData,
                                                    iplimage->width,
                                                    iplimage->height,
                                                    iplimage->depth,
                                                    iplimage->widthStep,
                                                    colorSpace,
                                                    kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef);
    
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

// IplImage -> UIImage変換
- (UIImage*)UIImageFromIplImage:(IplImage*)image {
    
    CGColorSpaceRef colorSpace;
    if (image->nChannels == 1)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        //BGRになっているのでRGBに変換
        cvCvtColor(image, image, CV_BGR2RGB);
    }
    
    NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(image->width,
                                        image->height,
                                        image->depth,
                                        image->depth * image->nChannels,
                                        image->widthStep,
                                        colorSpace,
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault
                                        );
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return ret;
}

- (UIImage*)ajustmentFilter:(UIImage*)sourceImage{
    //イメージ
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    GPUImageContrastFilter *ssContrastFilter = [[GPUImageContrastFilter alloc] init];
    [ssContrastFilter setContrast:1.5];
    
    GPUImageBrightnessFilter *ssBrightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [ssBrightnessFilter setBrightness:0.0];
    
    GPUImageSaturationFilter *ssSaturationFilter = [[GPUImageSaturationFilter alloc] init];
    [ssSaturationFilter setSaturation:1.8];
    
    GPUImagePosterizeFilter *ssPosterizeFilter = [[GPUImagePosterizeFilter alloc] init];
    [ssPosterizeFilter setColorLevels:100];
    
    GPUImageUnsharpMaskFilter *ssBlurFilter = [[GPUImageUnsharpMaskFilter alloc] init];
    [ssBlurFilter setBlurRadiusInPixels:1.0];
    [ssBlurFilter setIntensity:0.8];
    
    [imagePicture addTarget:ssBrightnessFilter];
    [ssBrightnessFilter addTarget:ssContrastFilter];
    [ssContrastFilter addTarget:ssBlurFilter];
    [ssBlurFilter addTarget:ssSaturationFilter];
    [ssSaturationFilter addTarget:ssPosterizeFilter];
    
    [ssPosterizeFilter useNextFrameForImageCapture];
    [imagePicture processImage];
    
    UIImage* outputImage = [ssPosterizeFilter imageFromCurrentFramebuffer];
    
    return outputImage;
}

@end
