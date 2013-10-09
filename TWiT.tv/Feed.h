//
//  Feed.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(int16_t, TWQuality)
{
    TWQualityAudio,
    TWQualityMobile,
    TWQualityHigh,
    TWQualityHD
};

typedef NS_ENUM(int16_t, TWType)
{
    TWTypeAudio,
    TWTypeVideo,
    TWTypeYouTube
};

@class Show;

@interface Feed : NSManagedObject

@property (nonatomic, strong) NSString *title, *subtitle, *url;
@property (nonatomic) TWQuality quality;
@property (nonatomic) TWType type;
@property (nonatomic, strong) NSDate *lastUpdated, *lastEnclosureDate;
@property (nonatomic, strong) Show *show;

@end
