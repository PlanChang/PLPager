//
//  PLPagerViewController.m
//  PLPagerDemo
//
//  Created by changshitong on 2018/9/13.
//  Copyright © 2018年 PLAN. All rights reserved.
//

#import "PLPagerViewController.h"

@interface PLPagerViewController () <UIScrollViewDelegate>
//@property (readonly) NSArray *pagerChildViewControllers;
@property (nonatomic) NSUInteger currentIndex;
@end

@implementation PLPagerViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self defaultConfiguration];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self initContainerView];
    
    [self updateContentForContainerView];
}

- (void)initContainerView
{
    self.containerView.backgroundColor = [UIColor redColor];
    self.containerView.frame = self.view.bounds;
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.containerView];
    
    if (self.dataSource){
        _pagerChildViewControllers = [self.dataSource childViewControllersForPagerViewController:self];
    }
}

#pragma mark - Setup

- (void)defaultConfiguration
{
    self.currentIndex = 0;
    self.dataSource = self;
}

- (void)updateContentForContainerView
{
    //更新containerView contentSize
    CGSize containerContentSize = CGSizeMake([self pageWidth] * [self numberOfChildViewControllers], [self pageHeight]);
    [self.containerView setContentSize:containerContentSize];
    
    NSLog(@"===%@",NSStringFromCGSize(containerContentSize));
    
    //添加childViewController
    UIViewController *childViewController = [self childViewControllerAtIndex:self.currentIndex];
    CGPoint offset = [self offsetWithIndex:self.currentIndex];
    if (![[childViewController presentationController] isEqual:self]) {
        [self addChildViewController:childViewController];
        [childViewController didMoveToParentViewController:self];
        
        childViewController.view.frame = CGRectMake(offset.x, 0, [self pageWidth], [self pageHeight]);
        childViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        [childViewController beginAppearanceTransition:YES animated:YES];
        [self.containerView addSubview:childViewController.view];
        [childViewController endAppearanceTransition];
    } else {
        [childViewController.view setFrame:CGRectMake(offset.x, 0, MIN(CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.containerView.bounds)), CGRectGetHeight(self.containerView.bounds))];
        childViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    
    //update currIndex
    NSInteger lastIndex = self.currentIndex;
    NSInteger virtualPage = [self virtualPageForContentOffset:self.containerView.contentOffset.x];
    NSUInteger newCurrentIndex = [self pageForVirtualPage:virtualPage];
    self.currentIndex = newCurrentIndex;
    BOOL changeCurrentIndex = newCurrentIndex != lastIndex;
    
    NSLog(@"curr index = %ld",self.currentIndex);
}

- (void)reloadPagerView
{
    if ([self isViewLoaded]){
        [self.pagerChildViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIViewController * childController = (UIViewController *)obj;
            if ([childController parentViewController]){
                [childController.view removeFromSuperview];
                [childController willMoveToParentViewController:nil];
                [childController removeFromParentViewController];
            }
        }];
        _pagerChildViewControllers = self.dataSource ? [self.dataSource childViewControllersForPagerViewController:self] : @[];
        self.containerView.contentSize = CGSizeMake([self pageWidth] * [self numberOfChildViewControllers], self.containerView.contentSize.height);
        if (self.currentIndex >= [self numberOfChildViewControllers]){
            self.currentIndex = [self numberOfChildViewControllers] - 1;
        }
        [self.containerView setContentOffset:[self offsetWithIndex:self.currentIndex]  animated:NO];
        [self updateContentForContainerView];
    }
}

#pragma mark - DataSource

- (NSArray *)childViewControllersForPagerViewController:(PLPagerViewController *)controller
{
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor yellowColor];
    
    UIViewController *vc2 = [[UIViewController alloc] init];
    vc2.view.backgroundColor = [UIColor blueColor];
    
    return @[vc,vc2];
}

#pragma mark - UIScrollViewDelegte

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView){
        [self updateContentForContainerView];
    }
}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView){
//        _lastPageNumber = [self pageForContentOffset:scrollView.contentOffset.x];
//        _lastContentOffset = scrollView.contentOffset.x;
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView && _pagerChildViewControllers){
        _pagerChildViewControllers = nil;
        [self updateContentForContainerView];
    }
    
    if (self.navigationController){
        self.navigationController.view.userInteractionEnabled = YES;
    } else {
        self.view.userInteractionEnabled = YES;
    }
}

#pragma mark - getter

- (UIScrollView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIScrollView alloc] init];
        _containerView.clipsToBounds = YES;
        _containerView.bounces = YES;
        [_containerView setAlwaysBounceHorizontal:YES];
        [_containerView setAlwaysBounceVertical:NO];
        _containerView.scrollsToTop = NO;
        _containerView.delegate = self;
        _containerView.showsVerticalScrollIndicator = NO;
        _containerView.showsHorizontalScrollIndicator = NO;
        _containerView.pagingEnabled = YES;
    }
    return _containerView;
}

#pragma mark - Private helper

- (CGFloat)pageWidth
{
    return CGRectGetWidth(self.containerView.bounds);
}
- (CGFloat)pageHeight
{
    return CGRectGetHeight(self.containerView.bounds);
}

-(NSInteger)virtualPageForContentOffset:(CGFloat)contentOffset
{
    NSInteger result = (contentOffset + (1.5f * [self pageWidth])) / [self pageWidth];
    return result - 1;
}

-(NSUInteger)pageForVirtualPage:(NSInteger)virtualPage
{
    if (virtualPage < 0){
        return 0;
    }
    if (virtualPage > [self numberOfChildViewControllers] - 1){
        return [self numberOfChildViewControllers] - 1;
    }
    return virtualPage;
}

//获取 页码 或 位移
- (CGPoint)offsetWithIndex:(NSInteger)index
{
    return CGPointMake([self pageWidth] * index, 0);
}
- (NSInteger)indexWithOffset:(CGFloat)offset
{
    return offset / [self pageWidth];
}

//dataSource
- (NSInteger)numberOfChildViewControllers
{
    return self.pagerChildViewControllers.count;
}
- (UIViewController *)childViewControllerAtIndex:(NSInteger)index
{
    if (index < self.pagerChildViewControllers.count) {
        return [self.pagerChildViewControllers objectAtIndex:index];
    }
    return nil;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
