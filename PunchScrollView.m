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


NSString *const PunchScrollViewPageChangedNotification          = @"PunchScrollViewPageChangedNotification";
NSString *const PunchScrollViewUserInfoNewPageIndexPathKey      = @"PunchScrollViewUserInfoNewPageIndexPathKey";
NSString *const PunchScrollViewUserInfoNewPageFlattenedIndexKey   = @"PunchScrollViewUserInfoNewPageFlattenedIndexKey";
NSString *const PunchScrollViewUserInfoTotalPagesNumberKey      = @"PunchScrollViewUserInfoTotalPagesNumberKey";


@interface PunchScrollView ()
{
    BOOL _needsUpdateContentOffset;
    BOOL _needsReload;
    BOOL _isScrollingForwardsOrBack;
    BOOL _scrollNextWorkaround;
    
	id <PunchScrollViewDataSource> _dataSource;
	id <PunchScrollViewDelegate> _delegate;
    
	NSMutableSet                    *_recycledPages;
    NSMutableSet                    *_visiblePages;
    NSMutableArray                  *_pageController;
    
	NSInteger                       _currentInternalPageIndex;
	NSMutableArray                  *_indexPaths;
	CGFloat                         _currentWidth;
    CGFloat                         _pagePadding;
    CGSize                          _pageSizeWithPadding;
    PunchScrollViewDirection        _direction;
}

@property (nonatomic, readonly) CGSize pageSizeWithPadding;
@property (nonatomic, readonly) NSArray *storedPages;
@property (nonatomic, readwrite) BOOL isScrollingForwardsOrBack;


@end

@implementation PunchScrollView
@synthesize infiniteScrolling = _infiniteScrolling;
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
    _pageSizeWithPadding = CGSizeZero;
    
    self.pagePadding = 0;
    [super setDelegate:self];
    
    self.bouncesZoom = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.pagingEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.directionalLockEnabled = YES;
    _currentInternalPageIndex = NSNotFound;
    _isScrollingForwardsOrBack = NO;
    
    _indexPaths     = [[NSMutableArray alloc] init];
    _recycledPages  = [[NSMutableSet alloc] init];
    _visiblePages   = [[NSMutableSet alloc] init];
    
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
	[_indexPaths release];
	_indexPaths = nil;
	[_recycledPages release];
	_recycledPages = nil;
	[_visiblePages release];
	_visiblePages = nil;
    [_pageController release];
    _pageController = nil;
    
    [super dealloc];
}

- (void)removePages
{
    _pageSizeWithPadding        = CGSizeZero;
    _currentWidth               = 0.0;
    _currentInternalPageIndex   = NSNotFound;
    self.contentSize            = CGSizeZero;
   
    NSArray *pages = self.storedPages;
    for (UIView *view in pages)
    {
        [view removeFromSuperview];
        view = nil;
    }
    
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];
}


#pragma mark -
#pragma mark Public Methods
- (void)setDataSource:(id <PunchScrollViewDataSource>)thedataSource
{
	if (_dataSource != thedataSource)
    {
        _dataSource = thedataSource;
        if (_dataSource != nil)
        {
            [self setNeedsReload];
        }
        else
        {
            [self removePages];
        }
    }
}

- (void)setDelegate:(id<PunchScrollViewDelegate>)aDelegate
{
    if (aDelegate != self->_delegate)
    {
        self->_delegate = aDelegate;
        if (aDelegate != nil)
        {
            [self setNeedsReload];
        }
    }
}

- (id<PunchScrollViewDelegate>)delegate
{
    return self->_delegate;
}


- (UIView *)dequeueRecycledPage
{
    UIView *page = [_recycledPages anyObject];
    if (page)
    {
        [[page retain] autorelease];
        [_recycledPages removeObject:page];
        [page removeFromSuperview];
    }
    return page;
}


- (UIView*)pageForIndexPath:(NSIndexPath*)indexPath
{
    NSInteger index = [_indexPaths indexOfObject:indexPath];
    if (self.infiniteScrolling)
    {
        index += 1;
    }
	
    return [self pageAtIndex:index];
}

