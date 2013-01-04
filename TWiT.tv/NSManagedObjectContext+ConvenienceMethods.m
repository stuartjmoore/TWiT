//
//  NSManagedObjectContext+ConvenienceMethods.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/4/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "NSManagedObjectContext+ConvenienceMethods.h"

@implementation NSManagedObjectContext (ConvenienceMethods)

- (id)insertEntity:(NSString*)name
{
    return [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:self];

}

- (NSSet*)fetchEntities:(NSString*)entityName withPredicate:(id)stringOrPredicate, ...
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    [request setEntity:entity];
    
    if(stringOrPredicate)
    {
        NSPredicate *predicate;
        
        if([stringOrPredicate isKindOfClass:NSString.class])
        {
            va_list variadicArguments;
            va_start(variadicArguments, stringOrPredicate);
            predicate = [NSPredicate predicateWithFormat:stringOrPredicate arguments:variadicArguments];
            va_end(variadicArguments);
        }
        else
        {
            predicate = (NSPredicate*)stringOrPredicate;
        }
        
        [request setPredicate:predicate];
    }
    
    NSArray *results = [self executeFetchRequest:request error:nil];
    
    return [NSSet setWithArray:results];
}

@end
