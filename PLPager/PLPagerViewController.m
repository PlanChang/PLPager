//
//  PLPagerViewController.m
//  PLPagerDemo
//
//  Created by changshitong on 2018/9/13.
//  Copyright © 2018年 PLAN. All rights reserved.
//

#import "PLPagerViewController.h"
#import "ContentViewController.h"

typedef NS_ENUM(NSUInteger, PLPagerScrollDirection) {
    PLPagerScrollDirectionNone,
    PLPagerScrollDirectionLeft,
    PLPagerScrollDirectionRight
};

@interface PLPagerViewController () <UIScrollViewDelegate,PLPagerViewControllerDelegate>
@property (nonatomic,copy) NSArray *childViewControllersForSkip;
@property (nonatomic) NSUInteger currentIndex;

@property (nonatomic) UISegmentedControl *segmentControl;

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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self moveToViewControllerAtIndex:5 animated:YES];
    });
    
    [self.view addSubview:self.segmentControl];
    self.segmentControl.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 30);
    
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
    self.dataSource = self;
    self.delegate = self;
    self.skipIntermediateViewControllers = YES;
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
            [self.delegate pagerViewController:self movedFromIndex:MIN(lastIndex,[self numberOfChildViewControllers]-1) toIndex:newCurrentIndex];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(pagerViewController:movingFromIndex:toIndex:progress:indexWasChanged:)]) {
        
        CGFloat scrollPercentage = [self scrollPercentage];
        if (scrollPercentage > 0) {
            NSInteger fromIndex = self.currentIndex;
            NSInteger toIndex = self.currentIndex;
            PLPagerScrollDirection scrollDirection = [self scrollDirection];
            if (scrollDirection == PLPagerScrollDirectionRight){
                
                if (virtualPage > [self numberOfChildViewControllers] - 1) {
                    fromIndex = [self numberOfChildViewControllers] - 1;
                    toIndex = [self numberOfChildViewControllers];
                } else {
                    if (scrollPercentage >= 0.5f){
                        fromIndex = MAX(toIndex - 1, 0);
                    } else {
                        toIndex = fromIndex + 1;
                    }
                }
                
            } else if (scrollDirection == PLPagerScrollDirectionRight) {
                
                if (virtualPage < 0){
                    fromIndex = 0;
                    toIndex = -1;
                    
                }  else {
                    if (scrollPercentage > 0.5f){
                        fromIndex = MIN(toIndex + 1, [self numberOfChildViewControllers] - 1);
                    }
                    else{
                        toIndex = fromIndex - 1;
                    }
                }
            }
            CGFloat progress = (self.isElasticIndicatorLimit ? scrollPercentage : ( toIndex < 0 || toIndex >= [self numberOfChildViewControllers] ? 0 : scrollPercentage ));
            [self.delegate pagerViewController:self movingFromIndex:fromIndex toIndex:toIndex progress:progress indexWasChanged:changeCurrentIndex];
        }
    }
    
}

#pragma mark - API

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

- (void)moveToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (!self.isViewLoaded || !self.view.window) {
        self.currentIndex = index;
    } else {
        if (animated && self.skipIntermediateViewControllers && ABS(self.currentIndex - index) > 1){
            NSMutableArray * tempChildViewControllers = [NSMutableArray arrayWithArray:self.pagerChildViewControllers];
            UIViewController *currentChildVC = [self.pagerChildViewControllers objectAtIndex:self.currentIndex];
            NSUInteger fromIndex = (self.currentIndex < index) ? index - 1 : index + 1;
            UIViewController *fromChildVC = [self.pagerChildViewControllers objectAtIndex:fromIndex];
            [tempChildViewControllers setObject:fromChildVC atIndexedSubscript:self.currentIndex];
            [tempChildViewControllers setObject:currentChildVC atIndexedSubscript:fromIndex];
            self.childViewControllersForSkip = tempChildViewControllers;
            
            [self.containerView setContentOffset:[self offsetWithIndex:fromIndex] animated:NO];
            if (self.navigationController){
                self.navigationController.view.userInteractionEnabled = NO;
            } else {
                self.view.userInteractionEnabled = NO;
            }
            [self.containerView setContentOffset:[self offsetWithIndex:index] animated:YES];
        }
        else{
            [self.containerView setContentOffset:[self offsetWithIndex:index] animated:animated];
        }
    }
}
- (void)moveToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self moveToViewControllerAtIndex:[self.pagerChildViewControllers indexOfObject:viewController] animated:animated];
}

#pragma mark - DataSource

- (NSArray *)childViewControllersForPagerViewController:(PLPagerViewController *)controller
{
    NSMutableArray *array = @[].mutableCopy;
    
    for (int i = 0; i < 20; i++) {
        ContentViewController *vc = [[ContentViewController alloc] init];
        vc.index = i;
        [array addObject:vc];
    }
    
    return array;
}

#pragma mark - Delegate

-(void)pagerViewController:(PLPagerViewController *)controller
            movedFromIndex:(NSInteger)fromIndex
                   toIndex:(NSInteger)toIndex
{
//    NSLog(@"moved fromIndex:%ld toIndex:%ld",fromIndex,toIndex);
}

-(void)pagerViewController:(PLPagerViewController *)controller
           movingFromIndex:(NSInteger)fromIndex
                   toIndex:(NSInteger)toIndex
                  progress:(CGFloat)progress
           indexWasChanged:(BOOL)indexWasChanged
{
    NSLog(@"moving fromIndex:%ld toIndex:%ld progress : %f changed:%@",fromIndex,toIndex,progress,indexWasChanged?@"YES":@"NO");
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
    if (self.containerView == scrollView) {
        _lastPageNumber = [self indexWithOffset:self.containerView.contentOffset.x];
        _lastContentOffset = scrollView.contentOffset.x;
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
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
    if (index < [self currChildViewControllers].count) {
        return [[self currChildViewControllers] objectAtIndex:index];
    }
    return nil;
}

// move
-(PLPagerScrollDirection)scrollDirection
{
    if (self.containerView.contentOffset.x > _lastContentOffset){
        return PLPagerScrollDirectionLeft;
    }
    else if (self.containerView.contentOffset.x < _lastContentOffset){
        return PLPagerScrollDirectionRight;
    }
    return PLPagerScrollDirectionNone;
}

-(CGFloat)scrollPercentage
{
    if ([self scrollDirection] == PLPagerScrollDirectionLeft || [self scrollDirection] == PLPagerScrollDirectionNone){
        if (fmodf(self.containerView.contentOffset.x, [self pageWidth]) == 0.0) {
            return 1.0;
        }
        return fmodf(self.containerView.contentOffset.x, [self pageWidth]) / [self pageWidth];
    }
    return 1 - fmodf(self.containerView.contentOffset.x >= 0 ? self.containerView.contentOffset.x : [self pageWidth] + self.containerView.contentOffset.x, [self pageWidth]) / [self pageWidth];
}

- (void)segmentControlValueChange:(UISegmentedControl *)control
{
    [self moveToViewControllerAtIndex:control.selectedSegmentIndex animated:YES];
}
- (UISegmentedControl *)segmentControl
{
    if (!_segmentControl) {
        _segmentControl = [[UISegmentedControl alloc] init];
        [_segmentControl addTarget:self action:@selector(segmentControlValueChange:) forControlEvents:UIControlEventValueChanged];
        
        for (int i =0;i<20;i++) {
            [_segmentControl insertSegmentWithTitle:[NSString stringWithFormat:@"%d",i] atIndex:i animated:YES];
        }
    }
    return _segmentControl;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
