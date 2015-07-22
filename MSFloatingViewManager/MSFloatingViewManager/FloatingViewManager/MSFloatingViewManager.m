//
//  MSFloatingViewManager.m
//
//  Created by Changwoo, Kim on 2015. 7. 20..
//  Copyright (c) 2015년 MS. All rights reserved.
//

#import "MSFloatingViewManager.h"
#import <objc/runtime.h>

#define FLOATING_VIEW_DICTIONARY_KEY_SWIZZLING_KEY  @"swizzlingKey"
#define FLOATING_VIEW_DICTIONARY_KEY_CORE_KEY       @"coreKey"

#define FLOATING_VIEW_DID_SCROLL_IMP_KEY            @"floatingViewDidScrollImpKey"
#define FLOATING_VIEW_WILL_BEGIN_DRAGGING_IMP_KEY   @"floatingViewWillBeginDraggingImpKey"
#define FLOATING_VIEW_DID_END_DRAGGING_IMP_KEY      @"floatingViewDidEndDraggingImpKey"
#define FLOATING_VIEW_DID_END_DECELERATING_IMP_KEY  @"floatingViewDidEndDeceleratingImpKey"



// ######################################################################################################################## //
// #################################################   Inner Class   ###################################################### //
// ######################################################################################################################## //

#define UNDEFINED_OFFSET    CGPointMake(CGFLOAT_MAX, CGFLOAT_MAX)


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
@property (nonatomic) MSFloatingViewManagerDynamicResizableViewOption dynamicResizableViewOption;   // Default: header.
@property (nonatomic, strong) UIView *dynamicResizableView;                                         // Default: scrollView.

@property (nonatomic) CGFloat floatingDistance;                                 // Default: headerView height.
@property (nonatomic) CGFloat distanceAtTheTopOfScrollWhenHeaderViewHidden;     // Default: floatingDistance

@property (nonatomic) BOOL enableFloatingViewAnimation;                     // Default: YES
@property (nonatomic) BOOL floatingViewAnimationOnlyTopOfScrollView;        // Default: NO
@property (nonatomic) BOOL alphaEffectWhenHidding;                          // Default: NO

@property (nonatomic) CGRect originHeaderViewFrame;                         // Default: headerView's frame
@property (nonatomic) CGRect originDynamicResizableViewFrame;               // Default: dynamicResizableView's frame

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, assign) CGPoint lastContentOffset;
@property (nonatomic) BOOL isScrollViewJustBeingDragging;

@property (nonatomic, strong) NSString *callingObjectAddress;
@property (nonatomic, strong) NSString *swizzlingKey;

#pragma mark - Initialize Methods
- (id)initForScrollView:(UIScrollView *)scrollView headerView:(UIView *)headerView;

#pragma mark - Inner Public Methods
- (void)switchScrollView:(UIScrollView *)scrollView;
- (void)resetSubviewsLayout;

@end


@implementation MSFloatingViewManagerCore


#pragma mark - Initialize Methods

- (id)initForScrollView:(UIScrollView *)scrollView headerView:(UIView *)headerView
{
    self = [super init];
    if (self) {
        _scrollView = scrollView;
        
        _dynamicResizableView = _scrollView;
        _originDynamicResizableViewFrame = _dynamicResizableView.frame;
        _dynamicResizableViewOption = MSFloatingViewManagerDynamicViewResizeOptionHeader;
        
        CGFloat headerViewHeight = 0.f;
        _headerView = headerView;
        if (_headerView != nil) {
            _originHeaderViewFrame = _headerView.frame;
            headerViewHeight = _headerView.frame.size.height;
        }
        
        _floatingDistance = headerViewHeight;
        _distanceAtTheTopOfScrollWhenHeaderViewHidden = _floatingDistance;
        
        _floatingOption = MSFloatingViewManagerFloatingOptionHeader;
        
        _lastContentOffset = UNDEFINED_OFFSET;
        
        _enableFloatingViewAnimation = YES;
        _floatingViewAnimationOnlyTopOfScrollView = NO;
        _alphaEffectWhenHidding = NO;
        _isScrollViewJustBeingDragging = NO;
    }
    
    return self;
}


