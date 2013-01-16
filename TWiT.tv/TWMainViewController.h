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

@class TWEpisodeViewController, Channel, TWPlayButton;

@interface TWMainViewController : UITableViewController <NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate, TWiTShowGridCellDelegate>

@property (nonatomic, weak) TWSplitViewContainer *splitViewContainer;
@property (assign, nonatomic) TWSection sectionVisible;

@property (strong, nonatomic) Channel *channel;

@property (strong, nonatomic) TWEpisodeViewController *episodeViewController;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedEpisodesController, *fetchedShowsController;

@property (strong, nonatomic) NSMutableDictionary *showsTableCache;
@property (strong, nonatomic) UIImageView *showSelectedView;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIButton *watchButton, *listenButton;
@property (weak, nonatomic) IBOutlet TWPlayButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *liveTimeLabel, *liveTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *livePosterView, *liveAlbumArtView;
@property (weak, nonatomic) IBOutlet UITableView *scheduleTable;
@property (strong, nonatomic) UIView *sectionHeader;

- (void)updateProgress:(NSNotification*)notification;

- (void)redrawSchedule:(NSNotification*)notification;
- (IBAction)transitionToSchedule:(UIButton*)sender;
- (IBAction)transitionToLive:(UIButton*)sender;

@end
