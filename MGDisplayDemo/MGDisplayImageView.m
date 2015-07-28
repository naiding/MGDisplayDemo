//
//  MGDisplayImageView.m
//  Detecting Pinch Gestures
//
//  Created by Leon on 15/7/28.
//  Copyright (c) 2015年 Pixolity Ltd. All rights reserved.
//

#import "MGDisplayImageView.h"

@interface MGDisplayImageView()<UIGestureRecognizerDelegate>

@property (strong, nonatomic) NSMutableSet *activeRecognizers;
@property (assign, nonatomic) CGAffineTransform referenceTransform;

@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (strong, nonatomic) UIRotationGestureRecognizer *rotationGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;


@property (assign, nonatomic) CGRect oldFrame;
@property (strong, nonatomic) UIWindow *thisWindow;
@property (strong, nonatomic) UIView *thisView;
@property (strong, nonatomic) UIImageView *thisImageView;
@property (strong, nonatomic) UIImage *displayImage;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation MGDisplayImageView

- (id)init
{
    if (self = [super init]) {
        
        self.oldFrame = CGRectZero;
        
        [self.thisView addGestureRecognizer:self.pinchGestureRecognizer];
        [self.thisView addGestureRecognizer:self.rotationGestureRecognizer];
        [self.thisView addGestureRecognizer:self.panGestureRecognizer];
    }
    
    return self;
}

- (void)showImageView:(UIImageView *)imageView
{
    self.displayImage = imageView.image;
    self.thisWindow = [UIApplication sharedApplication].keyWindow;
    self.thisView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.thisView.backgroundColor = [UIColor blackColor];
    self.thisView.alpha = 0;
    
    self.oldFrame = [imageView convertRect:imageView.bounds toView:self.thisWindow];

    self.thisImageView.frame = self.oldFrame;
    self.thisImageView.image = self.displayImage;
    
    [self.thisView addSubview:self.thisImageView];
    [self.thisWindow addSubview:self.thisView];
    
    [self.thisView addGestureRecognizer:self.tapGestureRecognizer];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.thisImageView.frame = CGRectMake(0,([UIScreen mainScreen].bounds.size.height-self.displayImage.size.height * [UIScreen mainScreen].bounds.size.width/self.displayImage.size.width)/2, [UIScreen mainScreen].bounds.size.width, self.displayImage.size.height*[UIScreen mainScreen].bounds.size.width/self.displayImage.size.width);
        self.thisView.alpha = 1;
    } completion:^(BOOL finished) {}];
}


- (void)hideImage:(UITapGestureRecognizer*)tap {
    
    [UIView animateWithDuration:0.3 animations:^{
        self.thisImageView.frame = self.oldFrame;
        self.thisView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.thisView removeFromSuperview];
        self.thisImageView.frame = CGRectZero;
        self.thisImageView.transform = CGAffineTransformIdentity;
    }];
}

- (void)handleGesture:(UIGestureRecognizer *)paramSender
{
    switch (paramSender.state) {
            
        case UIGestureRecognizerStateBegan:{
            if (self.activeRecognizers.count == 0)
                self.referenceTransform = self.thisImageView.transform;
            [self.activeRecognizers addObject:paramSender];
            
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGAffineTransform transform = self.referenceTransform;
            for (UIGestureRecognizer *recognizer in self.activeRecognizers){
                transform = [self applyRecognizer:recognizer toTransform:transform];
            }
            self.thisImageView.transform = transform;
            
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            self.referenceTransform = [self applyRecognizer:paramSender toTransform:self.referenceTransform];
            
            [self.activeRecognizers removeObject:paramSender];
            
            [UIView animateWithDuration:0.3 animations:^{
                self.thisImageView.transform = CGAffineTransformIdentity;
                self.thisImageView.frame = CGRectMake(0,([UIScreen mainScreen].bounds.size.height-self.displayImage.size.height * [UIScreen mainScreen].bounds.size.width/self.displayImage.size.width)/2, [UIScreen mainScreen].bounds.size.width, self.displayImage.size.height*[UIScreen mainScreen].bounds.size.width/self.displayImage.size.width);
            } completion:^(BOOL finished) {
                
            }];
            
            break;
        }
        default:
            break;
    }
}

- (CGAffineTransform)applyRecognizer:(UIGestureRecognizer *)recognizer toTransform:(CGAffineTransform)transform
{
    if ([recognizer respondsToSelector:@selector(rotation)])
        return CGAffineTransformRotate(transform, [(UIRotationGestureRecognizer *)recognizer rotation]);
    else if ([recognizer respondsToSelector:@selector(scale)]) {
        CGFloat scale = [(UIPinchGestureRecognizer *)recognizer scale];
        return CGAffineTransformScale(transform, scale, scale);
    }
    else {
        return CGAffineTransformTranslate(transform,[(UIPanGestureRecognizer *)recognizer translationInView:self.thisView].x, [(UIPanGestureRecognizer *)recognizer translationInView:self.thisView].y);
    }
    return transform;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Window & Views & Gestures

- (UIWindow *)thisWindow
{
    if (_thisWindow == nil) {
        _thisWindow = [UIWindow new];
    }
    return _thisWindow;
}

- (UIView *)thisView
{
    if (_thisView == nil) {
        _thisView = [UIView new];
    }
    return _thisView;
}

- (UIImageView *)thisImageView
{
    if (_thisImageView == nil) {
        _thisImageView = [UIImageView new];
    }
    
    return _thisImageView;
}

- (UIImage *)displayImage
{
    if (_displayImage == nil) {
        _displayImage = [UIImage new];
    }
    
    return _displayImage;
}

- (NSMutableSet *)activeRecognizers
{
    if (_activeRecognizers == nil) {
        _activeRecognizers = [NSMutableSet set];
    }
    
    return _activeRecognizers;
}

- (UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    if (_pinchGestureRecognizer == nil) {
        _pinchGestureRecognizer =  [[UIPinchGestureRecognizer alloc]
                                        initWithTarget:self
                                        action:@selector(handleGesture:)];
        _pinchGestureRecognizer.delegate = self;
        _pinchGestureRecognizer.cancelsTouchesInView = NO;
    }
    
    return _pinchGestureRecognizer;
}

- (UIRotationGestureRecognizer *)rotationGestureRecognizer
{
    if (_rotationGestureRecognizer == nil) {
        _rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
        _rotationGestureRecognizer.delegate = self;
        _rotationGestureRecognizer.cancelsTouchesInView = NO;
    }
    
    return _rotationGestureRecognizer;
}

- (UITapGestureRecognizer *)tapGestureRecognizer
{
    if (_tapGestureRecognizer == nil) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideImage:)];
    }
    
    return _tapGestureRecognizer;
}

- (UIPanGestureRecognizer *) panGestureRecognizer
{
    if (_panGestureRecognizer == nil) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handleGesture:)];
        _panGestureRecognizer.delegate = self;
        _panGestureRecognizer.cancelsTouchesInView = NO;
    }
    
    return _panGestureRecognizer;
}

@end