#pragma mark - Inner Public Methods

- (void)switchScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    _lastContentOffset = UNDEFINED_OFFSET;
}

- (void)resetSubviewsLayout
{
    _lastContentOffset = UNDEFINED_OFFSET;
    
    [_headerView setFrame:_originHeaderViewFrame];
    [_headerView setAlpha:1.0f];
    
    [_dynamicResizableView setFrame:_originDynamicResizableViewFrame];
}


#pragma mark - Inner Private Methods

- (void)moveFloatingViewsToFit
{
    if (_floatingOption == MSFloatingViewManagerFloatingOptionNone) {
        return;
    }
    
    if (!_enableFloatingViewAnimation) {
        return;
    }
    
    CGFloat gapBetweenOriginAndCurrentHeaderViewFrame = fabs(_originHeaderViewFrame.origin.y - _headerView.frame.origin.y);
    // move to hide
    if ((gapBetweenOriginAndCurrentHeaderViewFrame > _floatingDistance / 2) && ![self isHeaderViewStatusHide]) {
        [self hideFloatings:YES];
    }
    
    // move to show
    else if ((gapBetweenOriginAndCurrentHeaderViewFrame <= _floatingDistance / 2) && ![self isHeaderViewStatusShow]) {
        [self showFloatings:YES];
    }
}


- (void)showFloatings:(BOOL)animated
{
    CGFloat gapBetweenOriginAndCurrentHeaderViewFrame = fabs(_originHeaderViewFrame.origin.y - _headerView.frame.origin.y);
    CGFloat yPoint = MAX(_scrollView.contentOffset.y - gapBetweenOriginAndCurrentHeaderViewFrame, 0);
    [_scrollView setContentOffset:CGPointMake(0, yPoint) animated:animated];
}


- (void)hideFloatings:(BOOL)animated
{
    CGFloat gapBetweenOriginAndCurrentHeaderViewFrame = fabs(_originHeaderViewFrame.origin.y - _headerView.frame.origin.y);
    [_scrollView setContentOffset:CGPointMake(0, _scrollView.contentOffset.y + (_floatingDistance - gapBetweenOriginAndCurrentHeaderViewFrame)) animated:animated];
}


- (void)moveFloatingHeaderViewRelativelyFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
    CGFloat delta = toPoint.y - fromPoint.y;
    
    CGRect headerFrame = _headerView.frame;
    CGFloat beforeHeaderViewOriginY = _headerView.frame.origin.y;
    CGFloat afterHeaderViewOriginY = MIN(MAX(headerFrame.origin.y - delta, CGRectGetMinY(_originHeaderViewFrame) - _floatingDistance), CGRectGetMinY(_originHeaderViewFrame));
    if (beforeHeaderViewOriginY == afterHeaderViewOriginY) {
        return;
    }
    
    headerFrame.origin.y = afterHeaderViewOriginY;
    [_headerView setFrame:headerFrame];
    
    if (_alphaEffectWhenHidding) {
        CGFloat alpha =  1 - (fabs(headerFrame.origin.y - CGRectGetMinY(_originHeaderViewFrame)) / _floatingDistance);
        [_headerView setAlpha:alpha];
    }
    
    // resize scrollView
    [self resizeDynamicResizableViewWithBeforeHeaderViewOriginY:beforeHeaderViewOriginY afterHeaderViewOriginY:afterHeaderViewOriginY];
}

