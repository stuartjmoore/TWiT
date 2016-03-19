//
//  TWShowViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/2/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWSplitViewContainer.h"
#import "TWNavigationController.h"
#import "TWShowsViewController.h"
#import "TWShowViewController.h"
#import "TWEpisodeViewController.h"
#import "TWEnclosureViewController.h"

#import "TWEpisodeCell.h"

#import "Show.h"
#import "AlbumArt.h"
#import "Episode.h"
#import "Enclosure.h"

#define NAVBAR_INSET 64

@implementation TWShowViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
    
    CAGradientLayer *liveGradient = [CAGradientLayer layer];
    liveGradient.anchorPoint = CGPointMake(0, 0);
    liveGradient.position = CGPointMake(0, 0);
    liveGradient.startPoint = CGPointMake(0, 1);
    liveGradient.endPoint = CGPointMake(0, 0);
    liveGradient.bounds = self.gradientView.bounds;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        self.headerView.translatesAutoresizingMaskIntoConstraints = YES;
        self.blurgroundView.barStyle = UIBarStyleBlack;
        self.blurgroundView.clipsToBounds = YES;
        
        liveGradient.colors = [NSArray arrayWithObjects:
                               (id)[UIColor colorWithWhite:0 alpha:1].CGColor,
                               (id)[UIColor colorWithWhite:0 alpha:0.6f].CGColor,
                               (id)[UIColor colorWithWhite:0 alpha:0].CGColor, nil];
    }
    else
    {
        liveGradient.colors = [NSArray arrayWithObjects:
                               (id)[UIColor colorWithWhite:1 alpha:1].CGColor,
                               (id)[UIColor colorWithWhite:1 alpha:0.9f].CGColor,
                               (id)[UIColor colorWithWhite:1 alpha:0].CGColor, nil];
    }
    
    [self.gradientView.layer addSublayer:liveGradient];
    
    self.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithTitle:self.show.titleAcronym
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:nil
                                                                          action:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self becomeFirstResponder];
    [super viewWillAppear:animated];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidReceiveData"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidFinish"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidFail"
                                             object:nil];
}

- (void)setShow:(Show*)show
{
    if(_show != show)
    {
        _show = show;
        [self configureView];
    }
}

- (void)configureView
{
    if(self.show)
    {
        self.title = self.show.title;
        self.albumArt.image = self.show.albumArt.image;
        self.posterView.image = self.show.albumArt.image;
        
        self.scheduleLabel.text = self.show.scheduleString;
        self.descLabel.text = self.show.desc;
        
        self.favoriteButton.selected = self.show.favorite;
        self.remindButton.selected = self.show.remind;
        
        self.emailButton.hidden = !self.show.email;
        self.phoneButton.hidden = ([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"tel:+11111"]]) ? !self.show.phone : YES;

        self.fetchedEpisodesController = nil;
        [self.tableView reloadData];
    }
}

#pragma mark - Actions

- (IBAction)setFavorite:(UIButton*)sender
{
    self.show.favorite = !self.show.favorite;
    sender.selected = self.show.favorite;
}

- (IBAction)setReminder:(UIButton*)sender
{
    self.show.remind = !self.show.remind;
    sender.selected = self.show.remind;
}

- (IBAction)openDetailView:(UIButton*)sender
{
    CGFloat headerHeight = self.tableView.tableHeaderView.frame.size.height;
    
    if(self.tableView.contentOffset.y <= -self.view.bounds.size.height+headerHeight)
    {
        self.tableView.scrollEnabled = YES;
        
        __weak typeof(self) weak = self;
        
        [UIView animateWithDuration:0.3f animations:^
        {
            weak.tableView.contentOffset = CGPointMake(0, -NAVBAR_INSET);
            sender.transform = CGAffineTransformMakeRotation(0);
            [sender setImage:[UIImage imageNamed:@"toolbar-disclose"] forState:UIControlStateNormal];
            [weak.headerView layoutIfNeeded];
        }];
    }
    else
    {
        self.tableView.scrollEnabled = NO;
        
        __weak typeof(self) weak = self;
        
        [UIView animateWithDuration:0.3f animations:^
        {
            weak.tableView.contentOffset = CGPointMake(0, -weak.view.bounds.size.height+headerHeight);
            sender.transform = CGAffineTransformMakeRotation(M_PI);
            [sender setImage:[UIImage imageNamed:@"toolbar-disclose-up"] forState:UIControlStateNormal];
            [weak.headerView layoutIfNeeded];
        }];
    }
}

- (IBAction)email:(UIButton*)sender
{
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setToRecipients:[NSArray arrayWithObject:self.show.email]];
    [self presentViewController:controller animated:YES completion:nil];
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)phone:(UIButton*)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@", self.show.phone]];
    [UIApplication.sharedApplication openURL:url];
}

#pragma mark Shake

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent*)event
{
    if(event.subtype == UIEventSubtypeMotionShake)
        [self.show forceUpdateEpisodes];
}

#pragma mark Episodes

