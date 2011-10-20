//
//  PunchUIScrollViewViewController.h
//  PunchUIScrollView
//
//  Created by tapwork. on 20.10.10. 
//
//  Copyright 2010 tapwork. mobile design & development. All rights reserved.
//  tapwork.de

#import <UIKit/UIKit.h>
#import "PunchScrollView.h"


@interface PunchUIScrollViewViewController : UIViewController <UIScrollViewDelegate, PunchScrollViewDataSource, PunchScrollViewDelegate> {

	PunchScrollView *scrollView_;
}

@end

