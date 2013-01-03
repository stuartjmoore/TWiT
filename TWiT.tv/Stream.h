//
//  Stream.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Feed.h"

@class Channel;

@interface Stream : NSManagedObject

@property (nonatomic, strong) NSString *title, *subtitle, *url;
@property (nonatomic) TWType type;
@property (nonatomic) TWQuality quality;
@property (nonatomic, strong) Channel *channel;

@end
