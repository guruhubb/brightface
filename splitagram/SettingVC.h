//
//  SettingVC.h
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <StoreKit/StoreKit.h>
#import "MKStoreManager.h"


@class HackbookAppDelegate;
@interface SettingVC : UITableViewController<UITableViewDataSource,UITableViewDelegate,NSURLConnectionDelegate,NSURLConnectionDataDelegate,UIAlertViewDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate,SKStoreProductViewControllerDelegate>{
    
//        int idint;
//    NSMutableString *currentElementValue;
//    NSMutableDictionary *dic;
//    NSMutableArray *dataArr;
//    NSMutableArray *fbIDs;
    NSArray *editArr;
//    UIImage *userProfilePic;
    UISwitch *savePhoto;
    NSUserDefaults *defaults;
    BOOL restoreON;
}
@property (weak, nonatomic) IBOutlet UITableView *settingsTableView;

@end

