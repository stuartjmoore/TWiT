//
//  Show.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"

#import "NSManagedObjectContext+ConvenienceMethods.h"
#import "NSDate+comparisons.h"
#import "XMLReader.h"

#import "Show.h"
#import "Poster.h"
#import "Feed.h"
#import "Episode.h"
#import "Enclosure.h"

#define MAX_EPISODES 15

@implementation Show

static NSInteger threadCount;
static BOOL anyUpdates;

@dynamic desc, email, favorite, hosts, phone, published, remind, schedule, sort, updateInterval, title, titleAcronym, titleInSchedule, website, albumArt, channel, episodes, feeds;

- (Poster*)poster
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"poster.path != nil"];
    NSSet *episodes = [self.episodes filteredSetUsingPredicate:pred];
    Episode *episode = episodes.anyObject;
    
    if(!episode)
        episode = self.episodes.anyObject;

    if(episode)
        return episode.poster;
    
    return nil;
}

- (UIImage*)defaultImage
{
    NSString *resourceName = [NSString stringWithFormat:@"%@-poster.jpg", self.titleAcronym.lowercaseString];
    NSString *resourcePath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:resourceName];
    return [UIImage imageWithContentsOfFile:resourcePath];
}

- (NSArray*)scheduleDates
{
    NSMutableArray *dates = [NSMutableArray array];
    NSInteger day = 0, hour = 0, minute = 0;
    
    if([self.schedule rangeOfString:@"@"].location != NSNotFound)
    {
        NSArray *daysAndTime = [self.schedule componentsSeparatedByString:@"@"];
        
        NSInteger time = [daysAndTime[1] intValue];
        hour = time/100;
        minute = time%100;
        
        NSArray *days = [daysAndTime[0] componentsSeparatedByString:@","];
        for(NSString *dayString in days)
        {
            if([dayString isEqualToString:@"SU"])
                day = 1;
            else if([dayString isEqualToString:@"MO"])
                day = 2;
            else if([dayString isEqualToString:@"TU"])
                day = 3;
            else if([dayString isEqualToString:@"WE"])
                day = 4;
            else if([dayString isEqualToString:@"TH"])
                day = 5;
            else if([dayString isEqualToString:@"FR"])
                day = 6;
            else if([dayString isEqualToString:@"SA"])
                day = 7;
            
            NSDateComponents *components = [[NSDateComponents alloc] init];
            components.timeZone = [NSTimeZone timeZoneWithName:@"America/Los_Angeles"];
            components.year = 2012;
            components.weekday = day;
            components.weekdayOrdinal = 1;
            components.hour = hour;
            components.minute = minute;
            components.second = 0;
            
            NSDate *date = [NSCalendar.currentCalendar dateFromComponents:components];
            
            NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
            [offsetComponents setMinute:-10];
            date = [NSCalendar.currentCalendar dateByAddingComponents:offsetComponents toDate:date options:0];
            
            [dates addObject:date];
        }
    }
    
    return dates;
}