- (void)resizeDynamicResizableViewWithBeforeHeaderViewOriginY:(CGFloat)beforeHeaderViewOriginY afterHeaderViewOriginY:(CGFloat)afterHeaderViewOriginY
{
    CGFloat headerViewMovedDelta = beforeHeaderViewOriginY - afterHeaderViewOriginY;
    CGRect viewRect = _dynamicResizableView.frame;
    viewRect.origin.y -= headerViewMovedDelta;
    viewRect.size.height += headerViewMovedDelta;
    
    [_dynamicResizableView setFrame:viewRect];
}

- (BOOL)isHeaderViewStatusHide
{
    return _originHeaderViewFrame.origin.y - _floatingDistance == _headerView.frame.origin.y;
}

- (BOOL)isHeaderViewStatusShow
{
    return _originHeaderViewFrame.origin.y == _headerView.frame.origin.y;
}


#pragma mark - Scroll Event Handle Methods

- (void)scrollViewDidScroll
{
    // if floatingOption is none, return
    if (_floatingOption == MSFloatingViewManagerFloatingOptionNone) {
        return;
    }
    
    // if lastConentOffset is equals to current one, return
    if (_scrollView.contentOffset.y == _lastContentOffset.y) {
        return;
    }
    
    // if scrollView's height is less then actual floating distance, return
    if (_floatingDistance + _originDynamicResizableViewFrame.size.height >= _scrollView.contentSize.height) {
        return;
    }
    
    CGPoint offset = _lastContentOffset;
    _lastContentOffset = _scrollView.contentOffset;
    
    // if lastContentOffset is UNDEFINE, return
    if (CGPointEqualToPoint(offset, UNDEFINED_OFFSET)) {
        return;
    }
    
    // if floatingViewAnimation turned off, return
    if (!_enableFloatingViewAnimation) {
        return;
    }
    
    // ignore bouncing at the bottom at the bottom of scrollView
    CGFloat value = _scrollView.contentSize.height - _scrollView.bounds.size.height - _scrollView.contentOffset.y;
    if (value <= 0) {
        return;
    }
    
    // ignore bouncing at the top of scrollView
    if (_headerView.frame.origin.y >= 0 && _scrollView.contentOffset.y <= 0) {
        return;
    }
    
    // ignore scrolling event when floatingViewAnimationOnlyTopOfScrollView is setted
    if (_floatingViewAnimationOnlyTopOfScrollView && (_lastContentOffset.y > _headerView.frame.size.height) &&
        _headerView.frame.origin.y <= _originHeaderViewFrame.origin.y - _floatingDistance) {
        return;
    }
    
    // ignore scrolling event when scrollViewContentOffset is not enough to hide headerView
    BOOL isScrollViewContentOffsetSizeBigEnough = CGRectGetHeight(_scrollView.frame) + _distanceAtTheTopOfScrollWhenHeaderViewHidden <= _scrollView.contentSize.height;
    if (!isScrollViewContentOffsetSizeBigEnough) {
        return;
    }
    
    // scrollViewContentOffset reset when headerView hidden and scrollingDown from the top
    if (_isScrollViewJustBeingDragging) {
        _isScrollViewJustBeingDragging = NO;
        
        BOOL isScrollingDown = (offset.y != UNDEFINED_OFFSET.y && _lastContentOffset.y - offset.y <= 0);
        BOOL isScrollViewOffsetInResetBoundary = _lastContentOffset.y < _distanceAtTheTopOfScrollWhenHeaderViewHidden;
        if ([self isHeaderViewStatusHide] && isScrollingDown && isScrollViewOffsetInResetBoundary) {
            [_scrollView setContentOffset:CGPointMake(0, _distanceAtTheTopOfScrollWhenHeaderViewHidden) animated:NO];
            _lastContentOffset = CGPointMake(0, _distanceAtTheTopOfScrollWhenHeaderViewHidden);
        }
        return;
    }
    
    // move headerView
    if (_floatingOption == MSFloatingViewManagerFloatingOptionHeader) {
        [self moveFloatingHeaderViewRelativelyFromPoint:offset toPoint:_scrollView.contentOffset];
    }
}


