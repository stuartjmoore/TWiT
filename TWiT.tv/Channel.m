//
//  Channel.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Channel.h"
#import "Show.h"

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
             
                [self updateDatebase];
            }];
        }
        else if(updateDatabase)
        {
            [self updateDatebase];
        }
    }];
}

- (void)updateDatebase
{
    NSString *JSONPath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"TWiT.json"];
    NSData *JSONData = [NSData dataWithContentsOfFile:JSONPath];
    NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:nil];
    
    NSLog(@"%@", JSON);
}

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
