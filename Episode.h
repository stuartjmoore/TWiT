//
//  Episode.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Enclosure, Poster, Show;

@interface Episode : NSManagedObject

@property (nonatomic, retain) NSString *title, *guests, *desc;
@property (nonatomic) int16_t number;
@property (nonatomic) NSDate *published;
@property (nonatomic) int16_t duration, lastTimecode;
@property (nonatomic) BOOL watched;
@property (nonatomic) int16_t downloadedQuality, downloadState;
@property (nonatomic, retain) NSString *website;
@property (nonatomic, retain) NSSet *enclosures;
@property (nonatomic, retain) Poster *poster;
@property (nonatomic, retain) Show *show;

@end

@interface Episode (CoreDataGeneratedAccessors)

- (void)addEnclosuresObject:(Enclosure*)value;
- (void)removeEnclosuresObject:(Enclosure*)value;
- (void)addEnclosures:(NSSet*)values;
- (void)removeEnclosures:(NSSet*)values;

@end