- (NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if([tableView.indexPathForSelectedRow isEqual:indexPath])
        {
            [self.splitViewContainer hideModalFlyout];
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        else
        {
            UINavigationController *modalController = self.splitViewContainer.modalController;
            TWEpisodeViewController *episodeController = (TWEpisodeViewController*)modalController.topViewController;
            Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
            
            if(!episode.published)
            {
                NSString *message = (indexPath.row >= 10)
                                  ? @"Episodes older than 10 weeks aren’t available in TWiT’s feeds anymore."
                                  : @"If you’re online, shake to force a refresh.";
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh-oh"
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:nil];
                
                [alert show];
                return nil;
            }
            
            episodeController.episode = episode;
            
            [self.splitViewContainer showModalFlyout];
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        return nil;
    }
    
    return indexPath;
}

#pragma mark - Table

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    CGFloat headerHeight = self.tableView.tableHeaderView.frame.size.height;
    
    if(scrollView == self.tableView)
    {
        CGRect frame = self.headerView.frame;
        if(scrollView.contentOffset.y < -NAVBAR_INSET)
        {
            frame.origin.y = scrollView.contentOffset.y + NAVBAR_INSET;
            frame.size.height = ceilf(headerHeight - scrollView.contentOffset.y - NAVBAR_INSET);
        }
        else
        {
            frame.origin.y = 0;
            frame.size.height = headerHeight;
        }
        
        self.headerView.frame = frame;
        [self.headerView layoutIfNeeded];
        
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(frame.size.height + NAVBAR_INSET, 0, 0, 1);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return self.fetchedEpisodesController.sections.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo>sectionInfo = self.fetchedEpisodesController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *identifier = @"episodeCell";
    TWEpisodeCell *cell = (TWEpisodeCell*)[tableView dequeueReusableCellWithIdentifier:identifier];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Configure

- (void)configureCell:(TWEpisodeCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if([cell.reuseIdentifier isEqualToString:@"episodeCell"])
    {
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        TWEpisodeCell *episodeCell = (TWEpisodeCell*)cell;
        episodeCell.delegate = self;
        episodeCell.table = self.tableView;
        episodeCell.indexPath = indexPath;
        episodeCell.episode = episode;
        episodeCell.subtitleLabel.text = episode.guests;
        self.accessibilityLabel = [NSString stringWithFormat:@"Episode %d, %@, with %@.", episode.number, episode.title, episode.guests];
    }
}

#pragma mark - Notifications

- (void)updateProgress:(NSNotification*)notification
{
    Enclosure *enclosure = notification.object;
    Episode *episode = enclosure.episode;
    NSIndexPath *indexPath = [self.fetchedEpisodesController indexPathForObject:episode];
    TWEpisodeCell *cell = (TWEpisodeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if([notification.name isEqualToString:@"enclosureDownloadDidReceiveData"])
        cell.progress = enclosure.downloadedPercentage;
    else if([notification.name isEqualToString:@"enclosureDownloadDidFinish"] || [notification.name isEqualToString:@"enclosureDownloadDidFail"])
        cell.progress = 1;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController*)fetchedEpisodesController
{
    if(_fetchedEpisodesController != nil)
        return _fetchedEpisodesController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.show.managedObjectContext];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"number" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"show = %@", self.show]; //AND published != nil
    
    [fetchRequest setFetchBatchSize:10];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    [fetchRequest setPredicate:predicate];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.show.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    controller.delegate = self;
    self.fetchedEpisodesController = controller;
    
	NSError *error = nil;
	if(![self.fetchedEpisodesController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedEpisodesController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if(controller == self.fetchedEpisodesController)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeMove:
            case NSFetchedResultsChangeUpdate:
                break;
        }
    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    if(controller == self.fetchedEpisodesController)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Rotate

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Leave

- (BOOL)shouldPerformSegueWithIdentifier:(NSString*)identifier sender:(id)sender
{
    if([identifier isEqualToString:@"episodeDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        
        if(!episode.published)
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            NSString *message = (indexPath.row >= 10)
                              ? @"Episodes older than 10 weeks aren’t available in TWiT’s feeds anymore."
                              : @"Uh-oh. We should be re-syncing as soon as possible.";
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Available"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:nil];
            [alert show];
            return NO;
        }
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"episodeDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        [segue.destinationViewController setEpisode:episode];
    }
    else if([segue.identifier isEqualToString:@"playerDetail"])
    {
        TWEpisodeCell *episodeCell = (TWEpisodeCell*)[[[sender superview] superview] superview];
        Episode *episode = episodeCell.episode;
        NSSet *enclosures = [episode downloadedEnclosures];
        Enclosure *enclosure = enclosures.anyObject ?: [episode enclosureForType:TWTypeVideo andQuality:TWQualityHigh];
        
        [segue.destinationViewController setEnclosure:enclosure];
    }
    else if([segue.identifier isEqualToString:@"showInfoDetail"])
    {
        [segue.destinationViewController setShow:self.show];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if(self.tableView.indexPathForSelectedRow)
        {
            [self.splitViewContainer hideModalFlyout];
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
        }
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidReceiveData" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFinish" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFail" object:nil];
    
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
