//
//  Enclosure.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Enclosure.h"
#import "Episode.h"
#import "Show.h"

#define folder @"Downloads.nosync"

@implementation Enclosure

@dynamic path, quality, subtitle, title, type, url, episode;

@synthesize downloadSession = _downloadSession, downloadTask = _downloadTask;
@synthesize backgroundSessionCompletionHandler = _backgroundSessionCompletionHandler;
@synthesize downloadedPercentage = _downloadedPercentage;

- (void)prepareForDeletion
{
    if([NSFileManager.defaultManager fileExistsAtPath:self.path])
        [NSFileManager.defaultManager removeItemAtPath:self.path error:nil];
}

- (NSString*)path
{
    NSString *_path = [self primitiveValueForKey:@"path"];
    
    if(_path && ![NSFileManager.defaultManager fileExistsAtPath:_path])
    {
        _path = nil;
        
        [self willChangeValueForKey:@"path"];
        [self setPrimitiveValue:nil forKey:@"path"];
        [self didChangeValueForKey:@"path"];
    }
    
    return _path;
}

#pragma mark - Download

- (void)download
{
    if(self.downloadTask)
        return;
    
    NSString *sessionId = [NSString stringWithFormat:@"com.stuartjmoore.twit.pro.enclosure.%@.%d.%d",
                           self.episode.show.titleAcronym.lowercaseString,
                           self.episode.number,
                           self.quality];
    
    NSURL *url = [NSURL URLWithString:self.url];
    NSURLSessionConfiguration *downloadConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionId];
    self.downloadSession = [NSURLSession sessionWithConfiguration:downloadConfig delegate:self delegateQueue:NSOperationQueue.mainQueue];
    
    self.downloadTask = [self.downloadSession downloadTaskWithURL:url];
    [self.downloadTask resume];
    
    self.downloadedPercentage = 0;
    UIApplication.sharedApplication.networkActivityIndicatorVisible = YES;
}

- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

#pragma mark Progress

- (void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    self.downloadedPercentage = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    [NSNotificationCenter.defaultCenter postNotificationName:@"enclosureDownloadDidReceiveData" object:self];
}

#pragma mark Finish

-(void)URLSession:(NSURLSession*)session downloadTask:(NSURLSessionDownloadTask*)downloadTask didFinishDownloadingToURL:(NSURL*)location
{
    NSURL *url = downloadTask.originalRequest.URL;
    NSString *downloadDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:folder] path];
    
    if(![NSFileManager.defaultManager fileExistsAtPath:downloadDir])
        [NSFileManager.defaultManager createDirectoryAtPath:downloadDir withIntermediateDirectories:NO attributes:nil error:nil];
    
    NSString *downloadPath = [downloadDir stringByAppendingPathComponent:url.lastPathComponent];
    
    if([NSFileManager.defaultManager fileExistsAtPath:downloadPath])
        [NSFileManager.defaultManager removeItemAtPath:downloadPath error:nil];
    
    if([NSFileManager.defaultManager moveItemAtPath:location.path toPath:downloadPath error:nil])
    {
        [self.episode willChangeValueForKey:@"enclosures"];
        self.path = downloadPath;
        [self.managedObjectContext save:nil];
        [self.episode didChangeValueForKey:@"enclosures"];
    }
}

- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)downloadTask didCompleteWithError:(NSError*)error
{
    [self closeDownloadWithError:error];
    
    if(self.backgroundSessionCompletionHandler)
    {
        __weak typeof(self) weak = self;
        
        [self.downloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downTasks)
        {
            if(dataTasks.count + uploadTasks.count + downTasks.count == 0)
            {
                void (^completionHandler)() = weak.backgroundSessionCompletionHandler;
                weak.backgroundSessionCompletionHandler = nil;
                completionHandler();
            }
        }];
    }
}

- (void)closeDownloadWithError:(NSError*)error
{
    UIApplication.sharedApplication.networkActivityIndicatorVisible = NO;
    
    self.downloadTask = nil;
    self.downloadedPercentage = 0;
    
    NSString *notificationName = error ? @"enclosureDownloadDidFail" : @"enclosureDownloadDidFinish";
    [NSNotificationCenter.defaultCenter postNotificationName:notificationName object:self];
}

#pragma mark Actions

- (void)cancelDownload
{
    [self.downloadTask cancel];
    
    NSError *error = [NSError errorWithDomain:@"user-canceled" code:1 userInfo:nil];
    [self closeDownloadWithError:error];
}

- (void)deleteDownload
{
    if([NSFileManager.defaultManager fileExistsAtPath:self.path])
        [NSFileManager.defaultManager removeItemAtPath:self.path error:nil];
    
    [self.episode willChangeValueForKey:@"enclosures"];
    self.path = nil;
    [self.episode didChangeValueForKey:@"enclosures"];
}

#pragma mark - Helpers

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