// this method should only be used for public
// do not use for internal purpose
// use scrollToIndex:animated: instead
- (void)scrollToIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated
{
    void (^block)() = ^(){
        
        NSInteger pageNum = [_indexPaths indexOfObject:indexPath];
        if (self.infiniteScrolling)
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
    
        NSInteger page = [self calculatedPageIndexOffset] + 1;
        if (page <= [self pagesCount])
        {
            [self scrollToIndex:page animated:YES];
        }
        if (page == [self pagesCount])
        {
            _scrollNextWorkaround = YES;
        }
     };
    
    dispatch_async(dispatch_get_main_queue(), block);
}

- (void)scrollToPreviousPage:(BOOL)animated
{
    void(^block)() = ^(){
        
        NSInteger page = [self calculatedPageIndexOffset] - 1;
        if (page >= 0)
        {
            [self scrollToIndex:page animated:YES];
        }
    };
	
    dispatch_async(dispatch_get_main_queue(), block);
}


- (NSIndexPath*)currentIndexPath
{
    return [self indexPathForIndex:_currentInternalPageIndex];
}

- (NSIndexPath*)lastIndexPath
{
	return [_indexPaths lastObject];
}

- (NSUInteger)numPagesInDataSource
{
    return [_indexPaths count];
}

- (UIView*)currentPage
{
    return [self pageForIndexPath:self.currentIndexPath];
}

- (NSMutableSet*)visiblePages
{
    return _visiblePages;
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
    return _pageController;
}

- (NSInteger)flattenedIndexForIndexPath:(NSIndexPath*)indexPath
{
    return [_indexPaths indexOfObject:indexPath];
}

- (void)reloadData
{
    [self setIndexPaths];
    [self removePages];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    _needsReload = NO;
}

- (void)setPagePadding:(CGFloat)pagePadding
{
    if (_pagePadding != pagePadding)
    {
        _pagePadding = pagePadding;
        
        CGRect frame = self.frame;
        if (_direction == PunchScrollViewDirectionHorizontal)
        {
            frame.origin.x -= self.pagePadding;
            frame.size.width += (2 * self.pagePadding);
        }
        else if (_direction == PunchScrollViewDirectionVertical)
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
    if (_direction != direction)
    {
        _direction = direction;
        [self setNeedsReload];
    }
}

- (void)setInfiniteScrolling:(BOOL)infiniteScrolling
{
    if (_infiniteScrolling != infiniteScrolling)
    {
        _infiniteScrolling = infiniteScrolling;
        [self setNeedsReload];
    }
}

- (BOOL)infiniteScrolling
{
    if ([_indexPaths count] <= 1)
    {
        return NO;
    }
    
    return _infiniteScrolling;
}

#pragma mark -
#pragma mark Private methods
- (void)layoutSubviews
{
	[super layoutSubviews];
    
    if (_currentInternalPageIndex == NSNotFound)
    {
        if (self.infiniteScrolling)
        {
            // when we are in infinite mode we are starting
            // at index 1....index 0 will be also our last page
            // the last page will be displayed at the beginning and at the end
            // this allows us to wrap around
            // the index 0 will not be visible as starting index for the user
            // index 1 represents NSIndexPath [0,0] in infinite mode
            
            _currentInternalPageIndex = 1;
        }
        else
        {
            _currentInternalPageIndex = 0;
        }
    }
    
    
    _needsUpdateContentOffset = NO;
	if (_currentWidth != self.frame.size.width)
	{
        _needsUpdateContentOffset = YES;
        _pageSizeWithPadding = CGSizeZero;
	}
	
	_currentWidth = self.frame.size.width;
	
    [self updateContentSize];
    
	if (_needsUpdateContentOffset == YES)
	{
         _needsUpdateContentOffset = NO;
        
        NSInteger index = _currentInternalPageIndex;
        if (_direction == PunchScrollViewDirectionHorizontal)
        {
            [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*index, 0)
                          animated:NO];
            
        }
        else if (_direction == PunchScrollViewDirectionVertical)
        {
            [self setContentOffset:CGPointMake(0, self.pageSizeWithPadding.height*index)
                          animated:NO];
        }
        
        [self updateFrameForAvailablePages];
    }
    
    if (self.infiniteScrolling == YES &&
        _needsUpdateContentOffset == NO)
    {
        [self recenterForInfiniteIfNecessary];
    }
    

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
        if (_scrollNextWorkaround)
        {
            _scrollNextWorkaround = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
               [self scrollToIndex:_currentInternalPageIndex + 1 animated:YES]; 
            });
        }
    }
    else if (self.direction == PunchScrollViewDirectionVertical &&
             self.contentOffset.y + self.pageSizeWithPadding.height >= self.contentSize.height )
    {
        [self setContentOffset:CGPointMake(0,0)
                      animated:NO];
        if (_scrollNextWorkaround)
        {
            _scrollNextWorkaround = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self scrollToIndex:_currentInternalPageIndex + 1 animated:YES];
            });
        }
    }
    else if (self.direction == PunchScrollViewDirectionHorizontal &&
             self.contentOffset.x <= 0.0)
    {
        [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*([self pagesCount]-1), 0)
                      animated:NO];
    }
    else if (self.direction == PunchScrollViewDirectionVertical &&
             self.contentOffset.y <= 0.0)
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
    
    if (_direction == PunchScrollViewDirectionVertical)
    {
        firstNeededPageIndex = floorf(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds));
        lastNeededPageIndex  = ceil(CGRectGetMaxY(visibleBounds) / self.pageSizeWithPadding.height);
    }
    
    firstNeededPageIndex = MAX(firstNeededPageIndex-lazyOfLoadingPages-1, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex+lazyOfLoadingPages, [self pagesCount] - 1);
    
    // Recycle no-longer-visible pages
    for (UIView *page in _visiblePages)
    {
        int indexToDelete = page.tag;
        if (indexToDelete < firstNeededPageIndex ||
            indexToDelete > lastNeededPageIndex)
        {
            //
            // If we work in controller mode
            if (_pageController != nil &&
                indexToDelete >= 0 &&
                indexToDelete < [_pageController count])
            {
                UIViewController *vc = [_pageController objectAtIndex:indexToDelete];
                [controllerViewsToDelete addObject:vc];
            }
            //
            // if we work in view mode
            else if (_pageController == nil)
            {
                [_recycledPages addObject:page];
            }
            
        }
    }
    
    [_visiblePages minusSet:_recycledPages];
    
    //
    // Force Deletion
    for (UIViewController *vc in controllerViewsToDelete)
    {
        if ([vc isViewLoaded])
        {
            [_visiblePages removeObject:vc.view];
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
			UIView *page = [self askDataSourceForPageAtIndex:index addSubview:YES];
			if (page == nil)
			{
				[_visiblePages addObject:[NSNull null]];
			}
        }
    }
}

