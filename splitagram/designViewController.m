//
//  designViewController.m
//  splitagram
//
//  Created by Saswata Basu on 3/21/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//
#define IS_TALL_SCREEN ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define screenSpecificSetting(tallScreen, normal) ((IS_TALL_SCREEN) ? tallScreen : normal)
#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI)
#define kBorderWidth 3.0
#define kBlockWidth 7.0
#define kZoomMin 0.5
#define kZoomMax 2.5
#define kSplitMin 0.0
#define kSplitMax 20
#define kRotateMin -M_PI
#define kRotateMax M_PI
#import "designViewController.h"
#import "doneViewController.h"
#import "GPUImage.h"
#import "MKStoreManager.h"
#import "Flurry.h"

@interface designViewController (){
    
    NSMutableArray *labelEffectsArray;
    NSMutableArray *labelSecondEffectsArray;
    NSMutableArray *droppableAreas;
    BOOL firstTimeEffects;
    BOOL firstTime;
    BOOL firstTimeFilter;
    BOOL firstTimeDesign;
    NSInteger tapBlockNumber;
    NSInteger nStyle;
    NSInteger nSubStyle;
    NSInteger nMargin;
    
    CGRect rectBlockSlider1;
    CGRect rectBlockSlider2;
    CGRect rectBlockSlider3;
    CGRect rectBlockSlider4;

    UIScrollView* blockSlider1;
    UIScrollView* blockSlider2;
    UIScrollView* blockSlider3;
    UIScrollView* blockSlider4;
    UIImageView* image1;
    UIImageView* image2;
    UIImageView* image3;
    UIImageView* image4;
    
    UISlider *sliderZoom;
    UISlider *sliderRotate;
    UISlider *sliderSplit;
    UILabel *labelZoom;
    UILabel *labelRotate;
    UILabel *labelSplit;
    
    CGFloat zoom1;
    CGFloat zoom2;
    CGFloat zoom3;
    CGFloat zoom4;
    
    GPUImageOutput<GPUImageInput> *filter;
    NSUserDefaults *defaults;
    
    CGFloat imageWidth;
    CGFloat imageHeight;
}

@property (weak, nonatomic) IBOutlet UIImageView *selectedImageView;
@end

@implementation designViewController

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
//    self.selectedImageView.image=self.selectedImage;
    CGRect frame = CGRectMake(0, 0, 125, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:18.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"create";
    self.navigationItem.titleView = label;
    
    defaults = [NSUserDefaults standardUserDefaults];
    if (!IS_TALL_SCREEN) {
        self.designViewContainer.frame = CGRectMake(0, 320, 320, 480-64-320);  // for 3.5 screen; remove autolayout
        self.designViewContainer.contentSize = CGSizeMake(self.designViewContainer.frame.size.width, 184);
    }
    [self fillFrameSelectionSlider];
    [self fillSecondFrameSelectionSlider];
    [self fillRotateMenu];
    [self fillSplitMenu];
    [self resetGestureParameters ];
    
   
    if ([defaults boolForKey:@"watermark"]) //if 0 then watermark is ON
        _watermarkOnImage.hidden=YES;
    
    if ([defaults boolForKey:@"white"])
        _frameContainer.backgroundColor=[UIColor blackColor];

    nMargin = [defaults integerForKey:@"Split"];
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        nMargin = 5;
        [defaults setInteger:5 forKey:@"Split"];
    });

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 19;
    [self frameClicked:btn];
//    [self frameClicked:btn];
    firstTimeDesign = YES;
//    [self performSelector:@selector(frameClicked:) withObject:btn afterDelay:0.1];

    if (![defaults boolForKey:@"filter"])
        [self randomFilterPick];

    
//    [defaults setBool:YES forKey:kFeature0];  //test
//    [defaults setBool:YES forKey:kFeature1];  //test
}
- (void) randomFilterPick {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//    int randNum = arc4random() % 11 ;
    int number = [defaults integerForKey:@"number"];
    NSLog(@"number is %d",number);
    if (number > 9) {
        number = 1;
    }
//    dispatch_queue_t queue = dispatch_queue_create("com.saswata.queue", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_async(queue, ^{

    btn.tag = number;
    tapBlockNumber=1;
//    [self performSelectorOnMainThread:@selector(effectsClicked:) withObject:btn waitUntilDone:YES];
//        dispatch_async(dispatch_get_main_queue(), ^{
            [self effectsClicked:btn];
//});
//    });
    
//    dispatch_async(queue, ^{
    btn.tag = number+1;
    tapBlockNumber=2;
//    [self performSelectorOnMainThread:@selector(effectsClicked:) withObject:btn waitUntilDone:YES];

//    [self performSelector:@selector(effectsClicked:) withObject:btn afterDelay:0.3];
//dispatch_async(dispatch_get_main_queue(), ^{
    [self effectsClicked:btn];
//});
//    });
    
//    dispatch_async(queue, ^{
    btn.tag = number+2;
    tapBlockNumber=3;
//    [self performSelectorOnMainThread:@selector(effectsClicked:) withObject:btn waitUntilDone:YES];

//    [self performSelector:@selector(effectsClicked:) withObject:btn afterDelay:0.5];
//dispatch_async(dispatch_get_main_queue(), ^{
    [self effectsClicked:btn];
//});
//    });
    
    tapBlockNumber=0;
    number ++;
    [defaults setInteger:number forKey:@"number"];

}
- (void) resetGestureParameters {
    
    
    [defaults setFloat:0.0f forKey:@"PanX"];
    [defaults setFloat:0.0f forKey:@"PanY"];
    [defaults setFloat:0.0f forKey:@"Rotate"];
    [defaults setFloat:1.0f forKey:@"Zoom"];
    [defaults setBool:NO forKey:@"Flip"];
    
//    [defaults setFloat:0.0f forKey:@"PanX1"];
//    [defaults setFloat:0.0f forKey:@"PanY1"];
//    [defaults setFloat:0.0f forKey:@"Rotate1"];
//    [defaults setFloat:1.0f forKey:@"Zoom1"];
//    
//    [defaults setFloat:0.0f forKey:@"PanX2"];
//    [defaults setFloat:0.0f forKey:@"PanY2"];
//    [defaults setFloat:0.0f forKey:@"Rotate2"];
//    [defaults setFloat:1.0f forKey:@"Zoom2"];
//    
//    [defaults setFloat:0.0f forKey:@"PanX3"];
//    [defaults setFloat:0.0f forKey:@"PanY3"];
//    [defaults setFloat:0.0f forKey:@"Rotate3"];
//    [defaults setFloat:1.0f forKey:@"Zoom3"];
    
}
- (void)viewDidAppear:(BOOL)animated   {
    if (!firstTimeFilter){
        firstTimeFilter = YES;
        [self fillEffectsSlider];
        [self fillSecondEffectsSlider];
    
    }
    if (!firstTimeDesign){
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag=[defaults integerForKey:@"frame"];
        if (btn.tag <= 25)
            [self frameClicked:btn];
        else
            [self secondFrameClicked:btn];
    }
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }

}

-(void)frameAction
{
    UIActionSheet *popupQuery;
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"get more frames",@"buy for $1.99",nil];
    popupQuery.tag=0;
    [popupQuery showInView:self.view];
}
-(void)filterAction
{
    UIActionSheet *popupQuery;
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"get more filters",@"buy for $1.99",nil];
    popupQuery.tag=1;
    [popupQuery showInView:self.view];
}
//-(void)watermarkAction
//{
//    UIActionSheet *popupQuery;
//    if (![defaults boolForKey:kFeature2]){  //if not purchased
//        popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"remove watermark",@"buy for $1.99",nil];
//        popupQuery.tag=2;
//        [popupQuery showInView:self.view];
//        _watermark.on = YES;
//    }
//    else {  //if purchased
//        if (_watermark.on) {
//            _watermark.on = NO;
//            _watermarkOnImage.hidden=YES;
//        }
//        else {
//            _watermark.on = YES;
//            _watermarkOnImage.hidden=NO;
//        }
//    }
//}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (actionSheet.tag == 0) {
        if (buttonIndex==1){
            [self inAppBuyAction:actionSheet.tag];
        }
//        else if (buttonIndex==1)[defaults setBool:YES forKey:@"crop"];
        
//    }
//    else if (actionSheet.tag == 1) {
//        if (buttonIndex==0){
//            [self inAppBuyAction:actionSheet.tag];
//        }
////        else if (buttonIndex==1)[defaults setBool:YES forKey:@"white"];
//    }
//    if (actionSheet.tag == 2) {
//        if (buttonIndex==0 || buttonIndex ==2){
//            if (_watermark.on) {
//                _watermark.on = NO;
//                _watermarkOnImage.hidden=YES;
//            }
//            else {
//                _watermark.on = YES;
//                _watermarkOnImage.hidden=NO;
//            }
//        }
//    }
//            [self inAppBuyAction:actionSheet.tag];
//        }
//        //        else if (buttonIndex==1)[defaults setBool:YES forKey:@"white"];
//    }
//    
//    UILabel *label1 = (UILabel *) [self.view viewWithTag:100];
//    UILabel *label2 = (UILabel *) [self.view viewWithTag:101];
//    [label1 removeFromSuperview];
//    [label2 removeFromSuperview];
//    
//    [self.settingsTableView reloadData];
    
}


- (void) updateAppViewAndDefaults {
    
        if ([MKStoreManager isFeaturePurchased:kFeature0])
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFeature0];
        else
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kFeature0];
        
        if([MKStoreManager isFeaturePurchased:kFeature1])
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFeature1];
        else
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kFeature1];
    
}

- (void)inAppBuyAction:(int)tag {
    NSString *string;

    switch (tag) {
        case 0:
            string = kFeature0;
            [Flurry logEvent:@"InApp Frames"];
            break;
        case 1:
            string = kFeature1;
            [Flurry logEvent:@"InApp Filters"];
            break;
        default:
            break;
    }
    
    [[MKStoreManager sharedManager] buyFeature:string
                                    onComplete:^(NSString* purchasedFeature,
                                                 NSData* purchasedReceipt,
                                                 NSArray* availableDownloads)
     {
             NSLog(@"Purchased: %@, available downloads is %@ string is %@", purchasedFeature, availableDownloads, string);
             
   
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Successful" message:nil
                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
             [[NSUserDefaults standardUserDefaults] setBool:YES  forKey:string];
             [alert show];
             [self updateAppViewAndDefaults];

     }
                                   onCancelled:^
     {
         NSLog(@"User Cancelled Transaction");
     }];
    
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"doneDesign"])
    {
        firstTimeDesign=NO;
        for (UIScrollView *blockSlider in droppableAreas)
            [blockSlider.layer setBorderColor:[[UIColor clearColor] CGColor]];
        doneViewController *vc = [segue destinationViewController];
        CGRect rect = _frameContainer.frame;//[[UIScreen mainScreen] bounds];
        //    UIGraphicsBeginImageContext(rect.size);
        UIGraphicsBeginImageContextWithOptions(rect.size, YES, 2.0);  //v1.0 bookly use this instead of withoutOptions and 2.0 magnification to give a sharper image  //v1.0g bookly Scaling at 2.0 is too much pixels and too big of an image to email.  0.0 goes to default image size of the device which makes it pretty large.  So the optimum is 1.25 scaling with 0.6 compression to keep most images at around 50kB.
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [_frameContainer.layer renderInContext:context];
        vc.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
//        vc.image=self.selectedImage;
    }
}

- (void) fillFrameSelectionSlider {
    //    self.frameSelectionSlider = (UIScrollView *)[self.view viewWithTag:10120];
    if (!IS_TALL_SCREEN) {
        self.frameSelectionBar.contentSize = CGSizeMake(55 * 19+10, self.frameSelectionBar.frame.size.height);
    } else {
        self.frameSelectionBar.contentSize = CGSizeMake(70 * 19+10, 151);
//        self.frameSelectionBar.frame=CGRectMake(0, 353, 320, 151);
    }
    for (int ind = 7; ind <= 25; ind++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (!IS_TALL_SCREEN)
            btn.frame = CGRectMake((ind - 7 ) * 55+5, 5, 50, 50);
        else
            btn.frame = CGRectMake((ind - 7 ) * 70+5, 5, 65, 65);
            
        
        btn.tag = ind;
        //            btn.showsTouchWhenHighlighted=YES;
        btn.layer.borderWidth=kBorderWidth;
        btn.layer.borderColor=[[UIColor clearColor] CGColor];
        NSLog(@"btn.tag is %d ",btn.tag);
        [btn addTarget:self action:@selector(frameClicked:) forControlEvents:UIControlEventTouchUpInside];
        NSLog(@"Frame%02d.png",ind);
        [btn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Frame%02d.png",ind]] forState:UIControlStateNormal];
        btn.alpha = 0.5;
        [btn.imageView setContentMode:UIViewContentModeScaleToFill];

        [self.frameSelectionBar addSubview:btn];
    }
    
    
}
- (void) fillSecondFrameSelectionSlider {
    for (int ind = 8; ind <= 26; ind++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (!IS_TALL_SCREEN)
            btn.frame = CGRectMake((ind - 8 ) * 55+5, 60, 50, 50);
        else
            btn.frame = CGRectMake((ind - 8 ) * 70+5, 75, 65, 65);
        btn.tag = ind+25;
        btn.layer.borderWidth=kBorderWidth;
        btn.layer.borderColor=[[UIColor clearColor] CGColor];
        [btn addTarget:self action:@selector(secondFrameClicked:) forControlEvents:UIControlEventTouchUpInside];
        NSLog(@"secondFrame%02d.png",ind);
        [btn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"secondFrame%02d.png",ind]] forState:UIControlStateNormal];
        btn.alpha = 0.5;
        [btn.imageView setContentMode:UIViewContentModeScaleToFill];
        [self.frameSelectionBar addSubview:btn];
        
        if (![defaults boolForKey:kFeature0]){
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lockImage.png"]];
            imageView.alpha = 0.8;
            imageView.layer.shadowColor = [UIColor blackColor].CGColor;
            imageView.layer.shadowOffset = CGSizeMake(0, 1);
            imageView.layer.shadowOpacity = 1;
            imageView.frame=CGRectMake(btn.frame.size.width-15, 2, 15, 15);
            [btn addSubview:imageView];
        }
    }
}