- (NSString*)scheduleString
{
    NSString *scheduleString = self.schedule;
    NSMutableArray *dayStrings = [NSMutableArray array];
    NSString *timeString = @"";
    if([scheduleString rangeOfString:@"@"].location != NSNotFound)
    {
        NSArray *daysAndTime = [scheduleString componentsSeparatedByString:@"@"];
        scheduleString = @"";
        
        NSInteger TZDiff = ([[NSTimeZone timeZoneWithName:@"America/Los_Angeles"] secondsFromGMT]
                            - NSTimeZone.localTimeZone.secondsFromGMT)/60/60*100;
        
        //[[NSTimeZone timeZoneWithName:@"Europe/London"] secondsFromGMT]
        
        NSInteger time = [daysAndTime[1] intValue];
        time -= TZDiff;
        BOOL nextDay = NO;
        if(time >= 2400)
        {
            time -= 2400;
            nextDay = YES;
        }
        
        
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
        NSDateComponents *comps = [gregorian components:unitFlags fromDate:[NSDate date]];
        [comps setHour:time/100];
        [comps setMinute:time%100];
        NSDate *hourDate = [gregorian dateFromComponents:comps];
        
        NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
        [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
        [dateFormatterLocal setDateFormat:@"h:mma"];
        [dateFormatterLocal setPMSymbol:@"p"];
        [dateFormatterLocal setAMSymbol:@"a"];
        timeString = [dateFormatterLocal stringFromDate:hourDate];
        
        
        /*
        BOOL is24Hour = [NSDate is24Hour];
        NSString *suffix = is24Hour ? @"" : (time/100 < 12 ? @"a" : @"p");
        NSInteger maxHour = is24Hour ? 24 : 12;
        NSInteger midnightHour = is24Hour ? 0 : 12;
        
        if(time/100 == 0)
            timeString = [NSString stringWithFormat:@"%.2d:%.2d%@", midnightHour, time%100, suffix];
        else if(time/100 <= maxHour)
            timeString = [NSString stringWithFormat:@"%d:%.2d%@", time/100, time%100, suffix];
        else
            timeString = [NSString stringWithFormat:@"%d:%.2d%@", time/100-maxHour, time%100, suffix];
        */
        
        
        NSArray *days = [[daysAndTime objectAtIndex:0] componentsSeparatedByString:@","];
        for(NSString *dayString in days)
        {
            NSInteger day = [NSDate dayFromName:dayString];
            
            if(day < 0)
                day += 7;
            
            if(nextDay)
            {
                day++;
                if(day >= 8)
                    day = 0;
            }
            
            if(days.count <= 2)
                [dayStrings addObject:[NSDate longNameFromDay:day]];
            else
                [dayStrings addObject:[NSDate shortNameFromDay:day]];
        }
        
        for(NSString *dayString in dayStrings)
        {
            scheduleString = [scheduleString stringByAppendingString:dayString];
            
            if(dayString != dayStrings.lastObject)
            {
                if(dayString != [dayStrings objectAtIndex:dayStrings.count-2])
                    scheduleString = [scheduleString stringByAppendingString:@", "];
                else
                    scheduleString = [scheduleString stringByAppendingString:@" & "];
            }
        }
        
        if([scheduleString isEqualToString:@"Mon, Tues, Wed, Thur & Fri"])
            scheduleString = @"Weekdays";
        else if([scheduleString isEqualToString:@"Saturdays & Sundays"])
            scheduleString = @"Weekends";
        
        scheduleString = [scheduleString stringByAppendingString:@" @ "];
        scheduleString = [scheduleString stringByAppendingString:timeString];
    }
    return scheduleString;
}

#pragma mark -

- (void)setFavorite:(BOOL)favorite
{
    if(favorite)
    {
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:YES];
        Episode *episode = [[self.episodes sortedArrayUsingDescriptors:@[sortDescriptor]] lastObject];
        episode.watched = NO;
    }
    else
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"watched = %d", NO];
        NSSet *episodes = [self.episodes filteredSetUsingPredicate:predicate];
        [episodes makeObjectsPerformSelector:@selector(setWatched:) withObject:@YES];
    }
    
    [self willChangeValueForKey:@"favorite"];
    [self setPrimitiveValue:@(favorite) forKey:@"favorite"];
    [self didChangeValueForKey:@"favorite"];
}

- (void)setRemind:(BOOL)remind
{
    NSArray *notifications = UIApplication.sharedApplication.scheduledLocalNotifications;
    
    for(UILocalNotification *notification in notifications)
        if([notification.userInfo[@"title"] isEqualToString:self.titleAcronym])
            [UIApplication.sharedApplication cancelLocalNotification:notification];
    
    if(remind)
    {
        for(NSDate *fireDate in self.scheduleDates)
        {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.repeatInterval = NSWeekCalendarUnit;
            notification.fireDate = fireDate;
            
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.alertBody = [NSString stringWithFormat:@"%@ is Starting", self.title];
            notification.alertAction = @"Watch";
            
            notification.userInfo = @{ @"title" : self.titleAcronym };
            
            [UIApplication.sharedApplication scheduleLocalNotification:notification];
        }
    }
    
    [self willChangeValueForKey:@"remind"];
    [self setPrimitiveValue:@(remind) forKey:@"remind"];
    [self didChangeValueForKey:@"remind"];
}

