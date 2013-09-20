//
//  Channel.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "NSManagedObjectContext+ConvenienceMethods.h"

#import "Schedule.h"
#import "Channel.h"
#import "Stream.h"
#import "Show.h"
#import "AlbumArt.h"

@implementation Channel

@dynamic desc, published, scheduleURL, title, website, shows, streams;
@synthesize schedule = _schedule;

- (void)update
{
    [self updateJSON];
    //[self reloadSchedule];
}

- (Stream*)streamForType:(TWType)type
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == %d", type];
    
    if(type == TWTypeVideo)
    {
        TWQuality defaultQuality = [NSUserDefaults.standardUserDefaults integerForKey:@"stream-quality"];
        
        if(defaultQuality != TWQualityAudio)
            predicate = [NSPredicate predicateWithFormat:@"type == %d AND quality == %d", type, defaultQuality];
    }
    
    NSSet *streams = [self.streams filteredSetUsingPredicate:predicate];
    
    if(streams.count == 0)
        return nil;
    
    return streams.anyObject;
}
- (Stream*)streamForQuality:(TWQuality)quality
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"quality == %d", quality];
    NSSet *streams = [self.streams filteredSetUsingPredicate:predicate];
    
    if(streams.count == 0)
        return nil;
    
    return streams.anyObject;
}

- (void)updateJSON
{
    NSString *resourcedPath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"TWiT.json"];
    NSString *cachedPath = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:@"TWiT.json"] path];
    NSURL *url = [NSURL URLWithString:@"http://stuartjmoore.com/storage/TWiT.json"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue
    completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        if(error)
            return;
        
        NSString *lastModifiedString = nil;
        if([response respondsToSelector:@selector(allHeaderFields)])
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
            
            if(httpResponse.statusCode == 200)
                lastModifiedString = [httpResponse.allHeaderFields objectForKey:@"Last-Modified"];
            else
                return;
        }
      
        //---
        
        NSDate *lastModifiedServer = nil;
        @try
        {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
            df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            lastModifiedServer = [df dateFromString:lastModifiedString];
            
            //NSLog(@"lastModifiedServer: %f", lastModifiedServer.timeIntervalSince1970); // SERVER’S DATE FOR BELOW!
        }
        @catch(NSException *e)
        {
            return;
        }
        
        // ---
        
        BOOL updateDatabase = NO;
        NSDate *lastModifiedLocal = nil;

        if(![NSFileManager.defaultManager fileExistsAtPath:cachedPath])
        {
            [NSFileManager.defaultManager copyItemAtPath:resourcedPath toPath:cachedPath error:&error];
            
            if(error)
                return;
            
            lastModifiedLocal = [NSDate dateWithTimeIntervalSince1970:1379682582]; // REPLACE WITH SERVER’S DATE ABOVE!
            
            NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:lastModifiedLocal forKey:NSFileModificationDate];
            
            NSError *error = nil;
            [NSFileManager.defaultManager setAttributes:fileAttributes ofItemAtPath:cachedPath error:&error];
            
            if(error)
                return;
            
            updateDatabase = YES;
        }
        else
        {
            NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:cachedPath error:&error];
            
            if(error)
                return;
            
            lastModifiedLocal = [fileAttributes fileModificationDate];
        }
      
      
        // ---
        
        BOOL downloadFromServer = (!lastModifiedLocal) || ([lastModifiedLocal laterDate:lastModifiedServer] == lastModifiedServer);
      
        
        NSLog(@"downloadFromServer? %@", downloadFromServer?@"yes":@"no");
        
        if(downloadFromServer)
        {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue
            completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
            {
                if(error)
                    return;
                
                [data writeToFile:cachedPath options:NSAtomicWrite error:&error];
                
                if(error)
                    return;
                
                if(lastModifiedServer)
                {
                    NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:lastModifiedServer forKey:NSFileModificationDate];
                    
                    NSError *error = nil;
                    [NSFileManager.defaultManager setAttributes:fileAttributes ofItemAtPath:cachedPath error:&error];
                    
                    if(error)
                        return;
                }
             
                [self updateDatabase];
            }];
        }
        else if(updateDatabase)
        {
            [self updateDatabase];
        }
    }];
}

