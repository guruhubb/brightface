//
//  doneViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import "doneViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"

@interface doneViewController ()
@property (strong, atomic) ALAssetsLibrary* library;
@property (nonatomic, strong) UIImage *image;
@end

@implementation doneViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //Add this in the method where you wish to save
    
    [self.library saveImage:self.image toAlbum:@"splitagram" withCompletionBlock:^(NSError                 *error) {
        if (error!=nil) {
            NSLog(@"Big error: %@", [error description]);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