- (void)frameClicked:(UIButton *)clickedBtn
{
//    NSLog(@"draggable %@, originalimagescount is %d, arrImagescount is %d",self.draggableSubjects, self.originalImages.count, self.arrImages.count);
    //    if (self.originalImages.count !=self.arrImages.count) return;
    
//    if (firstTime){
//        [self setupTextBox];
//        
//        
//        _textOne.hidden=YES;
//        [self photoFrameView:nil];
//        //        [self.dragRegion setFrame:CGRectMake(self.dragRegion.frame.origin.x, 400, self.dragRegion.frame.size.width, self.dragRegion.frame.size.height)];
//        //        self.photoSlider.hidden=NO;
//        //        [self fillSolidColorSelectionSlider];
//        //        [self fillBlendSlider];
//        //        [self fillFontColorSlider];
//        //        [self fillFontSlider];
//        //        [self fillStickerSlider];
//        //        [self setUpFontsAndColors];
//        //
//        //        [self fillSecondBlendSlider];
//        //        [self fillSecondFontSlider];
//        //        [self fillSecondStickerSlider];
//    }
//    else
//        [Flurry logEvent:@"Frame - Frames"];
    
//    if (![self.draggableSubjects count]) return;
//    _firstHelpView.hidden=YES;
    //    [self unHideSideButtons];
    
    
    //    [self.view bringSubviewToFront:self.panView];
    
//    UIScrollView *scrllFrame = (UIScrollView *)[self.view viewWithTag:10120];
//    for (int i = 1; i <= 25; i++) {
//        UIButton *frameButton = (UIButton *)[scrllFrame viewWithTag:i];
//        frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
//        
//        //        if (frameButton.highlighted==YES)
//        //            frameButton.highlighted=NO;
//    }
    [defaults setInteger:clickedBtn.tag forKey:@"frame"];
    for (int i = 1; i <= 35+25; i++) {
        UIButton *frameButton = (UIButton *)[_frameSelectionBar viewWithTag:i];
        frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
        
        //        if (frameButton.highlighted==YES)
        //            frameButton.highlighted=NO;
    }
    
    //    [self performSelector:@selector(highlightButton:) withObject:clickedBtn afterDelay:0.0];
    clickedBtn.layer.borderColor=[[UIColor blackColor] CGColor];
    
    switch (clickedBtn.tag) {
        case 1:
            [self selectFrame:1 SUB:1];
            break;
        case 2:
            [self selectFrame:1 SUB:2];
            break;
        case 3:
            [self selectFrame:1 SUB:3];
            break;
        case 4:
            [self selectFrame:1 SUB:4];
            break;
            
        case 5:
            [self selectFrame:1 SUB:5];
            break;
            
        case 6:
            
            [self selectFrame:1 SUB:6];
            break;
        case 7:
            
            [self selectFrame:2 SUB:1];
            break;
        case 8:
            
            [self selectFrame:2 SUB:2];
            break;
        case 9:
            
            [self selectFrame:2 SUB:3];
            break;
        case 10:
            
            [self selectFrame:2 SUB:4];
            break;
        case 11:
            
            [self selectFrame:2 SUB:5];
            break;
            
        case 12:
            
            [self selectFrame:2 SUB:6];
            break;
            
        case 13:
            [self selectFrame:3 SUB:1];
            break;
        case 14:
            [self selectFrame:3 SUB:2];
            break;
        case  15:
            
            [self selectFrame:3 SUB:3];
            break;
        case 16:
            
            [self selectFrame:3 SUB:4];
            break;
        case 17:
            
            [self selectFrame:3 SUB:5];
            break;
        case 18:
            
            [self selectFrame:3 SUB:6];
            break;
        case 19:
            
            [self selectFrame:4 SUB:1];
            break;
        case 20:
            
            [self selectFrame:4 SUB:2];
            break;
        case 21:
            
            [self selectFrame:4 SUB:3];
            break;
        case 22:
            
            [self selectFrame:4 SUB:4];
            break;
        case 23:
            
            [self selectFrame:4 SUB:5];
            break;
        case 24:
            
            [self selectFrame:4 SUB:6];
            break;
        case 25:
            
            [self selectFrame:4 SUB:7];
            break;
            
        default:
            break;
    }
}
- (void)secondFrameClicked:(UIButton *)clickedBtn
{
    [defaults setInteger:clickedBtn.tag forKey:@"frame"];

//    NSLog(@"second frame clicked ");
    if (![defaults boolForKey:kFeature0]){
        [self frameAction];
        return;
    }
//    else {
//
//        if (firstTime){
//            [self setupTextBox];
//            
//            _textOne.hidden=YES;
//            //        [self fillPhotoSlider];
//            [self photoFrameView:nil];
            //        [self.dragRegion setFrame:CGRectMake(self.dragRegion.frame.origin.x, 400, self.dragRegion.frame.size.width, self.dragRegion.frame.size.height)];
            //        self.photoSlider.hidden=NO;
            //        [self fillSolidColorSelectionSlider];
            //        [self fillBlendSlider];
            //        [self fillFontColorSlider];
            //        [self fillFontSlider];
            //        [self fillStickerSlider];
            //        [self setUpFontsAndColors];
            //
            //        [self fillSecondBlendSlider];
            //        [self fillSecondFontSlider];
            //        [self fillSecondStickerSlider];
//        }
//        else
//            [Flurry logEvent:@"Frame - Second Frames"];
//        
//        if (![self.draggableSubjects count]) return;
//        _firstHelpView.hidden=YES;
//        [self unHideSideButtons];
    
//        for (int i = 1; i <= 25; i++) {
//            UIButton *frameButton = (UIButton *)[frameSelectionSlider viewWithTag:i];
//            frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
//            
//            //        if (frameButton.highlighted==YES)
//            //            frameButton.highlighted=NO;
//        }
        for (int i = 1; i <= 35+25; i++) {
            UIButton *frameButton = (UIButton *)[_frameSelectionBar viewWithTag:i];
            frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
            
            //        if (frameButton.highlighted==YES)
            //            frameButton.highlighted=NO;
        }
        //    [self performSelector:@selector(highlightButton:) withObject:clickedBtn afterDelay:0.0];
        clickedBtn.layer.borderColor=[[UIColor blackColor] CGColor];
        
        switch (clickedBtn.tag-25) {
            case 1:
                
                [self selectFrame:1 SUB:7];
                break;
                //        case 2:
                //            [self selectFrame:1 SUB:8];
                //            break;
                
            case 2: 
                [self selectFrame:1 SUB:9];
                break;
            case 3:
                [self selectFrame:1 SUB:10];
                break;
            case 4:
                
                [self selectFrame:1 SUB:11];
                break;
                
            case 5:
                
                [self selectFrame:1 SUB:12];
                break;
            case 6:
                
                [self selectFrame:1 SUB:13];
                break;
            case 7:
                
                [self selectFrame:1 SUB:14];
                break;
                //        case 9:
                //
                //            [self selectFrame:1 SUB:15];
                //            break;
            case 12:
                
                [self selectFrame:2 SUB:7];
                break;
                
            case 9:
                
                [self selectFrame:2 SUB:8];
                break;
//
//            case 10:
//                
//                [self selectFrame:2 SUB:9];
//                break;
                
            case 8:
                
                [self selectFrame:2 SUB:10];
                break;
//            case 9:
//                
//                [self selectFrame:2 SUB:11];
//                break;
            case 10:
                
                [self selectFrame:2 SUB:12];
                break;
            case 11:
                
                [self selectFrame:2 SUB:13];
                break;
//            case 15:
//                
//                [self selectFrame:2 SUB:14];
//                break;
//            case 16:
//                
//                [self selectFrame:2 SUB:15];
//                break;
                
                
//            case 17:
//                
//                [self selectFrame:2 SUB:16];
//                break;
            case 13:
                
                [self selectFrame:3 SUB:7];
                break;
            case 14:
                
                [self selectFrame:3 SUB:8];
                break;
            case 15:
                
                [self selectFrame:3 SUB:9];
                break;
            case 16:
                
                [self selectFrame:3 SUB:10];
                break;
            case 17:
                
                [self selectFrame:3 SUB:11];
                break;
            case 18:
                
                [self selectFrame:3 SUB:12];
                break;
//            case 18:
//                
//                [self selectFrame:3 SUB:13];
//                break;
                
            case 19:
                [self selectFrame:3 SUB:14];
                break;
//            case 26:
//                
//                [self selectFrame:3 SUB:15];
//                break;
//            case 27:
//                [self selectFrame:3 SUB:16];
//                break;
                
                //        case 28:
                //
                //            [self selectFrame:4 SUB:8];
                //            break;
                //        case 29:
                //
                //            [self selectFrame:4 SUB:9];
                //            break;
            case 20:
                
                [self selectFrame:4 SUB:10];
                break;
            case 21:
                
                [self selectFrame:4 SUB:11];
                break;
            case 22:
                
                [self selectFrame:4 SUB:12];
                break;
            case 23:
                
                [self selectFrame:4 SUB:13];
                break;
                
            case 24:
                [self selectFrame:4 SUB:14];
                break;
                //        case 33:
                //
                //            [self selectFrame:4 SUB:15];
                //            break;
            case 25:
                [self selectFrame:4 SUB:16];
                
                break;
//            case 34:
//                [self selectFrame:4 SUB:17];
//                
//                break;
            case 26:
                [self selectFrame:4 SUB:18];
                
                break;
                
            default:
                break;
        }
//    }
}

- (void) fillEffectsSlider {
    labelEffectsArray = [[NSMutableArray alloc]initWithObjects: @"original", @"delight", @"sunny",@"night", @"beach",@"b&w-red",@"sepia",@"water", @"b&w",@"morning", @"sky",nil];
    labelSecondEffectsArray = [[NSMutableArray alloc]initWithObjects: @"2layer",@"warm",@"winter",@"gold",@"platinum",@"copper",@"vignette",@"white", @"crisp",@"candle",@"fall",@"film",@"foggy",@"cobalt",@"blue",@"bright",@"bleak",@"moon",@"cyan",@"soft",nil];
    //    self.effectsSlider = (UIScrollView *)[self.view viewWithTag:10125];
//    self.filterSelectionBar.contentSize = CGSizeMake(65 * 11+10, self.filterSelectionBar.frame.size.height);
    if (!IS_TALL_SCREEN) {
        self.filterSelectionBar.contentSize = CGSizeMake(55 * 11+10, self.frameSelectionBar.frame.size.height);
    } else {
        self.filterSelectionBar.contentSize = CGSizeMake(70 * 11+10, 151);
//        self.filterSelectionBar.frame=CGRectMake(0, 353, 320, 151);
    }
    
    for (int ind = 1; ind <= 11; ind++) {
        @autoreleasepool {
     
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        btn.frame = CGRectMake((ind-1) * 55+5, 5, 50, 50);
        if (!IS_TALL_SCREEN)
            btn.frame = CGRectMake((ind - 1 ) * 55+5, 5, 50, 50);
        else
            btn.frame = CGRectMake((ind - 1 ) * 70+5, 5, 65, 65);

        btn.tag = ind;
        //        btn.showsTouchWhenHighlighted=YES;
        btn.layer.frame = btn.frame;
        btn.layer.borderWidth=kBorderWidth;
        btn.layer.borderColor=[[UIColor clearColor] CGColor];
        NSLog(@"effects btn.tag is %d ",btn.tag);
        [btn addTarget:self action:@selector(effectsClicked:) forControlEvents:UIControlEventTouchUpInside];
        CGRect labelEffects;
//        CGRect labelEffects = CGRectMake((ind - 1 )*55+5, 42, 50, 13);
        if (!IS_TALL_SCREEN)
            labelEffects = CGRectMake((ind - 1 ) * 55+5, 42, 50, 13);
        else
            labelEffects = CGRectMake((ind - 1 ) * 70+5, 57, 65, 13);

        UILabel *label = [[UILabel alloc] initWithFrame:labelEffects];
        label.backgroundColor = [UIColor darkGrayColor];
        label.alpha=0.8;
        label.font = [UIFont boldSystemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.text = [labelEffectsArray objectAtIndex:ind-1];
        label.layer.shadowOffset=CGSizeMake(1, 1);
        label.layer.shadowColor= [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 0.8;
        //        label.layer.masksToBounds=NO;
//        NSString *filters = [NSString stringWithFormat:@"filter #%d",ind];
//        SDImageCache *imageCache = [SDImageCache.alloc initWithNamespace:@"Bookly"];
        UIImage *quickFilteredImage;
//        =[imageCache imageFromDiskCacheForKey:filters];
//        if (quickFilteredImage==NULL) {
            NSLog(@"generating images");
//            UIImage *inputImage = [UIImage imageNamed:@"balloons1.png"];
        UIImage *inputImage = self.selectedImage;
            switch (ind) {
                case 1:{
                    filter = [[GPUImageFilter alloc] init]; //original
                } break;
                case 2: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_amatorka.png"];
                } break;
                case 3: {
                    filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
                } break;
                case 10: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
                } break;
                case 11: {
                    filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
                } break;
                case 4:{
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
                } break;
                case 5: {
                    filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
                } break;
                case 6: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
                } break;
                case 7: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
                } break;
                case 8: {
                    filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
                } break;
                case 9: {
                    filter = [[GPUImageGrayscaleFilter alloc] init];
                } break;
                default:
                    break;
                    
            }
            
            quickFilteredImage = [filter imageByFilteringImage:inputImage];
//            SDImageCache *imageCache = [SDImageCache.alloc initWithNamespace:@"Bookly"];
//            [imageCache storeImage:quickFilteredImage forKey:filters];
//        }
        [btn setImage:quickFilteredImage forState:UIControlStateNormal];
        [btn.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.filterSelectionBar addSubview:btn];
        [self.filterSelectionBar addSubview:label];
        }
    }
}

- (void) turnOnIndicator {
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc]     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center=self.view.center;
    activityView.layer.shadowOffset = CGSizeMake(1, 1);
    activityView.layer.shadowColor = [UIColor blackColor].CGColor;
    activityView.layer.shadowOpacity=0.8 ;
    
    
    activityView.tag = 10001;
    activityView.transform = CGAffineTransformScale(activityView.transform, 1.5, 1.5);
    [activityView startAnimating];
    [self.view addSubview:activityView];
    //
    //    UIView *view = [[UIView alloc ] initWithFrame: CGRectMake(0, 0, 50, 50)];
    //    view.layer.cornerRadius=5.0;
    //    view.layer.shadowOffset = CGSizeMake(2, 2);
    //    view.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    //    view.layer.shadowOpacity = 1.0;
    //    view.layer.shouldRasterize = NO;
    //    view.center = self.view.center;
    //    view.tag = 10002;
    ////    view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"blue.jpg"]];
    //    view.alpha=0.9;
    //    [self.view addSubview:view];
    
}

- (void) turnOffIndicator {
    UIActivityIndicatorView *activityView=(UIActivityIndicatorView *) [self.view viewWithTag:10001];
    [activityView removeFromSuperview];
    [activityView stopAnimating];
}

//- (IBAction)effectsButton:(id)sender {
//    if (firstTimeEffects){
//        [self turnOnIndicator];
//        //        [self hideHelp];
//        //        _effectsHelp.hidden=NO;
//        //        [self.view bringSubviewToFront:_effectsHelp];
//        [self performSelector:@selector(fillEffectsSlider) withObject:nil afterDelay:0.1];
////        [self performSelector:@selector(fillSecondEffectsSlider) withObject:nil afterDelay:0.2];
//        [self performSelector:@selector(turnOffIndicator) withObject:nil afterDelay:0.3];
//        //        [self fillEffectsSlider];
//        //        [self fillSecondEffectsSlider];
//        //        [self performSelector:@selector(turnOffIndicator) withObject:nil afterDelay:0.1];
//        //        [self setUpBlends];
//    }
//    firstTimeEffects = NO;
////    [self hideSliders];
//    //    [self.dragRegion setFrame:CGRectMake(self.dragRegion.frame.origin.x, 90, self.dragRegion.frame.size.width, self.dragRegion.frame.size.height)];
//    self.filterSelectionBar.hidden = NO;
////    self.secondEffectsSlider.hidden=NO;
//    //    self.blendSlider.hidden=NO;
//    
//}

- (void) fillSecondEffectsSlider {
    
//    self.filterSelectionBar.contentSize = CGSizeMake(65 * 20+10, self.filterSelectionBar.frame.size.height);
    
    
    for (int ind = 1; ind <= 11; ind++) {
        @autoreleasepool {
           
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        btn.frame = CGRectMake((ind-1) * 55+5, 60, 50, 50);
        if (!IS_TALL_SCREEN)
            btn.frame = CGRectMake((ind - 1 ) * 55+5, 60, 50, 50);
        else
            btn.frame = CGRectMake((ind - 1 ) * 70+5, 75, 65, 65);
        btn.tag = ind+11;
        btn.layer.borderWidth=kBorderWidth;
        btn.layer.borderColor=[[UIColor clearColor] CGColor];
        
        //        btn.showsTouchWhenHighlighted=YES;
        NSLog(@" second effects btn.tag is %d ",btn.tag);
        [btn addTarget:self action:@selector(secondEffectsClicked:) forControlEvents:UIControlEventTouchUpInside];
        CGRect labelEffects;
//        = CGRectMake((ind - 1 )*55+5, 52+45, 50, 13);
        if (!IS_TALL_SCREEN)
            labelEffects = CGRectMake((ind - 1 ) * 55+5, 52+45, 50, 13);
        else
            labelEffects = CGRectMake((ind - 1 ) * 70+5, 75+65-13, 65, 13);
        UILabel *label = [[UILabel alloc] initWithFrame:labelEffects];
        label.backgroundColor = [UIColor darkGrayColor];
        label.alpha=0.8;
        label.font = [UIFont boldSystemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.text = [labelSecondEffectsArray objectAtIndex:ind-1];
        label.layer.shadowOffset=CGSizeMake(1, 1);
        label.layer.shadowColor= [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 0.8;
//        NSString *filters = [NSString stringWithFormat:@"secondFilter #%d",ind];
//        SDImageCache *imageCache = [SDImageCache.alloc initWithNamespace:@"Bookly"];
        UIImage *quickFilteredImage;
//        =[imageCache imageFromDiskCacheForKey:filters];
//        if (quickFilteredImage==NULL) {
//            NSLog(@"generating images");
            UIImage *inputImage = self.selectedImage;
            switch (ind) {
                case 1:{
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
                } break;
                case 2: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarmBleach.png"];
                } break;
                case 3: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWinter.png"];
                } break;
                case 9: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWarm.png"];
                } break;
                case 10: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"candlelight.png"];
                } break;
                case 11:{
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fallcolors.png"];
                } break;
                case 12: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"filmstock.png"];
                } break;
                case 13: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"foggynight.png"];
                } break;
                case 14: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cobalt2Iron80Bleach.png"];
                } break;
                case 15: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"blue.png"];
                } break;
                case 16: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fuji2393.png"];
                } break;
                case 17: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleak.png"];
                } break;
                case 18: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachMoonlight.png"];
                } break;
                case 19: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cyanSeleniumBleachMoonlight.png"];
                } break;
                case 20: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarm.png"];
                } break;
                case 4: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"gold2.png"];
                } break;
                case 5: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"platinum.png"];
                } break;
                case 6: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"copperSepia2strip.png"];
                } break;
                case 7: {
                    filter = [[GPUImageVignetteFilter alloc] init];
                    [(GPUImageVignetteFilter *) filter setVignetteEnd:0.6];
                } break;
                case 8: {
                    filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"maximumWhite.png"];
                } break;
                    
                default:
                    break;
            }
            
            quickFilteredImage = [filter imageByFilteringImage:inputImage];
