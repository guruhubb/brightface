//
//  gridViewController.m
//  stripes
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//
#define IS_TALL_SCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define screenSpecificSetting(tallScreen, normal) ((IS_TALL_SCREEN) ? tallScreen : normal)

#import "gridViewController.h"
#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoCell.h"
#import "pageViewController.h"
//#import "pageViewContentViewController.h"
@interface gridViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    NSInteger selectedPhotoIndex;

}
@property(nonatomic, weak) IBOutlet UICollectionView *gridCollectionView;
@property(nonatomic, strong) NSArray *assets;

@end

@implementation gridViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect frame = CGRectMake(0, 0, 125, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:18];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"my stripes";
    self.navigationItem.titleView = label;
}
- (void)viewDidAppear:(BOOL)animated   {
    _assets = [@[] mutableCopy];
    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    NSString *albumName = @"stripes";
    ALAssetsLibrary *assetsLibrary = [gridViewController defaultAssetsLibrary];

    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if(result)
                {
                    [tmpAssets addObject:result];
                }
            }];
            self.assets = tmpAssets;
            NSLog(@"  assets count = %lu", (unsigned long)self.assets.count);
            
            
            [self.gridCollectionView reloadData];
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading images %@", error);
    }];
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
    if ([[segue identifier] isEqualToString:@"PageViewController"])
    {
        pageViewController *vc = [segue destinationViewController];
        vc.pageImages=self.assets;
        vc.index = selectedPhotoIndex;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
