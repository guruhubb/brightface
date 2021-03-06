//
//  designViewController.m
//  One Frame
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
#define kZoomMax 4
#define kSplitMin 0.0
#define kSplitMax 20
#define kRotateMin -M_PI/16
#define kRotateMax M_PI/16
#import "designViewController.h"
#import "doneViewController.h"
#import "GPUImage.h"
#import "Flurry.h"
#import "MKStoreManager.h"
#import <opencv2/opencv.hpp>
#import "SkinDetector.h"


@interface designViewController (){
    ALAssetsLibrary *library;
    
    NSMutableArray *labelEffectsArray;
    NSMutableArray *labelSecondEffectsArray;
    NSMutableArray *droppableAreas;
    NSMutableArray *faceViews;
    BOOL firstTimeEffects;
    BOOL firstTime;
    BOOL firstTimeFilter;
    BOOL firstTimeDesign;
    BOOL resizeOn;
    BOOL doneMarkingFaces;
    int tapBlockNumber;
    int nStyle;
    int nSubStyle;
    int nMargin;
    SkinDetector mySkinDetector;
    int Y_MIN;
    int Y_MAX;
    int Cr_MIN;
    int Cr_MAX;
    int Cb_MIN;
    int Cb_MAX;
    
    UIActivityIndicatorView *indicatorView;

    
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
    
    CGFloat scale;
    CGFloat scaleView;

    
    CGFloat adjustedPtX1;
    CGFloat adjustedPtY1;
    CGFloat adjustedWidth1;
    CGFloat adjustedHeight1;
    
    CGFloat adjustedPtX2;
    CGFloat adjustedPtY2;
    CGFloat adjustedWidth2;
    CGFloat adjustedHeight2;
    
    CGFloat adjustedPtX3;
    CGFloat adjustedPtY3;
    CGFloat adjustedWidth3;
    CGFloat adjustedHeight3;
    
    CGFloat adjustedPtX4;
    CGFloat adjustedPtY4;
    CGFloat adjustedWidth4;
    CGFloat adjustedHeight4;
    
    UIImage *imageTemp;
    UIImage *maskTemp;
    
//    NSTimeInterval nowTime;
//    NSTimeInterval startTime;
    
//    GPUImageOutput<GPUImageInput> *filter;
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
    
    [self startActivityIndicator];
    
    faceViews = [[NSMutableArray alloc] init];
    library = [designViewController defaultAssetsLibrary];
    imageTemp=[UIImage imageWithCGImage:self.selectedImage.CGImage scale:[self.selectedImage scale] orientation:self.selectedImage.imageOrientation];
    
//    imageTemp =[UIImage imageWithCGImage:self.selectedImage.CGImage];
//    Y_MIN  = 20;
//    Y_MAX  = 180;//255;
//    Cr_MIN = 60;//133;
//    Cr_MAX = 173;//173;
//    Cb_MIN = 60;//77;
//    Cb_MAX = 255;//127;
    Y_MIN  = 0;
    Y_MAX  = 255;
    Cr_MIN = 130;//140
    Cr_MAX = 195;//165 low cr, high cb for dark skin
    Cb_MIN = 77;//105
    Cb_MAX = 135;//135
    CGRect frame = CGRectMake(0, 0, 125, 40);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:18.0];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = @"create";
    self.navigationItem.titleView = label;
    NSDictionary *attrs = @{ NSFontAttributeName : [UIFont systemFontOfSize:18] };
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:attrs forState:UIControlStateNormal];
    defaults = [NSUserDefaults standardUserDefaults];
    if (!IS_TALL_SCREEN) {
        self.designViewContainer.frame = CGRectMake(0, 320, 320, 480-64-320);  // for 3.5 screen; remove autolayout
        self.designViewContainer.contentSize = CGSizeMake(self.designViewContainer.frame.size.width, 184);
    }
    [self fillFrameSelectionSlider];
    [self fillSecondFrameSelectionSlider];
    [self fillEffectsSlider];
    [self fillSecondEffectsSlider];
    [self fillRotateMenu];
    [self fillSplitMenu];
    [self resetGestureParameters ];
    
    if ([defaults boolForKey:@"watermark"]) //if 0 then watermark is ON
        _watermarkOnImage.hidden=YES;
    
    if ([defaults boolForKey:@"white"])
        _frameContainer.backgroundColor=[UIColor blackColor];

    nMargin = (int)[defaults integerForKey:@"Split"];
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        nMargin = 0;
        [defaults setInteger:0 forKey:@"Split"];
        sliderSplit.value = nMargin;
    });

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag=(int)[defaults integerForKey:@"frame"];
    NSLog(@"VDL btn.tag is %d",(int)btn.tag);
    btn.tag=1; 

//    if (btn.tag==0 || btn.tag > 25+35) btn.tag = 1;
    [self frameClicked:btn];
    [self frameClicked:btn];
    [self filtersButton:self];

    firstTimeDesign = YES;


}
- (void) startActivityIndicator {
    //Start Activity Indicator View
    indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicatorView.frame = CGRectMake(40.0, 20.0, 60.0, 60.0);
    indicatorView.center = self.view.center;
    indicatorView.backgroundColor = [UIColor colorWithRed:255./255 green:131./255 blue:0.0 alpha:1.0];
    
    // border radius
    [indicatorView.layer setCornerRadius:5.0f];
    
    // border
    [indicatorView.layer setBorderColor:[UIColor blackColor].CGColor];
    [indicatorView.layer setBorderWidth:1.5f];
    
    // drop shadow
    [indicatorView.layer setShadowColor:[UIColor blackColor].CGColor];
    [indicatorView.layer setShadowOpacity:0.8];
    [indicatorView.layer setShadowRadius:3.0];
    [indicatorView.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    
    [self.view addSubview:indicatorView];
    //    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [indicatorView startAnimating];
}
- (void) randomFilterPick {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//    int number = [defaults integerForKey:@"number"];
//    NSLog(@"number is %d",number);

//    btn.tag = number;
//    btn.tag = 9;  //test
//    tapBlockNumber=1;
//    [self effectsClicked:btn];

//    btn.tag = number;
    btn.tag = 9;  //test
    tapBlockNumber=3;
    [self effectsClicked:btn];

    tapBlockNumber=1;
//    number ++;
//    [defaults setInteger:number forKey:@"number"];

}
- (void) resetGestureParameters {
    
    
    [defaults setFloat:0.0f forKey:@"PanX"];
    [defaults setFloat:0.0f forKey:@"PanY"];
    [defaults setFloat:0.0f forKey:@"Rotate"];
    [defaults setFloat:1.0f forKey:@"Zoom"];
    [defaults setBool:NO forKey:@"Flip"];
    
}
- (void)viewDidAppear:(BOOL)animated   {
    [super viewDidAppear:NO];
//    if (firstTimeDesign)
//    {
//        if (![defaults boolForKey:@"filter"])
//            [self randomFilterPick];
//    }
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}
- (void) viewWillAppear:(BOOL)animated {
    if (!firstTimeDesign){
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag=(int)[defaults integerForKey:@"frame"];
        NSLog(@"VWA btn.tag is %d; nstyle = %d, nsubstyle = %d",(int)btn.tag, nStyle,nSubStyle);
        NSLog(@"blockslider vWA subview count = %lu", (unsigned long)blockSlider1.subviews.count);

        [self resizeFrames];
    }

}

-(void)frameAction
{
    UIActionSheet *popupQuery;
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Move + Frames Pack",@"Buy for $0.99",nil];
    popupQuery.tag=0;
    [popupQuery showInView:self.view];
}

-(void)filterAction
{
    UIActionSheet *popupQuery;
    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Get more Filters",@"Buy for $0.99",nil];
    popupQuery.tag=1;
    [popupQuery showInView:self.view];
}

//-(void)resizeAction
//{
//    UIActionSheet *popupQuery;
//    popupQuery = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"cancel" destructiveButtonTitle:nil otherButtonTitles:@"resize to create frames",@"buy for $0.99",nil];
//    popupQuery.tag=2;
//    [popupQuery showInView:self.view];
//}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
        if (buttonIndex==1){
            [self inAppBuyAction:(int)actionSheet.tag];
        }
}

- (void)inAppBuyAction:(int)tag {
    [Flurry logEvent:@"InApp Watermark"];
    
    NSLog(@"buying...");
    
        [[MKStoreManager sharedManager] buyFeature:kFeature2
                                        onComplete:^(NSString* purchasedFeature,
                                                     NSData* purchasedReceipt,
                                                     NSArray* availableDownloads)
         {
             NSLog(@"Purchased: %@, available downloads is %@ watermark ", purchasedFeature, availableDownloads );
    
    
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Successful" message:nil
                                                            delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
             [defaults setBool:YES  forKey:kFeature2];
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
    for (int i = 0; i <= 3; i++) {
        UIImageView *imageView= (UIImageView *)[self.frameContainer viewWithTag:200+i];
        [imageView removeFromSuperview];
    }

    if ([[segue identifier] isEqualToString:@"doneDesign"])
    {
        firstTimeDesign=NO;
        doneViewController *vc = [segue destinationViewController];
        vc.image = [self captureImage];
    }
}

- (UIImage *) captureScreenshot {
    CGRect rect = _frameContainer.frame;//[[UIScreen mainScreen] bounds];
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 2.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [_frameContainer.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
- (UIImage *) captureView : (UIView *) captureView {
    CGRect rect = captureView.bounds;//[[UIScreen mainScreen] bounds];
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [captureView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
- (UIImage *) captureImageFromView : (UIView *) captureView {
    
//    UIView* captureView = self.frameContainer;
    
    /* Capture the screen shoot at native resolution */
    UIGraphicsBeginImageContextWithOptions(captureView.bounds.size, YES, 0.0);
    [captureView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    return screenshot;
}
static inline double rad(double deg)
{
    return deg / 180.0 * M_PI;
}

- (UIImage *) skinDetect {
    cv::Mat frame=[self cvMatFromUIImage:self.selectedImage];
//    cv::Mat3b frame = frame1;
//    cv::Mat3b frame =cv::imread("ad.png");
    /* THRESHOLD ON HSV*/
    cvtColor(frame, frame, cv::COLOR_RGB2YCrCb);
    GaussianBlur(frame, frame, cv::Size(7,7), 1, 1);
    //medianBlur(frame, frame, 15);
    float test0, test1, test2;
    
    for(int r=0; r<frame.rows; ++r){
        for(int c=0; c<frame.cols; ++c){
            // 0<H<0.25  -   0.15<S<0.9    -    0.2<V<0.95
            

            test0 =frame.at<cv::Vec3b>(r,c).val[0];
            test1 =frame.at<cv::Vec3b>(r,c).val[1];
            test2 =frame.at<cv::Vec3b>(r,c).val[2];
//            NSLog(@"%f, %f, %f , rows = %d, cols = %d r = %d, c = %d", test0,test1,test2, frame.rows, frame.cols, r,c );

            
//            if( (frame.at<cv::Vec3b>(r,c).val[0]>5) && (frame.at<cv::Vec3b>(r,c).val[0] < 17) && (frame.at<cv::Vec3b>(r,c).val[1]>38) && (frame.at<cv::Vec3b>(r,c).val[1]<250) && (frame.at<cv::Vec3b>(r,c).val[2]>51) && (frame.at<cv::Vec3b>(r,c).val[2]<242) ); // do nothing
            if( (frame.at<cv::Vec3b>(r,c).val[0]>=0) && (frame.at<cv::Vec3b>(r,c).val[0] <=255) && (frame.at<cv::Vec3b>(r,c).val[1]>130) && (frame.at<cv::Vec3b>(r,c).val[1]<180) && (frame.at<cv::Vec3b>(r,c).val[2]>80) && (frame.at<cv::Vec3b>(r,c).val[2]<125) ){
//                NSLog(@"do nothing row = %d, col = %d ", r, c);

            }// do nothing
            else for(int i=0; i<3; ++i)	frame.at<cv::Vec3b>(r,c).val[i] = 0;
        }
    }
    NSLog(@"rows = %d, cols = %d ", frame.rows, frame.cols);

    /* BGR CONVERSION AND THRESHOLD */
    cv::Mat1b frame_gray;
    cvtColor(frame, frame, cv::COLOR_YCrCb2BGR);
    cvtColor(frame, frame_gray, cv::COLOR_BGR2GRAY);
    threshold(frame_gray, frame_gray, 60, 255, cv::THRESH_BINARY);
    morphologyEx(frame_gray, frame_gray, cv::MORPH_ERODE, cv::Mat1b(3,3,1), cv::Point(-1, -1), 3);
    morphologyEx(frame_gray, frame_gray, cv::MORPH_OPEN, cv::Mat1b(7,7,1), cv::Point(-1, -1), 1);
    morphologyEx(frame_gray, frame_gray, cv::MORPH_CLOSE, cv::Mat1b(9,9,1), cv::Point(-1, -1), 1);
    
    medianBlur(frame_gray, frame_gray, 15);
//    imshow("Threshold", frame_gray);
    
//    cvtColor(frame, frame, cv::COLOR_BGR2YCrCb);
    cv::resize(frame, frame, cv::Size(), 0.5, 0.5);
    cvtColor(frame, frame, cv::COLOR_YCrCb2RGB);

    return [self UIImageFromCVMat:frame];
}

UIImage* UIImageCrop(UIImage* img, CGRect rect)
{
    CGAffineTransform rectTransform;
    switch (img.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -img.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -img.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -img.size.width, -img.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    rectTransform = CGAffineTransformScale(rectTransform, img.scale, img.scale);
//    NSLog(@" untransformed rect = %@, scale = %f, orientation = %ld", NSStringFromCGRect(rect), img.scale, img.imageOrientation);
    CGImageRef imageRef = CGImageCreateWithImageInRect([img CGImage], CGRectApplyAffineTransform(rect, rectTransform));
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:img.scale orientation:img.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}


- (UIImage *) skinTone {
    // Convert the UIImage to a Mat
    cv::Mat inputMat = [self cvMatFromUIImage:self.selectedImage];
    cv::Mat converted;
    cv::Mat skinMask;
    cv::Mat temp;
    cv::Mat tmp;
    cv::Mat skinMat;
    cv::Mat kernel;
    cv::Mat grayMat;

    
    cvtColor(inputMat, converted, cv::COLOR_RGB2YCrCb);
    inRange(converted,cv::Scalar(Y_MIN,Cr_MIN,Cb_MIN),cv::Scalar(Y_MAX,Cr_MAX,Cb_MAX),skinMask);
    
    
    kernel = getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(11, 11));
    erode(skinMask, skinMask, kernel);
    dilate(skinMask, skinMask, kernel);

    
// blur the mask to help remove noise, then apply the
// mask to the frame
    GaussianBlur(skinMask, skinMask,cv::Size(3, 3), 0);
    cv::bitwise_and(inputMat, inputMat, skinMat, skinMask);
    
    // Convert back to a UIImage
    return [self UIImageFromCVMat:skinMat];

}


- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    // If the image is in black and white
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else { // If it's a color image
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}
- (UIImage *) cropImageWithView :(UIView *) captureView {

    CGRect rect=CGRectMake(captureView.frame.origin.x/scaleView, captureView.frame.origin.y/scaleView, captureView.frame.size.width/scaleView, captureView.frame.size.height/scaleView);
    // Create bitmap image from original image data,
    // using rectangle to specify desired crop area
    CGImageRef imageRef = CGImageCreateWithImageInRect([self.selectedImage CGImage], rect);
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);


//    // Create and show the new image from bitmap data
//    imageView = [[UIImageView alloc] initWithImage:img];
//    [imageView setFrame:CGRectMake(0, 200, (size.width / 2), (size.height / 2))];
//    [[self view] addSubview:imageView];
    return img;
}

- (UIImage *) captureImage {
    
    UIView* captureView = self.frameContainer;
    
    /* Capture the screen shoot at native resolution */
    UIGraphicsBeginImageContextWithOptions(captureView.bounds.size, captureView.opaque, 0.0);
    [captureView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    /* Render the screen shot at custom resolution */
    CGRect cropRect;
    if ([defaults integerForKey:@"pixel"]==1)
        cropRect= CGRectMake(0 ,0 ,640,640);
    else if ([defaults integerForKey:@"pixel"]==0)
        cropRect= CGRectMake(0 ,0 ,1280,1280);
    else if ([defaults integerForKey:@"pixel"]==2)
        cropRect= CGRectMake(0 ,0 ,2560,2560);

    UIGraphicsBeginImageContextWithOptions(cropRect.size, captureView.opaque, 1.0f);
    [screenshot drawInRect:cropRect];
    UIImage * customScreenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return customScreenShot;
}
- (UIImage*)captureYourView:(UIView *)yourView {
//    CGRect rect = [[UIScreen mainScreen] bounds];
    UIGraphicsBeginImageContext(blockSlider1.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [yourView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
- (UIImage *) captureImageFromButton : (UIButton *) captureView{
//    UIView* captureView = self.frameContainer;
    
    /* Capture the screen shoot at native resolution */
    UIGraphicsBeginImageContextWithOptions(captureView.bounds.size, captureView.opaque, 0.0);
    [captureView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    /* Render the screen shot at custom resolution */
    CGRect cropRect=CGRectMake(0 ,0 ,100,100);
    
    UIGraphicsBeginImageContextWithOptions(cropRect.size, captureView.opaque, 1.0f);
    [screenshot drawInRect:cropRect];
    UIImage * customScreenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return customScreenShot;
}
- (void) fillFrameSelectionSlider {
//    if (!IS_TALL_SCREEN)
//        self.frameSelectionBar.contentSize = CGSizeMake(52 * 6, self.frameSelectionBar.frame.size.height);
//    else
//        self.frameSelectionBar.contentSize = CGSizeMake(70 * 6, 151);
    for (int ind = 1; ind <= 6; ind++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        if (!IS_TALL_SCREEN)
//            btn.frame = CGRectMake((ind - 1) * 52+6, 7, 46, 46);
//        else
            btn.frame = CGRectMake((ind - 1 ) * 52+6, 7, 46, 46);

        btn.tag = ind;
        btn.layer.borderWidth=kBorderWidth;
        btn.layer.borderColor=[[UIColor clearColor] CGColor];
        [btn addTarget:self action:@selector(frameClicked:) forControlEvents:UIControlEventTouchUpInside];
        NSLog(@"Frame%02d.png",ind);
        
        [btn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Frame%02d.png",ind]] forState:UIControlStateNormal];
        btn.alpha = 0.4;
        [btn.imageView setContentMode:UIViewContentModeScaleToFill];

        [self.frameSelectionBar addSubview:btn];
    }

}

- (void) fillSecondFrameSelectionSlider {
    for (int ind = 1; ind <= 6; ind++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        if (!IS_TALL_SCREEN)
//            btn.frame = CGRectMake((ind - 1 ) *52+6, 46+7+7, 46, 46);
//        else
            btn.frame = CGRectMake((ind - 1 ) *52+6, 46+7+7, 46, 46);
        btn.tag = ind+6;
        btn.layer.borderWidth=kBorderWidth;
        btn.layer.borderColor=[[UIColor clearColor] CGColor];
        [btn addTarget:self action:@selector(frameClicked:) forControlEvents:UIControlEventTouchUpInside];
        NSLog(@"secondFrame%02d.png",ind);
        [btn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"secondFrame%02d.png",ind]] forState:UIControlStateNormal];
        [btn.imageView setContentMode:UIViewContentModeScaleToFill];
        btn.alpha = 0.4;
        [self.frameSelectionBar addSubview:btn];   
    }
}

- (void)frameClicked:(UIButton *)clickedBtn
{
//    [self closeBtnClicked];
//    resizeOn=NO;

    [defaults setInteger:clickedBtn.tag forKey:@"frame"];
    
    for (int i = 1; i <= 12; i++) {
        UIButton *frameButton = (UIButton *)[_frameSelectionBar viewWithTag:i];
        frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
    }
    
    clickedBtn.layer.borderColor=[[UIColor redColor] CGColor];
    
    switch (clickedBtn.tag) {
        case 1:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:1];
            break;
        case 2:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:2];
            break;
        case 3:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:3];
            break;
        case 4:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:4];
            break;
        case 5:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:5];
            break;
        case 6:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:6];
            break;
        case 7:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:7];
          
            break;
        case 8:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:8];
            break;
        case 9:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:9];
            break;
        case 10:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:10];
            break;
        case 11:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:11];
            break;
            
        case 12:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:12];
            break;

        default:
            [self resetAdjustedValues];
            [self selectFrame:1 SUB:1];

            break;
    }
}
- (void)secondFrameClicked:(UIButton *)clickedBtn
{
    
    [defaults setInteger:clickedBtn.tag forKey:@"frame"];
    [self closeBtnClicked];
    resizeOn=NO;
//    if (![defaults boolForKey:kFeature0]){
//        [self frameAction];
//        return;
//    }
        for (int i = 1; i <= 24; i++) {
            UIButton *frameButton = (UIButton *)[_frameSelectionBar viewWithTag:i];
            frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
        }
        clickedBtn.layer.borderColor=[[UIColor redColor] CGColor];

        switch (clickedBtn.tag-12) {
            case 1:
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:13];
                break;
            case 2: 
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:14];
                break;
            case 3:
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:15];
                break;
            case 4:
                
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:16];
                break;
                
            case 5:
                
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:17];
                break;
            case 6:
                
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:18];
                break;
            case 7:
                
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:19];
                break;
            case 8:
                
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:20];
                break;
                
            case 9:
                
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:21];
                break;

            case 10:
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:22];
                break;
                
            case 11:
                
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:23];
                break;

            case 12:
                
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:24];
                break;

                
            default:
                [self resetAdjustedValues];
                [self selectFrame:1 SUB:13];
                break;
        }
}

