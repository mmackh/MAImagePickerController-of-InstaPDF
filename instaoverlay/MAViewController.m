//
//  MAViewController.m
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/5/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import "MAViewController.h"
#import "MAImagePickerController.h"

@interface MAViewController ()

@end

@implementation MAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)initButton:(id)sender
{
    MAImagePickerController *customImagePickerController = [[MAImagePickerController alloc] init];
    customImagePickerController.imageSource = 0; //0 -> Camera (if available), 1 -> Library
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:customImagePickerController];
    [self addMANotificationObservers];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void) MAImagePickerClosed
{
    NSLog(@"No Image Chosen");
    [self removeMANotificationObservers];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) MAImagePickerChosen:(NSNotification *)notification
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString *tmpPath = [notification object];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tmpPath])
    {
        NSLog(@"File Found at %@", tmpPath);
        
    }
    else
    {
        NSLog(@"No File Found at %@", tmpPath);
    }
    [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    [self removeMANotificationObservers];
}

- (void)addMANotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MAImagePickerClosed) name:@"MAIPCFail" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MAImagePickerChosen:) name:@"MAIPCSuccess" object:nil];
}

- (void)removeMANotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MAIPCFail" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MAIPCSuccess" object:nil];
}

@end
