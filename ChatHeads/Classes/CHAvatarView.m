//
//  AvatarView.m
//
//  Created by Matthias Hochgatterer on 21.11.12.
//  Copyright (c) 2012 Matthias Hochgatterer. All rights reserved.
//

#import "CHAvatarView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CHAvatarView

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
//        self.layer.shadowColor = [UIColor blackColor].CGColor;
//        self.layer.shadowOffset = CGSizeMake(0,2);
//        self.layer.shadowRadius = 2;
//        self.layer.shadowOpacity = 0.7f;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGFloat s = 5;
    CGRect b = CGRectInset(self.bounds, s, s);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ctx);

    CGPathRef circlePath = CGPathCreateWithEllipseInRect(b, 0);
    CGMutablePathRef inverseCirclePath = CGPathCreateMutableCopy(circlePath);
    CGPathAddRect(inverseCirclePath, nil, CGRectInfinite);
    
    CGContextSaveGState(ctx); {
        CGContextBeginPath(ctx);
        CGContextAddPath(ctx, circlePath);
        CGContextClip(ctx);
        if (nil==_image) {
            CGContextSetFillColorWithColor(ctx,[UIColor blackColor].CGColor);
            CGContextFillPath(ctx);
        } else {
            [_image drawInRect:b];
        }
        // Draw the overlay
        CGContextSaveGState(ctx); {
            CGContextBeginPath(ctx);
            CGContextAddRect(ctx, CGRectMake(0, 0, b.size.width+2*s, s+b.size.height-(b.size.height*self.percentage)/100));
//            CGContextClip(ctx);
            CGContextSetFillColorWithColor(ctx,[UIColor colorWithRed:78/255. green:182/255. blue:78/255. alpha:1].CGColor);
            CGContextFillPath(ctx);
        } CGContextRestoreGState(ctx);
    } CGContextRestoreGState(ctx);
    
    CGContextSaveGState(ctx); {
        CGContextSetLineWidth(ctx, s);
        CGContextBeginPath(ctx);
        CGContextAddPath(ctx, circlePath);
        
        CGContextSetStrokeColorWithColor(ctx,[UIColor colorWithRed:78/255. green:182/255. blue:78/255. alpha:1].CGColor);
        CGContextStrokePath(ctx);
//        CGContextClip(ctx);
//        
//        CGContextSetShadowWithColor(ctx, CGSizeMake(0, 0), 3.0f, [UIColor colorWithRed:0.994 green:0.989 blue:1.000 alpha:1.0f].CGColor);
//        
//        CGContextBeginPath(ctx);
//        CGContextAddPath(ctx, inverseCirclePath);
//        CGContextEOFillPath(ctx);
    } CGContextRestoreGState(ctx);
    

    CGPathRelease(circlePath);
    CGPathRelease(inverseCirclePath);
    
    CGContextRestoreGState(ctx);
}


@end