- (UIImage *) cropImage: (UIImage *) image {
    CGRect rect = CGRectMake(0,0,65,65);
    UIGraphicsBeginImageContext( rect.size );
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}

- (void) fillEffectsSlider {
    labelEffectsArray = [[NSMutableArray alloc]initWithObjects: @"original", @"delight", @"sunny",@"night", @"beach",@"b&w+",nil];
    labelSecondEffectsArray = [[NSMutableArray alloc]initWithObjects: @"sepia",@"warm", @"b&w",@"morning", @"bleach",@"2layer",nil];

//    if (!IS_TALL_SCREEN)
//        self.filterSelectionBar.contentSize = CGSizeMake(55 * 11+10, self.frameSelectionBar.frame.size.height);
//    else
//        self.filterSelectionBar.contentSize = CGSizeMake(70 * 11+10, 151);
    
    
    for (int ind = 1; ind <= 6; ind++) {
     
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake((ind - 1 ) *52+6, 7, 46, 46);

//        if (!IS_TALL_SCREEN)
//            btn.frame = CGRectMake((ind - 1 ) * 55+5, 5, 50, 50);
//        else
//            btn.frame = CGRectMake((ind - 1 ) * 70+5, 5, 65, 65);

        btn.tag = ind;
        [btn setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 13.0, 0.0)];
        btn.layer.frame = btn.frame;
        btn.layer.borderWidth=kBorderWidth;
        btn.layer.borderColor=[[UIColor clearColor] CGColor];
        NSLog(@"effects btn.tag is %d ",(int)btn.tag);
        [btn addTarget:self action:@selector(effectsClicked:) forControlEvents:UIControlEventTouchUpInside];
        CGRect labelEffects;
        labelEffects = CGRectMake((ind - 1 ) * 52+6+kBorderWidth, 43-kBorderWidth, 46-2*kBorderWidth, 13);
//        if (!IS_TALL_SCREEN)
//            labelEffects = CGRectMake((ind - 1 ) * 55+5+kBorderWidth, 42-kBorderWidth, 50-2*kBorderWidth, 13);
//        else
//            labelEffects = CGRectMake((ind - 1 ) * 70+5+kBorderWidth, 57-kBorderWidth, 65-2*kBorderWidth, 13);

        UILabel *label = [[UILabel alloc] initWithFrame:labelEffects];
        label.backgroundColor = [UIColor lightGrayColor];
        label.alpha=0.8;
//            if (!IS_TALL_SCREEN)
                label.font = [UIFont boldSystemFontOfSize:10.0];
//            else
//                label.font = [UIFont boldSystemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.text = [labelEffectsArray objectAtIndex:ind-1];
        label.layer.shadowOffset=CGSizeMake(1, 1);
        label.layer.shadowColor= [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 0.8;

        [btn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"filter%02d.png",ind]] forState:UIControlStateNormal];
        [btn.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.filterSelectionBar addSubview:btn];
        [self.filterSelectionBar addSubview:label];
        }
}


- (void) fillSecondEffectsSlider {

    for (int ind = 1; ind <= 6; ind++) {
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        if (!IS_TALL_SCREEN)
//            btn.frame = CGRectMake((ind - 1 ) * 55+5, 60, 50, 50);
//        else
//            btn.frame = CGRectMake((ind - 1 ) * 70+5, 75, 65, 65);
        btn.frame = CGRectMake((ind - 1 ) *52+6, 46+7+7, 46, 46);

        btn.tag = ind+6;
        btn.layer.borderWidth=kBorderWidth;
        btn.layer.borderColor=[[UIColor clearColor] CGColor];
        [btn setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 13.0, 0.0)];
        NSLog(@" second effects btn.tag is %d ",(int)btn.tag);
        [btn addTarget:self action:@selector(effectsClicked:) forControlEvents:UIControlEventTouchUpInside];
        CGRect labelEffects;
        labelEffects = CGRectMake((ind - 1 ) * 52+6+kBorderWidth, 46+7+43-kBorderWidth, 46-2*kBorderWidth, 13);
//        if (!IS_TALL_SCREEN)
//            labelEffects = CGRectMake((ind - 1 ) * 55+5+kBorderWidth, 52+45-kBorderWidth, 50-2*kBorderWidth, 13);
//        else
//            labelEffects = CGRectMake((ind - 1 ) * 70+5+kBorderWidth, 75+65-13-kBorderWidth, 65-2*kBorderWidth, 13);
        UILabel *label = [[UILabel alloc] initWithFrame:labelEffects];
        label.backgroundColor = [UIColor lightGrayColor];
        label.alpha=0.8;
//            if (!IS_TALL_SCREEN)
                label.font = [UIFont boldSystemFontOfSize:10.0];
//            else
//                label.font = [UIFont boldSystemFontOfSize:12.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.text = [labelSecondEffectsArray objectAtIndex:ind-1];
        label.layer.shadowOffset=CGSizeMake(1, 1);
        label.layer.shadowColor= [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 0.8;
        [btn setImage:[UIImage imageNamed:[NSString stringWithFormat:@"filter%02d.png",ind+6]] forState:UIControlStateNormal];
        [btn.imageView setContentMode:UIViewContentModeScaleAspectFill];

        [self.filterSelectionBar addSubview:btn];
        [self.filterSelectionBar addSubview:label];

    }
}
- (void) saveImage : (UIImage *)image {
    NSLog(@"image is %@, image width is %f",image, image.size.width);
    
    CGImageRef img = [image CGImage];
    [library writeImageToSavedPhotosAlbum:img
                                 metadata:nil
                          completionBlock:nil];
}

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (void)edgeDilationClosing {

    UIView *tempView = [[UIView alloc] initWithFrame:blockSlider1.frame];
    int i=0;
    for (UIImageView *imageView in blockSlider1.subviews){
//        if (blockSlider.tag == tapBlockNumber){
        NSLog(@"blockslider subview count = %lu", (unsigned long)blockSlider1.subviews.count);
            if (blockSlider1.subviews.count<2) return;
//        UIImageView *imageView = faceFeature.subviews[0];
        i++;
        if (i>1 && [imageView isKindOfClass:[UIImageView class]] && imageView.tag >= 100) {
            NSLog(@"i=%d",i);
            UIImage *inputImage = [[UIImage alloc] initWithCGImage:[imageView.image CGImage]];
//            for (int i=0;i<[self.originalImages count];i++){
//                if ( (i == imageView.tag) && imageView.image ){
//                    UIImage *inputImage = self.selectedImage;
//                    switch (clickedBtn.tag) {
//                        case 1:{
                            GPUImageSobelEdgeDetectionFilter *filter = [[GPUImageSobelEdgeDetectionFilter alloc] init]; //original
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageFilter alloc] init]; //original
//                        } break;
//                        case 2: {
                          GPUImageDilationFilter*  filter2 = [[GPUImageDilationFilter alloc] init];
//                            GPUImageiOSBlurFilter * filter = [[GPUImageiOSBlurFilter alloc] init];
                            UIImage *quickFilteredImage2 = [filter2 imageByFilteringImage:quickFilteredImage];
        GPUImageClosingFilter*  filter3 = [[GPUImageClosingFilter alloc] init];
        //                            GPUImageiOSBlurFilter * filter = [[GPUImageiOSBlurFilter alloc] init];
        UIImage *finalImage = [filter3 imageByFilteringImage:quickFilteredImage2];
//                            imageView.image=finalImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_amatorka.png"];
//                        } break;
//                        case 3: {
//                           GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
////                            GPUImageSobelEdgeDetectionFilter *filter= [[GPUImageSobelEdgeDetectionFilter alloc] init];
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
//                        } break;
//                        case 10: {
//                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
//                            
////                            GPUImageRGBClosingFilter *filter = [[GPUImageRGBClosingFilter alloc] init];
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
//                        } break;
//                        case 11: {
//                           GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
////                            GPUImagePinchDistortionFilter *filter = [[GPUImagePinchDistortionFilter alloc] init];
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
//                        } break;
//                        case 4:{
//                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
////                            GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
//                        } break;
//                        case 5: {
//                           GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
////                            GPUImageSmoothToonFilter *filter = [[GPUImageSmoothToonFilter alloc] init];
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
//                        } break;
//                        case 6: {
//                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
////                            GPUImageGlassSphereFilter *filter = [[GPUImageGlassSphereFilter alloc] init];
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
//                        } break;
//                        case 7: {
//                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
////                            GPUImageSepiaFilter *filter = [[GPUImageSepiaFilter alloc] init];
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            quickFilteredImage=nil;
////                            filter=nil;
////                            [filter removeAllTargets];
////                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
//                        } break;
//                        case 8: {
//                            GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
////                            GPUImageColorInvertFilter *filter = [[GPUImageColorInvertFilter alloc] init];
//                            
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            quickFilteredImage=nil;
////                            filter=nil;
////                            [filter removeAllTargets];
////                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
//                        } break;
//                        case 9: {
//                            GPUImageGrayscaleFilter * filter = [[GPUImageGrayscaleFilter alloc] init];
//                            
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
////                            quickFilteredImage=nil;
////                            filter=nil;
////                            [filter removeAllTargets];
////                            videoFilter = [[GPUImageGrayscaleFilter alloc] init];
//                        } break;
//                        case 12:{
//                            GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
//                            //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
//                            
//                        } break;
//                        default:{
//                            GPUImageFilter *filter = [[GPUImageFilter alloc] init]; //original
//                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                            imageView.image=quickFilteredImage;
//                            
//                        }
//                            break;
//                    }
//            imageTemp=imageView.image;
//            CALayer *mask = [CALayer layer];
//            mask.contents = (id)[finalImage CGImage];
//            mask.frame = blockSlider1.frame;
////            [blockSlider1.layer addSublayer:mask]
//            blockSlider1.layer.mask=mask;
            UIImageView *imageView = [[UIImageView alloc] initWithImage:finalImage];
            [tempView addSubview:imageView];
//            [filter prepareForImageCapture];
//                    UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                    imageView.image=quickFilteredImage;
                    [filter removeAllTargets];
            [filter2 removeAllTargets];

            [filter3 removeAllTargets];

            
////                }
//            }
        }


    }
    UIImage *image = [self captureImageFromView:tempView];
    CALayer *mask = [CALayer layer];
    mask.contents = (id)[image CGImage];
    mask.frame = blockSlider1.frame;
    //            [blockSlider1.layer addSublayer:mask]
    blockSlider1.layer.mask=mask;
