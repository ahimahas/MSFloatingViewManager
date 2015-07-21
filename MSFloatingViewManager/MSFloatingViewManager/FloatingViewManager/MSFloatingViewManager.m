//
//  MSFloatingViewManager.m
//
//  Created by Changwoo, Kim on 2015. 7. 20..
//  Copyright (c) 2015년 MS. All rights reserved.
//

#import "MSFloatingViewManager.h"
#import "MSFloatingViewManagerCore.h"
#import <objc/runtime.h>

#define FLOATING_VIEW_DICTIONARY_KEY_SWIZZLING_KEY  @"swizzlingKey"
#define FLOATING_VIEW_DICTIONARY_KEY_CORE_KEY       @"coreKey"

#define FLOATING_VIEW_DID_SCROLL_IMP_KEY            @"floatingViewDidScrollImpKey"
#define FLOATING_VIEW_WILL_BEGIN_DRAGGING_IMP_KEY   @"floatingViewWillBeginDraggingImpKey"
#define FLOATING_VIEW_DID_END_DRAGGING_IMP_KEY      @"floatingViewDidEndDraggingImpKey"
#define FLOATING_VIEW_DID_END_DECELERATING_IMP_KEY  @"floatingViewDidEndDeceleratingImpKey"


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

@end
