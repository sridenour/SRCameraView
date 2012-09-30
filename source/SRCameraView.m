//
//  SRCameraView.m
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
	
	dispatch_queue_t _stillImagePrepareQueue;
}

#pragma mark - Init & Dealloc

- (id)init
{
	self = [super init];
	if(self) {
		BOOL setupWasOK = [self sharedSetup];
		if(setupWasOK == NO) {
			return nil;
		}
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
		BOOL setupWasOK = [self sharedSetup];
		if(setupWasOK == NO) {
			return nil;
		}
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self) {
		BOOL setupWasOK = [self sharedSetup];
		if(setupWasOK == NO) {
			return nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[_captureSession stopRunning];
	
	[self removeObserver:self forKeyPath:@"focusPointOfInterestIndicator" context:kSRCameraViewObserverContext];
	[self removeObserver:self forKeyPath:@"exposurePointOfInterestIndicator" context:kSRCameraViewObserverContext];
	[self removeObserver:self forKeyPath:@"paused" context:kSRCameraViewObserverContext];
	[self removeObserver:self forKeyPath:@"previewLayerGravity" context:kSRCameraViewObserverContext];
		
	if(_stillImagePrepareQueue) {
		dispatch_release(_stillImagePrepareQueue);
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
	} else if(_frontCamera != nil) {
		_currentCamera = _frontCamera;
	}
	
	if(_rearCamera == nil && _frontCamera ==  nil) {
		return NO;
	}
	
	[_captureSession addInput:_currentCamera.deviceInput];
	
	_stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	_stillImageOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
	[_captureSession addOutput:_stillImageOutput];
	
	_videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	_videoOutput.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
	dispatch_queue_t videoPreviewQueue = dispatch_queue_create("SRCameraView.videoPreviewQueue", 0);
	[_videoOutput setSampleBufferDelegate:self queue:videoPreviewQueue];
	dispatch_release(videoPreviewQueue);
	[_captureSession addOutput:_videoOutput];
	
	[self scanStillImageConnections];
	
	_previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
	_previewLayer.frame = self.bounds;
	_previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.layer addSublayer:_previewLayer];
	_previewLayerGravity = AVLayerVideoGravityResizeAspectFill;
	
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
	
	_stillImagePrepareQueue = dispatch_queue_create("SRCameraView.stillImagePreparationQueue", 0);
	
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
		 
		 dispatch_async(_stillImagePrepareQueue, ^{
			 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
			 UIImage *photo = [UIImage imageWithData:imageData];
			 imageData = nil;
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

- (void)setFocusPoint:(CGPoint)focusPoint
{
	// not implemented yet
}

- (void)setExposurePoint:(CGPoint)exposurePoint
{
	// not implemented yet
}

@end