//    }
}
- (void)effectsClicked:(UIButton *)clickedBtn {

    [indicatorView stopAnimating];

    NSLog(@"block number %d",tapBlockNumber);
    if (!doneMarkingFaces) return;

    @autoreleasepool {
//        [defaults setInteger:clickedBtn.tag forKey:@"filter"];
        //    [  Flurry logEvent:@"Frame - Effects"];
        //    [labelToApplyFilterToVideo removeFromSuperview];
        if (tapBlockNumber==100) tapBlockNumber=0;
        //    AppRecord *app = [[AppRecord alloc] init];
        for (int i = 1; i <= 12; i++) {
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
//                UIImageView *imageView = blockSlider.subviews[0];
                UIImageView *imageView = [[UIImageView alloc] initWithImage:imageTemp];

                UIImage *inputImage = maskTemp;

                switch (clickedBtn.tag) {
                    case 1:{
                        GPUImageFilter *filter = [[GPUImageFilter alloc] init]; //original
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageFilter alloc] init]; //original
                    } break;
                    case 2: {
                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_amatorka.png"];
                        //                            GPUImageiOSBlurFilter * filter = [[GPUImageiOSBlurFilter alloc] init];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_amatorka.png"];
                    } break;
                    case 3: {
//                        GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"copperSepia2strip.png"];

                        GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
                        //                            GPUImageSobelEdgeDetectionFilter *filter= [[GPUImageSobelEdgeDetectionFilter alloc] init];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
                    } break;
                    case 4:{
                        GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
                        //                            GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
                    } break;
                    case 5: {
                        GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
//                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"gold2.png"];

                        //                            GPUImageSmoothToonFilter *filter = [[GPUImageSmoothToonFilter alloc] init];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
                    } break;
                    case 6: {
                        GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
                        //                            GPUImageGlassSphereFilter *filter = [[GPUImageGlassSphereFilter alloc] init];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
                    } break;
                    case 7: {
                        GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"copperSepia2strip.png"];

//                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"maximumWhite.png"];
//                        GPUImageToonFilter * filter = [[GPUImageToonFilter alloc] init];

//                        GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
                        //                            GPUImageSepiaFilter *filter = [[GPUImageSepiaFilter alloc] init];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            quickFilteredImage=nil;
                        //                            filter=nil;
                        //                            [filter removeAllTargets];
                        //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
                    } break;
                    case 8: {
//                                                GPUImageSharpenFilter * filter = [[GPUImageSharpenFilter alloc] init];
                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWarm.png"];

//                        GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
//                        GPUImageColorInvertFilter *filter = [[GPUImageColorInvertFilter alloc] init];
//                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"maximumWhite.png"];

                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            quickFilteredImage=nil;
                        //                            filter=nil;
                        //                            [filter removeAllTargets];
                        //                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
                    } break;
                    case 9: {
                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"maximumWhite.png"];

//                        GPUImageGrayscaleFilter * filter = [[GPUImageGrayscaleFilter alloc] init];

                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            quickFilteredImage=nil;
                        //                            filter=nil;
                        //                            [filter removeAllTargets];
                        //                            videoFilter = [[GPUImageGrayscaleFilter alloc] init];
                    } break;
                    case 10: {
                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
                        
                        //                            GPUImageRGBClosingFilter *filter = [[GPUImageRGBClosingFilter alloc] init];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
                    } break;
                    case 11: {
//                        GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"copperSepia2strip.png"];
                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarmBleach.png"];

//                                                GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
//                        GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fallcolors"];
                        
                        //                            GPUImagePinchDistortionFilter *filter = [[GPUImagePinchDistortionFilter alloc] init];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
                    } break;

                    case 12:{
                        GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
                        
                    } break;
                    default:{
                        GPUImageFilter *filter = [[GPUImageFilter alloc] init]; //original
                        UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                        imageView.image=quickFilteredImage;
                        
                    }
                        break;
                }
                imageTemp = imageView.image;
                UIImageView *originalImageView = blockSlider.subviews[0];

                GPUImageLightenBlendFilter *maskingFilter = [[GPUImageLightenBlendFilter alloc] init];  //this works!!

                GPUImagePicture * maskGpuImage = [[GPUImagePicture alloc] initWithImage:imageTemp ];
                GPUImagePicture *FullGpuImage = [[GPUImagePicture alloc] initWithImage:self.selectedImage ];
                // Image first, Mask next
                [FullGpuImage addTarget:maskingFilter];
                [FullGpuImage processImage];
                [maskingFilter useNextFrameForImageCapture];
                [maskGpuImage addTarget:maskingFilter];
                [maskGpuImage processImage];
                UIImage *OutputImage = [maskingFilter imageFromCurrentFramebuffer];

                originalImageView.image = OutputImage;

//                imageTemp=imageView.image;
                //            [filter prepareForImageCapture];
                //                    UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                //                    imageView.image=quickFilteredImage;
                //                    [filter removeAllTargets];
                
            }
        }
        
    }
    //    }
}
- (UIImage*) maskImage:(UIImage *) image withMask:(UIImage *) mask
{
    CGImageRef imageReference = image.CGImage;
    CGImageRef maskReference = mask.CGImage;
    
    CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(maskReference),
                                             CGImageGetHeight(maskReference),
                                             CGImageGetBitsPerComponent(maskReference),
                                             CGImageGetBitsPerPixel(maskReference),
                                             CGImageGetBytesPerRow(maskReference),
                                             CGImageGetDataProvider(maskReference),
                                             NULL, // Decode is null
                                             YES // Should interpolate
                                             );
    
    CGImageRef maskedReference = CGImageCreateWithMask(imageReference, imageMask);
    CGImageRelease(imageMask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedReference];
    CGImageRelease(maskedReference);
    
    return maskedImage;
}
- (void)secondEffectsClicked:(UIButton *)clickedBtn {

//    [Flurry logEvent:@"Frame - Second Effects"];
    @autoreleasepool {
//    if (![defaults boolForKey:kFeature1]){
//        [self filterAction];
//        return;
//    }
    NSLog(@"block number %d",tapBlockNumber);
    for (int i = 1; i <= 12; i++) {
        UIButton *frameButton = (UIButton *)[_filterSelectionBar viewWithTag:i];
        frameButton.layer.borderColor=[[UIColor clearColor] CGColor];
    }

    clickedBtn.layer.borderColor=[[UIColor blackColor] CGColor];
    for (UIScrollView *blockSlider in droppableAreas){
        if (blockSlider.tag == tapBlockNumber){
            
                
            if (blockSlider.subviews.count==0) return;
            UIImageView *imageView = blockSlider.subviews[0];
                    UIImage *inputImage = self.selectedImage;
                    switch (clickedBtn.tag-11) {
                        case 1:{
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
                            
                        } break;
                        case 2: {
                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarmBleach.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarmBleach.png"];
                            
                        } break;
                        case 3: {
                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWinter.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWinter.png"];
                            
                        } break;
                        case 9: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWarm.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"crispWarm.png"];
                            
                        } break;
                        case 10: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"candlelight.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"candlelight.png"];
                            
                        } break;
                        case 11:{
                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fallcolors.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fallcolors.png"];
                            
                        } break;
                        case 7: {
                          GPUImageAmatorkaFilter*   filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"filmstock.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"filmstock.png"];
                            
                        } break;
                            
                        case 13: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"foggynight.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"foggynight.png"];
                            
                        } break;
                        case 14: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cobalt2Iron80Bleach.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cobalt2Iron80Bleach.png"];
                            
                        } break;
                        case 15: {
                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"blue.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"blue.png"];
                            
                        } break;
                        case 16: {
                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fuji2393.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"fuji2393.png"];
                            
                        } break;
                        case 17: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleak.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleak.png"];
                            
                        } break;
                        case 18: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachMoonlight.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachMoonlight.png"];
                            
                        } break;
                        case 19: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cyanSeleniumBleachMoonlight.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"cyanSeleniumBleachMoonlight.png"];
                            
                        } break;
                        case 20: {
                            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarm.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"softWarm.png"];
                            
                        } break;
                        case 4: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"gold2.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"gold2.png"];
                            
                        } break;
                        case 5: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"platinum.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"platinum.png"];
                            
                        } break;
                        case 6: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"copperSepia2strip.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"copperSepia2strip.png"];
                            
                        } break;
                        case 12: {
                           GPUImageVignetteFilter* filter = [[GPUImageVignetteFilter alloc] init];
                            [(GPUImageVignetteFilter *) filter setVignetteEnd:0.6];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageVignetteFilter alloc] init];
//                            [(GPUImageVignetteFilter *) videoFilter setVignetteEnd:0.6];
                        } break;
                        case 8: {
                           GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"maximumWhite.png"];
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
//                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"maximumWhite.png"];
                            
                        } break;
                            
                        default:{
                            GPUImageFilter *filter = [[GPUImageFilter alloc] init]; //original
                            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
                            imageView.image=quickFilteredImage;
                            
                        }
                            break;
                    }
//                    UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
//                    [filter removeAllTargets];
//                    imageView.image=quickFilteredImage;
                }
        }
    }
}

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
- (IBAction)resizeButton:(id)sender {
    [Flurry logEvent:@"resize"];
    if (nStyle ==2){
        if (nSubStyle == 1  || nSubStyle == 10) {
            if (resizeOn){
                [self closeBtnClicked];
                resizeOn = NO;
            }
            else {
                [self addButtons];
                resizeOn = YES;
                NSLog(@"resizeButton ON");
            }
            return;
        }
    }
//    if (![defaults boolForKey:kFeature0]){
//        [self frameAction];
//        return;
//    }
    
    if (resizeOn){
        [self closeBtnClicked];
        resizeOn = NO;
    }
    else {
        [self addButtons];
        resizeOn = YES;
        NSLog(@"resizeButton ON");
    }

//    [self hideBars];
//    _splitMenuView.hidden=NO;
}
-(void)markFaces:(UIImageView *)facePicture
{
    // draw a CI image with the previously loaded face detection picture
    CIImage* image = [CIImage imageWithCGImage:facePicture.image.CGImage];
    
    // create a face detector - since speed is not an issue we'll use a high accuracy
    // detector
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
    
    // create an array containing all the detected faces from the detector
    NSArray* features = [detector featuresInImage:image];
    // we'll iterate through every detected face.  CIFaceFeature provides us
    // with the width for the entire face, and the coordinates of each eye
    // and the mouth if detected.  Also provided are BOOL's for the eye's and
    // mouth so we can check if they already exist.
//    int i=0;
//    UIView *tempView = [[UIView alloc] initWithFrame:blockSlider1.frame];

    for(CIFaceFeature* faceFeature in features)
    {
        
        // get the width of the face
        CGFloat faceWidth = faceFeature.bounds.size.width;
//        CGFloat faceHeight = faceFeature.bounds.size.height;
//        CGFloat faceOriginX = faceFeature.bounds.origin.x;
//        CGFloat faceOriginY = faceFeature.bounds.origin.y;
//        CGFloat bigFactor = 1.;

//        CGRect biggerFace = CGRectMake(faceOriginX - faceWidth*(bigFactor-1)/2, faceOriginY - faceWidth*(bigFactor-1)/2, faceWidth*bigFactor, faceHeight*bigFactor);
        // create a UIView using the bounds of the face
        UIView* faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        // add a border around the newly created UIView
//        faceView.layer.borderWidth = 5;
//        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        [faceView setFrame:CGRectMake(faceView.frame.origin.x*scaleView, faceView.frame.origin.y*scaleView, faceView.frame.size.width*scaleView, faceView.frame.size.height*scaleView)];
        // add the new view to create a box around the face

        [blockSlider1 addSubview:faceView];
//        [faceViews addObject:faceView];
        
    NSLog(@" scaleView = %f, image size = %f width, %f height, faceView rect = %@, faceFeature bounds = %@, blockSlider frame = %@", scaleView,self.selectedImage.size.width,self.selectedImage.size.height, NSStringFromCGRect(faceView.frame),  NSStringFromCGRect(faceFeature.bounds),NSStringFromCGRect(blockSlider1.frame));
        NSLog(@"blockslider 9 subview count = %lu", (unsigned long)blockSlider1.subviews.count);

        if(faceFeature.hasLeftEyePosition)
        {
            // create a UIView with a size based on the width of the face
            UIView* leftEyeView = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.leftEyePosition.x-faceWidth*0.15, faceFeature.leftEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3)];
            // change the background color of the eye view
//            [leftEyeView setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
            // set the position of the leftEyeView based on the face
            [leftEyeView setCenter:faceFeature.leftEyePosition];
            // round the corners
            leftEyeView.layer.cornerRadius = faceWidth*0.15;
            // add the view to the window
            [leftEyeView setFrame:CGRectMake(leftEyeView.frame.origin.x*scaleView, leftEyeView.frame.origin.y*scaleView, leftEyeView.frame.size.width*scaleView, leftEyeView.frame.size.width*scaleView)];
            [blockSlider1 addSubview:leftEyeView];
            
        }
        NSLog(@"blockslider 10 subview count = %lu", (unsigned long)blockSlider1.subviews.count);

        if(faceFeature.hasRightEyePosition)
        {
            // create a UIView with a size based on the width of the face
            UIView* leftEye = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.rightEyePosition.x-faceWidth*0.15, faceFeature.rightEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3)];
            // change the background color of the eye view
//            [leftEye setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
            // set the position of the rightEyeView based on the face
            [leftEye setCenter:faceFeature.rightEyePosition];
            // round the corners
            leftEye.layer.cornerRadius = faceWidth*0.15;
            // add the new view to the window
            [leftEye setFrame:CGRectMake(leftEye.frame.origin.x*scaleView, leftEye.frame.origin.y*scaleView, leftEye.frame.size.width*scaleView, leftEye.frame.size.width*scaleView)];

            [blockSlider1 addSubview:leftEye];
        }
        NSLog(@"blockslider 11 subview count = %lu", (unsigned long)blockSlider1.subviews.count);

        if(faceFeature.hasMouthPosition)
        {
            // create a UIView with a size based on the width of the face
            UIView* mouth = [[UIView alloc] initWithFrame:CGRectMake(faceFeature.mouthPosition.x-faceWidth*0.2, faceFeature.mouthPosition.y-faceWidth*0.2, faceWidth*0.4, faceWidth*0.4)];
            // change the background color for the mouth to green
//            [mouth setBackgroundColor:[[UIColor greenColor] colorWithAlphaComponent:0.3]];
            // set the position of the mouthView based on the face
            [mouth setCenter:faceFeature.mouthPosition];
            // round the corners
            mouth.layer.cornerRadius = faceWidth*0.2;
            // add the new view to the window
            [mouth setFrame:CGRectMake(mouth.frame.origin.x*scaleView, mouth.frame.origin.y*scaleView, mouth.frame.size.width*scaleView, mouth.frame.size.width*scaleView)];

            [blockSlider1 addSubview:mouth];
        }
        NSLog(@"blockslider 12 subview count = %lu", (unsigned long)blockSlider1.subviews.count);

    }
//    [tempView setTransform:CGAffineTransformMakeScale(1, -1)];
    [facePicture setTransform:CGAffineTransformMakeScale(1, -1)];
    // flip the entire window to make everything right side up
    NSLog(@"blockslider 13 subview count = %lu", (unsigned long)blockSlider1.subviews.count);
    
//    CALayer *mask = [CALayer layer];
//    UIImage *image10 = [self captureYourView:tempView];
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:image10];
    maskTemp=[self skinTone];

    

//    [blockSlider2 setTransform:CGAffineTransformMakeScale(1, -1)];
    [blockSlider1 setTransform:CGAffineTransformMakeScale(1, -1)];
    NSLog(@"Done Marking Faces");
    doneMarkingFaces = YES;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];

        btn.tag=9;//black and white
    //    tapBlockNumber=0;
    if (![defaults boolForKey:@"filter"])
        [self effectsClicked:btn];
  
}

-(void)faceDetector
{
    // Load the picture for face detection
    image1 = [[UIImageView alloc] initWithImage:self.selectedImage];
    
    // Draw the face detection image
//    [blockSlider1 addSubview:image1];

    // Execute the method used to markFaces in background
    [self performSelectorInBackground:@selector(markFaces:) withObject:image1];
//    [image1 setTransform:CGAffineTransformMakeScale(1, -1)];

//    [blockSlider1 addSubview:image1];

    // flip image on y-axis to match coordinate system used by core image
    [image1 setTransform:CGAffineTransformMakeScale(1, -1)];
    // flip the entire window to make everything right side up
    [blockSlider1 setTransform:CGAffineTransformMakeScale(1, -1)];
    
    
}
- (void) selectFrame:(int)style SUB:(int)sub
{
    if (!firstTime){
        droppableAreas = [[NSMutableArray alloc] init];
        firstTime = YES;
//        nStyle= 4;
//        nSubStyle = 1;
        rectBlockSlider1 = [self getScrollFrame1:style subStyle:sub];
//        rectBlockSlider2 = [self getScrollFrame1:style subStyle:sub];
//        rectBlockSlider3 = [self getScrollFrame3:style subStyle:sub];
//        rectBlockSlider4 = [self getScrollFrame4:style subStyle:sub];
        blockSlider1 = [[UIScrollView alloc] initWithFrame:rectBlockSlider1];
//        blockSlider2 = [[UIScrollView alloc] initWithFrame:rectBlockSlider2];
//        blockSlider3 = [[UIScrollView alloc] initWithFrame:rectBlockSlider3];
//        blockSlider4 = [[UIScrollView alloc] initWithFrame:rectBlockSlider4];
        blockSlider1.scrollEnabled=NO;
//        blockSlider2.scrollEnabled=NO;
//        blockSlider3.scrollEnabled=NO;
//        blockSlider4.scrollEnabled=NO;
        blockSlider1.tag = 0;
//        blockSlider2.tag = 1;
//        blockSlider3.tag = 2;
//        blockSlider4.tag = 3;
        [blockSlider1.layer setBorderColor:[[UIColor clearColor] CGColor]];
        [blockSlider1.layer setBorderWidth:kBlockWidth];
   
        
        [self.frameContainer addSubview:blockSlider1];
//        [self.frameContainer addSubview:blockSlider2];
//        [self.frameContainer addSubview:blockSlider3];
//        [self.frameContainer addSubview:blockSlider4];
        [droppableAreas addObject:blockSlider1];
//        [droppableAreas addObject:blockSlider2];
//        [droppableAreas addObject:blockSlider3];
//        [droppableAreas addObject:blockSlider4];
        
//        UITapGestureRecognizer *tapBlock = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBlock:)];
//        tapBlock.numberOfTapsRequired = 1;
//        [tapBlock setDelegate:self];
//        [self.frameContainer addGestureRecognizer:tapBlock];

        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchImage:)];
        pinchGesture.delegate=self;
        [self.frameContainer addGestureRecognizer:pinchGesture];
        
        if ([defaults boolForKey:@"pan"]){
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanImage:)];
            panGesture.delegate=self;
            [self.frameContainer addGestureRecognizer:panGesture];
        }

