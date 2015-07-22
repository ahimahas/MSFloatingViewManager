//
//  MSFloatingViewManager.h
//
//  Created by Changwoo, Kim on 2015. 7. 20..
//  Copyright (c) 2015년 MS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MSFloatingViewManager : NSObject

@property (nonatomic) CGFloat floatingDistance;         // Default: headerView height
@property (nonatomic) BOOL enableFloatingViewAnimation; // Default: YES
@property (nonatomic) BOOL alphaEffectWhenHidding;      // Default: NO


/**
 *  Initailize Method
 *  Parameters
 *      - callingObject : object that calls floatingViewManager
 *      - scrollView    : scrollView that control header view's floating movement
 *      - headerView    : view that floated by scrollView's movement
 */
- (id)initWithCallingObject:(id)callingObject scrollView:(UIScrollView *)scrollView headerView:(UIView *)headerView;


/**
 *  Change scrollView
 */
- (void)switchScrollView:(UIScrollView *)scrollView;

/**
 *  ResetSubviewsLayout
 */
- (void)resetSubviewsLayout;


@end
