//
//  MSFloatingViewManagerCore.h
//
//  Created by Changwoo, Kim on 2015. 7. 20..
//  Copyright (c) 2015년 MS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MSFloatingViewManagerFloatingOption) {
    MSFloatingViewManagerFloatingOptionNone     = 0,
    MSFloatingViewManagerFloatingOptionHeader   = 1,
};

typedef NS_ENUM(NSInteger, MSFloatingViewManagerDynamicResizableViewOption) {
    MSFloatingViewManagerDynamicViewResizeOptionNone     = 0,
    MSFloatingViewManagerDynamicViewResizeOptionHeader   = 1,
};


@interface MSFloatingViewManagerCore : NSObject

@property (nonatomic) MSFloatingViewManagerFloatingOption floatingOption;                           // Default: header.
@property (nonatomic, strong) UIView *dynamicResizableView;                                         // Default: scrollView.
@property (nonatomic) MSFloatingViewManagerDynamicResizableViewOption dynamicResizableViewOption;   // Default: header.

@property (nonatomic) CGFloat floatingDistance;                                 // Default: headerView height.
@property (nonatomic) CGFloat distanceAtTheTopOfScrollWhenHeaderViewHidden;     // Default: floatingDistance

@property (nonatomic) BOOL floatingViewAnimation;                           // Default: YES
@property (nonatomic) BOOL floatingViewAnimationOnlyTopOfScrollView;        // Default: NO
@property (nonatomic) BOOL alphaEffectWhenHidding;                          // Default: NO

@property (nonatomic) CGRect originHeaderViewFrame;                         // Default: headerView's frame
@property (nonatomic) CGRect originDynamicResizableViewFrame;               // Default: dynamicResizableView's frame

@property (nonatomic, strong) UIScrollView *scrollView;


#pragma mark - Initialize Methods
- (id)initForScrollView:(UIScrollView *)scrollView headerView:(UIView *)headerView;
- (id)initForScrollView:(UIScrollView *)scrollView headerView:(UIView *)headerView callingObject:(id)callingObject swizzlingKey:(NSString *)swizzlingKey;


#pragma mark - Public Methods
- (void)switchScrollView:(UIScrollView *)scrollView;
- (void)resetLastContentsOffset;
- (void)initializeSubviewsLayout;


#pragma mark - Scroll Event Handle Methods
- (void)scrollViewDidScroll;
- (void)scrollViewWillBeginDragging;
- (void)scrollViewDidEndDraggingWithWillDecelerate:(BOOL)decelerate;
- (void)scrollViewDidEndDecelerating;

- (void)showFloatings:(BOOL)animated;
- (void)hideFloatings:(BOOL)animated;

@end
