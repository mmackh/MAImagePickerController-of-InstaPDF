# MAImagePickerController aka. InstaOverlay

MAImagePickerController is a critical component of the InstaPDF (http://instapdf.me) for iPhone app. I've started to code in Objective C a couple of months ago, so please
offer your insights into making the component better.

Credits:
- Maximilian Mackh (<a href="http://twitter.com/mmackh">@mmackh</a>)
- Utkarsh Sinha (<a href="http://twitter.com/aishack">@aishack</a>) - Excellent Tutorials
- Jason Job (<a href="https://twitter.com/musicalgeometry">@musicalgeometry</a>) - Excellent Tutorial
- OpenCV (<a href="http://opencv.org/">http://opencv.org/</a>);

Be sure to checkout the ToDo!

## ToDo

1. Improve Paper (Edge) Detection
2. Fix rotation of UIImages chosen from the Library
3. Store the rotations in the final view


## Screenshots

![Camera Viewer](https://github.com/mmackh/MAImagePickerController-of-InstaPDF/blob/master/screen1.PNG?raw=true "Take an image")

![Cropping View](https://github.com/mmackh/MAImagePickerController-of-InstaPDF/blob/master/srcreen2.PNG?raw=true "Crop")

![Final/Adjusting View](https://github.com/mmackh/MAImagePickerController-of-InstaPDF/blob/master/screen3.PNG?raw=true "Adjust the image, rotate, filter and confirm.")

## Using it in your project

1. Add all the necessary files inside MAImagePicker to your Project
2. #import "MAImagePickerController.h"
3. IMPORTANT: This project uses the OpenCV framework download it here: 'http://opencv.org/'
4. The API is rather simple, use it like this:
5. Double check all the necessary frameworks: 'CoreImage.framework', 'opencv2.framework', 'QuartzCore.framework', 'ImageIO.framework', 'CoreMedia.framework', 'AVFoundation.framework'

```objective-c
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
```

# License
Copyright (c) 2012-2013 Maximilian Mackh

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.