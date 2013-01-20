//
//  Channel.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Schedule.h"
#import "Feed.h"

@class Show, Stream, Schedule;

@interface Channel : NSManagedObject

@property (nonatomic, strong) NSString *title, *desc;
@property (nonatomic, strong) NSString *scheduleURL, *website;
@property (nonatomic, strong) NSDate *published;
@property (nonatomic, strong) NSSet *shows, *streams;

@property (strong, nonatomic) Schedule *schedule;

- (Stream*)streamForType:(TWType)type;
- (Stream*)streamForQuality:(TWQuality)quality;

- (void)update;
- (void)updateJSON;
- (void)updateDatabase;
- (void)reloadSchedule;

@end

@interface Channel (CoreDataGeneratedAccessors)

- (void)addShowsObject:(Show*)value;
- (void)removeShowsObject:(Show*)value;
- (void)addShows:(NSSet*)values;
- (void)removeShows:(NSSet*)values;

- (void)addStreamsObject:(Stream*)value;
- (void)removeStreamsObject:(Stream*)value;
- (void)addStreams:(NSSet *)values;
- (void)removeStreams:(NSSet *)values;

@end
