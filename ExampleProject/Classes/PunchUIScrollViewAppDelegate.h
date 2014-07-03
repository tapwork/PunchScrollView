//
//  PunchUIScrollViewAppDelegate.h
//  PunchUIScrollView
//
//  Created by tapwork. on 20.10.10. 
//
//  Copyright 2010 tapwork. mobile design & development. All rights reserved.
//  tapwork.de

#import <UIKit/UIKit.h>

@class PunchUIScrollViewViewController;

@interface PunchUIScrollViewAppDelegate : UIResponder <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet PunchUIScrollViewViewController *viewController;

@end