- (void)updateDatabase
{
    NSString *JSONPath = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:@"TWiT.json"] path];
    NSData *JSONData = [NSData dataWithContentsOfFile:JSONPath];
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
    
    // ---
    
    NSString *pubDate = [[JSON objectForKey:@"live"] objectForKey:@"pubdate"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    NSDate *published = [dateFormat dateFromString:pubDate];
    
    if(!self.published || [self.published laterDate:published] == published)
    {
        self.title = [[JSON objectForKey:@"live"] objectForKey:@"title"];
        self.scheduleURL = [[JSON objectForKey:@"live"] objectForKey:@"schedule"];
        self.published = published;
        
        for(Stream *stream in self.streams)
            [self.managedObjectContext deleteObject:stream];
        
        for(NSDictionary *url in [[JSON objectForKey:@"live"] objectForKey:@"urls"])
        {
            Stream *stream = [self.managedObjectContext insertEntity:@"Stream"];
            stream.url = [url objectForKey:@"location"];
            stream.type = [[url objectForKey:@"type"] isEqualToString:@"video"] ? TWTypeVideo : TWTypeAudio;
            stream.title = [url objectForKey:@"title"];
            stream.subtitle = [url objectForKey:@"subtitle"];
            stream.quality = [[url objectForKey:@"quality"] intValue];
            
            [self addStreamsObject:stream];
        }
    }
    
    // ---
    
    for(NSDictionary *showDictionary in [JSON objectForKey:@"shows"])
    {
        NSSet *fetchedShows = [self.managedObjectContext fetchEntities:@"Show" withPredicate:@"title == %@", [showDictionary objectForKey:@"title"]];
        Show *show = fetchedShows.anyObject ?: [self.managedObjectContext insertEntity:@"Show"];
        
        NSLog(@"update %@", show.title);
        
        NSString *pubDate = [showDictionary objectForKey:@"pubdate"];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        NSDate *published = [df dateFromString:pubDate];
        
        if(!show.published || [show.published laterDate:published] == published)
        {
            // TODO: Delete and reload local notifications
   
            show.title = [showDictionary objectForKey:@"title"];
            show.titleAcronym = [showDictionary objectForKey:@"short_title"];
            show.titleInSchedule = [showDictionary objectForKey:@"schedule_title"];
            show.desc = [showDictionary objectForKey:@"desc"];
            show.schedule = [showDictionary objectForKey:@"schedule"];
            show.hosts = [showDictionary objectForKey:@"hosts"];
            show.email = [showDictionary objectForKey:@"email"];
            show.phone = [showDictionary objectForKey:@"phone"];
            show.website = [showDictionary objectForKey:@"website"];
            show.sort = [[showDictionary objectForKey:@"id"] intValue];
            show.updateInterval = [showDictionary[@"update_interval"] intValue];
            show.published = published;
            
            AlbumArt *albumArt = show.albumArt ?: [self.managedObjectContext insertEntity:@"AlbumArt"];
            albumArt.url = [showDictionary objectForKey:@"album_art"];
            show.albumArt = albumArt;
            
            for(Feed *feed in show.feeds)
                [self.managedObjectContext deleteObject:feed];
            
            for(NSDictionary *url in [showDictionary objectForKey:@"urls"])
            {
                Feed *feed = [self.managedObjectContext insertEntity:@"Feed"];
                feed.url = [url objectForKey:@"location"];
                feed.type = [[url objectForKey:@"type"] isEqualToString:@"video"] ? TWTypeVideo : TWTypeAudio;
                feed.title = [url objectForKey:@"title"];
                feed.subtitle = [url objectForKey:@"subtitle"];
                feed.quality = [[url objectForKey:@"quality"] intValue];
                
                [show addFeedsObject:feed];
            }
            
            [self addShowsObject:show];
        }
    }
    
    [self.managedObjectContext save:nil];
    //[NSFetchedResultsController deleteCacheWithName:@"Shows"];
}