#pragma mark - Update Episodes

- (void)updateEpisodes
{
    [self updateEpisodesWithCompletionHandler:nil];
}

- (void)forceUpdateEpisodes
{
    [self updateEpisodesWithCompletionHandler:nil forceUpdate:YES];
}

- (void)updateEpisodesWithCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"number" ascending:NO];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"self == %@", nil];
    
    NSArray *epsiodes = [self.episodes sortedArrayUsingDescriptors:@[sortDescriptor]];
    NSArray *publishedDates = [[epsiodes subarrayWithRange:NSMakeRange(0, epsiodes.count >= 9 ? 9 : epsiodes.count)] valueForKey:@"published"];
    NSArray *notPublished = [publishedDates filteredArrayUsingPredicate:pred];
    
    BOOL forceUpdate = notPublished.count;
    [self updateEpisodesWithCompletionHandler:completionHandler forceUpdate:forceUpdate];
}

- (void)updateEpisodesWithCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler forceUpdate:(BOOL)forceUpdate
{
    for(Feed *feed in self.feeds)
    {
        if(!forceUpdate && feed.lastEnclosureDate && feed.lastEnclosureDate.timeIntervalSinceNow > -self.updateInterval)
            continue;
        
        if(threadCount == 0)
        {
            anyUpdates = NO;
            UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
        }
        
        threadCount++;
        
        NSMutableURLRequest *headerRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:feed.url]
                                                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                 timeoutInterval:60.0f];
        [headerRequest setHTTPMethod:@"HEAD"];
        
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        __weak typeof(self) weak = self;
        
        NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:nil delegateQueue:NSOperationQueue.mainQueue];
        [[delegateFreeSession dataTaskWithRequest:headerRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
            if([httpResponse respondsToSelector:@selector(allHeaderFields)] && httpResponse.statusCode == 200)
            {
                NSDictionary *metaData = [httpResponse allHeaderFields];
                NSString *lastModifiedString = [metaData objectForKey:@"Last-Modified"];
                
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
                df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
                
                NSDate *lastModified = [df dateFromString:lastModifiedString];
                
                if(forceUpdate || (lastModified == nil || ![lastModified isEqualToDate:feed.lastUpdated]))
                {
                    [weak updatePodcastFeed:feed withCompletionHandler:completionHandler];
                    return;
                }
            }
            
            [weak finishUpdateWithCompletionHandler:completionHandler];
        }] resume];
    }
}

