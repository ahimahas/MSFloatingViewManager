//
//  MSFloatingViewManager.h
//
//  Created by Changwoo, Kim on 2015. 7. 20..
//  Copyright (c) 2015년 MS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MSFloatingViewManager : NSObject

@property (nonatomic) CGFloat floatingDistance;     // Default: headerView height

/**
 *  Parameters
 *      - callingObject : object that calls floatingViewManager
 *      - scrollView    : 
 *      - headerView    : floated view by scrollView's movement
 */
- (id)initWithCallingObject:(id)callingObject scrollView:(UIScrollView *)scrollView headerView:(UIView *)headerView;

@end
