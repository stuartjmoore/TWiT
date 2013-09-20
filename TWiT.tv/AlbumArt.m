//
//  AlbumArt.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "AlbumArt.h"
#import "Show.h"

#define folder @"AlbumArt.nosync"

@implementation AlbumArt

@dynamic path, url, show;

- (UIImage*)image
{
    return [UIImage imageWithContentsOfFile:self.path] ?: [UIImage imageNamed:@"generic.jpg"];
}

- (void)setUrl:(NSString*)URLString
{
    [self willChangeValueForKey:@"image"];
    [self willChangeValueForKey:@"url"];
    [self setPrimitiveValue:URLString forKey:@"url"];
    [self didChangeValueForKey:@"url"];
    [self didChangeValueForKey:@"image"];
    
    NSURL *url = [NSURL URLWithString:URLString];
    [self downloadAlbumArtFromURL:url];
}

- (NSString*)path
{
    NSString *_path = [self primitiveValueForKey:@"path"];
    
    if((!_path || [_path isEqualToString:@""]) && self.url)
    {
        NSURL *url = [NSURL URLWithString:self.url];
        NSString *cachedDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:folder] path];
        NSString *cachedPath = [cachedDir stringByAppendingPathComponent:url.lastPathComponent];
        
        if([NSFileManager.defaultManager fileExistsAtPath:cachedPath])
        {
            _path = cachedPath;
            [self willChangeValueForKey:@"image"];
            [self willChangeValueForKey:@"path"];
            [self setPrimitiveValue:_path forKey:@"path"];
            [self didChangeValueForKey:@"path"];
            [self didChangeValueForKey:@"image"];
        }
    }
    
    if(_path && ![NSFileManager.defaultManager fileExistsAtPath:_path] && self.url)
    {
        [self willChangeValueForKey:@"path"];
        [self setPrimitiveValue:nil forKey:@"path"];
        [self didChangeValueForKey:@"path"];
        
        NSURL *url = [NSURL URLWithString:self.url];
        [self downloadAlbumArtFromURL:url];
    }
    
    return _path;
}

- (void)setPath:(NSString*)_path
{
    if([_path isEqualToString:self.path])
        return;
    
    if([NSFileManager.defaultManager fileExistsAtPath:self.path])
        [NSFileManager.defaultManager removeItemAtPath:self.path error:nil];
        
    [self willChangeValueForKey:@"image"];
    [self willChangeValueForKey:@"path"];
    [self setPrimitiveValue:_path forKey:@"path"];
    [self didChangeValueForKey:@"path"];
    [self didChangeValueForKey:@"image"];
}

#pragma mark - Download

- (void)downloadAlbumArtFromURL:(NSURL*)url
{
    NSLog(@"downloadAlbumArtFromURL");
    
    NSString *cachedDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:folder] path];
    NSString *cachedPath = [cachedDir stringByAppendingPathComponent:url.lastPathComponent];
    
    if(![NSFileManager.defaultManager fileExistsAtPath:cachedDir])
    {
        NSLog(@"downloadAlbumArtFromURL - create folder");
        [NSFileManager.defaultManager createDirectoryAtPath:cachedDir withIntermediateDirectories:NO attributes:nil error:nil];
        
        NSURL *cachedURL = [NSURL fileURLWithPath:cachedDir];
        [cachedURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
    
    // ---
    
    if(url.fragment)
    {
        NSString *fileName = [url.lastPathComponent stringByReplacingOccurrencesOfString:url.pathExtension withString:@""];
        NSString *resourceName = [NSString stringWithFormat:@"%@%@.%@", fileName, url.fragment, url.pathExtension];
        NSString *resourcePath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:resourceName];
        
        if([NSFileManager.defaultManager fileExistsAtPath:resourcePath] && ![NSFileManager.defaultManager fileExistsAtPath:cachedPath])
        {
            NSLog(@"downloadAlbumArtFromURL - copy resource");
            
            self.path = cachedPath;
            [NSFileManager.defaultManager copyItemAtPath:resourcePath toPath:cachedPath error:nil];
            
            [NSNotificationCenter.defaultCenter postNotificationName:@"albumArtDidChange" object:self.show];
            
            return;
        }
        
        if(!self.path && [NSFileManager.defaultManager fileExistsAtPath:cachedPath])
        {
            self.path = cachedPath;
        }
    }
    
    // ---
    
    BOOL downloadFromServer = YES;
    
    if(url.fragment && [NSFileManager.defaultManager fileExistsAtPath:cachedPath])
    {
        NSError *error = nil;
        
        NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:cachedPath error:&error];
        
        if(error)
            return;
        
        NSDate *lastModifiedLocal = [fileAttributes fileModificationDate];
        NSDate *lastModifiedServer = [NSDate dateWithTimeIntervalSince1970:url.fragment.floatValue];
        
        downloadFromServer = (!lastModifiedLocal) || ([lastModifiedLocal laterDate:lastModifiedServer] == lastModifiedServer);
    }
    
    NSLog(@"downloadFromServer? - %@", downloadFromServer?@"yes":@"no");
    
    // ---
    
    if(downloadFromServer)
    {
        NSString *sessionId = [NSString stringWithFormat:@"com.stuartjmoore.twit.pro.%@.albumArt", self.show.titleAcronym.lowercaseString];
        
        NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionId];
        NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue:NSOperationQueue.mainQueue];
        
        NSLog(@"downloadTaskWithURL %@", url);
        [[delegateFreeSession downloadTaskWithURL:url] resume];
    }
}


- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
}

- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

-(void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask didFinishDownloadingToURL:(NSURL*)location
{
    NSLog(@"location %@", location);
    
    NSURL *url = downloadTask.originalRequest.URL;
    
    NSLog(@"url %@", url);
    
    NSString *cachedDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:folder] path];
    NSString *cachedPath = [cachedDir stringByAppendingPathComponent:url.lastPathComponent];
    
    NSLog(@"cachedPath %@", cachedPath);
    
    // TODO: Shrink file to largest needed size on iPhone and iPad
    
    if([NSFileManager.defaultManager fileExistsAtPath:cachedPath])
        [NSFileManager.defaultManager removeItemAtPath:cachedPath error:nil];
    
    if([NSFileManager.defaultManager moveItemAtPath:location.path toPath:cachedPath error:nil])
    {
        self.path = cachedPath;
        
        NSLog(@"moveItemAtURL");
        
        if(url.fragment)
        {
            NSDate *lastModified = [NSDate dateWithTimeIntervalSince1970:url.fragment.floatValue];
            NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:lastModified forKey:NSFileModificationDate];
            [NSFileManager.defaultManager setAttributes:fileAttributes ofItemAtPath:cachedPath error:nil];
        }
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"albumArtDidChange" object:self.show];
}

#pragma mark - Kill

- (void)prepareForDeletion
{
    self.path = nil;
}

#pragma mark - Helpers

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