//            SDImageCache *imageCache = [SDImageCache.alloc initWithNamespace:@"Bookly"];
//            [imageCache storeImage:quickFilteredImage forKey:filters];
//        }
        
        [btn setImage:quickFilteredImage forState:UIControlStateNormal];
        [btn.imageView setContentMode:UIViewContentModeScaleAspectFill];

        [self.filterSelectionBar addSubview:btn];
        [self.filterSelectionBar addSubview:label];
        //        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"com.guruhubb.bookly.subscription"]){
        //        if(![[MKStoreManager sharedManager] isSubscriptionActive:kFeatureAId]){
        if (![defaults boolForKey:kFeature1]){
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lockImage.png"]];
            imageView.alpha = 0.8;
            imageView.layer.shadowColor = [UIColor blackColor].CGColor;
            imageView.layer.shadowOffset = CGSizeMake(0, 1);
            imageView.layer.shadowOpacity = 1;
//            imageView.layer.shadowRadius = 1.0;
//            imageView.clipsToBounds = NO;
//            imageView.layer.shadowOffset=CGSizeMake(1, 1);
//            imageView.layer.shadowColor= [UIColor blackColor].CGColor;
            imageView.frame=CGRectMake(btn.frame.size.width-15, 2, 15, 15);
            
            //            [[NSUserDefaults standardUserDefaults] setBool:NO  forKey:@"booklySubscription"];
            //            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"glyphicons_203_lock.png"]];
            //            imageView.alpha = 0.5;
            //            imageView.center = CGPointMake(btn.frame.size.width/2, btn.frame.size.height/2);
            //            imageView.tag = ind;
            [btn addSubview:imageView];
        }
        }
        //        else
        //            [[NSUserDefaults standardUserDefaults] setBool:YES  forKey:@"booklySubscription"];
        
//    }
}
}

- (void)effectsClicked:(UIButton *)clickedBtn {
    NSLog(@"block number %d",tapBlockNumber);

//    [  Flurry logEvent:@"Frame - Effects"];
//    [labelToApplyFilterToVideo removeFromSuperview];
    if (tapBlockNumber==100) tapBlockNumber=0;
//    AppRecord *app = [[AppRecord alloc] init];
    for (int i = 1; i <= 11+20; i++) {
        UIButton *frameButton = (UIButton *)[_filterSelectionBar viewWithTag:i];
        frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
    }
//    for (int i = 1; i <= 20; i++) {
//        UIButton *frameButton = (UIButton *)[_secondEffectsSlider viewWithTag:i];
//        frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
//    }
//    clickedBtnTag = clickedBtn.tag;
    clickedBtn.layer.borderColor=[[UIColor blackColor] CGColor];
//    blendBtnClicked=NO;
//    effectsBtnClicked=YES;
    for (UIScrollView *blockSlider in droppableAreas){
        if (blockSlider.tag == tapBlockNumber){
            if (blockSlider.subviews.count==0) return;
            UIImageView *imageView = blockSlider.subviews[0];
//            for (int i=0;i<[self.originalImages count];i++){
//                if ( (i == imageView.tag) && imageView.image ){
                    UIImage *inputImage = self.selectedImage;
                    switch (clickedBtn.tag) {
                        case 1:{
                            filter = [[GPUImageFilter alloc] init]; //original
//                            videoFilter = [[GPUImageFilter alloc] init]; //original
                        } break;
                        case 2: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_amatorka.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_amatorka.png"];
                        } break;
                        case 3: {
                            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
//                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
                        } break;
                        case 10: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
                        } break;
                        case 11: {
                            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
//                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
                        } break;
                        case 4:{
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
                        } break;
                        case 5: {
                            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
//                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
                        } break;
                        case 6: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
                        } break;
                        case 7: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
                        } break;
                        case 8: {
                            filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
//                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
                        } break;
                        case 9: {
                            filter = [[GPUImageGrayscaleFilter alloc] init];
//                            videoFilter = [[GPUImageGrayscaleFilter alloc] init];
                        } break;
                    }
                    UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                    imageView.image=quickFilteredImage;
                    [filter removeAllTargets];
            
                }
            }
//        }
//    }
}
- (void)secondEffectsClicked:(UIButton *)clickedBtn {

//    [Flurry logEvent:@"Frame - Second Effects"];
    
    if (![defaults boolForKey:kFeature1]){
        [self filterAction];
        return;
    }
    NSLog(@"block number %d",tapBlockNumber);
    for (int i = 1; i <= 20+11; i++) {
        UIButton *frameButton = (UIButton *)[_filterSelectionBar viewWithTag:i];
        frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
    }
//    for (int i = 1; i <= 11; i++) {
//        UIButton *frameButton = (UIButton *)[_filterSelectionBar viewWithTag:i];
//        frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
//    }
//    NSInteger clickedBtnTag= 11+clickedBtn.tag;
//    blendBtnClicked=NO;
//    effectsBtnClicked=YES;
    clickedBtn.layer.borderColor=[[UIColor blackColor] CGColor];
    for (UIScrollView *blockSlider in droppableAreas){
        if (blockSlider.tag == tapBlockNumber){
            if (blockSlider.subviews.count==0) return;
            UIImageView *imageView = blockSlider.subviews[0];
//            for (int i=0;i<[self.originalImages count];i++){
//                if ( (i == imageView.tag) && imageView.image ){
                    UIImage *inputImage = self.selectedImage;
                    switch (clickedBtn.tag-11) {
                        case 1:{
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
                            
                        } break;
                        case 2: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarmBleach.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarmBleach.png"];
                            
                        } break;
                        case 3: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWinter.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWinter.png"];
                            
                        } break;
                        case 9: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWarm.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWarm.png"];
                            
                        } break;
                        case 10: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"candlelight.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"candlelight.png"];
                            
                        } break;
                        case 11:{
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fallcolors.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fallcolors.png"];
                            
                        } break;
                        case 12: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"filmstock.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"filmstock.png"];
                            
                        } break;
                            
                        case 13: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"foggynight.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"foggynight.png"];
                            
                        } break;
                        case 14: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cobalt2Iron80Bleach.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cobalt2Iron80Bleach.png"];
                            
                        } break;
                        case 15: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"blue.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"blue.png"];
                            
                        } break;
                        case 16: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fuji2393.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fuji2393.png"];
                            
                        } break;
                        case 17: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleak.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleak.png"];
                            
                        } break;
                        case 18: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachMoonlight.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachMoonlight.png"];
                            
                        } break;
                        case 19: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cyanSeleniumBleachMoonlight.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cyanSeleniumBleachMoonlight.png"];
                            
                        } break;
                        case 20: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarm.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarm.png"];
                            
                        } break;
                        case 4: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"gold2.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"gold2.png"];
                            
                        } break;
                        case 5: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"platinum.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"platinum.png"];
                            
                        } break;
                        case 6: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"copperSepia2strip.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"copperSepia2strip.png"];
                            
                        } break;
                        case 7: {
                            filter = [[GPUImageVignetteFilter alloc] init];
                            [(GPUImageVignetteFilter *) filter setVignetteEnd:0.6];
//                            videoFilter = [[GPUImageVignetteFilter alloc] init];
//                            [(GPUImageVignetteFilter *) videoFilter setVignetteEnd:0.6];
                        } break;
                        case 8: {
                            filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"maximumWhite.png"];
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"maximumWhite.png"];
                            
                        } break;
                            
                        default:
                            break;
                    }
                    UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                    [filter removeAllTargets];
                    imageView.image=quickFilteredImage;
//                    filterVideo=nil;
//                    app=_videoArray[imageView.tag];
//                    if ([app.appURLString isEqualToString:@"video"]){
//                        switch (tapBlockNumber) {
//                            case 0:
//                                if(trimmedVideo1)
//                                    filterVideo=trimmedVideo1;
//                                break;
//                            case 1:
//                                if(trimmedVideo2)
//                                    filterVideo=trimmedVideo2;
//                                break;
//                            case 2:
//                                if(trimmedVideo3)
//                                    filterVideo=trimmedVideo3;
//                                break;
//                            case 3:
//                                if(trimmedVideo4)
//                                    filterVideo=trimmedVideo4;
//                                break;
//                        }
//                        if (!filterVideo)
//                            filterVideo = app.appURL;
//                        [self.frameContainerSlider addSubview:labelToApplyFilterToVideo];
//                    }
            
                    
                    //                                        if (app.appURL){
                    //                                            filterVideo = app.appURL;
                    ////                                            [self.bottomView addSubview:labelToApplyFilterToVideo];
                    //
                    //                                            labelToApplyFilterToVideo.hidden=NO;
                    //                                            [self.bottomView bringSubviewToFront:labelToApplyFilterToVideo];
                    
                    //                                        }
                    //                                        if (!brightenState) {
                    //                                            blurFilter = [[GPUImageBrightnessFilter alloc] init];
                    //                                            [(GPUImageBrightnessFilter *) blurFilter setBrightness:0.15];
                    //                                            quickFilteredImage = [blurFilter imageByFilteringImage:quickFilteredImage];
                    //                                            [blurFilter removeAllTargets];
                    //                                        }
                    //                                        if (clickedBtn.tag==1)
                    //                                            quickFilteredImage = [self.originalImages objectAtIndex:i];
                    
                    //                                        imageView.image=quickFilteredImage;
                    //                                    }
                }
//            }
//        }
    }
}
//- (void) originalClicked {
//    blendOrignalClicked=YES;
//    for (UIScrollView *blockSlider in self.droppableAreas){
//        if (blockSlider.tag == tapBlockNumber){
//            //        if ((blockSlider.tag == 4*currentPage) || (blockSlider.tag == 4*currentPage+1) || (blockSlider.tag == 4*currentPage+2) || (blockSlider.tag == 4*currentPage+3)) {
//            for (UIImageView *imageView in blockSlider.subviews){
//                for (int i=0;i<[self.originalImages count];i++){
//                    if ( (i == imageView.tag) && imageView.image ){
//                        UIImage *inputImage = [self.originalImages objectAtIndex:i];
//                        filter = [[GPUImageFilter alloc] init]; //original
//                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                        [filter removeAllTargets];
//                        imageView.image=quickFilteredImage;
//                    }
//                }
//            }
//        }
//    }
//}
#pragma mark Autoload
- (void) hideLabels {
    _rotateBtn.hidden=NO;
    _frameBtn.hidden=NO;
    _filtersBtn.hidden=NO;
    
}
- (void) hideBars {
    _filterSelectionBar.hidden=YES;
    _frameSelectionBar.hidden=YES;
    _rotateMenuView.hidden=YES;
    _splitMenuView.hidden=YES;
}
- (IBAction)rotateButton:(id)sender {
    [Flurry logEvent:@"rotate"];

    [self hideBars];
    _rotateMenuView.hidden=NO;
}
- (IBAction)filtersButton:(id)sender {
    [Flurry logEvent:@"filters"];
    [self hideBars];
    _filterSelectionBar.hidden=NO;
}
- (IBAction)framesButton:(id)sender {
    [Flurry logEvent:@"frames"];
    [self hideBars];
    _frameSelectionBar.hidden=NO;
}
- (IBAction)splitButton:(id)sender {
    [Flurry logEvent:@"split"];
    [self hideBars];
    _splitMenuView.hidden=NO;
}