//        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanImage:)];
//        panGesture.delegate=self;
//        [self.frameContainer addGestureRecognizer:panGesture];
        [self.frameContainer bringSubviewToFront:_watermarkOnImage];
//        [self faceDetector];

    }
    else {
        nStyle = style;
        nSubStyle = sub;
        NSLog(@" nstyle = %d, nsubstyle = %d", nStyle,nSubStyle);

        [self resizeFrames];
    }
}

- (void) resizeFrames {

//    for (UIScrollView *blockSlider in droppableAreas){
        blockSlider1.layer.mask=nil;
//    blockSlider2.layer.mask=nil;

//        }
    for (UIImageView *imageView in blockSlider1.subviews){
             [imageView removeFromSuperview];
    }
//    for (UIImageView *imageView in blockSlider2.subviews){
//        [imageView removeFromSuperview];
//    }
    NSLog(@"blockslider 1 subview count = %lu", (unsigned long)blockSlider1.subviews.count);

        image1 = [[UIImageView alloc] initWithImage:self.selectedImage];
        [blockSlider1 addSubview:image1];
    NSLog(@"blockslider 2 subview count = %lu", (unsigned long)blockSlider1.subviews.count);

            [self fitImageToScroll:image1 SCROLL:blockSlider1 scrollViewNumber:blockSlider1.tag angle:[defaults floatForKey:@"Rotate"]+sliderRotate.value];
    NSLog(@"blockslider 3 subview count = %lu", (unsigned long)blockSlider1.subviews.count);
//    image2 = [[UIImageView alloc] initWithImage:self.selectedImage];
//    [blockSlider2 addSubview:image2];
//    NSLog(@"blockslider 2 subview count = %lu", (unsigned long)blockSlider2.subviews.count);
//    
//    [self fitImageToScroll:image2 SCROLL:blockSlider2 scrollViewNumber:blockSlider2.tag angle:[defaults floatForKey:@"Rotate"]+sliderRotate.value];
    [self performSelectorInBackground:@selector(markFaces:) withObject:image1];
    //    [image1 setTransform:CGAffineTransformMakeScale(1, -1)];
    
    //    [blockSlider1 addSubview:image1];
    

}
- (void) resizeFramesWithoutFilter {
    
    //    for (UIScrollView *blockSlider in droppableAreas){
    blockSlider1.layer.mask=nil;
    
    //        if (blockSlider.tag == 0) {
    rectBlockSlider1 = [self getScrollFrame1:nStyle subStyle:nSubStyle];
    blockSlider1.frame = rectBlockSlider1;

    for (UIImageView *imageView in blockSlider1.subviews){
        [imageView removeFromSuperview];
    }
    image1 = [[UIImageView alloc] initWithImage:self.selectedImage];
    [blockSlider1 addSubview:image1];
    
    [self fitImageToScroll:image1 SCROLL:blockSlider1 scrollViewNumber:blockSlider1.tag angle:[defaults floatForKey:@"Rotate"]+sliderRotate.value];
    

    [self reFilterImage:[defaults integerForKey:@"filter"] :image1];

}
- (void) reFilterImage : (NSInteger) tag : (UIImageView *) imageView{
   
     @autoreleasepool {
    UIImage *inputImage = self.selectedImage;
    switch (tag) {
        case 1:{
            GPUImageFilter *filter = [[GPUImageFilter alloc] init]; //original
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageFilter alloc] init]; //original
        } break;
        case 2: {
            GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_amatorka.png"];
            //                            GPUImageiOSBlurFilter * filter = [[GPUImageiOSBlurFilter alloc] init];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_amatorka.png"];
        } break;
        case 3: {
            GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
            //                            GPUImageSobelEdgeDetectionFilter *filter= [[GPUImageSobelEdgeDetectionFilter alloc] init];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"02"];
        } break;
        case 10: {
            GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
            
            //                            GPUImageRGBClosingFilter *filter = [[GPUImageRGBClosingFilter alloc] init];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"lookup_miss_etikate.png"];
        } break;
        case 11: {
            GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
            //                            GPUImagePinchDistortionFilter *filter = [[GPUImagePinchDistortionFilter alloc] init];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"17"];
        } break;
        case 4:{
            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
            //                            GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"bleachNight"];
        } break;
        case 5: {
            GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
            //                            GPUImageSmoothToonFilter *filter = [[GPUImageSmoothToonFilter alloc] init];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"06"];
        } break;
        case 6: {
            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
            //                            GPUImageGlassSphereFilter *filter = [[GPUImageGlassSphereFilter alloc] init];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"BWhighContrastRed"];
        } break;
        case 7: {
            GPUImageAmatorkaFilter* filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
            //                            GPUImageSepiaFilter *filter = [[GPUImageSepiaFilter alloc] init];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            quickFilteredImage=nil;
            //                            filter=nil;
            //                            [filter removeAllTargets];
            //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"sepiaSelenium2"];
        } break;
        case 8: {
            GPUImageToneCurveFilter* filter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
            //                            GPUImageColorInvertFilter *filter = [[GPUImageColorInvertFilter alloc] init];
            
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            quickFilteredImage=nil;
            //                            filter=nil;
            //                            [filter removeAllTargets];
            //                            videoFilter = [[GPUImageToneCurveFilter alloc] initWithACV:@"aqua"];
        } break;
        case 9: {
            GPUImageGrayscaleFilter * filter = [[GPUImageGrayscaleFilter alloc] init];
            
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            quickFilteredImage=nil;
            //                            filter=nil;
            //                            [filter removeAllTargets];
            //                            videoFilter = [[GPUImageGrayscaleFilter alloc] init];
        } break;
        case 12:{
            GPUImageAmatorkaFilter*  filter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            //                            videoFilter = [[GPUImageAmatorkaFilter alloc] initWithString:@"2strip.png"];
            
        } break;
        default:{
            GPUImageFilter *filter = [[GPUImageFilter alloc] init]; //original
            UIImage *quickFilteredImage = [filter imageByFilteringImage:inputImage];
            imageView.image=quickFilteredImage;
            
        }
            break;
    }
     }
}

- (IBAction)handlePinchImage:(UIPinchGestureRecognizer *)sender {
    if (tapBlockNumber !=100){
        CGFloat factor = [(UIPinchGestureRecognizer *)sender scale];
        CGFloat factorVideo = [defaults floatForKey:@"Zoom"]*factor;
        if (factorVideo > kZoomMin && factorVideo < kZoomMax){
            for (UIScrollView *blockSlider in droppableAreas){
                    if (blockSlider.subviews.count==0) return;
                    UIImageView *imageView = blockSlider.subviews[0];
                    imageView.transform = CGAffineTransformScale(imageView.transform, factor, factor);
            }
            [defaults setFloat:factorVideo forKey:@"Zoom"];
            sliderZoom.value = factorVideo;
        }
        sender.scale = 1;
    }
    labelZoom.text = [NSString stringWithFormat:@"%.02f",sliderZoom.value];
    
}

- (IBAction)handlePanImage:(UIPanGestureRecognizer *)sender {

    CGPoint translation = [sender translationInView:self.view];

    CGFloat ptX = [defaults floatForKey:@"PanX"] + translation.x;
    CGFloat ptY = [defaults floatForKey:@"PanY"] + translation.y;
    [defaults setFloat:ptX forKey:@"PanX"];
    [defaults setFloat:ptY forKey:@"PanY"];

    for (UIScrollView *blockSlider in droppableAreas){
        NSLog(@"blockSlider is %@, count is %d",blockSlider,(int)blockSlider.subviews.count);
        if (blockSlider.subviews.count==0) return;
        UIImageView *imageView = blockSlider.subviews[0];
            imageView.center = CGPointMake(imageView.center.x + translation.x,
                                           imageView.center.y - translation.y);  //brightface - changed to '-' because the imageview is flipped
    }
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
}
- (void)centerImage {

    CGPoint translation;

    translation.x = -(self.selectedImage.size.width*scale - self.frameContainer.frame.size.width)/2;
    translation.y = -(self.selectedImage.size.height*scale - self.frameContainer.frame.size.height)/2;
    [defaults setFloat:translation.x forKey:@"PanX"];
    [defaults setFloat:translation.y forKey:@"PanY"];

    for (UIScrollView *blockSlider in droppableAreas){
        for (UIImageView *imageView in blockSlider.subviews){
            imageView.center = CGPointMake(imageView.center.x + translation.x,
                                           imageView.center.y + translation.y);
        }
    }
    NSLog(@"panX is %f",translation.x);
    NSLog(@"panY is %f",translation.y);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([gestureRecognizer isKindOfClass:[UIImageView class]])
        return YES;
    else
        return NO;
}



