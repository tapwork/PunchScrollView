//
//  PunchScrollView.m
//  
//
//  Created by tapwork. on 20.10.10. 
//
//  Copyright 2010 tapwork. mobile design & development. All rights reserved.
//  tapwork.de

#import "PunchScrollView.h"


@interface PunchScrollView (Private)

@property (nonatomic, readonly) CGSize originalPageSizeWithPadding;
- (UIView*)askDataSourceForPageAtIndex:(NSInteger)index;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (CGRect)frameForPageAtIndex:(NSUInteger)index withSize:(CGSize)size;
- (void)updateFrameForVisiblePages;
- (void)updateContentSize;
- (void)loadPages;
- (void)pageIndexChanged;
- (void)setIndexPaths;
- (NSUInteger)sectionCount;
- (NSUInteger)pagesCount;
- (NSIndexPath*)indexPathForIndex:(NSInteger)index;


@end

@implementation PunchScrollView
@synthesize punchDataSource = punchDataSource_;
@synthesize punchDelegate = punchDelegate_;

@synthesize pagePadding = pagePadding_;
@synthesize direction = direction_;

@dynamic currentIndexPath;
@dynamic lastIndexPath;
@dynamic currentPage;
@dynamic firstPage;
@dynamic lastPage;
@dynamic pageController;

- (id)init
{
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if ((self = [super initWithFrame:aFrame]))
	{
		originalFrame_ = aFrame;
        originalPageSizeWithPadding_ = CGSizeZero;
        
        self.pagePadding = 10;
        
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.delegate = self;  
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.pagingEnabled = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		self.directionalLockEnabled = YES;
		
		indexPaths_     = [[NSMutableArray alloc] init];
		recycledPages_  = [[NSMutableSet alloc] init];
		visiblePages_   = [[NSMutableSet alloc] init];
		pageController_ = [[NSMutableArray alloc] init];
		
		
    }
    return self;
}



- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.punchDataSource = nil;
	self.punchDelegate = nil;
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
#pragma mark PunchScrollView Public Methods

- (UIView *)dequeueRecycledPage
{
    UIView *page = [recycledPages_ anyObject];
    if (page)
    {
        [[page retain] autorelease];
        [recycledPages_ removeObject:page];
    }
    return page;
}

- (UIView*)pageForIndexPath:(NSIndexPath*)indexPath
{
    NSArray *storedPages = [NSArray arrayWithArray:[recycledPages_ allObjects]];
    storedPages = [storedPages arrayByAddingObjectsFromArray:[visiblePages_ allObjects]];

    for (UIView *thePage in storedPages)
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
	NSInteger pageNum = 0;
    
    BOOL indexPathFound = NO;
	for (NSIndexPath *storedPath in indexPaths_)
	{
		if (storedPath.section == indexPath.section && storedPath.row == indexPath.row)
		{
			indexPathFound = YES;
            break;
		}
        
		pageNum++;
	}
	
    if (indexPathFound == NO)
    {
        // The indexPath is not avaiable. go out, but do not crash and burn
        return;
    }
    
    
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        
        [self setContentOffset:CGPointMake(self.originalPageSizeWithPadding.width*pageNum,
                                           0)
                      animated:animated];
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        [self setContentOffset:CGPointMake(0,
                                           self.originalPageSizeWithPadding.height*pageNum)
                      animated:animated];
    }
	if (animated == NO)
	{
		[self pageIndexChanged];
	}
}

- (void)scrollToNextPage:(BOOL)animated
{
	NSIndexPath *indexPath = [self indexPathForIndex:currentPageIndex_+1];
    
    if (indexPath != nil)
    {
        [self scrollToIndexPath:indexPath animated:animated];
        if (animated == NO)
        {
            [self pageIndexChanged];
        }
    }
}

- (void)scrollToPreviousPage:(BOOL)animated
{
	NSIndexPath *indexPath = [self indexPathForIndex:currentPageIndex_-1];
    
    if (indexPath != nil)
    {
        [self scrollToIndexPath:indexPath animated:animated];
        if (animated == NO)
        {
            [self pageIndexChanged];
        }	
    }
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
    
    currentPageIndex_ = 0;
    originalPageSizeWithPadding_ = CGSizeZero;
    [visiblePages_ removeAllObjects];
    [recycledPages_ removeAllObjects];
    
    [self adjustSelfFrame:originalFrame_];
    [self updateFrameForVisiblePages];
    [self updateContentSize];
    
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        [self setContentOffset:CGPointMake(self.originalPageSizeWithPadding.width*currentPageIndex_, 0) animated:NO];
    }
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        [self setContentOffset:CGPointMake(0, self.originalPageSizeWithPadding.height*currentPageIndex_) animated:NO];
    }
    
    
    // load the views in the next runloop
    [self performSelector:@selector(loadPages) withObject:nil afterDelay:0.0];

}



