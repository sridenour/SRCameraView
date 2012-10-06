//
//  SRCameraView.h
/*
 Copyright (c) 2012 Sean Ridenour
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

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

// Does this device have a camera?
+ (BOOL)deviceHasCamera;

- (void)start;
- (void)stop;

- (void)useFrontCamera;
- (void)useRearCamera;
- (void)swapCameras;

// Focus point and exposure point are in view coordinates, will be converted to camera coordinates
- (void)setCurrentCameraFocusPoint:(CGPoint)focusPoint;
- (void)setCurrentCameraExposurePoint:(CGPoint)exposurePoint;

- (void)setCurrentCameraFocusPoint:(CGPoint)focusPoint withFocusMode:(AVCaptureFocusMode)focusMode;
- (void)setCurrentCameraExposurePoint:(CGPoint)exposurePoint withFocusMode:(AVCaptureExposureMode)exposureMode;

// Will batch the focus and exposure point change into one configuration change.
// lockFocus: YES = camera will autofocus on point and then lock, NO = camera will continuously autofocus on point
// lockExposure: YES = camera will autoexpose on point and then lock, NO = camera will continuously autoexpose on point
- (void)setCurrentCameraFocusAndExposurePoint:(CGPoint)point lockFocus:(BOOL)lockFocus lockExposure:(BOOL)lockExposure;

// Completion block will always be executed on the main thread
- (void)takePhotoWithCompletionBlock:(void (^)(UIImage *photo, UIImage *preview))takePhotoCompletionBlock;

@end