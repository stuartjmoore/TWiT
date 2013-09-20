//
//  Episode.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Poster.h"
#import "Feed.h"

@class Enclosure, Show;

@interface Episode : NSManagedObject

@property (nonatomic, strong) NSString *title, *guests, *desc;
@property (nonatomic) int16_t number;
@property (nonatomic, strong) NSDate *published;
@property (nonatomic) int16_t duration, lastTimecode;
@property (nonatomic) BOOL watched;
@property (nonatomic) int16_t downloadedQuality, downloadState;
@property (nonatomic, strong) NSString *website;
@property (nonatomic, strong) NSSet *enclosures;
@property (nonatomic, strong) Poster *poster;
@property (nonatomic, strong) Show *show;

@property (nonatomic, strong) NSSet *downloadedEnclosures, *downloadingEnclosures;

- (NSString*)durationString;
- (NSString*)publishedString;

- (NSSet*)enclosuresForType:(enum TWType)type;
- (Enclosure*)enclosureForQuality:(TWQuality)quality;
- (Enclosure*)enclosureForType:(enum TWType)type andQuality:(enum TWQuality)quality;

- (void)downloadEnclosure:(Enclosure*)enclosure;
- (void)cancelDownloads;
- (void)deleteDownloads;

- (void)updatePoster:(NSNotification*)notification;

@end

@interface Episode (CoreDataGeneratedAccessors)

- (void)addEnclosuresObject:(Enclosure*)value;
- (void)removeEnclosuresObject:(Enclosure*)value;
- (void)addEnclosures:(NSSet*)values;
- (void)removeEnclosures:(NSSet*)values;

@end
