//
//  CHDraggableView.m
//  ChatHeads
//
//  Created by Matthias Hochgatterer on 4/19/13.
//  Copyright (c) 2013 Matthias Hochgatterer. All rights reserved.
//

#import "CHDraggableView.h"
#import <QuartzCore/QuartzCore.h>
#import "Fotolia.h"

#import "CHAvatarView.h"
#import "SKBounceAnimation.h"

@interface CHDraggableView ()

@property(nonatomic) CHAvatarView *avatarView;
@property (nonatomic, assign) BOOL moved;
@property (nonatomic, assign) BOOL scaledDown;
@property (nonatomic, assign) CGPoint startTouchPoint;

@end

@implementation CHDraggableView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithImage:(UIImage *)avatar
{
    self = [super initWithFrame:CGRectMake(160, 200, 100, 100)];
    if (self) {
        // Initialization code
        _avatarView = [[CHAvatarView alloc] initWithFrame:CGRectInset(self.bounds, 4, 4)];
        _avatarView.backgroundColor = [UIColor clearColor];
        [_avatarView setImage:avatar];
        _avatarView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [self addSubview:_avatarView];
        [self setHidden:YES];
        [[NSNotificationCenter defaultCenter] addObserverForName:kFXManagerImageUploadProgressNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSDictionary *userInfo = note.userInfo;
            NSNumber *state = [userInfo valueForKey:kFXManagerImageUploadProgressNotificationStateKey];
            NSString *UUID = [userInfo valueForKey:kFXManagerImageUploadProgressNotificationUUIDKey];
            NSNumber *percentage = nil;
            NSError *error = nil;
            switch ([state integerValue]) {
                case FXManagerUploadImageStart:
                    percentage = @(0);
                    self.avatar = nil;
                    DLog(@"Image %@ start", UUID);
                    break;
                case FXManagerUploadImageInProgress:
                    percentage = [userInfo valueForKey:kFXManagerImageUploadProgressNotificationProgressKey];
                    DLog(@"Image %@ in progress %@", UUID, percentage);
                    break;
                case FXManagerUploadImageEnd:
                    percentage = @(100);
                    DLog(@"Image %@ end", UUID);
                    break;
                case FXManagerUploadImageError:
                    error = [userInfo valueForKey:kFXManagerImageUploadProgressNotificationErrorKey];
                    DLog(@"Image %@ error : %@", UUID, error);
                    break;
                default:
                    break;
            }
            if (nil!=error) {
                //
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (nil!=percentage) {
                        [self setPercentage:[percentage integerValue]];
                        if (100==[percentage integerValue]) {
                            [self setHidden:YES];
                        } else {
                            [self setHidden:NO];
                            [self setAvatar:[UIImage imageWithContentsOfFile:[[FXManager sharedManager] mediaThumbPathWithUUID:UUID]]];
                        }
                    }
                });
            }
        }];
    }
    return self;
}

- (void)snapViewCenterToPoint:(CGPoint)point edge:(CGRectEdge)edge
{
    [self _snapViewCenterToPoint:point edge:edge];
}

- (void)hideViewCenterToSlidingPanel
{
    [self _hideViewCenterToPoint:CGPointMake(20, 20)];
}

#pragma mark - Acessors
- (void)setAvatar:(UIImage *)avatar
{
    _avatar = avatar;
    [self.avatarView setImage:_avatar];
    [self.avatarView setNeedsDisplay];
}

- (void)setPercentage:(NSInteger *)percentage
{
    _percentage = percentage;
    [self.avatarView setPercentage:_percentage];
    [self.avatarView setNeedsDisplay];
}

#pragma mark - Override Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    _startTouchPoint = [touch locationInView:self];
    
    // Simulate a touch with the scale animation
    [self _beginHoldAnimation];
    _scaledDown = YES;
    
    [_delegate draggableViewHold:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint movedPoint = [touch locationInView:self];
    
    CGFloat deltaX = movedPoint.x - _startTouchPoint.x;
    CGFloat deltaY = movedPoint.y - _startTouchPoint.y;
    [self _moveByDeltaX:deltaX deltaY:deltaY];
    if (_scaledDown) {
        [self _beginReleaseAnimation];
    }
    _scaledDown = NO;
    _moved = YES;
    
    [_delegate draggableView:self didMoveToPoint:movedPoint];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_scaledDown) {
        [self _beginReleaseAnimation];
    }
    if (!_moved) {
        [_delegate draggableViewTouched:self];
    } else {
        [_delegate draggableViewReleased:self];
    }
    
    _moved = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

