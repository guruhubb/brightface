//
//  adViewController.m
//  One Frame
//
//  Created by Saswata Basu on 3/23/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//
#define IS_TALL_SCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define screenSpecificSetting(tallScreen, normal) ((IS_TALL_SCREEN) ? tallScreen : normal)


#import "adViewController.h"
#import "Flurry.h" 
@interface adViewController ()

@end

@implementation adViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
//    if (!IS_TALL_SCREEN) {
//        self.view.frame = CGRectMake(0, 0, 320, 436);  // for 3.5 screen; remove autolayout
//    }
    CGRect frame = CGRectMake(0, 0, 125, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
//    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:18.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"our latest app";
    self.navigationItem.titleView = label;
	// Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
   
}
- (IBAction)lookAtApp:(id)sender {
    [Flurry logEvent:@"Ad Clicked"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"oneframe"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=866641636&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"]];
    return;
}


- (void)cancel {
//    [(UINavigationController *)self.presentingViewController  popToRootViewController:NO];
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
