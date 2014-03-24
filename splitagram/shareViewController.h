//
//  shareViewController.h
//  splitagram
//
//  Created by Saswata Basu on 3/23/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
@interface shareViewController : UIViewController <NSURLConnectionDelegate,NSURLConnectionDataDelegate,UIActionSheetDelegate, MFMailComposeViewControllerDelegate,UIDocumentInteractionControllerDelegate, UIDocumentInteractionControllerDelegate>
@property (nonatomic,strong) UIImage *image;

@end