- (void) selectFrame:(int)style SUB:(int)sub
{
    
    
    if (!firstTime){
        
//        frameContainerArray = [[NSMutableArray alloc]init];
//        canvasArray = [[NSMutableArray alloc] init];
        droppableAreas = [[NSMutableArray alloc] init];
//        replacableImages = [[NSMutableArray alloc] init];
//        frameDimensionArray = [[NSMutableArray alloc] init];
//        _labelArray= [[NSMutableArray alloc] init];
//        _stickerArray= [[NSMutableArray alloc] init];
//        _doodleArray= [[NSMutableArray alloc] init];
        //        _labelViewArray=[[NSMutableArray alloc] init];
        
//        self.frameSelectionBar = (UIScrollView *)[self.view viewWithTag:10130];
//        self.frameSelectionBar.delegate = self;
//        self.frameSelectionBar.userInteractionEnabled=YES;
//        self.frameSelectionBar.canCancelContentTouches=NO;
        //        self.frameSlider.scrollEnabled = YES;
        ////        self.scrollIcon.alpha=0.5;
        ////        scrollON=NO;
//        self.frameSelectionBar.scrollEnabled=NO;
//        frameCount= [self.originalImages count]/style;
//        if ([originalImages count]%style != 0) frameCount++;
//        
//        if (frameCount >= kFrameMax) {
//            frameCount=kFrameMax;  //maximum frameCount=kFrameMax
//            self.frameSlider.contentSize = CGSizeMake(320 * frameCount, 320);//SB v1.0i
//        }
        
        firstTime = YES;
        nStyle= 4;
        nSubStyle = 1;
//        cornerState=0;
//        panState=0;
//        borderState=0;
        //        self.pan.alpha=0.8;
        
//        for (int i = 0; i < frameCount; i++)
//        {
//            NSLog(@"frameCount = %i",i);
        
//            self.frameContainer = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 310, 310)];
//            self.frameContainer.tag = i;
//            self.frameContainer.backgroundColor = [UIColor clearColor];
//            if (self.frameContainer.tag == i) {
//                [self.frameSlider addSubview:self.frameContainer];
//                [self.frameContainerArray addObject:self.frameContainer];
//            }
        
//            canvas = [[UIImageView alloc] initWithFrame:CGRectMake (0, 0, 310, 350)];
//            canvas.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0f];
////            canvas.tag = i;
//            [canvas setContentMode:UIViewContentModeScaleToFill];
        
//            [self.canvasArray addObject:canvas];
//            if ((self.frameContainer.tag == i) && (canvas.tag == i))
//                [self.frameContainer addSubview:canvas];
        
            rectBlockSlider1 = [self getScrollFrame1:style subStyle:sub];
            rectBlockSlider2 = [self getScrollFrame2:style subStyle:sub];
            rectBlockSlider3 = [self getScrollFrame3:style subStyle:sub];
            rectBlockSlider4 = [self getScrollFrame4:style subStyle:sub];
            
            blockSlider1 = [[UIScrollView alloc] initWithFrame:rectBlockSlider1];
            blockSlider2 = [[UIScrollView alloc] initWithFrame:rectBlockSlider2];
            blockSlider3 = [[UIScrollView alloc] initWithFrame:rectBlockSlider3];
            blockSlider4 = [[UIScrollView alloc] initWithFrame:rectBlockSlider4];
            
            blockSlider1.scrollEnabled=NO;
            blockSlider2.scrollEnabled=NO;
            blockSlider3.scrollEnabled=NO;
            blockSlider4.scrollEnabled=NO;
            
//            blockSlider1.backgroundColor = [UIColor clearColor];
//            blockSlider2.backgroundColor = [UIColor clearColor];
//            blockSlider3.backgroundColor = [UIColor clearColor];
//            blockSlider4.backgroundColor = [UIColor clearColor];
        
            blockSlider1.tag = 0;
            blockSlider2.tag = 1;
            blockSlider3.tag = 2;
            blockSlider4.tag = 3;
            
            [blockSlider1.layer setBorderColor:[[UIColor clearColor] CGColor]];
            //            [blockSlider1.layer setCornerRadius:kCornerRadius];
            [blockSlider1.layer setBorderWidth:kBlockWidth];
            
            [blockSlider2.layer setBorderColor:[[UIColor clearColor] CGColor]];
            //            [blockSlider2.layer setCornerRadius:kCornerRadius];
            [blockSlider2.layer setBorderWidth:kBlockWidth];
            
            [blockSlider3.layer setBorderColor:[[UIColor clearColor] CGColor]];
            //            [blockSlider3.layer setCornerRadius:kCornerRadius];
            [blockSlider3.layer setBorderWidth:kBlockWidth];
            
            [blockSlider4.layer setBorderColor:[[UIColor clearColor] CGColor]];
            //            [blockSlider4.layer setCornerRadius:kCornerRadius];
            [blockSlider4.layer setBorderWidth:kBlockWidth];
            
            
//            if ((blockSlider1.tag == 0) || (blockSlider2.tag == 1) || (blockSlider3.tag == 2) || (blockSlider4.tag == 3)) {

//            }
        
            
            //            UITapGestureRecognizer *tapBlock1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBlockEffects:)];
            //            tapBlock1.numberOfTapsRequired = 1;
            //            [tapBlock1 setDelegate:self];
            //            [blockSlider1 addGestureRecognizer:tapBlock1];
            
//            UILongPressGestureRecognizer * longPressGestureRecognizer1 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(draggingLongPress:)];
//            [blockSlider1 addGestureRecognizer:longPressGestureRecognizer1];
//            longPressGestureRecognizer1.minimumPressDuration=1.0;
        
            
            //            UITapGestureRecognizer *tapBlock2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBlockEffects:)];
            //            tapBlock2.numberOfTapsRequired = 1;
            //            [tapBlock2 setDelegate:self];
            //            [blockSlider2 addGestureRecognizer:tapBlock2];
//            UILongPressGestureRecognizer * longPressGestureRecognizer2 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(draggingLongPress:)];
//            [blockSlider2 addGestureRecognizer:longPressGestureRecognizer2];
//            longPressGestureRecognizer2.minimumPressDuration=1.0;
        
            
            //            UITapGestureRecognizer *tapBlock3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBlockEffects:)];
            //            tapBlock3.numberOfTapsRequired = 1;
            //            [tapBlock3 setDelegate:self];
            //            [blockSlider3 addGestureRecognizer:tapBlock3];
//            UILongPressGestureRecognizer * longPressGestureRecognizer3 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(draggingLongPress:)];
//            [blockSlider3 addGestureRecognizer:longPressGestureRecognizer3];
//            longPressGestureRecognizer3.minimumPressDuration=1.0;
        
            
            //            UITapGestureRecognizer *tapBlock4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBlockEffects:)];
            //            tapBlock4.numberOfTapsRequired = 1;
            //            [tapBlock4 setDelegate:self];
            //            [blockSlider4 addGestureRecognizer:tapBlock4];
//            UILongPressGestureRecognizer * longPressGestureRecognizer4 = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(draggingLongPress:)];
//            [blockSlider4 addGestureRecognizer:longPressGestureRecognizer4];
//            longPressGestureRecognizer4.minimumPressDuration=1.0;
//            
//            
//            cornerState=0;
//            panState=0;
//            borderState=0;
//            vignetteState=1;
//            brightenState=0;
//            stickerState=1;
//            textState=1;
        
//            NSMutableDictionary *frameDimensionDictionary = [[NSMutableDictionary alloc ]  init];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:nStyle] forKey:@"style"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:nSubStyle] forKey:@"sub"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:nMargin] forKey:@"nMargin"];
//            
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:borderState] forKey:@"borderState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:vignetteState] forKey:@"vignetteState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:brightenState] forKey:@"brightenState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:cornerState] forKey:@"cornerState"];
//            
//            [self.frameDimensionArray addObject:frameDimensionDictionary];
        
//            if (nStyle == 1){
//                image1 = [[UIImageView alloc] initWithImage:self.selectedImage];
////                self.image1.userInteractionEnabled = YES;
//                image1.tag =0;
//                
//                if ((blockSlider1.tag == 0) && (image1.tag == 0)) {
//                    [blockSlider1 addSubview:image1];
//                    [self fitImageToScroll:image1 SCROLL:blockSlider1 scrollViewNumber:blockSlider1.tag angle:0.0 ];
//                }
//            }
//            else if (nStyle == 2 ){
//                image1 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                image1.tag =0;
////                self.image1.userInteractionEnabled = YES;
//                if ((blockSlider1.tag == 0) && (image1.tag == 0)) {
//                    [blockSlider1 addSubview:image1];
//                    [self fitImageToScroll:image1 SCROLL:blockSlider1 scrollViewNumber:blockSlider1.tag angle:0.0 ];
//                }
////                if (i*2+1 <[self.originalImages count]){
//                    image2 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                    image2.tag =1;
////                    image2.userInteractionEnabled = YES;
//                    if ((blockSlider2.tag == 1) && (image2.tag == 1)) {
//                        [blockSlider2 addSubview:image2];
//                        [self fitImageToScroll:image2 SCROLL:blockSlider2 scrollViewNumber:blockSlider2.tag angle:0.0 ];
//                    }
////                }
//            }
//            else if (nStyle == 3 ){
//                image1 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                image1.tag =0;
////                self.image1.userInteractionEnabled = YES;
//                if ((blockSlider1.tag == 0) && (image1.tag == 0)) {
//                    [blockSlider1 addSubview:image1];
//                    [self fitImageToScroll:image1 SCROLL:blockSlider1 scrollViewNumber:blockSlider1.tag angle:0.0 ];
//                }
////                if (i*3+1 <[self.originalImages count]) {
//                    image2 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                    image2.tag =1;
////                    self.image2.userInteractionEnabled = YES;
//                    if ((blockSlider2.tag == 1) && (image2.tag == 1)) {
//                        [blockSlider2 addSubview:image2];
//                        [self fitImageToScroll:image2 SCROLL:blockSlider2 scrollViewNumber:blockSlider2.tag angle:0.0 ];
//                    }
////                }
////                if (i*3+2 <[self.originalImages count]) {
//                    image3 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                    image3.tag =2;
////                    self.image3.userInteractionEnabled = YES;
//                    if ((blockSlider3.tag == 2) && (image3.tag == 2)) {
//                        [blockSlider3 addSubview:image3];
//                        [self fitImageToScroll:image3 SCROLL:blockSlider3 scrollViewNumber:blockSlider3.tag angle:0.0 ];
//                    }
//                    
////                }
//            }
//            else if (nStyle == 4 ){
//                image1 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                image1.tag =0;
////                self.image1.userInteractionEnabled = YES;
//                if ((blockSlider1.tag == 0) && (image1.tag == 0)) {
//                    [blockSlider1 addSubview:image1];
//                    [self fitImageToScroll:image1 SCROLL:blockSlider1 scrollViewNumber:blockSlider1.tag angle:0.0 ];
//                }
////                if (i*4+1 <[self.originalImages count]){
//                    image2 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                    image2.tag =1;
////                    self.image2.userInteractionEnabled = YES;
//                    if ((blockSlider2.tag == 1) && (image2.tag == 1)) {
//                        [blockSlider2 addSubview:image2];
//                        [self fitImageToScroll:image2 SCROLL:blockSlider2 scrollViewNumber:blockSlider2.tag angle:0.0 ];
//                    }
////                }
////                if (i*4+2 <[self.originalImages count]){
//                    
//                    image3 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                    image3.tag =2;
////                    self.image3.userInteractionEnabled = YES;
//                    if ((blockSlider3.tag == 2) && (image3.tag == 2)) {
//                        [blockSlider3 addSubview:image3];
//                        [self fitImageToScroll:image3 SCROLL:blockSlider3 scrollViewNumber:blockSlider3.tag angle:0.0 ];
//                    }
////                }
////                if (i*4+3 <[self.originalImages count]){
//                    
//                    image4 = [[UIImageView alloc] initWithImage:self.selectedImage];
//                    image4.tag =3;
////                    self.image4.userInteractionEnabled = YES;
//                    if ((blockSlider4.tag == 3) && (image4.tag == 3)) {
//                        [blockSlider4 addSubview:image4];
//                        [self fitImageToScroll:image4 SCROLL:blockSlider4 scrollViewNumber:blockSlider4.tag angle:0.0 ];
//                    }
////                }
//            }
//            NSLog(@"original Image 2 %@", self.originalImages);
        
        image1 = [[UIImageView alloc] initWithImage:self.selectedImage];
        image1.tag =0;
        [blockSlider1 addSubview:image1];
        [self fitImageToScroll:image1 SCROLL:blockSlider1 scrollViewNumber:blockSlider1.tag angle:0.0 ];
        image2 = [[UIImageView alloc] initWithImage:self.selectedImage];
        image2.tag =1;
        [blockSlider2 addSubview:image2];
        [self fitImageToScroll:image2 SCROLL:blockSlider2 scrollViewNumber:blockSlider2.tag angle:0.0 ];
        image3 = [[UIImageView alloc] initWithImage:self.selectedImage];
        image3.tag =2;
        [blockSlider3 addSubview:image3];
        [self fitImageToScroll:image3 SCROLL:blockSlider3 scrollViewNumber:blockSlider3.tag angle:0.0 ];
        image4 = [[UIImageView alloc] initWithImage:self.selectedImage];
        image4.tag =3;
        [blockSlider4 addSubview:image4];
        [self fitImageToScroll:image4 SCROLL:blockSlider4 scrollViewNumber:blockSlider4.tag angle:0.0 ];
        [self.frameContainer addSubview:blockSlider1];
        [self.frameContainer addSubview:blockSlider2];
        [self.frameContainer addSubview:blockSlider3];
        [self.frameContainer addSubview:blockSlider4];
//            if (blockSlider1.tag==0){
                [droppableAreas addObject:blockSlider1];
////                [self.replacableImages addObject:self.blockSlider1];
//            }
//            if (blockSlider2.tag == 1){
                [droppableAreas addObject:blockSlider2];
//                [self.replacableImages addObject:self.blockSlider2];
                
//            }
//            if (blockSlider3.tag ==2){
                [droppableAreas addObject:blockSlider3];
//                [self.replacableImages addObject:self.blockSlider3];
                
//            }
//            if (blockSlider4.tag == 3){
                [droppableAreas addObject:blockSlider4];
//                [self.replacableImages addObject:self.blockSlider4];
//                
//            }
        
            //            CGRect bounds = self.frameContainer.bounds;
            //            self.blockSlider1.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
            //            self.blockSlider1.clipsToBounds=YES;
            //            blockSlider1Offset = CGPointMake(0.0, 0.0);
            //            blockSlider1Rotation = 0.0;
            //            CGRect bounds = self.blockSlider1.bounds;
            //            self.image1.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
            //            self.image1.bounds = (CGRect){ CGPointZero, self.image1.image.size };
            //            UIPanGestureRecognizer *panBlock = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panBlock:)];
            //            [panBlock setDelegate:self];
            //            [self.blockSlider1 addGestureRecognizer:panBlock];
            //            UIRotationGestureRecognizer *rotateBlock = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateBlock:)];
            //            [rotateBlock setDelegate:self];
            //            [self.blockSlider1 addGestureRecognizer:rotateBlock];
            //            UIPinchGestureRecognizer *pinchBlock = [[UIPinchGestureRecognizer alloc]
            //                                                      initWithTarget:self action:@selector(pinchBlock:)];
            //            pinchBlock.delegate=self;
            ////            [self.blockSlider1 addGestureRecognizer:pinchBlock];
            //            [self transformView:self.blockSlider1 :self.image1 :CGPointZero :1 :1];
//        }
        
        UITapGestureRecognizer *tapBlock = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBlock:)];
        tapBlock.numberOfTapsRequired = 1;
        [tapBlock setDelegate:self];
        [self.frameContainer addGestureRecognizer:tapBlock];
        
        //        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(eraseImage:)];
        //        tap1.numberOfTapsRequired = 2;
        //        [tap1 setDelegate:self];
        //        [self.frameContainer addGestureRecognizer:tap1];
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchImage:)];
        pinchGesture.delegate=self;
        [self.frameContainer addGestureRecognizer:pinchGesture];
        
//        UIRotationGestureRecognizer *rotationGesture= [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateImage:)];
//        rotationGesture.delegate=self;
//        [self.frameContainer addGestureRecognizer:rotationGesture];
    
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanImage:)];
        panGesture.delegate=self;
        [self.frameContainer addGestureRecognizer:panGesture];
        [self.frameContainer bringSubviewToFront:_watermarkOnImage];
//        self.frameContainer.hidden=YES;
//        if (frameCount < kFrameMax) {
//            self.tapToAddAFrame.frame = CGRectMake(320*(frameCount)+5, 5, 310, 350);
//            self.tapToAddAFrame.hidden = NO;
//            self.frameSlider.contentSize = CGSizeMake(320 * (frameCount+1), 320);//SB
//            cornerState=0;
//            panState=0;
//            borderState=0;
//            vignetteState=1;
//            brightenState=0;
//            stickerState=1;
//            textState=1;
//            
//            NSMutableDictionary *frameDimensionDictionary = [[NSMutableDictionary alloc ]  init];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:nStyle] forKey:@"style"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:nSubStyle] forKey:@"sub"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:nMargin] forKey:@"nMargin"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:cornerState] forKey:@"cornerState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:panState] forKey:@"panState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:borderState] forKey:@"borderState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:vignetteState] forKey:@"vignetteState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:brightenState] forKey:@"brightenState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:vignetteState] forKey:@"stickerState"];
//            [frameDimensionDictionary setValue:[NSNumber numberWithInteger:brightenState] forKey:@"textState"];
//            [frameDimensionArray addObject:frameDimensionDictionary];
//        }
    
//        NSLog(@"done selection");
        //        for (currentPage=0;currentPage<=frameCount;currentPage++){
        //            for (UIScrollView *blockSlider in self.droppableAreas){
        //                if (blockSlider.tag == currentPage*4) {
        //                    for (UIImageView *imageView in blockSlider.subviews){
        //                        NSMutableDictionary *dict =[self.arrImages objectAtIndex:(imageView.tag)];
        //                        NSLog(@"dict selectFrame:SUB is %@",dict);
        //                    }
        //                }
        //            }
        //        }
        
//        _dragDropManager = [[DragDropManager alloc] initWithDragSubjects:draggableSubjects andDropAreas:droppableAreas andOriginalImages:originalImages andReplaceImages:replacableImages];
//        UILongPressGestureRecognizer * longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:_dragDropManager action:@selector(dragging:)];
//        longPressGestureRecognizer.minimumPressDuration=0.1;
        //         UILongPressGestureRecognizer * longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(draggingLongPress:)];
        //        panGestureRecognizer.minimumNumberOfTouches=1;
//        [self.dragRegion addGestureRecognizer:longPressGestureRecognizer];
        //        [self.view bringSubviewToFront:self.dragRegionFrames];
        //        [self.dragRegionFrames addGestureRecognizer:longPressGestureRecognizer];
        //        [self.blockSlider2 addGestureRecognizer:panGestureRecognizer];
        //        [self.blockSlider3 addGestureRecognizer:panGestureRecognizer];
        //        [self.blockSlider4 addGestureRecognizer:panGestureRecognizer];
