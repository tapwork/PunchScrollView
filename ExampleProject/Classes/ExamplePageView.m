//
//  ExamplePageView.m
//  PunchUIScrollView
//
//  Created by tapwork. on 20.10.10. 
//
//  Copyright 2010 tapwork. mobile design & development. All rights reserved.
//  tapwork.de

#import "ExamplePageView.h"


@implementation ExamplePageView
@synthesize titleLabel;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		self.backgroundColor = [UIColor whiteColor];
		
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                               (frame.size.height/2)-25,
                                                               frame.size.width,
                                                               50)];
		titleLabel.backgroundColor = [UIColor redColor];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleTopMargin |
                                        UIViewAutoresizingFlexibleBottomMargin;
        titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
		titleLabel.textAlignment = UITextAlignmentCenter;
		[self addSubview:titleLabel];
    }
    return self;
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
}
*/

- (void)dealloc {
	
	[titleLabel release];
    [super dealloc];
}


@end
