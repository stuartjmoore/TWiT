//
//  Episode.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Episode.h"
#import "Enclosure.h"
#import "Show.h"

@implementation Episode

@dynamic desc, downloadedQuality, downloadState, duration, guests, lastTimecode, number;
@dynamic published, title, watched, website, enclosures, poster, show;

@synthesize downloadedEnclosures = _downloadedEnclosures, downloadingEnclosures = _downloadingEnclosures;

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
    df.dateFormat = @"EEEE, MMM dd";
    
    return [df stringFromDate:self.published];
}

- (NSString*)publishedMonth
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MMM";
    
    return [df stringFromDate:self.published];
}

- (NSString*)publishedDayName
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"E";
    
    return [df stringFromDate:self.published];
}

- (NSString*)publishedDayNum
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"dd";
    
    return [df stringFromDate:self.published];
}

#pragma mark - Episodes

- (NSSet*)enclosuresForType:(enum TWType)type
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %d", type];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
    
    return enclosures;
}
- (Enclosure*)enclosureForQuality:(TWQuality)quality
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quality == %d", quality];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
    
    return enclosures.anyObject;
}
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

- (NSSet*)downloadedEnclosures
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path != nil"];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
    
    return enclosures;
}

- (NSSet*)downloadingEnclosures
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"downloadTask != nil"];
    NSSet *enclosures = [self.enclosures filteredSetUsingPredicate:predicate];
    
    if(enclosures.count == 0)
        return nil;
    
    return enclosures;
}

- (void)downloadEnclosure:(Enclosure*)enclosure
{
    [enclosure download];
}

- (void)cancelDownloads
{
    [self.downloadingEnclosures makeObjectsPerformSelector:@selector(cancelDownload)];
}

- (void)deleteDownloads
{
    [self.downloadedEnclosures makeObjectsPerformSelector:@selector(deleteDownload)];
}

#pragma mark - iCloud

- (void)setWatched:(BOOL)watched
{
    if(watched == self.watched)
        return;
    
    NSURL *ubiq = [NSFileManager.defaultManager URLForUbiquityContainerIdentifier:nil];
    BOOL iCloudDisabled = [NSUserDefaults.standardUserDefaults boolForKey:@"icloud-disabled"];
    
    if(ubiq && !iCloudDisabled)
    {
        NSLog(@"Store watched");
        
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        
        NSString *key = [NSString stringWithFormat:@"%@:%@", self.show.titleAcronym, @(self.number)];
        NSMutableDictionary *episode = [[store dictionaryForKey:key] mutableCopy];
        
        if(!episode)
        {
            episode = [NSMutableDictionary dictionary];
            [episode setValue:self.published forKey:@"pubDate"];
            [episode setValue:@(self.lastTimecode) forKey:@"timecode"];
            
            [episode setValue:self.show.titleAcronym forKey:@"show.titleAcronym"];
            [episode setValue:self.title forKey:@"title"];
            [episode setValue:@(self.number) forKey:@"number"];
        }
        
        [episode setValue:@(watched) forKey:@"watched"];
        [store setDictionary:episode forKey:key];
    }
        
    [self willChangeValueForKey:@"watched"];
    [self setPrimitiveValue:@(watched) forKey:@"watched"];
    [self didChangeValueForKey:@"watched"];
}

- (void)setLastTimecode:(int16_t)lastTimecode
{
    if(lastTimecode == self.lastTimecode)
        return;
    
    NSURL *ubiq = [NSFileManager.defaultManager URLForUbiquityContainerIdentifier:nil];
    BOOL iCloudDisabled = [NSUserDefaults.standardUserDefaults boolForKey:@"icloud-disabled"];
    
    if(ubiq && !iCloudDisabled)
    {
        NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
        
        NSString *key = [NSString stringWithFormat:@"%@:%@", self.show.titleAcronym, @(self.number)];
        NSMutableDictionary *episode = [[store dictionaryForKey:key] mutableCopy];
        
        if(!episode)
        {
            episode = [NSMutableDictionary dictionary];
            [episode setValue:self.published forKey:@"pubDate"];
            [episode setValue:@(self.watched) forKey:@"watched"];
            
            [episode setValue:self.show.titleAcronym forKey:@"show.titleAcronym"];
            [episode setValue:self.title forKey:@"title"];
            [episode setValue:@(self.number) forKey:@"number"];
        }
        
        [episode setValue:@(lastTimecode) forKey:@"lastTimecode"];
        [store setDictionary:episode forKey:key];
    }
    
    [self willChangeValueForKey:@"lastTimecode"];
    [self setPrimitiveValue:@(lastTimecode) forKey:@"lastTimecode"];
    [self didChangeValueForKey:@"lastTimecode"];
}

#pragma mark - Notifications

- (void)updatePoster:(NSNotification*)notification
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"MPMoviePlayerThumbnailImageRequestDidFinishNotification" object:nil];

    UIImage *poster = notification.userInfo[@"MPMoviePlayerThumbnailImageKey"];
    
    if(poster)
        [self.poster setImage:poster];
}

@end
