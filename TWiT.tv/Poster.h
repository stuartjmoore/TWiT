//
//  Poster.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Episode;

@interface Poster : NSManagedObject

@property (nonatomic, retain) NSString *url, *path;
@property (nonatomic, retain) Episode *episode;

@property (nonatomic, retain) UIImage *image;

@end
