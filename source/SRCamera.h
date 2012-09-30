//
//  SRCamera.h
//
//  Copyright (c) 2012 Sean Ridenour. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SRCamera : NSObject

@property (nonatomic, readonly) AVCaptureDeviceInput *deviceInput;

@property (nonatomic, readonly) AVCaptureDevicePosition cameraPosition;

@property (nonatomic, readwrite, assign) AVCaptureFlashMode flashMode;
@property (nonatomic, readonly) BOOL hasFlash;

@property (nonatomic, readonly) BOOL focusPointOfInterestSupported;
@property (nonatomic, readonly) BOOL exposurePointOfInterestSupported;

@property (nonatomic, readwrite, assign) CGPoint focusPointOfInterest;
@property (nonatomic, readwrite, assign) CGPoint exposurePointOfInterest;

+ (SRCamera *)cameraWithCaptureDevice:(AVCaptureDevice *)captureDevice;
+ (SRCamera *)cameraWithPosition:(AVCaptureDevicePosition)position;

- (id)initWithCaptureDevice:(AVCaptureDevice *)captureDevice;
- (id)initWithCameraPosition:(AVCaptureDevicePosition)position;

@end
