//
//  Channel.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Channel.h"
#import "Stream.h"
#import "Show.h"
#import "AlbumArt.h"

@implementation Channel

@dynamic desc, published, scheduleURL, title, website, shows, streams;

- (void)updateShows
{
    [self updateJSON];
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
        }
        @catch(NSException *e)
        {
            NSLog(@"Error parsing last modified date: %@ - %@", lastModifiedString, e.description);
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
            
            lastModifiedLocal = [NSDate dateWithTimeIntervalSince1970:1356983942]; // TODO: REPLACE WITH SERVER’S DATE!
            
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
    NSString *JSONPath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"TWiT.json"];
    NSData *JSONData = [NSData dataWithContentsOfFile:JSONPath];
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
    
    //NSLog(@"%@", JSON);
    
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
            Stream *stream = [NSEntityDescription insertNewObjectForEntityForName:@"Stream" inManagedObjectContext:self.managedObjectContext];
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
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Show" inManagedObjectContext:self.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"title == %@", [showDictionary objectForKey:@"title"]]];
        
        NSArray *fetchedShows = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
        Show *show = fetchedShows.lastObject ?: [NSEntityDescription insertNewObjectForEntityForName:@"Show" inManagedObjectContext:self.managedObjectContext];
        
        NSString *pubDate = [showDictionary objectForKey:@"pubdate"];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        NSDate *published = [df dateFromString:pubDate];
        
        if(!show.published || [show.published laterDate:published] == published)
        {
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
            show.published = published;
            
            NSString *albumArtURL = [showDictionary objectForKey:@"album_art"];
            AlbumArt *albumArt = [NSEntityDescription insertNewObjectForEntityForName:@"AlbumArt"
                                                               inManagedObjectContext:self.managedObjectContext];
            albumArt.url = albumArtURL;
            show.albumArt = albumArt;
            
            for(Feed *feed in show.feeds)
                [self.managedObjectContext deleteObject:feed];
            
            for(NSDictionary *url in [showDictionary objectForKey:@"urls"])
            {
                Feed *feed = [NSEntityDescription insertNewObjectForEntityForName:@"Feed" inManagedObjectContext:self.managedObjectContext];
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
}

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
