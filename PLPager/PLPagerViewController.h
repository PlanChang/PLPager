//
//  PLPagerViewController.h
//  PLPagerDemo
//
//  Created by changshitong on 2018/9/13.
//  Copyright © 2018年 PLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLPagerViewController;
///滑动过程的代理方法：两个方法在满足条件时可同时触发，可根据场景选用
@protocol PLPagerViewControllerDelegate <NSObject>
@optional
/*
 pager自某一页面滑动到另一个页面：仅在滑动比例超过0.5时调用一次
 */
- (void)pagerViewController:(PLPagerViewController *)controller
             movedFromIndex:(NSInteger)fromIndex
                    toIndex:(NSInteger)toIndex;
/*
 pager自某一页面滑动到另一个页面：多次调用，包含上面的代理方法的功能；增加滑动比例进度，滑动比例超过0.5后indexWasChanged=YES
 */
- (void)pagerViewController:(PLPagerViewController *)controller
            movingFromIndex:(NSInteger)fromIndex
                    toIndex:(NSInteger)toIndex
                   progress:(CGFloat)progress
            indexWasChanged:(BOOL)indexWasChanged;
@end

@protocol PLPagerViewControllerDataSource <NSObject>
@required
- (NSArray *)childViewControllersForPagerViewController:(PLPagerViewController *)controller;
@end

@interface PLPagerViewController : UIViewController
@property (nonatomic, readonly) NSArray *pagerChildViewControllers;
@property (nonatomic, readonly) UIScrollView *containerView;
@property (nonatomic, readonly) NSUInteger currentIndex;
@property (nonatomic, weak) id <PLPagerViewControllerDelegate>delegate;
@property (nonatomic, weak) id <PLPagerViewControllerDataSource>dataSource;

- (instancetype)initWithIndex:(NSInteger)defaultIndex;

///移动到指定索引的页面
-(void)moveToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated;
///移动到指定视图控制器的页面
-(void)moveToViewController:(UIViewController *)viewController animated:(BOOL)animated;
///刷新
-(void)reloadPagerView;

/*
 UIScrollView代理方法：子类可以重写该方法
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView NS_REQUIRES_SUPER;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView NS_REQUIRES_SUPER;
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView NS_REQUIRES_SUPER;

@end
