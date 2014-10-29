//
//  ViewController.m
//  0725FILTER
//
//  Created by 鈴木 龍彦 on 2014/07/25.
//  Copyright (c) 2014年 鈴木 龍彦. All rights reserved.
//

#import "ViewController.h"
#import "AIAburaeFilter.h"
#import "AIKnitFIlter.h"
#import "AISewingFIlter.h"
#import "AIStampFilter.h"
#import "AITrianglateFilter.h"
#import "AIYoshikawaFilter.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>

#include  <opencv2/opencv.hpp>
#include  <opencv2/highgui/ios.h>
#include  <opencv2/legacy/legacy.hpp>
#include  <opencv2/imgproc/imgproc.hpp>
#include  <opencv2/imgproc/imgproc_c.h>
#include  <opencv2/core/core.hpp>

@interface ViewController (){
    
   // UIImage *inputImage;
    /*UIImage *outputImage;
    UIImage *txtImage;
    
    UIImage *sisyuFirstOutputImage;
    
    UIImage *basicImage;
    UIImage *firstImage;
    UIImage *secondImage;
    UIImage *blendImage;
    
    UIImage *thirdImage;
    UIImage *textureImage;
    
    UIImage *forthImage;*/
    
    AIAburaeFilter* aiAburaeFilter;
    AIKnitFilter* aiKnitFilter;
    AISewingFilter* aiSewingFilter;
    AIStampFilter* aiStampFilter;
    AITrianglateFilter * aiTrianglateFilter;
    AIYoshikawaFilter * aiYoshikawaFilter;
    
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"viewDidLoad");
    
    UIImage* inputImage = [UIImage imageNamed:@"yskw_test_photo.jpg"];
    UIImage* outputImage;
    aiAburaeFilter = [[AIAburaeFilter alloc]init];
    aiKnitFilter = [[AIKnitFilter alloc] init];
    aiSewingFilter = [[AISewingFilter alloc] init];
    aiStampFilter = [[AIStampFilter alloc] init];
    aiTrianglateFilter = [[AITrianglateFilter alloc]init];
    aiYoshikawaFilter = [[AIYoshikawaFilter alloc] init];
    
    
    //outputImage = [aiAburaeFilter pass:inputImage];
    //outputImage = [aiKnitFilter pass:inputImage];
    //outputImage = [aiSewingFilter pass:inputImage];
    //outputImage = [aiStampFilter pass:inputImage];
    //outputImage = [aiTrianglateFilter pass:inputImage];
    outputImage = [aiYoshikawaFilter pass:inputImage];
    
    self.imageView.image = outputImage;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end