//        currentPage=0;
//        lastPage=0;
        //        [self loadOriginalVideos];
        //        editedVideo1 = originalVideo1;
        //        editedVideo2 = originalVideo2;
        //        editedVideo3 = originalVideo3;
        //        editedVideo4 = originalVideo4;
        //        unrotatedVideo1 = originalVideo1;
        //        unrotatedVideo2 = originalVideo2;
        //        unrotatedVideo3 = originalVideo3;
        //        unrotatedVideo4 = originalVideo4;
//        [self performSelector:@selector(loadOriginalVideos) withObject:nil afterDelay:0.1];
    
        //        [self reloadAssets];
//        [self helpAction:self];
        //        [self performSelector:@selector(resetFrames) withObject:nil afterDelay:0.2];
        //        [self resetFrames];
        //        for (UIGestureRecognizer *gestureRecognizer in self.view.gestureRecognizers)
        //            if ([gestureRecognizer isKindOfClass:UIPinchGestureRecognizer.class] || [gestureRecognizer isKindOfClass:UIRotationGestureRecognizer.class])
        //                gestureRecognizer.enabled=NO;
    }
    else {
//        self.frameContainer.hidden=NO;
//        [self hideLabels];

//        if  (currentPage == frameContainerArray.count) return;
        
        //        NSString *string1 = [NSString stringWithFormat:@"%d",style];
        //        NSString *string2 = [NSString stringWithFormat:@"%d",sub];
        //        NSDictionary *flurryParams = [NSDictionary dictionaryWithObjectsAndKeys:string1, @"style", string2,@"sub", nil];
        //        NSString *string1and2 = [NSString stringWithFormat:@"Select Frame style = %d substyle = %d",style,sub];
        //        [Flurry logEvent:string1and2 withParameters:flurryParams];
        
        nStyle = style;
        nSubStyle = sub;
//        [[frameDimensionArray objectAtIndex:currentPage] setValue:[NSNumber numberWithInteger:nStyle] forKey:@"style"];
//        [[frameDimensionArray objectAtIndex:currentPage] setValue:[NSNumber numberWithInteger:nSubStyle] forKey:@"sub"];
//        NSLog(@"selectFrame:SUB: frameDimensionArray is %@",frameDimensionArray);
        
        for (UIScrollView *blockSlider in droppableAreas){
//            NSLog(@ "currentPage is %d blockSlider.tag is %d",currentPage, blockSlider.tag);
            if (blockSlider.tag == 0) {
                rectBlockSlider1 = [self getScrollFrame1:nStyle subStyle:nSubStyle];
                blockSlider.frame = rectBlockSlider1;
                //                int j=0;
                
                //                for (UIImageView *imageView in blockSlider.subviews){
                //                    NSLog(@"blockslider subview # is %d",j);
                ////                    [imageView removeFromSuperview];
                //                    NSLog(@"bloackSlider 1 imageview is %@, and imageView.image is %@ imageView.class is %@",imageView, imageView.image, imageView.class);
                ////                    if ([imageView isKindOfClass:[UIImageView class]] && imageView.image){
                //                        UIImageView *replaceImage = [[UIImageView alloc] initWithImage:imageView.image];
                //                        replaceImage.userInteractionEnabled = YES;
                //                        replaceImage.tag=imageView.tag;
                //                        [blockSlider addSubview:replaceImage];
                //                    if(imageView.image!=nil  && imageView!=nil){
                //                        NSLog(@"imageView is %@",imageView);
                //                UIImageView *imageView = [blockSlider.subviews firstObject];
                //                for (UIView *view in blockSlider.subviews)  {
                //                    [view removeFromSuperview];
                //                }
                //                UIImageView *replaceImage = [[UIImageView alloc] initWithImage:[self.originalImages objectAtIndex:imageView.tag]];
                //                replaceImage.tag = imageView.tag;
                //                replaceImage.userInteractionEnabled = YES;
                //                [blockSlider addSubview:replaceImage];
                //                [self fitImageToScroll:replaceImage SCROLL:blockSlider scrollViewNumber:blockSlider.tag];
                
                //                         [blockSlider setContentMode:UIViewContentModeRedraw];
                //                    }
                //                    }
                //                    for (UIGestureRecognizer *gestureRecognizer in imageView.gestureRecognizers)
                //                        gestureRecognizer.enabled = NO;
                
                //                    j++;
                //                }
            }
            else if (blockSlider.tag == 1) {
                rectBlockSlider2 = [self getScrollFrame2:nStyle subStyle:nSubStyle];
                blockSlider.frame = rectBlockSlider2;
                
                //                int j=0;
                //                for (UIImageView *imageView in blockSlider.subviews){
                //                    [imageView removeFromSuperview];
                //                    NSLog(@"bloackSlider 2 imageview is %@",imageView);
                //                    if ([imageView isKindOfClass:[UIImageView class]] && imageView.image){
                //                        UIImageView *replaceImage = [[UIImageView alloc] initWithImage:imageView.image];
                //                        replaceImage.userInteractionEnabled = YES;
                //                        replaceImage.tag=imageView.tag;
                //                        [blockSlider addSubview:replaceImage];
                //                         [blockSlider setContentMode:UIViewContentModeRedraw];
                //                        [self fitImageToScroll:replaceImage SCROLL:blockSlider scrollViewNumber:blockSlider.tag];
                //                    }
                ////                    for (UIGestureRecognizer *gestureRecognizer in imageView.gestureRecognizers)
                ////                        gestureRecognizer.enabled = NO;
                //                    j++;
                //                }
            }
            else if (blockSlider.tag == 2) {
                rectBlockSlider3 = [self getScrollFrame3:nStyle subStyle:nSubStyle];
                blockSlider.frame = rectBlockSlider3;
                //                int j=0;
                //                for (UIImageView *imageView in blockSlider.subviews){
                //                    NSLog(@"blockslider subview # is %d",j);
                //                    [imageView removeFromSuperview];
                //                    NSLog(@"bloackSlider 3 imageview is %@",imageView);
                //                    if ([imageView isKindOfClass:[UIImageView class]] && imageView.image){
                //                        UIImageView *replaceImage = [[UIImageView alloc] initWithImage:imageView.image];
                //                        replaceImage.userInteractionEnabled = YES;
                //                        replaceImage.tag=imageView.tag;
                //                        [blockSlider addSubview:replaceImage];
                //                         [blockSlider setContentMode:UIViewContentModeRedraw];
                //                        [self fitImageToScroll:replaceImage SCROLL:blockSlider scrollViewNumber:blockSlider.tag];
                //                    }
                ////                    for (UIGestureRecognizer *gestureRecognizer in imageView.gestureRecognizers)
                ////                        gestureRecognizer.enabled = NO;
                //                    j++;
                //                }
            }
            else if (blockSlider.tag == 3) {
                rectBlockSlider4 = [self getScrollFrame4:nStyle subStyle:nSubStyle];
                blockSlider.frame = rectBlockSlider4;
                //                for (UIImageView *imageView in blockSlider.subviews){
                //                    [imageView removeFromSuperview];
                //                    NSLog(@"bloackSlider 4 imageview is %@",imageView);
                //                    if ([imageView isKindOfClass:[UIImageView class]] && imageView.image){
                //                        UIImageView *replaceImage = [[UIImageView alloc] initWithImage:imageView.image];
                //                        replaceImage.userInteractionEnabled = YES;
                //                        replaceImage.tag=imageView.tag;
                //                        [blockSlider addSubview:replaceImage];
                //                         [blockSlider setContentMode:UIViewContentModeRedraw];
                //                        [self fitImageToScroll:replaceImage SCROLL:blockSlider scrollViewNumber:blockSlider.tag];
                //                    }
                //                    for (UIGestureRecognizer *gestureRecognizer in imageView.gestureRecognizers)
                //                        gestureRecognizer.enabled = NO;
                //                }
            }
            UIImageView *imageView = [blockSlider.subviews firstObject];
            for (UIView *view in blockSlider.subviews)  {
                [view removeFromSuperview];
            }
//            NSString *tagRotate = [NSString stringWithFormat:@"Rotate%d",blockSlider.tag];
            UIImageView *replaceImage = [[UIImageView alloc] initWithImage:imageView.image];
            replaceImage.tag = imageView.tag;
            replaceImage.userInteractionEnabled = YES;
            [blockSlider addSubview:replaceImage];
            [self fitImageToScroll:replaceImage SCROLL:blockSlider scrollViewNumber:blockSlider.tag  angle:[defaults floatForKey:@"Rotate"] ];
        }
        for (UIScrollView *blockSlider in droppableAreas)
            for (UIImageView *imageView in blockSlider.subviews){
                imageView.center = CGPointMake(imageView.center.x + [defaults floatForKey:@"PanX"],
                                               imageView.center.y + [defaults floatForKey:@"PanY"]);
            }

        [self.frameContainer bringSubviewToFront:_watermarkOnImage];

    }
}
//- (IBAction)handleRotateImage:(UIRotationGestureRecognizer *)recognizer {
//    for (UIScrollView *blockSlider in droppableAreas){
//        if (blockSlider.tag == tapBlockNumber){
//            if (blockSlider.subviews.count==0) return;
//            UIImageView *imageView = blockSlider.subviews[0];
//            imageView.transform = CGAffineTransformRotate(imageView.transform, recognizer.rotation);
//        }
//    }
//    NSString *tagRotate = [NSString stringWithFormat:@"Rotate%d",tapBlockNumber];
//    CGFloat rotateVideo=[defaults floatForKey:tagRotate]+ recognizer.rotation;
//    rotateVideo = fmodf(rotateVideo, 2*M_PI);
//    
//    [defaults setFloat:rotateVideo forKey:tagRotate];
//    NSLog(@"rotateVideo is %f and tag is %d, and tagRotate is %@, recognizer.rotation is %f",rotateVideo, tapBlockNumber,tagRotate,recognizer.rotation);
//    sliderRotate.value=rotateVideo;
//    recognizer.rotation = 0;
//    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(sliderRotate.value)];
//    
//}

- (IBAction)handlePinchImage:(UIPinchGestureRecognizer *)sender {
    if (tapBlockNumber !=100){
        CGFloat factor = [(UIPinchGestureRecognizer *)sender scale];
//        NSString *tagZoom = [NSString stringWithFormat:@"Zoom%d",tapBlockNumber];
        CGFloat factorVideo = [defaults floatForKey:@"Zoom"]*factor;
        if (factorVideo > kZoomMin && factorVideo < kZoomMax){
            for (UIScrollView *blockSlider in droppableAreas){
//                if (blockSlider.tag == tapBlockNumber){  //split
                    if (blockSlider.subviews.count==0) return;
                    UIImageView *imageView = blockSlider.subviews[0];
                    imageView.transform = CGAffineTransformScale(imageView.transform, factor, factor);
//                }
            }
            [defaults setFloat:factorVideo forKey:@"Zoom"];
//            NSLog(@"factor is %f and %f and %@",factorVideo, factor, tagZoom);
            sliderZoom.value = factorVideo;
        }
        sender.scale = 1;
    }
    labelZoom.text = [NSString stringWithFormat:@"%.02f",sliderZoom.value];
    
}

//- (IBAction)handlePanImage:(UIPanGestureRecognizer *)sender {
//    NSString *tagPanX = [NSString stringWithFormat:@"PanX%d",tapBlockNumber];
//    NSString *tagPanY = [NSString stringWithFormat:@"PanY%d",tapBlockNumber];
//    CGPoint pointVideo;
//    pointVideo.x = [[_imageObject objectForKey:tagPanX] floatValue];
//    pointVideo.y = [[_imageObject objectForKey:tagPanX] floatValue];
//    NSLog(@"pointVideo.x is %f and y is %f",pointVideo.x, pointVideo.y);
//    CGFloat width;
//    CGFloat height;
//    for (UIScrollView *blockSlider in self.droppableAreas){
//        if (blockSlider.tag == tapBlockNumber){
//            if (blockSlider.subviews.count==0) return;
//            UIImageView *imageView = blockSlider.subviews[0];
//            width = imageView.frame.size.width;
//            height = imageView.frame.size.height;
//
//            CGPoint translation = [sender translationInView:[imageView superview]];
//            NSLog(@"pt.x is %f and y is %f",translation.x  , translation.y);
//
//                CGFloat ptX = pointVideo.x + translation.x;
//                CGFloat ptY = pointVideo.y + translation.y;
//            if ((ptX < -width/2 || ptX > width/2) || (ptY < -height/2 || ptY > height/2 ))
//                return;
//            imageView.center = CGPointMake(imageView.center.x + translation.x,
//                                           imageView.center.y + translation.y);
//            NSLog(@"pt.x is %f and y is %f",ptX, ptY);
//
//            [_imageObject setObject:[NSNumber numberWithFloat:ptX] forKey:tagPanX];
//            [_imageObject setObject:[NSNumber numberWithFloat:ptY] forKey:tagPanY];
//
//
//            [sender setTranslation:CGPointMake(0, 0) inView:[imageView superview]];
//
////            CGPoint translation = [sender translationInView:self.view];
////            imageView.center = CGPointMake(imageView.center.x + translation.x,
////                                                 imageView.center.y + translation.y);
////            [sender setTranslation:CGPointMake(0, 0) inView:imageView.superview];
//        }
//    }
//}
- (IBAction)handlePanImage:(UIPanGestureRecognizer *)sender {
    //    if (currentStickerTag!=1000  || currentLabelTag != 1000  || currentDoodleTag!=1000) return;
    //
    //      [self tapBlock:(UITapGestureRecognizer *)sender];
//    NSString *tagPanX = [NSString stringWithFormat:@"PanX%d",tapBlockNumber];
//    NSString *tagPanY = [NSString stringWithFormat:@"PanY%d",tapBlockNumber];
    CGPoint pointVideo;
    pointVideo.x = [defaults floatForKey:@"PanX"];
    pointVideo.y = [defaults floatForKey:@"PanY"];
    CGPoint translation = [sender translationInView:self.view];
//    CGFloat width;
//    CGFloat height;
//    width = imageView.frame.size.width;
//    height = imageView.frame.size.height;
    CGFloat ptX = pointVideo.x + translation.x;
    CGFloat ptY = pointVideo.y + translation.y;
    [defaults setFloat:ptX forKey:@"PanX"];
    [defaults setFloat:ptY forKey:@"PanY"];
//    if ((ptX < -imageWidth*0.8 || ptX > imageWidth*.8) || (ptY < -imageHeight*.8 || ptY > imageHeight*.8 ))
//        return;
    //    pointVideo.x = [[_imageObject objectForKey:tagPanX] floatValue];//does not save values
    //    pointVideo.y = [[_imageObject objectForKey:tagPanY] floatValue];

    for (UIScrollView *blockSlider in droppableAreas){
//        if (blockSlider.tag == tapBlockNumber){   //split
        NSLog(@"blockSlider is %@, count is %d",blockSlider,blockSlider.subviews.count);

//        if (blockSlider.subviews.count!=0) {
//            UIImageView *imageView = blockSlider.subviews[0];
        for (UIImageView *imageView in blockSlider.subviews){

            
            
            imageView.center = CGPointMake(imageView.center.x + translation.x,
                                           imageView.center.y + translation.y);
 
            //            [_imageObject setObject:[NSNumber numberWithFloat:ptX] forKey:tagPanX];
            //            [_imageObject setObject:[NSNumber numberWithFloat:ptY] forKey:tagPanX];

        }
//        }
    }
    NSLog(@"panX is %f",ptX);
    NSLog(@"panY is %f",ptY);
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])
        return YES;
    else
        return NO;
}
// this allows you to dispatch touches
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

