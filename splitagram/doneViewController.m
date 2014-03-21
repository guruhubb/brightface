//
//  doneViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import "doneViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
//#import "ALAssetsLibrary+CustomPhotoAlbum.h"

@interface doneViewController (){
    ALAssetsGroup* groupToAddTo;
    NSString *albumName;
    ALAssetsLibrary *library;
}
//@property (strong, atomic) ALAssetsLibrary* library;
@end

@implementation doneViewController
//@synthesize library=_library;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
//    self.library = [[ALAssetsLibrary alloc] init];
    //Add this in the method where you wish to save
    albumName = @"splitagram";
    self.imageView.image=self.image;
    //find album
//    __block ALAssetsGroup* groupToAddTo;
    library = [doneViewController defaultAssetsLibrary];
    [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                        NSLog(@"found album %@", albumName);
                                        groupToAddTo = group;
                                    }
                                    else {  //create album
                                        NSLog(@"create album %@", albumName);

                                        [library addAssetsGroupAlbumWithName:albumName
                                                                      resultBlock:^(ALAssetsGroup *group) {
                                                                      }
                                                                     failureBlock:^(NSError *error) {
                                                                         NSLog(@"error adding album");
                                                                     }];
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
                                                         // assign the photo to the album
                                                         [groupToAddTo addAsset:asset];
                                                         NSLog(@"Added %@ to %@", [[asset defaultRepresentation] filename], albumName);
                                                     }
                                                    failureBlock:^(NSError* error) {
                                                        NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                    }];
                                   }
                                   else {
                                       NSLog(@"saved image failed.\nerror code %i\n%@", error.code, [error localizedDescription]);
                                   }
                               }];
    
}

//- (void) saveImage: (UIImage *)image {
//
//    [self.library saveImage:image toAlbum:@"splitagram" withCompletionBlock:^(NSError *error) {
//        NSLog(@"add to album");
//
//        if (error!=nil) {
//            NSLog(@"Big error: %@", [error description]);
//        }
//    }];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
