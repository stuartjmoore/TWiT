//
//  TWWatchListController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 11/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "NSDate+comparisons.h"

#import "TWWatchListController.h"
#import "TWSplitViewContainer.h"
#import "TWShowsViewController.h"
#import "TWEpisodeViewController.h"
#import "TWEnclosureViewController.h"
#import "TWStreamViewController.h"

#import "Schedule.h"
#import "Channel.h"
#import "Show.h"
#import "Episode.h"
#import "Enclosure.h"

#import "TWEpisodeCell.h"

#define NAVBAR_INSET 64

@interface TWWatchListController ()

@end

@implementation TWWatchListController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.blurground.barStyle = UIBarStyleBlack;
    self.blurground.clipsToBounds = YES;
    
    self.headerView.translatesAutoresizingMaskIntoConstraints = YES;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(redrawSchedule:)
                                                   name:@"ScheduleDidUpdate"
                                                 object:self.channel.schedule];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [self redrawSchedule:nil];
    
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
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        UIImage *backIcon = [[UIImage imageNamed:@"navbar-back-twit-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithImage:backIcon
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:nil
                                                                              action:nil];
    }
}

#pragma mark - Gesture Recognizer

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer*)recognizer
{
    UIView *cell = recognizer.view;
    CGPoint translation = [recognizer translationInView:cell.superview];
    
    if(fabsf(translation.x) > fabsf(translation.y))
        return YES;
    
    return NO;
}

- (void)swipeEpisode:(UIPanGestureRecognizer*)recognizer
{
    TWEpisodeCell *cell = (TWEpisodeCell*)recognizer.observationInfo;
    UIView *view = recognizer.view;
    
    if(cell.selected)
        return;
    
    if(!cell || ![cell isKindOfClass:TWEpisodeCell.class])
        return;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if(!indexPath)
        return;
    
    Episode *episode = cell.episode;
    CGRect frame = view.frame;
    
    if(episode.downloadedEnclosures)
        return;
    
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        cell.swipeBackgroundView.hidden = NO;
        cell.swipeConfirmationView.hidden = YES;
    }
    else if(recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:view];
        
        frame.origin.x = translation.x;
        view.frame = frame;
        
        if(view.frame.origin.x > 0)
            cell.swipeLabel.textAlignment = NSTextAlignmentLeft;
        else
            cell.swipeLabel.textAlignment = NSTextAlignmentRight;
        
        if(view.frame.origin.x > self.tableView.frame.size.width/2)
            cell.swipeLabel.text = @"Release to Hide";
        else if(view.frame.origin.x < -self.tableView.frame.size.width/2)
            cell.swipeLabel.text = @"Release to Hide";
        else
            cell.swipeLabel.text = @"Swipe to Hide";
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGFloat speed = [recognizer velocityInView:view].x;
        
        if(view.frame.origin.x > self.tableView.frame.size.width/2
           || view.frame.origin.x < -self.tableView.frame.size.width/2
           || fabs(speed) > 1000)
        {
            cell.swipeLabel.text = @"Hiding…";
            
            CGFloat animateSpeed = (self.tableView.frame.size.width-frame.origin.x)/speed;
            
            if(view.frame.origin.x > self.tableView.frame.size.width/2)
                frame.origin.x = self.tableView.frame.size.width;
            else if(view.frame.origin.x < -self.tableView.frame.size.width/2)
                frame.origin.x = -self.tableView.frame.size.width;
            
            [UIView animateWithDuration:animateSpeed animations:^{
                view.frame = frame;
            } completion:^(BOOL fin) {
                if(!episode.downloadedEnclosures && !episode.watched)
                    episode.watched = YES;
            }];
        }
        else
        {
            cell.swipeLabel.text = @"Nevermind";
            
            frame.origin.x = 0;
            [UIView animateWithDuration:0.5f animations:^{
                view.frame = frame;
            }];
        }
    }
}

#pragma mark - Notifications

- (void)redrawSchedule:(NSNotification*)notification
{
    if(UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone)
        return;
    
    BOOL didSucceed = [notification.userInfo[@"scheduleDidSucceed"] boolValue];
    
    if(notification && !didSucceed)
    {
        // TODO: Show can't load notice.
        return;
    }
    
    if(!self.channel.schedule || self.channel.schedule.days.count == 0)
        return;
    
    Event *currentShow = self.channel.schedule.currentShow;
    Show *show = currentShow.show ?: self.channel.shows.anyObject;
    self.livePosterView.image = show.poster.image ?: show.defaultImage;
    
    [self.scheduleTable reloadData];
    
    NSTimeInterval updateDelay = 60;
    
    if(currentShow.start.isAfterNow)    // Starts soon
    {
        NSInteger interval = currentShow.start.timeIntervalSinceNow;
        
        if(interval > 5*60*60)          // More than 5 hours away
            updateDelay = interval;
        else if(interval > 10*60)       // 5 hours to 10 minutes away
            updateDelay = 60;
        else                            // 10 minutes away, Pre-show
            updateDelay = interval;
    }
    else if(currentShow.end.isAfterNow) // Live
    {
        Event *nextShow = [self.channel.schedule showAfterShow:currentShow];
        updateDelay = nextShow.end.timeIntervalSinceNow;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(redrawSchedule:) object:nil];
    [self performSelector:@selector(redrawSchedule:) withObject:nil afterDelay:updateDelay];
}

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

