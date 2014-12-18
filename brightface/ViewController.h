//
//  ViewController.h
//  brightface
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "MKStoreManager.h"
#import "Flurry.h"
#import <StoreKit/StoreKit.h>

@interface ViewController : UIViewController < UIActionSheetDelegate,SKStoreProductViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *launchView;

@end
