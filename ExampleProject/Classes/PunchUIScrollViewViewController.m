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

@interface PunchUIScrollViewViewController ()

@property (nonatomic,strong) PunchScrollView *scrollView;

@end

@implementation PunchUIScrollViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.scrollView = [[PunchScrollView alloc] init];
    self.scrollView.delegate = self;
	self.scrollView.dataSource = self;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:self.scrollView];
	
	UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[prevButton setTitle:@"Previous Page" forState:UIControlStateNormal];
	prevButton.frame = CGRectMake(5, 40, 80, 40);
	prevButton.titleLabel.font = [UIFont systemFontOfSize:10];
	[prevButton addTarget:self action:@selector(toPrevPage:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:prevButton];
	
	UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[nextButton setTitle:@"Next Page" forState:UIControlStateNormal];
	nextButton.titleLabel.font = prevButton.titleLabel.font;
	nextButton.frame = CGRectMake(self.view.frame.size.width-85, 40, 80, 40);
    nextButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	[nextButton addTarget:self action:@selector(toNextPage:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:nextButton];
}

#pragma mark - Button Actions

- (void)toPrevPage:(id)sender
{
	[self.scrollView scrollToPreviousPage:YES];
}

- (void)toNextPage:(id)sender
{
	[self.scrollView scrollToNextPage:YES];
}

#pragma mark - PunchScrollViewDataSource

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
        //
        // You could also use PunchScrollview as gallery scrollview - just change the size of the desired view
        //
		page = [[ExamplePageView alloc] initWithFrame:self.view.bounds];
        page.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	
	page.titleLabel.text = [NSString stringWithFormat:@"Page %d in section %d", indexPath.row, indexPath.section];
	
	return page;
}

#pragma mark - PunchScrollViewDelegate

- (void)punchScrollView:(PunchScrollView*)scrollView pageChanged:(NSIndexPath*)_indexPath
{
	
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


@end
