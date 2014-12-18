//
//  PhotoCell.m
//  brightface
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#import "PhotoCell.h"

@interface PhotoCell ()
@property(nonatomic, weak) IBOutlet UIImageView *photoImageView;
@end

@implementation PhotoCell

- (void) setAsset:(ALAsset *)asset
{
    _asset = asset;
    self.photoImageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
}

@end
