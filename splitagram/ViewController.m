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
#import <ImageIO/ImageIO.h>
#import "PhotoCell.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    NSInteger selectedPhotoIndex;
    NSUserDefaults *defaults;
}
@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property(nonatomic, strong) NSArray *assets;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    defaults = [NSUserDefaults standardUserDefaults];
    self.launchView.backgroundColor= self.navigationController.navigationBar.barTintColor;
    if (!IS_TALL_SCREEN) {
        self.collectionView.frame = CGRectMake(0, 95+64, 320, 480-(95+64));  // for 3.5 screen; remove autolayout
    }


}

- (void) showSurvey {
    NSLog(@"showSurvey");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"like splitagram? please rate" message:nil
                                                   delegate:self cancelButtonTitle:@"remind me later" otherButtonTitles:@"yes, I will rate now", @"don't ask me again", nil];
    [alert show];

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)buttonIndex {
    NSLog(@"buttonIndex is %d",buttonIndex);
    if (buttonIndex == 1) {
        [self rateApp];
    }
    else if (buttonIndex == 2 ){
        [defaults setBool:YES forKey:@"rateDone"];
           NSLog(@"rateDone is %d",[defaults boolForKey:@"rateDone"]);
    }
    else {
        [defaults setBool:NO forKey:@"showSurvey"];
        [defaults setInteger:0 forKey:@"counter" ];
           NSLog(@"showSurvey is %d and counter is %ld",[defaults boolForKey:@"showSurvey"],(long)[defaults integerForKey:@"counter"]);
    }
    [defaults synchronize];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _assets = [@[] mutableCopy];
    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    ALAssetsLibrary *assetsLibrary = [ViewController defaultAssetsLibrary];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
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
    NSLog(@"showSurvey is %d and rateDone is %d",[defaults boolForKey:@"showSurvey"],[defaults boolForKey:@"rateDone"]);
    if ([defaults boolForKey:@"showSurvey"]&&![defaults boolForKey:@"rateDone"])
        [self performSelector:@selector(showSurvey) withObject:nil afterDelay:0.1];
//    [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.1];
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.1];
        
    });

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
//    ALAssetRepresentation *defaultRep = [asset defaultRepresentation];
//    UIImageOrientation orientation = UIImageOrientationUp;
//    NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
//    if (orientationValue != nil) {
//        orientation = [orientationValue intValue];
//    }
    
//    UIImage *image = [UIImage imageWithCGImage:[defaultRep fullResolutionImage] scale:[defaultRep scale] orientation:(UIImageOrientation)[defaultRep orientation]]; //6.5MBx4=26MB
//    UIImage *image = [UIImage imageWithCGImage:[defaultRep fullScreenImage] scale:[defaultRep scale] orientation:(UIImageOrientation)[defaultRep orientation]];
    UIImage *image = [self thumbnailForAsset:asset maxPixelSize:1280];//2560 is 4-5MBx4=20MB
    if ([[segue identifier] isEqualToString:@"showDesign"])
    {
        designViewController *vc = [segue destinationViewController];
        vc.selectedImage=image;
        NSLog(@"image size is %lu",(unsigned long)[UIImageJPEGRepresentation(image, 1.0) length]);
    }
}
// Helper methods for thumbnailForAsset:maxPixelSize:
static size_t getAssetBytesCallback(void *info, void *buffer, off_t position, size_t count) {
    ALAssetRepresentation *rep = (__bridge id)info;
    
    NSError *error = nil;
    size_t countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
    
    if (countRead == 0 && error) {
        // We have no way of passing this info back to the caller, so we log it, at least.
        NSLog(@"thumbnailForAsset:maxPixelSize: got an error reading an asset: %@", error);
    }
    
    return countRead;
}

static void releaseAssetCallback(void *info) {
    // The info here is an ALAssetRepresentation which we CFRetain in thumbnailForAsset:maxPixelSize:.
    // This release balances that retain.
    CFRelease(info);
}

// Returns a UIImage for the given asset, with size length at most the passed size.
// The resulting UIImage will be already rotated to UIImageOrientationUp, so its CGImageRef
// can be used directly without additional rotation handling.
// This is done synchronously, so you should call this method on a background queue/thread.
- (UIImage *)thumbnailForAsset:(ALAsset *)asset maxPixelSize:(NSUInteger)size {
    NSParameterAssert(asset != nil);
    NSParameterAssert(size > 0);
    
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    
    CGDataProviderDirectCallbacks callbacks = {
        .version = 0,
        .getBytePointer = NULL,
        .releaseBytePointer = NULL,
        .getBytesAtPosition = getAssetBytesCallback,
        .releaseInfo = releaseAssetCallback,
    };
    
    CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(rep), [rep size], &callbacks);
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) @{
                                                                                                      (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                                                                      (NSString *)kCGImageSourceThumbnailMaxPixelSize : [NSNumber numberWithInt:(int)size],
                                                                                                      (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                                                                      });
    CFRelease(source);
    CFRelease(provider);
    
    if (!imageRef) {
        return nil;
    }
    
    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
    
    CFRelease(imageRef);
    
    return toReturn;
}
- (void)rateApp {
    
    [Flurry logEvent:@"Rate App" ];
    [defaults setBool:YES forKey:@"rateDone"];
//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/app/850204569"]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=850204569&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"]];
    return;
    
    // Initialize Product View Controller
    SKStoreProductViewController *storeProductViewController = [[SKStoreProductViewController alloc] init];
    
    // Configure View Controller  850204569
    [storeProductViewController setDelegate:self];
    [storeProductViewController loadProductWithParameters:
  @{SKStoreProductParameterITunesItemIdentifier : @"850204569"} completionBlock:^(BOOL result, NSError *error) {
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
