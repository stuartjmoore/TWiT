//
//  NSManagedObjectContext+ConvenienceMethods.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/4/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (ConvenienceMethods)

- (id)insertEntity:(NSString*)name;
- (NSSet*)fetchEntities:(NSString*)entityName withPredicate:(id)stringOrPredicate, ...;

@end
