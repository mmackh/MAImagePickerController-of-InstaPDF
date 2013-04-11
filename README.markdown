# MAImagePickerController aka. InstaOverlay

MAImagePickerController is a critical component of the InstaPDF (http://instapdf.me) for iPhone app. I've started to code in Objective C a couple of months ago, so please
offer your insights into making the component better.

Credits:
- Maximilian Mackh (<a href="http://twitter.com/mmackh">@mmackh</a>) - Creator & Maintainer
- Utkarsh Sinha (<a href="http://twitter.com/aishack">@aishack</a>) - Excellent Tutorials
- Jason Job (<a href="https://twitter.com/musicalgeometry">@musicalgeometry</a>) - Excellent Tutorial
- Karl Phillip Buhr (<a href="https://twitter.com/karlphillip">@karlphillip</a>) - Excellent Square Detection Code
- OpenCV (<a href="http://opencv.org/">http://opencv.org/</a>);

Be sure to checkout the ToDo!

## ToDo

1. ~~Improve Paper (Edge) Detection~~
2. Fix rotation of UIImages chosen from the Library
3. Store the rotations in the final view
4. ~~Improve API~~


## Screenshots

![Camera Viewer](https://github.com/mmackh/MAImagePickerController-of-InstaPDF/blob/master/screen1.PNG?raw=true "Take an image")

![Cropping View](https://github.com/mmackh/MAImagePickerController-of-InstaPDF/blob/master/screen2.PNG?raw=true "Crop")

![Final/Adjusting View](https://github.com/mmackh/MAImagePickerController-of-InstaPDF/blob/master/screen3.PNG?raw=true "Adjust the image, rotate, filter and confirm.")

## Using it in your project

1. Add all the necessary files inside MAImagePicker to your Project
2. #import "MAImagePickerController.h" in your ViewController's header (.h) file & declare that it can be delegated by MAImagePickerControllerDelegate
3. IMPORTANT: This project uses the OpenCV framework. Download the newest version here: 'http://opencv.org/'
4. Double check all the necessary frameworks: 'CoreImage.framework', 'opencv2.framework', 'QuartzCore.framework', 'ImageIO.framework', 'CoreMedia.framework', 'AVFoundation.framework', MediaPlayer.framework
5. The API is rather simple, use it like this:

```objective-c
- (IBAction)initButton:(id)sender
{
    MAImagePickerController *imagePicker = [[MAImagePickerController alloc] init];
   
    [imagePicker setDelegate:self];
    [imagePicker setSourceType:MAImagePickerControllerSourceTypeCamera];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePicker];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)imagePickerDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerDidChooseImageWithPath:(NSString *)path
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSLog(@"File Found at %@", path);
        
    }
    else
    {
        NSLog(@"No File Found at %@", path);
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}
```

# License
Copyright (c) 2012-2013 Maximilian Mackh

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.