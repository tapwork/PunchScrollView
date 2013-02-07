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
 Please destroy all your views in that delegate call
 
 otherwise your app will leak!!
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



//
// The standard UIScrollView Delegates
//
- (void)scrollViewDidScroll:(PunchScrollView *)scrollView;

- (void)scrollViewWillBeginDragging:(PunchScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(PunchScrollView *)scrollView willDecelerate:(BOOL)decelerate;

- (void)scrollViewDidEndDecelerating:(PunchScrollView *)scrollView;
- (void)scrollViewWillBeginDecelerating:(PunchScrollView *)scrollView;

- (void)scrollViewDidScrollToTop:(PunchScrollView *)scrollView;
- (void)scrollViewDidEndScrollingAnimation:(PunchScrollView *)scrollView;

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
	
	id <PunchScrollViewDataSource> dataSource_;
	id <PunchScrollViewDelegate> delegate_;
    
	NSMutableSet                    *recycledPages_;
    NSMutableSet                    *visiblePages_;
    NSMutableArray                  *pageController_;
    
	NSInteger                       currentPageIndex_;
	NSMutableArray                  *indexPaths_;
	CGFloat                         currentWidth_;
    CGFloat                         pagePadding_;
    CGSize                          pageSizeWithPadding_;
    PunchScrollViewDirection        direction_;
}


// Set the dataSource
@property (nonatomic, assign) id <PunchScrollViewDataSource> dataSource;

// set the delegate
@property (nonatomic, assign) id <PunchScrollViewDelegate> delegate;

// Set the padding between pages. Default is 10pt
@property (nonatomic, assign) CGFloat             pagePadding;

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

//  Get all page controller if given
@property (nonatomic, readonly) NSArray *pageController;



/*
 * Init Method for PunchScrollView
 *
 */
- (id)init;
- (id)initWithFrame:(CGRect)aFrame;

/*
 * This Method returns a UIView which is in the Queue
 */
- (UIView *)dequeueRecycledPage;


/*
 * This Method reloads the data in the scrollView
 */
- (void)reloadData;


/*
 * This Method returns an UIView for a given indexPath
 *
 */
- (UIView*)pageForIndexPath:(NSIndexPath*)indexPath;

/*
 * Some Scrolling to page methods
 *
 */
- (void)scrollToIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated;
- (void)scrollToNextPage:(BOOL)animated;
- (void)scrollToPreviousPage:(BOOL)animated;


@end



