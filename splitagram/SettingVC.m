//
//  SettingVC.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//
//#define NSLog                       //
//#define NSLog(...)
#define IS_TALL_SCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define screenSpecificSetting(tallScreen, normal) ((IS_TALL_SCREEN) ? tallScreen : normal)
#import "SettingVC.h"
#import "Flurry.h"
@implementation SettingVC



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}



#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    defaults = [NSUserDefaults standardUserDefaults];
    CGRect frame = CGRectMake(0, 0, 125, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:18];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"settings";
    self.navigationItem.titleView = label;
    editArr = [[NSArray alloc]initWithObjects:
               @"photo format for frame",@"photo background color",@"auto-filter",@"auto-save to camera roll",@"add watermark",
               @"follow us on instagram", @"like us on facebook",@"follow us on twitter",
               @"rate app",@"feedback",@"restore purchases",nil];
    [self.settingsTableView reloadData];
//    [defaults setBool:YES forKey:kFeature2];  //test

    
}



- (void)rateApp {
    
    [Flurry logEvent:@"Rate App" ];

    // Initialize Product View Controller
    SKStoreProductViewController *storeProductViewController = [[SKStoreProductViewController alloc] init];
    // Configure View Controller  850204569
    [storeProductViewController setDelegate:self];
    [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier : @"850204569"} completionBlock:^(BOOL result, NSError *error) {
        if (error) {
            NSLog(@"Error %@ with User Info %@.", error, [error userInfo]);
        } else {
            // Present Store Product View Controller
            [[UINavigationBar appearance] setTintColor:[UIColor blueColor]];

            [self presentViewController:storeProductViewController animated:YES completion:nil];
        }
    }];

}
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

}


- (void) sendMail
{
//     [Flurry logEvent:@"Settings - Customer Feedback"];
    MFMailComposeViewController *pickerMail = [[MFMailComposeViewController alloc] init];
    pickerMail.mailComposeDelegate = self;
    
    [pickerMail setSubject:@"customer feedback"];
    [pickerMail setToRecipients:[NSArray arrayWithObject:@"splitagram@gmail.com"]];
    // Fill out the email body text
    NSString *emailBody = @"hi, I have the following feedback on splitagram...";
    [pickerMail setMessageBody:emailBody isHTML:NO];
    [[UINavigationBar appearance] setTintColor:[UIColor blueColor]];

    [self presentViewController:pickerMail animated:YES completion:nil];
    pickerMail=nil;
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

	[self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - tableView delegated methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case (0):
            return 5;
        case (1):
            return 3;
        case (2):
            return 3;
        default:
            return 1;
    }
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case (0):
            return @"  ";
        case (1):
            return @"  ";
        case (2):
            return @"  ";
        default:
            return @"  ";
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = [NSString stringWithFormat:@"%ld and %ld",(long)indexPath.row,(long)indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] ;
    }

