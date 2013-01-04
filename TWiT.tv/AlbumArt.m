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

// TODO: Name pre-downloaded art and posters the same as in JSON.
// TODO: Download the files if not available, else copy.
// TODO: Create image accessor.


- (void)setUrl:(NSString*)URLString
{
    [self willChangeValueForKey:@"url"];
    [self setPrimitiveValue:URLString forKey:@"url"];
    [self didChangeValueForKey:@"url"];
    
    NSURL *url = [NSURL URLWithString:URLString];
    NSString *cachedDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:@"albumArt"] path];
    NSString *cachedPath = [cachedDir stringByAppendingPathComponent:url.lastPathComponent];
    
    if(![NSFileManager.defaultManager fileExistsAtPath:cachedDir])
        [NSFileManager.defaultManager createDirectoryAtPath:cachedDir withIntermediateDirectories:NO attributes:nil error:nil];
    
    if(url.fragment)
    {
        NSString *fileName = [url.lastPathComponent stringByReplacingOccurrencesOfString:url.pathExtension withString:@""];
        NSString *resourceName = [NSString stringWithFormat:@"%@%@.%@", fileName, url.fragment, url.pathExtension];
        NSString *resourcePath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:resourceName];
        
        if([NSFileManager.defaultManager fileExistsAtPath:resourcePath]
        && ![NSFileManager.defaultManager fileExistsAtPath:cachedPath])
        {
            [NSFileManager.defaultManager copyItemAtPath:resourcePath toPath:cachedPath error:nil];
            self.path = cachedPath;
            
            return;
        }
    }
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:NSOperationQueue.mainQueue
    completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if([httpResponse respondsToSelector:@selector(statusCode)] && httpResponse.statusCode == 200)
        {
            [data writeToFile:cachedPath atomically:NO];
            self.path = cachedPath;
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
