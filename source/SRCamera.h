//
//  SRCamera.h
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

@interface SRCamera : NSObject

@property (nonatomic, readonly) AVCaptureDeviceInput *deviceInput;

@property (nonatomic, readonly) AVCaptureDevicePosition cameraPosition;

@property (nonatomic, readwrite, assign) AVCaptureFlashMode flashMode;
@property (nonatomic, readonly) BOOL hasFlash;

@property (nonatomic, readonly) BOOL focusPointOfInterestSupported;
@property (nonatomic, readonly) BOOL exposurePointOfInterestSupported;

@property (nonatomic, readonly) CGPoint focusPointOfInterest;
@property (nonatomic, readonly) CGPoint exposurePointOfInterest;

+ (SRCamera *)cameraWithCaptureDevice:(AVCaptureDevice *)captureDevice;
+ (SRCamera *)cameraWithPosition:(AVCaptureDevicePosition)position;

- (id)initWithCaptureDevice:(AVCaptureDevice *)captureDevice;
- (id)initWithCameraPosition:(AVCaptureDevicePosition)position;

// Focus point and exposure point are in camera coordinates, i.e. (0, 0) is top left of unrotated picture,
// and (1, 1) is bottom right.
// Returns YES if set, NO if not.
- (BOOL)setFocusPointOfInterest:(CGPoint)focusPoint withFocusMode:(AVCaptureFocusMode)focusMode;
- (BOOL)setExposurePointOfInterest:(CGPoint)exposurePoint withExposureMode:(AVCaptureExposureMode)exposureMode;

@end
