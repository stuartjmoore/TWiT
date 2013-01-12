//
//  TWPlayButton.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWPlayButton.h"

@implementation TWPlayButton

- (void)setPercentage:(float)percentage
{
    _percentage = percentage;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextMoveToPoint(context, self.bounds.size.width/2, self.bounds.size.height/2);
    CGContextAddArc(context,
                    self.bounds.size.width/2, self.bounds.size.height/2,
                    self.bounds.size.width/2, -M_PI_2, 2*M_PI*self.percentage-M_PI_2, NO);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
}

@end
