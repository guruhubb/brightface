//
//  shareViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/23/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import "shareViewController.h"
#import <Social/Social.h>

@interface shareViewController ()
@property(nonatomic,retain) UIDocumentInteractionController *documentationInteractionController;
@property(nonatomic, strong)  UIDocumentInteractionController* docController;
@end

@implementation shareViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];

}
- (void)cancel {
    [self dismissViewControllerAnimated: YES completion: nil];
}

- (IBAction)postToFacebook:(id)sender {
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        [controller setInitialText:@"First post from my iPhone app"];
        [controller addURL:[NSURL URLWithString:@"http://www.appcoda.com"]];
        [controller addImage:[UIImage imageNamed:@"socialsharing-facebook-image.jpg"]];
        
        [self presentViewController:controller animated:YES completion:Nil];
        
    }
}

- (IBAction)postToTwitter:(id)sender {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:@"Great fun to learn iOS programming at appcoda.com!"];
        [tweetSheet addURL:[NSURL URLWithString:@"http://www.appcoda.com"]];
        [tweetSheet addImage:[UIImage imageNamed:@"socialsharing-facebook-image.jpg"]];
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
}


- (void) doInstagram {
//    [Flurry logEvent:@"Photobook: Instagram"];
    //    UIImageView *drawingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,612,612)];
    //    drawingImageView.image = self.albumImage.image;
    //    UIImage* instaImage = [self cropImage:self.albumImage.image :drawingImageView];  //this works it just chops the top/bottom off
    NSString *imagePath;
//    if (isImage){
//        UIImageView *temp = [[UIImageView alloc] initWithImage:self.image];
    
//        UIImage* instaImage = [self captureView:temp];
        //    UIImage *instaImage = self.albumImage.image;  //chops off top and bottom
        
        imagePath = [NSString stringWithFormat:@"%@/image.igo", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
        [UIImagePNGRepresentation(self.image) writeToFile:imagePath atomically:YES];
//        NSLog(@"image size: %@", NSStringFromCGSize(instaImage.size));
    
    _docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imagePath]];
    _docController.delegate=self;
    //key to open Instagram app - need to make sure docController is "strong"
    _docController.UTI = @"com.instagram.exclusivegram";
    _docController.annotation = [NSDictionary dictionaryWithObject:@"#splitagram using @splitagram app" forKey:@"InstagramCaption"];
    [_docController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
    
    //    [_docController release];
    //    NSURL *instagramURL = [NSURL URLWithString:@"instagram://media?id=MEDIA_ID"];
    //    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
    //        [[UIApplication sharedApplication] openURL:instagramURL];
    //    }
    //
    //    else {
    //        NSLog(@"No Instagram Found");
    //    }
}

- (void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *) controller
{  _docController = nil;
}

- (UIImage*)captureView:(UIView *)view
{
    
    //    CGRect rect = view.frame;//[[UIScreen mainScreen] bounds];
    UIView *viewFull = [[UIView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width+40, view.frame.size.height)];
    
    UIView *viewA = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, view.frame.size.height)];
    viewA.backgroundColor=[UIColor whiteColor];
    [viewFull addSubview:viewA];
    
    UIView *viewB = [[UIView alloc] initWithFrame:CGRectMake(20, 0, view.frame.size.width, view.frame.size.height)];
    [viewB addSubview:view];
    [viewFull addSubview:viewB];
    
    UIView *viewC = [[UIView alloc] initWithFrame:CGRectMake(20+view.frame.size.width, 0, 20, view.frame.size.height)];
    viewC.backgroundColor=[UIColor whiteColor];
    [viewFull addSubview:viewC];
    
    
    //    UIGraphicsBeginImageContext(rect.size);
    UIGraphicsBeginImageContextWithOptions(viewFull.frame.size, YES, 0.0);  //v1.0 bookly use this instead of withoutOptions and 2.0 magnification to give a sharper image  //v1.0g bookly Scaling at 2.0 is too much pixels and too big of an image to email.  0.0 goes to default image size of the device which makes it pretty large.  So the optimum is 1.25 scaling with 0.6 compression to keep most images at around 50kB.
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [viewFull.layer renderInContext:context];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSLog(@"img%@",img);
    return img;
}

- (void) sendMail:(NSData*)img
{
//    [Flurry logEvent:@"Photobook: Email"];
    MFMailComposeViewController *pickerMail = [[MFMailComposeViewController alloc] init];
    pickerMail.mailComposeDelegate = self;
    
    [pickerMail setSubject:@"#bookly created using bookly app"];
    
    // Fill out the email body text
    NSString *temp = @"bookly";
    NSString *booklyMediaId = [temp stringByAppendingString:[labelContents objectForKey:@"id"]];
    NSData *inputData = [booklyMediaId dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedString = [inputData base64EncodedString];      //encode
    NSString *string;
    if (isImage)
        string= [NSString stringWithFormat:@"http://getbooklyapp.com/image.php?mediaId=%@",encodedString];
    else
        string= [NSString stringWithFormat:@"http://getbooklyapp.com/video.php?mediaId=%@",encodedString];
    
    
    NSString *emailBody = string;
    
    [pickerMail setMessageBody:emailBody isHTML:NO];
    
    // Attach an image to the email
    //    if (isImage)
    [pickerMail addAttachmentData:img mimeType:@"image/png" fileName:@"attach"];
    //    else
    //        [pickerMail addAttachmentData:img mimeType:@"video/mpeg" fileName:@"tmp.mp4"];
    
    //    [self presentModalViewController:pickerMail animated:YES];
    [self presentViewController:pickerMail animated:YES completion:nil];
    //    [[[[pickerMail viewControllers] lastObject] navigationItem] setTitle:@"Email"];
    
    pickerMail=nil;
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    //	[self dismissModalViewControllerAnimated:YES];
    [ self dismissViewControllerAnimated: YES completion:nil];
}

- (void) mmsSend {  //sms or mms
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.persistent = YES;
    pasteboard.image = [UIImage imageNamed:@"PDF_File.png"];
    
    
    NSString *phoneToCall = @"sms:";
    NSString *phoneToCallEncoded = [phoneToCall stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSURL *url = [[NSURL alloc] initWithString:phoneToCallEncoded];
    [[UIApplication sharedApplication] openURL:url];
}
- (IBAction)bocClick:(UIButton *)sender {
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,     NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"]; //here i am fetched image path from document directory and convert it in to URL and use bellow
    
    
    NSURL *imageFileURL =[NSURL fileURLWithPath:getImagePath];
    NSLog(@"imag %@",imageFileURL);
    
    self.documentationInteractionController.delegate = self;
    self.documentationInteractionController.UTI = @"net.whatsapp.image";
    self.documentationInteractionController = [self setupControllerWithURL:imageFileURL usingDelegate:self];
    [self.documentationInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    
    
}

- (UIDocumentInteractionController *) setupControllerWithURL: (NSURL*) fileURL

                                               usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate {
    
    
    
    self.documentationInteractionController =
    
    [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    
    self.documentationInteractionController.delegate = interactionDelegate;
    
    
    
    return self.documentationInteractionController;
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