-(void) tapBlock :(UITapGestureRecognizer *)recognizer{
    if (resizeOn){
        [self closeBtnClicked];
        resizeOn = NO;
    }
//    [self closeBtnClicked];
//    resizeOn = NO;
//    for (UIScrollView *blockSlider in droppableAreas)
//        [blockSlider.layer setBorderColor:[[UIColor clearColor] CGColor]];
    
    for (UIScrollView *blockSlider in droppableAreas) {
        CGPoint tappedBlock = [recognizer locationInView:blockSlider];
        if ([blockSlider pointInside:tappedBlock withEvent:nil]) {
            tapBlockNumber = (int)blockSlider.tag;
            NSLog(@"tapblocknumber is %d",tapBlockNumber);
//            [blockSlider.layer setBorderColor:[[UIColor cyanColor] CGColor]];
        }
    }
//    [self addButtons];
    
    [UIView animateWithDuration:2.0
                     animations:^{
                         for (UIScrollView *blockSlider in droppableAreas){
                             if (blockSlider.tag == tapBlockNumber){
                                 CABasicAnimation *color = [CABasicAnimation animationWithKeyPath:@"borderColor"];
                                 // animate from red to blue border ...
                                 color.fromValue = (id)[UIColor clearColor].CGColor;
                                 color.toValue   = (id)[UIColor cyanColor].CGColor;
                                 // ... and change the model value
                                 color.duration = 1;
                                 [blockSlider.layer addAnimation:color forKey:@"AnimateFrame"];
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
    CGFloat rateScr;
    CGFloat rateImg;
    CGFloat rateWidth;
    CGFloat rateHeight;
//    if (scrView.frame.size.width > 0 && imgView.frame.size.width >0){
        rateScr = scrView.frame.size.height / scrView.frame.size.width;
        rateImg = imgView.frame.size.height / imgView.frame.size.width;
//    }
//    if (imgView.frame.size.width > 0 && imgView.frame.size.height > 0){
        rateWidth = scrView.frame.size.width / imgView.frame.size.width;
        rateHeight = scrView.frame.size.height / imgView.frame.size.height;
//    }
    NSLog(@"imgView is width=%f, height=%f, rateWidth is %f, rateHeight is %f",imgView.frame.size.width, imgView.frame.size.height,rateWidth,rateHeight);
    CGFloat rateFit = rateScr < rateImg ? rateWidth : rateHeight;
    rateFit = rateHeight > rateWidth? rateWidth : rateHeight;
    scaleView = rateFit;


    NSLog (@"rateFit is %f",rateFit);
    CGSize szImage = CGSizeMake(imgView.frame.size.width*rateFit, imgView.frame.size.height*rateFit);
    [imgView setFrame:CGRectMake(0.0, 0.0, szImage.width, szImage.height)];

    [scrView setContentSize:CGSizeMake(imgView.frame.size.width, imgView.frame.size.height)];
    CGPoint pt;

    pt.x = (imgView.frame.size.width - scrView.frame.size.width)/2;
    pt.y = (imgView.frame.size.height - scrView.frame.size.height)/2;
//    [imgView setFrame:CGRectMake(pt.x, pt.y, szImage.width, szImage.height)];

    NSLog(@"pt is x=%f and y=%f",pt.x, pt.y);
    NSLog(@"imageView  subview count = %lu", (unsigned long)imgView.subviews.count);

    [scrView setContentOffset:pt animated:NO];
    NSLog(@"blockslider 6 subview count = %lu", (unsigned long)scrView.subviews.count);
    
    NSLog(@"blockslider 7 subview count = %lu", (unsigned long)scrView.subviews.count);

}

- (void) fillRotateMenu {
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
    labelRotate.textColor = [UIColor lightGrayColor];
    labelRotate.font = [UIFont systemFontOfSize:12];
//    labelRotate.backgroundColor=[UIColor clearColor];
//    labelRotate.layer.shadowOffset=CGSizeMake(1, 1);
//    labelRotate.layer.shadowColor= [UIColor blackColor].CGColor;
//    labelRotate.layer.shadowOpacity = 0.8;
    [self.rotateMenuView addSubview:labelRotate];
    
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    resetButton.frame = CGRectMake(20*4+46*4+5, 57,  46, 46);
    [resetButton setTitle:@"reset" forState:UIControlStateNormal];
    resetButton.titleLabel.font = [UIFont systemFontOfSize:18];
    resetButton.backgroundColor=[UIColor lightGrayColor];
    resetButton.titleLabel.textColor= [UIColor whiteColor];
    [resetButton addTarget:self action:@selector(resetRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:resetButton];
    
    UIButton *minusAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    minusAngleButton.frame = CGRectMake(5, 57,  46, 46);
    minusAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [minusAngleButton setTitle:@"-10°" forState:UIControlStateNormal];
    minusAngleButton.backgroundColor=[UIColor lightGrayColor];
    [minusAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [minusAngleButton addTarget:self action:@selector(minusTenDegreeRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:minusAngleButton];
    
    UIButton *rightAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightAngleButton.frame = CGRectMake(51+20, 57,  46, 46);
    rightAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [rightAngleButton setTitle:@"90°" forState:UIControlStateNormal];
    rightAngleButton.backgroundColor=[UIColor lightGrayColor];
    [rightAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [rightAngleButton addTarget:self action:@selector(rightAngleRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:rightAngleButton];
    
    UIButton *plusAngleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    plusAngleButton.frame = CGRectMake(20*2+46*2+5, 57,  46, 46);
    plusAngleButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [plusAngleButton setTitle:@"10°" forState:UIControlStateNormal];
    plusAngleButton.backgroundColor=[UIColor lightGrayColor];
    [plusAngleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [plusAngleButton addTarget:self action:@selector(plusTenDegreeRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:plusAngleButton];
    
    UIButton *flipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    flipButton.frame = CGRectMake(20*3+46*3+5, 57,  46, 46);
    flipButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [flipButton setTitle:@"flip" forState:UIControlStateNormal];
    flipButton.backgroundColor=[UIColor lightGrayColor];
    [flipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [flipButton addTarget:self action:@selector(flip) forControlEvents:UIControlEventTouchUpInside];
    [self.rotateMenuView addSubview:flipButton];
    
}
- (void) fillSplitMenu {

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
    labelSplit.textColor = [UIColor lightGrayColor];
    labelSplit.font = [UIFont systemFontOfSize:12];
//    labelSplit.backgroundColor=[UIColor clearColor];
//    labelSplit.layer.shadowOffset=CGSizeMake(1, 1);
//    labelSplit.layer.shadowColor= [UIColor blackColor].CGColor;
//    labelSplit.layer.shadowOpacity = 0.8;
    [self.splitMenuView addSubview:labelSplit];
    
}
- (void) resetRotate {
        sliderRotate.value = 0.0;
        [defaults setFloat:sliderRotate.value forKey:@"Rotate"];
        CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
        for (UIScrollView *blockSlider in droppableAreas){
                if (blockSlider.subviews.count==0) return;
                UIImageView *imageView = blockSlider.subviews[0];
                imageView.transform = CGAffineTransformIdentity;
                imageView.transform = CGAffineTransformRotate(imageView.transform, M_PI);//brightface - added'M_PI' because of flipped imageview
                imageView.transform = CGAffineTransformScale(imageView.transform, -1,1);//brightface - added'FLIP' because of flipped imageview
                imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor,zoomFactor);



            [defaults setBool:NO forKey:@"Flip"];
        }
    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(sliderRotate.value)];
}

- (void)splitChanged:(id)sender {
    sliderSplit = (UISlider *)sender;
    nMargin = sliderSplit.value;
    [sliderSplit setValue:(int)(sliderSplit.value) animated:NO];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag=[defaults integerForKey:@"frame"];
    [self resizeFrames];
//    if (btn.tag <= 25)
//        [self frameClicked:btn];
//    else
//        [self secondFrameClicked:btn];
    [defaults setFloat:sliderSplit.value forKey:@"Split"];
    labelSplit.text = [NSString stringWithFormat:@"%.0f",sliderSplit.value];
}

- (void)rotateChanged:(id)sender {
    sliderRotate = (UISlider *)sender;
    CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
    CGFloat totalRotate = sliderRotate.value +[defaults floatForKey:@"Rotate"];
        for (UIScrollView *blockSlider in droppableAreas){
            if (blockSlider.subviews.count==0) return;
                UIImageView *imageView = blockSlider.subviews[0];
                imageView.transform = CGAffineTransformIdentity;
                imageView.transform = CGAffineTransformRotate(imageView.transform, M_PI);//brightface - added'M_PI' because of flipped imageview
                imageView.transform = CGAffineTransformScale(imageView.transform, -1,1);//brightface - added'FLIP' because of flipped imageview
                imageView.transform = CGAffineTransformRotate(imageView.transform, totalRotate);
                if ([defaults boolForKey:@"Flip"])
                    imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
                else
                    imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
        }
    totalRotate = fmodf(totalRotate, 2*M_PI);
//    [defaults setFloat:totalRotate forKey:@"Rotate"];

    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(totalRotate)];
}
- (void) rightAngleRotate {
    [Flurry logEvent:@"rightAngle"];
        CGFloat rotateAngle = [defaults floatForKey:@"Rotate"]+M_PI_2;
//        [defaults setFloat:rotateAngle forKey:@"Rotate"];
        CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
        for (UIScrollView *blockSlider in droppableAreas){
                if (blockSlider.subviews.count==0) return;
                UIImageView *imageView = blockSlider.subviews[0];
                imageView.transform = CGAffineTransformIdentity;
                imageView.transform = CGAffineTransformRotate(imageView.transform, M_PI);//brightface - added'M_PI' because of flipped imageview
                imageView.transform = CGAffineTransformScale(imageView.transform, -1,1);//brightface - added'FLIP' because of flipped imageview
                imageView.transform = CGAffineTransformRotate(imageView.transform, rotateAngle);
                if ([defaults boolForKey:@"Flip"])
                    imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
                else
                    imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
        }
        rotateAngle = fmodf(rotateAngle, 2*M_PI);
    [defaults setFloat:rotateAngle forKey:@"Rotate"];

    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(rotateAngle)];

}

- (void) plusTenDegreeRotate {
    [Flurry logEvent:@"plusTen"];

    CGFloat rotateAngle = [defaults floatForKey:@"Rotate"]+M_PI_2/9;
//    [defaults setFloat:rotateAngle forKey:@"Rotate"];
    CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
    for (UIScrollView *blockSlider in droppableAreas){
            if (blockSlider.subviews.count==0) return;
            UIImageView *imageView = blockSlider.subviews[0];
            imageView.transform = CGAffineTransformIdentity;
            imageView.transform = CGAffineTransformRotate(imageView.transform, M_PI);//brightface - added'M_PI' because of flipped imageview
            imageView.transform = CGAffineTransformScale(imageView.transform, -1,1);//brightface - added'FLIP' because of flipped imageview
            imageView.transform = CGAffineTransformRotate(imageView.transform, rotateAngle);
            if ([defaults boolForKey:@"Flip"])
                imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
            else
                imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
    }
    rotateAngle = fmodf(rotateAngle, 2*M_PI);
    [defaults setFloat:rotateAngle forKey:@"Rotate"];

    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(rotateAngle)];

}

- (void) minusTenDegreeRotate {
    [Flurry logEvent:@"minusTen"];

    CGFloat rotateAngle = [defaults floatForKey:@"Rotate"]-M_PI_2/9;   
//    [defaults setFloat:rotateAngle forKey:@"Rotate"];
    CGFloat zoomFactor = [defaults floatForKey:@"Zoom"];
    for (UIScrollView *blockSlider in droppableAreas){
            if (blockSlider.subviews.count==0) return;
            UIImageView *imageView = blockSlider.subviews[0];
            imageView.transform = CGAffineTransformIdentity;
            imageView.transform = CGAffineTransformRotate(imageView.transform, M_PI);//brightface - added'M_PI' because of flipped imageview
            imageView.transform = CGAffineTransformScale(imageView.transform, -1,1);//brightface - added'FLIP' because of flipped imageview
            imageView.transform = CGAffineTransformRotate(imageView.transform, rotateAngle);
            if ([defaults boolForKey:@"Flip"])
                imageView.transform = CGAffineTransformScale(imageView.transform, -zoomFactor, zoomFactor);
            else
                imageView.transform = CGAffineTransformScale(imageView.transform, zoomFactor, zoomFactor);
    }
    rotateAngle = fmodf(rotateAngle, 2*M_PI);
    [defaults setFloat:rotateAngle forKey:@"Rotate"];

    labelRotate.text = [NSString stringWithFormat:@"%.0f",radiansToDegrees(rotateAngle)];

}

- (void) flip {
    [Flurry logEvent:@"Flip"];
    
        if (![defaults boolForKey:@"Flip"])
            [defaults setBool:YES forKey:@"Flip"];
        else
            [defaults setBool:NO forKey:@"Flip"];
        for (UIScrollView *blockSlider in droppableAreas){
                if (blockSlider.subviews.count==0) return;
                UIImageView *imageView = blockSlider.subviews[0];
                imageView.transform = CGAffineTransformScale(imageView.transform, -1,1);
        }
}
- (void) closeBtnClicked {

    for (int i = 0; i <= 3; i++) {
        UIImageView *imageView= (UIImageView *)[self.frameContainer viewWithTag:200+i];
        [imageView removeFromSuperview];
    }

}
- (void) addButtons {

    if (nStyle==2) {
        switch (nSubStyle) {
            case 1:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,155-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.alpha = 0.5;
                btn.tag = 200;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 2:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 201;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 3:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];

                break;
            }
            case 4:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,155-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.alpha = 0.5;
                btn.tag = 200;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 5:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,155-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.alpha = 0.5;
                btn.tag = 200;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 6:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];

                break;
            }
            case 10:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedPtX2,155-15+adjustedPtY2, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 8:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 12:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,180-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 13:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,180-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 7:{
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,180-15+adjustedHeight2, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            case 17:
            case 18:
                case 19:
                case 20:
                case 21:
                case 22:
            {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedPtX2,155-15+adjustedPtY2, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                break;
            }
            default:
                break;
        }
    }
    else if (nStyle==3) {
        switch (nSubStyle) {
            case 1: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(112+adjustedWidth1,155-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.alpha = 0.5;
                btn.tag = 200;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
            
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+77+adjustedWidth1/2,155-15+adjustedHeight2, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.tag = 201;
                btn1.alpha = 0.5;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                break;
            }
            case 2: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(177/2-15+adjustedWidth1/2,155-15+adjustedHeight1, 30, 30)];
                
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(177-7+adjustedWidth1,155-15, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                break;
            }
            case 3: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,112+adjustedHeight1, 30, 30)];
                
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+ adjustedWidth2,211-15-adjustedHeight2/2, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                break;
            }
            case 4: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,77-adjustedHeight3/2, 30, 30)];
                
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,184-15-adjustedHeight3, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                break;
            }
            case 5: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(103-15+adjustedWidth1,155, 30, 30)];
                
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(206-15-adjustedWidth3,155, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                break;
            }
            case 6: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,103-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,206-15-adjustedHeight3, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                break;
            }
            case 7: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,155-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
               
                break;
            }
            case 8: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                
                break;
            }
            case 9: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(130-13+adjustedWidth3,175-13, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 10: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 11: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 12: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15-adjustedHeight1/2, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 14: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15-adjustedHeight1/2, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }

            default:
                break;
        }
    }
    else if (nStyle==4) {
        switch (nSubStyle) {
            case 1: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,77-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.alpha = 0.5;
                btn.tag = 200;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(77-15,155-15+adjustedHeight1, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.tag = 201;
                btn1.alpha = 0.5;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                
                UIImageView *btn2 = [[UIImageView alloc] initWithFrame:CGRectMake(155+77-15,155-15+adjustedHeight2, 30, 30)];
                btn2.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn2.tag = 202;
                btn2.alpha = 0.5;
                btn2.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn2:)];
                panGestureBtn2.delegate=self;
                [btn2 addGestureRecognizer:panGestureBtn2];
                [self.frameContainer addSubview:btn2];
                
                UIImageView *btn3 = [[UIImageView alloc] initWithFrame:CGRectMake(155+adjustedWidth3-15,155+77-15, 30, 30)];
                btn3.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn3.tag = 203;
                btn3.alpha = 0.5;
                btn3.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn3 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn3:)];
                panGestureBtn3.delegate=self;
                [btn3 addGestureRecognizer:panGestureBtn3];
                [self.frameContainer addSubview:btn3];
                break;
            }
            case 2: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(77-15+adjustedWidth1,155-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1+adjustedWidth2,155-15, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                
                UIImageView *btn2 = [[UIImageView alloc] initWithFrame:CGRectMake(155+77-15-adjustedWidth4,155-15, 30, 30)];
                btn2.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn2.tag = 202;
                btn2.alpha = 0.5;
                btn2.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn2:)];
                panGestureBtn2.delegate=self;
                [btn2 addGestureRecognizer:panGestureBtn2];
                [self.frameContainer addSubview:btn2];

                break;
            }
            case 3: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,77-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,adjustedHeight1+adjustedHeight2+155-15, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                
                UIImageView *btn2 = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155+77-15-adjustedHeight4, 30, 30)];
                btn2.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn2.tag = 202;
                btn2.alpha = 0.5;
                btn2.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn2:)];
                panGestureBtn2.delegate=self;
                [btn2 addGestureRecognizer:panGestureBtn2];
                [self.frameContainer addSubview:btn2];
                break;
            
            }
            case 4: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(110+adjustedWidth1,155-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(200+adjustedWidth1/2,adjustedHeight2+103-15, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                
                UIImageView *btn2 = [[UIImageView alloc] initWithFrame:CGRectMake(200+adjustedWidth1/2,206-15-adjustedHeight4, 30, 30)];
                btn2.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn2.tag = 202;
                btn2.alpha = 0.5;
                btn2.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn2:)];
                panGestureBtn2.delegate=self;
                [btn2 addGestureRecognizer:panGestureBtn2];
                [self.frameContainer addSubview:btn2];
                break;
            }
            case 5: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(200/2-22-adjustedWidth2/2,103-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(200/2-adjustedWidth2/2-22,adjustedHeight3+206-15+adjustedHeight1, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                
                UIImageView *btn2 = [[UIImageView alloc] initWithFrame:CGRectMake(200-adjustedWidth2-30,155-15, 30, 30)];
                btn2.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn2.tag = 202;
                btn2.alpha = 0.5;
                btn2.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn2:)];
                panGestureBtn2.delegate=self;
                [btn2 addGestureRecognizer:panGestureBtn2];
                [self.frameContainer addSubview:btn2];
                break;
            }
            case 6: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,110+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(103+adjustedWidth2-15,210-7+adjustedHeight1/2, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                
                UIImageView *btn2 = [[UIImageView alloc] initWithFrame:CGRectMake(206+adjustedWidth2+adjustedWidth3-15,210-7+adjustedHeight1/2, 30, 30)];
                btn2.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn2.tag = 202;
                btn2.alpha = 0.5;
                btn2.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn2:)];
                panGestureBtn2.delegate=self;
                [btn2 addGestureRecognizer:panGestureBtn2];
                [self.frameContainer addSubview:btn2];
                break;
            }
            case 7: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(103+adjustedWidth1-15,200/2-15-7-adjustedHeight4/2, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                UIImageView *btn1 = [[UIImageView alloc] initWithFrame:CGRectMake(206+adjustedWidth2+adjustedWidth1-15,200/2-15-7-adjustedHeight4/2, 30, 30)];
                btn1.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn1.alpha = 0.5;
                btn1.tag = 201;
                btn1.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn1:)];
                panGestureBtn1.delegate=self;
                [btn1 addGestureRecognizer:panGestureBtn1];
                [self.frameContainer addSubview:btn1];
                
                UIImageView *btn2 = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,-adjustedHeight4+200-15-15, 30, 30)];
                btn2.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn2.tag = 202;
                btn2.alpha = 0.5;
                btn2.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn2:)];
                panGestureBtn2.delegate=self;
                [btn2 addGestureRecognizer:panGestureBtn2];
                [self.frameContainer addSubview:btn2];
                break;
            }
            case 10: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15-adjustedHeight1/2, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 11: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 12: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15+adjustedWidth1,155-15, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 13: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15-adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 14: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 16: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15-adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }
            case 18: {
                UIImageView *btn = [[UIImageView alloc] initWithFrame:CGRectMake(155-15,155-15+adjustedHeight1, 30, 30)];
                btn.image =[UIImage imageNamed:[NSString stringWithFormat:@"square.png"]];
                btn.tag = 200;
                btn.alpha = 0.5;
                btn.userInteractionEnabled=YES;
                UIPanGestureRecognizer *panGestureBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBtn:)];
                panGestureBtn.delegate=self;
                [btn addGestureRecognizer:panGestureBtn];
                [self.frameContainer addSubview:btn];
                
                break;
            }

            default:
                break;
        }
    }
//    }
}
- (void) moveBtn :(UIPanGestureRecognizer *)sender  {
    CGPoint translation = [sender translationInView:self.view];
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
    if (nStyle == 2) {
        switch (nSubStyle) {
            case 1:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2=adjustedWidth2 - translation.x;
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 2:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                NSLog(@"btn center y =%f ", btn.center.y + translation.y);
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y +translation.y);
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2=adjustedHeight2 - translation.y;
                    adjustedPtY2=adjustedPtY2 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 3:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2+translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 4:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2=adjustedWidth2 - translation.x;
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 5:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2=adjustedWidth2 - translation.x;
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 6:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2-translation.x;
                    adjustedPtX2 = adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 10:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)&&(btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40) ){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y+translation.y );
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    adjustedPtY2=adjustedPtY2 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 8:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 250) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedPtX2 = adjustedPtX2 - translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 12:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 260) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedPtX2 = adjustedPtX2 - translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 13:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 220) && (btn.center.y + translation.y > 90)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedPtY2 = adjustedPtY2 - translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 7:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 301) && (btn.center.y + translation.y > 80)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
//                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
//                    adjustedPtY2 = adjustedPtY2 - translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 17:
                case 18:
                case 19:
                case 20:
                case 21:
                case 22:
            
            {
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)&&(btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40) ){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y+translation.y );
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    adjustedPtY2=adjustedPtY2 + translation.y;
                    [self resizeFrames];
                }
                break;
            }

            default:
                break;
        }
    }
    else if (nStyle == 3) {
        switch (nSubStyle) {
            case 1:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2=adjustedWidth2 - translation.x;
                    adjustedWidth3=adjustedWidth3 - translation.x;
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    adjustedPtX3= adjustedPtX3 + translation.x;
                    UIImageView *btn1 = (UIImageView *) [self.frameContainer viewWithTag:201];
                    btn1.center = CGPointMake(btn1.center.x +translation.x/2,btn.center.y+adjustedHeight2 );
                    [self resizeFrames];
                }
                break;
            }
            case 2:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 270) && (btn.center.y+ translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight3=adjustedHeight3 - translation.y;
                    adjustedPtY3= adjustedPtY3 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 3:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 270) && (btn.center.y+ translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2=adjustedHeight2 - translation.y;
                    adjustedHeight3=adjustedHeight3 - translation.y;
                    adjustedPtY2= adjustedPtY2 + translation.y;
                    adjustedPtY3= adjustedPtY3 + translation.y;
                    UIImageView *btn1 = (UIImageView *) [self.frameContainer viewWithTag:201];
                    btn1.center = CGPointMake(btn1.center.x ,btn1.center.y+translation.y/2 );
                    [self resizeFrames];
                }
                break;
            }
            case 4:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x+ translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x+translation.x ,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2-translation.x;
                    adjustedPtX2 = adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 5:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 155) && (btn.center.x+ translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x+translation.x ,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2-translation.x;
                    adjustedPtX2 = adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 6:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 155) && (btn.center.y+ translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2-translation.y;
                    adjustedPtY2 = adjustedPtY2 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 7:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 250) && (btn.center.x+ translation.x > 100)){
                    btn.center = CGPointMake(btn.center.x+translation.x ,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedWidth3= adjustedWidth3+translation.x;
                    adjustedPtX2 = adjustedPtX2 - translation.x/2;
                    adjustedPtX3 = adjustedPtX3 - translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 8:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 200) && (btn.center.y+ translation.y > 100)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3+translation.y;
                    adjustedPtY1 = adjustedPtY1 - translation.y/2;
                    adjustedPtY2 = adjustedPtY2 - translation.y/2;
                    adjustedPtY3 = adjustedPtY3 - translation.y/2;
                    [self resizeFrames];
                }
                break;
            }
            case 9:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 193) && (btn.center.x+ translation.x > 100)){
                    btn.center = CGPointMake(btn.center.x+translation.x ,btn.center.y );
                    adjustedHeight1= adjustedHeight1+translation.x;
                    adjustedWidth3= adjustedWidth3+translation.x;
                    adjustedPtY1 = adjustedPtY1 - translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 10:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 251) && (btn.center.y+ translation.y > 100)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3+translation.y;
                    adjustedPtY2 = adjustedPtY2 - translation.y/2;
                    adjustedPtY3 = adjustedPtY3 - translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 11:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 227) && (btn.center.y+ translation.y > 100)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3+translation.y;
                    adjustedPtY2 = adjustedPtY2 - translation.y;
