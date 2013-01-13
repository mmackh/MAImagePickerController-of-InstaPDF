//
//  UIImageView+ContentFrame.h
//  instaoverlay
//
//  Created by Maximilian Mackh on 11/6/12.
//  Copyright (c) 2012 mackh ag. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImageView (UIImageView_ContentFrame)

-(CGRect)contentFrame;
- (CGFloat) contentScale;
- (CGSize) contentSize;

@end
