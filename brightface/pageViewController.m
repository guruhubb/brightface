//
//  pageViewController.m
//  brightface
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import "pageViewController.h"
#import "pageViewContentViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Flurry.h"

@interface pageViewController ()

@end

@implementation pageViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect frame = CGRectMake(0, 0, 125, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:18];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"my brightface";
    self.navigationItem.titleView = label;
    [self setUp];
    [Flurry logEvent:@"mybrightface"];
}

- (void) setUp {
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageView"];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    NSLog(@"pageImage.count = %lu",(unsigned long)self.pageImages.count);
    pageViewContentViewController *startingViewController = [self viewControllerAtIndex:self.index];
    NSLog(@"starting view controller = %@",startingViewController);

    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    // Change the size of page view controller
    self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];

}

- (pageViewContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    NSLog(@"pageImage.count = %lu",(unsigned long)self.pageImages.count);

    if (([self.pageImages count] == 0) || (index >= [self.pageImages count])) {
        return nil;
    }
    NSString *string = [NSString stringWithFormat:@"%lu of %lu",(unsigned long)index+1,(unsigned long)self.pageImages.count];
    ALAsset *asset = self.pageImages[index];
    ALAssetRepresentation *defaultRep = [asset defaultRepresentation];
    UIImage *image = [UIImage imageWithCGImage:[defaultRep fullScreenImage] scale:[defaultRep scale] orientation:0];
    // Create a new view controller and pass suitable data.
    pageViewContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewContentViewController"];
    pageContentViewController.image = image;
    pageContentViewController.pageIndex = index;
    pageContentViewController.titleText=string;
    pageContentViewController.asset=asset;
    return pageContentViewController;
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((pageViewContentViewController*) viewController).pageIndex;
    NSLog(@"pageIndex  is %lu",(unsigned long)index);

    if ((index == 0) || (index == NSNotFound)) {
        return [self viewControllerAtIndex:self.pageImages.count-1];
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((pageViewContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return [self viewControllerAtIndex:0];
    }
    
    index++;
    if (index == [self.pageImages count]) {
        return [self viewControllerAtIndex:0];
    }
    return [self viewControllerAtIndex:index];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
