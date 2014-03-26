//
//  designViewController.h
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface designViewController : UIViewController <UIScrollViewDelegate,UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIImage *selectedImage;
@property (weak, nonatomic) IBOutlet UIScrollView *menuBar;
@property (weak, nonatomic) IBOutlet UIScrollView *frameSelectionBar;
@property (weak, nonatomic) IBOutlet UIScrollView *filterSelectionBar;
@property (strong, nonatomic) IBOutlet UIScrollView *rotateMenuView;
@property (weak, nonatomic) IBOutlet UIView *frameContainer;
@property (weak, nonatomic) IBOutlet UIScrollView *designViewContainer;
@end