- (void)updatePodcastFeed:(Feed*)feed withCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler
{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    defaultConfigObject.timeoutIntervalForResource = 60;
    
    __weak typeof(self) weak = self;
    
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:nil delegateQueue:NSOperationQueue.mainQueue];
    [[delegateFreeSession dataTaskWithURL:[NSURL URLWithString:feed.url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if(error || ([httpResponse respondsToSelector:@selector(allHeaderFields)] && httpResponse.statusCode != 200))
        {
            NSLog(@"update error: %@, httpResponse: %@", error, httpResponse);
            [weak finishUpdateWithCompletionHandler:completionHandler];
            return;
        }
        
        BOOL firstLoad = (weak.episodes.count == 0);
        
        NSManagedObjectContext *context = weak.managedObjectContext;
        NSDictionary *RSS = [XMLReader dictionaryForXMLData:data];
        NSArray *episodes = [[[RSS objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"];
        
        for(NSDictionary *epiDic in episodes)
        {
            NSInteger number = 0;
            NSString *title = @"";
            
            if([[epiDic objectForKey:@"title"] objectForKey:@"text"])
            {
                NSString *text = [[[epiDic objectForKey:@"title"] objectForKey:@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                if([feed.show.title isEqualToString:@"The Tech Guy"])
                {
                    NSError *error;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Leo Laporte - The Tech Guy: (\\d+)" options:NSRegularExpressionCaseInsensitive error:&error];
                    
                    if(!error)
                    {
                        NSTextCheckingResult *results = [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
                        number = [[text substringWithRange:[results rangeAtIndex:1]] intValue];
                        title  = [NSString stringWithFormat:@"Episode #%zd", number];
                    }
                    else
                    {
                        number = 0;
                        title  = @"";
                    }
                }
                else if([feed.show.title isEqualToString:@"OMGcraft"])
                {
                    NSString *commentsString = [[epiDic objectForKey:@"comments"] objectForKey:@"text"];
                    
                    NSError *error;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http://twit.tv/omgcraft/(\\d+)" options:NSRegularExpressionCaseInsensitive error:&error];
                    NSTextCheckingResult *results = [regex firstMatchInString:commentsString options:0 range:NSMakeRange(0, commentsString.length)];
                    
                    number = [[commentsString substringWithRange:[results rangeAtIndex:1]] intValue];
                    title = text;
                }
                else
                {
                    NSError *error;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".* (\\d+) ?: (.*)" options:NSRegularExpressionCaseInsensitive error:&error];
                    
                    if(!error)
                    {
                        NSTextCheckingResult *results = [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
                        number = [[text substringWithRange:[results rangeAtIndex:1]] intValue];
                        title  = [text substringWithRange:[results rangeAtIndex:2]];
                    }
                    else
                    {
                        number = 0;
                        title  = @"";
                    }
                }
            }
            
            NSString *desc = [[[epiDic objectForKey:@"itunes:subtitle"] objectForKey:@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            desc = [desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // TODO: Check user set calendar or AM/PM/24
            NSString *pubDateString = [[epiDic objectForKey:@"pubDate"] objectForKey:@"text"];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
            NSDate *published = [dateFormat dateFromString:pubDateString];
            
            NSString *durationString = [[[epiDic objectForKey:@"itunes:duration"] objectForKey:@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSArray *durationArray = [[[durationString componentsSeparatedByString:@":"] reverseObjectEnumerator] allObjects];
            NSInteger duration = 0;
            for(NSInteger i = 0; i < durationArray.count; i++)
                duration += [[durationArray objectAtIndex:i] intValue]*pow(60, i);
            
            NSString *summary = [[epiDic objectForKey:@"description"] objectForKey:@"text"];
            NSString *guests;
            if(summary)
            {
                NSRegularExpression *guestRegex = [NSRegularExpression regularExpressionWithPattern:@"<p><strong>Guests?:</strong> (.*?)</p>" options:NSRegularExpressionCaseInsensitive error:NULL];
                NSTextCheckingResult *guestResults = [guestRegex firstMatchInString:summary options:0 range:NSMakeRange(0, [summary length])];
                
                if(guestResults.numberOfRanges > 0)
                    guests = [summary substringWithRange:[guestResults rangeAtIndex:1]];
                
                if(!guests)
                {
                    NSRegularExpression *guestRegex = [NSRegularExpression regularExpressionWithPattern:@"<p><strong>Hosts?:</strong> (.*?)</p>" options:NSRegularExpressionCaseInsensitive error:NULL];
                    NSTextCheckingResult *guestResults = [guestRegex firstMatchInString:summary options:0 range:NSMakeRange(0, [summary length])];
                    
                    if(guestResults.numberOfRanges > 0)
                        guests = [summary substringWithRange:[guestResults rangeAtIndex:1]];
                }
                
                if(!guests)
                    guests = weak.hosts;
                
                if(!guests)
                    guests = @"";
                
                NSRange r;
                while((r = [guests rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
                    guests = [guests stringByReplacingCharactersInRange:r withString:@""];
            }
            
            NSString *posterURL = [NSString stringWithFormat:@"http://twit.tv/files/imagecache/slideshow-slide/spiros_%@_%.4zdjpg.jpg",
                                   weak.titleAcronym.lowercaseString, number];
            
            NSString *enclosureURL = [[epiDic objectForKey:@"enclosure"] objectForKey:@"url"];
            NSString *website = [[epiDic objectForKey:@"comments"] objectForKey:@"text"];
            
            
            Episode *episode = nil;
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number == %d", number];
            NSSet *sameEpisode = [weak.episodes filteredSetUsingPredicate:predicate];
            
            if(sameEpisode.count > 0)
            {
                episode = sameEpisode.anyObject;
                
                if(!episode.published)
                {
                    episode.title = title;
                    episode.published = published ?: [NSDate date];
                    episode.desc = desc;
                    episode.duration = duration;
                    episode.guests = guests;
                    episode.website = website;
                    
                    Poster *poster = [context insertEntity:@"Poster"];
                    poster.url = posterURL;
                    episode.poster = poster;
                }
            }
            else
            {
                if(weak.episodes.count >= MAX_EPISODES)
                {
                    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO];
                    NSArray *sortedEpisodes = [weak.episodes sortedArrayUsingDescriptors:@[descriptor]];
                    Episode *oldestEpisode = sortedEpisodes.lastObject;
                    
                    if([published compare:oldestEpisode.published] == NSOrderedAscending)
                    {
                        continue;
                    }
                    else
                    {
                        [weak.managedObjectContext deleteObject:oldestEpisode];
                    }
                }
                
                anyUpdates = YES;
                episode = [context insertEntity:@"Episode"];
                
                [weak addEpisodesObject:episode];
                episode.title = title;
                episode.number = number;
                episode.published = published ?: [NSDate date];
                episode.desc = desc;
                episode.duration = duration;
                episode.guests = guests;
                episode.website = website;
                
                Poster *poster = [context insertEntity:@"Poster"];
                poster.url = posterURL;
                episode.poster = poster;
                
                bool watched = firstLoad ?: !weak.favorite;
                
                if(watched)
                {
                    [episode willChangeValueForKey:@"watched"];
                    [episode setPrimitiveValue:@(watched) forKey:@"watched"];
                    [episode didChangeValueForKey:@"watched"];
                }
                else
                {
                    // TODO: store in iCloud
                    episode.watched = watched;
                }
            }
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"quality == %d", feed.quality];
            NSSet *enclosures = [episode.enclosures filteredSetUsingPredicate:pred];
            
            Enclosure *enclosure = (enclosures.count == 0) ? [context insertEntity:@"Enclosure"] : enclosures.anyObject;
            enclosure.url = enclosureURL;
            enclosure.title = feed.title;
            enclosure.subtitle = feed.subtitle;
            enclosure.quality = feed.quality;
            enclosure.type = feed.type;
            [episode addEnclosuresObject:enclosure];
            
            feed.lastEnclosureDate = [published laterDate:feed.lastEnclosureDate];
        }
        
        if([httpResponse respondsToSelector:@selector(allHeaderFields)] && httpResponse.statusCode == 200)
        {
            NSDictionary *metaData = [httpResponse allHeaderFields];
            NSString *lastModifiedString = [metaData objectForKey:@"Last-Modified"];
            
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
            
            NSDate *lastModified = [df dateFromString:lastModifiedString];
            feed.lastUpdated = lastModified;
        }
        
        [context save:nil];
        [weak finishUpdateWithCompletionHandler:completionHandler];
     }] resume];
}

- (void)finishUpdateWithCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler
{
    threadCount--;
    
    if(threadCount == 0)
    {
        [(TWAppDelegate*)UIApplication.sharedApplication.delegate updateBadgeCount];
        UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
        
        [self.managedObjectContext save:nil];
        
        if(completionHandler)
            completionHandler(anyUpdates ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
    }
}

@end
