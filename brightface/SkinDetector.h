//
//  SkinDetector.h
//  brightface
//
//  Created by Saswata Basu on 12/31/14.
//  Copyright (c) 2014 Saswata Basu. All rights reserved.
//

#ifndef brightface_SkinDetector_h
#define brightface_SkinDetector_h


#endif

//SkinDetector.h


#pragma once
//#include <opencv/cv.h>

using namespace std;
class SkinDetector
{
public:
    SkinDetector(void);
    ~SkinDetector(void);
    
    cv::Mat getSkin(cv::Mat input);
    
private:
    int Y_MIN;
    int Y_MAX;
    int Cr_MIN;
    int Cr_MAX;
    int Cb_MIN;
    int Cb_MAX;
};

// end of SkinDetector.h file


