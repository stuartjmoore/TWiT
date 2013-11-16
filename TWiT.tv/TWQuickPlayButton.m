//
//  TWQuickPlayButton.m
//  TWiT.tv
//
//  Created by Stuart Moore on 11/16/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWQuickPlayButton.h"

@implementation TWQuickPlayButton

- (void)setPercentage:(CGFloat)percentage
{
    _percentage = percentage;
    [self setNeedsDisplay];
}

- (void)tintColorDidChange
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGFloat r, g, b, a;
    UIColor *color = [self.tintColor getRed:&r green:&g blue:&b alpha:&a]? [UIColor colorWithRed:r green:g blue:b alpha:0.2f] : self.tintColor;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextMoveToPoint(context, self.bounds.size.width/2, self.bounds.size.height/2);
    CGContextAddArc(context,
                    self.bounds.size.width/2, self.bounds.size.height/2,
                    self.bounds.size.width/3, -M_PI_2, 2*M_PI*self.percentage-M_PI_2, NO);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
}

@end
