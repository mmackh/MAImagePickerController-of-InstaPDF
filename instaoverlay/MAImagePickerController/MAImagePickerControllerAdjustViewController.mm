//
//  MAImagePickerControllerAdjustViewController.m
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/5/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import "MAImagePickerControllerAdjustViewController.h"
#import "MAImagePickerFinalViewController.h"

#import "MAOpenCV.h"
#import "UIImageView+ContentFrame.h"
#import <QuartzCore/QuartzCore.h>

@interface MAImagePickerControllerAdjustViewController ()

@end

@implementation MAImagePickerControllerAdjustViewController

@synthesize sourceImageView = _sourceImageView;
@synthesize adjustToolBar = _adjustToolBar;
@synthesize sourceImage = _sourceImage;
@synthesize adjustedImage = _adjustedImage;
@synthesize adjustRect = _adjustRect;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    [backgroundView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:backgroundView];
    
    _sourceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - kCameraToolBarHeight)];
    [_sourceImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    _adjustedImage = _sourceImage;
    
    [_sourceImageView setImage:_adjustedImage];
    [self.view addSubview:_sourceImageView];
    
    _adjustRect= [[MADrawRect alloc] initWithFrame:_sourceImageView.contentFrame];
    [self.view addSubview:_adjustRect];
    
    _adjustToolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - kCameraToolBarHeight, self.view.bounds.size.width, kCameraToolBarHeight)];
    [_adjustToolBar setBackgroundImage:[UIImage imageNamed:@"camera-bottom-bar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close-button"] style:UIBarButtonItemStylePlain target:self action:@selector(popCurrentViewController)];
    cancelButton.accessibilityLabel = @"Return to Camera Viewer";
    
    UIBarButtonItem *undoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"toolbar-icon-crop"] style:UIBarButtonItemStylePlain target:self action:@selector(resetRectFrame)];
    undoButton.accessibilityLabel = @"Reset Frame";
    
    UIBarButtonItem *confirmButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"confirm-button"] style:UIBarButtonItemStylePlain target:self action:@selector(confirmedImage)];
    confirmButton.accessibilityLabel = @"Confirm adjusted Image";
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [fixedSpace setWidth:10.0f];
    
    [_adjustToolBar setItems:[NSArray arrayWithObjects:fixedSpace,cancelButton,flexibleSpace,undoButton,flexibleSpace,confirmButton,fixedSpace, nil]];
    
    [self.view addSubview:_adjustToolBar];
    
    [self detectEdges];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([_adjustRect frameEdited])
    {
        _adjustedImage = _sourceImage;
        [_sourceImageView setImage:_adjustedImage];
    }
}

- (void)popCurrentViewController
{    
    [self.navigationController popViewControllerAnimated:NO];
    
    _adjustRect = nil;
    _adjustToolBar = nil;
    _adjustedImage = nil;
    _sourceImage = nil;
}

- (void)resetRectFrame
{
    _adjustedImage = _sourceImage;
    [_sourceImageView setImage:_adjustedImage];
    [_adjustRect setHidden:NO];
    [_adjustRect resetFrame];
}

