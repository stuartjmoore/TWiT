//
//  TWShowViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/2/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

#define headerHeight 180

@class Show;

@interface TWShowViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Show *show;

@property (strong, nonatomic) NSFetchedResultsController *fetchedEpisodesController;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton, *remindButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton, *phoneButton;

@property (weak, nonatomic) IBOutlet UIImageView *albumArt, *posterView;
@property (weak, nonatomic) IBOutlet UILabel *scheduleLabel, *descLabel;

- (IBAction)setReminder:(UIButton*)sender;
- (IBAction)openDetailView:(UIButton*)sender;

@end
