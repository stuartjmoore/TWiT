//
//  TWMainViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "TWShowsCell.h"

typedef NS_ENUM(NSInteger, TWSection)
{
    TWSectionEpisodes,
    TWSectionShows
};

@class TWEpisodeViewController;

@interface TWMainViewController : UITableViewController <NSFetchedResultsControllerDelegate, TWiTShowGridCellDelegate>
{
    TWSection sectionVisible;
}

@property (strong, nonatomic) TWEpisodeViewController *episodeViewController;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedEpisodesController, *fetchedShowsController;

@end