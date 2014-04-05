//
//  ViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#define IS_TALL_SCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define screenSpecificSetting(tallScreen, normal) ((IS_TALL_SCREEN) ? tallScreen : normal)

#import "ViewController.h"
#import "designViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoCell.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    NSInteger selectedPhotoIndex;
}
@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property(nonatomic, strong) NSArray *assets;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.launchView.backgroundColor= self.navigationController.navigationBar.barTintColor;
    if (!IS_TALL_SCREEN) {
        self.collectionView.frame = CGRectMake(0, 95+64, 320, 480-(95+64));  // for 3.5 screen; remove autolayout
    }

}

- (void) showSurvey {
    NSLog(@"showSurvey");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"are you enjoying splitagram? please rate us" message:nil
                                                   delegate:self cancelButtonTitle:@"remind me later" otherButtonTitles:@"yes, I will rate now", @"don't ask me again", nil];
    [alert show];

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"buttonIndex is %d",buttonIndex);
    if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"rateDone"];
        [self rateApp];
    }
    else if (buttonIndex == 2 ){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"rateDone"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showSurvey"];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"counter" ];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _assets = [@[] mutableCopy];
    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    ALAssetsLibrary *assetsLibrary = [ViewController defaultAssetsLibrary];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result)
            {
                [tmpAssets addObject:result];
            }
        }];
        self.assets = tmpAssets;
        [self.collectionView reloadData];
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading images %@", error);
    }];
    NSLog(@"showSurvey is %d and rateDone is %d",[[NSUserDefaults standardUserDefaults] boolForKey:@"showSurvey"],![[NSUserDefaults standardUserDefaults] boolForKey:@"rateDone"]);
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showSurvey"]&&![[NSUserDefaults standardUserDefaults] boolForKey:@"rateDone"])
        [self performSelector:@selector(showSurvey) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.01];
    
}
-(void)scrollToBottom
{
    if (self.assets.count){
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:self.assets.count-1 inSection:0];
    [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }

}

#pragma mark - collection view data source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    
    ALAsset *asset = self.assets[indexPath.row];
    cell.asset = asset;
    cell.tag = indexPath.row;
    return cell;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 4;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UICollectionViewCell *cell = (UICollectionViewCell *)sender;
    selectedPhotoIndex = cell.tag;
    NSLog(@"index is %ld",(long)selectedPhotoIndex);

    ALAsset *asset = self.assets[selectedPhotoIndex];
    ALAssetRepresentation *defaultRep = [asset defaultRepresentation];
//    UIImageOrientation orientation = UIImageOrientationUp;
//    NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
//    if (orientationValue != nil) {
//        orientation = [orientationValue intValue];
//    }
    
    UIImage *image = [UIImage imageWithCGImage:[defaultRep fullResolutionImage] scale:[defaultRep scale] orientation:(UIImageOrientation)[defaultRep orientation]];
    if ([[segue identifier] isEqualToString:@"showDesign"])
    {
        designViewController *vc = [segue destinationViewController];
        vc.selectedImage=image;
    }
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


@end
