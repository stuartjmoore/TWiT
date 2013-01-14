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

@dynamic desc, downloadedQuality, downloadState, duration, guests, lastTimecode, number;
@dynamic published, title, watched, website, enclosures, poster, show;

@synthesize downloadedEnclosures = _downloadedEnclosures;

- (NSString*)durationString
{
    NSInteger interval = self.duration;
    NSInteger seconds = interval % 60;
    NSInteger minutes = (interval / 60) % 60;
    NSInteger hours = (interval / 3600);
    
    return [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
}

- (NSString*)publishedString
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MMM dd, yyyy";
    
    return [df stringFromDate:self.published];
}

#pragma mark - Episodes

- (Enclosure*)enclosureForType:(enum TWType)type andQuality:(enum TWQuality)quality
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %d AND quality == %d", type, quality];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
    
    return enclosures.anyObject;
    
    // TODO: Load all enclosures of type and less than quality, sorted by quality and if downloaded. Choose top.
}

#pragma mark - Download

- (void)downloadEnclosure:(Enclosure*)enclosure
{
    [enclosure download];
}

- (void)cancelDownloads
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"downloadConnection != nil"];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    [enclosures makeObjectsPerformSelector:@selector(cancelDownload)];
}

- (NSSet*)downloadedEnclosures
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path != nil"];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
        
    return enclosures;
}
- (void)deleteDownloads
{
    [self.downloadedEnclosures makeObjectsPerformSelector:@selector(deleteDownload)];
}

@end
