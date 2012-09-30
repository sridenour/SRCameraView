//
//  UIImage+SRImageProcess.h
//
//  Copyright (c) 2012 Sean Ridenour. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

typedef enum {
	kSRImageProcessScaleAspectFill = UIViewContentModeScaleAspectFill,
	kSRImageProcessScaleAspectFit = UIViewContentModeScaleAspectFit,
	kSRImageProcessScaleToFill = UIViewContentModeScaleToFill
} SRImageProcessScaleMode;

@interface UIImage (SRImageProcess)

+ (UIImage *)imageWithCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;

+ (UIImage *)image:(UIImage *)image scaledToSize:(CGSize)size scaleMode:(SRImageProcessScaleMode)scaleMode;

@end