#pragma mark - Table Delegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    CGFloat headerHeight = self.tableView.tableHeaderView.frame.size.height;
    
    if(self.headerView && scrollView == self.tableView)
    {
        CGRect frame = self.headerView.frame;
        CGFloat sectionHeaderHeight = (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 28 : 0;
        
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
        
        UIEdgeInsets scrollerInsets = self.tableView.scrollIndicatorInsets;
        scrollerInsets.top = frame.size.height + sectionHeaderHeight + NAVBAR_INSET;
        self.tableView.scrollIndicatorInsets = scrollerInsets;
    }
}

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
            UINavigationController *modalController = (UINavigationController*)self.splitViewContainer.modalController;
            TWEpisodeViewController *episodeController = (TWEpisodeViewController*)modalController.topViewController;
            Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
            
            if(!episode.published)
            {
                [episode.show updateEpisodes];
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                
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

#pragma mark - Table Data

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    if(tableView == self.tableView)
    {
        return self.fetchedEpisodesController.sections.count;
    }
    else if(tableView == self.scheduleTable)
    {
        return self.channel.schedule.days.count;
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.tableView)
    {
        id <NSFetchedResultsSectionInfo>sectionInfo;
        
        [[self.tableView viewWithTag:98] removeFromSuperview];
        
        sectionInfo = self.fetchedEpisodesController.sections[section];
        
        if(sectionInfo.numberOfObjects == 0)
        {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            
            UIImageView *emptyView = [[UIImageView alloc] init];
            emptyView.image = [UIImage imageNamed:@"episodes-table-empty.png"];
            emptyView.contentMode = UIViewContentModeScaleAspectFit;
            emptyView.frame = CGRectMake(0, 0, 320, 88);
            emptyView.center = self.tableView.center;
            
            CGPoint center = emptyView.center;
            emptyView.center = center;
            
            emptyView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin);
            emptyView.tag = 98;
            [self.tableView addSubview:emptyView];
        }
        else
        {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        }
        
        return sectionInfo.numberOfObjects;
    }
    else if(tableView == self.scheduleTable)
    {
        return [self.channel.schedule.days[section] count];
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(self.channel.schedule.days.count <= section)
        return 0;
    
    if([self.channel.schedule.days[section] count] == 0)
        return 0;
    
    return (tableView == self.scheduleTable && section != 0)? 20 : 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView == self.tableView)
    {
        return 65;
    }
    else if(tableView == self.scheduleTable)
    {
        Event *showEvent = self.channel.schedule.days[indexPath.section][indexPath.row];
        
        if(indexPath.section == 0 && showEvent.end.isBeforeNow)
            return 0;
        
        return 20;
    }
    
    return 0;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    if(tableView == self.scheduleTable)
    {
        if(self.channel.schedule.days.count <= section)
            return nil;
        
        if([self.channel.schedule.days[section] count] == 0)
            return nil;
        
        CGFloat width = tableView.frame.size.width;

        Event *showEvent = self.channel.schedule.days[section][0];
     
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(112, 0, width-112, 20)];
        
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.font = [UIFont systemFontOfSize:12];
        
        if(showEvent.start.isTomorrow)
            headerLabel.text = @"Tomorrow";
        else if(showEvent.start.isToday)
            headerLabel.text = @"Today";
        else
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"EEEE"];
            headerLabel.text = [dateFormatter stringFromDate:showEvent.start];
        }
        
        [header addSubview:headerLabel];
        return header;
    }
    
    UIView *header = [[UIView alloc] init];
    return header;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView != self.tableView)
        return NO;
    
    if([indexPath isEqual:[tableView indexPathForSelectedRow]])
        return NO;
    
    Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
    return episode.downloadedEnclosures;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView != self.tableView)
        return;
    
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        
        if(!episode.watched)
            episode.watched = YES;
        
        [episode deleteDownloads];
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView == self.tableView)
    {
        NSString *identifier = @"episodeCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        [self configureCell:cell atIndexPath:indexPath];
        
        return cell;
    }
    else if(tableView == self.scheduleTable)
    {
        NSString *identifier = @"scheduleCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        Event *showEvent = self.channel.schedule.days[indexPath.section][indexPath.row];
        
        if(indexPath.section == 0)
        {
            if(showEvent.end.isBeforeNow)
            {
                cell.textLabel.text = @"Ended";
            }
            else
            {
                if(indexPath.row == 0)
                {
                    cell.textLabel.text = showEvent.until;
                }
                else
                {
                    Event *prevEvent = self.channel.schedule.days[indexPath.section][indexPath.row-1];
                    
                    if(prevEvent.end.isBeforeNow)
                        cell.textLabel.text = showEvent.until;
                    else
                        cell.textLabel.text = showEvent.time;
                }
            }
        }
        else
        {
            cell.textLabel.text = showEvent.time;
        }
        
        cell.detailTextLabel.text = showEvent.title;
        
        return cell;
    }
    
    return nil;
}

