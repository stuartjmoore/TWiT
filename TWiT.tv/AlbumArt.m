//
//  AlbumArt.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "AlbumArt.h"
#import "Show.h"


@implementation AlbumArt

@dynamic path, url, show;

- (UIImage*)image
{
    return [UIImage imageWithContentsOfFile:self.path];
}

- (void)setUrl:(NSString*)URLString
{
    [self willChangeValueForKey:@"image"];
    [self willChangeValueForKey:@"url"];
    [self setPrimitiveValue:URLString forKey:@"url"];
    [self didChangeValueForKey:@"url"];
    [self didChangeValueForKey:@"image"];
    
    NSURL *url = [NSURL URLWithString:URLString];
    NSString *cachedDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:@"albumArt"] path];
    NSString *cachedPath = [cachedDir stringByAppendingPathComponent:url.lastPathComponent];
    
    if(![NSFileManager.defaultManager fileExistsAtPath:cachedDir])
        [NSFileManager.defaultManager createDirectoryAtPath:cachedDir withIntermediateDirectories:NO attributes:nil error:nil];
    
    // ---
    
    if(url.fragment)
    {
        NSString *fileName = [url.lastPathComponent stringByReplacingOccurrencesOfString:url.pathExtension withString:@""];
        NSString *resourceName = [NSString stringWithFormat:@"%@%@.%@", fileName, url.fragment, url.pathExtension];
        NSString *resourcePath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:resourceName];
        
        if([NSFileManager.defaultManager fileExistsAtPath:resourcePath]
        && ![NSFileManager.defaultManager fileExistsAtPath:cachedPath])
        {
            NSLog(@"Copying Album Art named %@", url.lastPathComponent);
            
            [self willChangeValueForKey:@"image"];
            [NSFileManager.defaultManager copyItemAtPath:resourcePath toPath:cachedPath error:nil];
            self.path = cachedPath;
            [self didChangeValueForKey:@"image"];
            
            return;
        }
    }
    
    // ---
    
    // TODO: Check NSFileModificationDate?
    
    // ---
    
    NSLog(@"Downloading Album Art named %@", url.lastPathComponent);
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:NSOperationQueue.mainQueue
    completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if([httpResponse respondsToSelector:@selector(statusCode)] && httpResponse.statusCode == 200)
        {
            NSLog(@"Downloaded Album Art named %@", url.lastPathComponent);
            
            [self willChangeValueForKey:@"image"];
            [data writeToFile:cachedPath atomically:NO];
            self.path = cachedPath;
            [self didChangeValueForKey:@"image"];
            
            if(url.fragment)
            {
                NSDate *lastModified = [NSDate dateWithTimeIntervalSince1970:url.fragment.floatValue];
                NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:lastModified forKey:NSFileModificationDate];
                [NSFileManager.defaultManager setAttributes:fileAttributes ofItemAtPath:cachedPath error:nil];
            }
            
            [self.managedObjectContext save:nil];
            // TODO: post notification
        }
    }];
}

- (void)prepareForDeletion
{
    if([NSFileManager.defaultManager fileExistsAtPath:self.path])
        [NSFileManager.defaultManager removeItemAtPath:self.path error:nil];
}

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
