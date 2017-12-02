//
//  ORBVisualTimer.h
//  ORBVisualTimerDemo
//
//  Created by Vladislav Averin on 29/03/2016.
//  Copyright © 2016 Vlad Averin (hello@vladaverin.me). All rights reserved.
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/vladaverin24/ORBVisualTimer
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger) {
    ORBVisualTimerStyleBar = 0
    /* More styles to come */
} ORBVisualTimerStyle;

typedef NS_ENUM(NSUInteger) {
    ORBVisualTimerBarAnimationStyleStraight = 0,
    ORBVisualTimerBarAnimationStyleBackwards,
    ORBVisualTimerBarAnimationStyleReflection
} ORBVisualTimerBarAnimationStyle;


@class ORBVisualTimer;

@protocol ORBVisualTimerDelegate <NSObject>

@required
- (void)visualTimerFired:(ORBVisualTimer *)timerView;

@end


/**
 \class ORBVisualTimer
 \brief Base class for all visual timers.
 */
@interface ORBVisualTimer : UIView

#pragma mark - Properties

/**
 Style of the timer to construct. In v1.0 only ORBVisualTimerStyleBar is implemented.
 */
@property (nonatomic, assign, readonly) ORBVisualTimerStyle style;

/**
 Delegate object to receive events from timer.
 */
@property (nonatomic, weak) id <ORBVisualTimerDelegate> delegate;

/**
 Use this readonly property to track currently remaining time.
 */
@property (nonatomic, assign, readonly) NSTimeInterval timeRemaining;

/**
 Indicates if timer is currently running or stopped.
 */
@property (nonatomic, assign, readonly) BOOL timerIsActive;

/* --- CUSTOMIZATION --- */

/**
 Color of the containing view around timer itself. Default value is black color.
 */
@property (nonatomic, strong) UIColor *backgroundViewColor;

/**
 Corner radius for containing view around timer. Default value is 0.0f.
 */
@property (nonatomic, assign) CGFloat backgroundViewCornerRadius;

/**
 Color of the timer shape's (bar, circle, etc) background component, which stays inactive all the time. Default value is light gray color.
 */
@property (nonatomic, strong) UIColor *timerShapeInactiveColor;

/**
 Color of the timer shape's (bar, circle, etc) foreground component, which is animated according to time remaining. Default value is green color.
 */
@property (nonatomic, strong) UIColor *timerShapeActiveColor;

/**
 Whether or not to show label with time remaining. Default value is YES;
 */
@property (nonatomic, assign) BOOL showTimerLabel;

/**
 Color of the timer label text. Default value is white color.
 */
@property (nonatomic, strong) UIColor *timerLabelColor;


/**
 Whether or not to hide timer view after firing. Default value is NO.
 */
@property (nonatomic, assign) BOOL autohideWhenFired;

#pragma mark - Methods

/**
 \brief Constructs timer view with given style.
 \param style Style of the timer.
 \param frame Frame of the view.
 \param timeRemaining Time to initialize timer with.
 \returns Timer object of correspondent class.
 */
+ (instancetype)timerWithStyle:(ORBVisualTimerStyle)style
                       frame:(CGRect)frame
               timeRemaining:(NSTimeInterval)timeRemaining;

/**
 \brief Starts the timer.
 */
- (void)start;

/**
 \brief Stops the timer and resets time setting.
 */
- (void)stopTimerView;

/**
 \brief Stops the timer and hides its view.
 */
- (void)stopAndHide;

@end

/**
 \class ORBVisualTimerBar
 \brief Bar style implementation of the visual timer.
 */
@interface ORBVisualTimerBar : ORBVisualTimer

#pragma mark - Properties

/**
 Style of bar timer animation. Default value is ORBVisualTimerBarAnimationStyleStraight.
 */
@property (nonatomic, assign) ORBVisualTimerBarAnimationStyle barAnimationStyle;

/**
 Thikness of bar. Default value is 5.0f.
 */
@property (nonatomic, assign) CGFloat barThickness;

/**
 Horizontal padding for both left and right bar ends. Default value is 10.0f;
 */
@property (nonatomic, assign) CGFloat barPadding;

/**
 Cap style for both bar ends. Default value is kCALineCapRound.
 \discussion Possible pre-defined values include kCALineCapButt, kCALineCapRound and kCALineCapSquare.
 */
@property (nonatomic, assign) NSString *barCapStyle;

#pragma mark - Methods

/**
 \brief Initializes bar timer with given style.
 \param barAnimationStyle Style of bar animation.
 \param frame Frame of the view.
 \param timeRemaining Time to initialize timer with.
 */
- (instancetype)initWithBarAnimationStyle:(ORBVisualTimerBarAnimationStyle)barAnimationStyle
                                    frame:(CGRect)frame
                            timeRemaining:(NSTimeInterval)timeRemaining;

@end
