//
//  Poster.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Poster.h"
#import "Show.h"
#import "Episode.h"

#define folder @"Posters"

@implementation Poster

@dynamic path, url, episode;

@synthesize image = _image;

- (UIImage*)image
{
    NSString *_path = self.path ?: self.episode.show.poster.path;
    
    return [UIImage imageWithContentsOfFile:_path];
}

- (void)setImage:(UIImage*)image
{
    NSString *posterName = [NSString stringWithFormat:@"%@%.4d.jpg", self.episode.show.titleAcronym.lowercaseString, self.episode.number];
    NSString *cachedDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:folder] path];
    NSString *cachedPath = [cachedDir stringByAppendingPathComponent:posterName];
    
    self.path = cachedPath;
    
    NSData *posterData = UIImageJPEGRepresentation(image, 0.25f);
    [posterData writeToFile:cachedPath atomically:YES];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"posterDidChange" object:self.episode];
}

- (void)setUrl:(NSString*)URLString
{
    [self willChangeValueForKey:@"url"];
    [self setPrimitiveValue:URLString forKey:@"url"];
    [self didChangeValueForKey:@"url"];
    
    NSURL *url = [NSURL URLWithString:URLString];
    NSString *cachedDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:folder] path];
    NSString *cachedPath = [cachedDir stringByAppendingPathComponent:url.lastPathComponent];
    
    if(![NSFileManager.defaultManager fileExistsAtPath:cachedDir])
        [NSFileManager.defaultManager createDirectoryAtPath:cachedDir withIntermediateDirectories:NO attributes:nil error:nil];
    
    // ---
    
    //NSLog(@"Downloading %@ named %@", folder, url.lastPathComponent);
    __block Poster *weak = self;
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:NSOperationQueue.mainQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if([httpResponse respondsToSelector:@selector(statusCode)] && httpResponse.statusCode == 200)
        {
            //NSLog(@"Downloaded %@ named %@", folder, url.lastPathComponent);
            
            weak.path = cachedPath;
            [data writeToFile:cachedPath atomically:NO];
            
            [NSNotificationCenter.defaultCenter postNotificationName:@"posterDidChange" object:self.episode];
        }
        else
        {
            [weak willChangeValueForKey:@"url"];
            [weak setPrimitiveValue:nil forKey:@"url"];
            [weak didChangeValueForKey:@"url"];
        }
    }];
}

- (NSString*)path
{
    [self willAccessValueForKey:@"path"];
 
    NSString *_path = [self primitiveValueForKey:@"path"];
    
    if((!_path || [_path isEqualToString:@""]) && !self.url)
    {
        NSString *resourceName = [NSString stringWithFormat:@"%@-poster.jpg", self.episode.show.titleAcronym.lowercaseString];
        NSString *resourcePath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:resourceName];
        
        if([NSFileManager.defaultManager fileExistsAtPath:resourcePath])
            _path = resourcePath;
        else
            _path = self.episode.show.albumArt.path;
    }
    
    if((!_path || [_path isEqualToString:@""]) && self.url)
    {
        NSURL *url = [NSURL URLWithString:self.url];
        NSString *cachedDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:folder] path];
        NSString *cachedPath = [cachedDir stringByAppendingPathComponent:url.lastPathComponent];
        
        if([NSFileManager.defaultManager fileExistsAtPath:cachedPath])
        {
            _path = cachedPath;
            [self willChangeValueForKey:@"path"];
            [self setPrimitiveValue:_path forKey:@"path"];
            [self didChangeValueForKey:@"path"];
        }
    }
    
    if(_path && self.url && ![NSFileManager.defaultManager fileExistsAtPath:_path])
    {   
        // TODO: Download (iCloud sync) (reset URL?)
    }
    
    [self didAccessValueForKey:@"path"];
    
    return _path;
}

- (void)setPath:(NSString*)_path
{
    if([_path isEqualToString:self.path])
        return;
    
    if([NSFileManager.defaultManager fileExistsAtPath:self.path])
    {
        NSString *resourceName = [NSString stringWithFormat:@"%@-poster.jpg", self.episode.show.titleAcronym.lowercaseString];
        NSString *resourcePath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:resourceName];
        
        if(![self.path isEqualToString:resourcePath])
            [NSFileManager.defaultManager removeItemAtPath:self.path error:nil];
    }
    
    [self willChangeValueForKey:@"path"];
    [self setPrimitiveValue:_path forKey:@"path"];
    [self didChangeValueForKey:@"path"];
}

- (void)prepareForDeletion
{
    NSLog(@"prepareForDeletion, %@", self);
    self.path = nil;
}

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