- (void)scrollViewWillBeginDragging
{
    _isScrollViewJustBeingDragging = YES;
}

- (void)scrollViewDidEndDraggingWithWillDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self moveFloatingViewsToFit];
    }
}

- (void)scrollViewDidEndDecelerating
{
    [self moveFloatingViewsToFit];
}


#pragma mark - Setty, Getty Methods

- (void)setDynamicResizableView:(UIView *)dynamicResizableView
{
    _dynamicResizableView = dynamicResizableView;
    _originDynamicResizableViewFrame = _dynamicResizableView.frame;
}

@end





// ######################################################################################################################## //

/**
 *  Data Structure <callingObjectDictionary>
 *  callingObjectAddress : {
 *      swizzlingKey : [key]
 *      core : [floatingViewManagerCore]
 *  }
 */
static NSMutableDictionary *callingObjectDictionary;

/**
 *  Data Structure <swizzlingKeyDictionary>
 *  swizzlingKey : {
 *      FLOATING_VIEW_DID_SCROLL_IMP_KEY : [imp]
 *      FLOATING_VIEW_WILL_BEGIN_DRAGGING_IMP_KEY : [imp]
 *      FLOATING_VIEW_DID_END_DRAGGING_IMP_KEY : [imp]
 *      FLOATING_VIEW_DID_END_DECELERATING_IMP_KEY : [imp]
 *  }
 */
static NSMutableDictionary *swizzlingKeyDictionary;

@interface MSFloatingViewManager()

@property (nonatomic, strong) MSFloatingViewManagerCore *floatingViewManagerCore;
@property (nonatomic, strong) NSString *callingObjectAddress;
@property (nonatomic, strong) NSString *swizzlingKey;

@end


@implementation MSFloatingViewManager

#pragma mark - Initialize Methods

- (id)initWithCallingObject:(id)callingObject scrollView:(UIScrollView *)scrollView headerView:(UIView *)headerView
{
    self = [super init];
    if (self) {
        NSString *swizzlingKey = NSStringFromClass([callingObject class]);
        
        // 01. save callingObject's original implements in stack just once
        [self scrollViewDelegateMethodSwizzling:callingObject scrollView:scrollView swizzlingKey:swizzlingKey];
        
        // 02. save callingObject's information in stack if not exist (refreshable data)
        [self saveCallingObjectInformationWithCallingObject:callingObject scrollView:scrollView headerView:headerView];
    }
    
    return self;
}

- (void)dealloc
{
    [[self callingObjectDictionary] removeObjectForKey:_callingObjectAddress];
}

#pragma mark - Public Methods

- (void)switchScrollView:(UIScrollView *)scrollView
{
    [_floatingViewManagerCore switchScrollView:scrollView];
}

- (void)resetSubviewsLayout
{
    [_floatingViewManagerCore resetSubviewsLayout];
}


#pragma mark - Private Methods

