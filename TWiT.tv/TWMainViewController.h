//
//  TWMainViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "TWShowTableCell.h"

#define headerHeight 180

typedef NS_ENUM(NSInteger, TWSection)
{
    TWSectionEpisodes,
    TWSectionShows
};

@class TWEpisodeViewController, Channel;

@interface TWMainViewController : UITableViewController <NSFetchedResultsControllerDelegate, TWiTShowGridCellDelegate>
{
    TWSection sectionVisible;
}

@property (strong, nonatomic) Channel *channel;

@property (strong, nonatomic) TWEpisodeViewController *episodeViewController;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedEpisodesController, *fetchedShowsController;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *liveTimeLabel, *liveTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *livePosterView;
@property (weak, nonatomic) IBOutlet UITableView *scheduleTable;
@property (strong, nonatomic) UIView *sectionHeader;

- (void)reloadSchedule:(NSNotification*)notification;
- (IBAction)openScheduleView:(UIButton*)sender;

@end
