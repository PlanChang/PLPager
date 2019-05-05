//
//  PLPagerViewController.m
//  PLPagerDemo
//
//  Created by changshitong on 2018/9/13.
//  Copyright © 2018年 PLAN. All rights reserved.
//

#import "PLPagerViewController.h"

typedef NS_ENUM(NSUInteger, PLPagerScrollDirection) {
    PLPagerScrollDirectionNone,
    PLPagerScrollDirectionLeft,
    PLPagerScrollDirectionRight
};

@interface PLPagerViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *containerView;
@property (nonatomic, copy) NSArray *pagerChildViewControllers;
@property (nonatomic, copy) NSArray *childViewControllersForSkip;
@property (nonatomic, assign) NSUInteger currentIndex;
@end

@implementation PLPagerViewController
{
    NSUInteger _lastPageNumber;
    CGFloat _lastContentOffset;
}

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
    self.containerView.frame = self.view.bounds;
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.containerView];
    if (self.dataSource){
        self.pagerChildViewControllers = [self.dataSource childViewControllersForPagerViewController:self];
    }
}

#pragma mark - Setup

- (void)defaultConfiguration
{
    self.currentIndex = 0;
}

- (void)updateContentForContainerView
{
    //更新containerView contentSize
    CGSize containerContentSize = CGSizeMake([self pageWidth] * [self numberOfChildViewControllers], [self pageHeight]);
    [self.containerView setContentSize:containerContentSize];
    
    //添加childViewController
    UIViewController *childViewController = [self childViewControllerAtIndex:self.currentIndex];
    if (!childViewController) {
        return;
    }
    CGPoint offset = [self offsetWithIndex:self.currentIndex];
    if (![[childViewController presentationController] isEqual:self]) {
        [self addChildViewController:childViewController];
        [childViewController didMoveToParentViewController:self];
        childViewController.view.frame = CGRectMake(offset.x, 0, CGRectGetWidth(self.containerView.bounds), CGRectGetHeight(self.containerView.bounds));
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
    
    if (changeCurrentIndex) {
        if ([self.delegate respondsToSelector:@selector(pagerViewController:movedFromIndex:toIndex:)]) {
            [self.delegate pagerViewController:self movedFromIndex:MIN(lastIndex,[self numberOfChildViewControllers] - 1) toIndex:newCurrentIndex];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(pagerViewController:movingFromIndex:toIndex:progress:indexWasChanged:)]) {
        //滑动比例
        CGFloat scrollPercentage = [self scrollPercentage];
        //有效的滑动范围
        CGPoint scrollOffset = self.containerView.contentOffset;
        CGPoint lastPagerOffset = [self offsetWithIndex:[self numberOfChildViewControllers]-1];
        BOOL validScrollBounds = scrollOffset.x >= 0.0 && scrollOffset.x <= lastPagerOffset.x;
        if (scrollPercentage > 0 && validScrollBounds) {
            NSInteger fromIndex = self.currentIndex;
            NSInteger toIndex = self.currentIndex;
            PLPagerScrollDirection scrollDirection = [self scrollDirection];
            //活动方向：当前是向左👈滑动
            if (scrollDirection == PLPagerScrollDirectionLeft) {
                if (virtualPage > [self numberOfChildViewControllers] - 1) {
                    fromIndex = [self numberOfChildViewControllers] - 1;
                    toIndex = [self numberOfChildViewControllers];
                } else {
                    if (scrollPercentage >= 0.5f) {
                        fromIndex = MAX(toIndex - 1, 0);
                    } else {
                        toIndex = fromIndex + 1;
                    }
                }
            }
            //活动方向：当前是向右👉滑动
            else if (scrollDirection == PLPagerScrollDirectionRight) {
                if (virtualPage < 0) {
                    fromIndex = 0;
                    toIndex = -1;
                }  else {
                    if (scrollPercentage > 0.5f) {
                        fromIndex = MIN(toIndex + 1, [self numberOfChildViewControllers] - 1);
                    }
                    else{
                        toIndex = fromIndex - 1;
                    }
                }
            }
            
            CGFloat progress = scrollPercentage;
            changeCurrentIndex = progress > 0.5;
            [self.delegate pagerViewController:self movingFromIndex:fromIndex toIndex:toIndex progress:progress indexWasChanged:changeCurrentIndex];
        }
    }
}

#pragma mark - API

///刷新
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
        self.pagerChildViewControllers = self.dataSource ? [self.dataSource childViewControllersForPagerViewController:self] : @[];
        self.containerView.contentSize = CGSizeMake([self pageWidth] * [self numberOfChildViewControllers], self.containerView.contentSize.height);
        if (self.currentIndex >= [self numberOfChildViewControllers]){
            self.currentIndex = [self numberOfChildViewControllers] - 1;
        }
        [self.containerView setContentOffset:[self offsetWithIndex:self.currentIndex]  animated:NO];
        [self updateContentForContainerView];
    }
}

