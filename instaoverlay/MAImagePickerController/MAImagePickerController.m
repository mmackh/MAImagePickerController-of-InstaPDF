//
//  MAImagePickerController.m
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/5/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import "MAImagePickerController.h"
#import "MAImagePickerControllerAdjustViewController.h"

#import "UIImage+fixOrientation.h"


@interface MAImagePickerController ()
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
@end

@implementation MAImagePickerController
{
    BOOL volumeChangeOK;
}

@synthesize captureManager = _captureManager;
@synthesize cameraToolbar = _cameraToolbar;
@synthesize flashButton = _flashButton;
@synthesize pictureButton = _pictureButton;
@synthesize cameraPictureTakenFlash = _cameraPictureTakenFlash;

@synthesize invokeCamera = _invokeCamera;

- (void)viewDidLoad
{
    [self.navigationController setNavigationBarHidden:YES];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    
    
    if (_sourceType == MAImagePickerControllerSourceTypeCamera && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MAImagePickerChosen:) name:@"MAIPCSuccessInternal" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
            AudioSessionInitialize(NULL, NULL, NULL, NULL);
            AudioSessionSetActive(YES);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification)
         {
             AudioSessionSetActive(NO);
         }];
        
        
        AudioSessionInitialize(NULL, NULL, NULL, NULL);
        AudioSessionSetActive(YES);
        
        // Volume View to hide System HUD
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, 0, 10, 0)];
        [_volumeView sizeToFit];
        [self.view addSubview:_volumeView];
        
        [self setCaptureManager:[[MACaptureSession alloc] init]];
        [_captureManager addVideoInputFromCamera];
        [_captureManager addStillImageOutput];
        [_captureManager addVideoPreviewLayer];
        
        CGRect layerRect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - kCameraToolBarHeight);
        [[_captureManager previewLayer] setBounds:layerRect];
        [[_captureManager previewLayer] setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
        [[[self view] layer] addSublayer:[[self captureManager] previewLayer]];
        
        UIImage *gridImage;
        
        if ([[UIScreen mainScreen] bounds].size.height == 568.000000)
        {
            gridImage = [UIImage imageNamed:@"camera-grid-1136@2x.png"];
        }
        else
        {
            gridImage = [UIImage imageNamed:@"camera-grid"];
        }
        
        UIImageView *gridCameraView = [[UIImageView alloc] initWithImage:gridImage];
        [gridCameraView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - kCameraToolBarHeight)];
        
        UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMAImagePickerController)];
        [swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
        [self.view addGestureRecognizer:swipeDown];
        
        [[self view] addSubview:gridCameraView];
        
        _cameraToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - kCameraToolBarHeight, self.view.bounds.size.width, kCameraToolBarHeight)];
        [_cameraToolbar setBackgroundImage:[UIImage imageNamed:@"camera-bottom-bar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close-button"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissMAImagePickerController)];
        cancelButton.accessibilityLabel = @"Close Camera Viewer";
        
        UIImage *cameraButtonImage = [UIImage imageNamed:@"camera-button"];
        UIImage *cameraButtonImagePressed = [UIImage imageNamed:@"camera-button-pressed"];
        UIButton *pictureButtonRaw = [UIButton buttonWithType:UIButtonTypeCustom];
        [pictureButtonRaw setImage:cameraButtonImage forState:UIControlStateNormal];
        [pictureButtonRaw setImage:cameraButtonImagePressed forState:UIControlStateHighlighted];
        [pictureButtonRaw addTarget:self action:@selector(pictureMAIMagePickerController) forControlEvents:UIControlEventTouchUpInside];
        pictureButtonRaw.frame = CGRectMake(0.0, 0.0, cameraButtonImage.size.width, cameraButtonImage.size.height);
        _pictureButton = [[UIBarButtonItem alloc] initWithCustomView:pictureButtonRaw];
        _pictureButton.accessibilityLabel = @"Take Picture";
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kCameraFlashDefaultsKey] == nil)
        {
            [self storeFlashSettingWithBool:YES];
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kCameraFlashDefaultsKey])
        {
            _flashButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"flash-on-button"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleFlash)];
            _flashButton.accessibilityLabel = @"Disable Camera Flash";
            flashIsOn = YES;
            [_captureManager setFlashOn:YES];
        }
        else
        {
            _flashButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"flash-off-button"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleFlash)];
            _flashButton.accessibilityLabel = @"Enable Camera Flash";
            flashIsOn = NO;
            [_captureManager setFlashOn:NO];
        }
        
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        [fixedSpace setWidth:10.0f];
        
        [_cameraToolbar setItems:[NSArray arrayWithObjects:fixedSpace,cancelButton,flexibleSpace,_pictureButton,flexibleSpace,_flashButton,fixedSpace, nil]];
        
        [self.view addSubview:_cameraToolbar];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transitionToMAImagePickerControllerAdjustViewController) name:kImageCapturedSuccessfully object:nil];
        
        _cameraPictureTakenFlash = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height -kCameraToolBarHeight)];
        [_cameraPictureTakenFlash setBackgroundColor:[UIColor colorWithRed:0.99f green:0.99f blue:1.00f alpha:1.00f]];
        [_cameraPictureTakenFlash setUserInteractionEnabled:NO];
        [_cameraPictureTakenFlash setAlpha:0.0f];
        [self.view addSubview:_cameraPictureTakenFlash];
    }
    else
    {
        self.view.layer.cornerRadius = 8;
        self.view.layer.masksToBounds = YES;
        
        _invokeCamera = [[UIImagePickerController alloc] init];
        _invokeCamera.delegate = self;
        _invokeCamera.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _invokeCamera.allowsEditing = NO;
        [self.view addSubview:_invokeCamera.view];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    if (_sourceType == MAImagePickerControllerSourceTypeCamera && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(pictureMAIMagePickerController)
                                                     name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                   object:nil];
        
        [_pictureButton setEnabled:YES];
        [[_captureManager captureSession] startRunning];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_sourceType == MAImagePickerControllerSourceTypeCamera && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
        
        [[_captureManager captureSession] stopRunning];
    }
}