-(void) tapBlock :(UITapGestureRecognizer *)recognizer{
    for (UIScrollView *blockSlider in droppableAreas) {
        CGPoint tappedBlock = [recognizer locationInView:blockSlider];
        if ([blockSlider pointInside:tappedBlock withEvent:nil]) {
            tapBlockNumber = blockSlider.tag;
        }
    }
//    __block CGPoint tappedBlock;
    [UIView animateWithDuration:2.0
                     animations:^{
                         for (UIScrollView *blockSlider in droppableAreas){
//                             tappedBlock = [recognizer locationInView:blockSlider];
//                             if ([blockSlider pointInside:tappedBlock withEvent:nil]) {
//                                 tapBlockNumber = blockSlider.tag;
////                             }
//
                             if (blockSlider.tag == tapBlockNumber){
                                 CABasicAnimation *color = [CABasicAnimation animationWithKeyPath:@"borderColor"];
                                 // animate from red to blue border ...
                                 color.fromValue = (id)[UIColor clearColor].CGColor;
                                 color.toValue   = (id)[UIColor cyanColor].CGColor;
                                 // ... and change the model value
                                 color.duration = 1;
                                 [blockSlider.layer addAnimation:color forKey:@"AnimateFrame"];
//                                 if (tapBlockNumber >1)
//                                     break;
                             }
                         }
                     }
                     completion:^(BOOL finished){
                         for (UIScrollView *blockSlider in droppableAreas)
                             [blockSlider.layer setBorderColor:[[UIColor clearColor] CGColor]];
                         NSLog(@"completion block");
                     }];
    
}
- (void) fitImageToScroll:(UIImageView*)imgView SCROLL:(UIScrollView*)scrView  scrollViewNumber: (NSInteger)tagNumber angle: (CGFloat) angle
{
    float imageWidthGreater = imgView.frame.size.width > imgView.frame.size.height ? imgView.frame.size.width: imgView.frame.size.height;
    float imageWidthSmaller = imgView.frame.size.width > imgView.frame.size.height ? imgView.frame.size.height: imgView.frame.size.width;
    float rateImageFill;
    float rateImageFit;
        rateImageFill = 310/imageWidthSmaller;
        rateImageFit = 310/imageWidthGreater;
    
    
    float rate;
    if ([defaults boolForKey:@"fill"])
        rate = rateImageFit;
    else
        rate = rateImageFill;
    
//    float rateScr=0, rateImg=0, rateWidth=0, rateHeight=0;
//    if (scrView.frame.size.width > 0 && imgView.frame.size.width >0){
//        rateScr = scrView.frame.size.height / scrView.frame.size.width;
//        rateImg = imgView.frame.size.height / imgView.frame.size.width;
//    }
//    if (imgView.frame.size.width > 0 && imgView.frame.size.height > 0){
//        rateWidth = scrView.frame.size.width / imgView.frame.size.width;
//        rateHeight = scrView.frame.size.height / imgView.frame.size.height;
//    }
    NSLog(@"imgView is width=%f, height=%f, imageWidthSmaller is %f, imageWidthGreater is %f",imgView.frame.size.width, imgView.frame.size.height,imageWidthSmaller,imageWidthGreater);
//    CGFloat rateFit = rateScr < rateImg ? rateWidth : rateHeight;
    NSLog (@"rateFit is %f, rateFill is %f, rate is %f",rateImageFit,rateImageFill,rate);
//    CGSize szImage = CGSizeMake(imgView.frame.size.width*rateFit, imgView.frame.size.height*rateFit);
    //        [imgView setFrame:CGRectMake(scrView.center.x, scrView.center.y, szImage.width, szImage.height)];
//    [imgView setFrame:CGRectMake(0.0, 0.0, szImage.width, szImage.height)]; //split
//    NSLog (@"imageView frame size is %f width %f height",szImage.width,szImage.height);
    if(!isinf(rate)) {
     [imgView setFrame:CGRectMake(0.0,0.0, imgView.frame.size.width*rate, imgView.frame.size.height*rate)];  //split
        NSLog (@"imageView frame size is %f width %f height",imgView.frame.size.width,imgView.frame.size.height);
        imageWidth=imgView.frame.size.width;
        imageHeight=imgView.frame.size.height;
    }
    //        NSLog(@"scrView content .width%f,imgView content .width%f",scrView.frame.size.width,imgView.frame.size.height);
    //        scrView.frame = CGRectMake(imgView.center.x, imgView.center.y, imgView.frame.size.width*1.25, imgView.frame.size.height*1.25);
//    [scrView setContentSize:CGSizeMake(imgView.frame.size.width*1.2, imgView.frame.size.height*1.2)];
    CGPoint pt;
    //        if (scrView.frame.size.width-2 <= scrView.frame.size.height){
    //        if ((imgView.frame.size.width >= imgView.frame.size.height)|| (scrView.frame.size.width <= scrView.frame.size.height)){
    
//    pt.x = (imgView.frame.size.width - scrView.frame.size.width)/2;
    //            pt.y = 0;
    //        }
    //        else {
    //            pt.x = 0;
//    pt.y = (imgView.frame.size.height - scrView.frame.size.height)/2;
    //        }
    
    pt.x =   scrView.frame.origin.x ;//splitagram
    pt.y =   scrView.frame.origin.y;//splitagram
    
    NSLog(@"pt is x=%f and y=%f",pt.x, pt.y);
    [scrView setContentOffset:pt animated:NO];
    
//    NSString *tagPtX = [NSString stringWithFormat:@"PtX%d",tagNumber];
//    NSString *tagPtY = [NSString stringWithFormat:@"PtY%d",tagNumber];
//    NSString *tagScale = [NSString stringWithFormat:@"Scale%d",tagNumber];
//    [defaults setFloat:pt.x  forKey:@"PanX"];
//    [defaults setFloat:pt.y forKey:@"PanY"];
//    [defaults setFloat:1.0f forKey:@"Zoom"];
    
//    [defaults setFloat:rateFit forKey:tagScale];
//    switch (tagNumber) {
//        case 0:{
//            zoom1 = [defaults floatForKey:@"Scale0"];
//            [defaults setFloat:0.0f forKey:@"PanX0"];
//            [defaults setFloat:0.0f forKey:@"PanY0"];
//            [defaults setFloat:1.0f forKey:@"Zoom0"];
//        }
//            break;
//        case 1:{
//            zoom2 = [defaults floatForKey:@"Scale1"];
//            [defaults setFloat:0.0f forKey:@"PanX1"];
//            [defaults setFloat:0.0f forKey:@"PanY1"];
//            [defaults setFloat:1.0f forKey:@"Zoom1"];
//        }
//            break;
//        case 2:{
//            zoom3 = [defaults floatForKey:@"Scale2"];
//            [defaults setFloat:0.0f forKey:@"PanX2"];
//            [defaults setFloat:0.0f forKey:@"PanY2"];
//            [defaults setFloat:1.0f forKey:@"Zoom2"];
//        }
//            break;
//        case 3:{
//            zoom4 = [defaults floatForKey:@"Scale3"];
//            [defaults setFloat:0.0f forKey:@"PanX3"];
//            [defaults setFloat:0.0f forKey:@"PanY3"];
//            [defaults setFloat:1.0f forKey:@"Zoom3"];
//        }
//            break;
    
//    }
    //    [self resetPostionZoomParameters];
    //    [self resetGestureParameters];
//    NSLog(@"angle is %f",angle);
    float zoomFactor = [defaults floatForKey:@"Zoom"];
    imgView.transform = CGAffineTransformRotate(imgView.transform, angle);
    if ([defaults boolForKey:@"Flip"])
        imgView.transform = CGAffineTransformScale(imgView.transform, -zoomFactor, zoomFactor);
    else
        imgView.transform = CGAffineTransformScale(imgView.transform, zoomFactor, zoomFactor);
    
    
//    imgView.transform = CGAffineTransformTranslate(imgView.transform, [defaults floatForKey:@"PanX"], [defaults floatForKey:@"PanY"]);
}
- (void) fillRotateMenu {
//    _rotateMenuView = [[UIScrollView alloc] initWithFrame:self.frameSelectionBar.frame];
    //    _rotateMenuView.contentSize=CGSizeMake(320, self.photoSlider.frame.size.height);
//    _rotateMenuView.backgroundColor=[UIColor darkGrayColor];
    
//    [self.bottomView addSubview:_rotateMenuView];
    
//    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    backButton.frame = CGRectMake(5, 5, 60, 60);
//    //    backButton.showsTouchWhenHighlighted=YES;
//    backButton.tag=1;
//    [backButton setImage:[UIImage imageNamed:@"back-icon-614x460.png"]  forState:UIControlStateNormal];
//    backButton.backgroundColor=[UIColor scrollViewTexturedBackgroundColor];
//    backButton.titleLabel.textColor= [UIColor whiteColor];
//    [backButton addTarget:self action:@selector(goBackToPreviousMenu) forControlEvents:UIControlEventTouchUpInside];
//    [self.rotateMenuView addSubview:backButton];
//    if (IS_TALL_SCREEN) {
//        
//        self.rotateMenuView.frame=CGRectMake(0, 353, 320, 151);
//    }
    CGRect frame = CGRectMake(5.0, 5.0, 310.0, 47.0);
    sliderRotate = [[UISlider alloc] initWithFrame:frame];
    [sliderRotate addTarget:self action:@selector(rotateChanged:) forControlEvents:UIControlEventValueChanged];
    [sliderRotate setBackgroundColor:[UIColor clearColor]];
    sliderRotate.minimumValue = kRotateMin;
    sliderRotate.maximumValue = kRotateMax;
    sliderRotate.continuous = YES;
    sliderRotate.value = 0.0;
    [self.rotateMenuView addSubview:sliderRotate];
    
    labelRotate = [[UILabel alloc] initWithFrame:CGRectMake(265, 0, 50, 15)];
    labelRotate.textAlignment = NSTextAlignmentRight;
    labelRotate.textColor = [UIColor whiteColor];
    labelRotate.font = [UIFont systemFontOfSize:12];
    labelRotate.backgroundColor=[UIColor clearColor];
    labelRotate.layer.shadowOffset=CGSizeMake(1, 1);
    labelRotate.layer.shadowColor= [UIColor blackColor].CGColor;
    labelRotate.layer.shadowOpacity = 0.8;
    [self.rotateMenuView addSubview:labelRotate];
    
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    resetButton.frame = CGRectMake(5*5+58*4, 57,  58, 58);
    //    resetButton.showsTouchWhenHighlighted=YES;
    [resetButton setTitle:@"reset" forState:UIControlStateNormal];
    resetButton.titleLabel.font = [UIFont systemFontOfSize:18];
    resetButton.backgroundColor=[UIColor darkGrayColor];
    resetButton.titleLabel.textColor= [UIColor whiteColor];
    [resetButton addTarget:self action:@selector(resetRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:resetButton];
    UIButton *minusAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    minusAngleButton.frame = CGRectMake(5, 57,  58, 58);
    minusAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
    //    rightAngleButton.showsTouchWhenHighlighted=YES;
    //    rightAngleButton.layer.borderWidth=kBorderWidth;
    //    rightAngleButton.layer.borderColor=[[UIColor clearColor] CGColor];
    [minusAngleButton setTitle:@"-10°" forState:UIControlStateNormal];
    minusAngleButton.backgroundColor=[UIColor darkGrayColor];
    [minusAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [minusAngleButton addTarget:self action:@selector(minusTenDegreeRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:minusAngleButton];
    
    UIButton *rightAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightAngleButton.frame = CGRectMake(5*2+58, 57,  58, 58);
    rightAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
    //    rightAngleButton.showsTouchWhenHighlighted=YES;
    //    rightAngleButton.layer.borderWidth=kBorderWidth;
    //    rightAngleButton.layer.borderColor=[[UIColor clearColor] CGColor];
    [rightAngleButton setTitle:@"90°" forState:UIControlStateNormal];
    rightAngleButton.backgroundColor=[UIColor darkGrayColor];
    [rightAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [rightAngleButton addTarget:self action:@selector(rightAngleRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:rightAngleButton];
    
    UIButton *plusAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    plusAngleButton.frame = CGRectMake(5*3+58*2, 57,  58, 58);
    plusAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
    //    rightAngleButton.showsTouchWhenHighlighted=YES;
    //    rightAngleButton.layer.borderWidth=kBorderWidth;
    //    rightAngleButton.layer.borderColor=[[UIColor clearColor] CGColor];
    [plusAngleButton setTitle:@"10°" forState:UIControlStateNormal];
    plusAngleButton.backgroundColor=[UIColor darkGrayColor];
    [plusAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [plusAngleButton addTarget:self action:@selector(plusTenDegreeRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:plusAngleButton];
    
    UIButton *flipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    flipButton.frame = CGRectMake(5*4+58*3, 57,  58, 58);
    flipButton.titleLabel.font = [UIFont systemFontOfSize:18];
    //    flipButton.showsTouchWhenHighlighted=YES;
    //    flipButton.layer.borderWidth=kBorderWidth;
    //    flipButton.layer.borderColor=[[UIColor clearColor] CGColor];
    [flipButton setTitle:@"flip" forState:UIControlStateNormal];
    flipButton.backgroundColor=[UIColor darkGrayColor];
    [flipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [flipButton addTarget:self action:@selector(flip) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:flipButton];
    
}
- (void) fillSplitMenu {
//    if (IS_TALL_SCREEN) {
//        self.splitMenuView.frame=CGRectMake(0, 353, 320, 151);
//    }
    CGRect frame = CGRectMake(5.0, 5.0, 310.0, 47.0);
    sliderSplit = [[UISlider alloc] initWithFrame:frame];
    [sliderSplit addTarget:self action:@selector(splitChanged:) forControlEvents:UIControlEventValueChanged];
    [sliderSplit setBackgroundColor:[UIColor clearColor]];
    sliderSplit.minimumValue = kSplitMin;
    sliderSplit.maximumValue = kSplitMax;
    sliderSplit.continuous = YES;
    sliderSplit.value = [defaults integerForKey:@"Split"];
    [self.splitMenuView addSubview:sliderSplit];
    
    labelSplit = [[UILabel alloc] initWithFrame:CGRectMake(265, 0, 50, 15)];
    labelSplit.textAlignment = NSTextAlignmentRight;
    labelSplit.textColor = [UIColor whiteColor];
    labelSplit.font = [UIFont systemFontOfSize:12];
    labelSplit.backgroundColor=[UIColor clearColor];
    labelSplit.layer.shadowOffset=CGSizeMake(1, 1);
    labelSplit.layer.shadowColor= [UIColor blackColor].CGColor;
    labelSplit.layer.shadowOpacity = 0.8;
    [self.splitMenuView addSubview:labelSplit];
    
//    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    resetButton.frame = CGRectMake(5*5+58*4, 57,  58, 58);
//    //    resetButton.showsTouchWhenHighlighted=YES;
//    [resetButton setTitle:@"reset" forState:UIControlStateNormal];
//    resetButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    resetButton.backgroundColor=[UIColor scrollViewTexturedBackgroundColor];
//    resetButton.titleLabel.textColor= [UIColor whiteColor];
//    [resetButton addTarget:self action:@selector(resetRotate) forControlEvents:UIControlEventTouchUpInside];
//    [self.rotateMenuView addSubview:resetButton];
//    UIButton *minusAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    minusAngleButton.frame = CGRectMake(5, 57,  58, 58);
//    minusAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    //    rightAngleButton.showsTouchWhenHighlighted=YES;
//    //    rightAngleButton.layer.borderWidth=kBorderWidth;
//    //    rightAngleButton.layer.borderColor=[[UIColor clearColor] CGColor];
//    [minusAngleButton setTitle:@"-10°" forState:UIControlStateNormal];
//    minusAngleButton.backgroundColor=[UIColor scrollViewTexturedBackgroundColor];
//    [minusAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [minusAngleButton addTarget:self action:@selector(minusTenDegreeRotate) forControlEvents:UIControlEventTouchUpInside];
//    [self.rotateMenuView addSubview:minusAngleButton];
//    
//    UIButton *rightAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    rightAngleButton.frame = CGRectMake(5*2+58, 57,  58, 58);
//    rightAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    //    rightAngleButton.showsTouchWhenHighlighted=YES;
//    //    rightAngleButton.layer.borderWidth=kBorderWidth;
//    //    rightAngleButton.layer.borderColor=[[UIColor clearColor] CGColor];
//    [rightAngleButton setTitle:@"90°" forState:UIControlStateNormal];
//    rightAngleButton.backgroundColor=[UIColor scrollViewTexturedBackgroundColor];
//    [rightAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [rightAngleButton addTarget:self action:@selector(rightAngleRotate) forControlEvents:UIControlEventTouchUpInside];
//    [self.rotateMenuView addSubview:rightAngleButton];
//    
//    UIButton *plusAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    plusAngleButton.frame = CGRectMake(5*3+58*2, 57,  58, 58);
//    plusAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    //    rightAngleButton.showsTouchWhenHighlighted=YES;
//    //    rightAngleButton.layer.borderWidth=kBorderWidth;
//    //    rightAngleButton.layer.borderColor=[[UIColor clearColor] CGColor];
//    [plusAngleButton setTitle:@"10°" forState:UIControlStateNormal];
//    plusAngleButton.backgroundColor=[UIColor scrollViewTexturedBackgroundColor];
//    [plusAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [plusAngleButton addTarget:self action:@selector(plusTenDegreeRotate) forControlEvents:UIControlEventTouchUpInside];
//    [self.rotateMenuView addSubview:plusAngleButton];
//    
//    UIButton *flipButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    flipButton.frame = CGRectMake(5*4+58*3, 57,  58, 58);
//    flipButton.titleLabel.font = [UIFont systemFontOfSize:18];
//    //    flipButton.showsTouchWhenHighlighted=YES;
//    //    flipButton.layer.borderWidth=kBorderWidth;
//    //    flipButton.layer.borderColor=[[UIColor clearColor] CGColor];
//    [flipButton setTitle:@"flip" forState:UIControlStateNormal];
//    flipButton.backgroundColor=[UIColor scrollViewTexturedBackgroundColor];
//    [flipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [flipButton addTarget:self action:@selector(flip) forControlEvents:UIControlEventTouchUpInside];
//    [self.rotateMenuView addSubview:flipButton];
    
}
- (void) resetRotate {
//        NSString *tagZoom = [NSString stringWithFormat:@"Zoom%d",tapBlockNumber];
        sliderRotate.value = 0.0;
//        NSString *tagRotate = [NSString stringWithFormat:@"Rotate%d",tapBlockNumber];
        [defaults setFloat:sliderRotate.value forKey:@"Rotate"];
        CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
        for (UIScrollView *blockSlider in droppableAreas){
//            if (blockSlider.tag == tapBlockNumber){//split
                if (blockSlider.subviews.count==0) return;
                UIImageView *imageView = blockSlider.subviews[0];
                imageView.transform = CGAffineTransformIdentity;
                imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor,zoomFactor);
            [defaults setBool:NO forKey:@"Flip"];
//            }
        }
    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(sliderRotate.value)];
}
- (void)splitChanged:(id)sender {
    //    [Flurry logEvent:@"Frame - Rotate"];
    
    sliderSplit = (UISlider *)sender;
    nMargin = sliderSplit.value;
//    CGFloat splitLevel = [defaults floatForKey:@"Split"];
//    for (UIScrollView *blockSlider in droppableAreas){
//               if (blockSlider.subviews.count==0) return;
//        UIImageView *imageView = blockSlider.subviews[0];
//        imageView.transform = CGAffineTransformIdentity;
//        imageView.transform = CGAffineTransformRotate(imageView.transform, sliderRotate.value);
//        if ([defaults boolForKey:@"Flip"])
//            imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
//        else
//            imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
//        //            }
//    }
    [sliderSplit setValue:(int)(sliderSplit.value) animated:NO];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag=[defaults integerForKey:@"frame"];
    if (btn.tag <= 25)
        [self frameClicked:btn];
    else
        [self secondFrameClicked:btn];
    [defaults setFloat:sliderSplit.value forKey:@"Split"];
    labelSplit.text = [NSString stringWithFormat:@"%.0f",sliderSplit.value];
}
- (void)rotateChanged:(id)sender {
    
//    [Flurry logEvent:@"Frame - Rotate"];
    
    sliderRotate = (UISlider *)sender;
//        NSString *tagFlip = [NSString stringWithFormat:@"flipImage%d",tapBlockNumber];
//        NSString *tagZoom = [NSString stringWithFormat:@"Zoom%d",tapBlockNumber];
//    NSString *tagRotate;
        CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
        for (UIScrollView *blockSlider in droppableAreas){
//            tagRotate = [NSString stringWithFormat:@"Rotate%d",blockSlider.tag];
//            if (blockSlider.tag == tapBlockNumber){//split
                if (blockSlider.subviews.count==0) return;
                UIImageView *imageView = blockSlider.subviews[0];
                imageView.transform = CGAffineTransformIdentity;
                imageView.transform = CGAffineTransformRotate(imageView.transform, sliderRotate.value);
                if ([defaults boolForKey:@"Flip"])
                    imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
                else
                    imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
//            }
        }
        [defaults setFloat:sliderRotate.value forKey:@"Rotate"];
    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(sliderRotate.value)];
}
- (void) rightAngleRotate {
    [Flurry logEvent:@"rightAngle"];

//        NSString *tagZoom = [NSString stringWithFormat:@"Zoom%d",tapBlockNumber];
//        NSString *tagRotate = [NSString stringWithFormat:@"Rotate%d",tapBlockNumber];
        CGFloat rotateAngle = [defaults floatForKey:@"Rotate"]+M_PI_2;
        [defaults setFloat:rotateAngle forKey:@"Rotate"];
        CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
        for (UIScrollView *blockSlider in droppableAreas){
//            if (blockSlider.tag == tapBlockNumber){//split
                if (blockSlider.subviews.count==0) return;
                UIImageView *imageView = blockSlider.subviews[0];
                imageView.transform = CGAffineTransformIdentity;
//                NSString *tagFlip = [NSString stringWithFormat:@"flipImage%d",tapBlockNumber];
                imageView.transform = CGAffineTransformRotate(imageView.transform, rotateAngle);
                if ([defaults boolForKey:@"Flip"])
                    imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
                else
                    imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
//            }
        }
        rotateAngle = fmodf(rotateAngle, 2*M_PI);
        sliderRotate.value=rotateAngle;
    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(sliderRotate.value)];

}

- (void) plusTenDegreeRotate {
    [Flurry logEvent:@"plusTen"];

//    NSString *tagZoom = [NSString stringWithFormat:@"Zoom%d",tapBlockNumber];
//    NSString *tagRotate = [NSString stringWithFormat:@"Rotate%d",tapBlockNumber];
    CGFloat rotateAngle = [defaults floatForKey:@"Rotate"]+M_PI_2/9;
    [defaults setFloat:rotateAngle forKey:@"Rotate"];
    CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
    for (UIScrollView *blockSlider in droppableAreas){
//        if (blockSlider.tag == tapBlockNumber){//split
            if (blockSlider.subviews.count==0) return;
            UIImageView *imageView = blockSlider.subviews[0];
            imageView.transform = CGAffineTransformIdentity;
//            NSString *tagFlip = [NSString stringWithFormat:@"flipImage%d",tapBlockNumber];
            imageView.transform = CGAffineTransformRotate(imageView.transform, rotateAngle);
            if ([defaults boolForKey:@"Flip"])
                imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
            else
                imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
//        }
    }
    rotateAngle = fmodf(rotateAngle, 2*M_PI);
    sliderRotate.value=rotateAngle;
    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(sliderRotate.value)];

}

- (void) minusTenDegreeRotate {
    [Flurry logEvent:@"minusTen"];

//    NSString *tagZoom = [NSString stringWithFormat:@"Zoom%d",tapBlockNumber];
//    NSString *tagRotate = [NSString stringWithFormat:@"Rotate%d",tapBlockNumber];
    CGFloat rotateAngle = [defaults floatForKey:@"Rotate"]-M_PI_2/9;
    [defaults setFloat:rotateAngle forKey:@"Rotate"];
    CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
    for (UIScrollView *blockSlider in droppableAreas){
//        if (blockSlider.tag == tapBlockNumber){ //split
            if (blockSlider.subviews.count==0) return;
            UIImageView *imageView = blockSlider.subviews[0];
            imageView.transform = CGAffineTransformIdentity;
//            NSString *tagFlip = [NSString stringWithFormat:@"flipImage%d",tapBlockNumber];
            imageView.transform = CGAffineTransformRotate(imageView.transform, rotateAngle);
            if ([defaults boolForKey:@"Flip"])
                imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
            else
                imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
//        }
    }
    rotateAngle = fmodf(rotateAngle, 2*M_PI);
    sliderRotate.value=rotateAngle;
    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(sliderRotate.value)];

}

- (void) flip {
    [Flurry logEvent:@"Flip"];
    
//        NSString *tagFlip = [NSString stringWithFormat:@"flipImage%d",tapBlockNumber];
        if (![defaults boolForKey:@"Flip"])
            [defaults setBool:YES forKey:@"Flip"];
        else
            [defaults setBool:NO forKey:@"Flip"];
        for (UIScrollView *blockSlider in droppableAreas){
//            if (blockSlider.tag == tapBlockNumber){  //split
                if (blockSlider.subviews.count==0) return;
                UIImageView *imageView = blockSlider.subviews[0];
                imageView.transform = CGAffineTransformScale(imageView.transform, -1,1);
//            }
        }
}


- (CGRect) getScrollFrame1:(int)style subStyle:(int)sub
{
    CGRect rc;
    float scroll_width = 0;
    float scroll_height = 0;
    
    float   nLeftMargin=0;
    float  nTopMargin =0;
    NSLog(@"style=%d,sub=%d",style,sub);
    if (style == 1) {
        if( sub == 1) {
            scroll_width = self.frameContainer.frame.size.width - 10 * 2;
            scroll_height = self.frameContainer.frame.size.height - 10 * 2;
            rc = CGRectMake(10, 10, scroll_width, scroll_height );
            return rc;
            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
        }else if( sub == 2) {
            scroll_width = self.frameContainer.frame.size.width - 10 * 4;//10*7
            scroll_height = self.frameContainer.frame.size.height - 10 * 4;//10*7
            nLeftMargin =10 * 4/2;//10*7
            nTopMargin = 10 * 4/2;//10*7
            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
            rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
        }
        else if( sub == 3) {
            scroll_width = self.frameContainer.frame.size.width - 10 * 2;
            scroll_height = self.self.frameContainer.frame.size.height - 70; // - 10*7*2 = -140
            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
            rc = CGRectMake(10, 10, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 4) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 5*2;// *8*2
            scroll_height = self.frameContainer.frame.size.height - nMargin * 5*2;
            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
        }
        
        else if ( sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            //            nTopMargin = nMargin;
            nLeftMargin = nMargin * 2 + scroll_width;
            //nLeftMargin=  200;
            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
            rc = CGRectMake(nLeftMargin, nMargin, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 6) { //full
            scroll_width = 310;
            scroll_height = 310;//350
            //            nTopMargin = nMargin;
            //            nLeftMargin = 0;
            //nLeftMargin=  200;
            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        
        //secondFrameSlider stuff begins here
        
        else if ( sub == 7) { //tall right with 10 margin top/right
            scroll_width = 240;
            scroll_height = 290; //330
            //            nTopMargin = nMargin;
            //            nLeftMargin = 0;
            //nLeftMargin=  200;
            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
            rc = CGRectMake(60, 10, scroll_width, scroll_height );
            return rc;
        }
        //        else if ( sub == 8) { // small right corner with 10 margin top/right
        //            scroll_width = 150;
        //            scroll_height = 150;
        //            //            nTopMargin = nMargin;
        //            //            nLeftMargin = 0;
        //            //nLeftMargin=  200;
        //            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
        //            rc = CGRectMake(150, 10, scroll_width, scroll_height );
        //            return rc;
        //        }
        
        else if ( sub == 9) {  //frame with horizontal bottom
            scroll_width = 310;
            scroll_height = 250; //250
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 10) { // left column frame
            scroll_width = 250;
            scroll_height = 310; //350
            rc = CGRectMake(60, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 11) { // middle column frame
            scroll_width = 210;
            scroll_height = 310; //350
            rc = CGRectMake(50, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 12) { // middle row frame
            scroll_width = 310;
            scroll_height = 210; //250
            rc = CGRectMake(0, 50, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 13) { // left corner frame
            scroll_width = 150;
            scroll_height = 150;
            rc = CGRectMake(60, 60, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 14) { // right frame
            scroll_width = 200;
            scroll_height = 200;
            rc = CGRectMake(55, 55, scroll_width, scroll_height );
            return rc;
        }
        //        else if ( sub == 15) { // right frame
        //            scroll_width = 310;
        //            scroll_height = 350;
        //            rc = CGRectMake(0, 0, scroll_width, scroll_height );
        //            return rc;
        //        }
    }
    
    else if (style == 2) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
        }
        else if (sub == 2) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
        }
        else if (sub == 3){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
        }
        else if(sub == 4){
            scroll_width = (self.frameContainer.frame.size.width - 10 * 3 ) / 2;
            scroll_height = self.frameContainer.frame.size.height - 10 * 4;
            nTopMargin=10 *2+10;

            rc = CGRectMake(20-nMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
        }
        else if(sub == 5){
            scroll_width = (self.frameContainer.frame.size.width - 10 * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - 10 * 12);
            nTopMargin=10 *6;
            rc = CGRectMake(nMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
        }
        else if(sub == 6){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 )/2;
            nTopMargin=nMargin *2;
            nLeftMargin = nMargin * 5+2;
            rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
            
        }
        else if (sub == 7) { //secondFrameSlider stuff
            scroll_width = 155;//155
            scroll_height = 310;//350
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 8) {  //secondFrameSlider stuff
            scroll_width = 200;
            scroll_height = 135;
            rc = CGRectMake(10, 20, scroll_width+nMargin, scroll_height );
            return rc;
        }
        else if (sub == 9) {  //secondFrameSlider stuff
            scroll_width = 185;
            scroll_height = 290;
            rc = CGRectMake(10, 10, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 10) {  //secondFrameSlider stuff
            scroll_width = 310;
            scroll_height =310;
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 11) {  //secondFrameSlider stuff
            scroll_width = 190;
            scroll_height =190;
            rc = CGRectMake(5, 115, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 12) {  //secondFrameSlider stuff
            scroll_width = 180;
            scroll_height =180;
            rc = CGRectMake(0, 0, scroll_width+nMargin*3, scroll_height );
            return rc;
        }
        else if (sub == 13) {  //secondFrameSlider stuff
            scroll_width = 150;
            scroll_height =250;
            rc = CGRectMake(0, 0, scroll_width+nMargin/4, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 14) {  //secondFrameSlider stuff
            scroll_width = 130;
            scroll_height =130;
            rc = CGRectMake(5, 5, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 15) { // right frame
            scroll_width = 155;
            scroll_height = 310; //350
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 16) { // right frame
            scroll_width = 310;
            scroll_height = 155;
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        
    }
    else if (style == 3) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 2 / 5;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
        } else if (sub == 2) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
        } else if (sub == 3) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 2 / 5;
        } else if (sub == 4) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
        } else if (sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
        } else if (sub == 6) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
        }
        else if (sub == 7){
            scroll_width = 150;
            scroll_height = 96;
            rc = CGRectMake(5, 5, scroll_width+nMargin*3, scroll_height );
            return rc;
            
        }else if (sub == 8) {
            scroll_width = 96;
            scroll_height = 250;
            rc = CGRectMake(5, 30-nMargin, scroll_width, scroll_height+nMargin*2 );
            return rc;
            
        }else if (sub == 9) {
            scroll_width = 100;
            scroll_height = 100;
            rc = CGRectMake(30-nMargin, 75-nMargin - nMargin/4, scroll_width+nMargin+nMargin/4, scroll_height+nMargin +nMargin/4 );
            return rc;
            
        }
        else if (sub == 10){
            scroll_width = 96;
            scroll_height = 150;
            rc = CGRectMake(5, 5, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 11){
            scroll_width = 100;
            scroll_height = 200;
            rc = CGRectMake(5, 20, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 12){
            scroll_width = 100;
            scroll_height = 100;
            rc = CGRectMake(5, 105-nMargin, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 13){
            scroll_width = 150;
            scroll_height = 300;//330
            rc = CGRectMake(5, 5, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 14){
            scroll_width = 150;
            scroll_height = 200;
            rc = CGRectMake(0, 55-nMargin, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(0, 0, 155, 310 ); //(0,0,155,350)
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(0, 0, 310, 155 );
            return rc;
        }
    }
    else if (style == 4) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
        } else if (sub == 2) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 5 ) / 4;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
        } else if (sub == 3) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 5 ) / 4;
        } else if (sub == 4) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 2 / 5;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
        } else if (sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
        } else if (sub == 6) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 2 / 5;
        } else if (sub == 7) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
        }else if (sub == 8){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4);
            scroll_height = self.frameContainer.frame.size.height - nMargin * 10.50;
            nLeftMargin = nMargin * 2;
            rc = CGRectMake( nLeftMargin, nMargin, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 9){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 5 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3)*6/18;
            nTopMargin = nMargin  ;
            rc = CGRectMake(nMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 10){
            rc = CGRectMake(5-nMargin/4, 5, 71+nMargin/2, 250+nMargin );
            return rc;
        }
        else if (sub == 11){
            rc = CGRectMake(5-nMargin/4, 5, 180+nMargin/2, 150 );
            return rc;
        }
        
        else if (sub == 12){
            rc = CGRectMake(5,5,175+nMargin*2,75 );
            return rc;
        }
        else if (sub == 13){
            rc = CGRectMake(10-nMargin/4,75-nMargin/2,100+nMargin/2,100+nMargin/2 );
            return rc;
        }
        else if (sub == 14){
            rc = CGRectMake(5,75,100,100 );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(5,55,200,200 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(5,5,96,300 );//330
            return rc;
        }
        else if (sub == 17){
            rc = CGRectMake(0, 0, 155, 155 );
            return rc;
        }
        else if (sub == 18){
            rc = CGRectMake(5, 5, 75+nMargin, 75 );
            return rc;
        }
        
    }
    
    rc = CGRectMake(nMargin, nMargin, scroll_width, scroll_height );
    NSLog(@"nMargin=%d, nMargin=%d,width=%f , height=%f",nMargin, nMargin,scroll_width,scroll_height);
    return rc;
}


- (CGRect) getScrollFrame2:(int)style subStyle:(int)sub
{
    CGRect rc;
    
    float scroll_width = 0;
    float scroll_height = 0;
    
    float nLeftMargin = 0;
    float nTopMargin = 0;
    
    if (style == 1) {
    }
    else if (style == 2) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin;
            NSLog(@"Scroll 2 inside nLeftMargin=%f nTopMargin=%f width=%f,height=%f",nLeftMargin,nTopMargin,self.frameContainer.frame.size.width,self.frameContainer.frame.size.height);
        }
        else if (sub == 2) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3) / 2;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin;
            NSLog(@"Scroll 2 inside nLeftMargin=%f nTopMargin=%f width=%f,height=%f",nLeftMargin,nTopMargin,scroll_width,scroll_height);
        }
        else if (sub == 3){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 2 + scroll_height;
            
        }
        else if (sub == 4){
            scroll_width = (self.frameContainer.frame.size.width - 10 * 3 ) / 2;
            scroll_height = self.frameContainer.frame.size.height - 10 * 10;
            nLeftMargin = self.frameContainer.frame.size.width - scroll_width ;
            nTopMargin = 10 *5+10;
            rc = CGRectMake(nLeftMargin - (20-nMargin), nTopMargin, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 5){
            scroll_width = (self.frameContainer.frame.size.width - 10 * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - 10 * 12);
            nTopMargin=10 *6;
            //            rc = CGRectMake(nMargin, nTopMargin, scroll_width, scroll_height );
            //            return rc;
            //            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            //            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 5 / 9;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            //            nTopMargin = nMargin *6;
        }
        else if (sub == 6){
            //            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            //            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 )* 6/13;
            //            nLeftMargin = self.frameContainer.frame.size.width - 5*nMargin - scroll_width;
            ////            nTopMargin = nMargin *13;
            //            nTopMargin = nMargin *18;
            
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 2;
            
            nLeftMargin = -nMargin * 2 + scroll_width;
            nTopMargin = nMargin * 2 + scroll_height;
        }
        else if (sub == 7) {  //secondFrameSlider stuff
            scroll_width = 120+nMargin*2;
            scroll_height = 150+nMargin*2;
            rc = CGRectMake(175-nMargin, 20-nMargin, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 8) {  //secondFrameSlider stuff
            scroll_width = 200;
            scroll_height = 135;
            rc = CGRectMake(100-nMargin*3, 155, scroll_width+nMargin*3, scroll_height );
            return rc;
        }
        else if (sub == 9) {  //secondFrameSlider stuff
            scroll_width = 100;
            scroll_height =100;
            rc = CGRectMake(200, 200, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 10) {  //secondFrameSlider stuff
            scroll_width = 100;
            scroll_height =100;
            rc = CGRectMake(105-nMargin, 105-nMargin, scroll_width+nMargin*4, scroll_height+nMargin*4 );
            return rc;
        }
        else if (sub == 11) {  //secondFrameSlider stuff
            scroll_width = 110;
            scroll_height =250;
            rc = CGRectMake(195, 5, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 12) {  //secondFrameSlider stuff
            scroll_width = 210;
            scroll_height =130;
            rc = CGRectMake(100-nMargin*3, 180, scroll_width+nMargin*3, scroll_height );
            return rc;
        }
        else if (sub == 13) {  //secondFrameSlider stuff
            scroll_width = 155;
            scroll_height =150;
            rc = CGRectMake(155, 160-nMargin*3, scroll_width, scroll_height+nMargin*3 );
            return rc;
        }
        else if (sub == 14) {  //secondFrameSlider stuff
            scroll_width = 170;
            scroll_height =310; //350
            rc = CGRectMake(140, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 15) { // right frame
            scroll_width = 155;
            scroll_height = 310; //350
            rc = CGRectMake(155, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 16) { // right frame
            scroll_width = 310;
            scroll_height = 155;
            rc = CGRectMake(0, 155, scroll_width, scroll_height );
            return rc;
        }
        
    }
    else if (style == 3) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin;
        } else if (sub == 2) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 2 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 2 );
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin;
        } else if (sub == 3) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin;
        } else if (sub == 4) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin;
        } else if (sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 2 + scroll_width;
        } else if (sub == 6) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 2 + scroll_height;
        }
        else if (sub == 7) {
            rc = CGRectMake(70-nMargin,106-nMargin/4,150+nMargin*3,98+nMargin/2 );
            return rc;
        }
        else if (sub == 8) {
            rc = CGRectMake(106-nMargin/4,30-nMargin,96+nMargin/2,250+nMargin*2 );
            return rc;
        } else if (sub == 9) {
            rc = CGRectMake(135,10,165,165 );
            return rc;
        }
        else if (sub == 10) {
            rc = CGRectMake(106-nMargin/4,100-nMargin,96+nMargin/2,150+nMargin*2 );
            return rc;
        }
        else if (sub == 11){
            scroll_width = 100;
            scroll_height = 200;
            rc = CGRectMake(105, 90-nMargin, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 12){
            scroll_width = 100;
            scroll_height = 260;//300
            rc = CGRectMake(105,25-nMargin, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 13){
            scroll_width = 145;
            scroll_height = 95;
            rc = CGRectMake(160, 5, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 14){
            scroll_width = 75;
            scroll_height = 200;
            rc = CGRectMake(155-nMargin/2, 55-nMargin, scroll_width+nMargin, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(155, 0, 155, 155 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(0, 155, 155, 155 );
            return rc;
        }
        
    }
    else if (style == 4) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 2 + scroll_width;
        } else if (sub == 2) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 5 ) / 4;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 2 + scroll_width;
        } else if (sub == 3) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 5 ) / 4;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 2 + scroll_height;
        } else if (sub == 4) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin;
        } else if (sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 2 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 2 );
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin;
        } else if (sub == 6) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin;
        } else if (sub == 7) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 2 + scroll_width;
        }else if (sub == 8){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3)*6/17;
            nTopMargin = nMargin *15 ;
            rc = CGRectMake(nMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
            
        } else if (sub == 9) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 )*6 /9 ;
            nTopMargin = nMargin *8.50;
            nLeftMargin = nMargin*7;
            rc = CGRectMake( nLeftMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
            
        }
        else if (sub == 10){
            rc = CGRectMake(81, 310-255-nMargin, 71+nMargin/4, 250+nMargin );
            return rc;
        }
        else if (sub == 11){
            rc = CGRectMake(190, 5, 100, 150 );
            return rc;
        }
        else if (sub == 12){
            rc = CGRectMake(130-nMargin*2, 80, 175+nMargin*2, 75 );
            return rc;
        }
        else if (sub == 13){
            rc = CGRectMake(10-nMargin/4, 180-nMargin/4, 100+nMargin/2, 100+nMargin/2 );
            return rc;
        }
        else if (sub == 14){
            rc = CGRectMake(205, 75, 100, 100  );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(200, 5, 175, 100 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(106-nMargin/4, 5, 96+nMargin/2, 96+nMargin );
            return rc;
        }
        else if (sub == 17){
            rc = CGRectMake(155, 0, 155, 155 );
            return rc;
        }
        else if (sub == 18){
            rc = CGRectMake(80-nMargin/4, 85-nMargin/4, 110+nMargin/2, 310-90+nMargin/4 );
            return rc;
        }
        
    }
    
    rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height);
    NSLog(@"Scroll 2 outside nLeftMargin=%f nTopMargin=%f width=%f,height=%f",nLeftMargin,nTopMargin,scroll_width,scroll_height);
    return rc;
}



