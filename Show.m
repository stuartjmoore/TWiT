//
//  Show.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "XMLReader.h"

#import "Show.h"
#import "Poster.h"
#import "Feed.h"
#import "Episode.h"
#import "Enclosure.h"

#define MAX_EPISODES 50

@implementation Show

@dynamic desc, email, favorite, hosts, phone, published, remind, schedule, sort, title, titleAcronym, titleInSchedule, website, albumArt, channel, episodes, feeds;

#pragma mark - Update Episodes

- (void)updateEpisodes
{
    for(Feed *feed in self.feeds)
    {
        NSMutableURLRequest *headerRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:feed.url]
                                                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                 timeoutInterval:60.0f];
        [headerRequest setHTTPMethod:@"HEAD"];
        [NSURLConnection sendAsynchronousRequest:headerRequest queue:NSOperationQueue.mainQueue
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
             if([httpResponse respondsToSelector:@selector(allHeaderFields)])
             {
                 if(httpResponse.statusCode != 200)
                     return;
                 
                 NSDictionary *metaData = [httpResponse allHeaderFields];
                 NSString *lastModifiedString = [metaData objectForKey:@"Last-Modified"];
                 
                 NSDateFormatter *df = [[NSDateFormatter alloc] init];
                 df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
                 df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                 df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
                 
                 NSDate *lastModified = [df dateFromString:lastModifiedString];
                 
                 if(lastModified == nil || ![lastModified isEqualToDate:feed.lastUpdated])
                 {
                     feed.lastUpdated = lastModified;
                     [feed.managedObjectContext save:nil];
                     [self updatePodcastFeed:feed];
                 }
             }
         }];
    }
}

