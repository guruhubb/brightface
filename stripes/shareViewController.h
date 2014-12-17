//
//  shareViewController.h
//  stripes
//
//  Created by Saswata Basu on 3/23/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
@interface shareViewController : UIViewController <NSURLConnectionDelegate,NSURLConnectionDataDelegate,UIActionSheetDelegate, MFMailComposeViewControllerDelegate,UIDocumentInteractionControllerDelegate, UIDocumentInteractionControllerDelegate, MFMessageComposeViewControllerDelegate>
@property (nonatomic,strong) UIImage *image;
@property (strong, nonatomic) IBOutlet UIView *shareView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView1;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet UIImageView *imageView3;
@property (weak, nonatomic) IBOutlet UIImageView *imageView4;
@property (weak, nonatomic) IBOutlet UIImageView *imageView5;
@property (weak, nonatomic) IBOutlet UIImageView *imageView6;
@property (weak, nonatomic) IBOutlet UIImageView *imageView7;
@property (weak, nonatomic) IBOutlet UIImageView *imageView8;

@end
