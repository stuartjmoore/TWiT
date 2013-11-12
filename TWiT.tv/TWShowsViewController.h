//
//  TWShowsViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 11/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWSplitViewContainer, TWLargeHeaderCell, TWPlayButton, Channel;

@interface TWShowsViewController : UICollectionViewController <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) TWSplitViewContainer *splitViewContainer;

@property (strong, nonatomic) Channel *channel;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedShowsController;

@property (weak, nonatomic) IBOutlet TWLargeHeaderCell *headerView;

- (void)redrawSchedule:(NSNotification*)notification;

@end
