//
//  ViewController.m
//  ImageExample
//
//  Created by Christian Menschel on 08.02.13.
//  Copyright (c) 2013 tapwork. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
{
    PunchScrollView *_scrollView;
    NSArray *_imageURLS;
    NSCache *_imageCache;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // add a cache for our images
    _imageCache = [[NSCache alloc] init];
    
    _imageURLS = @[@"http://1.2.3.10/bmi/farm9.staticflickr.com/8106/8456055846_37a609ccc1_b.jpg",
                   @"http://1.2.3.13/bmi/farm9.staticflickr.com/8227/8347399220_4bce62dff2_b.jpg",
                   @"http://1.2.3.10/bmi/farm9.staticflickr.com/8220/8334174410_31657fa66d_b.jpg",
                   @"http://1.2.3.13/bmi/farm9.staticflickr.com/8492/8334173420_13f510237c_b.jpg",
                   @"http://1.2.3.9/bmi/farm9.staticflickr.com/8208/8216204409_5e48ccc1f3_b.jpg"];
    
    
    
    _scrollView = [[PunchScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.pagePadding = 0.0;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _scrollView.delegate = self;
    _scrollView.dataSource = self;
   
    [self.view addSubview:_scrollView];
    
   
    
}

- (NSInteger)numberOfSectionsInPunchScrollView:(PunchScrollView *)scrollView
{
    return 1;
}

- (NSInteger)punchscrollView:(PunchScrollView *)scrollView numberOfPagesInSection:(NSInteger)section
{
    return [_imageURLS count];
}

- (UIView*)punchScrollView:(PunchScrollView *)scrollView viewForPageAtIndexPath:(NSIndexPath *)indexPath
{
    UIImageView *imageView = (UIImageView *)[scrollView dequeueRecycledPage];
    if (imageView == nil) {
        imageView = [[UIImageView alloc] initWithFrame:scrollView.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    // reset the image first
    imageView.image = nil;
    
    
    // do the image loading here
    NSURL *url = [NSURL URLWithString:_imageURLS[indexPath.page]];
    
    if ([_imageCache objectForKey:url])
    {
        // the image is in our cache
        imageView.image = [UIImage imageWithData:[_imageCache objectForKey:url]];
    }
    else
    {
        dispatch_async(dispatch_queue_create("punchscrollview_gcd_loading_queue_t", 0),^{
            
            NSData *data = [NSData dataWithContentsOfURL:url];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (data && url)
                {
                    if ([scrollView.visiblePages containsObject:imageView])
                    {
                        // if the imageView is visible so we can directly show the image
                        imageView.image = [UIImage imageWithData:data];
                    }
                    // set NSData to our cache
                    [_imageCache setObject:data forKey:url];
                }
                
            });
        });
    }

    return imageView;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
