//
//  CHDraggableView.h
//  ChatHeads
//
//  Created by Matthias Hochgatterer on 4/19/13.
//  Copyright (c) 2013 Matthias Hochgatterer. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CHDraggableViewDelegate;
@interface CHDraggableView : UIView

@property(nonatomic) UIImage *avatar;
@property(nonatomic, assign) NSInteger *percentage;
@property(nonatomic, assign, getter = isForcedHidden) BOOL forcedHidden;
@property (nonatomic, assign) id<CHDraggableViewDelegate> delegate;

- (id)initWithImage:(UIImage *)avatar;

- (void)snapViewCenterToPoint:(CGPoint)point edge:(CGRectEdge)edge;
- (void)hideViewCenterToSlidingPanel;

@end

@protocol CHDraggableViewDelegate <NSObject>

- (void)draggableViewHold:(CHDraggableView *)view;
- (void)draggableView:(CHDraggableView *)view didMoveToPoint:(CGPoint)point;
- (void)draggableViewReleased:(CHDraggableView *)view;

- (void)draggableViewTouched:(CHDraggableView *)view;

@end