#pragma mark - Animations
#define CGPointIntegral(point) CGPointMake((int)point.x, (int)point.y)

- (CGFloat)_distanceFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2
{
    return hypotf(point1.x - point2.x, point1.y - point2.y);
}

- (CGFloat)_angleFromPoint:(CGPoint)point1 toPoint:(CGPoint)point2
{
    CGFloat x = point2.x - point1.x;
    CGFloat y = point2.y - point1.y;
    
    return atan2f(x,y);
}

- (void)_moveByDeltaX:(CGFloat)x deltaY:(CGFloat)y
{
    [UIView animateWithDuration:0.3f animations:^{
        CGPoint center = self.center;
        center.x += x;
        center.y += y;
        self.center = CGPointIntegral(center);
    }];
}

- (void)_beginHoldAnimation
{
    SKBounceAnimation *animation = [SKBounceAnimation animationWithKeyPath:@"transform"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 1, 1)];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95f, 0.95f, 1)];
    animation.duration = 0.2f;
    
    self.layer.transform = [animation.toValue CATransform3DValue];
    [self.layer addAnimation:animation forKey:nil];
}

- (void)_beginReleaseAnimation
{
    SKBounceAnimation *animation = [SKBounceAnimation animationWithKeyPath:@"transform"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fromValue = [NSValue valueWithCATransform3D:self.layer.transform];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 1, 1)];
    animation.duration = 0.2f;
    
    self.layer.transform = [animation.toValue CATransform3DValue];
    [self.layer addAnimation:animation forKey:nil];
}

- (void)_snapViewCenterToPoint:(CGPoint)point edge:(CGRectEdge)edge
{
    CGPoint currentCenter = self.center;
    
    SKBounceAnimation *animation = [SKBounceAnimation animationWithKeyPath:@"position"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fromValue = [NSValue valueWithCGPoint:currentCenter];
    animation.toValue = [NSValue valueWithCGPoint:point];
    animation.duration = 1.2f;
    self.layer.position = point;
    [self.layer addAnimation:animation forKey:nil];
}

- (void)_hideViewCenterToPoint:(CGPoint)point
{
    CGPoint currentCenter = self.center;
    [CATransaction begin];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fromValue = [NSValue valueWithCGPoint:currentCenter];
    animation.toValue = [NSValue valueWithCGPoint:point];
    animation.duration = 0.2f;
    self.layer.position = point;
    [self.layer addAnimation:animation forKey:nil];
    
    // avatar layer animation
    CALayer *avatarLayer = [[[self subviews] objectAtIndex:0] layer];
    
    CGRect newBounds = self.layer.bounds;
    newBounds.size = CGSizeMake(0, 0);
    CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    boundsAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    boundsAnimation.fromValue = [NSValue valueWithCGRect:self.bounds];
    boundsAnimation.toValue = [NSValue valueWithCGRect:newBounds];
    boundsAnimation.duration = 0.2f;
    
    
//    avatarLayer.bounds = newBounds;
    
    CAKeyframeAnimation *alphaAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    NSArray *times = @[@(0.0),@(0.18),@(0.2)];
    [alphaAnimation setKeyTimes:times];
    NSArray *values = @[@(1),@(1), @(0)];
    [alphaAnimation setValues:values];
    alphaAnimation.duration = 0.2;
    
    CAAnimationGroup * avatarLayerAnimationGroup = [CAAnimationGroup animation];
    [avatarLayerAnimationGroup setAnimations:@[boundsAnimation, alphaAnimation]];
    avatarLayerAnimationGroup.duration = 0.2;
    [avatarLayer addAnimation:avatarLayerAnimationGroup forKey:nil];
    
    
    
    
    [CATransaction commit];

}

@end
