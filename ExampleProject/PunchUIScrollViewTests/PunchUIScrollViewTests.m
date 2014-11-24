//
//  PunchUIScrollViewTests.m
//  PunchUIScrollViewTests
//
//  Created by Christian Menschel on 24/11/14.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <PunchScrollView/PunchScrollView.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "PunchUIScrollViewViewController.h"

@interface PunchUIScrollViewTests : FBSnapshotTestCase

@property (nonatomic) PunchUIScrollViewViewController *controller;

@end

@implementation PunchUIScrollViewTests

- (void)setUp
{
    [super setUp];
    self.controller = [[PunchUIScrollViewViewController alloc] init];
    self.controller.view.frame = CGRectMake(0, 0, 320, 568);
   // self.recordMode = YES;
}


- (void)testGoNextPage
{
    PunchScrollView *scrollView = self.controller.scrollView;
    [scrollView scrollToNextPage:NO];
    [self runTest:^{
        FBSnapshotVerifyView(self.controller.view, @"after_action");
    } after:0.2];
}

- (void)testGoPrevPage
{
    PunchScrollView *scrollView = self.controller.scrollView;
    [scrollView scrollToPreviousPage:NO];
    [self runTest:^{
        FBSnapshotVerifyView(self.controller.view, @"after_action");
    } after:0.2];
}

- (void)testGotoLastPage
{
    PunchScrollView *scrollView = self.controller.scrollView;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:2 inSection:2];
    [scrollView scrollToIndexPath:lastIndexPath animated:NO];
    [self runTest:^{
        FBSnapshotVerifyView(self.controller.view, @"after_action");
    } after:0.3];
}

- (void)testPadding
{
    PunchScrollView *scrollView = self.controller.scrollView;
    scrollView.frame = CGRectMake(0, 0, 1400, 800);
    scrollView.pagePadding = 40.0;
    [self runTest:^{
        FBSnapshotVerifyLayer(scrollView.layer, @"before_action");
        scrollView.pagePadding = 0.0;
    } after:0.1];
    [self runTest:^{
        FBSnapshotVerifyLayer(scrollView.layer, @"after_action");
    } after:0.2];
}

#pragma mark - Helper

- (void)runTest:(void (^)())block after:(NSTimeInterval)dispatchAfterTime {
    XCTestExpectation *expectation = [self expectationWithDescription:@"XCTestCaseAsync"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dispatchAfterTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3*dispatchAfterTime handler:^(NSError *error) {
        XCTAssertFalse(error, @"timeout with error: %@", error);
    }];
}


@end
