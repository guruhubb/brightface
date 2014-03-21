//
//  SettingVC.m
//#define NSLog                       //
//#define NSLog(...)
#define IS_TALL_SCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define screenSpecificSetting(tallScreen, normal) ((IS_TALL_SCREEN) ? tallScreen : normal)
#import "SettingVC.h"

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
    label.font = [UIFont systemFontOfSize:20.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"settings";
    self.navigationItem.titleView = label;
    editArr = [[NSArray alloc]initWithObjects:
               @"photo format",@"photo background color",@"auto-save to camera roll",
               @"follow us on instagram", @"like us on facebook",@"follow us on twitter",
               @"rate app",@"feedback",@"restore purchases",nil];
    [self.settingsTableView reloadData];
}

-(void)smsAction{
//    [Flurry logEvent:@"Settings - SMS Invite" ];
    MFMessageComposeViewController *smsController = [[MFMessageComposeViewController alloc] init];
    smsController.messageComposeDelegate = self;
    smsController.body = @"Check out my new photobook on bookly.  Download bookly at www.appstore.com/bookly";
//    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//    pasteboard.persistent = YES;
//    pasteboard.image = [UIImage imageNamed:@"bookly144.png"];
//    smsController.body=[pasteboard string];
    [self presentViewController:smsController animated:YES completion:nil];
//    [smsController release];
}
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)rateApp {
//    [Flurry logEvent:@"Settings - Rate App" ];

    // Initialize Product View Controller
    SKStoreProductViewController *storeProductViewController = [[SKStoreProductViewController alloc] init];
    // Configure View Controller
    [storeProductViewController setDelegate:self];
    [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier : @"554083056"} completionBlock:^(BOOL result, NSError *error) {
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
    
    [pickerMail setSubject:@"Customer Feedback"];
    [pickerMail setToRecipients:[NSArray arrayWithObject:@"getbooklyapp@gmail.com"]];
    // Fill out the email body text
    NSString *emailBody = @"Hello team, I have the following comments on splitagram...";
    [pickerMail setMessageBody:emailBody isHTML:NO];

    [self presentViewController:pickerMail animated:YES completion:nil];
    pickerMail=nil;
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - tableView delegated methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case (0):
            return 3;
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
    NSString *cellId = [NSString stringWithFormat:@"%d and %d",indexPath.row,indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] ;
    }

        [cell.textLabel setFont:[UIFont systemFontOfSize:18]];
//        [cell.textLabel setTextColor:[UIColor lightGrayColor]];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        if (indexPath.section == 0){
            if (indexPath.row==0) {
                [cell.textLabel setText:[editArr objectAtIndex:0]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(255, 0, 40, 40)];
                label.textColor = [UIColor lightGrayColor];
                label.font = [UIFont systemFontOfSize:14];
                label.tag = 100;
                [cell.contentView addSubview:label];
                if ([defaults boolForKey:@"crop"])
                    label.text = @"frame";
                else
                    label.text = @"crop";
            
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
                savePhoto = [[UISwitch alloc] initWithFrame:CGRectZero];
                [savePhoto addTarget: self action: @selector(flip:) forControlEvents:UIControlEventValueChanged];
                if ([defaults boolForKey:@"savePhoto"])  //if 0 then save is ON
                    savePhoto.on = NO;
                else
                    savePhoto.on = YES;
                cell.accessoryView = savePhoto;

            }
        }
        if (indexPath.section == 1) {
            if(indexPath.row==0){
                [cell.textLabel setText:[editArr objectAtIndex:3]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            if(indexPath.row==1){
                [cell.textLabel setText:[editArr objectAtIndex:4]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            if (indexPath.row==2) {
                [cell.textLabel setText:[editArr objectAtIndex:5]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
        }
        if (indexPath.section == 2) {
            if(indexPath.row==0){
                [cell.textLabel setText:[editArr objectAtIndex:6]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            if(indexPath.row==1){
                [cell.textLabel setText:[editArr objectAtIndex:7]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            if(indexPath.row==2){
                [cell.textLabel setText:[editArr objectAtIndex:8]];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            
        }

//        if (indexPath.section == 3) {
//            if(indexPath.row==0){
//                [cell.textLabel setText:[editArr objectAtIndex:7]];
//                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
//                savePhoto = [[UISwitch alloc] initWithFrame:CGRectZero];
//                [savePhoto addTarget: self action: @selector(flip:) forControlEvents:UIControlEventValueChanged];
//                NSLog(@"savePHoto is %d",[defaults boolForKey:@"savePhoto"]);
//                if ([defaults boolForKey:@"savePhoto"])  //if 1 then save is ON
//                    savePhoto.on = YES;
//                else
//                    savePhoto.on = NO;
//                NSLog(@"savePHoto.on is %d",savePhoto.on);
//                
//                cell.accessoryView = savePhoto;
//            }
//        }
//        if (indexPath.section == 4) {
//            if(indexPath.row==0){
//                
//                [cell.textLabel setText:[editArr objectAtIndex:8]];
//                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
//            }
//            if(indexPath.row==1){
//                
//                [cell.textLabel setText:[editArr objectAtIndex:9]];
//                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
//            }
//        }
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row==0) {
//            suggestFollowersVC *suggestVC = [[suggestFollowersVC alloc]initWithNibName:@"suggestFollowersVC" bundle:nil];
//            suggestVC.backButtonString=@"settings";
//            [self.navigationController pushViewController:suggestVC animated:YES];
//            [Flurry logEvent:@"Settings - Suggest Followers" ];
            [self frameAction];
        }

        if (indexPath.row==1) {
            [self backgroundColorAction];
//            [self findFriends];
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
            NSURL *instagramURL = [NSURL URLWithString:@"instagram://user?username=getbooklyapp"];
            if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
                [[UIApplication sharedApplication] openURL:instagramURL];
            }
//            ProfileEditVC *obj = [[ProfileEditVC alloc]initWithNibName:@"ProfileEditVC" bundle:nil];
//            obj.backButtonString=@"settings";
//            [self.navigationController pushViewController:obj animated:YES];
        }
        if (indexPath.row==1) {
            NSURL *fbURL = [NSURL URLWithString:@"https://www.facebook.com/getbooklyapp"];
            if ([[UIApplication sharedApplication] canOpenURL:fbURL]) {
                [[UIApplication sharedApplication] openURL:fbURL];
            }

//            [self cameraAction];
        }
        if (indexPath.row==2) {
            NSURL *twitterURL = [NSURL URLWithString:@"twitter://user?screen_name=getbooklyapp"];
            if ([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
                [[UIApplication sharedApplication] openURL:twitterURL];
            }

//            PasswordVC *passwordVC = [[PasswordVC alloc]initWithNibName:@"PasswordVC" bundle:nil];
//            passwordVC.backButtonString=@"settings";
//            [self.navigationController pushViewController:passwordVC animated:YES];
        }
    }
   
//    if (indexPath.section == 4) {
//        if (indexPath.row == 0){
////            inAppPurchaseVC *inApp = [[inAppPurchaseVC alloc]initWithNibName:@"inAppPurchaseVC" bundle:nil];
////            [self.navigationController pushViewController:inApp animated:NO];
//        }
//        if (indexPath.row == 1){
//            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Log Out" message:@"Are you sure?" delegate:self cancelButtonTitle:@"no" otherButtonTitles:@"yes", nil];
//            alert.tag = 3;
//            [alert setDelegate:self];
//            [alert show];
//        }
//    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (IBAction)flip:(id)sender {
    
    if (savePhoto.on) {  //if 1 then  save
        NSLog(@"save");
        [defaults setBool:NO forKey:@"savePhoto"];
    }
    else {   //if 0 then don't save
        NSLog(@"dont save");
        [defaults setBool:YES forKey:@"savePhoto"];
    }
}

- (void)restorePurchases {
    
//    if (!restoreON ){
        if( [[NSUserDefaults standardUserDefaults] boolForKey:@"restorePurchases"]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already Restored" message:nil
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            return;
        }
//        restoreON = YES;
//        [self turnOnIndicator];
        [[MKStoreManager sharedManager]restorePreviousTransactionsOnComplete:^{
            NSLog(@"RESTORED PREVIOUS PURCHASE");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restore Successful" message:nil
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            [self updateAppViewAndDefaults];
//            [self turnOffIndicator];
//            restoreON = NO;
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"restorePurchases"];
        } onError:nil];
//    }
    
}
- (void) updateAppViewAndDefaults {
    NSString *string;
    for (int i=0;i<9;i++) {
        switch (i) {
            case 0:
                string = kFeature0;
                break;
            case 1:
                string = kFeature1;
                break;
            case 2:
                string = kFeature2;
                break;
            case 3:
                string = kFeature3;
                break;
            case 4:
                string = kFeature4;
                break;
                //            case 5:
                //                string = kFeature5;
                //                break;
            case 6:
                string = kFeature6;
                break;
            case 7:
                string = kFeature7;
                break;
            case 8:
                string = kFeature8;
                break;
            default:
                break;
        }
        
        if ([MKStoreManager isFeaturePurchased:kFeature8]){
//            UIButton *btn = (UIButton *) [self.inAppSubView viewWithTag:i*2+800];
//            btn.hidden = YES;
//            UILabel *label = (UILabel*) [self.inAppSubView viewWithTag:i*2+1+800];
//            //            label.hidden = YES;
//            if (label.tag == 817)
//                label.hidden = YES;
//            else
//                label.text = @"YES";
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:string];
        }
        
        else if([MKStoreManager isFeaturePurchased:string])
        {
//            UIButton *btn = (UIButton *) [self.inAppSubView viewWithTag:i*2+800];
//            btn.hidden = YES;
//            UILabel *label = (UILabel*) [self.inAppSubView viewWithTag:i*2+1+800];
//            if (label.tag == 817)
//                label.hidden = YES;
//            else
//                label.text = @"YES";
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:string];
        }
        else
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:string];
    }
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
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"crop",@"fit frame",nil];
    popupQuery.tag=0;
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [popupQuery showInView:self.view];
    popupQuery = nil;
    popupQuery.destructiveButtonIndex=-1;
}
-(void)backgroundColorAction
{
    UIActionSheet *popupQuery;
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"white",@"black",nil];
    popupQuery.tag=1;
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [popupQuery showInView:self.view];
    popupQuery = nil;
    popupQuery.destructiveButtonIndex=-1;
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
        if (actionSheet.tag == 0) {
            if (buttonIndex==0){
                [defaults setBool:NO forKey:@"crop"];
            }
            else if (buttonIndex==1)[defaults setBool:YES forKey:@"crop"];
            
        }
        else {
            if (buttonIndex==0){
                [defaults setBool:NO forKey:@"white"];
            }
            else if (buttonIndex==1)[defaults setBool:YES forKey:@"white"];
        }
    UILabel *label1 = (UILabel *) [self.view viewWithTag:100];
    UILabel *label2 = (UILabel *) [self.view viewWithTag:101];
    [label1 removeFromSuperview];
    [label2 removeFromSuperview];

    [self.settingsTableView reloadData];

}




- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 0:
            if (buttonIndex)
//                [self emailContacts];
            break;
            
        case 1:
            if (buttonIndex)
//                [self facebookAction];
            break;
            
        case 2:
            if (buttonIndex)
//                [self findFacebookFriends];
            break;
            
        case 3:
            if(buttonIndex)
                {
                
//                RootViewController *root=[[RootViewController alloc]init];
//                [UIView animateWithDuration:0.2
//                                 animations:^{
//                                     [Flurry logEvent:@"Settings - Logout"];
//                                     islogout=TRUE;
//                                     [self loadxmlparsing];
//                                     
//                                     [[delegate facebook]logout];
//                                     //                             [root fbSessionInvalidated];
//                                     [root booklyLogout];
//                                     
//                                 }
//                                 completion:^(BOOL finished){
//                                     //                             [root showLoggedOut];
//                                     [self presentViewController:root animated:NO completion:nil];
//                                 }];
            }
            break;
        case 4:
            if (buttonIndex)
//                [self clearCache];
            break;
            
        default:
            break;
    }
    
}


@end
