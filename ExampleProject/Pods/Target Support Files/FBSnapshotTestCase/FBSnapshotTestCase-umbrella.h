#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FBSnapshotTestCase.h"
#import "FBSnapshotTestController.h"
#import "UIImage+Compare.h"
#import "UIImage+Diff.h"

FOUNDATION_EXPORT double FBSnapshotTestCaseVersionNumber;
FOUNDATION_EXPORT const unsigned char FBSnapshotTestCaseVersionString[];