//                    adjustedPtY3 = adjustedPtY3 - translation.y;
//                    adjustedPtY3 = adjustedPtY3 - translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 12:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 229) && (btn.center.y+ translation.y > 100)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1-2*translation.y;
                    adjustedHeight2= adjustedHeight2-translation.y;
                    adjustedHeight3= adjustedHeight3-2*translation.y;
                    adjustedPtY2 = adjustedPtY2 + translation.y/2;
                    adjustedPtY3 = adjustedPtY3 + translation.y;
                    adjustedPtY1 = adjustedPtY1 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 14:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 200) && (btn.center.y+ translation.y > 106)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1-2*translation.y;
                    adjustedHeight2= adjustedHeight2-2*translation.y;
                    adjustedHeight3= adjustedHeight3-2*translation.y;
                    adjustedPtY2 = adjustedPtY2 + translation.y;
                    adjustedPtY3 = adjustedPtY3 + translation.y;
                    adjustedPtY1 = adjustedPtY1 + translation.y;
                    [self resizeFrames];
                }
                break;
            }


            default:
                break;
        }
    }
    else if (nStyle == 4) {
        switch (nSubStyle) {
            case 1:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2=adjustedWidth2 - translation.x;
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 2:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 155) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2=adjustedWidth2 - translation.x;
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 3:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 155) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y +translation.y);
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2-translation.y;
                    adjustedPtY2=adjustedPtY2 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 4:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 270) && (btn.center.x+ translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x+translation.x ,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2-translation.x;
                    adjustedWidth3= adjustedWidth3-translation.x;
                    adjustedWidth4= adjustedWidth4-translation.x;
                    adjustedPtX2 = adjustedPtX2 + translation.x;
                    adjustedPtX3 = adjustedPtX3 + translation.x;
                    adjustedPtX4 = adjustedPtX4 + translation.x;
                    UIImageView *btn1 = (UIImageView *) [self.frameContainer viewWithTag:201];
                    btn1.center = CGPointMake(btn1.center.x+translation.x/2 ,btn1.center.y );
                    UIImageView *btn2 = (UIImageView *) [self.frameContainer viewWithTag:202];
                    btn2.center = CGPointMake(btn2.center.x+translation.x/2 ,btn2.center.y );
                    [self resizeFrames];
                }
                break;
            }
            case 5:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 155) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y +translation.y);
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedPtY3=adjustedPtY3 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 6:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y +translation.y);
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2-translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedHeight4= adjustedHeight4-translation.y;
                    adjustedPtY2=adjustedPtY2 + translation.y;
                    adjustedPtY3=adjustedPtY3 + translation.y;
                    adjustedPtY4=adjustedPtY4 + translation.y;
                    UIImageView *btn1 = (UIImageView *) [self.frameContainer viewWithTag:201];
                    btn1.center = CGPointMake(btn1.center.x,btn1.center.y +translation.y/2 );
                    UIImageView *btn2 = (UIImageView *) [self.frameContainer viewWithTag:202];
                    btn2.center = CGPointMake(btn2.center.x,btn2.center.y +translation.y/2 );
                    [self resizeFrames];
                }
                break;
            }
            case 7:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 155) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x ,btn.center.y);
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2-translation.x;
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 10:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 200) && (btn.center.y+ translation.y > 148)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1-2*translation.y;
                    adjustedHeight2= adjustedHeight2-2*translation.y;
                    adjustedHeight3= adjustedHeight3-2*translation.y;
                    adjustedHeight4= adjustedHeight4-2*translation.y;

                    adjustedPtY2 = adjustedPtY2 + translation.y;
                    adjustedPtY3 = adjustedPtY3 + translation.y;
                    adjustedPtY1 = adjustedPtY1 + translation.y;
                    adjustedPtY4 = adjustedPtY4 + translation.y;

                    [self resizeFrames];
                }
                break;
            }
            case 11:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 220) && (btn.center.y+ translation.y > 80)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedHeight4= adjustedHeight4-translation.y;
                    
//                    adjustedPtY2 = adjustedPtY2 + translation.y;
                    adjustedPtY3 = adjustedPtY3 + translation.y;
//                    adjustedPtY1 = adjustedPtY1 + translation.y;
                    adjustedPtY4 = adjustedPtY4 + translation.y;
                    
                    [self resizeFrames];
                }
                break;
            }
            case 12:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.x + translation.x< 250) && (btn.center.x+ translation.x > 70)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedWidth3= adjustedWidth3+translation.x;
                    adjustedWidth4= adjustedWidth4+translation.x;
                    
                    adjustedPtX2 = adjustedPtX2 - translation.x;
//                    adjustedPtY3 = adjustedPtY3 + translation.y;
//                    adjustedPtY1 = adjustedPtY1 + translation.y;
                    adjustedPtX4 = adjustedPtX4 - translation.x;
                    
                    [self resizeFrames];
                }
                break;
            }
            case 13:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 200) && (btn.center.y+ translation.y > 122)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedWidth1= adjustedWidth1-translation.y;
                    adjustedHeight1= adjustedHeight1-translation.y;

                    adjustedHeight2= adjustedHeight2-translation.y;
                    adjustedWidth2= adjustedWidth2-translation.y;
                    
                    adjustedWidth3= adjustedWidth3-translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    
                    adjustedWidth4= adjustedWidth4+translation.y;
                    adjustedHeight4= adjustedHeight4+translation.y;
                    
                    adjustedPtX4 = adjustedPtX4 - translation.y;
                    adjustedPtX3 = adjustedPtX3 - translation.y;

                    adjustedPtY1 = adjustedPtY1 + 2*translation.y;
                    adjustedPtY2 = adjustedPtY2 + translation.y;
                    adjustedPtY3 = adjustedPtY3 + translation.y;
                    
                    [self resizeFrames];
                }
                break;
            }
            case 14:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 220) && (btn.center.y+ translation.y > 97)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3+translation.y;
                    adjustedHeight4= adjustedHeight4-translation.y;
                    
//                    adjustedPtY2 = adjustedPtY2 + translation.y;
//                    adjustedPtY3 = adjustedPtY3 + translation.y;
//                    adjustedPtY1 = adjustedPtY1 + translation.y;
                    adjustedPtY4 = adjustedPtY4 + translation.y;
                    
                    [self resizeFrames];
                }
                break;
            }
            case 16:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 250) && (btn.center.y+ translation.y > 155)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1-translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y/2;
                    adjustedHeight3= adjustedHeight3+translation.y/2;
                    adjustedHeight4= adjustedHeight4-translation.y;
                    
//                    adjustedPtY2 = adjustedPtY2 + translation.y;
                    adjustedPtY3 = adjustedPtY3 - translation.y/2;
                    adjustedPtY1 = adjustedPtY1 + translation.y/2;
                    adjustedPtY4 = adjustedPtY4 + translation.y/2;
                    
                    [self resizeFrames];
                }
                break;
            }
            case 18:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:200];
                if ((btn.center.y + translation.y< 236) && (btn.center.y+ translation.y > 120)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedHeight4= adjustedHeight4+translation.y;
                    
                    adjustedPtY2 = adjustedPtY2 - translation.y;
//                    adjustedPtY3 = adjustedPtY3 + translation.y;
//                    adjustedPtY1 = adjustedPtY1 + translation.y;
                    adjustedPtY4 = adjustedPtY4 - translation.y;
                    
                    [self resizeFrames];
                }
                break;
            }
           
            default:
                break;
        }
    }
}
- (void) moveBtn1 :(UIPanGestureRecognizer *)sender  {
    
    CGPoint translation = [sender translationInView:self.view];
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
    if (nStyle == 2) {
        switch (nSubStyle) {
            case 3:{
//                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
//                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
//                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
//                    adjustedWidth2= adjustedWidth2+translation.x;
//                    [self resizeFrames];
//                }
//                break;
            }
            case 6:{
//                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
//                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
//                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
//                    adjustedWidth2= adjustedWidth2-translation.x;
//                    adjustedPtX2 = adjustedPtX2 + translation.x;
//                    [self resizeFrames];
//                }
//                break;
            }
                
            default:
                break;
        }
    }
    else if (nStyle == 3) {
        switch (nSubStyle) {
            case 1:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x, btn.center.y+translation.y );
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedPtY3 = adjustedPtY3 +translation.y;
                    
                    [self resizeFrames];
                }
                break;
            }
            case 2:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x+translation.x, btn.center.y );
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth2= adjustedWidth2-translation.x;
                    adjustedWidth3= adjustedWidth3+translation.x;
                    adjustedPtX2 = adjustedPtX2 +translation.x;
                    UIImageView *btn1 = (UIImageView *) [self.frameContainer viewWithTag:200];
                    btn1.center = CGPointMake(btn1.center.x +translation.x/2,btn.center.y+adjustedHeight1 );
                    [self resizeFrames];
                }
                break;
            }
            case 3:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x+translation.x, btn.center.y );
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedWidth3= adjustedWidth3-translation.x;
                    adjustedPtX3 = adjustedPtX3 +translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 4:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x, btn.center.y +translation.y);
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedPtY3= adjustedPtY3+ translation.y;
                    UIImageView *btn1 = (UIImageView *) [self.frameContainer viewWithTag:200];
                    btn1.center = CGPointMake(btn1.center.x ,btn1.center.y+translation.y/2 );
                    [self resizeFrames];
                }
                break;
            }
            case 5:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 155)){
                    btn.center = CGPointMake(btn.center.x+translation.x, btn.center.y );
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedWidth3= adjustedWidth3-translation.x;
                    adjustedPtX3 = adjustedPtX3 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 6:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 155)){
                    btn.center = CGPointMake(btn.center.x, btn.center.y+translation.y );
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedPtY3 = adjustedPtY3 + translation.y;                    [self resizeFrames];
                }
                break;
            }
            default:
                break;
        }
    }
    else if (nStyle == 4) {
        switch (nSubStyle) {
            case 1:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x, btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedPtY3 = adjustedPtY3 +translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 2:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.x + translation.x< 155+77) && (btn.center.x + translation.x > 77)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedWidth3=adjustedWidth3 - translation.x;
                    adjustedPtX3=adjustedPtX3 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 3:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.y + translation.y< 155+77) && (btn.center.y + translation.y > 77)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y +translation.y);
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedPtY3=adjustedPtY3 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 4:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.y + translation.y< 155) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x, btn.center.y +translation.y);
                    adjustedHeight3= adjustedHeight3-translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedPtY3= adjustedPtY3+ translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 5:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 155)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y +translation.y);
                    adjustedHeight3= adjustedHeight3+translation.y;
                    adjustedHeight4= adjustedHeight4-translation.y;
                    adjustedPtY4=adjustedPtY4 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 6:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.x + translation.x< 155) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedWidth3=adjustedWidth3 - translation.x;
                    adjustedPtX3=adjustedPtX3 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 7:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:201];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 155)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth2= adjustedWidth2+translation.x;
                    adjustedWidth3=adjustedWidth3 - translation.x;
                    adjustedPtX3=adjustedPtX3 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
                
            
            default:
                break;
        }
    }
}
- (void) moveBtn2 :(UIPanGestureRecognizer *)sender  {
    CGPoint translation = [sender translationInView:self.view];
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
    if (nStyle == 4) {
        switch (nSubStyle) {
            case 1:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:202];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y +translation.y);
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight4=adjustedHeight4 - translation.y;
                    adjustedPtY4=adjustedPtY4 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 2:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:202];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 155)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth3= adjustedWidth3+translation.x;
                    adjustedWidth4=adjustedWidth4 - translation.x;
                    adjustedPtX4=adjustedPtX4 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 3:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:202];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 155)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y +translation.y);
                    adjustedHeight3= adjustedHeight3+translation.y;
                    adjustedHeight4= adjustedHeight4-translation.y;
                    adjustedPtY4=adjustedPtY4 + translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 4:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:202];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 155)){
                    btn.center = CGPointMake(btn.center.x, btn.center.y +translation.y);
                    adjustedHeight4= adjustedHeight4-translation.y;
                    adjustedHeight3= adjustedHeight3+translation.y;
                    adjustedPtY4= adjustedPtY4+ translation.y;
                    [self resizeFrames];
                }
                break;
            }
            case 5:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:202];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth2= adjustedWidth2-translation.x;
                    adjustedWidth1= adjustedWidth1+translation.x;
                    adjustedWidth3= adjustedWidth3+translation.x;
                    adjustedWidth4= adjustedWidth4+translation.x;
                    adjustedPtX2=adjustedPtX2 + translation.x;
                    UIImageView *btn1 = (UIImageView *) [self.frameContainer viewWithTag:200];
                    btn1.center = CGPointMake(btn1.center.x+translation.x/2 ,btn1.center.y );
                    UIImageView *btn2 = (UIImageView *) [self.frameContainer viewWithTag:201];
                    btn2.center = CGPointMake(btn2.center.x+translation.x/2 ,btn2.center.y );
                    [self resizeFrames];
                }
                break;
            }
            case 6:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:202];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 155)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth3= adjustedWidth3+translation.x;
                    adjustedWidth4=adjustedWidth4 - translation.x;
                    adjustedPtX4=adjustedPtX4 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
            case 7:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:202];
                if ((btn.center.y + translation.y< 270) && (btn.center.y + translation.y > 40)){
                    btn.center = CGPointMake(btn.center.x ,btn.center.y+translation.y );
                    adjustedHeight1= adjustedHeight1+translation.y;
                    adjustedHeight2= adjustedHeight2+translation.y;
                    adjustedHeight3= adjustedHeight3+translation.y;
                    adjustedHeight4= adjustedHeight4-translation.y;
                    adjustedPtY4=adjustedPtY4 + translation.y;
                    UIImageView *btn1 = (UIImageView *) [self.frameContainer viewWithTag:200];
                    btn1.center = CGPointMake(btn1.center.x,btn1.center.y +translation.y/2 );
                    UIImageView *btn2 = (UIImageView *) [self.frameContainer viewWithTag:201];
                    btn2.center = CGPointMake(btn2.center.x,btn2.center.y +translation.y/2 );
                    [self resizeFrames];

                }
                break;
            }
            default:
                break;
        }
    }
}
- (void) moveBtn3 :(UIPanGestureRecognizer *)sender  {
    CGPoint translation = [sender translationInView:self.view];
    [sender setTranslation:CGPointMake(0, 0) inView:self.view];
    if (nStyle == 4) {
        switch (nSubStyle) {
            case 1:{
                UIImageView *btn = (UIImageView *) [self.frameContainer viewWithTag:203];
                if ((btn.center.x + translation.x< 270) && (btn.center.x + translation.x > 40)){
                    btn.center = CGPointMake(btn.center.x +translation.x,btn.center.y );
                    adjustedWidth3= adjustedWidth3+translation.x;
                    adjustedWidth4= adjustedWidth4-translation.x;
                    adjustedPtX4=adjustedPtX4 + translation.x;
                    [self resizeFrames];
                }
                break;
            }
                
            default:
                break;
        }
    }
}