#pragma mark -
#pragma mark -
#pragma mark Tiling and page configuration
- (void)layoutSubviews
{
	[super layoutSubviews];
    
    BOOL orientationHasChanged = NO;
	if (oldWidth_ != self.frame.size.width)
	{
        originalFrame_.size.width = originalFrame_.size.height;
        originalFrame_.size.height = originalFrame_.size.width;
        
        originalPageSizeWithPadding_ = CGSizeZero;
        
		orientationHasChanged = YES;
	}
	
	oldWidth_ = self.frame.size.width;
	
    [self updateContentSize];
   
	if (orientationHasChanged == YES)
	{
		if (direction_ == PunchScrollViewDirectionHorizontal)
        {
            self.contentOffset = CGPointMake(self.originalPageSizeWithPadding.width*currentPageIndex_, 0);
        }
        else if (direction_ == PunchScrollViewDirectionVertical)
        {
            self.contentOffset = CGPointMake(0, self.originalPageSizeWithPadding.height*currentPageIndex_);
        }
        
		[self updateFrameForVisiblePages];
	}
}

- (void)loadPages 
{
    if ([self pagesCount]  == 0 ||
        (self.punchDataSource == nil))
    {
        
        // do not render the pages if there is not at least one page
        
        return;
    }
    
    int lazyOfLoadingPages = 0;
    if ([self.punchDataSource respondsToSelector:@selector(numberOfLazyLoadingPages)])
    {
        lazyOfLoadingPages = [self.punchDataSource numberOfLazyLoadingPages];
    }
    
    // Calculate which pages are visible
    CGRect visibleBounds = self.bounds;
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = ceil(CGRectGetMaxX(visibleBounds) / self.originalPageSizeWithPadding.width);
      
    if (direction_ == PunchScrollViewDirectionVertical)
    {
        firstNeededPageIndex = floorf(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds));
        lastNeededPageIndex  = ceil(CGRectGetMaxY(visibleBounds) / self.originalPageSizeWithPadding.height);
    }
    
    firstNeededPageIndex = MAX(firstNeededPageIndex-lazyOfLoadingPages, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex+lazyOfLoadingPages, [self pagesCount] - 1);
	
    // Recycle no-longer-visible pages 
    for (UIView *page in visiblePages_)
    {
        int indexToDelete = page.tag;
        if (indexToDelete < firstNeededPageIndex ||
            indexToDelete > lastNeededPageIndex)
        {
            if (indexToDelete >= 0 &&
                indexToDelete < [pageController_ count])
            {
                UIViewController *vc = [pageController_ objectAtIndex:indexToDelete];
                [vc viewDidUnload];
                vc.view = nil;
            }
            [recycledPages_ addObject:page];
            [page removeFromSuperview];
        }
    }
    [visiblePages_ minusSet:recycledPages_];
    
    // add missing pages
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) 
    {
        if (![self isDisplayingPageForIndex:index])
		{
			
			UIView *page = [self askDataSourceForPageAtIndex:index];            
            
			if (nil != page)
			{
				page.tag = index;
				page.frame = [self frameForPageAtIndex:index withSize:page.frame.size]; 
				[page layoutIfNeeded];
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
    
    if ([self.punchDataSource respondsToSelector:@selector(punchScrollView:controllerForPageAtIndexPath:)])
    {
        UIViewController *controller = [self.punchDataSource
                                        punchScrollView:self
                                        controllerForPageAtIndexPath:[self indexPathForIndex:index]];
        if (![pageController_ containsObject:controller] &&
            controller != nil)
        {
            [pageController_ addObject:controller];
        }
        
        page = controller.view;
        
    }
    else if ([self.punchDataSource respondsToSelector:@selector(punchScrollView:viewForPageAtIndexPath:)])
    {
        page = [self.punchDataSource punchScrollView:self viewForPageAtIndexPath:[self indexPathForIndex:index]];
    }
    
    return page;
}


- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
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

- (void)setPunchDataSource:(id <PunchScrollViewDataSource>)thePunchDataSource
{
	if (punchDataSource_ != thePunchDataSource)
    {
        punchDataSource_ = thePunchDataSource;
        if (punchDataSource_ != nil)
        {
            [self reloadData];
        }
    }
}



#pragma mark -
#pragma mark ScrollView delegate methods



- (void)scrollViewDidScroll:(PunchScrollView *)scrollView
{
    //
    // Check if the page really has changed
    //
    BOOL pageChanged = NO;
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        if ( (int)(self.contentOffset.x) % (int)(self.contentSize.width) == 0)
        {
            pageChanged = YES;
        }
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        if ( (int)(self.contentOffset.y) % (int)(self.contentSize.height) == 0)
        {
            pageChanged = YES;
        }
    }
    
    if (pageChanged == YES)
    {
        [self loadPages];
        [self pageIndexChanged];
    }
}

- (void)scrollViewDidEndDecelerating:(PunchScrollView *)scrollView 
{
    [self pageIndexChanged];
}

- (void)scrollViewDidEndScrollingAnimation:(PunchScrollView *)scrollView
{
	[self pageIndexChanged];
}

- (void)pageIndexChanged
{
    NSInteger newPageIndex = NSNotFound;
    
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        CGFloat pageWidth = self.originalPageSizeWithPadding.width;
        newPageIndex = floor(self.contentOffset.x) / floor(pageWidth);
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        CGFloat pageHeight = self.originalPageSizeWithPadding.height;
        newPageIndex = floor(self.contentOffset.y) / floor(pageHeight);
    }
    
    if (newPageIndex != currentPageIndex_)
    {
        currentPageIndex_ = newPageIndex;
        if ([self.punchDelegate respondsToSelector:@selector(punchScrollView:pageChanged:)] &&
            [indexPaths_ count] > 0)
        {
            [self.punchDelegate punchScrollView:self
                                    pageChanged:[self indexPathForIndex:currentPageIndex_]];
        }
	}
}