- (CGRect) getScrollFrame3:(int)style subStyle:(int)sub{
    CGRect rc;
    
    float scroll_width = 0;
    float scroll_height = 0;
    
    float nLeftMargin = 0;
    float nTopMargin = 0;
    
    if (style == 3) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            NSLog(@"Scroll 3 inside nLeftMargin=%f nTopMargin=%f width=%f,height=%f",nLeftMargin,nTopMargin,self.frameContainer.frame.size.width,self.frameContainer.frame.size.height);
        } else if (sub == 2) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin;
        } else if (sub == 3) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
        } else if (sub == 4) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 2 );
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 2 / 5;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin;
        } else if (sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 3 + scroll_width * 2;
        } else if (sub == 6) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 3 + scroll_height * 2;
        }
        else if (sub == 7) {
            rc = CGRectMake(150-nMargin*2,310-96-5,155+nMargin*2,96 );
            return rc;
        }
        else if (sub == 8) {
            rc = CGRectMake(206,30-nMargin,96,250+nMargin*2 );
            return rc;
            
        } else if (sub == 9) {
            rc = CGRectMake(135,180-nMargin/4,100+nMargin+nMargin/4,100+nMargin+nMargin/4 );
            return rc;
        }
        else if (sub == 10) {
            rc = CGRectMake(206,155-nMargin*2,96,150+nMargin*2 );
            return rc;
        }
        else if (sub == 11){
            scroll_width = 100;
            scroll_height = 200;
            rc = CGRectMake(205, 20, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 12){
            scroll_width = 100;
            scroll_height = 100;
            rc = CGRectMake(205, 105-nMargin, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 13){
            scroll_width = 145;
            scroll_height = 200;
            rc = CGRectMake(160, 105, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 14){
            scroll_width = 75;
            scroll_height = 200;
            rc = CGRectMake(235, 55-nMargin, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(155, 155, 155, 155 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(155, 155, 155, 155 );
            return rc;
        }
    }
    else if (style == 4) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 2 + scroll_height;
        } else if (sub == 2) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 5 ) / 4;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 3 + scroll_width * 2;
        } else if (sub == 3) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 5 ) / 4;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 3 + scroll_height * 2;
        } else if (sub == 4) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin * 2 + scroll_height;
        } else if (sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
            nTopMargin = nMargin * 2 + scroll_height;
            nLeftMargin = nMargin;
        } else if (sub == 6) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin * 2 + scroll_width;
        } else if (sub == 7) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 3 + scroll_width * 2;
        }else if (sub == 8) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 )*6 /17 ;
            nTopMargin = nMargin *15;
            nLeftMargin = nMargin * 2 + scroll_width;
            rc = CGRectMake(nLeftMargin , nTopMargin, scroll_width, scroll_height );
            return rc;
            
        }else if (sub == 9) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 15.50 ) ;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 12);
            nTopMargin=nMargin *4;
            nLeftMargin = nMargin * 14.50;
            rc = CGRectMake(nLeftMargin , nTopMargin, scroll_width, scroll_height );
            return rc;
            
        }
        else if (sub == 10){
            rc = CGRectMake(157, 5, 71+nMargin/4, 250+nMargin );
            return rc;
        }
        else if (sub == 11){
            rc = CGRectMake(85-nMargin, 160-nMargin/4, 100+nMargin+nMargin/4, 150+nMargin/4 );
            return rc;
        }
        else if (sub == 12){
            rc = CGRectMake(5, 310-155, 175+nMargin*2, 75 );
            return rc;
        }
        else if (sub == 13){
            rc = CGRectMake(115, 180-nMargin/4, 100+nMargin/2, 100+nMargin/2 );
            return rc;
        }
        else if (sub == 14){
            rc = CGRectMake(105, 10, 100, 100 );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(105, 245, 175, 100 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(106-nMargin/4, 310-96-5-nMargin, 96+nMargin/2, 96+nMargin );
            return rc;
        }
        else if (sub == 17){
            rc = CGRectMake(0, 155, 155, 155 );
            return rc;
        }
        else if (sub == 18){
            rc = CGRectMake(195, 5, 110, 310-75-15+nMargin/4 );
            return rc;
        }
        
    }
    
    rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height);
    NSLog(@"Scroll 3 outside nLeftMargin=%f nTopMargin=%f width=%f,height=%f",nLeftMargin,nTopMargin,scroll_width,scroll_height);
    return rc;
}


