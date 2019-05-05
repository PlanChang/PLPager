//
//  ContentViewController.m
//  PLPagerDemo
//
//  Created by changshitong on 2018/9/14.
//  Copyright © 2018年 PLAN. All rights reserved.
//

#import "ContentViewController.h"

@interface ContentViewController ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation ContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor redColor];
    UILabel *label = [UILabel new];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor whiteColor];
    label.text = [NSString stringWithFormat:@"%d",self.index];
    [self.view addSubview:label];
    label.frame = CGRectMake(100, 100, 100, 100);
    
    self.label = label;
    
    NSInteger type = self.index%5;
    switch (type) {
        case 0:
            self.view.backgroundColor = [UIColor redColor];
            break;
        case 1:
            self.view.backgroundColor = [UIColor orangeColor];
            break;
        case 2:
            self.view.backgroundColor = [UIColor yellowColor];
            break;
        case 3:
            self.view.backgroundColor = [UIColor greenColor];
            break;
        case 4:
            self.view.backgroundColor = [UIColor purpleColor];
            break;
        default:
            break;
    }
}

- (void)setIndex:(int)index
{
    _index = index;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.label.center = CGPointMake(CGRectGetWidth(self.view.bounds)/2.0, CGRectGetHeight(self.view.bounds)/2.0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
