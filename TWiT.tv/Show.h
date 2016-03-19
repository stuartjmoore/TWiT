//
//  Show.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "AlbumArt.h"

@import UIKit;

@class AlbumArt, Episode, Feed, Channel, Poster;

@interface Show : NSManagedObject

@property (nonatomic, strong) NSString *title, *titleAcronym, *titleInSchedule;
@property (nonatomic, strong) NSString *desc, *hosts, *schedule;
@property (nonatomic, strong) NSString *email, *phone, *website;
@property (nonatomic, strong) NSDate *published;
@property (nonatomic) BOOL favorite, remind;
@property (nonatomic) int16_t sort;
@property (nonatomic) int32_t updateInterval;
@property (nonatomic, strong) AlbumArt *albumArt;
@property (nonatomic, strong) Channel *channel;
@property (nonatomic, strong) NSSet *episodes, *feeds;

- (Poster*)poster;
- (UIImage*)defaultImage;

- (NSArray*)scheduleDates;
- (NSString*)scheduleString;

- (void)updateEpisodes;
- (void)forceUpdateEpisodes;
- (void)updateEpisodesWithCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler;
- (void)updateEpisodesWithCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler forceUpdate:(BOOL)forceUpdate;
- (void)updatePodcastFeed:(Feed*)feed withCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler;
- (void)finishUpdateWithCompletionHandler:(void(^)(UIBackgroundFetchResult))completionHandler;

@end

@interface Show (CoreDataGeneratedAccessors)

- (void)addEpisodesObject:(Episode*)value;
- (void)removeEpisodesObject:(Episode*)value;
- (void)addEpisodes:(NSSet*)values;
- (void)removeEpisodes:(NSSet*)values;

- (void)addFeedsObject:(Feed*)value;
- (void)removeFeedsObject:(Feed*)value;
- (void)addFeeds:(NSSet*)values;
- (void)removeFeeds:(NSSet*)values;

@end