///移动到指定的试图控制器页面
- (void)moveToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.pagerChildViewControllers.count == 0) return;
    [self moveToViewControllerAtIndex:[self.pagerChildViewControllers indexOfObject:viewController] animated:animated];
}

///移动到指定索引的页面
- (void)moveToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (!self.isViewLoaded || !self.view.window) {
        self.currentIndex = index;
    } else {
        if (self.pagerChildViewControllers.count == 0) return;
        
        if (animated && ABS(self.currentIndex - index) > 1) {
            NSMutableArray * tempChildViewControllers = [NSMutableArray arrayWithArray:self.pagerChildViewControllers];
            UIViewController *currentChildVC = [self.pagerChildViewControllers objectAtIndex:self.currentIndex];
            NSUInteger fromIndex = (self.currentIndex < index) ? index - 1 : index + 1;
            UIViewController *fromChildVC = [self.pagerChildViewControllers objectAtIndex:fromIndex];
            [tempChildViewControllers setObject:fromChildVC atIndexedSubscript:self.currentIndex];
            [tempChildViewControllers setObject:currentChildVC atIndexedSubscript:fromIndex];
            self.childViewControllersForSkip = tempChildViewControllers;
            self.currentIndex = fromIndex;
            [self.containerView setContentOffset:[self offsetWithIndex:fromIndex] animated:NO];
            if (self.navigationController){
                self.navigationController.view.userInteractionEnabled = NO;
            } else {
                self.view.userInteractionEnabled = NO;
            }
        }
        _lastContentOffset = self.containerView.contentOffset.x;
        [self.containerView setContentOffset:[self offsetWithIndex:index] animated:animated];
    }
}

#pragma mark - UIScrollViewDelegte

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView){
        [self updateContentForContainerView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView) {
        _lastPageNumber = [self indexWithOffset:self.containerView.contentOffset.x];
        _lastContentOffset = scrollView.contentOffset.x;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (self.containerView == scrollView && _childViewControllersForSkip){
        self.childViewControllersForSkip = nil;
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
        if (@available(iOS 11.0, *)) {
            _containerView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _containerView;
}

- (NSArray *)currChildViewControllers
{
    return _childViewControllersForSkip? :_pagerChildViewControllers;
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

- (NSInteger)virtualPageForContentOffset:(CGFloat)contentOffset
{
    NSInteger result = (contentOffset + (1.5f * [self pageWidth])) / [self pageWidth];
    return result - 1;
}

- (NSUInteger)pageForVirtualPage:(NSInteger)virtualPage
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
    if (index < [self currChildViewControllers].count) {
        return [[self currChildViewControllers] objectAtIndex:index];
    }
    return nil;
}

// move
- (PLPagerScrollDirection)scrollDirection
{
    if (self.containerView.contentOffset.x > _lastContentOffset){
        return PLPagerScrollDirectionLeft;
    }
    else if (self.containerView.contentOffset.x < _lastContentOffset){
        return PLPagerScrollDirectionRight;
    }
    return PLPagerScrollDirectionNone;
}

- (CGFloat)scrollPercentage
{
    if ([self scrollDirection] == PLPagerScrollDirectionLeft || [self scrollDirection] == PLPagerScrollDirectionNone){
        if (fmodf(self.containerView.contentOffset.x, [self pageWidth]) == 0.0) {
            return 1.0;
        }
        return fmodf(self.containerView.contentOffset.x, [self pageWidth]) / [self pageWidth];
    }
    return 1 - fmodf(self.containerView.contentOffset.x >= 0 ? self.containerView.contentOffset.x : [self pageWidth] + self.containerView.contentOffset.x, [self pageWidth]) / [self pageWidth];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
