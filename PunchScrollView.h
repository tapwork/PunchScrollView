/*
 *
 *
 PunchScrollView.h
 
 If you are using iOS 6:
 I suggest using UICollectionViewController
 Therefore we will stop developing on PunchScrollView
 
 Created by tapwork. on 20.10.10.
 tapwork.net
 
 Copyright (C) 2010,2011,2012 tapwork. mobile design & development. All rights reserved.
 
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 *
 */

#import <UIKit/UIKit.h>
// This notification is sent out after the page has been changed
// it comes with an userInfo Dictionary including the 3 following keys 
extern NSString *const PunchScrollViewPageChangedNotification;

extern NSString *const PunchScrollViewUserInfoNewPageIndexPathKey;  // an NSIndexPath
extern NSString *const PunchScrollViewUserInfoNewPageFlattenedIndexKey;  // an NSNumber
extern NSString *const PunchScrollViewUserInfoTotalPagesNumberKey;  // an NSNumber

@class PunchScrollView;

/*
 *  PunchScrollView Delegate Methods
 *
 */

@protocol PunchScrollViewDelegate <UIScrollViewDelegate>
@optional

/*
 Called when the page will be unloaded & if you are using
 the dataSource method
 - (UIViewController*)punchScrollView:(PunchScrollView*)scrollView controllerForPageAtIndexPath:(NSIndexPath *)indexPath;
 we used to call "viewDidUnload" - but this method will be deprecated in iOS 6
 destroy all your views or memory consuming stuff in that delegate call

 */
- (void)punchScrollView:(PunchScrollView*)scrollView
             unloadPage:(UIView*)view
          forController:(UIViewController*)controller;


//
// Called when page has changed
//
- (void)punchScrollView:(PunchScrollView*)scrollView pageChanged:(NSIndexPath*)indexPath;

//
// Called when page has been tapped
//
- (void)punchScrollView:(PunchScrollView*)scrollView didTapOnPage:(UIView*)view atIndexPath:(NSIndexPath*)indexPath;

@end


/*
 * PunchScrollView DataSource Methods
 *
 */

@protocol PunchScrollViewDataSource <UIScrollViewDelegate>

@required

- (NSInteger)punchscrollView:(PunchScrollView *)scrollView numberOfPagesInSection:(NSInteger)section;

@optional

- (NSInteger)numberOfSectionsInPunchScrollView:(PunchScrollView *)scrollView;        // Default is 1 if not implemented

- (UIView*)punchScrollView:(PunchScrollView*)scrollView viewForPageAtIndexPath:(NSIndexPath *)indexPath;

- (UIViewController*)punchScrollView:(PunchScrollView*)scrollView controllerForPageAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfLazyLoadingPages;

@end



typedef enum {
    PunchScrollViewDirectionHorizontal = 0,
    PunchScrollViewDirectionVertical = 1,
} PunchScrollViewDirection;



@interface PunchScrollView : UIScrollView <UIScrollViewDelegate> {

}


// Set the dataSource
@property (nonatomic, weak) id <PunchScrollViewDataSource> dataSource;

// set the delegate
@property (nonatomic, weak) id <PunchScrollViewDelegate> delegate;

// Set the padding (gap) between pages. Default is 10pt
@property (nonatomic, assign) CGFloat pagePadding;

// Set a Vertical or horizontal direction of the scrolling
@property (nonatomic, assign) PunchScrollViewDirection direction;

//  Get the current visible page
@property (nonatomic, readonly) UIView *currentPage;

//  Get the first page
@property (nonatomic, readonly) UIView *firstPage;

//  Get the last page
@property (nonatomic, readonly) UIView *lastPage;

// get all visible pages
@property (nonatomic, readonly) NSMutableSet *visiblePages;

//  Get the current visible indexPath
@property (nonatomic, readonly) NSIndexPath *currentIndexPath;

//  Get the last indexPath
@property (nonatomic, readonly) NSIndexPath *lastIndexPath;

// 0 if no dataSource, otherwise, whatever it got from him
@property (nonatomic, readonly) NSUInteger numPagesInDataSource;  

//  Get all page controller if given
@property (nonatomic, readonly) NSArray *pageController;

//  set to a inifinite scolling experience (=> carrousel)   Default is NO
@property (nonatomic, assign) BOOL infiniteScrolling;


/*
 * Init Method for PunchScrollView
 *
 */
- (instancetype)init;
- (instancetype)initWithFrame:(CGRect)aFrame;

/*
 * This Method returns a UIView which is in the Queue
 */
- (UIView *)dequeueRecycledPage;


/*
 * This Method reloads the data in the scrollView
 */
- (void)reloadData;


/*
 * This Method returns an UIView (when visible, if not visible PunchScrollView will ask
 *   the dataSource for the view) for a given indexPath
 *
 */
- (UIView*)pageForIndexPath:(NSIndexPath*)indexPath;


/*
 * This method returns an integer which represents the overall index over all sections
 * i.e. PunchScrollView has 2 sections with 2 rows for each section ( [0,0];[0,1];[1,0];[1,1] )
 * then the NSIndexPath [1,1] will have the index: 4
 * 
 *
 */
- (NSInteger)flattenedIndexForIndexPath:(NSIndexPath*)indexPath;


/*
 * Some Scrolling to page methods
 *
 */
- (void)scrollToIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated;
- (void)scrollToNextPage:(BOOL)animated;
- (void)scrollToPreviousPage:(BOOL)animated;


@end


// This category provides convenience methods to make it easier to use an NSIndexPath to represent a section and page
@interface NSIndexPath (PunchScrollView)

+ (NSIndexPath *)indexPathForPage:(NSUInteger)page inSection:(NSUInteger)section;

@property(nonatomic,readonly) NSUInteger section;
@property(nonatomic,readonly) NSUInteger page;

@end
