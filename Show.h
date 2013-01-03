//
//  Show.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AlbumArt, Episode, Feed, Channel;

@interface Show : NSManagedObject

@property (nonatomic, retain) NSString *title, *titleAcronym, *titleInSchedule;
@property (nonatomic, retain) NSString *desc, *hosts, *schedule;
@property (nonatomic, retain) NSString *email, *phone, *website;
@property (nonatomic) NSDate *published;
@property (nonatomic) BOOL favorite, remind;
@property (nonatomic) int16_t sort;
@property (nonatomic, retain) AlbumArt *albumArt;
@property (nonatomic, retain) Channel *channel;
@property (nonatomic, retain) NSSet *episodes, *feeds;

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
