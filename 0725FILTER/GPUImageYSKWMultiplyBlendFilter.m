#import "GPUImageYSKWMultiplyBlendFilter.h"

@implementation GPUImageYSKWMultiplyBlendFilter

NSString *const kGPUImageYSKWMultiplyBlendFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 uniform highp float overlayR;
 uniform highp float overlayG;
 uniform highp float overlayB;
 
 void main()
 {
     vec4 base = texture2D(inputImageTexture, textureCoordinate);
	 vec4 overlayer = vec4(overlayR, overlayG, overlayB, 1.0);
     
	 // multiply overlay
     gl_FragColor = overlayer * base + overlayer * (1.0 - base.a) + base * (1.0 - overlayer.a);
 }
);

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageYSKWMultiplyBlendFragmentShaderString]))
    {
		return nil;
    }
	
    uniformR = [filterProgram uniformIndex:@"overlayR"];
    uniformG = [filterProgram uniformIndex:@"overlayG"];
    uniformB = [filterProgram uniformIndex:@"overlayB"];
	
    self.hue = 0.14;
	
    return self;
}


#pragma mark -
#pragma mark Accessors

- (void)setHue:(CGFloat)hue
{
    _hue = hue; // 0 ~ 1
	
	UIColor *overlay = [[UIColor alloc] initWithHue:hue saturation:0.23 brightness:1.0 alpha:1.0];
	
	CGFloat r, g, b, a;
    [overlay getRed:&r green:&g blue:&b alpha:&a];
    
	[self setFloat:r forUniform:uniformR program:filterProgram];
    [self setFloat:g forUniform:uniformG program:filterProgram];
    [self setFloat:b forUniform:uniformB program:filterProgram];
}

@end
