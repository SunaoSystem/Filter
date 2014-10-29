//
//  AISewingFilter.m
//  0725FILTER
//
//  Created by 鈴木 龍彦 on 2014/10/01.
//  Copyright (c) 2014年 鈴木 龍彦. All rights reserved.
//

#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#include  <opencv2/opencv.hpp>
#include  <opencv2/highgui/ios.h>
#include  <opencv2/legacy/legacy.hpp>
#include  <opencv2/imgproc/imgproc.hpp>
#include  <opencv2/imgproc/imgproc_c.h>
#include  <opencv2/core/core.hpp>

#import "AISewingFilter.h"

@implementation AISewingFilter

-(UIImage*)pass:(UIImage*)sourceImage{
    
    UIImage* passImage;
    UIImage* edgeImage;
    
    //領域分割前の調整
    passImage = [self preFilter:sourceImage];
    //領域分割(openCV)
    passImage = [self pyrSegFilter:passImage];
    //色調整
    passImage = [self adjustmentFilter:passImage];
    //輪郭検出
    edgeImage = [self edgeDetectionFilter:passImage];
    //輪郭検出画像とのブレンド
    passImage = [self blendingFilter:passImage secondSource:edgeImage];
    //色調整その2
    passImage = [self secondAjustmentFilter:passImage];
    //テクスチャイメージの調整
    UIImage* txtImage = [UIImage imageNamed:@"texture.jpg"];
    txtImage = [self textureFilter:txtImage];
    //テクスチャ画像とのブレンド
    passImage = [self txtBlendFilter:passImage secondSource:txtImage];
    
    return passImage;
}

- (UIImage*)preFilter:(UIImage*)sourceImage{
    //領域分割前のフィルタ
    GPUImagePicture *sourcePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    GPUImageBoxBlurFilter *ssBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [ssBlurFilter setBlurRadiusInPixels:0];
    
    GPUImagePixellateFilter *ssMosaicFilter = [[GPUImagePixellateFilter alloc] init];
    [ssMosaicFilter setFractionalWidthOfAPixel:0.005];
    //[ssMosaicFilter setFractionalWidthOfAPixel:0.02];
    //[ssMosaicFilter setFractionalWidthOfAPixel:0.00];
    
    [sourcePicture addTarget:ssMosaicFilter];
    [ssMosaicFilter addTarget:ssBlurFilter];
    
    [ssBlurFilter useNextFrameForImageCapture];
    [sourcePicture processImage];
    
    UIImage* outputImage= [ssBlurFilter imageFromCurrentFramebuffer];
    
    return outputImage;
    
}