- (void)scrollViewDelegateMethodSwizzling:(id)callingObject scrollView:(UIScrollView *)scrollView swizzlingKey:(NSString *)swizzlingKey
{
    _swizzlingKey = swizzlingKey;
    if (swizzlingKey == nil || [swizzlingKeyDictionary objectForKey:swizzlingKey] != nil) {
        return;
    }
    
    NSMutableDictionary *scrollViewDelegateImpDictionary = [NSMutableDictionary new];
    IMP __original_ScrollViewDidScroll_Imp = NULL;
    IMP __original_ScrollViewWillBeginDragging_Imp = NULL;
    IMP __original_ScrollViewDidEndDragging_Imp = NULL;
    IMP __original_scrollViewDidEndDecelerating_Imp = NULL;
    
    // - (void)scrollViewDidScroll:(id)scrollView
    SEL sel = @selector(scrollViewDidScrollByFloatingViewManager:);
    Method method = class_getInstanceMethod([self class], sel);
    Method scrollViewDidScrollMethod = class_getInstanceMethod([callingObject class], @selector(scrollViewDidScroll:));
    if (scrollViewDidScrollMethod) {
        __original_ScrollViewDidScroll_Imp = method_setImplementation(scrollViewDidScrollMethod, method_getImplementation(method));
    } else {
        class_addMethod([callingObject class], @selector(scrollViewDidScroll:), method_getImplementation(method), method_getTypeEncoding(method));
    }
    
    // - (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
    sel = @selector(scrollViewWillBeginDraggingByFloatingViewManager:);
    method = class_getInstanceMethod([self class], sel);
    Method scrollViewWillBeginDraggingMethod = class_getInstanceMethod([callingObject class], @selector(scrollViewWillBeginDragging:));
    if (scrollViewWillBeginDraggingMethod) {
        __original_ScrollViewWillBeginDragging_Imp = method_setImplementation(scrollViewWillBeginDraggingMethod, method_getImplementation(method));
    } else {
        class_addMethod([callingObject class], @selector(scrollViewWillBeginDragging:), method_getImplementation(method), method_getTypeEncoding(method));
    }
    
    // - (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
    sel = @selector(scrollViewDidEndDraggingByFloatingViewManager:willDecelerate:);
    method = class_getInstanceMethod([self class], sel);
    Method scrollViewDidEndDraggingMethod = class_getInstanceMethod([callingObject class], @selector(scrollViewDidEndDragging:willDecelerate:));
    if (scrollViewDidEndDraggingMethod) {
        __original_ScrollViewDidEndDragging_Imp = method_setImplementation(scrollViewDidEndDraggingMethod, method_getImplementation(method));
    } else {
        class_addMethod([callingObject class], @selector(scrollViewDidEndDragging:willDecelerate:), method_getImplementation(method), method_getTypeEncoding(method));
    }
    
    // - (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
    sel = @selector(scrollViewDidEndDeceleratingByFloatingViewManager:);
    method = class_getInstanceMethod([self class], sel);
    Method scrollViewDidEndDeceleratingMethod = class_getInstanceMethod([callingObject class], @selector(scrollViewDidEndDecelerating:));
    if (scrollViewDidEndDeceleratingMethod) {
        __original_scrollViewDidEndDecelerating_Imp = method_setImplementation(scrollViewDidEndDeceleratingMethod, method_getImplementation(method));
    } else {
        class_addMethod([callingObject class], @selector(scrollViewDidEndDecelerating:), method_getImplementation(method), method_getTypeEncoding(method));
    }
    
    [scrollViewDelegateImpDictionary setObject:[NSValue valueWithPointer:__original_ScrollViewDidScroll_Imp] forKey:FLOATING_VIEW_DID_SCROLL_IMP_KEY];
    [scrollViewDelegateImpDictionary setObject:[NSValue valueWithPointer:__original_ScrollViewWillBeginDragging_Imp] forKey:FLOATING_VIEW_WILL_BEGIN_DRAGGING_IMP_KEY];
    [scrollViewDelegateImpDictionary setObject:[NSValue valueWithPointer:__original_ScrollViewDidEndDragging_Imp] forKey:FLOATING_VIEW_DID_END_DRAGGING_IMP_KEY];
    [scrollViewDelegateImpDictionary setObject:[NSValue valueWithPointer:__original_scrollViewDidEndDecelerating_Imp] forKey:FLOATING_VIEW_DID_END_DECELERATING_IMP_KEY];
    
    [[self swizzlingKeyDictionary] setObject:scrollViewDelegateImpDictionary forKey:swizzlingKey];
    
    [scrollView setDelegate:nil];
    [scrollView setDelegate:callingObject];
}

