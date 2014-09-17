//
//  ViewController.m
//  CameraTest
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

#import "ViewController.h"
#import "SRCameraView.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *cameraButton;

@property (nonatomic, strong) NSArray *defaultToolbarItems;			// So we can put the default toolbar items back after a photo is taken
@property (nonatomic, strong) NSArray *photoToolbarItems;			// After the user snaps a pic, we show these. So they can Retake or Use Photo.

@property (nonatomic, strong) UIImage *photo;

@property (nonatomic, strong) SRCameraView *cameraView;

- (IBAction)touchCameraButton:(id)sender;

@end

@implementation ViewController

#pragma mark - View Management

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Do we have a camera?
	if([SRCameraView deviceHasCamera]) {
		NSLog(@"Device has camera");
		
		self.defaultToolbarItems = self.toolbar.items;
		self.photoToolbarItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																				target:nil
																				action:nil],
								  [[UIBarButtonItem alloc] initWithTitle:@"Retake"
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(touchRetakeButton:)],
								  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																				target:nil
																				action:nil],
								  [[UIBarButtonItem alloc] initWithTitle:@"Use Photo"
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(touchUsePhotoButton:)],
								  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																				target:nil
																				action:nil]];
		
		CGRect cameraFrame = self.view.bounds;
		cameraFrame.size.height = cameraFrame.size.height - self.toolbar.frame.size.height;
		
		self.cameraView = [[SRCameraView alloc] initWithFrame:cameraFrame];
		self.cameraView.backgroundColor = [UIColor blackColor];
		
		// IMPORTANT: need this if you want camera view to be taller on iPhone 5 & normal size on iPhone 4/4S/etc.
		self.cameraView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self.view addSubview:_cameraView];
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
		tapGesture.numberOfTapsRequired = 1;
		tapGesture.numberOfTouchesRequired = 1;
		[_cameraView addGestureRecognizer:tapGesture];
		
		// This isn't required, only use it if you need acces to the preview video frames in sampleBuffer
		_cameraView.videoPreviewBlock = ^void(AVCaptureOutput *captureOutput, CMSampleBufferRef sampleBuffer, AVCaptureConnection *connection) {
			// do something with sampleBuffer
		};
	} else {
		NSLog(@"No camera");
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.cameraView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.cameraView start];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[self.cameraView stop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Methods

- (IBAction)touchCameraButton:(id)sender
{
	__weak ViewController *weakSelf = self;
	[self.cameraView takePhotoWithCompletionBlock:^(UIImage *photo, UIImage *preview) {
		// Do something with preview if you want to.
		weakSelf.photo = photo;
		[weakSelf.toolbar setItems:weakSelf.photoToolbarItems animated:YES];
	}];
}

- (void)touchRetakeButton:(id)sender
{
	[self.toolbar setItems:self.defaultToolbarItems animated:YES];
	self.photo = nil;
	self.cameraView.paused = NO;
}

- (void)touchUsePhotoButton:(id)sender
{
	[self.toolbar setItems:self.defaultToolbarItems animated:YES];
	UIImageWriteToSavedPhotosAlbum(self.photo, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
	self.cameraView.paused = NO;
	self.photo = nil;
}

#pragma mark - Gesture Recognizer Methods

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
	if(sender.state == UIGestureRecognizerStateEnded) {
		[self.cameraView setCurrentCameraFocusPoint:[sender locationInView:sender.view]];
		[self.cameraView setCurrentCameraExposurePoint:[sender locationInView:sender.view]];
	}
}

#pragma mark - Image Saving

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
	if(error == nil) {
		NSLog(@"Saved photo to library");
	} else {
		NSLog(@"Couldn't save photo: %@", error);
	}
}

@end
