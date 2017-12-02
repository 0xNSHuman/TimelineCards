//
//  ORBVisualTimer.m
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

#import "ORBVisualTimer.h"

#define ORBVisualTimerDefaultHeight 60.0f
#define ORBVisualTimerTimeRemainingDefault 15.0f

#define ORBScreenDimensions ([[UIScreen mainScreen] bounds].size)
#define ORBVisualTimerBarDefaultFrame CGRectMake(0, ORBScreenDimensions.height - ORBVisualTimerDefaultHeight, ORBScreenDimensions.width, ORBVisualTimerDefaultHeight)
#define ORBVisualTimerBarDefaultHeight 5.0f
#define ORBVisualTimerBarDefaultPadding 10.0f

/* ORBVisualTimer Class */

@interface ORBVisualTimer () {

@protected
    UIView *_timerView;
    NSTimer *_internalTimer;
    
    UILabel *_timerLabel;
    UIBezierPath *_timerPath;
    
    CAShapeLayer *_backShapeLayer;
    CAShapeLayer *_shapeLayer;
    
    NSTimeInterval _timeRemaining;
    NSTimeInterval _lastTimeSetting;
    
    BOOL _showTimerLabel;
}

@property (nonatomic, assign, readwrite) ORBVisualTimerStyle style;
@property (nonatomic, assign, readwrite) NSTimeInterval timeRemaining;

@end

@implementation ORBVisualTimer

@synthesize timeRemaining = _timeRemaining;
@synthesize backgroundViewColor = _backgroundViewColor;
@synthesize backgroundViewCornerRadius = _backgroundViewCornerRadius;
@synthesize timerShapeInactiveColor = _timerShapeInactiveColor;
@synthesize timerShapeActiveColor = _timerShapeActiveColor;
@synthesize autohideWhenFired = _autohideWhenFired;
@synthesize showTimerLabel = _showTimerLabel;
@synthesize timerLabelColor = _timerLabelColor;

#pragma mark - Visual timer fabric

+ (instancetype)timerWithStyle:(ORBVisualTimerStyle)style
                       frame:(CGRect)frame
               timeRemaining:(NSTimeInterval)timeRemaining {
    
    switch (style) {
        
        case ORBVisualTimerStyleBar: {
            return [[ORBVisualTimerBar alloc] initWithBarAnimationStyle:ORBVisualTimerBarAnimationStyleStraight frame:frame timeRemaining:timeRemaining];
        break;
        }
        
        default:
        break;
    }
    
    return nil;
}

#pragma mark - Init

- (instancetype)initWithTimeRemaining:(NSTimeInterval)timeRemaining frame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundViewColor = [UIColor blackColor];
        self.backgroundViewCornerRadius = 0.0f;
        self.timerShapeInactiveColor = [UIColor lightGrayColor];
        self.timerShapeActiveColor = [UIColor greenColor];
        self.autohideWhenFired = NO;
        self.showTimerLabel = YES;
        self.timerLabelColor = [UIColor whiteColor];
        
        _timeRemaining = timeRemaining;
        _lastTimeSetting = _timeRemaining;
    }
    
    return self;
}

#pragma mark - Virtual methods

- (void)reconstructTimerView {
    NSLog(@"Implemented in subclass");
}

- (void)startTimerProgressAnimating {
    NSLog(@"Implemented in subclass");
}

#pragma mark - Setup

- (void)setupView {
    [self reconstructTimerView];
}

#pragma mark - Custom accessors

- (BOOL)timerIsActive {
    return _internalTimer.valid;
}

- (void)setBackgroundViewColor:(UIColor *)backgroundViewColor {
    _backgroundViewColor = backgroundViewColor;
    _timerView.backgroundColor = self.backgroundViewColor;
}

- (void)setBackgroundViewCornerRadius:(CGFloat)backgroundViewCornerRadius {
    _backgroundViewCornerRadius = backgroundViewCornerRadius;
    _timerView.layer.cornerRadius = self.backgroundViewCornerRadius;
}

- (void)setTimerShapeInactiveColor:(UIColor *)timerShapeInactiveColor {
    _timerShapeInactiveColor = timerShapeInactiveColor;
    _backShapeLayer.strokeColor = [self.timerShapeInactiveColor CGColor];
}

- (void)setTimerShapeActiveColor:(UIColor *)timerShapeActiveColor {
    _timerShapeActiveColor = timerShapeActiveColor;
    _shapeLayer.strokeColor = [self.timerShapeActiveColor CGColor];
}

- (void)setTimerLabelColor:(UIColor *)timerLabelColor {
    _timerLabelColor = timerLabelColor;
    _timerLabel.textColor = self.timerLabelColor;
}

#pragma mark - Timer view changes

- (void)start {
    [self resetTimerViewWithTimeRemaining:_timeRemaining];
}

