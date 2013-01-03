//
//  Feed.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(int16_t, TWFeedQuality)
{
    TWFeedQualityAudio,
    TWFeedQualityMobile,
    TWFeedQualityHigh,
    TWFeedQualityHD
};

typedef NS_ENUM(int16_t, TWFeedType)
{
    TWFeedTypeAudio,
    TWFeedTypeVideo,
    TWFeedTypeYouTube
};

@class Show;

@interface Feed : NSManagedObject

@property (nonatomic, strong) NSString *title, *subtitle, *url;
@property (nonatomic) TWFeedQuality quality;
@property (nonatomic) TWFeedType type;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) Show *show;

@end
