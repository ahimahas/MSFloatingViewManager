//
//  ViewController.m
//  MSFloatingViewManager
//
//  Created by ahimahas on 2015. 7. 21..
//  Copyright (c) 2015년 ahimahas. All rights reserved.
//

#import "ViewController.h"
#import "MSFloatingViewManager.h"

#define TABLE_VIEW_CELL     @"tableViewCell"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) MSFloatingViewManager *floatingViewManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup FloatingViewManager
    _floatingViewManager = [[MSFloatingViewManager alloc] initWithCallingObject:self scrollView:_tableView headerView:_headerView];
    _floatingViewManager.enableFloatingViewAnimation = YES;
    _floatingViewManager.alphaEffectWhenHidding = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // set floatingDistance after autolayout processs has done.
    [_floatingViewManager setFloatingDistance:CGRectGetHeight(_headerView.frame)];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TABLE_VIEW_CELL];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TABLE_VIEW_CELL];
    }
    
    [cell.textLabel setText:[NSString stringWithFormat:@"%ld", (long)indexPath.row]];
    
    return cell;
}


#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}


@end
