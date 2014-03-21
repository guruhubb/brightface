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
    if (!IS_TALL_SCREEN) {
        self.collectionView.frame = CGRectMake(0, 95+64, 320, 480-(95+64));  // for 3.5 screen; remove autolayout
    }
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
        [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.01];
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading images %@", error);
    }];
}
-(void)scrollToBottom
{//Scrolls to bottom of scroller
    
    CGPoint bottomOffset = CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.bounds.size.height);
    [self.collectionView setContentOffset:bottomOffset animated:NO];
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
    NSLog(@"index is %d",selectedPhotoIndex);

    ALAsset *asset = self.assets[selectedPhotoIndex];
    ALAssetRepresentation *defaultRep = [asset defaultRepresentation];
    UIImage *image = [UIImage imageWithCGImage:[defaultRep fullScreenImage] scale:[defaultRep scale] orientation:0];
    if ([[segue identifier] isEqualToString:@"showDesign"])
    {
        designViewController *vc = [segue destinationViewController];
        vc.selectedImage=image;

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


@end
