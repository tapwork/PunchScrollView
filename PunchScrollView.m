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


- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (void)updateFrameForVisiblePages;
- (BOOL)didOrientationChange;
- (void)renderPages;
- (void)pageIndexChanged;
- (void)setCurrentPage;
- (void)setIndexPaths;
- (NSUInteger)sectionCount;
- (NSUInteger)pagesCount;

@end

@implementation PunchScrollView
@synthesize punchDataSource = punchDataSource_;
@synthesize punchDelegate = punchDelegate_;

@synthesize pagePadding = pagePadding_;
@synthesize direction = direction_;

@synthesize currentIndexPath;
@synthesize lastIndexPath;
@synthesize currentPage;
@synthesize firstPage;
@synthesize lastPage;

- (id)init
{
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if ((self = [super initWithFrame:aFrame]))
	{
		originalFrame_ = aFrame;
        self.pagePadding = 10;
        
        
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.delegate = self;  
		
		
		self.pagingEnabled = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		self.directionalLockEnabled = YES;
		
		indexPaths_	   = [[NSMutableArray alloc] init];
		recycledPages_ = [[NSMutableSet alloc] init];
		visiblePages_  = [[NSMutableSet alloc] init];
		
		
		
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
    [super dealloc];
}

#pragma mark -
#pragma mark PunchScrollView Public Methods
- (UIView*)pageForIndexPath:(NSIndexPath*)indexPath
{
    NSArray *storedPages = [NSArray arrayWithArray:[recycledPages_ allObjects]];
    storedPages = [storedPages arrayByAddingObjectsFromArray:[visiblePages_ allObjects]];

    for (UIView *thePage in storedPages)
	{
		if ((NSNull*)thePage == [NSNull null]) break;
		NSIndexPath *storedIndexPath = (thePage.tag < [indexPaths_ count])?[indexPaths_ objectAtIndex:thePage.tag]:nil;
		
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
        [self scrollRectToVisible:CGRectMake(self.frame.size.width*pageNum,
                                             0,
                                             self.frame.size.width,
                                             self.frame.size.height)
                         animated:animated];
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        [self scrollRectToVisible:CGRectMake(0,
                                             self.frame.size.height*pageNum,
                                             self.frame.size.width,
                                             self.frame.size.height)
                         animated:animated];
    }
	if (animated == NO)
	{
		[self pageIndexChanged];
	}
}

- (void)scrollToNextPage:(BOOL)animated
{
	NSIndexPath *indexPath = nil;
	if (currentPage_ >= [indexPaths_ count]-1)
	{
		// do nothing because we reached the end
		return;
	}
	else
	{
		indexPath = [indexPaths_ objectAtIndex:currentPage_+1];
		[self scrollToIndexPath:indexPath animated:animated];
		
		if (animated == NO)
		{
			[self pageIndexChanged];
		}
	}
	
	
}

- (void)scrollToPreviousPage:(BOOL)animated
{
	NSIndexPath *indexPath = nil;
	if (currentPage_ < 1)
	{
		// do nothing because we reached the beginning
		return;
	}
	else
	{
		indexPath = [indexPaths_ objectAtIndex:currentPage_-1];
		[self scrollToIndexPath:indexPath animated:animated];
		
		if (animated == NO)
		{
			[self pageIndexChanged];
		}
	}
	
}

- (NSIndexPath*)getCurrentIndexPath
{
	if (currentPage_ >= [indexPaths_ count])
    {
        return nil;
    }
    return [indexPaths_ objectAtIndex:currentPage_];
}

- (NSIndexPath*)getLastIndexPath
{
	return [indexPaths_ lastObject];
}

- (UIView*)getCurrentPage
{
    return [self pageForIndexPath:self.currentIndexPath];
}

- (UIView*)getFirstPage
{
    return [self pageForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (UIView*)getLastPage
{
    return [self pageForIndexPath:self.lastIndexPath];
}

- (void)reloadData
{
    [self setIndexPaths];
    currentPage_ = 0;
    [visiblePages_ removeAllObjects];
    [recycledPages_ removeAllObjects];
    
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        self.contentSize = CGSizeMake(self.frame.size.width * [self pagesCount],
                                  self.frame.size.height);

        [self setContentOffset:CGPointMake(self.frame.size.width*currentPage_, 0) animated:NO];
    }
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        self.contentSize = CGSizeMake(self.frame.size.width,
                                     self.frame.size.height* [self pagesCount]);
        
        [self setContentOffset:CGPointMake(0, self.frame.size.height*currentPage_) animated:NO];
    }
   // [self renderPages];
    [self performSelector:@selector(renderPages) withObject:nil afterDelay:0.01];
}


#pragma mark -
#pragma mark -
#pragma mark Tiling and page configuration
- (void)layoutSubviews
{
	[super layoutSubviews];
	
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        self.contentSize = CGSizeMake(self.frame.size.width * [self pagesCount],
								  self.frame.size.height);
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        self.contentSize = CGSizeMake(self.frame.size.width,
                                      self.frame.size.height* [self pagesCount]);
    }
   
	if ([self didOrientationChange])
	{
		if (direction_ == PunchScrollViewDirectionHorizontal)
        {
            self.contentOffset = CGPointMake(self.frame.size.width*currentPage_, 0);
        }
        else if (direction_ == PunchScrollViewDirectionVertical)
        {
            self.contentOffset = CGPointMake(0, self.frame.size.height*currentPage_);
        }
        
		[self updateFrameForVisiblePages];
	}
}