- (void)saveCallingObjectInformationWithCallingObject:(id)callingObject scrollView:(UIScrollView *)scrollView headerView:(UIView *)headerView
{
    if (callingObject == nil) {
        return;
    }
    
    _floatingViewManagerCore = [[MSFloatingViewManagerCore alloc] initForScrollView:scrollView headerView:headerView];
    
    NSDictionary *callingObjectDetailDictionary = [NSDictionary dictionaryWithObjects:@[_swizzlingKey, _floatingViewManagerCore]
                                                                              forKeys:@[FLOATING_VIEW_DICTIONARY_KEY_SWIZZLING_KEY, FLOATING_VIEW_DICTIONARY_KEY_CORE_KEY]];
    
    _callingObjectAddress = [NSString stringWithFormat:@"%p", callingObject];
    if ([[self callingObjectDictionary] objectForKey:_callingObjectAddress] != nil) {
        [[self callingObjectDictionary] removeObjectForKey:_callingObjectAddress];
    }
    
    [[self callingObjectDictionary] setObject:callingObjectDetailDictionary forKey:_callingObjectAddress];
}


#pragma mark - Custom ScrollViewDelegate Methods

- (void)scrollViewDidScrollByFloatingViewManager:(id)scrollView
{
    NSString *callingObjectAddress = [NSString stringWithFormat:@"%p", self];
    NSDictionary *callingObjectDetailDictionary = [callingObjectDictionary objectForKey:callingObjectAddress];
    
    MSFloatingViewManagerCore *core = [callingObjectDetailDictionary objectForKey:FLOATING_VIEW_DICTIONARY_KEY_CORE_KEY];
    NSString *swizzlingKey = [callingObjectDetailDictionary objectForKey:FLOATING_VIEW_DICTIONARY_KEY_SWIZZLING_KEY];
    if (core == nil || swizzlingKey == nil) {
        return;
    }
    
    NSMutableDictionary *scrollViewDelegateImpDictionary = [swizzlingKeyDictionary objectForKey:swizzlingKey];
    if (scrollViewDelegateImpDictionary == nil) {
        return;
    }
    
    [core scrollViewDidScroll];
    
    NSValue *value = [scrollViewDelegateImpDictionary objectForKey:FLOATING_VIEW_DID_SCROLL_IMP_KEY];
    IMP originalImp = [value pointerValue];
    if (originalImp) {
        void (*func)(__strong id, SEL, UIScrollView *) = (void (*)(__strong id, SEL, UIScrollView *))originalImp;
        func(self, _cmd, core.scrollView);
    }
}

- (void)scrollViewWillBeginDraggingByFloatingViewManager:(id)scrollView
{
    NSString *callingObjectAddress = [NSString stringWithFormat:@"%p", self];
    NSDictionary *callingObjectDetailDictionary = [callingObjectDictionary objectForKey:callingObjectAddress];
    
    MSFloatingViewManagerCore *core = [callingObjectDetailDictionary objectForKey:FLOATING_VIEW_DICTIONARY_KEY_CORE_KEY];
    NSString *swizzlingKey = [callingObjectDetailDictionary objectForKey:FLOATING_VIEW_DICTIONARY_KEY_SWIZZLING_KEY];
    if (core == nil || swizzlingKey == nil) {
        return;
    }
    
    NSMutableDictionary *scrollViewDelegateImpDictionary = [swizzlingKeyDictionary objectForKey:swizzlingKey];
    if (scrollViewDelegateImpDictionary == nil) {
        return;
    }
    
    [core scrollViewWillBeginDragging];
    
    NSValue *value = [scrollViewDelegateImpDictionary objectForKey:FLOATING_VIEW_WILL_BEGIN_DRAGGING_IMP_KEY];
    IMP originalImp = [value pointerValue];
    if (originalImp) {
        void (*func)(__strong id,SEL,...) = (void (*)(__strong id, SEL, ...))originalImp;
        func(self, _cmd, scrollView);
    }
}

