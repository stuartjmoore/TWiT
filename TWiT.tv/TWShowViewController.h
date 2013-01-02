//
//  TWShowViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/2/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

#define headerHeight 180

@interface TWShowViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedEpisodesController;

@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (weak, nonatomic) IBOutlet UIImageView *albumArt, *posterView;
@property (weak, nonatomic) IBOutlet UILabel *scheduleLabel, *descLabel;

- (IBAction)openDetailView:(UIButton*)sender;

@end
