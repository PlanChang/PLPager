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
- (void)pagerViewController:(PLPagerViewController *)controller didSelectedChildViewControllerAtIndex:(NSInteger)index;
@end


@protocol PLPagerViewControllerDataSource <NSObject>

@required
- (NSArray *)childViewControllersForPagerViewController:(PLPagerViewController *)controller;

@end



@interface PLPagerViewController : UIViewController <PLPagerViewControllerDataSource>

@property (readonly) NSArray *pagerChildViewControllers;
@property (nonatomic, strong) UIScrollView *containerView;
@property (nonatomic, weak) id <PLPagerViewControllerDelegate>delegate;
@property (nonatomic, weak) id <PLPagerViewControllerDataSource>dataSource;

@property (readonly) NSUInteger currentIndex;
@property BOOL skipIntermediateViewControllers;
@property BOOL isProgressiveIndicator;
@property BOOL isElasticIndicatorLimit;

-(void)moveToViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated;
-(void)moveToViewController:(UIViewController *)viewController animated:(BOOL)animated;

-(void)reloadPagerView;

@end
