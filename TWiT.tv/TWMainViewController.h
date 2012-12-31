//
//  TWMainViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWEpisodeViewController;

#import <CoreData/CoreData.h>

@interface TWMainViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    int sectionVisible;
}

@property (strong, nonatomic) TWEpisodeViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
