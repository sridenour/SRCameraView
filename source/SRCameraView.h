//
//  SRCameraView.h
//
//  Copyright (c) 2012 Sean Ridenour. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SRCamera.h"

@interface SRCameraView : UIView <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, readonly) AVCaptureSession *captureSession;

@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, copy) NSString *previewLayerGravity;

@property (nonatomic, readonly) SRCamera *frontCamera;
@property (nonatomic, readonly) SRCamera *rearCamera;
@property (nonatomic, readonly) SRCamera *currentCamera;
@property (nonatomic, readonly) AVCaptureDevicePosition currentCameraPosition;

// setting either point-of-interest's indicator image will automatically change this to YES
@property (nonatomic, readwrite, assign) BOOL shouldDrawPointsOfInterest;
// default is focusPoint.png, change to set your own indicator image
@property (nonatomic, strong) UIImage *focusPointOfInterestIndicator;
// default is exposurePoint.png, change to set your own indicator image
@property (nonatomic, strong) UIImage *exposurePointOfInterestIndicator;

// YES = live video preview will be paused, NO = live video preview will resume
@property (nonatomic, readwrite, assign) BOOL paused;

- (void)start;
- (void)stop;

- (void)useFrontCamera;
- (void)useRearCamera;
- (void)swapCameras;

- (void)setFocusPoint:(CGPoint)focusPoint;
- (void)setExposurePoint:(CGPoint)exposurePoint;

// Completion block will always be executed on the main thread
- (void)takePhotoWithCompletionBlock:(void (^)(UIImage *photo, UIImage *preview))takePhotoCompletionBlock;

@end
