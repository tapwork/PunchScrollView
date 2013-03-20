/*
 *
 *
 PunchScrollView.m
 
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

#import "PunchScrollView.h"

@interface PunchScrollView ()
{
    BOOL needsUpdateContentOffset_;
    BOOL needsReload_;
}

@property (nonatomic, readonly) CGSize pageSizeWithPadding;
@property (nonatomic, readonly) NSArray *storedPages;


@end

@implementation PunchScrollView
@synthesize dataSource = dataSource_;
@synthesize delegate = delegate_;

@synthesize pagePadding = pagePadding_;
@synthesize direction = direction_;
@synthesize infiniteScrolling = infiniteScrolling_;
@dynamic currentIndexPath;
@dynamic lastIndexPath;
@dynamic currentPage;
@dynamic firstPage;
@dynamic lastPage;
@dynamic pageController;


#pragma mark - init, dealloc & setup
- (id)init
{
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
    
}


- (id)initWithFrame:(CGRect)aFrame
{
    if ((self = [super initWithFrame:aFrame]))
	{
       	[self setup];
    }
    return self;
}


- (void)setup
{
    pageSizeWithPadding_ = CGSizeZero;
    
    self.pagePadding = 0;
    
    self.bouncesZoom = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    [super setDelegate:self];
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.directionalLockEnabled = YES;
    
    indexPaths_     = [[NSMutableArray alloc] init];
    recycledPages_  = [[NSMutableSet alloc] init];
    visiblePages_   = [[NSMutableSet alloc] init];
    
    UITapGestureRecognizer *tapGesutre = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnPage:)];
    [self addGestureRecognizer:tapGesutre];
    [tapGesutre release];
    
    [self setNeedsReload];
}



- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.dataSource = nil;
	self.delegate = nil;
	[indexPaths_ release];
	indexPaths_ = nil;
	[recycledPages_ release];
	recycledPages_ = nil;
	[visiblePages_ release];
	visiblePages_ = nil;
    [pageController_ release];
    pageController_ = nil;
    
    [super dealloc];
}



#pragma mark -
#pragma mark Public Methods
- (void)setDataSource:(id <PunchScrollViewDataSource>)thedataSource
{
	if (dataSource_ != thedataSource)
    {
        dataSource_ = thedataSource;
        if (dataSource_ != nil)
        {
            [self setNeedsReload];
        }
    }
}

- (void)setDelegate:(id<PunchScrollViewDelegate>)aDelegate
{
    [super setDelegate:self];
    
    if (aDelegate != self->delegate_)
    {
        self->delegate_ = aDelegate;
        if (aDelegate != nil)
        {
            [self setNeedsReload];
        }
    }
}


- (UIView *)dequeueRecycledPage
{
    UIView *page = [recycledPages_ anyObject];
    if (page)
    {
        [[page retain] autorelease];
        [recycledPages_ removeObject:page];
        [page removeFromSuperview];
    }
    return page;
}


- (UIView*)pageForIndexPath:(NSIndexPath*)indexPath
{
    
    for (UIView *thePage in self.storedPages)
	{
		if ((NSNull*)thePage == [NSNull null]) break;
		NSIndexPath *storedIndexPath = [self indexPathForIndex:thePage.tag];
		
        if (storedIndexPath.row == indexPath.row &&
            storedIndexPath.section == indexPath.section)
		{
            return thePage;
        }
    }
	
	
    return nil;
}

- (void)scrollToIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated
{
    
    void (^block)() = ^(){
        
        NSInteger pageNum = [indexPaths_ indexOfObject:indexPath];
        
        if (self.infiniteScrolling &&
            (pageNum < [self pagesCount]-1))
        {
            pageNum += 1;
        }
        
        [self scrollToIndex:pageNum animated:animated];
    };
    
    dispatch_async(dispatch_get_main_queue(), block);
}

- (void)scrollToNextPage:(BOOL)animated
{
    void (^block)() = ^(){
        
        NSInteger page = currentPageIndex_ + 1;
        if (self.infiniteScrolling)
        {
            if (page < [self pagesCount]-1)
            {
                page += 1;
            }
            else
            {
                page = 1;
            }
        }
        if (page < [self pagesCount])
        {
            [self scrollToIndex:page animated:YES];
        }
    };
    
    dispatch_async(dispatch_get_main_queue(), block);
}

- (void)scrollToPreviousPage:(BOOL)animated
{
    void(^block)() = ^(){
        
        NSInteger page = currentPageIndex_ - 1;
        if (self.infiniteScrolling)
        {
            if (page == - 1)
            {
                page = 0;
            }
            else
            {
                page += 1;
            }
        }
        if (page >= 0)
        {
            [self scrollToIndex:page animated:YES];
        }
    };
	
    dispatch_async(dispatch_get_main_queue(), block);
}


- (NSIndexPath*)currentIndexPath
{
	if (currentPageIndex_ >= [indexPaths_ count])
    {
        return nil;
    }
    return [self indexPathForIndex:currentPageIndex_];
}

- (NSIndexPath*)lastIndexPath
{
	return [indexPaths_ lastObject];
}

- (UIView*)currentPage
{
    return [self pageForIndexPath:self.currentIndexPath];
}

- (NSMutableSet*)visiblePages
{
    return visiblePages_;
}

- (UIView*)firstPage
{
    return [self pageForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (UIView*)lastPage
{
    return [self pageForIndexPath:self.lastIndexPath];
}

- (NSArray*)pageController
{
    return pageController_;
}

- (void)reloadData
{
    [self setIndexPaths];
    
    pageSizeWithPadding_    = CGSizeZero;
    currentWidth_           = 0.0;
    
    for (UIView *view in self.storedPages)
    {
        [view removeFromSuperview];
        view = nil;
    }
    
    [visiblePages_ removeAllObjects];
    [recycledPages_ removeAllObjects];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    needsReload_ = NO;
    
}

- (void)setPagePadding:(CGFloat)pagePadding
{
    if (pagePadding_ != pagePadding)
    {
        pagePadding_ = pagePadding;
        
        CGRect frame = self.frame;
        if (direction_ == PunchScrollViewDirectionHorizontal)
        {
            frame.origin.x -= self.pagePadding;
            frame.size.width += (2 * self.pagePadding);
        }
        else if (direction_ == PunchScrollViewDirectionVertical)
        {
            frame.origin.y -= self.pagePadding;
            frame.size.height += (2 * self.pagePadding);
        }
        
        [super setFrame:frame];
        [self setNeedsReload];
    }
}


- (void)setDirection:(PunchScrollViewDirection)direction
{
    if (direction_ != direction)
    {
        direction_ = direction;
        [self setNeedsReload];
    }
}

- (void)setInfiniteScrolling:(BOOL)infiniteScrolling
{
    if (infiniteScrolling_ != infiniteScrolling)
    {
        infiniteScrolling_ = infiniteScrolling;
        [self setNeedsReload];
    }
}

- (BOOL)infiniteScrolling
{
    if ([indexPaths_ count] <= 1)
    {
        return NO;
    }
    
    return infiniteScrolling_;
}

#pragma mark -
#pragma mark Private methods
- (void)layoutSubviews
{
	[super layoutSubviews];
    
    
    needsUpdateContentOffset_ = NO;
	if (currentWidth_ != self.frame.size.width)
	{
        needsUpdateContentOffset_ = YES;
        pageSizeWithPadding_ = CGSizeZero;
	}
	
	currentWidth_ = self.frame.size.width;
	
    [self updateContentSize];
    
	if (needsUpdateContentOffset_ == YES)
	{
        NSInteger page = currentPageIndex_;
        // do some inifinite scrolling tricks
        if (self.infiniteScrolling &&
            page < [self pagesCount]-1)
        {
            page += 1;
        }
        
        if (direction_ == PunchScrollViewDirectionHorizontal)
        {
            [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*page, 0)
                          animated:NO];
            
        }
        else if (direction_ == PunchScrollViewDirectionVertical)
        {
            [self setContentOffset:CGPointMake(0, self.pageSizeWithPadding.height*page)
                          animated:NO];
        }
        
        [self updateFrameForAvailablePages];
    }
    
    if (self.infiniteScrolling == YES &&
        needsUpdateContentOffset_ == NO)
    {
        [self recenterForInfiniteIfNecessary];
    }
    
    needsUpdateContentOffset_ = NO;
    
    [self loadPages];
}



- (void)recenterForInfiniteIfNecessary
{
    // when we reach the end or beginning we change the offset again
    if (self.direction == PunchScrollViewDirectionHorizontal &&
        self.contentOffset.x + self.pageSizeWithPadding.width >= self.contentSize.width )
    {
        [self setContentOffset:CGPointMake(0,0)
                      animated:NO];
    }
    else if (self.direction == PunchScrollViewDirectionVertical &&
             self.contentOffset.y + self.pageSizeWithPadding.height >= self.contentSize.height )
    {
        [self setContentOffset:CGPointMake(0,0)
                      animated:NO];
    }
    else if (self.direction == PunchScrollViewDirectionHorizontal &&
             self.contentOffset.x <= 0.0 )
    {
        [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*([self pagesCount]-1), 0)
                      animated:NO];
    }
    else if (self.direction == PunchScrollViewDirectionVertical &&
             self.contentOffset.y <= 0.0 )
    {
        [self setContentOffset:CGPointMake(0, self.pageSizeWithPadding.height*([self pagesCount]-1))
                      animated:NO];
    }
}

- (void)loadPages
{
    if ([self pagesCount]  == 0 ||
        (self.dataSource == nil))
    {
        
        // do not render the pages if there is not at least one page
        
        return;
    }
    
    int lazyOfLoadingPages = 0;
    NSMutableArray *controllerViewsToDelete = [[NSMutableArray alloc] init];
    
    if ([self.dataSource respondsToSelector:@selector(numberOfLazyLoadingPages)])
    {
        lazyOfLoadingPages = [self.dataSource numberOfLazyLoadingPages]-1;
    }
    
    // Calculate which pages are visible
    CGRect visibleBounds = self.bounds;
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = ceil(CGRectGetMaxX(visibleBounds) / self.pageSizeWithPadding.width);
    
    if (direction_ == PunchScrollViewDirectionVertical)
    {
        firstNeededPageIndex = floorf(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds));
        lastNeededPageIndex  = ceil(CGRectGetMaxY(visibleBounds) / self.pageSizeWithPadding.height);
    }
    
    firstNeededPageIndex = MAX(firstNeededPageIndex-lazyOfLoadingPages-1, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex+lazyOfLoadingPages, [self pagesCount] - 1);
    
    // Recycle no-longer-visible pages
    for (UIView *page in visiblePages_)
    {
        int indexToDelete = page.tag;
        if (indexToDelete < firstNeededPageIndex ||
            indexToDelete > lastNeededPageIndex)
        {
            //
            // If we work in controller mode
            if (pageController_ != nil &&
                indexToDelete >= 0 &&
                indexToDelete < [pageController_ count])
            {
                UIViewController *vc = [pageController_ objectAtIndex:indexToDelete];
                [controllerViewsToDelete addObject:vc];
            }
            //
            // if we work in view mode
            else if (pageController_ == nil)
            {
                [recycledPages_ addObject:page];
            }
            
        }
    }
    
    [visiblePages_ minusSet:recycledPages_];
    
    //
    // Force Deletion
    for (UIViewController *vc in controllerViewsToDelete)
    {
        if ([vc isViewLoaded])
        {
            [visiblePages_ removeObject:vc.view];
            if ([self.delegate respondsToSelector:@selector(punchScrollView:unloadPage:forController:)])
            {
                [self.delegate punchScrollView:self unloadPage:vc.view forController:vc];
            }
            vc.view = nil;
        }
    }
    [controllerViewsToDelete release];
    
    
    //
    // add missing pages
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++)
    {
        if (![self isDisplayingPageForIndex:index])
		{
            NSInteger indexToAsk = index;
            //
            // some xtra tricks for infinite scrolling here
            if (self.infiniteScrolling &&
                (index == 0 || index == [self pagesCount]-1))
            {
                indexToAsk = [self pagesCount]-2;
            }
            else if (self.infiniteScrolling)
            {
                indexToAsk = index - 1;
            }
            //
            // end extra tricks
            
			UIView *page = [self askDataSourceForPageAtIndex:indexToAsk];
			if (nil != page)
			{
				page.tag = index;
				[page layoutIfNeeded];
                page.frame = [self frameForPageAtIndex:index withSize:page.frame.size];
				[self addSubview:page];
				[visiblePages_ addObject:page];
                
			}
			else
			{
				[visiblePages_ addObject:[NSNull null]];
			}
        }
    }
}

- (UIView*)askDataSourceForPageAtIndex:(NSInteger)index
{
    UIView *page = nil;
    
    if ([self.dataSource respondsToSelector:@selector(punchScrollView:controllerForPageAtIndexPath:)])
    {
        if (pageController_ == nil)
        {
            pageController_ = [[NSMutableArray alloc] init];
        }
        
        UIViewController *controller = [self.dataSource
                                        punchScrollView:self
                                        controllerForPageAtIndexPath:[self indexPathForIndex:index]];
        if (![pageController_ containsObject:controller] &&
            controller != nil)
        {
            [pageController_ addObject:controller];
        }
        
        page = controller.view;
        
    }
    else if ([self.dataSource respondsToSelector:@selector(punchScrollView:viewForPageAtIndexPath:)])
    {
        page = [self.dataSource punchScrollView:self viewForPageAtIndexPath:[self indexPathForIndex:index]];
    }
    
    
    return page;
}


- (void)setNeedsReload
{
    if (needsReload_ == NO)
    {
        needsReload_ = YES;
        __block PunchScrollView *blockself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockself reloadData];
        });
    }
}

- (NSArray*)storedPages
{
    NSArray *storedPages = [NSArray arrayWithArray:[recycledPages_ allObjects]];
    
    return [storedPages arrayByAddingObjectsFromArray:[visiblePages_ allObjects]];
}

- (BOOL)isDisplayingPageForIndex:(NSInteger)index
{
    BOOL foundPage = NO;
    for (UIView *page in visiblePages_)
    {
        if (page.tag == index)
        {
            return YES;
        }
    }
    return foundPage;
}


- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated
{
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        
        [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*index,
                                           0)
                      animated:animated];
    }
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        [self setContentOffset:CGPointMake(0,
                                           self.pageSizeWithPadding.height*index)
                      animated:animated];
    }
    if (animated == NO)
    {
        [self pageIndexChanged];
    }
    
}


- (void)tapOnPage:(UIGestureRecognizer*)gesture
{
    if ([self.delegate respondsToSelector:@selector(punchScrollView:didTapOnPage:atIndexPath:)])
    {
        if ([gesture state] == UIGestureRecognizerStateRecognized)
        {
            // if this gesture intercepts any of the views, then inform the delegate
            CGPoint p = [gesture locationInView:self];
            for (UIView *v in visiblePages_)
            {
                if (CGRectContainsPoint(v.frame, p))
                {
                    [self.delegate punchScrollView:self
                                      didTapOnPage:v
                                       atIndexPath:[self indexPathForIndex:v.tag]];
                    return;
                }
            }
        }
        
    }
}



#pragma mark -
#pragma mark ScrollView delegate methods


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    //
    // Check if the page really has changed
    //
    BOOL pageChanged = NO;
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        if ( (int)(self.contentOffset.x) % MAX((int)(self.pageSizeWithPadding.width),1) == 0)
        {
            pageChanged = YES;
        }
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        if ( (int)(self.contentOffset.y) % MAX((int)(self.pageSizeWithPadding.height),1) == 0)
        {
            pageChanged = YES;
        }
    }
    
    
    if (pageChanged == YES &&
        needsUpdateContentOffset_ == NO)
    {
        [self pageIndexChanged];
    }
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)])
    {
        [self.delegate performSelector:@selector(scrollViewDidScroll:) withObject:self];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)])
    {
        [self.delegate performSelector:@selector(scrollViewWillBeginDragging:) withObject:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
    {
        [self.delegate scrollViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
    {
        [self.delegate performSelector:@selector(scrollViewDidEndDecelerating:) withObject:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
    {
        [self.delegate performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:self];
    }
}


- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView   // called on finger up as we are moving
{
    if ([self.delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)])
    {
        [self.delegate performSelector:@selector(scrollViewWillBeginDecelerating:) withObject:self];
    }
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)])
    {
        [self.delegate performSelector:@selector(scrollViewDidScrollToTop:) withObject:self];
    }
}




#pragma mark -
#pragma mark Page &  Frame calculations
- (void)pageIndexChanged
{
    NSInteger newPageIndex = NSNotFound;
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        CGFloat pageWidth = floorf(self.pageSizeWithPadding.width);
        newPageIndex = floorf(self.contentOffset.x /
                              ( (pageWidth == 0) ? 1 : pageWidth) );
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        CGFloat pageHeight = floorf(self.pageSizeWithPadding.height);
        newPageIndex = floorf(self.contentOffset.y /
                              ( (pageHeight == 0) ? 1 : pageHeight) );
    }
    
    if (self.infiniteScrolling)
    {
        if (newPageIndex == 0)
        {
            newPageIndex = [self pagesCount]-2;
        }
        else
        {
            newPageIndex -= 1;
        }
    }
    if (newPageIndex != currentPageIndex_)
    {
        currentPageIndex_ = newPageIndex;
        if ([self.delegate respondsToSelector:@selector(punchScrollView:pageChanged:)] &&
            [indexPaths_ count] > 0)
        {
            [self.delegate punchScrollView:self
                               pageChanged:[self indexPathForIndex:currentPageIndex_]];
        }
	}
}



- (void)updateContentSize
{
    NSInteger pagesCount = [self pagesCount];
    
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        self.contentSize = CGSizeMake(self.pageSizeWithPadding.width * pagesCount,
                                      self.pageSizeWithPadding.height);
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        self.contentSize = CGSizeMake(self.pageSizeWithPadding.width,
                                      self.pageSizeWithPadding.height * pagesCount);
    }
}


- (void)updateFrameForAvailablePages
{
	for (UIView *page in self.storedPages)
	{
		if ((NSNull*)page != [NSNull null])
        {
            page.frame = [self frameForPageAtIndex:page.tag
                                          withSize:page.frame.size];
        }
	}
}

- (CGRect)frameForPageAtIndex:(NSInteger)index withSize:(CGSize)size
{
    CGRect pageFrame = CGRectMake(self.bounds.origin.x,
                                  self.bounds.origin.y,
                                  size.width,
                                  size.height);
    
    
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        pageFrame.origin.x = (self.pageSizeWithPadding.width * index) + self.pagePadding;
        pageFrame.origin.y = 0;
    }
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        pageFrame.origin.x = 0;
        pageFrame.origin.y = (self.pageSizeWithPadding.height * index) + self.pagePadding;
    }
    
    
    
    
    return pageFrame;
}



- (CGSize)pageSizeWithPadding
{
    if ([indexPaths_ count] == 0)
    {
        pageSizeWithPadding_ = CGSizeZero;
        
        return pageSizeWithPadding_;
    }
    
    CGSize size = pageSizeWithPadding_;
    if (CGSizeEqualToSize(size,CGSizeZero))
    {
        UIView *page = [self.storedPages lastObject];
        if (page == nil)
        {
            page = [self askDataSourceForPageAtIndex:0];
        }
        if (page != nil)
        {
            size = page.bounds.size;
            
            if (direction_ == PunchScrollViewDirectionHorizontal)
            {
                size = CGSizeMake(size.width+(2*self.pagePadding),size.height);
            }
            else if (direction_ == PunchScrollViewDirectionVertical)
            {
                size = CGSizeMake(size.width,size.height+(2*self.pagePadding));
            }
            
            pageSizeWithPadding_ = size;
        }
    }
    
    
    return pageSizeWithPadding_;
}


- (NSUInteger)sectionCount
{
	if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInPunchScrollView:)])
    {
        return [self.dataSource numberOfSectionsInPunchScrollView:self];
    }
    return 1;
}

- (NSUInteger)pagesCount
{
    if (self.infiniteScrolling)
    {
        return [indexPaths_ count] + 1;
    }
    return [indexPaths_ count];
}


- (void)setIndexPaths
{
	[indexPaths_ removeAllObjects];
    
    for (int section = 0; section < [self sectionCount]; section++)
	{
		NSUInteger rowsInSection = 1;
		if ([self.dataSource respondsToSelector:@selector(punchscrollView:numberOfPagesInSection:)])
		{
			rowsInSection = [self.dataSource punchscrollView:self numberOfPagesInSection:section];
		}
		
		for (int row = 0; row < rowsInSection; row++)
		{
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
			[indexPaths_ addObject:indexPath];
		}
	}
}

- (NSIndexPath*)indexPathForIndex:(NSInteger)index
{
    if (index < [indexPaths_ count] &&
        index >= 0)
    {
        return [indexPaths_ objectAtIndex:index];
    }
    
    return nil;
}

@end


#pragma mark
#pragma mark IndexPath Category
@implementation NSIndexPath (PunchScrollView)


+ (NSIndexPath *)indexPathForPage:(NSUInteger)page inSection:(NSUInteger)section
{
    NSUInteger indexArr[] = {section,page};
    return [NSIndexPath indexPathWithIndexes:indexArr length:2];
}

- (NSUInteger)section
{
    return [self indexAtPosition:0];
}


- (NSUInteger)page
{
    return [self indexAtPosition:1];
}

@end