#pragma mark -
#pragma mark Page Frame calculations

- (void)setPagePadding:(CGFloat)pagePadding
{
    if (pagePadding_ != pagePadding)
    {
        pagePadding_ = pagePadding;
        
        [self reloadData];
    }
}


- (void)adjustSelfFrame:(CGRect)aFrame
{
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        aFrame.origin.x -= self.pagePadding;
        aFrame.size.width += (2 * self.pagePadding);
    }
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        aFrame.origin.y -= self.pagePadding;
        aFrame.size.height += (2 * self.pagePadding);
    }

    
    self.frame = aFrame;
    
 
}

- (void)updateContentSize
{
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        self.contentSize = CGSizeMake(self.originalPageSizeWithPadding.width * [self pagesCount],
                                      self.originalPageSizeWithPadding.height);
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        self.contentSize = CGSizeMake(self.originalPageSizeWithPadding.width,
                                      self.originalPageSizeWithPadding.height* [self pagesCount]);
    }
}


- (void)updateFrameForVisiblePages
{
	for (UIView *page in visiblePages_)
	{
		if ((NSNull*)page != [NSNull null])
        {
            page.frame = [self frameForPageAtIndex:page.tag
                                          withSize:page.frame.size];
        }
	}
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index withSize:(CGSize)size
{
    
    CGRect pageFrame = CGRectMake(self.bounds.origin.x,
                                  self.bounds.origin.y,
                                  size.width,
                                  size.height);

           
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        pageFrame.size.width += (2 * self.pagePadding);
        pageFrame.origin.x = (pageFrame.size.width * index) + self.pagePadding;
        pageFrame.origin.y = 0;
        pageFrame.size.width -= (2 * self.pagePadding);
    }
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        pageFrame.size.height += (2 * self.pagePadding);
        pageFrame.origin.x = 0;
        pageFrame.origin.y = (pageFrame.size.height * index) + self.pagePadding;
        pageFrame.size.height -= (2 * self.pagePadding);
    }
    
    
    return pageFrame;
}



- (void)setDirection:(PunchScrollViewDirection)direction
{
    if (direction_ != direction)
    {
        direction_ = direction;
        [self reloadData];
    }
}

- (CGSize)originalPageSizeWithPadding
{
   
    if ([indexPaths_ count] == 0)
    {
             
        originalPageSizeWithPadding_ = CGSizeZero; 
        
        return originalPageSizeWithPadding_;
    }
    
    CGSize size = originalPageSizeWithPadding_;
    if (CGSizeEqualToSize(size,CGSizeZero))
    {
        UIView *page = [self askDataSourceForPageAtIndex:0];
        if (page != nil)
        {
            size = page.bounds.size;
        }
    }
    

    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        size = CGSizeMake(size.width+(2*self.pagePadding),size.height);
    }
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        size = CGSizeMake(size.width,size.height+(2*self.pagePadding));
    }
        
    originalPageSizeWithPadding_ = size;
    
    return size;
}


#pragma mark -
#pragma mark Count & hold the data Source



- (NSUInteger)sectionCount
{
	if ([self.punchDataSource respondsToSelector:@selector(numberOfSectionsInPunchScrollView:)])
    {
        return [self.punchDataSource numberOfSectionsInPunchScrollView:self];
    }
    return 1;
}

- (NSUInteger)pagesCount {
    
	return [indexPaths_ count];
	
}


- (void)setIndexPaths
{
	[indexPaths_ removeAllObjects];
    
    for (int section = 0; section < [self sectionCount]; section++)
	{
		NSUInteger rowsInSection = 1;
		if ([self.punchDataSource respondsToSelector:@selector(punchscrollView:numberOfPagesInSection:)])
		{
			rowsInSection = [self.punchDataSource punchscrollView:self numberOfPagesInSection:section];
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