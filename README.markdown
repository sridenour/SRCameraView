SRCameraView
============

Written for the iOS 8.0 SDK, but *should* be able to be deployed as far back as iOS 7.1. There is no explicit support for iOS 6 or earlier, but it may work.

How To Install
--------------

1. Create an iOS project in Xcode.
2. Add the following frameworks:  
	CoreGraphics (if it isn't already)
	AVFoundation
	CoreVideo
	CoreMedia
3. Add all the files in the source/ directory to your project. Put the headers (.h) and Objective-C source (.m) in whatever group you want. Put the images (.png) in the Supporting Files group.

How to Use
----------

1. Import SRCameraView.h in the source for whatever view controller will be managing the camera view.
2. Detect for the presence of a camera (if you haven't already).
3. Create an instance of SRCameraView using `-initWithFrame:`
4. Set the resizing mask and whatever other properties you want (background color, etc.).
5. Add your SRCameraView instance to your view controller's view.
6. Call `-start` to begin the live preview.
7. Call `-takePhotoWithCompletionBlock:` when you want to take a picture. The live preview will be paused, a photo will be taken, and your provided completion block will be called on the main thread.
8. Set the `paused` property to NO after taking a picture when you're ready to un-pause the live preview.
9. Call `-stop` when you're ready to get rid of the SRCameraView (such as in your view controller's viewDidUnload method).

See the CameraTest example app.

Licensed under MIT license.