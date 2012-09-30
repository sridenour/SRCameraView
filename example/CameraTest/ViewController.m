//
//  ViewController.m
//  CameraTest
//
//  Created by Sean Ridenour on 9/29/12.
//  Copyright (c) 2012 Sean Ridenour.
//

#import "ViewController.h"
#import "SRCameraView.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *cameraButton;

- (IBAction)touchCameraButton:(id)sender;

@end

@implementation ViewController {
	SRCameraView *_cameraView;
	NSArray *_defaultToolbarItems;			// So we can put the default toolbar items back after a photo is taken
	NSArray *_photoToolbarItems;			// After the user snaps a pic, we show these. So they can Retake or Use Photo.
	
	UIImage *_photo;
}

#pragma mark - View Management

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Do we have a camera?
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		NSLog(@"Device has camera");
		
		_defaultToolbarItems = self.toolbar.items;
		_photoToolbarItems = [NSArray arrayWithObjects:
							  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
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
																			action:nil],
							  nil];
		
		CGRect cameraFrame = self.view.bounds;
		cameraFrame.size.height = cameraFrame.size.height - self.toolbar.frame.size.height;
		
		_cameraView = [[SRCameraView alloc] initWithFrame:cameraFrame];
		_cameraView.backgroundColor = [UIColor blackColor];
		
		// IMPORTANT: need this if you want camera view to be taller on iPhone 5 & normal size on iPhone 4/4S/etc.
		_cameraView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self.view addSubview:_cameraView];
	} else {
		NSLog(@"No camera");
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	if(_cameraView.superview != nil) {
		[_cameraView removeFromSuperview];
	}
	_cameraView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[_cameraView start];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[_cameraView stop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Methods

- (IBAction)touchCameraButton:(id)sender
{
	[_cameraView takePhotoWithCompletionBlock:^(UIImage *photo, UIImage *preview) {
		// Do something with preview if you want to.
		_photo = photo;
		[self.toolbar setItems:_photoToolbarItems animated:YES];
	}];
}

- (void)touchRetakeButton:(id)sender
{
	[self.toolbar setItems:_defaultToolbarItems animated:YES];
	_photo = nil;
	_cameraView.paused = NO;
}

- (void)touchUsePhotoButton:(id)sender
{
	[self.toolbar setItems:_defaultToolbarItems animated:YES];
	UIImageWriteToSavedPhotosAlbum(_photo, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
	_cameraView.paused = NO;
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