- (CGRect) getScrollFrame4:(int)style subStyle:(int)sub{
    CGRect rc;
    
    float scroll_width = 0;
    float scroll_height = 0;
    
    float nLeftMargin = 0;
    float nTopMargin = 0;
    
    if (style == 4) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            nLeftMargin = nMargin * 2 + scroll_width;
            nTopMargin = nMargin * 2 + scroll_height;
            NSLog(@"Scroll 4 inside nLeftMargin=%f nTopMargin=%f width=%f,height=%f",nLeftMargin,nTopMargin,scroll_width,scroll_height);
        } else if (sub == 2) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 5 ) / 4;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 4 + scroll_width * 3;
        } else if (sub == 3) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 5 ) / 4;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 4 + scroll_height * 3;
        } else if (sub == 4) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin * 3 + scroll_height * 2;
        } else if (sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3;
            nTopMargin = nMargin * 3 + scroll_height * 2;
            nLeftMargin = nMargin;
        } else if (sub == 6) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin * 3 + scroll_width * 2;
        } else if (sub == 7) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 2 );
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 2 / 5;
            nLeftMargin = nMargin;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
        }else if (sub == 8) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 6 / 17;
            nTopMargin = nMargin*15;
            nLeftMargin = nMargin * 3 + scroll_width * 2;
            
            rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 9) {
            
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 6 ) / 3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 6 / 20;
            nTopMargin = nMargin*16;
            nLeftMargin = nMargin * 3 + scroll_width * 2;
            
            rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 10){
            rc = CGRectMake(233, 310-255-nMargin, 71+nMargin/4, 250+nMargin );//250
            return rc;
        }
        else if (sub == 11){
            rc = CGRectMake(190, 160-nMargin/4, 100, 150 +nMargin/4);
            return rc;
        }
        else if (sub == 12){
            rc = CGRectMake(130-nMargin*2, 310-80, 175+nMargin*2, 75 );
            return rc;
        }
        else if (sub == 13){
            rc = CGRectMake(115, 10, 185+nMargin/4, 165 );
            return rc;
        }
        else if (sub == 14){
            rc = CGRectMake(105, 310-180-nMargin, 100, 175+nMargin );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(130, 195, 175, 100 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(207, 5, 96, 300 );//330
            return rc;
        }
        else if (sub == 17){
            rc = CGRectMake(155, 155, 155, 155 );
            return rc;
        }
        else if (sub == 18){
            rc = CGRectMake(195, 310-80, 75+nMargin, 75 );
            return rc;
        }
    }
    rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height);
    NSLog(@"Scroll 4 outside nLeftMargin=%f nTopMargin=%f width=%f,height=%f",nLeftMargin,nTopMargin,scroll_width,scroll_height);
    return rc;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
