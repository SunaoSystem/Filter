//
//  AITrianglateFilter.m
//  0725FILTER
//
//  Created by 鈴木 龍彦 on 2014/10/06.
//  Copyright (c) 2014年 鈴木 龍彦. All rights reserved.
//

#import "AITrianglateFilter.h"

#import "AIStampFilter.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

#include  <opencv2/opencv.hpp>
#include  <opencv2/highgui/ios.h>
#include  <opencv2/legacy/legacy.hpp>
#include  <opencv2/imgproc/imgproc.hpp>
#include  <opencv2/imgproc/imgproc_c.h>
#include  <opencv2/core/core.hpp>

#import "UIImage+ColorAtPixel.h"


@implementation AITrianglateFilter

-(UIImage*)pass:(UIImage*)sourceImage{
    
    UIImage* passImage;
    
    passImage = [self preFilter:sourceImage];
    passImage = [self pyrSegFilter:passImage];
    passImage = [self adjustmentFilter:passImage];
    //特徴点検出
    passImage = [self triangleFilter:passImage];
    //最後の調整
    passImage = [self afterAdjustmentFilter:passImage];

    return passImage;
}

- (UIImage*)preFilter:(UIImage*)sourceImage{
    //領域分割前のフィルタ
    GPUImagePicture *sourcePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    GPUImageBoxBlurFilter *ssBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [ssBlurFilter setBlurRadiusInPixels:1];
    
    GPUImagePixellateFilter *ssMosaicFilter = [[GPUImagePixellateFilter alloc] init];
    //[ssMosaicFilter setFractionalWidthOfAPixel:0.005];
    //[ssMosaicFilter setFractionalWidthOfAPixel:0.02];
    [ssMosaicFilter setFractionalWidthOfAPixel:0.00];
    
    [sourcePicture addTarget:ssMosaicFilter];
    [ssMosaicFilter addTarget:ssBlurFilter];
    
    [ssBlurFilter useNextFrameForImageCapture];
    [sourcePicture processImage];
    
    UIImage* outputImage= [ssBlurFilter imageFromCurrentFramebuffer];
    
    return outputImage;
    
}

