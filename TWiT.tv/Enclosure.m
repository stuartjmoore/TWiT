//
//  Enclosure.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "Enclosure.h"
#import "Episode.h"

#define folder @"Downloads"

@implementation Enclosure

@dynamic path, quality, subtitle, title, type, url, episode;
@synthesize downloadingFile = _downloadingFile;
@synthesize expectedLength = _expectedLength, downloadedLength = _downloadedLength;

- (void)prepareForDeletion
{
    if([NSFileManager.defaultManager fileExistsAtPath:self.path])
        [NSFileManager.defaultManager removeItemAtPath:self.path error:nil];
}

#pragma mark - Download

- (void)download
{
    NSURL *url = [NSURL URLWithString:self.url];
    NSString *downloadDir = [[self.applicationDocumentsDirectory URLByAppendingPathComponent:folder] path];
    NSString *downloadPath = [downloadDir stringByAppendingPathComponent:url.lastPathComponent];
    
    if(![NSFileManager.defaultManager fileExistsAtPath:downloadDir])
        [NSFileManager.defaultManager createDirectoryAtPath:downloadDir withIntermediateDirectories:NO attributes:nil error:nil];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:downloadPath])
        [NSFileManager.defaultManager createFileAtPath:downloadPath contents:nil attributes:nil];
    
    self.path = downloadPath;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(!connection)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error!" message:@"Please check your internet connection"  delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        
        [alert show];
    }
}

-(void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    self.expectedLength = response.expectedContentLength;
    self.downloadedLength = 0;
    
    self.downloadingFile = [NSFileHandle fileHandleForWritingAtPath:self.path];
    [self.downloadingFile seekToEndOfFile];
}
-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [self.downloadingFile seekToEndOfFile];
    [self.downloadingFile writeData:data];
    
    self.downloadedLength += data.length;
    float percentage = (self.expectedLength != 0) ? self.downloadedLength/(float)self.expectedLength : 0;
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"enclosureDownloadDidReceiveData" object:self];
    
    NSLog(@"didReceiveData, %@, %f", self.path.lastPathComponent, percentage);
}

-(void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    self.expectedLength = 0;
    self.downloadedLength = 0;
    
    [self.downloadingFile closeFile];
    self.downloadingFile = nil;
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"enclosureDownloadDidFinish" object:self];
}
-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    self.expectedLength = 0;
    self.downloadedLength = 0;
    
    [self.downloadingFile closeFile];
    self.downloadingFile = nil;
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"enclosureDownloadDidFail" object:self];
}

- (NSURL*)applicationDocumentsDirectory
{
    return [[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