- (void)detectEdges
{
    cv::Mat original = [MAOpenCV cvMatGrayFromUIImage:_adjustedImage];
    CGSize targetSize = _sourceImageView.contentSize;
    cv::resize(original, original, cvSize(targetSize.width, targetSize.height));
    
    cv::Mat outerBox = cv::Mat(original.size(), CV_8UC1);
    
    cv::GaussianBlur(original, original, cvSize(11,11), 0);
    cv::adaptiveThreshold(original, outerBox, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 5, 2);
    
    original.release();
    
    cv::bitwise_not(outerBox, outerBox);
    
    uchar ps[] = {0,1,0,1,1,1,0,1,0};
    cv::Mat kernel = cv::Mat_<uchar>(3,3, ps);
    dilate(outerBox, outerBox, kernel);
    
    int max=-1;
    cv::Point maxPt;
    
    for(int y=0;y < outerBox.size().height;y++)
    {
        uchar *row = outerBox.ptr(y);
        for(int x=0;x < outerBox.size().width;x++)
        {
            if(row[x]>=128)
            {
                int area = floodFill(outerBox, cv::Point(x,y), CV_RGB(0,0,64));
                
                if(area>max)
                {
                    maxPt = cvPoint(x,y);
                    max = area;
                }
            }
        }
    }
    
    floodFill(outerBox, maxPt, CV_RGB(255,255,255));
    
    for(int y=0;y < outerBox.size().height;y++)
    {
        uchar *row = outerBox.ptr(y);
        for(int x=0;x < outerBox.size().width;x++)
        {
            if(row[x]==64 && x!=maxPt.x && y != maxPt.y)
            {
                floodFill(outerBox, cv::Point(x,y), CV_RGB(0,0,0));
            }
        }
    }
    
    erode(outerBox, outerBox, kernel);
    
    
    std::vector<cv::Vec2f> lines;
    cv::HoughLines(outerBox, lines, 1, CV_PI/180, 60);
    
    /*
    for(int i=0;i < lines.size();i++)
    {
        cv::Vec2f line = lines[i];
        cv::Scalar rgb = CV_RGB(0,0,128);
        
        if(line[1]!=0)
        {
            float m = -1/tan(line[1]);
            float c = line[0]/sin(line[1]);
            
            cv::line(outerBox, cv::Point(0, c), cv::Point(outerBox.size().width, m*outerBox.size().width+c), rgb);
        }
        else
        {
            cv::line(outerBox, cv::Point(line[0], 0), cv::Point(line[0], outerBox.size().height), rgb);
        }
    }
    */
    
    cv::vector<cv::Vec2f>::iterator current;
    for(current = lines.begin();current != lines.end(); current++)
    {
        if((*current)[0]==0 && (*current)[1] == -100)
        {
            continue;
        }
        
        float p1 = (*current)[0];
        float theta1 = (*current)[1];
        
        cv::Point pt1current, pt2current;
        if(theta1 > CV_PI*45/180 && theta1 < CV_PI*135/180)
        {
            pt1current.x=0;
            pt1current.y = p1/sin(theta1);
            
            pt2current.x= outerBox.size().width;
            pt2current.y=-pt2current.x/tan(theta1) + p1/sin(theta1);
        }
        else
        {
            pt1current.y=0;
            pt1current.x=p1/cos(theta1);
            
            pt2current.y= outerBox.size().height;
            pt2current.x=-pt2current.y/tan(theta1) + p1/cos(theta1);
        }
        
        cv::vector<cv::Vec2f>::iterator pos;
        for(pos = lines.begin(); pos != lines.end(); pos++)
        {
            if(*current==*pos)
            {
                continue;
            }
            
            if(fabs((*pos)[0]-(*current)[0]) < 20 && fabs((*pos)[1]-(*current)[1]) < CV_PI*10/180)
            {
                float p = (*pos)[0];
                float theta = (*pos)[1];
                cv::Point pt1, pt2;
                if((*pos)[1] > CV_PI*45/180 && (*pos)[1]< CV_PI*135/180)
                {
                    pt1.x=0;
                    pt1.y = p/sin(theta);
                    pt2.x=outerBox.size().width;
                    pt2.y=-pt2.x/tan(theta) + p/sin(theta);
                }
                else
                {
                    pt1.y=0;
                    pt1.x=p/cos(theta);
                    pt2.y=outerBox.size().height;
                    pt2.x=-pt2.y/tan(theta) + p/cos(theta);
                }
                
                if(((double)(pt1.x-pt1current.x)*(pt1.x-pt1current.x) + (pt1.y-pt1current.y)*(pt1.y-pt1current.y) < 64*64)
                   &&
                   ((double)(pt2.x-pt2current.x)*(pt2.x-pt2current.x) + (pt2.y-pt2current.y)*(pt2.y-pt2current.y) < 64*64))
                {
                    // Merge the two
                    (*current)[0] = ((*current)[0]+(*pos)[0])/2;
                    (*current)[1] = ((*current)[1]+(*pos)[1])/2;
                    
                    (*pos)[0]=0;
                    (*pos)[1]=-100;
                }
            }
            
        }
    }
    
    cv::Vec2f topEdge = cv::Vec2f(1000,1000);
    cv::Vec2f bottomEdge = cv::Vec2f(-1000,-1000);
    cv::Vec2f leftEdge = cv::Vec2f(1000,1000);
    cv::Vec2f rightEdge = cv::Vec2f(-1000,-1000);
    
    
    double leftXIntercept=100000;
    double rightXIntercept=0;
    
    
    for(int i=0;i  < lines.size();i++)
    {
        cv::Vec2f current = lines[i];
        
        float p=current[0];
        float theta=current[1];
        
        if(p==0 && theta==-100)
        {
            continue;
        }
        
        double xIntercept, yIntercept;
        xIntercept = p/cos(theta);
        yIntercept = p/(cos(theta)*sin(theta));
        
        if(theta > CV_PI*80/180 && theta < CV_PI*100/180)
        {
            if(p < topEdge[0])
            {
                topEdge = current;
            }
            
            if(p > bottomEdge[0])
            {
                bottomEdge = current;
            }
        }
        else if(theta < CV_PI*10/180 || theta > CV_PI*170/180)
        {
            if(xIntercept > rightXIntercept)
            {
                rightEdge = current;
                rightXIntercept = xIntercept;
            }
            else if(xIntercept <= leftXIntercept)
            {
                leftEdge = current;
                leftXIntercept = xIntercept;
            }
        }
    }
    
    cv::Point left1, left2, right1, right2, bottom1, bottom2, top1, top2;
    
    int height=outerBox.size().height;
    int width=outerBox.size().width;
    
    if(leftEdge[1]!=0)
    {
        left1.x=0;        left1.y=leftEdge[0]/sin(leftEdge[1]);
        left2.x=width;    left2.y=-left2.x/tan(leftEdge[1]) + left1.y;
    }
    else
    {
        left1.y=0;        left1.x=leftEdge[0]/cos(leftEdge[1]);
        left2.y=height;    left2.x=left1.x - height*tan(leftEdge[1]);
    }
    
    if(rightEdge[1]!=0)
    {
        right1.x=0;        right1.y=rightEdge[0]/sin(rightEdge[1]);
        right2.x=width;    right2.y=-right2.x/tan(rightEdge[1]) + right1.y;
    }
    else
    {
        right1.y=0;        right1.x=rightEdge[0]/cos(rightEdge[1]);
        right2.y=height;    right2.x=right1.x - height*tan(rightEdge[1]);
    }
    
    bottom1.x=0;    bottom1.y=bottomEdge[0]/sin(bottomEdge[1]);
    bottom2.x=width;bottom2.y=-bottom2.x/tan(bottomEdge[1]) + bottom1.y;
    
    top1.x=0;        top1.y=topEdge[0]/sin(topEdge[1]);
    top2.x=width;    top2.y=-top2.x/tan(topEdge[1]) + top1.y;
    
    double leftA = left2.y-left1.y;
    double leftB = left1.x-left2.x;
    double leftC = leftA*left1.x + leftB*left1.y;
    
    double rightA = right2.y-right1.y;
    double rightB = right1.x-right2.x;
    double rightC = rightA*right1.x + rightB*right1.y;
    
    double topA = top2.y-top1.y;
    double topB = top1.x-top2.x;
    double topC = topA*top1.x + topB*top1.y;
    
    double bottomA = bottom2.y-bottom1.y;
    double bottomB = bottom1.x-bottom2.x;
    double bottomC = bottomA*bottom1.x + bottomB*bottom1.y;
    
    double detTopLeft = leftA*topB - leftB*topA;
    CvPoint ptTopLeft = cvPoint((topB*leftC - leftB*topC)/detTopLeft  + 15, (leftA*topC - topA*leftC)/detTopLeft + 16);
    
    double detTopRight = rightA*topB - rightB*topA;
    CvPoint ptTopRight = cvPoint((topB*rightC-rightB*topC)/detTopRight - 17, (rightA*topC-topA*rightC)/detTopRight);
    
    double detBottomRight = rightA*bottomB - rightB*bottomA;
    CvPoint ptBottomRight = cvPoint((bottomB*rightC-rightB*bottomC)/detBottomRight, (rightA*bottomC-bottomA*rightC)/detBottomRight);
    
    double detBottomLeft = leftA*bottomB-leftB*bottomA;
    CvPoint ptBottomLeft = cvPoint((bottomB*leftC-leftB*bottomC)/detBottomLeft - 3, (leftA*bottomC-bottomA*leftC)/detBottomLeft - 8);
    
    if (CGRectContainsPoint([_sourceImageView contentFrame], CGPointMake(ptTopLeft.x, ptTopLeft.y)) &&
        CGRectContainsPoint([_sourceImageView contentFrame], CGPointMake(ptTopRight.x, ptTopRight.y)) &&
        CGRectContainsPoint([_sourceImageView contentFrame], CGPointMake(ptBottomRight.x, ptBottomRight.y)) &&
        CGRectContainsPoint([_sourceImageView contentFrame], CGPointMake(ptBottomLeft.x, ptBottomLeft.y))
        )
    {
        CGFloat w1 = sqrt( pow(ptBottomRight.x - ptBottomLeft.x , 2) + pow(ptBottomRight.x - ptBottomLeft.x, 2));
        CGFloat w2 = sqrt( pow(ptTopRight.x - ptTopLeft.x , 2) + pow(ptTopRight.x - ptTopLeft.x, 2));
        
        CGFloat h1 = sqrt( pow(ptTopRight.y - ptBottomRight.y , 2) + pow(ptTopRight.y - ptBottomRight.y, 2));
        CGFloat h2 = sqrt( pow(ptTopLeft.y - ptBottomLeft.y , 2) + pow(ptTopLeft.y - ptBottomLeft.y, 2));
        
        if ((w1 || w2 > 100.0 ) && (h1 || h2 > 100))
        {
            [_adjustRect topLeftCornerToCGPoint:CGPointMake(ptTopLeft.x, ptTopLeft.y)];
            [_adjustRect topRightCornerToCGPoint:CGPointMake(ptTopRight.x, ptTopRight.y)];
            [_adjustRect bottomRightCornerToCGPoint:CGPointMake(ptBottomRight.x, ptBottomRight.y)];
            [_adjustRect bottomLeftCornerToCGPoint:CGPointMake(ptBottomLeft.x, ptBottomLeft.y)];
        }
        else
        {
            NSLog(@"Sample area too small");
        }
    }
    
    /*
    [_sourceImageView setNeedsDisplay];
    [_sourceImageView setImage:[MAOpenCV UIImageFromCVMat:outerBox]];
    [_sourceImageView setContentMode:UIViewContentModeScaleAspectFit];
     
     */
    
    outerBox.release();
}