- (UIImage*)pyrSegFilter:(UIImage*)sourceImage{
    
    int level = 4;
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
    [ssBrightnessFilter setBrightness:0.1];
    
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


- (UIImage*)triangleFilter:(UIImage*)sourceImage{
    
    //--------エッジ検出---------
#pragma mark edgeDetection
    
    UIImage* colorImage = sourceImage;
    
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    //thirdFilter (白黒)
    GPUImageThresholdEdgeDetectionFilter *detectionFilter = [[GPUImageThresholdEdgeDetectionFilter alloc] init];
    [detectionFilter setThreshold:0.08];
    
    //画像加工実行その1
    [imagePicture addTarget:detectionFilter];
    
    [detectionFilter useNextFrameForImageCapture];
    [imagePicture processImage];
    
    //outputImageに書き出し
    UIImage* detectImage = [detectionFilter imageFromCurrentFramebuffer];
    
    //白い部分の座標抽出
    
    cv::Mat src_img;
    src_img = [self cvMatFromUIImage:detectImage];
    cv::Mat dst_img;
    
    cvtColor(src_img,dst_img,CV_RGB2GRAY);
    
    std::vector<cv::Point2f> points;
    
    //エッジ画像を抽出
    int count = 0;
    for(int y=0; y<dst_img.rows; y++){
        for(int x=0; x<dst_img.cols; x++){
            if(x == 0 || y == 0){
                   points.push_back(cv::Point2f(x,y));
            }
            else if(y == dst_img.rows-1 || x == dst_img.cols-1){
                    points.push_back(cv::Point2f(x,y));
            }
            else if(dst_img.at<unsigned char>( y,x ) > 128){
                count++;
                if(count > 30){
                    points.push_back(cv::Point2f(x,y));
                    count = 0;
                }
            }
        }
    }
    
    //--------- 三角形分割-----------
#pragma mark triangulate
    
    //Subdiv2D初期化
    cv::Subdiv2D subdiv;
    subdiv.initDelaunay(cv::Rect(0, 0, dst_img.cols, dst_img.rows));
    subdiv.insert(points);
    
    std::vector<cv::Vec6f> triangles;
    subdiv.getTriangleList(triangles);
    
    cv::Mat img(dst_img.rows,dst_img.cols,CV_8UC4,3);
    
    
    CGSize size = CGSizeMake(dst_img.cols,dst_img.rows);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    //CGRect rect = CGRectMake(0,0,dst_img.cols,dst_img.rows);
    //CGContextAddRect(context,rect);
    //CGContextFillPath(context);
    
    
    // 描画
    for(auto it = triangles.begin(); it != triangles.end(); it++)
    {
        cv::Point center;
        
        cv::Vec6f &vec = *it;
        cv::Point p1(vec[0], vec[1]);
        cv::Point p2(vec[2], vec[3]);
        cv::Point p3(vec[4], vec[5]);
        
        int p1_x,p1_y,p2_x,p2_y,p3_x,p3_y;
        
        p1_x = p1.x;
        p1_y = p1.y;
        p2_x = p2.x;
        p2_y = p2.y;
        p3_x = p3.x;
        p3_y = p3.y;
        
        int center_x = (p1.y+p2.y+p3.y)/3;
        if(center_x > dst_img.rows) center_x = dst_img.rows-1;
        if(center_x < 0) center_x = 1;
        
        int center_y = (p1.x+p2.x+p3.x)/3;
        if(center_y > dst_img.cols) center_y = dst_img.cols-1;
        if(center_y < 0) center_y = 1;
        
        CGPoint center_point = CGPointMake(center_y,center_x);
        
        UIColor* center_color = [colorImage colorAtPixel:center_point];
        
        CGFloat red_float;
        CGFloat green_float;
        CGFloat blue_float;
        CGFloat alpha_float;
        
        [center_color getRed:&red_float green:&green_float blue:&blue_float alpha:&alpha_float];
        
        uchar red = red_float*255;
        uchar green = green_float*255;
        uchar blue = blue_float*255;
        
        //cv::fillConvexPoly(img, pt, 3, cv::Scalar(red,green,blue),8,0);
        
        CGContextBeginPath(context);
        CGContextSetLineWidth(context, 1.5);
        CGContextSetRGBStrokeColor(context, red_float, green_float, blue_float, 1.0);
        CGContextMoveToPoint(context,p1_x,p1_y);
        CGContextAddLineToPoint(context,p2_x,p2_y);
        CGContextAddLineToPoint(context,p3_x,p3_y);
        CGContextStrokePath(context);
        //CGContextClosePath(context);

        CGContextBeginPath(context);
        CGContextSetRGBFillColor(context, red_float, green_float, blue_float, 1.0);
        CGContextMoveToPoint(context,p1_x,p1_y);
        CGContextAddLineToPoint(context,p2_x,p2_y);
        CGContextAddLineToPoint(context,p3_x,p3_y);
        CGContextFillPath(context);
        //CGContextClosePath(context);
        

        
        //cv::circle(img, cv::Point(center_y,center_x), 2, cv::Scalar(0,0,200), 3, 4);
        
        /*
        cv::line(img, p1, p2, cv::Scalar(0,255,0));
        cv::line(img, p2, p3, cv::Scalar(0,255,0));
        cv::line(img, p3, p1, cv::Scalar(0,255,0));
        */
        
        //NSLog(@"R=%d G=%d B=%d", red, green, blue);
        //NSLog(@"center_y=%d center_x=%d",center_y, center_x);
        
    }
    
    
    
    UIImage* outputImage;
    
    //outputImage = [self UIImageFromCVMat:color_img];
    CGImageRef imgRef = CGBitmapContextCreateImage (context);
    outputImage =  [UIImage imageWithCGImage:imgRef];
    
    return outputImage;
}

- (UIImage*)afterAdjustmentFilter:(UIImage*)sourceImage{
    //イメージ
    GPUImagePicture *imagePicture = [[GPUImagePicture alloc] initWithImage:sourceImage];
    
    GPUImageUnsharpMaskFilter *ssBlurFilter = [[GPUImageUnsharpMaskFilter alloc] init];
    [ssBlurFilter setBlurRadiusInPixels:1.0];
    [ssBlurFilter setIntensity:1.0];
    
    [imagePicture addTarget:ssBlurFilter];
    
    [ssBlurFilter useNextFrameForImageCapture];
    [imagePicture processImage];
    
    UIImage* outputImage = [ssBlurFilter imageFromCurrentFramebuffer];
    
    return outputImage;
}



//UIImage->cvMatに変換
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

//cvMat->UIImageに変換
- (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