- (void)pictureMAIMagePickerController
{
    if (![[_captureManager captureSession] isRunning]) {
        return;
    }
    
    [_pictureButton setEnabled:NO];
    [_captureManager captureStillImage];
}

- (void)toggleFlash
{
    if (flashIsOn)
    {
        flashIsOn = NO;
        [_captureManager setFlashOn:NO];
        [_flashButton setImage:[UIImage imageNamed:@"flash-off-button"]];
        _flashButton.accessibilityLabel = @"Enable Camera Flash";
        [self storeFlashSettingWithBool:NO];
    }
    else
    {
        flashIsOn = YES;
        [_captureManager setFlashOn:YES];
        [_flashButton setImage:[UIImage imageNamed:@"flash-on-button"]];
        _flashButton.accessibilityLabel = @"Disable Camera Flash";
        [self storeFlashSettingWithBool:YES];
    }
}

- (void)storeFlashSettingWithBool:(BOOL)flashSetting
{
    [[NSUserDefaults standardUserDefaults] setBool:flashSetting forKey:kCameraFlashDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)transitionToMAImagePickerControllerAdjustViewController
{
    [[_captureManager captureSession] stopRunning];
    
    MAImagePickerControllerAdjustViewController *adjustViewController = [[MAImagePickerControllerAdjustViewController alloc] init];
    adjustViewController.sourceImage = [[self captureManager] stillImage];
    
    [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^
     {
         _cameraPictureTakenFlash.alpha = 0.5f;
     }
                     completion:^(BOOL finished)
     {
         [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^
          {
              _cameraPictureTakenFlash.alpha = 0.0f;
          }
                          completion:^(BOOL finished)
          {
              CATransition* transition = [CATransition animation];
              transition.duration = 0.4;
              transition.type = kCATransitionFade;
              transition.subtype = kCATransitionFromBottom;
              [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
              [self.navigationController pushViewController:adjustViewController animated:NO];
          }];
     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissMAImagePickerController];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [_invokeCamera removeFromParentViewController];
    imagePickerDismissed = YES;
    [self.navigationController popViewControllerAnimated:NO];
    
    MAImagePickerControllerAdjustViewController *adjustViewController = [[MAImagePickerControllerAdjustViewController alloc] init];
    adjustViewController.sourceImage = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
    
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.type = kCATransitionFade;
    transition.subtype = kCATransitionFromBottom;
    [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    [self.navigationController pushViewController:adjustViewController animated:NO];
    
}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != NULL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"Image couldn't be saved" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    _captureManager = nil;
}

- (void)dismissMAImagePickerController
{
    [self removeNotificationObservers];
    if (_sourceType == MAImagePickerControllerSourceTypeCamera && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [[_captureManager captureSession] stopRunning];
        AudioSessionSetActive(NO);
    }
    else
    {
        [_invokeCamera removeFromParentViewController];
    }
    
    [_delegate imagePickerDidCancel];
}

- (void) MAImagePickerChosen:(NSNotification *)notification
{
    AudioSessionSetActive(NO);
    
    [self removeNotificationObservers];
    [_delegate imagePickerDidChooseImageWithPath:[notification object]];
}

- (void)removeNotificationObservers
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
