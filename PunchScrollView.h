//
//  PunchScrollView.h
//  
//
//  Created by tapwork. on 20.10.10. 
//
//  Copyright 2010 tapwork. mobile design & development. All rights reserved.
//  tapwork.de
//

#import <UIKit/UIKit.h>


@protocol PunchScrollViewDataSource;
@protocol PunchScrollViewDelegate;

typedef enum {
    PunchScrollViewDirectionHorizontal = 0,
    PunchScrollViewDirectionVertical = 1,
} PunchScrollViewDirection;

@interface PunchScrollView : UIScrollView <UIScrollViewDelegate> {
	
	id <PunchScrollViewDataSource> punchDataSource_;
	id <PunchScrollViewDelegate> punchDelegate_;
    
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


// Set the DataSource for the Scroll Suite
@property (nonatomic, assign) id <PunchScrollViewDataSource> punchDataSource;  

// set the Delegate for the Scroll Suite
@property (nonatomic, assign) id <PunchScrollViewDelegate> punchDelegate;

// Set the padding between pages. Default is 10pt
@property (nonatomic, assign) CGFloat             pagePadding;       

// Set a Vertical or Horizontal Direction of the scrolling
@property (nonatomic, assign) PunchScrollViewDirection direction;                              

//  Get the current visible Page
@property (nonatomic, readonly) UIView *currentPage;  

//  Get the first Page
@property (nonatomic, readonly) UIView *firstPage;    

//  Get the last Page
@property (nonatomic, readonly) UIView *lastPage;         

//  Get the current visible indexPath
@property (nonatomic, readonly) NSIndexPath *currentIndexPath;       

//  Get the last indexPath of the Scroll Suite
@property (nonatomic, readonly) NSIndexPath *lastIndexPath; 

//  Get all Page Controller if given
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



/* 
 *  PunchScrollView Delegate Methods
 *
 */

@protocol PunchScrollViewDelegate <NSObject>

@optional

- (void)punchScrollView:(PunchScrollView*)scrollView pageChanged:(NSIndexPath*)indexPath;


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

@protocol PunchScrollViewDataSource <NSObject>

@required

- (NSInteger)punchscrollView:(PunchScrollView *)scrollView numberOfPagesInSection:(NSInteger)section;

@optional

- (NSInteger)numberOfSectionsInPunchScrollView:(PunchScrollView *)scrollView;        // Default is 1 if not implemented

- (UIView*)punchScrollView:(PunchScrollView*)scrollView viewForPageAtIndexPath:(NSIndexPath *)indexPath;

- (UIViewController*)punchScrollView:(PunchScrollView*)scrollView controllerForPageAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfLazyLoadingPages;

@end

