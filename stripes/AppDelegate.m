//
//  AppDelegate.m
//  stripes
//
//  Created by Saswata Basu on 3/18/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#import "AppDelegate.h"

@interface AppDelegate (){
    NSUserDefaults *defaults;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setBool:YES forKey:kFeature0];  //test
//    [defaults setBool:YES forKey:kFeature1];  //test
//    static dispatch_once_t pred;
//    dispatch_once(&pred, ^{
//    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"rateDone"];
//    });
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
//    {
//    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
    //note: iOS only allows one crash reporting tool per app; if using another, set to: NO
    [Flurry setCrashReportingEnabled:YES];
    
    // Replace YOUR_API_KEY with the api key in the downloaded package
    [Flurry startSession:@"KJ3Z269788RNJPRGP929"];
    // Tapjoy Connect Notifications
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(tjcConnectSuccess:)
//                                                 name:TJC_CONNECT_SUCCESS
//                                               object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(tjcConnectFail:)
//                                                 name:TJC_CONNECT_FAILED
//                                               object:nil];
    
	// NOTE: This is the only step required if you're an advertiser.
	// NOTE: This must be replaced by your App ID. It is retrieved from the Tapjoy website, in your account.
    
//	[Tapjoy requestTapjoyConnect:@"076a56d4-4ec1-44ce-b4b4-89e03032c2c5"
//					   secretKey:@"BMgDZYR6Az8t23lCSQWf" options:@{ TJC_OPTION_ENABLE_LOGGING : @(YES) }];
    
 
     // If you are not using Tapjoy Managed currency, you would set your own user ID here.
     // TJC_OPTION_USER_ID : @"A_UNIQUE_USER_ID"
     
     // You can also set your event segmentation parameters here.
     // Example segmentationParams object -- NSDictionary *segmentationParams = @{@"iap" : @(YES)};
     // TJC_OPTION_SEGMENTATION_PARAMS : segmentationParams
//     ];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];  //text color on nav bar
//    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:165/255.0 green:42/255.0 blue:42/255.0 alpha:1.0f]]; //color of nav bar
    // Override point for customization after application launch.
  
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
//    UINavigationController *navigationController;
//    [navigationController.interactivePopGestureRecognizer setEnabled:NO];
//    }
//    [[MKStoreKit sharedKit] startProductRequest];
//    
//    [[NSNotificationCenter defaultCenter] addObserverForName:kMKStoreKitProductsAvailableNotification
//                                                      object:nil
//                                                       queue:[[NSOperationQueue alloc] init]
//                                                  usingBlock:^(NSNotification *note) {
//                                                      
//                                                      NSLog(@"Products available: %@", [[MKStoreKit sharedKit] availableProducts]);
//                                                  }];
//    
//    
//    [[NSNotificationCenter defaultCenter] addObserverForName:kMKStoreKitProductPurchasedNotification
//                                                      object:nil
//                                                       queue:[[NSOperationQueue alloc] init]
//                                                  usingBlock:^(NSNotification *note) {
//                                                      
//                                                      NSLog(@"Purchased/Subscribed to product with id: %@", [note object]);
//                                                  }];
//    
//    [[NSNotificationCenter defaultCenter] addObserverForName:kMKStoreKitRestoredPurchasesNotification
//                                                      object:nil
//                                                       queue:[[NSOperationQueue alloc] init]
//                                                  usingBlock:^(NSNotification *note) {
//                                                      
//                                                      NSLog(@"Restored Purchases");
//                                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restore Successful" message:nil
//                                                                                                     delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                                                      [alert show];
//                                                      [self updateAppViewAndDefaults];
//                                                      [defaults setBool:YES forKey:@"restorePurchases"];
//
//                                                  }];
//    
//    [[NSNotificationCenter defaultCenter] addObserverForName:kMKStoreKitRestoringPurchasesFailedNotification
//                                                      object:nil
//                                                       queue:[[NSOperationQueue alloc] init]
//                                                  usingBlock:^(NSNotification *note) {
//                                                      
//                                                      NSLog(@"Failed restoring purchases with error: %@", [note object]);
//                                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restore Failed" message:nil
//                                                                                                     delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
//                                                      [alert show];
//                                                      [self updateAppViewAndDefaults];
//                                                      [defaults setBool:NO forKey:@"restorePurchases"];
//
//                                                  }];

    [MKStoreManager sharedManager];
    //create album
    NSString *albumName = @"stripes";
    __block BOOL albumFound = NO;
    ALAssetsLibrary *library = [AppDelegate defaultAssetsLibrary];
    [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                           usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                               if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                   NSLog(@"found album %@", albumName);
                                   albumFound=YES;
                               }
                           }
                         failureBlock:^(NSError* error) {
                             NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                         }];
    
    if (!albumFound){
        [library addAssetsGroupAlbumWithName:albumName
                                 resultBlock:^(ALAssetsGroup *group) {
                                 }
                                failureBlock:^(NSError *error) {
                                    NSLog(@"error adding album");
                                }];
    }
//    [[MKStoreManager sharedManager] removeAllKeychainData];  //test purpose to reset in-app purchase

    return YES;
}
//- (void) updateAppViewAndDefaults {
//    
//    if ([[MKStoreKit sharedKit] isProductPurchased:kFeature0])
//        [defaults setBool:YES forKey:kFeature0];
//    else
//        [defaults setBool:NO forKey:kFeature0];
//    
//    if([[MKStoreKit sharedKit] isProductPurchased:kFeature1])
//        [defaults setBool:YES forKey:kFeature1];
//    else
//        [defaults setBool:NO forKey:kFeature1];
//    
//    if([[MKStoreKit sharedKit] isProductPurchased:kFeature2])
//        [defaults setBool:YES forKey:kFeature2];
//    else
//        [defaults setBool:NO forKey:kFeature2];
//}
#pragma mark - assets
+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

-(void)tjcConnectSuccess:(NSNotification*)notifyObj
{
	NSLog(@"Tapjoy connect Succeeded");
}


- (void)tjcConnectFail:(NSNotification*)notifyObj
{
	NSLog(@"Tapjoy connect Failed");
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSInteger counter = [[NSUserDefaults standardUserDefaults] integerForKey:@"counter"];
    counter++;
    NSLog(@"counter is %ld",(long)counter);

    if (counter>4){
        NSLog(@"counter is %ld",(long)counter);

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showSurvey"];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"counter" ];
        counter = 0;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:counter forKey:@"counter" ];
    
   
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
