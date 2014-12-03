//
//  pageViewContentViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//
#define IS_TALL_SCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define screenSpecificSetting(tallScreen, normal) ((IS_TALL_SCREEN) ? tallScreen : normal)

#import "pageViewContentViewController.h"
#import "shareViewController.h"

@interface pageViewContentViewController ()

@end

@implementation pageViewContentViewController


- (IBAction)deleteImage:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"delete",nil];
    [actionSheet showInView:sender];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==0){
        if(self.asset.isEditable ) {
                [self.asset setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                    NSLog(@"Asset url %@ should be deleted. (Error %@)", assetURL, error);
                }];
            }
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.backgroundImageView.image = self.image;
    self.titleLabel.text = self.titleText;
    if (!IS_TALL_SCREEN) {
        self.menuView.frame = CGRectMake(0, 480-44-50-20, 320, 50);  // for 3.5 screen; remove autolayout
        self.titleLabel.frame = CGRectMake(123,5,75,20);
        self.backgroundImageView.frame = CGRectMake(0,30,320,320);

    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShareViewController"])
	{
		UINavigationController *navigationController = segue.destinationViewController;
		shareViewController *vc = [[navigationController viewControllers] objectAtIndex:0];
        vc.image=self.image;
        NSLog(@"vc.image is %@",vc.image);

//		vc.delegate = self;
	}
//    if ([[segue identifier] isEqualToString:@"ShareViewController"])
//    {
////        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
////        shareViewController *vc = (shareViewController*)[storyboard instantiateViewControllerWithIdentifier:@"ShareViewController"];
//
//        shareViewController *vc = [segue destinationViewController];
//        vc.image=self.image;
//        NSLog(@"vc.image is %@",vc.image);
//    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
