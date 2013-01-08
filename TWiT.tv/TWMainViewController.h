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

#define mainHeaderHeight 180
#define mainHeaderHeight_iPad 62
#define mainHeaderHeight_iPad_shows 220

typedef NS_ENUM(NSInteger, TWSection)
{
    TWSectionEpisodes,
    TWSectionShows
};

@class TWEpisodeViewController, Channel;

@interface TWMainViewController : UITableViewController <NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate, TWiTShowGridCellDelegate>
{
    TWSection sectionVisible;
}

@property (strong, nonatomic) Channel *channel;

@property (strong, nonatomic) TWEpisodeViewController *episodeViewController;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedEpisodesController, *fetchedShowsController;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIButton *watchButton, *listenButton;
@property (weak, nonatomic) IBOutlet UILabel *liveTimeLabel, *liveTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *livePosterView, *liveAlbumArtView;
@property (weak, nonatomic) IBOutlet UITableView *scheduleTable;
@property (strong, nonatomic) UIView *sectionHeader;

- (IBAction)loadLiveDetail:(UIButton*)sender;

- (void)reloadSchedule:(NSNotification*)notification;

@end
