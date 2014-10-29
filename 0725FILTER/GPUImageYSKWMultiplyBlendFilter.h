#import "GPUImageFilter.h"

extern NSString *const kGPUImageYSKWMultiplyBlendFragmentShaderString;

@interface GPUImageYSKWMultiplyBlendFilter : GPUImageFilter
{
	CGFloat uniformHueCenter;
	CGFloat uniformR;
	CGFloat uniformG;
	CGFloat uniformB;
	
}
@property(nonatomic, readwrite) CGFloat hue;
@end
