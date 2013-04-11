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
#import <MediaPlayer/MediaPlayer.h>

typedef NS_ENUM(NSInteger, MAImagePickerControllerSourceType)
{
    MAImagePickerControllerSourceTypeCamera,
    MAImagePickerControllerSourceTypePhotoLibrary
};

@protocol MAImagePickerControllerDelegate <NSObject>

@required
- (void)imagePickerDidCancel;
- (void)imagePickerDidChooseImageWithPath:(NSString *)path;

@end

@interface MAImagePickerController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    BOOL flashIsOn;
    BOOL imagePickerDismissed;
}

@property (nonatomic,assign) id<MAImagePickerControllerDelegate> delegate;

@property (strong, nonatomic) MACaptureSession *captureManager;
@property (strong, nonatomic) UIToolbar *cameraToolbar;
@property (strong, nonatomic) UIBarButtonItem *flashButton;
@property (strong, nonatomic) UIBarButtonItem *pictureButton;
@property (strong, nonatomic) UIView *cameraPictureTakenFlash;

@property (strong ,nonatomic) UIImagePickerController *invokeCamera;

@property MAImagePickerControllerSourceType *sourceType;

@property (strong, nonatomic) MPVolumeView *volumeView;

@end