- (UIView*)askDataSourceForPageAtIndex:(NSInteger)index addSubview:(BOOL)shouldAddSubView
{
    UIView *page = nil;

    if ([self.dataSource respondsToSelector:@selector(punchScrollView:controllerForPageAtIndexPath:)])
    {
        if (_pageController == nil)
        {
            _pageController = [[NSMutableArray alloc] init];
        }
        
        UIViewController *controller = [self.dataSource
                                        punchScrollView:self
                                        controllerForPageAtIndexPath:[self indexPathForIndex:index]];
        if (![_pageController containsObject:controller] &&
            controller != nil)
        {
            [_pageController addObject:controller];
        }
        
        page = controller.view;
        
    }
    else if ([self.dataSource respondsToSelector:@selector(punchScrollView:viewForPageAtIndexPath:)])
    {
        page = [self.dataSource punchScrollView:self viewForPageAtIndexPath:[self indexPathForIndex:index]];
    }
    
    if (nil != page &&
        shouldAddSubView == YES)
    {
        [self addSubview:page];
        [_visiblePages addObject:page];
    }
    
    if (page)
    {
        page.tag = index;
        [page layoutIfNeeded];
        page.frame = [self frameForPage:page];
    }
    
    
    return page;
}



- (void)setNeedsReload
{
    if (_needsReload == NO)
    {
        _needsReload = YES;
        __block PunchScrollView *blockself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockself reloadData];
        });
    }
}

- (NSArray*)storedPages
{
    NSArray *storedPages = [NSArray arrayWithArray:[_recycledPages allObjects]];
    
    return [storedPages arrayByAddingObjectsFromArray:[_visiblePages allObjects]];
}