#pragma mark - Configure

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
    
    if(!episode.downloadedEnclosures)
    {
        UIPanGestureRecognizer *swipeRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipeEpisode:)];
        swipeRecognizer.delegate = self;
        swipeRecognizer.observationInfo = (__bridge void *)(cell);
        [cell.contentView addGestureRecognizer:swipeRecognizer];
    }
    
    TWEpisodeCell *episodeCell = (TWEpisodeCell*)cell;
    episodeCell.delegate = self;
    episodeCell.table = self.tableView;
    episodeCell.indexPath = indexPath;
    episodeCell.episode = episode;
    self.accessibilityLabel = [NSString stringWithFormat:@"%@ episode %d, %@, with %@.", episode.show.title, episode.number, episode.title, episode.guests];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController*)fetchedEpisodesController
{
    if(_fetchedEpisodesController != nil)
        return _fetchedEpisodesController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"watched == NO OR ANY enclosures.path != nil"];
    
    //?  AND published != nil
    //?  OR ANY enclosures.downloadTask != nil
    
    [fetchRequest setFetchBatchSize:10];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    [fetchRequest setPredicate:predicate];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.managedObjectContext
                                                                                   sectionNameKeyPath:nil cacheName:nil];
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
    if(controller == self.fetchedEpisodesController)
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
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationTop];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationTop];
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
    if(controller == self.fetchedEpisodesController)
    {
        UITableView *tableView = self.tableView;
        
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
                break;
                
            case NSFetchedResultsChangeDelete:
                if([indexPath isEqual:self.tableView.indexPathForSelectedRow])
                    [self.splitViewContainer hideModalFlyout];
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                
                break;
                
            case NSFetchedResultsChangeUpdate:
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    if(controller == self.fetchedEpisodesController)
    {
        [self.tableView endUpdates];
    }
}

#pragma mark - Settings

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString*)identifier sender:(id)sender
{
    if([identifier isEqualToString:@"episodeDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        
        if(!episode.published)
        {
            [episode.show updateEpisodes];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            
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
    else if([segue.identifier isEqualToString:@"showsDetail"])
    {
        TWShowsViewController *showsController = segue.destinationViewController;
        showsController.managedObjectContext = self.managedObjectContext;
        showsController.channel = self.channel;
    }
    else if([segue.identifier isEqualToString:@"showDetail"])
    {
        if([sender isKindOfClass:Show.class])
        {
            Show *show = (Show*)sender;
            [show updateEpisodes];
            
            if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
                [segue.destinationViewController setSplitViewContainer:self.splitViewContainer];
            
            [segue.destinationViewController setShow:show];
        }
        else
        {
            TWEpisodeCell *episodeCell = (TWEpisodeCell*)[[[[[sender superview] superview] superview] superview] superview];
            Episode *episode = episodeCell.episode;
            Show *show = episode.show;
            [show updateEpisodes];
            
            if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
                [segue.destinationViewController setSplitViewContainer:self.splitViewContainer];
            
            [segue.destinationViewController setShow:show];
        }
    }
    else if([segue.identifier isEqualToString:@"scheduleView"])
    {
        [segue.destinationViewController setSchedule:self.channel.schedule];
    }
    else if([segue.identifier isEqualToString:@"playerDetail"])
    {
        TWEpisodeCell *episodeCell = (TWEpisodeCell*)[[[[[sender superview] superview] superview] superview] superview];
        Episode *episode = episodeCell.episode;
        NSSet *enclosures = [episode downloadedEnclosures];
        Enclosure *enclosure = enclosures.anyObject ?: [episode enclosureForType:TWTypeVideo andQuality:TWQualityHigh];
        enclosure = enclosure ?: [episode enclosureForType:TWTypeAudio andQuality:TWQualityAudio];
        
        [segue.destinationViewController setEnclosure:enclosure];
    }
    else if([segue.identifier isEqualToString:@"liveAudioDetail"])
    {
        [segue.destinationViewController setStream:[self.channel streamForType:TWTypeAudio]];
    }
    else if([segue.identifier isEqualToString:@"liveVideoDetail"])
    {
        [segue.destinationViewController setStream:[self.channel streamForType:TWTypeVideo]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidReceiveData" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFinish" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFail" object:nil];
    
    [super viewWillDisappear:animated];
}

@end