- (void)updatePodcastFeed:(Feed*)feed
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:feed.url]];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if(error)
             return;
         
         BOOL firstLoad = (self.episodes.count == 0);
         
         NSDictionary *RSS = [XMLReader dictionaryForXMLData:data];
         
         NSArray *episodes = [[[RSS objectForKey:@"rss"] objectForKey:@"channel"] objectForKey:@"item"];
         
         for(NSDictionary *epiDic in episodes)
         {
             int number = 0;
             NSString *title = @"";
             
             if([[epiDic objectForKey:@"title"] objectForKey:@"text"])
             {
                 NSString *text = [[[epiDic objectForKey:@"title"] objectForKey:@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                 
                 if([text hasPrefix:@"Leo Laporte - The Tech Guy "])
                 {
                     NSError *error;
                     NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Leo Laporte - The Tech Guy (\\d+)" options:NSRegularExpressionCaseInsensitive error:&error];
                     
                     if(!error)
                     {
                         NSTextCheckingResult *results = [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
                         number = [[text substringWithRange:[results rangeAtIndex:1]] intValue];
                         title  = [NSString stringWithFormat:@"Episode #%d", number];
                     }
                     else
                     {
                         number = 0;
                         title  = @"";
                     }
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
             
             NSString *pubDateString = [[epiDic objectForKey:@"pubDate"] objectForKey:@"text"];
             NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
             [dateFormat setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
             NSDate *published = [dateFormat dateFromString:pubDateString];
             
             NSString *durationString = [[[epiDic objectForKey:@"itunes:duration"] objectForKey:@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
             NSArray *durationArray = [[[durationString componentsSeparatedByString:@":"] reverseObjectEnumerator] allObjects];
             int duration = 0;
             for(int i = 0; i < durationArray.count; i++)
                 duration += [[durationArray objectAtIndex:i] intValue]*pow(60, i);
             
             NSString *summary = [[epiDic objectForKey:@"description"] objectForKey:@"text"];
             NSString *guests;
             if(summary)
             {
                 NSRegularExpression *guestRegex = [NSRegularExpression regularExpressionWithPattern:@"<p><b>Guests?:</b> (.*?)</p>" options:NSRegularExpressionCaseInsensitive error:NULL];
                 NSTextCheckingResult *guestResults = [guestRegex firstMatchInString:summary options:0 range:NSMakeRange(0, [summary length])];
                 
                 if(guestResults.numberOfRanges > 0)
                     guests = [summary substringWithRange:[guestResults rangeAtIndex:1]];
                 
                 if(!guests)
                 {
                     NSRegularExpression *guestRegex = [NSRegularExpression regularExpressionWithPattern:@"<p><b>Hosts?:</b> (.*?)</p>" options:NSRegularExpressionCaseInsensitive error:NULL];
                     NSTextCheckingResult *guestResults = [guestRegex firstMatchInString:summary options:0 range:NSMakeRange(0, [summary length])];
                     
                     if(guestResults.numberOfRanges > 0)
                         guests = [summary substringWithRange:[guestResults rangeAtIndex:1]];
                 }
                 
                 if(!guests)
                     guests = self.hosts;
                 
                 if(!guests)
                     guests = @"";
                 
                 NSRange r;
                 while((r = [guests rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
                     guests = [guests stringByReplacingCharactersInRange:r withString:@""];
                 
                 //guests = [guests stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
             }
             
             NSString *posterURL = [NSString stringWithFormat:@"http://twit.tv/files/imagecache/slideshow-slide/%@%.4d.jpg", self.titleAcronym.lowercaseString, number];
             
             NSString *enclosureURL = [[epiDic objectForKey:@"enclosure"] objectForKey:@"url"];
             //NSString *enclosureType = [[epiDic objectForKey:@"enclosure"] objectForKey:@"type"];
             NSString *website = [[epiDic objectForKey:@"comments"] objectForKey:@"text"];
             
             
             Episode *episode = nil;
             
             NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title == %@ && number == %d", title, number];
             NSSet *sameEpisode = [self.episodes filteredSetUsingPredicate:predicate];
             
             if(sameEpisode.count > 0)
             {
                 episode = sameEpisode.anyObject;
             }
             else
             {
                 if(self.episodes.count >= MAX_EPISODES)
                 {
                     NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"published" ascending:NO];
                     NSArray *descriptors = [NSArray arrayWithObject:descriptor];
                     NSArray *sortedEpisodes = [self.episodes sortedArrayUsingDescriptors:descriptors];
                     Episode *oldestEpisode = sortedEpisodes.lastObject;
                     
                     if([published laterDate:oldestEpisode.published] == oldestEpisode.published)
                     {
                         continue;
                     }
                     else
                     {
                         [self removeEpisodesObject:oldestEpisode];
                     }
                 }
                 
                 NSManagedObjectContext *context = self.managedObjectContext;
                 episode = [NSEntityDescription insertNewObjectForEntityForName:@"Episode" inManagedObjectContext:context];
                 episode.title = title;
                 episode.desc = desc;
                 episode.duration = duration;
                 episode.guests = guests;
                 episode.website = website;
                 episode.published = published;
                 episode.number = number;
                 episode.watched = firstLoad;
                 
                 Poster *poster = [NSEntityDescription insertNewObjectForEntityForName:@"Poster"
                                                                inManagedObjectContext:context];
                 poster.url = posterURL;
                 
                 [self addEpisodesObject:episode];
             }
             
             
             NSPredicate *pred = [NSPredicate predicateWithFormat:@"quality == %d", feed.quality];
             NSSet *enclosures = [episode.enclosures filteredSetUsingPredicate:pred];
             
             NSManagedObjectContext *context = self.managedObjectContext;
             Enclosure *enclosure = (enclosures.count == 0) ? [NSEntityDescription insertNewObjectForEntityForName:@"Enclosure"
                                                                                            inManagedObjectContext:context] : enclosures.anyObject;
             enclosure.url = enclosureURL;
             enclosure.title = feed.title;
             enclosure.subtitle = feed.subtitle;
             enclosure.quality = feed.quality;
             enclosure.type = feed.type;
             [episode addEnclosuresObject:enclosure];
             [context save:nil];
         }
     }];
}

@end
