//
//  Episode.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Episode.h"
#import "Enclosure.h"

@implementation Episode

@dynamic desc, downloadedQuality, downloadState, duration, guests, lastTimecode, number, published, title, watched, website, enclosures, poster, show;

- (NSString*)durationString
{
    NSInteger interval = self.duration;
    NSInteger seconds = interval % 60;
    NSInteger minutes = (interval / 60) % 60;
    NSInteger hours = (interval / 3600);
    
    return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
}

- (NSString*)publishedString
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MMM dd, yyyy";
    
    return [df stringFromDate:self.published];
}

#pragma mark - Download

- (void)downloadEnclosure:(Enclosure*)enclosure
{
    [enclosure download];
}

@end
