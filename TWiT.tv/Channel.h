//
//  Channel.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Show, Stream;

@interface Channel : NSManagedObject

@property (nonatomic, strong) NSString *title, *desc;
@property (nonatomic, strong) NSString *scheduleURL, *website;
@property (nonatomic, strong) NSDate *published;
@property (nonatomic, strong) NSSet *shows, *streams;

- (void)updateShows;

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
