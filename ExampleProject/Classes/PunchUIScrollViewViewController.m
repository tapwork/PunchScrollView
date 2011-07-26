//
//  PunchUIScrollViewViewController.m
//  PunchUIScrollView
//
//  Created by tapwork. on 20.10.10. 
//
//  Copyright 2010 tapwork. mobile design & development. All rights reserved.
//  tapwork.de

#import "PunchUIScrollViewViewController.h"

#import "ExamplePageView.h"


@implementation PunchUIScrollViewViewController




// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	scrollView_ = [[PunchScrollView alloc] init];
	scrollView_.punchDataSource	= self;
	scrollView_.punchDelegate	= self;
	[self.view addSubview:scrollView_];
	
	UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[prevButton setTitle:@"Previous Page" forState:UIControlStateNormal];
	prevButton.frame = CGRectMake(5, 0, 80, 40);
	prevButton.titleLabel.font = [UIFont systemFontOfSize:10];
	[prevButton addTarget:self action:@selector(toPrevPage:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:prevButton];
	
	UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[nextButton setTitle:@"Next Page" forState:UIControlStateNormal];
	nextButton.titleLabel.font = prevButton.titleLabel.font;
	nextButton.frame = CGRectMake(self.view.frame.size.width-85, 0, 80, 40);
	[nextButton addTarget:self action:@selector(toNextPage:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:nextButton];
}

#pragma mark -
#pragma mark Button Actions

- (void)toPrevPage:(id)sender
{
	[scrollView_ scrollToPreviousPage:YES];
}
- (void)toNextPage:(id)sender
{
	[scrollView_ scrollToNextPage:YES];
}


#pragma mark -
#pragma mark PunchScrollView DataSources

- (NSInteger)numberOfSectionsInPunchScrollView:(PunchScrollView *)scrollView
{
	return 3;
}

- (NSInteger)punchscrollView:(PunchScrollView *)scrollView numberOfPagesInSection:(NSInteger)section
{
	return 3;
}

            
- (UIView*)punchScrollView:(PunchScrollView*)scrollView viewForPageAtIndexPath:(NSIndexPath *)indexPath
{
	ExamplePageView *page = (ExamplePageView*)[scrollView dequeueRecycledPage];
	if (page == nil)
	{
		page = [[[ExamplePageView alloc] initWithFrame:self.view.frame] autorelease];
	}
	
	
	page.titleLabel.text = [NSString stringWithFormat:@"Page %d in section %d", indexPath.row, indexPath.section];
	
	return page;
}

#pragma mark PunchScrollView Delegate
- (void)punchScrollView:(PunchScrollView*)scrollView pageChanged:(NSIndexPath*)_indexPath
{
	
}


#pragma mark -
#pragma mark Memory Management
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[scrollView_ release];
	scrollView_ = nil;
}


- (void)dealloc {
	
	[scrollView_ release];
	scrollView_ = nil;
	
    [super dealloc];
}

@end
