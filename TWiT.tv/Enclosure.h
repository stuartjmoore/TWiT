//
//  Enclosure.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Feed.h"

@class Episode;

@interface Enclosure : NSManagedObject <NSURLConnectionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSString *title, *subtitle;
@property (nonatomic, strong) NSString *url, *path;
@property (nonatomic) TWQuality quality;
@property (nonatomic) TWType type;
@property (nonatomic, strong) Episode *episode;

@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, copy) void (^backgroundSessionCompletionHandler)();
@property (nonatomic) CGFloat downloadedPercentage;

- (void)download;
- (void)cancelDownload;
- (void)closeDownloadWithError:(NSError*)error;
- (void)deleteDownload;

@end