- (void)reloadSchedule
{
    self.schedule = [[Schedule alloc] init];
    NSMutableArray *schedule = [NSMutableArray array];
    
    NSDate *startMin = [NSDate date];
    NSDate *startMax = [startMin dateByAddingTimeInterval:60*60*24*7];
    
    NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
    [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatterLocal setDateFormat:@"yyyy-MM-dd"];
    NSString *startMinString = [dateFormatterLocal stringFromDate:startMin];
    NSString *startMaxString = [dateFormatterLocal stringFromDate:startMax];
    
    NSURL *JSONURLString = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.google.com/calendar/feeds/mg877fp19824mj30g497frm74o@group.calendar.google.com/public/embed?ctz=America%%2FLos_Angeles&start-min=%@T00%%3A00%%3A00-08%%3A00&start-max=%@T00%%3A00%%3A00-08%%3A00&singleevents=true&max-results=720&alt=json", startMinString, startMaxString]];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:JSONURLString];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:NSOperationQueue.mainQueue
    completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if([httpResponse respondsToSelector:@selector(statusCode)] && httpResponse.statusCode == 200)
        {
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *showEntries = JSON[@"feed"][@"entry"];
            
            NSCalendar *calendar = NSCalendar.currentCalendar;
            NSDate *fromDate;
            NSDate *toDate;
            
            for(NSDictionary *showEntry in showEntries)
            {
                if([showEntry objectForKey:@"gd$when"] == nil)
                    continue;
                
                NSString *showTitle = [[showEntry objectForKey:@"title"] objectForKey:@"$t"];
                NSString *showSubtitle = @"";
                NSString *startTimeString = [[[showEntry objectForKey:@"gd$when"] lastObject] objectForKey:@"startTime"];
                NSString *endTimeString = [[[showEntry objectForKey:@"gd$when"] lastObject] objectForKey:@"endTime"];
                
                showTitle = [showTitle stringByReplacingOccurrencesOfString:@"&#39;" withString:@"’"];
                showTitle = [showTitle stringByReplacingOccurrencesOfString:@"&#38;" withString:@"&"];
                showTitle = [showTitle stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                showTitle = [showTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                
                NSPredicate *p = [NSPredicate predicateWithFormat:@"%@ BEGINSWITH title OR %@ BEGINSWITH titleInSchedule", showTitle, showTitle];
                Show *show = [[self.shows filteredSetUsingPredicate:p] anyObject];
                
                // TODO: if set has more than one object, try harder?
                
                if(show && show.titleInSchedule)
                {
                    showSubtitle = [showTitle stringByReplacingOccurrencesOfString:show.titleInSchedule withString:@""];
                    NSMutableCharacterSet *characters = [[NSMutableCharacterSet alloc] init];
                    [characters formUnionWithCharacterSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
                    [characters formUnionWithCharacterSet:NSCharacterSet.punctuationCharacterSet];
                    showSubtitle = [showSubtitle stringByTrimmingCharactersInSet:characters];
                    
                    showTitle = show.title;
                    
                    if([showTitle isEqualToString:showSubtitle])
                        showSubtitle = @"";
                }
                
                if(startTimeString.length > 20)
                    startTimeString = [startTimeString stringByReplacingOccurrencesOfString:@":" withString:@"" options:0
                                                                                      range:NSMakeRange(20, startTimeString.length-20)];
                if(endTimeString.length > 20)
                    endTimeString = [endTimeString stringByReplacingOccurrencesOfString:@":" withString:@"" options:0
                                                                                  range:NSMakeRange(20, endTimeString.length-20)];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
                [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"America/Los_Angeles"]];
                NSDate *startDate = [dateFormatter dateFromString:startTimeString];
                NSDate *endDate = [dateFormatter dateFromString:endTimeString];
                NSTimeInterval duration = [endDate timeIntervalSinceDate:startDate];
                
                [calendar rangeOfUnit:NSDayCalendarUnit
                            startDate:&fromDate
                             interval:NULL
                              forDate:[NSDate date]];
                
                [calendar rangeOfUnit:NSDayCalendarUnit
                            startDate:&toDate
                             interval:NULL
                              forDate:startDate];
                
                NSInteger daysAway = [[calendar components:NSDayCalendarUnit
                                                  fromDate:fromDate
                                                    toDate:toDate
                                                   options:0] day];
                
                if(daysAway < 0)
                    continue;
                
                while(daysAway >= schedule.count)
                    [schedule addObject:[NSMutableArray array]];
                NSMutableArray *shows = [schedule objectAtIndex:daysAway];
                
                Event *showEvent = [[Event alloc] init];
                showEvent.title = showTitle;
                showEvent.subtitle = showSubtitle;
                showEvent.show = show;
                showEvent.start = startDate;
                showEvent.end = endDate;
                showEvent.duration = duration/60;
                [shows addObject:showEvent];
            }
            
            for(NSMutableArray *shows in schedule)
            {
                [shows sortUsingComparator:(NSComparator)^(Event *obj1, Event *obj2)
                 {
                     NSDate *startA = obj1.start;
                     NSDate *startB = obj2.start;
                     return startB == [startA earlierDate:startB];
                 }];
            }
            
            self.schedule.days = [NSArray arrayWithArray:schedule];
        }
        else
        {
            self.schedule.days = [NSArray array];
        }
        
        [NSNotificationCenter.defaultCenter postNotificationName:@"ScheduleDidUpdate" object:self.schedule userInfo:nil];
    }];
}

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