//        [cell.textLabel setFont:[UIFont systemFontOfSize:18]];
//        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        if (indexPath.section == 0){
            if (indexPath.row==0) {
                [cell.textLabel setText:[editArr objectAtIndex:0]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(255, 0, 40, 40)];
                label.textColor = [UIColor lightGrayColor];
                label.font = [UIFont systemFontOfSize:14];
                label.tag = 100;
                [cell.contentView addSubview:label];
                if ([defaults boolForKey:@"fill"])
                    label.text = @"fit";
                else
                    label.text = @"fill";
            
            }
            if (indexPath.row==1) {
                [cell.textLabel setText:[editArr objectAtIndex:1]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(255, 0, 40, 40)];
                label.textColor = [UIColor lightGrayColor];
                label.font = [UIFont systemFontOfSize:14];
                label.tag = 101;
                [cell.contentView addSubview:label];
                if ([defaults boolForKey:@"white"])
                    label.text = @"black";
                else
                    label.text = @"white";
                
            }
            if (indexPath.row==2) {
                [cell.textLabel setText:[editArr objectAtIndex:2]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(255, 0, 40, 40)];
                label.textColor = [UIColor lightGrayColor];
                label.font = [UIFont systemFontOfSize:14];
                label.tag = 102;
                [cell.contentView addSubview:label];
                if ([defaults boolForKey:@"filter"])
                    label.text = @"no";
                else
                    label.text = @"yes";
                
            }
            if (indexPath.row==3) {
                [cell.textLabel setText:[editArr objectAtIndex:3]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                savePhoto = [[UISwitch alloc] initWithFrame:CGRectZero];
                [savePhoto addTarget: self action: @selector(flip) forControlEvents:UIControlEventValueChanged];
                if ([defaults boolForKey:@"savePhoto"])  //if 0 then save is ON
                    savePhoto.on = NO;
                else
                    savePhoto.on = YES;
                cell.accessoryView = savePhoto;

            }
            if (indexPath.row==4) {
                [cell.textLabel setText:[editArr objectAtIndex:4]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                watermark = [[UISwitch alloc] initWithFrame:CGRectZero];
                [watermark addTarget: self action: @selector(watermarkAction) forControlEvents:UIControlEventValueChanged];
               
                cell.accessoryView = watermark;
                
                if ([defaults boolForKey:@"watermark"]) { //if 0 then watermark is ON
                    watermark.on = NO;
                }
                else
                    watermark.on = YES;
                
            }
            
        }
        if (indexPath.section == 1) {
            if(indexPath.row==0){
                [cell.textLabel setText:[editArr objectAtIndex:5]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            if(indexPath.row==1){
                [cell.textLabel setText:[editArr objectAtIndex:6]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            if (indexPath.row==2) {
                [cell.textLabel setText:[editArr objectAtIndex:7]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
        }
        if (indexPath.section == 2) {
            if(indexPath.row==0){
                [cell.textLabel setText:[editArr objectAtIndex:8]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            if(indexPath.row==1){
                [cell.textLabel setText:[editArr objectAtIndex:9]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            if(indexPath.row==2){
                [cell.textLabel setText:[editArr objectAtIndex:10]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            
        }

    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row==0) {
            [self frameAction];
        }

        if (indexPath.row==1) {
            [self backgroundColorAction];
        }
        if (indexPath.row==2) {
            [self filterAction];
        }
    }
    if (indexPath.section == 2){
        if (indexPath.row==0) {

            [self rateApp];
            
        }
        if (indexPath.row==1) {
            [self sendMail];
        }
        if (indexPath.row == 2){
            [self restorePurchases];
        }
    }
    if (indexPath.section == 1) {
        if (indexPath.row==0) {
            NSURL *instagramURL = [NSURL URLWithString:@"instagram://user?username=splitagram"];
            if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
                [[UIApplication sharedApplication] openURL:instagramURL];
            }
        }
        if (indexPath.row==1) {
            NSURL *fbURL = [NSURL URLWithString:@"fb://profile/671210576279888"];
            if ([[UIApplication sharedApplication] canOpenURL:fbURL]) {
                [[UIApplication sharedApplication] openURL:fbURL];
            }
        }
        if (indexPath.row==2) {
            NSURL *twitterURL = [NSURL URLWithString:@"twitter://user?screen_name=splitagram"];
            if ([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
                [[UIApplication sharedApplication] openURL:twitterURL];
            }
        }
    }
     [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (void)flip {
    
    if (savePhoto.on) {  //if 1 then  save
        NSLog(@"save");
        [defaults setBool:NO forKey:@"savePhoto"];
    }
    else {   //if 0 then don't save
        NSLog(@"dont save");
        [defaults setBool:YES forKey:@"savePhoto"];
        [Flurry logEvent:@"NoSave"];
    }
}
-(void)watermarkAction
{
    UIActionSheet *popupQuery;
    if (![defaults boolForKey:kFeature2]){  //if not purchased
        popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"remove watermark",@"buy for $1.99",nil];
        popupQuery.tag=3;
        [popupQuery showInView:self.view];
        watermark.on = YES;
    }
    else {  //if purchased
        if (watermark.on) {
//            watermark.on = NO;
            [defaults setBool:NO forKey:@"watermark"];
        }
        else {
//            watermark.on = YES;
            [defaults setBool:YES forKey:@"watermark"];
        }
    }
}
- (void)inAppBuyAction:(int)tag {
    [Flurry logEvent:@"InApp Watermark"];
    //    UIButton *btn = (UIButton *) sender;
//    NSString *string;
//    //    NSLog(@"btn.tag is %d",btn.tag);
//    //    [self turnOnIndicator];
//    switch (tag) {
//        case 800:
//            string = kFeature0;
//            break;
//        case 802:
//            string = kFeature1;
//            break;
//        case 804:
//            string = kFeature2;
//            break;
//        case 806:
//            string = kFeature3;
//            break;
//        case 808:
//            string = kFeature4;
//            break;
//            //        case 810:
//            //            string = kFeature5;
//            //            break;
//        case 812:
//            string = kFeature6;
//            break;
//        case 814:
//            string = kFeature7;
//            break;
//        case 816:
//            string = kFeature8;
//            break;
//        default:
//            break;
//    }
    NSLog(@"buying...");
    
    [[MKStoreManager sharedManager] buyFeature:kFeature2
                                    onComplete:^(NSString* purchasedFeature,
                                                 NSData* purchasedReceipt,
                                                 NSArray* availableDownloads)
     {
         //         if (!restoreON){
         NSLog(@"Purchased: %@, available downloads is %@ watermark ", purchasedFeature, availableDownloads );
         
         
         //             [self turnOffIndicator];
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Successful" message:nil
                                                        delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
         [defaults setBool:YES  forKey:kFeature2];
         [alert show];
         [self updateAppViewAndDefaults];
         //         }
         //         [self.inAppSubView setNeedsDisplay];
     }
                                   onCancelled:^
     {
         NSLog(@"User Cancelled Transaction");
         //         [self turnOffIndicator];
     }];
    
}
- (void)restorePurchases {
    
        if( [[NSUserDefaults standardUserDefaults] boolForKey:@"restorePurchases"]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"already restored" message:nil
                                                           delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil];
            [alert show];
            return;
        }
        [[MKStoreManager sharedManager]restorePreviousTransactionsOnComplete:^{
            NSLog(@"RESTORED PREVIOUS PURCHASE");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"restore successful" message:nil
                                                           delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil];
            [alert show];
            [self updateAppViewAndDefaults];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"restorePurchases"];
        } onError:nil];
    
}
- (void) updateAppViewAndDefaults {
    if ([MKStoreManager isFeaturePurchased:kFeature0])
        [defaults setBool:YES forKey:kFeature0];
    else
        [defaults setBool:NO forKey:kFeature0];
    
    if([MKStoreManager isFeaturePurchased:kFeature1])
        [defaults setBool:YES forKey:kFeature1];
    else
        [defaults setBool:NO forKey:kFeature1];
    
    if([MKStoreManager isFeaturePurchased:kFeature2])
        [defaults setBool:YES forKey:kFeature2];
    else
        [defaults setBool:NO forKey:kFeature2];
    
//    NSString *string;
//    for (int i=0;i<9;i++) {
//        switch (i) {
//            case 0:
//                string = kFeature0;
//                break;
//            case 1:
//                string = kFeature1;
//                break;
//            case 2:
//                string = kFeature2;
//                break;
//            case 3:
//                string = kFeature3;
//                break;
//            case 4:
//                string = kFeature4;
//                break;
//                //            case 5:
//                //                string = kFeature5;
//                //                break;
//            case 6:
//                string = kFeature6;
//                break;
//            case 7:
//                string = kFeature7;
//                break;
//            case 8:
//                string = kFeature8;
//                break;
//            default:
//                break;
//        }
//        
//        if ([MKStoreManager isFeaturePurchased:kFeature8]){
////            UIButton *btn = (UIButton *) [self.inAppSubView viewWithTag:i*2+800];
////            btn.hidden = YES;
////            UILabel *label = (UILabel*) [self.inAppSubView viewWithTag:i*2+1+800];
////            //            label.hidden = YES;
////            if (label.tag == 817)
////                label.hidden = YES;
////            else
////                label.text = @"YES";
//            
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:string];
//        }
//        
//        else if([MKStoreManager isFeaturePurchased:string])
//        {
////            UIButton *btn = (UIButton *) [self.inAppSubView viewWithTag:i*2+800];
////            btn.hidden = YES;
////            UILabel *label = (UILabel*) [self.inAppSubView viewWithTag:i*2+1+800];
////            if (label.tag == 817)
////                label.hidden = YES;
////            else
////                label.text = @"YES";
//            
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:string];
//        }
//        else
//            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:string];
//    }
}

- (void) turnOnIndicator {
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc]     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center=self.view.center;
    activityView.layer.shadowOffset = CGSizeMake(1, 1);
    activityView.layer.shadowColor = [UIColor blackColor].CGColor;
    activityView.layer.shadowOpacity=0.8 ;
    
    
    activityView.tag = 10001;
    activityView.transform = CGAffineTransformScale(activityView.transform, 1.5, 1.5);
    [activityView startAnimating];
    [self.view addSubview:activityView];
}

- (void) turnOffIndicator {
    UIActivityIndicatorView *activityView=(UIActivityIndicatorView *) [self.view viewWithTag:10001];
    [activityView removeFromSuperview];
    [activityView stopAnimating];
}



-(void)frameAction
{
    UIActionSheet *popupQuery;
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"fill frame",@"fit frame",nil];
    popupQuery.tag=0;
    [popupQuery showInView:self.view];
}
-(void)backgroundColorAction
{
    UIActionSheet *popupQuery;
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"white",@"black",nil];
    popupQuery.tag=1;
    [popupQuery showInView:self.view];
}
-(void)filterAction
{
    UIActionSheet *popupQuery;
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"auto filter",@"no filter",nil];
    popupQuery.tag=2;
    [popupQuery showInView:self.view];
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
        if (actionSheet.tag == 0) {
            if (buttonIndex==0){
                [defaults setBool:NO forKey:@"fill"];
            }
            else if (buttonIndex==1)[defaults setBool:YES forKey:@"fill"];
            
        }
        else if (actionSheet.tag == 1){
            if (buttonIndex==0){
                [defaults setBool:NO forKey:@"white"];
            }
            else if (buttonIndex==1)[defaults setBool:YES forKey:@"white"];
        }
        else if (actionSheet.tag ==2 ){
            if (buttonIndex==0){
                [defaults setBool:NO forKey:@"filter"];
            }
            else if (buttonIndex==1)[defaults setBool:YES forKey:@"filter"];
        }
        else if (actionSheet.tag == 3) {
            if (buttonIndex==1){
                [self inAppBuyAction:actionSheet.tag];
            }
        }
    
    UILabel *label1 = (UILabel *) [self.view viewWithTag:100];
    UILabel *label2 = (UILabel *) [self.view viewWithTag:101];
    UILabel *label3 = (UILabel *) [self.view viewWithTag:102];

    [label1 removeFromSuperview];
    [label2 removeFromSuperview];
    [label3 removeFromSuperview];

    [self.settingsTableView reloadData];

}








@end
