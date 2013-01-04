//
//  Episode.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Episode.h"

@implementation Episode

@dynamic desc, downloadedQuality, downloadState, duration, guests, lastTimecode, number, published, title, watched, website, enclosures, poster, show;

- (NSString*)durationString
{
    NSInteger ti = self.duration;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    
    return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
}

- (NSString*)publishedString
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MMM dd, yyyy";
    
    return [df stringFromDate:self.published];
}

@end
