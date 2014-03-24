//
//  pageViewContentViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import "pageViewContentViewController.h"

@interface pageViewContentViewController ()

@end

@implementation pageViewContentViewController


- (IBAction)deleteImage:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"delete",nil];
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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