- (void)stopAndHide {
    [self stopTimerView];
    
    if (self.superview) {
        [self removeFromSuperview];
    }
}

- (void)resetTimerViewWithTimeRemaining:(NSTimeInterval)time {
    _timeRemaining = time;
    _lastTimeSetting = _timeRemaining;
    
    _timerLabel.text = [self minutesSecondsStringWithTimeInterval:time];
    [self startTimerProgressAnimating];
    [self rechargeTimerWithTime:time];
}

- (void)stopTimerView {
    [self invalidateTimer];
    [_shapeLayer removeFromSuperlayer];
    _timerLabel.text = @"00:00";
    
    _timeRemaining = _lastTimeSetting;
}

#pragma mark - Timer

- (void)invalidateTimer {
    [_internalTimer invalidate];
}

- (void)rechargeTimerWithTime:(NSTimeInterval)time {
    _internalTimer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(internalTimerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_internalTimer forMode:NSDefaultRunLoopMode];
}

- (void)timerFired {
    [self stopTimerView];
    
    if (self.superview) {
        if (self.autohideWhenFired) { [self removeFromSuperview]; }
        
        if ([self.delegate respondsToSelector:@selector(visualTimerFired:)]) {
            [self.delegate visualTimerFired:self];
        }
    }
}

- (void)internalTimerFired:(NSTimer *)timer {
    self.timeRemaining--;
    [self updateViewWithTimeRemaining:_timeRemaining];
    if (_timeRemaining < 1) {
        [self timerFired];
    }
}

#pragma mark - View updates

- (void)updateViewWithTimeRemaining:(NSTimeInterval)time {
    _timerLabel.text = [self minutesSecondsStringWithTimeInterval:time];
}

#pragma mark - Helpers

- (NSString *)minutesSecondsStringWithTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger seconds = ti % 60;
    
    NSString *minStr = [NSString stringWithFormat:(minutes < 10) ? @"0%li" : @"%li", minutes];
    NSString *secStr = [NSString stringWithFormat:(seconds < 10) ? @"0%li" : @"%li", seconds];
    
    return [NSString stringWithFormat:@"%@:%@", minStr, secStr];
}

@end

/* ORBVisualTimerBar Class */

@interface ORBVisualTimerBar ()

@end

@implementation ORBVisualTimerBar

@synthesize barAnimationStyle = _barAnimationStyle;
@synthesize barThickness = _barThickness;
@synthesize barCapStyle = _barCapStyle;
@synthesize barPadding = _barPadding;

#pragma mark - Init

- (instancetype)init {
    return [self initWithBarAnimationStyle:ORBVisualTimerBarAnimationStyleStraight frame:ORBVisualTimerBarDefaultFrame timeRemaining:ORBVisualTimerTimeRemainingDefault];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithBarAnimationStyle:ORBVisualTimerBarAnimationStyleStraight frame:frame timeRemaining:ORBVisualTimerTimeRemainingDefault];
}

- (instancetype)initWithBarAnimationStyle:(ORBVisualTimerBarAnimationStyle)barAnimationStyle
                                    frame:(CGRect)frame
                            timeRemaining:(NSTimeInterval)timeRemaining {

    if (self = [super initWithTimeRemaining:timeRemaining frame:frame]) {
        _barAnimationStyle = barAnimationStyle;
        _barThickness = ORBVisualTimerBarDefaultHeight;
        _barCapStyle = kCALineCapRound;
        _barPadding = ORBVisualTimerBarDefaultPadding;
        
        [self setupView];
    }
    
    return self;
}

#pragma mark - Timer view construction

- (void)reloadBarPathWithUpdatedParameters {
    _timerPath = [UIBezierPath bezierPath];
    _timerPath.lineWidth = self.barThickness;
    
    [_timerPath moveToPoint:CGPointMake(_timerView.bounds.origin.x + self.barPadding,
                                        _timerView.center.y + ((self.showTimerLabel) ? 10 : 0))];
    [_timerPath addLineToPoint:CGPointMake(_timerView.bounds.size.width - self.barPadding, _timerView.center.y + ((self.showTimerLabel) ? 10 : 0))];
}

- (void)reconstructTimerView {
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    _timerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                          0,
                                                          self.bounds.size.width,
                                                          self.bounds.size.height)];
    _timerView.backgroundColor = self.backgroundViewColor;
    _timerView.layer.cornerRadius = self.backgroundViewCornerRadius;
    
    [self reloadBarPathWithUpdatedParameters];
    
    [self resetProgressBar];
    
    if (self.showTimerLabel) {
        _timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                0,
                                                                self.bounds.size.width/2,
                                                                20)];
        _timerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Regular" size:14.0f];
        _timerLabel.textAlignment = NSTextAlignmentCenter;
        _timerLabel.textColor = self.timerLabelColor;
        _timerLabel.text = @"00:00";
        _timerLabel.center = CGPointMake(_timerView.center.x, _timerView.center.y - self.barThickness/2 - 5);
        [_timerView addSubview:_timerLabel];
    }
    
    [self addSubview:_timerView];
}

