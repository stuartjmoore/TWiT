//
//  TWShowViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/2/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@class TWEpisodeViewController, Show;

@interface TWShowViewController : UITableViewController <NSFetchedResultsControllerDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) Show *show;

@property (weak, nonatomic) TWSplitViewContainer *splitViewContainer;
@property (strong, nonatomic) TWEpisodeViewController *episodeViewController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedEpisodesController;

@property (weak, nonatomic) IBOutlet UIView *headerView, *gradientView;
@property (weak, nonatomic) IBOutlet UIToolbar *blurgroundView;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton, *remindButton;
@property (weak, nonatomic) IBOutlet UIButton *emailButton, *phoneButton;

@property (weak, nonatomic) IBOutlet UIImageView *albumArt, *posterView;
@property (weak, nonatomic) IBOutlet UILabel *scheduleLabel, *descLabel;

- (IBAction)setFavorite:(UIButton*)sender;
- (IBAction)setReminder:(UIButton*)sender;
- (IBAction)openDetailView:(UIButton*)sender;
- (IBAction)email:(UIButton*)sender;
- (IBAction)phone:(UIButton*)sender;

- (void)updateProgress:(NSNotification*)notification;

@end