- (void)renderPages 
{
    if ([self pagesCount]  == 0)
    {
        
        // do not render the pages if there is not at least one page
        
        return;
    }
    
    // Calculate which pages are visible
    CGRect visibleBounds = self.bounds;
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    
    if (direction_ == PunchScrollViewDirectionVertical)
    {
        firstNeededPageIndex = floorf(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds));
        lastNeededPageIndex  = floorf((CGRectGetMaxY(visibleBounds)-1) / CGRectGetHeight(visibleBounds));
        
    }
    
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, [self pagesCount] - 1);
	
    // Recycle no-longer-visible pages 
    for (UIView *page in visiblePages_)
    {
        if (page.tag < firstNeededPageIndex || page.tag > lastNeededPageIndex)
        {
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
			
			UIView *page = nil;
			if ([self.punchDataSource respondsToSelector:@selector(punchScrollView:viewForPageAtIndexPath:)])
			{
				page = [self.punchDataSource punchScrollView:self viewForPageAtIndexPath:[indexPaths_ objectAtIndex:index]];
			}
			if (nil != page)
			{
				page.tag = index;
				page.frame = [self frameForPageAtIndex:index]; 
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

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    BOOL foundPage = NO;
    for (UIView *page in visiblePages_)
    {
        if (page.tag == index)
        {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}

- (void)setPunchDataSource:(id <PunchScrollViewDataSource>)thePunchDataSource
{
	punchDataSource_ = thePunchDataSource;
	if (punchDataSource_ != nil)
	{
		[self reloadData];
	}
}

- (void)setCurrentPage
{
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        CGFloat pageWidth = self.frame.size.width;
        currentPage_ = floor(self.contentOffset.x) / floor(pageWidth);
	}
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        CGFloat pageHeight = self.frame.size.height;
        currentPage_ = floor(self.contentOffset.y) / floor(pageHeight);
    }
}

#pragma mark -
#pragma mark ScrollView delegate methods


- (void)scrollViewDidScroll:(PunchScrollView *)scrollView
{
	[self renderPages];
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
    [self setCurrentPage];
    
    
	if ([self.punchDelegate respondsToSelector:@selector(punchScrollView:pageChanged:)] && [indexPaths_ count] > 0)
	{
		[self.punchDelegate punchScrollView:self pageChanged:[indexPaths_ objectAtIndex:currentPage_]];
	}
	
}


#pragma mark -
#pragma mark Page Frame calculations

- (void)setPagePadding:(CGFloat)pagePadding
{
    pagePadding_ = pagePadding;
    
    [self adjustFrame:originalFrame_];
}

- (void)adjustFrame:(CGRect)aFrame
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
    
    [self updateFrameForVisiblePages];
}


- (void)updateFrameForVisiblePages
{
	for (UIView *page in visiblePages_)
	{
		if ((NSNull*)page != [NSNull null]) page.frame = [self frameForPageAtIndex:page.tag];
	}
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
	CGRect pageFrame = self.bounds;
	
    if (direction_ == PunchScrollViewDirectionHorizontal)
    {
        pageFrame.origin.x = (pageFrame.size.width * index) + self.pagePadding;
        pageFrame.origin.y = 0;
        pageFrame.size.width -= (2 * self.pagePadding);
    }
    else if (direction_ == PunchScrollViewDirectionVertical)
    {
        pageFrame.origin.x = 0;
        pageFrame.origin.y = (pageFrame.size.height * index) + self.pagePadding;
        pageFrame.size.height -= (2 * self.pagePadding);
    }
    
    
	
    return pageFrame;
}

- (BOOL)didOrientationChange
{
	BOOL hasChanged = NO;
	if (oldWidth_ != self.frame.size.width)
	{
		
		hasChanged = YES;
	}
	
	oldWidth_ = self.frame.size.width;
	
	return hasChanged;
}

- (void)setDirection:(PunchScrollViewDirection)direction
{
    direction_ = direction;
    [self adjustFrame:originalFrame_];
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



@end