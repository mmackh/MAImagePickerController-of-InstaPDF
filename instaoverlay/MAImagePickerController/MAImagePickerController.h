//
//  MAImagePickerController.h
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/5/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MACaptureSession.h"
#import "MAConstants.h"

@interface MAImagePickerController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    BOOL flashIsOn;
    BOOL imagePickerDismissed;
}

@property (strong, nonatomic) MACaptureSession *captureManager;
@property (strong, nonatomic) UIToolbar *cameraToolbar;
@property (strong, nonatomic) UIBarButtonItem *flashButton;
@property (strong, nonatomic) UIBarButtonItem *pictureButton;
@property (strong, nonatomic) UIView *cameraPictureTakenFlash;

@property (strong ,nonatomic) UIImagePickerController *invokeCamera;
@property int imageSource; // 0 -> Camera, 1 -> Library 

@end