- (void) resetAdjustedValues {
    adjustedPtX1 = adjustedPtX2 = adjustedPtX3 = adjustedPtX4 = 0.0;
    adjustedPtY1 = adjustedPtY2 = adjustedPtY3 = adjustedPtY4 = 0.0;
    adjustedWidth1 = adjustedWidth2 = adjustedWidth3 = adjustedWidth4 = 0.0;
    adjustedHeight1 = adjustedHeight2 = adjustedHeight3 = adjustedHeight4 = 0.0;
}
- (CGRect) getScrollFrame1:(int)style subStyle:(int)sub
{
    CGRect rc;
    float scroll_width = 0;
    float scroll_height = 0;
    float   nLeftMargin=0;
    float  nTopMargin =0;
    
    if (style == 1) {
        if ( sub == 1) {  //full frame

            scroll_width = self.frameContainer.frame.size.width - 2*nMargin;
            scroll_height = self.frameContainer.frame.size.height - 2*nMargin;
            rc = CGRectMake(nMargin, nMargin, scroll_width, scroll_height );
//            CALayer *mask = [CALayer layer];
//            mask.contents = (id)[[UIImage imageNamed:@"maskCircle.png"] CGImage];
//            mask.frame = CGRectMake(nMargin-5, nMargin-20, scroll_width-10, scroll_height-10 );
//            blockSlider1.layer.mask=mask;
            return rc;
        }
        else if( sub == 6) { // fixed height, change width
            scroll_width = self.frameContainer.frame.size.width - 100 + 4*nMargin;
            scroll_height = self.frameContainer.frame.size.height - 100+2*nMargin;
            rc = CGRectMake(50-2*nMargin, 50-nMargin, scroll_width, scroll_height );
            return rc;
        }else if( sub == 3) { //full on width, change height
            scroll_width = self.frameContainer.frame.size.width ;//10*7
            scroll_height = self.frameContainer.frame.size.height - 10 * 4-nMargin*2;//10*7
            nLeftMargin =0;
            nTopMargin = 0;
//            nLeftMargin =10 * 4/2;//10*7
//            nTopMargin = 10 * 4/2;//10*7
            rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height );
            return rc;
        }
//        else if( sub == 4) { //
////            scroll_width = self.frameContainer.frame.size.width - 10 * 2;
////            scroll_height = self.self.frameContainer.frame.size.height - 70; // - 10*7*2 = -140
//            scroll_width = self.frameContainer.frame.size.width - 100+nMargin*3;
//            scroll_height = self.self.frameContainer.frame.size.height - 100+nMargin*3;
//            rc = CGRectMake(0, 0, scroll_width, scroll_height );
//            return rc;
//        }
       
        
        else if ( sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width + nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height + nMargin * 3 ) / 2;
            nLeftMargin = -nMargin * 3 + scroll_width;
            rc = CGRectMake(nLeftMargin, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 4) {
            scroll_width = self.frameContainer.frame.size.width -100+ nMargin * 5;// *8*2
            scroll_height = self.frameContainer.frame.size.height -100+ nMargin * 5;
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
//        else if ( sub == 7) { // right frame
//            scroll_width = 270;
//            scroll_height = 310;
//            rc = CGRectMake(0, 0, scroll_width+nMargin, scroll_height );
//            return rc;
//        }
//        else if ( sub == 8) { // small right corner with 10 margin top/right
//            scroll_width = 150+nMargin;
//            scroll_height = 150+nMargin;
//            //            nTopMargin = nMargin;
//            //            nLeftMargin = 0;
//            //nLeftMargin=  200;
//            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
//            rc = CGRectMake(150-nMargin/2, 10, scroll_width, scroll_height );
//            return rc;
//        }

//        else if ( sub == 7) { //full
//            scroll_width = 310-nMargin;
//            scroll_height = 310-nMargin;//350
//            rc = CGRectMake(0-nMargin/2, 0-nMargin/2, scroll_width, scroll_height );
//            return rc;
//        }
        
        
        else if ( sub == 7) { //tall right with 10 margin top/right
            scroll_width = 220+3*nMargin;
            scroll_height = 290; //330
            //            nTopMargin = nMargin;
            //            nLeftMargin = 0;
            //nLeftMargin=  200;
//            NSLog(@"width=%f , height=%f",scroll_width,scroll_height);
            rc = CGRectMake(0, 10, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 8) {  //frame with horizontal bottom
            scroll_width = 310;
            scroll_height = 270-nMargin*3; //250
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 9) { // left column frame
            scroll_width = 210+nMargin*3;
            scroll_height = 310; //350
            rc = CGRectMake(100-nMargin*3, 0, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 10) { // middle column frame
            scroll_width = 280-4*nMargin;
            scroll_height = 310; //350
            rc = CGRectMake(15+2*nMargin, 0, scroll_width, scroll_height );
            return rc;
        }
        
        else if ( sub == 11) { // middle row frame
            scroll_width = 310;
            scroll_height = 280-4*nMargin; //250
            rc = CGRectMake(0, 15+2*nMargin, scroll_width, scroll_height );
            return rc;
        }
        
        else if ( sub == 12) { // left corner frame
            scroll_width = 150+4*nMargin;
            scroll_height = 150+4*nMargin;
            rc = CGRectMake(60-2*nMargin, 60-2*nMargin, scroll_width, scroll_height );
            return rc;
        }
        else if ( sub == 2) { // right frame
            scroll_width = 200+2*nMargin;
            scroll_height = 200+2*nMargin;
            rc = CGRectMake(55-nMargin, 55-nMargin, scroll_width, scroll_height );
            return rc;
        }

    }
    
    else if (style == 2) {
        if (sub == 1) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2 ;
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
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 )/2;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
        }
        else if(sub == 5){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin *2 - 100);
            nTopMargin=nMargin+ 100/2;
            rc = CGRectMake(nMargin, nTopMargin, scroll_width, scroll_height );
            rc = CGRectMake(nMargin+adjustedPtX1, nTopMargin+adjustedPtY1, scroll_width+adjustedWidth1, scroll_height+adjustedHeight1 );
            return rc;
        }
        else if(sub == 6){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 )/2;
        }
        else if (sub == 7) { //secondFrameSlider stuff
            scroll_width = 155;//155
            scroll_height = 310;//350
            rc = CGRectMake(adjustedPtX1, adjustedPtY1, scroll_width+adjustedWidth1, scroll_height+adjustedHeight1 );

//            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 8) {  //secondFrameSlider stuff
            scroll_width = 200;
            scroll_height = 135;
//            rc = CGRectMake(nMargin+adjustedPtX1, nMargin+adjustedPtY1, scroll_width+adjustedWidth1, scroll_height+adjustedHeight1 );

            rc = CGRectMake(10+adjustedPtX1, 20+adjustedPtY1, scroll_width+adjustedWidth1-nMargin, scroll_height+adjustedHeight1-nMargin );
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
            rc = CGRectMake(adjustedPtX1, adjustedPtY1, scroll_width+adjustedWidth1-nMargin, scroll_height+adjustedHeight1-nMargin );

//            rc = CGRectMake(0, 0, scroll_width+nMargin*3, scroll_height );
            return rc;
        }
        else if (sub == 13) {  //secondFrameSlider stuff
            scroll_width = 150;
            scroll_height =250;
            rc = CGRectMake(adjustedPtX1, adjustedPtY1, scroll_width+adjustedWidth1-nMargin+5, scroll_height+adjustedHeight1-nMargin );

//            rc = CGRectMake(0, 0, scroll_width+nMargin/4, scroll_height+nMargin*2 );
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
        else if (sub == 17) {  //secondFrameSlider stuff
            scroll_width = 310;
            scroll_height =310;
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 18) {  //secondFrameSlider stuff
            scroll_width = 310;
            scroll_height =310;
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 19) {  //secondFrameSlider stuff
            scroll_width = 310;
            scroll_height =310;
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 20) {  //secondFrameSlider stuff
            scroll_width = 310;
            scroll_height =310;
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 21) {  //secondFrameSlider stuff
            scroll_width = 310;
            scroll_height =310;
            rc = CGRectMake(0, 0, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 22) {  //secondFrameSlider stuff
            scroll_width = 310;
            scroll_height =310;
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
            scroll_height = 102;
            rc = CGRectMake(5+adjustedPtX1, 5+adjustedPtY1, scroll_width-nMargin+adjustedWidth1, scroll_height -nMargin+adjustedHeight1);
            return rc;
            
        }else if (sub == 8) {
            scroll_width = 102;
            scroll_height = 250;
            rc = CGRectMake(5+nMargin/2+adjustedPtX1, 30+nMargin/2+adjustedPtY1, scroll_width-nMargin+adjustedWidth1, scroll_height-nMargin+adjustedHeight1 );
            return rc;
            
        }else if (sub == 9) {
            scroll_width = 105;
            scroll_height = 105;
            rc = CGRectMake(25+nMargin/2+adjustedPtX1+5, 70+nMargin/2 +adjustedPtY1, scroll_width-nMargin+adjustedWidth1, scroll_height-nMargin+adjustedHeight1  );
            return rc;
            
        }
        else if (sub == 10){
            scroll_width = 100;
            scroll_height = 150;
            rc = CGRectMake(5+adjustedPtX1, 5+adjustedPtY1, scroll_width-nMargin+adjustedWidth1, scroll_height -nMargin+adjustedHeight1);
//            rc = CGRectMake(5, 5, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 11){
            scroll_width = 100;
            scroll_height = 200;
             rc = CGRectMake(5+adjustedPtX1, 22+adjustedPtY1, scroll_width-nMargin+adjustedWidth1, scroll_height -nMargin+adjustedHeight1);
//            rc = CGRectMake(5, 20, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 12){
            scroll_width = 100;
            scroll_height = 100;
            rc = CGRectMake(5+adjustedPtX1, 108+adjustedPtY1, scroll_width-nMargin+adjustedWidth1, scroll_height -nMargin+adjustedHeight1);
//            rc = CGRectMake(5, 105-nMargin, scroll_width, scroll_height+nMargin*2 );
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
            scroll_height = 220;
            rc = CGRectMake(0+adjustedPtX1, 47+adjustedPtY1, scroll_width-nMargin+adjustedWidth1, scroll_height -nMargin+adjustedHeight1);
//            rc = CGRectMake(0, 55-nMargin, scroll_width, scroll_height+nMargin*2 );
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
            rc = CGRectMake(0+adjustedPtX1, 5+adjustedPtY1, 78-nMargin+adjustedWidth1, 250 +adjustedHeight1);
//            rc = CGRectMake(5-nMargin/4, 5, 71+nMargin/2, 250+nMargin );
            return rc;
        }
        else if (sub == 11){
            rc = CGRectMake(5+adjustedPtX1+nMargin, 5+adjustedPtY1, 180-nMargin+adjustedWidth1, 150 - nMargin +adjustedHeight1);
//            rc = CGRectMake(5-nMargin/4, 5, 180+nMargin/2, 150 );
            return rc;
        }
        
        else if (sub == 12){
            rc = CGRectMake(5+adjustedPtX1, 5+adjustedPtY1, 175-nMargin+adjustedWidth1, 75 - nMargin +adjustedHeight1);
//            rc = CGRectMake(5,5,175+nMargin*2,75 );
            return rc;
        }
        else if (sub == 13){
            rc = CGRectMake(10+adjustedPtX1+nMargin/2+5, 75+adjustedPtY1, 100-nMargin+adjustedWidth1, 100 - nMargin +adjustedHeight1);
//            rc = CGRectMake(10-nMargin/4,75-nMargin/2,100+nMargin/2,100+nMargin/2 );
            return rc;
        }
        else if (sub == 14){
            rc = CGRectMake(5+adjustedPtX1, 75+adjustedPtY1, 100-nMargin+adjustedWidth1, 100 - nMargin +adjustedHeight1);
//            rc = CGRectMake(5,75,100,100 );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(5,55,200,200 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(5+adjustedPtX1, 5+adjustedPtY1+nMargin/2, 96-nMargin+adjustedWidth1, 300 - nMargin +adjustedHeight1);
//            rc = CGRectMake(5,5,96,300 );//330
            return rc;
        }
        else if (sub == 17){
            rc = CGRectMake(0, 0, 155, 155 );
            return rc;
        }
        else if (sub == 18){
            rc = CGRectMake(5+adjustedPtX1, 5+adjustedPtY1-1, 75-nMargin+adjustedWidth1, 75 - nMargin +adjustedHeight1);
//            rc = CGRectMake(5, 5, 75+nMargin, 75 );
            return rc;
        }
    }
    rc = CGRectMake(nMargin+adjustedPtX1, nMargin+adjustedPtY1, scroll_width+adjustedWidth1, scroll_height+adjustedHeight1 );
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
        }
        else if (sub == 2) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3) / 2;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin;
        }
        else if (sub == 3){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) / 2;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 2 + scroll_height;
        }
        else if (sub == 4){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2 - 100;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin+100/2;
        }
        else if (sub == 5){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin *2 - 100);
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin=nMargin+ 100/2;
        }
        else if (sub == 6){
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) / 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 2;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
//            nLeftMargin = -nMargin * 2 + scroll_width;
//            nTopMargin = nMargin * 2 + scroll_height;
        }
        else if (sub == 7) {  //secondFrameSlider stuff
            scroll_width = 115-nMargin*2+40;
            scroll_height = 150-nMargin*2+40;
            rc = CGRectMake(175+adjustedPtX2+nMargin-20, 20+adjustedPtY2+nMargin-20, scroll_width+adjustedWidth2, scroll_height+adjustedHeight2);

//            rc = CGRectMake(175-nMargin, 20-nMargin, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 8) {  //secondFrameSlider stuff
            scroll_width = 200;
            scroll_height = 135;
            rc = CGRectMake(100+nMargin+adjustedPtX2, 155+nMargin+adjustedPtY2, scroll_width+adjustedWidth2-nMargin, scroll_height+adjustedHeight2-nMargin );

//            rc = CGRectMake(100-nMargin*3, 155, scroll_width+nMargin*3, scroll_height );
            return rc;
        }
        else if (sub == 9) {  //secondFrameSlider stuff
            scroll_width = 100;
            scroll_height =100;
            rc = CGRectMake(200, 200, scroll_width, scroll_height );
            return rc;
        }
        else if (sub == 10) {  //secondFrameSlider stuff
            scroll_width = 50;
            scroll_height =50;
            rc = CGRectMake(155-50/2-nMargin*4+adjustedPtX2, 155-50/2-nMargin*4+adjustedPtY2, scroll_width+nMargin*8, scroll_height+nMargin*8 );
            CALayer *mask = [CALayer layer];
            mask.contents = (id)[[UIImage imageNamed:@"maskSquare.png"] CGImage];
            mask.frame = rc;
            blockSlider2.layer.mask=mask;

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
            rc = CGRectMake(100+adjustedPtX2+nMargin, 180+adjustedPtY2+nMargin, scroll_width+adjustedWidth2-nMargin, scroll_height+adjustedHeight2-nMargin );

//            rc = CGRectMake(100-nMargin*3, 180, scroll_width+nMargin*3, scroll_height );
            return rc;
        }
        else if (sub == 13) {  //secondFrameSlider stuff
            scroll_width = 155;
            scroll_height =150;
            rc = CGRectMake(155+adjustedPtX2+nMargin/2, 160+adjustedPtY2+nMargin/2, scroll_width+adjustedWidth2-nMargin, scroll_height+adjustedHeight2-nMargin );

//            rc = CGRectMake(155, 160-nMargin*3, scroll_width, scroll_height+nMargin*3 );
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
        else if ( sub == 18) {
            scroll_width = 50;
            scroll_height =50;
            rc = CGRectMake(155-50/2-nMargin*6+adjustedPtX2, 155-50/2-nMargin*6+adjustedPtY2, scroll_width+nMargin*12, scroll_height+nMargin*12 );
            
            CALayer *mask = [CALayer layer];
            mask.contents = (id)[[UIImage imageNamed:@"maskCircle.png"] CGImage];
            mask.frame = rc;
            blockSlider2.layer.mask=mask;
            return rc;
        }
        else if ( sub == 17) {
            scroll_width = 50;
            scroll_height =50;
            rc = CGRectMake(155-50/2-nMargin*6+adjustedPtX2, 155-50/2-nMargin*6+adjustedPtY2, scroll_width+nMargin*12, scroll_height+nMargin*12 );
            
            CALayer *mask = [CALayer layer];
            mask.contents = (id)[[UIImage imageNamed:@"maskHeart.png"] CGImage];
            mask.frame = rc;
            blockSlider2.layer.mask=mask;
            return rc;
        }
        else if ( sub == 19) {
            scroll_width = 50;
            scroll_height =50;
            rc = CGRectMake(155-50/2-nMargin*6+adjustedPtX2, 155-50/2-nMargin*6+adjustedPtY2, scroll_width+nMargin*12, scroll_height+nMargin*12 );
            
            CALayer *mask = [CALayer layer];
            mask.contents = (id)[[UIImage imageNamed:@"maskStar.png"] CGImage];
            mask.frame = rc;
            blockSlider2.layer.mask=mask;
            return rc;
        }
        else if ( sub == 20) {
            scroll_width = 50;
            scroll_height =50;
            rc = CGRectMake(155-50/2-nMargin*6+adjustedPtX2, 155-50/2-nMargin*6+adjustedPtY2, scroll_width+nMargin*12, scroll_height+nMargin*12 );
            
            CALayer *mask = [CALayer layer];
            mask.contents = (id)[[UIImage imageNamed:@"maskDiamond.png"] CGImage];
            mask.frame = rc;
            blockSlider2.layer.mask=mask;
            return rc;
        }
        else if ( sub == 22) {
            scroll_width = 50;
            scroll_height =50;
            rc = CGRectMake(155-50/2-nMargin*6+adjustedPtX2, 155-50/2-nMargin*6+adjustedPtY2, scroll_width+nMargin*12, scroll_height+nMargin*12 );
            
            CALayer *mask = [CALayer layer];
            mask.contents = (id)[[UIImage imageNamed:@"maskTriangle.png"] CGImage];
            mask.frame = rc;
            blockSlider2.layer.mask=mask;
            return rc;
        }
        else if ( sub == 21) {
            scroll_width = 50;
            scroll_height =50;
            rc = CGRectMake(155-50/2-nMargin*6+adjustedPtX2, 155-50/2-nMargin*6+adjustedPtY2, scroll_width+nMargin*12, scroll_height+nMargin*12 );
            
            CALayer *mask = [CALayer layer];
            mask.contents = (id)[[UIImage imageNamed:@"maskInvertedTriangle.png"] CGImage];
            mask.frame = rc;
            blockSlider2.layer.mask=mask;
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
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3+2;
            scroll_height = self.frameContainer.frame.size.height - nMargin * 2;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 2 + scroll_width-3;
        } else if (sub == 6) {
            scroll_width = self.frameContainer.frame.size.width - nMargin * 2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3+2;
            nLeftMargin = nMargin;
            nTopMargin = nMargin * 2 + scroll_height-3;
        }
        else if (sub == 7) {
            rc = CGRectMake(79+adjustedPtX2+nMargin/2,107+adjustedPtY2+nMargin/2,150-nMargin+adjustedWidth2,102-nMargin+adjustedHeight2 );
            return rc;
        }
        else if (sub == 8) {
            rc = CGRectMake(106+nMargin/2+adjustedPtX2, 30+nMargin/2+adjustedPtY2, 102-nMargin+adjustedWidth2, 250-nMargin+adjustedHeight2 );
//            rc = CGRectMake(106-nMargin/4,30-nMargin,96+nMargin/2,250+nMargin*2 );
            return rc;
        } else if (sub == 9) {
            scroll_width = 165;
            scroll_height = 165;
            rc = CGRectMake(135+nMargin/2+adjustedPtX2, 10+nMargin/2 +adjustedPtY2, scroll_width-nMargin+adjustedWidth2, scroll_height-nMargin+adjustedHeight2  );
            return rc;
//            rc = CGRectMake(135,10,165,165 );
//            return rc;
        }
        else if (sub == 10) {
//            rc = CGRectMake(106-nMargin/4,100-nMargin,96+nMargin/2,150+nMargin*2 );
            rc = CGRectMake(105+adjustedPtX2+nMargin/2,80+adjustedPtY2+nMargin/2,100-nMargin+adjustedWidth2,150-nMargin+adjustedHeight2 );
            return rc;
        }
        else if (sub == 11){
            scroll_width = 100;
            scroll_height = 200;
            rc = CGRectMake(105+adjustedPtX2+nMargin/2,92+adjustedPtY2+nMargin/2,100-nMargin+adjustedWidth2,200-nMargin+adjustedHeight2 );
//            rc = CGRectMake(105, 90-nMargin, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 12){
            scroll_width = 100;
            scroll_height = 260;//300
            rc = CGRectMake(105+adjustedPtX2+nMargin/2,25+adjustedPtY2+nMargin/2,100-nMargin+adjustedWidth2,261-nMargin+adjustedHeight2 );
//            rc = CGRectMake(105,25-nMargin, scroll_width, scroll_height+nMargin*2 );
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
            scroll_height = 220;
            rc = CGRectMake(155+adjustedPtX2+nMargin/2-5,47+adjustedPtY2,75-nMargin+adjustedWidth2+10,220-nMargin+adjustedHeight2 );
//            rc = CGRectMake(155-nMargin/2, 55-nMargin, scroll_width+nMargin, scroll_height+nMargin*2 );
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
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3+2;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = nMargin;
            nLeftMargin = nMargin * 2 + scroll_width-3;
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
              rc = CGRectMake(78+adjustedPtX2+nMargin/2,310-255+adjustedPtY2,77-nMargin+adjustedWidth2,250+adjustedHeight2 );
//            rc = CGRectMake(81, 310-255-nMargin, 71+nMargin/4, 250+nMargin );
            return rc;
        }
        else if (sub == 11){
             rc = CGRectMake(185+adjustedPtX2+nMargin,5+adjustedPtY2,100-nMargin+adjustedWidth2,150+adjustedHeight2 -nMargin);
//            rc = CGRectMake(190, 5, 100, 150 );
            return rc;
        }
        else if (sub == 12){
             rc = CGRectMake(130+adjustedPtX2,80+adjustedPtY2+nMargin/3,175-nMargin+adjustedWidth2,75+adjustedHeight2-nMargin );
//            rc = CGRectMake(130-nMargin*2, 80, 175+nMargin*2, 75 );
            return rc;
        }
        else if (sub == 13){
             rc = CGRectMake(10+adjustedPtX2+nMargin/2+5,180+adjustedPtY2-5,100-nMargin+adjustedWidth2,100+adjustedHeight2-nMargin );
//            rc = CGRectMake(10-nMargin/4, 180-nMargin/4, 100+nMargin/2, 100+nMargin/2 );
            return rc;
        }
        else if (sub == 14){
             rc = CGRectMake(205+adjustedPtX2+nMargin,75+adjustedPtY2,100-nMargin+adjustedWidth2,100+adjustedHeight2-nMargin );
//            rc = CGRectMake(205, 75, 100, 100  );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(200, 5, 175, 100 );
            return rc;
        }
        else if (sub == 16){
             rc = CGRectMake(106+adjustedPtX2+nMargin/2-5,5+adjustedPtY2+nMargin/2,96-nMargin+adjustedWidth2+10,96+adjustedHeight2-nMargin +7);
//            rc = CGRectMake(106-nMargin/4, 5, 96+nMargin/2, 96+nMargin );
            return rc;
        }
        else if (sub == 17){
            rc = CGRectMake(155, 0, 155, 155 );
            return rc;
        }
        else if (sub == 18){
             rc = CGRectMake(80+adjustedPtX2+nMargin/2,85+adjustedPtY2,110-nMargin+adjustedWidth2+5,310-90+adjustedHeight2-nMargin );
//            rc = CGRectMake(80-nMargin/4, 85-nMargin/4, 110+nMargin/2, 310-90+nMargin/4 );
            return rc;
        }
        
    }
    
    rc = CGRectMake(nLeftMargin+adjustedPtX2, nTopMargin+adjustedPtY2, scroll_width+adjustedWidth2, scroll_height+adjustedHeight2);
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
            rc = CGRectMake(152+nMargin+adjustedPtX3,310-96-5+nMargin+adjustedPtY3,150-nMargin+adjustedWidth3,102 -nMargin+adjustedHeight3);
            return rc;
        }
        else if (sub == 8) {
            rc = CGRectMake(206+nMargin/2+adjustedPtX3, 30+nMargin/2+adjustedPtY3, 96-nMargin+adjustedWidth3, 250-nMargin+adjustedHeight3 );
//            rc = CGRectMake(206,30-nMargin,96,250+nMargin*2 );
            return rc;
            
        } else if (sub == 9) {
            scroll_width = 105;
            scroll_height = 105;
            rc = CGRectMake(135+nMargin/2+adjustedPtX3, 180+nMargin/2 +adjustedPtY3-5, scroll_width-nMargin+adjustedWidth3, scroll_height-nMargin+adjustedHeight3  );
            return rc;
//            rc = CGRectMake(135,180-nMargin/4,100+nMargin+nMargin/4,100+nMargin+nMargin/4 );
//            return rc;
        }
        else if (sub == 10) {
            rc = CGRectMake(205+adjustedPtX3+nMargin,155+adjustedPtY3+nMargin,100-nMargin+adjustedWidth3,150-nMargin+adjustedHeight3 );
//            rc = CGRectMake(206,155-nMargin*2,96,150+nMargin*2 );
            return rc;
        }
        else if (sub == 11){
            scroll_width = 100;
            scroll_height = 200;
            rc = CGRectMake(205+adjustedPtX3+nMargin,22+adjustedPtY3,100-nMargin+adjustedWidth3,200-nMargin+adjustedHeight3 );
//            rc = CGRectMake(205, 20, scroll_width, scroll_height+nMargin*2 );
            return rc;
        }
        else if (sub == 12){
            scroll_width = 100;
            scroll_height = 100;
             rc = CGRectMake(205+adjustedPtX3+nMargin,108+adjustedPtY3,100-nMargin+adjustedWidth3,100-nMargin+adjustedHeight3 );
//            rc = CGRectMake(205, 105-nMargin, scroll_width, scroll_height+nMargin*2 );
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
            scroll_height = 220;
            rc = CGRectMake(235+adjustedPtX3+nMargin,47+adjustedPtY3,75-nMargin+adjustedWidth3,220-nMargin+adjustedHeight3 );
//            rc = CGRectMake(235, 55-nMargin, scroll_width, scroll_height+nMargin*2 );
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
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3+3;
            nLeftMargin = self.frameContainer.frame.size.width - nMargin - scroll_width;
            nTopMargin = nMargin * 2 + scroll_height-4;
        } else if (sub == 5) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 3 ) * 3 / 5;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 4 ) / 3+3;
            nTopMargin = nMargin * 2 + scroll_height-4;
            nLeftMargin = nMargin;
        } else if (sub == 6) {
            scroll_width = (self.frameContainer.frame.size.width - nMargin * 4 ) / 3+3;
            scroll_height = (self.frameContainer.frame.size.height - nMargin * 3 ) * 3 / 5;
            nTopMargin = self.frameContainer.frame.size.height - nMargin - scroll_height;
            nLeftMargin = nMargin * 2 + scroll_width-4;
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
            rc = CGRectMake(155+adjustedPtX3+nMargin,5+adjustedPtY3,78-nMargin+adjustedWidth3,250+adjustedHeight3 );
//            rc = CGRectMake(157, 5, 71+nMargin/4, 250+nMargin );
            return rc;
        }
        else if (sub == 11){
            rc = CGRectMake(85+adjustedPtX3+nMargin,155+adjustedPtY3,100-nMargin+adjustedWidth3,150+adjustedHeight3-nMargin );
//            rc = CGRectMake(85-nMargin, 160-nMargin/4, 100+nMargin+nMargin/4, 150+nMargin/4 );
            return rc;
        }
        else if (sub == 12){
            rc = CGRectMake(5+adjustedPtX3,310-155+adjustedPtY3+nMargin/3,175-nMargin+adjustedWidth3,75+adjustedHeight3-nMargin );
//            rc = CGRectMake(5, 310-155, 175+nMargin*2, 75 );
            return rc;
        }
        else if (sub == 13){
            rc = CGRectMake(115+adjustedPtX3+nMargin,180+adjustedPtY3-5,100-nMargin+adjustedWidth3,100+adjustedHeight3-nMargin );
//            rc = CGRectMake(115, 180-nMargin/4, 100+nMargin/2, 100+nMargin/2 );
            return rc;
        }
        else if (sub == 14){
            rc = CGRectMake(105+adjustedPtX3+nMargin/2,10+adjustedPtY3,100-nMargin+adjustedWidth3,100+adjustedHeight3-nMargin+10 );
//            rc = CGRectMake(105, 10, 100, 100 );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(105, 245, 175, 100 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(106+adjustedPtX3+nMargin/2-5,310-96-5+adjustedPtY3+nMargin/2-7,96-nMargin+adjustedWidth3+10,96+adjustedHeight3-nMargin +7);
//            rc = CGRectMake(106-nMargin/4, 310-96-5-nMargin, 96+nMargin/2, 96+nMargin );
            return rc;
        }
        else if (sub == 17){
            
            rc = CGRectMake(0, 155, 155, 155 );
            return rc;
        }
        else if (sub == 18){
            rc = CGRectMake(195+adjustedPtX3+nMargin,5+adjustedPtY3,110-nMargin+adjustedWidth3,310-75-15+adjustedHeight3-nMargin+5 );
//            rc = CGRectMake(195, 5, 110, 310-75-15+nMargin/4 );
            return rc;
        }
        
    }
    rc = CGRectMake(nLeftMargin+adjustedPtX3, nTopMargin+adjustedPtY3, scroll_width+adjustedWidth3, scroll_height+adjustedHeight3);