- (void)confirmedImage
{
    BOOL edited;
    if ([_adjustRect frameEdited])
    {
        //cv::GaussianBlur(original, original, cvSize(11,11), 0);
        //cv::adaptiveThreshold(original, original, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY, 5, 2);
        
        CGFloat scaleFactor =  [_sourceImageView contentScale];
        CGPoint ptBottomLeft = [_adjustRect coordinatesForPoint:1 withScaleFactor:scaleFactor];
        CGPoint ptBottomRight = [_adjustRect coordinatesForPoint:2 withScaleFactor:scaleFactor];
        CGPoint ptTopRight = [_adjustRect coordinatesForPoint:3 withScaleFactor:scaleFactor];
        CGPoint ptTopLeft = [_adjustRect coordinatesForPoint:4 withScaleFactor:scaleFactor];
        
        CGFloat w1 = sqrt( pow(ptBottomRight.x - ptBottomLeft.x , 2) + pow(ptBottomRight.x - ptBottomLeft.x, 2));
        CGFloat w2 = sqrt( pow(ptTopRight.x - ptTopLeft.x , 2) + pow(ptTopRight.x - ptTopLeft.x, 2));
        
        CGFloat h1 = sqrt( pow(ptTopRight.y - ptBottomRight.y , 2) + pow(ptTopRight.y - ptBottomRight.y, 2));
        CGFloat h2 = sqrt( pow(ptTopLeft.y - ptBottomLeft.y , 2) + pow(ptTopLeft.y - ptBottomLeft.y, 2));
        
        CGFloat maxWidth = (w1 < w2) ? w1 : w2;
        CGFloat maxHeight = (h1 < h2) ? h1 : h2;
        
        cv::Point2f src[4], dst[4];
        src[0].x = ptTopLeft.x;
        src[0].y = ptTopLeft.y;
        src[1].x = ptTopRight.x;
        src[1].y = ptTopRight.y;
        src[2].x = ptBottomRight.x;
        src[2].y = ptBottomRight.y;
        src[3].x = ptBottomLeft.x;
        src[3].y = ptBottomLeft.y;
        
        dst[0].x = 0;
        dst[0].y = 0;
        dst[1].x = maxWidth - 1;
        dst[1].y = 0;
        dst[2].x = maxWidth - 1;
        dst[2].y = maxHeight - 1;
        dst[3].x = 0;
        dst[3].y = maxHeight - 1;
        
        cv::Mat undistorted = cv::Mat( cvSize(maxWidth,maxHeight), CV_8UC1);
        cv::Mat original = [MAOpenCV cvMatFromUIImage:_adjustedImage];
        cv::warpPerspective(original, undistorted, cv::getPerspectiveTransform(src, dst), cvSize(maxWidth, maxHeight));
        original.release();
        
        _adjustedImage = [MAOpenCV UIImageFromCVMat:undistorted];
        undistorted.release();
        edited = YES;
    }
    else
    {
        edited = NO;
    }
    
    MAImagePickerFinalViewController *finalView = [[MAImagePickerFinalViewController alloc] init];
    finalView.sourceImage = _adjustedImage;
    finalView.imageFrameEdited = edited;
    
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.type = kCATransitionFade;
    transition.subtype = kCATransitionFromBottom;
    [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    [self.navigationController pushViewController:finalView animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
