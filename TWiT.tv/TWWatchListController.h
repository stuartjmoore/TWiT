//
//  TWWatchListController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 11/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWSplitViewContainer, Channel;

@interface TWWatchListController : UITableViewController <UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) TWSplitViewContainer *splitViewContainer;

@property (strong, nonatomic) Channel *channel;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedEpisodesController;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIToolbar *blurground;
@property (weak, nonatomic) IBOutlet UIImageView *livePosterView;
@property (weak, nonatomic) IBOutlet UITableView *scheduleTable;

- (void)redrawSchedule:(NSNotification*)notification;

@end
