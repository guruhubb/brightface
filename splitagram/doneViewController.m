//
//  doneViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import "doneViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

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
    label.font = [UIFont systemFontOfSize:20.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"share split";
    self.navigationItem.titleView = label;
    
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
    [self saveImage];
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"delete",nil];
    [actionSheet showInView:sender];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