- (BOOL)isDisplayingPageForIndex:(NSInteger)index
{
    BOOL foundPage = NO;
    for (UIView *page in _visiblePages)
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
    if (_currentInternalPageIndex == index) {
        return; // already on that page!
    }

    if (animated) {
        self.isScrollingForwardsOrBack = YES;
    }
    
    if (_direction == PunchScrollViewDirectionHorizontal)
    {
        [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*index,
                                           0)
                      animated:animated];
    }
    else if (_direction == PunchScrollViewDirectionVertical)
    {
        [self setContentOffset:CGPointMake(0,
                                           self.pageSizeWithPadding.height*index)
                      animated:animated];
    }
    
    [self pageIndexChanged];
}


- (void)tapOnPage:(UIGestureRecognizer*)gesture
{
    if ([self.delegate respondsToSelector:@selector(punchScrollView:didTapOnPage:atIndexPath:)])
    {
        if ([gesture state] == UIGestureRecognizerStateRecognized)
        {
            // if this gesture intercepts any of the views, then inform the delegate
            CGPoint p = [gesture locationInView:self];
            for (UIView *v in _visiblePages)
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

- (UIView*)pageAtIndex:(NSInteger)index
{
    for (UIView *thePage in self.visiblePages)
	{
		if ((NSNull*)thePage == [NSNull null]) break;
		if (thePage.tag == index)
		{
            return thePage;
        }
    }
    
    return [self askDataSourceForPageAtIndex:index addSubview:NO];
}



#pragma mark -
#pragma mark ScrollView delegate methods


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(!scrollView.isTracking)
        self.isScrollingForwardsOrBack = YES;
    
    //
    // Check if the page really has changed
    //
    BOOL pageChanged = NO;
    if (_direction == PunchScrollViewDirectionHorizontal)
    {
        if ( (int)(self.contentOffset.x) % MAX((int)(self.pageSizeWithPadding.width),1) == 0)
        {
            pageChanged = YES;
        }
	}
    else if (_direction == PunchScrollViewDirectionVertical)
    {
        if ( (int)(self.contentOffset.y) % MAX((int)(self.pageSizeWithPadding.height),1) == 0)
        {
            pageChanged = YES;
        }
    }
    
    
    if (pageChanged == YES &&
        _needsUpdateContentOffset == NO)
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
    if (!decelerate) {
        self.isScrollingForwardsOrBack = NO;
    }  // else this gets set when decelerating has ended
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
    {
        [self.delegate scrollViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.isScrollingForwardsOrBack = NO;
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
    {
        [self.delegate performSelector:@selector(scrollViewDidEndDecelerating:) withObject:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.isScrollingForwardsOrBack = NO;
    
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
    if ([self calculatedPageIndexOffset] != _currentInternalPageIndex)
    {
        // if we are in infinite scroll mode:
        // then the currentInternalIndex is not representing the visible indexPath
        // because: the last visible page of the scrollview will also be placed at the index 0...
        // but we start at index 1 ...index 0 is invisble at the beginning
        // when we scroll to the last page , then we immediately change the contentoffset to the index 0
        
        _currentInternalPageIndex = [self calculatedPageIndexOffset];
        
        if ([_indexPaths count] > 0)
        {
            NSIndexPath *indexPath = [self currentIndexPath];
            NSInteger index = [_indexPaths indexOfObject:indexPath];
            NSDictionary *userInfo = @{PunchScrollViewUserInfoNewPageIndexPathKey: indexPath,
                                       PunchScrollViewUserInfoNewPageFlattenedIndexKey: @(index),
                                       PunchScrollViewUserInfoTotalPagesNumberKey : @([_indexPaths count])};
            
            [[NSNotificationCenter defaultCenter] postNotificationName: PunchScrollViewPageChangedNotification
                                                                object: self
                                                              userInfo: userInfo];
            
            if ([self.delegate respondsToSelector:@selector(punchScrollView:pageChanged:)]) {
            
                [self.delegate punchScrollView:self
                                   pageChanged:[self currentIndexPath]];
            }
        }
	}
}

- (NSInteger)calculatedPageIndexOffset
{
    NSInteger index = 0;
    if (_direction == PunchScrollViewDirectionHorizontal)
    {
        CGFloat pageWidth = floorf(self.pageSizeWithPadding.width);
        index = floorf(self.contentOffset.x /
                              ( (pageWidth == 0) ? 1 : pageWidth) );
	}
    else if (_direction == PunchScrollViewDirectionVertical)
    {
        CGFloat pageHeight = floorf(self.pageSizeWithPadding.height);
        index = floorf(self.contentOffset.y /
                              ( (pageHeight == 0) ? 1 : pageHeight) );
    }
    
    return index;
}

- (void)updateContentSize
{
    NSInteger pagesCount = [self pagesCount];
    
    if (_direction == PunchScrollViewDirectionHorizontal)
    {
        self.contentSize = CGSizeMake(self.pageSizeWithPadding.width * pagesCount,
                                      self.pageSizeWithPadding.height);
	}
    else if (_direction == PunchScrollViewDirectionVertical)
    {
        self.contentSize = CGSizeMake(self.pageSizeWithPadding.width,
                                      self.pageSizeWithPadding.height * pagesCount);
    }
}


- (void)updateFrameForAvailablePages
{
	for (UIView *page in _visiblePages)
	{
		if ((NSNull*)page != [NSNull null])
        {
            page.frame = [self frameForPage:page];
        }
	}
}

- (CGRect)frameForPage:(UIView*)page
{
    NSInteger index = page.tag;
    CGSize size = page.frame.size;
    
    // if the page has an autoresizing mask then we need to substract the padding from the new size
    if (page.autoresizingMask & UIViewAutoresizingFlexibleWidth)
    {
        size.width -= self.pagePadding*2;
    }
    else if (page.autoresizingMask & UIViewAutoresizingFlexibleHeight)
    {
        size.height -= self.pagePadding*2;
    }
    
    
    CGRect pageFrame = CGRectMake(self.bounds.origin.x,
                                  self.bounds.origin.y,
                                  size.width,
                                  size.height);
    
    
    if (_direction == PunchScrollViewDirectionHorizontal)
    {
        pageFrame.origin.x = (self.pageSizeWithPadding.width * index) + self.pagePadding;
        pageFrame.origin.y = 0;
    }
    else if (_direction == PunchScrollViewDirectionVertical)
    {
        pageFrame.origin.x = 0;
        pageFrame.origin.y = (self.pageSizeWithPadding.height * index) + self.pagePadding;
    }
    
    
    return pageFrame;
}



- (CGSize)pageSizeWithPadding
{
    if ([_indexPaths count] == 0)
    {
        _pageSizeWithPadding = CGSizeZero;
        
        return _pageSizeWithPadding;
    }
    
    CGSize size = _pageSizeWithPadding;
    if (CGSizeEqualToSize(size,CGSizeZero))
    {
        UIView *page = [[_visiblePages allObjects] lastObject];
        if (page == nil)
        {
            page = [self askDataSourceForPageAtIndex:0 addSubview:YES];
        }
        if (page != nil)
        {
            size = page.bounds.size;
            
            if (_direction == PunchScrollViewDirectionHorizontal)
            {
                size = CGSizeMake(size.width+(2*self.pagePadding),size.height);
            }
            else if (_direction == PunchScrollViewDirectionVertical)
            {
                size = CGSizeMake(size.width,size.height+(2*self.pagePadding));
            }
            
            _pageSizeWithPadding = size;
        }
    }
    
    
    return _pageSizeWithPadding;
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
        return [_indexPaths count] + 1;
    }
    return [_indexPaths count];
}


- (void)setIndexPaths
{
	[_indexPaths removeAllObjects];
    
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
			[_indexPaths addObject:indexPath];
		}
	}
}

//
// the indexPath will only be used for external public usage!
// PunchScrollView itself is not allowed to use the indexPath for internal usage
- (NSIndexPath*)indexPathForIndex:(NSInteger)index
{
    if (index < [self pagesCount] &&
        index >= 0)
    {
        //
        // If we are in infinite scrolling, we have to do some magic calculation
        // this is why we have public and internal indexes
        // we need to change the index for internal usage
        if (self.infiniteScrolling == YES)
        {
            if (index == 0)
            {
                index = [self pagesCount]-2;
            }
            else
            {
                index -= 1;
            }
        }
        return [_indexPaths objectAtIndex:index];
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
