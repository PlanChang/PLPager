//
//  PLPagerViewController.h
//  PLPagerDemo
//
//  Created by changshitong on 2018/9/13.
//  Copyright © 2018年 PLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLPagerViewController;
@protocol PLPagerViewControllerDelegate <NSObject>
- (void)pagerViewController:(PLPagerViewController *)controller
             movedFromIndex:(NSInteger)fromIndex
                    toIndex:(NSInteger)toIndex;
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
@property (nonatomic, weak) id <PLPagerViewControllerDelegate>delegate;
@property (nonatomic, weak) id <PLPagerViewControllerDataSource>dataSource;
@property (nonatomic, readonly) NSUInteger currentIndex;
@property (nonatomic, assign) BOOL isElasticIndicatorLimit;

///移动到指定索引的页面
-(void)moveToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated;
///移动到指定视图控制器的页面
-(void)moveToViewController:(UIViewController *)viewController animated:(BOOL)animated;

///刷新
-(void)reloadPagerView;

/*
 UIScrollView代理方法：子类如果实现本方法，必须要实现[Super scrollViewDidScroll:scrollView]
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView NS_REQUIRES_SUPER;

@end