//    rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height);
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
            rc = CGRectMake(233+adjustedPtX4+nMargin,310-255+adjustedPtY4,77-nMargin+adjustedWidth4,250+adjustedHeight4 );
//            rc = CGRectMake(233, 310-255-nMargin, 71+nMargin/4, 250+nMargin );//250
            return rc;
        }
        else if (sub == 11){
            rc = CGRectMake(185+adjustedPtX4+nMargin,155+adjustedPtY4,100-nMargin+adjustedWidth4,150+adjustedHeight4-nMargin );
//            rc = CGRectMake(190, 160-nMargin/4, 100, 150 +nMargin/4);
            return rc;
        }
        else if (sub == 12){
            rc = CGRectMake(130+adjustedPtX4,310-80+adjustedPtY4+nMargin,175-nMargin+adjustedWidth4,75+adjustedHeight4-nMargin );
//            rc = CGRectMake(130-nMargin*2, 310-80, 175+nMargin*2, 75 );
            return rc;
        }
        else if (sub == 13){
            rc = CGRectMake(115+adjustedPtX4+nMargin,10+adjustedPtY4,185-nMargin+adjustedWidth4,165+adjustedHeight4-nMargin );
//            rc = CGRectMake(115, 10, 185+nMargin/4, 165 );
            return rc;
        }
        else if (sub == 14){
            rc = CGRectMake(105+adjustedPtX4+nMargin/2,310-180+adjustedPtY4-10,100-nMargin+adjustedWidth4,165+adjustedHeight4-nMargin+10 );
//            rc = CGRectMake(105, 310-180-nMargin, 100, 175+nMargin );
            return rc;
        }
        else if (sub == 15){
            rc = CGRectMake(130, 195, 175, 100 );
            return rc;
        }
        else if (sub == 16){
            rc = CGRectMake(207+adjustedPtX4+nMargin,5+adjustedPtY4+nMargin/2,96-nMargin+adjustedWidth4,300+adjustedHeight4-nMargin );
//            rc = CGRectMake(207, 5, 96, 300 );//330
            return rc;
        }
        else if (sub == 17){
            rc = CGRectMake(155, 155, 155, 155 );
            return rc;
        }
        else if (sub == 18){
            rc = CGRectMake(195+adjustedPtX4+nMargin,310-80+adjustedPtY4-1+nMargin,75-nMargin+adjustedWidth4,75+adjustedHeight4-nMargin+1 );
//            rc = CGRectMake(195, 310-80, 75+nMargin, 75 );
            return rc;
        }
    }
    rc = CGRectMake(nLeftMargin+adjustedPtX4, nTopMargin+adjustedPtY4, scroll_width+adjustedWidth4, scroll_height+adjustedHeight4);

//    rc = CGRectMake(nLeftMargin, nTopMargin, scroll_width, scroll_height);
    NSLog(@"Scroll 4 outside nLeftMargin=%f nTopMargin=%f width=%f,height=%f",nLeftMargin,nTopMargin,scroll_width,scroll_height);
    return rc;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    sleep(1);
    // Dispose of any resources that can be recreated.
}

@end
