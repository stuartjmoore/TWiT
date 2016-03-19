//
//  AlbumArt.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/3/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@import UIKit;

@class Show;

@interface AlbumArt : NSManagedObject

@property (nonatomic, retain) NSString *path, *url;
@property (nonatomic, retain) Show *show;

- (UIImage*)image;

@end
