//
//  SRCamera.m
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

#import "SRCamera.h"
#import <AVFoundation/AVFoundation.h>

#pragma mark - SRCamera Private Class Continuation

@interface SRCamera ()

@end

#pragma mark - SRCamera

@implementation SRCamera

#pragma mark - Init & Dealloc

+ (SRCamera *)cameraWithCaptureDevice:(AVCaptureDevice *)captureDevice
{
	SRCamera *camera = [[SRCamera alloc] initWithCaptureDevice:captureDevice];
	return camera;
}

+ (SRCamera *)cameraWithPosition:(AVCaptureDevicePosition)position
{
	SRCamera *camera = [[SRCamera alloc] initWithCameraPosition:position];
	return camera;
}

- (id)initWithCaptureDevice:(AVCaptureDevice *)captureDevice
{
	if(captureDevice == nil) {
		return nil;
	}
	
	if(self = [super init]) {
		NSError *error = nil;
		AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
		if(error != nil) {
			self = nil;
		} else {
			_deviceInput = input;
			
			AVCaptureDevice *device = _deviceInput.device;
			
			_cameraPosition = device.position;
			
			_hasFlash = device.hasFlash;
			
			_focusPointOfInterestSupported = device.focusPointOfInterestSupported;
			if(_focusPointOfInterestSupported == YES) {
				_focusPointOfInterest = device.focusPointOfInterest;
			} else {
				_focusPointOfInterest = CGPointZero;
			}
			
			_exposurePointOfInterestSupported = device.exposurePointOfInterestSupported;
			if(_exposurePointOfInterestSupported == YES) {
				_exposurePointOfInterest = device.exposurePointOfInterest;
			} else {
				_exposurePointOfInterest = CGPointZero;
			}
		}
	}
	
	return self;
}

- (id)initWithCameraPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	AVCaptureDevice *captureDevice = nil;
	for(AVCaptureDevice *device in devices) {
		if(device.position == position) {
			captureDevice = device;
			break;
		}
	}
	
	return [self initWithCaptureDevice:captureDevice];
}

- (void)dealloc
{
	_deviceInput = nil;
}

#pragma mark - Setters & Getters

- (void)setFlashMode:(AVCaptureFlashMode)newFlashMode
{
	if(_hasFlash == NO) {
		[NSException raise:NSInternalInconsistencyException format:@"%s: tried to set flash mode on a camera with no flash", __FUNCTION__];
	}
	
	if(_flashMode == newFlashMode) {
		return;
	} else {
		AVCaptureDevice *device = _deviceInput.device;
		
		if([device isFlashModeSupported:newFlashMode]) {
			NSError *lockError = nil;
			[device lockForConfiguration:&lockError];
			if(lockError == nil) {
				device.flashMode = newFlashMode;
				[device unlockForConfiguration];
				_flashMode = newFlashMode;
			}
		}
	}
}

- (void)setFocusPointOfInterest:(CGPoint)newFocusPoint
{
	if(_focusPointOfInterestSupported == NO) {
		[NSException raise:NSInternalInconsistencyException
					format:@"%s: tried to set focus point-of-interest on a camera without focus point-of-interest support", __FUNCTION__];
	}
	
	if(CGPointEqualToPoint(_focusPointOfInterest, newFocusPoint)) {
		return;
	}
	
	AVCaptureDevice *device = _deviceInput.device;
	NSError *lockError = nil;
	
	[device lockForConfiguration:&lockError];
	if(lockError == nil) {
		device.focusPointOfInterest = newFocusPoint;
		if([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
			device.focusMode = AVCaptureFocusModeAutoFocus;
		}
		_focusPointOfInterest = newFocusPoint;
		[device unlockForConfiguration];
	}
}

- (void)setExposurePointOfInterest:(CGPoint)newExposurePointOfInterest
{
	if(_exposurePointOfInterestSupported == NO) {
		[NSException raise:NSInternalInconsistencyException
					format:@"%s: tried to set exposure point-of-interest on a camera without exposure point-of-interest support", __FUNCTION__];
	}
	
	if(CGPointEqualToPoint(_exposurePointOfInterest, newExposurePointOfInterest)) {
		return;
	}
	
	AVCaptureDevice *device = _deviceInput.device;
	NSError *lockError = nil;
	
	[device lockForConfiguration:&lockError];
	if(lockError == nil) {
		device.exposurePointOfInterest = newExposurePointOfInterest;
		if([device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
			device.exposureMode = AVCaptureExposureModeAutoExpose;
		}
		_exposurePointOfInterest = newExposurePointOfInterest;
		[device unlockForConfiguration];
	}
}

@end
