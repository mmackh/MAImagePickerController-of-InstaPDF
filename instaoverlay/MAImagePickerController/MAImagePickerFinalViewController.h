//
//  MAImagePickerFinalViewController.h
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/10/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MAConstants.h"

@interface MAImagePickerFinalViewController : UIViewController <UIScrollViewDelegate>
{
    int currentlySelected;
    UIImageOrientation sourceImageOrientation;
}

@property BOOL imageFrameEdited;

@property (strong, nonatomic) UIImage *sourceImage;
@property (strong, nonatomic) UIImage *adjustedImage;

@property (strong, nonatomic) UIButton *firstSettingIcon;
@property (strong, nonatomic) UIButton *secondSettingIcon;
@property (strong, nonatomic) UIButton *thirdSettingIcon;
@property (strong, nonatomic) UIButton *fourthSettingIcon;

@property (strong, nonatomic) UIBarButtonItem *rotateButton;

@property (strong, nonatomic) UIImageView *activityIndicator;
@property (strong, nonatomic) UIActivityIndicatorView *progressIndicator;

@property (strong, nonatomic) UIImageView *finalImageView;

@end
