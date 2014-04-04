//
//  doneViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//
#define IS_TALL_SCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define screenSpecificSetting(tallScreen, normal) ((IS_TALL_SCREEN) ? tallScreen : normal)

#import "doneViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "shareViewController.h"

@interface doneViewController (){
    ALAssetsGroup* groupToAddTo;
    NSString *albumName;
    ALAssetsLibrary *library;
    ALAsset *assetSaved;
}
@end

@implementation doneViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect frame = CGRectMake(0, 0, 125, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:18.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"share";
    self.navigationItem.titleView = label;
    if (!IS_TALL_SCREEN) {
        self.menuView.frame = CGRectMake(0, 454-88, 320, 50);  // for 3.5 screen; remove autolayout
    }
    albumName = @"splitagram";
    self.imageView.image=self.image;
    //find album
    library = [doneViewController defaultAssetsLibrary];
    [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                        NSLog(@"found album %@", albumName);
                                        groupToAddTo = group;
                                    }
                                }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                              }];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"savePhoto"]){
        [self saveImage];
        _saveButton.hidden=YES;
    }
    else
        _saveButton.hidden=NO;
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
//                                             initWithImage:nil
//                                             style:UIBarButtonItemStylePlain
//                                             target:self
//                                             action:@selector(goHome:)];
    [self performSegueWithIdentifier:@"shareToNav" sender:self];
}
- (IBAction)saveImageAction:(id)sender {
    [self saveImage];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"saved to camera roll" message:nil
                                                   delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil];
    [alert show];

}

- (void) saveImage {
    //save image to library and then put it in album
    CGImageRef img = [self.image CGImage];
    [library writeImageToSavedPhotosAlbum:img
                                      metadata:nil //[info objectForKey:UIImagePickerControllerMediaMetadata]
                               completionBlock:^(NSURL* assetURL, NSError* error) {
                                   if (error.code == 0) {
                                       NSLog(@"saved image completed:\nurl: %@", assetURL);
                                       
                                       // try to get the asset
                                       [library assetForURL:assetURL
                                                     resultBlock:^(ALAsset *asset) {
                                                         assetSaved=asset;
                                                         // assign the photo to the album
                                                         [groupToAddTo addAsset:asset];
                                                         NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], albumName);
                                                     }
                                                    failureBlock:^(NSError* error) {
                                                        NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                    }];
                                   }
                                   else {
                                       NSLog(@"saved image failed.\nerror code %li\n%@", (long)error.code, [error localizedDescription]);
                                   }
                               }];
}
- (IBAction)deleteImage:(id)sender {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"savePhoto"]) {

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"delete",nil];
    [actionSheet showInView:sender];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==0){
        if(assetSaved.isEditable ) {
            [assetSaved setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                NSLog(@"Asset url %@ should be deleted. (Error %@)", assetURL, error);
            }];
        }
        [self goHome:self];
    }
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

- (IBAction)goHome:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"shareToNav"])
	{
		UINavigationController *navigationController = segue.destinationViewController;
		shareViewController *vc = [[navigationController viewControllers] objectAtIndex:0];
        vc.image=self.image;
        NSLog(@"vc.imageDone is %@",vc.image);
        
        //		vc.delegate = self;
	}
//
//    if ([[segue identifier] isEqualToString:@"ShareViewController"])
//    {
//        shareViewController *vc = [segue destinationViewController];
//        vc.image=self.image;
//    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
