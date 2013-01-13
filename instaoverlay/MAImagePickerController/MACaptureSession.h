//
//  MACaptureSession.h
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/5/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "MAConstants.h"

@interface MACaptureSession : NSObject
{
    BOOL flashOn;
}

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) UIImage *stillImage;

- (void)addVideoPreviewLayer;
- (void)addStillImageOutput;
- (void)captureStillImage;
- (void)addVideoInputFromCamera;

- (void)setFlashOn:(BOOL)boolWantsFlash;

@end