- (void)scrollViewDidEndDraggingByFloatingViewManager:(id)scrollView willDecelerate:(BOOL)decelerate
{
    NSString *callingObjectAddress = [NSString stringWithFormat:@"%p", self];
    NSDictionary *callingObjectDetailDictionary = [callingObjectDictionary objectForKey:callingObjectAddress];
    
    MSFloatingViewManagerCore *core = [callingObjectDetailDictionary objectForKey:FLOATING_VIEW_DICTIONARY_KEY_CORE_KEY];
    NSString *swizzlingKey = [callingObjectDetailDictionary objectForKey:FLOATING_VIEW_DICTIONARY_KEY_SWIZZLING_KEY];
    if (core == nil || swizzlingKey == nil) {
        return;
    }
    
    NSMutableDictionary *scrollViewDelegateImpDictionary = [swizzlingKeyDictionary objectForKey:swizzlingKey];
    if (scrollViewDelegateImpDictionary == nil) {
        return;
    }
    
    [core scrollViewDidEndDraggingWithWillDecelerate:decelerate];
    
    NSValue *value = [scrollViewDelegateImpDictionary objectForKey:FLOATING_VIEW_DID_END_DRAGGING_IMP_KEY];
    IMP originalImp = [value pointerValue];
    if (originalImp) {
        void (*func)(__strong id,SEL,...) = (void (*)(__strong id, SEL, ...))originalImp;
        func(self, _cmd, scrollView);
    }
}

- (void)scrollViewDidEndDeceleratingByFloatingViewManager:(id)scrollView
{
    NSString *callingObjectAddress = [NSString stringWithFormat:@"%p", self];
    NSDictionary *callingObjectDetailDictionary = [callingObjectDictionary objectForKey:callingObjectAddress];
    
    MSFloatingViewManagerCore *core = [callingObjectDetailDictionary objectForKey:FLOATING_VIEW_DICTIONARY_KEY_CORE_KEY];
    NSString *swizzlingKey = [callingObjectDetailDictionary objectForKey:FLOATING_VIEW_DICTIONARY_KEY_SWIZZLING_KEY];
    if (core == nil || swizzlingKey == nil) {
        return;
    }
    
    NSMutableDictionary *scrollViewDelegateImpDictionary = [swizzlingKeyDictionary objectForKey:swizzlingKey];
    if (scrollViewDelegateImpDictionary == nil) {
        return;
    }
    
    [core scrollViewDidEndDecelerating];
    
    NSValue *value = [scrollViewDelegateImpDictionary objectForKey:FLOATING_VIEW_DID_END_DECELERATING_IMP_KEY];
    IMP originalImp = [value pointerValue];
    if (originalImp) {
        void (*func)(__strong id,SEL,...) = (void (*)(__strong id, SEL, ...))originalImp;
        func(self, _cmd, scrollView);
    }
}


#pragma mark - Setty, Getty Methods

- (NSMutableDictionary *)swizzlingKeyDictionary
{
    if (!swizzlingKeyDictionary) {
        swizzlingKeyDictionary = [NSMutableDictionary new];
    }
    
    return swizzlingKeyDictionary;
}

- (NSMutableDictionary *)callingObjectDictionary
{
    if (!callingObjectDictionary) {
        callingObjectDictionary = [NSMutableDictionary new];
    }
    
    return callingObjectDictionary;
}

- (void)setFloatingDistance:(CGFloat)floatingDistance
{
    [_floatingViewManagerCore setFloatingDistance:floatingDistance];
}

- (void)setEnableFloatingViewAnimation:(BOOL)enableFloatingViewAnimation
{
    [_floatingViewManagerCore setEnableFloatingViewAnimation:enableFloatingViewAnimation];
}

- (void)setAlphaEffectWhenHidding:(BOOL)alphaEffectWhenHidding
{
    [_floatingViewManagerCore setAlphaEffectWhenHidding:alphaEffectWhenHidding];
}


@end