#pragma mark - Custom Accessors

- (void)setBarAnimationStyle:(ORBVisualTimerBarAnimationStyle)barAnimationStyle {
    if (_internalTimer.valid) {
        NSLog(@"Modifying animation style on the fly is not supported at the moment. Please stop the timer first");
        return;
    }
    
    _barAnimationStyle = barAnimationStyle;
}

- (void)setBarThickness:(CGFloat)barThickness {
    _barThickness = barThickness;
    _backShapeLayer.lineWidth = self.barThickness;
    _shapeLayer.lineWidth = self.barThickness;
    
    if (self.showTimerLabel) {
        _timerLabel.center = CGPointMake(_timerView.center.x,
                                         _timerView.center.y - self.barThickness/2 - 5);
    }
}

- (void)setBarPadding:(CGFloat)barPadding {
    _barPadding = barPadding;
    
    [self reloadBarPathWithUpdatedParameters];
    
    _backShapeLayer.path = [_timerPath CGPath];
    _shapeLayer.path = [_timerPath CGPath];
}

- (void)setBarCapStyle:(NSString *)barCapStyle {
    _barCapStyle = barCapStyle;
    
    _backShapeLayer.lineCap = _barCapStyle;
    _shapeLayer.lineCap = _barCapStyle;
}

- (void)setShowTimerLabel:(BOOL)showTimerLabel {
    _showTimerLabel = showTimerLabel;
    
    [self reloadBarPathWithUpdatedParameters];
    
    _backShapeLayer.path = [_timerPath CGPath];
    _shapeLayer.path = [_timerPath CGPath];
    
    [_timerLabel removeFromSuperview];
    if (_showTimerLabel) {
        _timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                0,
                                                                self.bounds.size.width/2,
                                                                20)];
        _timerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Regular" size:14.0f];
        _timerLabel.textAlignment = NSTextAlignmentCenter;
        _timerLabel.textColor = self.timerLabelColor;
        _timerLabel.text = @"00:00";
        _timerLabel.center = CGPointMake(_timerView.center.x, _timerView.center.y - self.barThickness/2 - 5);
        [_timerView addSubview:_timerLabel];
    }
}

#pragma mark - Animations

- (void)resetProgressBar {
    [_backShapeLayer removeFromSuperlayer];
    
    _backShapeLayer = [CAShapeLayer layer];
    _backShapeLayer.path = [_timerPath CGPath];
    _backShapeLayer.strokeColor = [self.timerShapeInactiveColor CGColor];
    _backShapeLayer.fillColor = nil;
    _backShapeLayer.lineWidth = self.barThickness;
    _backShapeLayer.lineCap = _barCapStyle;
    _backShapeLayer.zPosition = -1;
    
    [_timerView.layer insertSublayer:_backShapeLayer atIndex:0];
    
    [_shapeLayer removeFromSuperlayer];
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.path = [_timerPath CGPath];
    _shapeLayer.strokeColor = [self.timerShapeActiveColor CGColor];
    _shapeLayer.fillColor = nil;
    _shapeLayer.lineWidth = self.barThickness;
    _shapeLayer.lineCap = _barCapStyle;
    _shapeLayer.zPosition = 0;
    
    [_timerView.layer insertSublayer:_shapeLayer atIndex:1];
}

- (void)startTimerProgressAnimating {
    [self resetProgressBar];
    
    switch (self.barAnimationStyle) {
        case ORBVisualTimerBarAnimationStyleStraight: {
            CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            pathAnimation.duration = _timeRemaining;
            pathAnimation.fromValue = @(1.0f);
            pathAnimation.toValue = @(0.0f);
            [_shapeLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
            
            break;
        }
        
        case ORBVisualTimerBarAnimationStyleBackwards: {
            CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
            pathAnimation.duration = _timeRemaining;
            pathAnimation.fromValue = @(0.0f);
            pathAnimation.toValue = @(1.0f);
            [_shapeLayer addAnimation:pathAnimation forKey:@"strokeStart"];
            
            break;
        }
        
        case ORBVisualTimerBarAnimationStyleReflection: {
            CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
            pathAnimation.duration = _timeRemaining;
            pathAnimation.fromValue = @(0.0f);
            pathAnimation.toValue = @(0.5f);
            [_shapeLayer addAnimation:pathAnimation forKey:@"strokeStart"];
            
            CABasicAnimation *pathAnimation1 = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            pathAnimation1.duration = _timeRemaining;
            pathAnimation1.fromValue = @(1.0f);
            pathAnimation1.toValue = @(0.5f);
            [_shapeLayer addAnimation:pathAnimation1 forKey:@"strokeEnd"];
            
            break;
        }
        
        default:
        break;
    }
}

@end