- (UIImage*)pyrSegFilter:(UIImage*)sourceImage{
    
    int level = 3;
    double threshold1,threshold2;
    IplImage *ipl_source, *ipl_adjustSize, *ipl_edit, *ipl_resize;
    CvMemStorage *storage=0;
    CvSeq *comp =0;
    //CvRect roi;
    
    
    //UIIMage→IplImage
    ipl_source = [self IplImageFromUIImage:sourceImage];
    //大きさをcvPyrSegmentationが使えるものに変更
    ipl_adjustSize = cvCreateImage(cvSize(ipl_source->width & -(1 << level),
                               ipl_source->height & -(1 << level)),
                               IPL_DEPTH_8U, 3);
    //ipl_sourceの大きさをiplに変更
    cvResize(ipl_source, ipl_adjustSize);
    
    //出力用画像領域確保
    ipl_edit = cvCloneImage (ipl_adjustSize);
    storage = cvCreateMemStorage (0);
    threshold1 = 255.0;
    threshold2 = 5.0;
    
    
    //領域分割実行
    cvPyrSegmentation(ipl_adjustSize, ipl_edit, storage, &comp, level, threshold1, threshold2);
    
    //もとの大きさに戻すためのIplImage
    ipl_resize = cvCreateImage(cvSize(ipl_source->width,ipl_source->height),IPL_DEPTH_8U, 3);
    //元の大きさに戻す
    cvResize(ipl_edit, ipl_resize);
    
    
    
    //IplImage→UIImage
    UIImage* outputImage = [self UIImageFromIplImage:ipl_resize];
    
    cvReleaseImage(&ipl_adjustSize);
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

- (UIImage*)adjustmentFilter:(UIImage*)sourceImage{
    //イメージ
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    //モザイクフィルター
    /*GPUImagePixellateFilter *ssMosaicFilter = [[GPUImagePixellateFilter alloc] init];
     [ssMosaicFilter setFractionalWidthOfAPixel:0.003];*/
    
    /*GPUImagePolkaDotFilter *ssMosaicFilter = [[GPUImagePolkaDotFilter alloc] init];
     [ssMosaicFilter setDotScaling:0.5];*/
    
    GPUImageContrastFilter *ssContrastFilter = [[GPUImageContrastFilter alloc] init];
    [ssContrastFilter setContrast:1.8];
    
    GPUImageBrightnessFilter *ssBrightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [ssBrightnessFilter setBrightness:0.0];
    
    GPUImageSaturationFilter *ssSaturationFilter = [[GPUImageSaturationFilter alloc] init];
    [ssSaturationFilter setSaturation:1.8];
    
    GPUImagePosterizeFilter *ssPosterizeFilter = [[GPUImagePosterizeFilter alloc] init];
    [ssPosterizeFilter setColorLevels:7];
    
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

- (UIImage*)edgeDetectionFilter:(UIImage*)sourceImage{
    
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    //輪郭検出フィルター
    GPUImageSobelEdgeDetectionFilter *ssATFilter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
    [ssATFilter setTexelHeight:0.0004];
    [ssATFilter setTexelWidth:0.0000];
    GPUImageColorInvertFilter *ssInvertFilter = [[GPUImageColorInvertFilter alloc] init];
    GPUImageEmbossFilter *ssEmbossFilter = [[GPUImageEmbossFilter alloc] init];
    GPUImageUnsharpMaskFilter *ssBlurFilter = [[GPUImageUnsharpMaskFilter alloc] init];
    [ssBlurFilter setBlurRadiusInPixels:2.8];
    [ssBlurFilter setIntensity:2.0];
    
    
    [imagePicture addTarget:ssATFilter];
    [ssATFilter addTarget:ssInvertFilter];
    [ssInvertFilter addTarget:ssBlurFilter];
    //[ssInvertFilter addTarget:ssEmbossFilter];
    [ssBlurFilter useNextFrameForImageCapture];
    [imagePicture processImage];
    
    UIImage* outputImage = [ssBlurFilter imageFromCurrentFramebuffer];
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

-(UIImage*)secondAjustmentFilter:(UIImage*)sourceImage{
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    GPUImageBoxBlurFilter* ssBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [ssBlurFilter setBlurRadiusInPixels:3];
    GPUImageContrastFilter* ssContrastFilter = [[GPUImageContrastFilter alloc] init];
    [ssContrastFilter setContrast:1.0];
    
    [imagePicture addTarget:ssBlurFilter];
    [ssBlurFilter addTarget:ssContrastFilter];
    [ssContrastFilter useNextFrameForImageCapture];
    [imagePicture processImage];
    
    UIImage* thirdImage = [ssContrastFilter imageFromCurrentFramebuffer];
    return thirdImage;
}

-(UIImage*)textureFilter:(UIImage*)sourceImage{
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    //ぼかしフィルタ
    GPUImageBoxBlurFilter* txBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [txBlurFilter setBlurRadiusInPixels:0];
    //明るさフィルタ
    GPUImageBrightnessFilter* txBrightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [txBrightnessFilter setBrightness:0.0];
    //拡大フィルタ
    GPUImageTransformFilter *txTranceFilter = [[GPUImageTransformFilter alloc] init];
    
    CGAffineTransform txExpantion;
    txExpantion = CGAffineTransformMakeScale(1.1, 1.1);
    [txTranceFilter setAffineTransform:txExpantion];
    
    [imagePicture addTarget:txTranceFilter];
    [txTranceFilter addTarget:txBrightnessFilter];
    [txBrightnessFilter addTarget:txBlurFilter];
    [txBlurFilter useNextFrameForImageCapture];
    [imagePicture processImage];
    
    UIImage* textureImage = [txBlurFilter imageFromCurrentFramebuffer];
    return textureImage;
}

-(UIImage*)txtBlendFilter:(UIImage*)firstSourceImage secondSource:(UIImage*)secondSourceImage{
    GPUImagePicture *blendSource = [[GPUImagePicture alloc] initWithImage:firstSourceImage];
    GPUImagePicture *txtSource = [[GPUImagePicture alloc] initWithImage:secondSourceImage];
    
    GPUImageUnsharpMaskFilter *ssBlurFilter = [[GPUImageUnsharpMaskFilter alloc] init];
    [ssBlurFilter setBlurRadiusInPixels:2.8];
    [ssBlurFilter setIntensity:0.4];
    
    GPUImageMultiplyBlendFilter* blendFilter = [[GPUImageMultiplyBlendFilter alloc] init];
    
    [blendSource addTarget:blendFilter];
    [blendSource processImage];
    [txtSource addTarget:blendFilter];
    [txtSource processImage];
    
    [blendFilter useNextFrameForImageCapture];
    
    UIImage *finalImage = [blendFilter imageFromCurrentFramebufferWithOrientation:secondSourceImage.imageOrientation];
    
    return finalImage;
}


@end
