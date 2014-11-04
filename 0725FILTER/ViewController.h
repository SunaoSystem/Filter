//
//  ViewController.h
//  0725FILTER
//
//  Created by 鈴木 龍彦 on 2014/07/25.
//  Copyright (c) 2014年 鈴木 龍彦. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

//イメージビュー

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIImageView *sampleImageView;


//Filter 01 明るさ調節用スライダー

//明るさの数値を表示するラベル
- (IBAction)startFilter:(id)sender;

@end
