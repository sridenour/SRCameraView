//
//  SRCameraView.m
/*
 Copyright (c) 2012-2014 Sean Ridenour
 
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

#import "SRCameraView.h"
#import "UIImage+SRImageProcess.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreGraphics/CoreGraphics.h>

static void *kSRCameraViewObserverContext = &kSRCameraViewObserverContext;

#pragma mark - SRCameraView Private Class Continuation

@interface SRCameraView ()

@property (nonatomic, strong) AVCaptureConnection *captureConnection;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@property (nonatomic, strong) UIImageView *focusPointIndicatorView;
@property (nonatomic, strong) UIImageView *exposurePointIndicatorView;

@property (nonatomic, strong) UIImageView *previewPausedView;

- (void)scanStillImageConnections;

@end

#pragma mark - SRCameraView

@implementation SRCameraView {
	__weak SRCamera *_currentCamera;
	BOOL _shouldCapturePreviewImage;
	
	dispatch_queue_t _videoPreviewQueue;
}

#pragma mark - Class Methods

+ (BOOL)deviceHasCamera
{
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		return YES;
	} else {
		return NO;
	}
}

#pragma mark - Init & Dealloc

- (id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]) {
		if(![self sharedSetup]) {
			NSLog(@"Since current device has no camera, SRCameraView won't display anything and will be unusable.");
		}
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if(self = [super initWithCoder:aDecoder]) {
		if(![self sharedSetup]) {
			NSLog(@"Since current device has no camera, SRCameraView won't display anything and will be unusable.");
		}
	}
	return self;
}

- (void)dealloc
{
	[_captureSession stopRunning];
	
	// If device has no camera, observers are not assigned, so we check is device has camera before (with same condition as in sharedSetup
	if(!(_rearCamera == nil && _frontCamera ==  nil)) {
		[self removeObserver:self forKeyPath:@"focusPointOfInterestIndicator" context:kSRCameraViewObserverContext];
		[self removeObserver:self forKeyPath:@"exposurePointOfInterestIndicator" context:kSRCameraViewObserverContext];
		[self removeObserver:self forKeyPath:@"paused" context:kSRCameraViewObserverContext];
		[self removeObserver:self forKeyPath:@"previewLayerGravity" context:kSRCameraViewObserverContext];
	}
}

- (BOOL)sharedSetup
{
	_captureSession = [[AVCaptureSession alloc] init];
	_captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
	
	_rearCamera = [SRCamera cameraWithPosition:AVCaptureDevicePositionBack];
	_frontCamera = [SRCamera cameraWithPosition:AVCaptureDevicePositionFront];
	
	if(_rearCamera != nil) {
		_currentCamera = _rearCamera;
		_currentCameraPosition = AVCaptureDevicePositionBack;
	} else if(_frontCamera != nil) {
		_currentCamera = _frontCamera;
		_currentCameraPosition = AVCaptureDevicePositionFront;
	}
	
	if(_rearCamera == nil && _frontCamera ==  nil) {
		return NO;
	}
	
	if(_currentCamera.hasFlash == YES) {
		_currentCamera.flashMode = AVCaptureFlashModeOff;
	}
	
	[_captureSession addInput:_currentCamera.deviceInput];
	
	_stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	_stillImageOutput.outputSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
	[_captureSession addOutput:_stillImageOutput];
	
	_videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	_videoOutput.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
	_videoOutput.alwaysDiscardsLateVideoFrames = YES;
	_videoPreviewQueue = dispatch_queue_create("SRCameraView.videoPreviewQueue", 0);
	[_videoOutput setSampleBufferDelegate:self queue:_videoPreviewQueue];
	[_captureSession addOutput:_videoOutput];
	
	[self scanStillImageConnections];
	
	_previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
	_previewLayer.frame = self.bounds;
	_previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.layer insertSublayer:_previewLayer below:[self.layer sublayers][0]];
	_previewLayerGravity = AVLayerVideoGravityResizeAspectFill;
	self.clipsToBounds = YES;
	self.layer.masksToBounds = YES;
	
	if(![_previewLayer respondsToSelector:@selector(captureDevicePointOfInterestForPoint:)]) {
		[NSException raise:NSInternalInconsistencyException format:@"%s: _previewLayer does not support -captureDevicePointOfInterestForPoint:",
		  __FUNCTION__];

	}
	
	_focusPointOfInterestIndicator = [UIImage imageNamed:@"focusPoint.png"];
	_focusPointIndicatorView = [[UIImageView alloc] initWithImage:_focusPointOfInterestIndicator];
	_focusPointIndicatorView.hidden = YES;
	[self addSubview:_focusPointIndicatorView];
	
	_exposurePointOfInterestIndicator = [UIImage imageNamed:@"exposurePoint.png"];
	_exposurePointIndicatorView = [[UIImageView alloc] initWithImage:_exposurePointOfInterestIndicator];
	_exposurePointIndicatorView.hidden = YES;
	[self addSubview:_exposurePointIndicatorView];
	
	_shouldDrawPointsOfInterest = YES;
	
	_previewPausedView = [[UIImageView alloc] initWithFrame:self.bounds];
	_previewPausedView.contentMode = UIViewContentModeScaleAspectFill;
	_previewPausedView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	_previewPausedView.clipsToBounds = YES;
	_previewPausedView.hidden = YES;
	[self addSubview:_previewPausedView];
	_shouldCapturePreviewImage = NO;
	
	[self addObserver:self forKeyPath:@"focusPointOfInterestIndicator" options:0 context:kSRCameraViewObserverContext];
	[self addObserver:self forKeyPath:@"exposurePointOfInterestIndicator" options:0 context:kSRCameraViewObserverContext];
	[self addObserver:self forKeyPath:@"paused" options:0 context:kSRCameraViewObserverContext];
	[self addObserver:self forKeyPath:@"previewLayerGravity" options:0 context:kSRCameraViewObserverContext];
	
	return YES;
}

#pragma mark - Layout Management

- (void)layoutSubviews
{
	_previewLayer.frame = self.layer.bounds;
}

#pragma mark - Start & Stop

- (void)start
{
	[self.captureSession startRunning];
	self.paused = NO;
}

- (void)stop
{
	[self.captureSession stopRunning];
}

#pragma mark - Camera Handling

- (void)scanStillImageConnections
{
	AVCaptureConnection *videoConnection = nil;
	
	for(AVCaptureConnection *connection in self.stillImageOutput.connections) {
		for(AVCaptureInputPort *port in connection.inputPorts) {
			if([port.mediaType isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
	}
	
	self.captureConnection = videoConnection;
}

- (void)useCamera:(SRCamera *)camera
{
	[self.captureSession beginConfiguration];
	
	NSArray *inputs = self.captureSession.inputs;
	for(AVCaptureDeviceInput *input in inputs) {
		[self.captureSession removeInput:input];
	}
	
	[self.captureSession addInput:camera.deviceInput];
	
	[self.captureSession commitConfiguration];
	
	_currentCamera = camera;
}

- (void)useFrontCamera
{
	if(self.frontCamera != nil) {
		[self useCamera:self.frontCamera];
		_currentCameraPosition = AVCaptureDevicePositionFront;
		[self scanStillImageConnections];
	}
}

- (void)useRearCamera
{
	if(self.rearCamera != nil) {
		[self useCamera:self.rearCamera];
		_currentCameraPosition = AVCaptureDevicePositionBack;
		[self scanStillImageConnections];
	}
}

- (void)swapCameras
{
	if(_currentCameraPosition == AVCaptureDevicePositionBack) {
		[self useFrontCamera];
	} else {
		[self useRearCamera];
	}
}

- (void)takePhotoWithCompletionBlock:(void (^)(UIImage *, UIImage *))takePhotoCompletionBlock
{
	UIImage *(^completionBlock)(UIImage *photo, UIImage *preview) = [takePhotoCompletionBlock copy];
	
	self.paused = YES;
	
	[self.stillImageOutput
	 captureStillImageAsynchronouslyFromConnection:self.captureConnection
	 completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
		 CFRetain(imageDataSampleBuffer);
		 
		 dispatch_async(_videoPreviewQueue, ^{
			 UIImage *photo = [UIImage imageWithCMSampleBuffer:imageDataSampleBuffer];
			 CFRelease(imageDataSampleBuffer);
			 
			 UIImage *previewImage = [UIImage image:photo scaledToSize:self.previewPausedView.frame.size scaleMode:kSRImageProcessScaleAspectFill];
			 
			 dispatch_async(dispatch_get_main_queue(), ^{
				 self.previewPausedView.image = previewImage;
				 completionBlock(photo, previewImage);
			 });
		 });
	 }];
	
}

#pragma mark - Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(context == kSRCameraViewObserverContext) {
		if([keyPath isEqualToString:@"paused"]) {
			if(_paused == NO) {
				_shouldCapturePreviewImage = NO;
				dispatch_async(dispatch_get_main_queue(), ^{
					self.previewPausedView.hidden = YES;
				});
			} else {
				_shouldCapturePreviewImage = YES;
			}
		} else if([keyPath isEqualToString:@"focusPointOfInterestIndicator"]) {
			if(self.focusPointOfInterestIndicator != nil) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if(self.focusPointIndicatorView != nil) {
						[self.focusPointIndicatorView removeFromSuperview];
						self.focusPointIndicatorView = nil;
					}
					
					UIImageView *fpv = [[UIImageView alloc] initWithImage:self.focusPointOfInterestIndicator];
					fpv.hidden = YES;
					fpv.autoresizingMask = UIViewAutoresizingNone;
					[self addSubview:fpv];
					self.focusPointIndicatorView = fpv;
				});
			}
		} else if([keyPath isEqualToString:@"exposurePointOfInterestIndicator"]) {
			if(self.exposurePointOfInterestIndicator != nil) {
				dispatch_async(dispatch_get_main_queue(), ^{
					if(self.exposurePointIndicatorView != nil) {
						[self.exposurePointIndicatorView removeFromSuperview];
						self.exposurePointIndicatorView = nil;
					}
					
					UIImageView *epv = [[UIImageView alloc] initWithImage:self.exposurePointOfInterestIndicator];
					epv.hidden = YES;
					epv.autoresizingMask = UIViewAutoresizingNone;
					[self addSubview:epv];
					self.exposurePointIndicatorView = epv;
				});
			}
		} else if([keyPath isEqualToString:@"previewLayerGravity"]) {
			self.previewLayer.videoGravity = self.previewLayerGravity;
			if([self.previewLayerGravity isEqualToString:AVLayerVideoGravityResize]) {
				self.previewPausedView.contentMode = UIViewContentModeScaleToFill;
			} else if([self.previewLayerGravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
				self.previewPausedView.contentMode = UIViewContentModeScaleAspectFit;
			} else if([self.previewLayerGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
				self.previewPausedView.contentMode = UIViewContentModeScaleAspectFill;
			} else {
				[NSException raise:NSInvalidArgumentException format:@"invalid preview layer gravity: %@", self.previewLayerGravity];
			}
		} else {
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate Methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection
{
	if(_shouldCapturePreviewImage == YES) {
		_shouldCapturePreviewImage = NO;
		
		UIImage *previewImage = [UIImage imageWithCMSampleBuffer:sampleBuffer];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.previewPausedView.image = previewImage;
			self.previewPausedView.hidden = NO;
		});
	}
}

#pragma mark - Setters & Getters

- (BOOL)setCurrentCameraFocusPoint:(CGPoint)focusPoint
{
	return [self setCurrentCameraFocusPoint:focusPoint withFocusMode:AVCaptureFocusModeAutoFocus];
}

- (BOOL)setCurrentCameraExposurePoint:(CGPoint)exposurePoint
{
	return [self setCurrentCameraExposurePoint:exposurePoint withExposureMode:AVCaptureExposureModeContinuousAutoExposure];
}

- (BOOL)setCurrentCameraFocusPoint:(CGPoint)focusPoint withFocusMode:(AVCaptureFocusMode)focusMode
{
	BOOL success = NO;
	
	if(self.currentCamera.focusPointOfInterestSupported) {
		CGPoint cameraPoint = [_previewLayer captureDevicePointOfInterestForPoint:focusPoint];
		
		if([self.currentCamera setFocusPointOfInterest:cameraPoint withFocusMode:focusMode] == YES) {
			success = YES;
			
			if(self.shouldDrawPointsOfInterest) {
				self.focusPointIndicatorView.center = focusPoint;
				self.focusPointIndicatorView.alpha = 1.0;
				self.focusPointIndicatorView.hidden = NO;
				[UIView animateWithDuration:0.3 animations:^{
					self.focusPointIndicatorView.alpha = 0.0;
				} completion:^(BOOL finished) {
					if(finished == YES) {
						self.focusPointIndicatorView.hidden = YES;
					}
				}];
			}
		}
	}
	
	return success;
}

- (BOOL)setCurrentCameraExposurePoint:(CGPoint)exposurePoint withExposureMode:(AVCaptureExposureMode)exposureMode
{
	BOOL success = NO;
	
	if(self.currentCamera.exposurePointOfInterestSupported) {
		CGPoint cameraPoint = [_previewLayer captureDevicePointOfInterestForPoint:exposurePoint];
		
		if([self.currentCamera setExposurePointOfInterest:cameraPoint withExposureMode:exposureMode]) {
			success = YES;
			
			if(self.shouldDrawPointsOfInterest) {
				self.exposurePointIndicatorView.center = exposurePoint;
				self.exposurePointIndicatorView.alpha = 1.0;
				self.exposurePointIndicatorView.hidden = NO;
				[UIView animateWithDuration:0.3 animations:^{
					self.exposurePointIndicatorView.alpha = 0.0;
				} completion:^(BOOL finished) {
					if(finished == YES) {
						self.exposurePointIndicatorView.hidden = YES;
					}
				}];
			}
		}
	}
	
	return success;
}

- (BOOL)setCurrentCameraFlashMode:(AVCaptureFlashMode)flashMode
{
	BOOL success = NO;
	
	if(self.currentCamera.hasFlash) {
		self.currentCamera.flashMode = flashMode;
		success = YES;
	}
	
	return success;
}

- (AVCaptureFlashMode)currentCameraFlashMode
{
	if(self.currentCamera.hasFlash) {
		return self.currentCamera.flashMode;
	} else {
		return AVCaptureFlashModeOff;
	}
}

@end

