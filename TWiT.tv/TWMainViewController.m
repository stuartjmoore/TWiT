//
//  TWMainViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NSDate+comparisons.h"

#import "TWSplitViewContainer.h"
#import "TWMainViewController.h"

#import "TWShowViewController.h"
#import "TWEpisodeViewController.h"
#import "TWEpisodeCell.h"
#import "TWPlayButton.h"

#import "TWScheduleViewController.h"
#import "TWScheduleGridViewController.h"

#import "Schedule.h"
#import "Channel.h"
#import "Show.h"
#import "AlbumArt.h"
#import "Feed.h"
#import "Episode.h"
#import "Enclosure.h"

@interface TWMainViewController ()
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
@end

@implementation TWMainViewController

- (void)awakeFromNib
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        // TODO: Save state?
        self.sectionVisible = TWSectionEpisodes;
    }
    
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(reloadSchedule:)
                                               name:@"ScheduleDidUpdate"
                                             object:nil];
    
    [self.tableView addObserver:self forKeyPath:@"contentOffset"
                        options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                        context:NULL];
    
    UIImage *leftOrangeBackground = [self.watchButton backgroundImageForState:UIControlStateNormal];
    leftOrangeBackground = [leftOrangeBackground stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    [self.watchButton setBackgroundImage:leftOrangeBackground forState:UIControlStateNormal];
    
    UIImage *rightOrangeBackground = [self.listenButton backgroundImageForState:UIControlStateNormal];
    rightOrangeBackground = [rightOrangeBackground stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    [self.listenButton setBackgroundImage:rightOrangeBackground forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
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

- (void)viewDidAppear:(BOOL)animated
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.sectionVisible == TWSectionShows)
        [self.tableView reloadData];
    
    [super viewDidAppear:animated];
}

#pragma mark - Actions

- (void)switchVisibleSection:(UIButton*)sender
{
    self.sectionVisible = sender.tag;
    
    if(self.sectionVisible == TWSectionEpisodes)
    {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
        footer.backgroundColor = [UIColor whiteColor];
        self.tableView.tableFooterView = footer;
    }
    else
    {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 9)];
        footer.backgroundColor = [UIColor clearColor];
        self.tableView.tableFooterView = footer;
    }
    
    [self.tableView reloadData];
}

- (NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if([tableView.indexPathForSelectedRow isEqual:indexPath])
        {
            TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.navigationController.parentViewController;
            
            CGRect frame = splitViewContainer.modalFlyout.frame;
            frame.origin.x -= frame.size.width;
            
            [UIView animateWithDuration:0.3f animations:^{
                splitViewContainer.modalFlyout.frame = frame;
                splitViewContainer.modalBlackground.alpha = 0;
            } completion:^(BOOL fin){
                splitViewContainer.modalContainer.hidden = YES;
                splitViewContainer.modalBlackground.alpha = 1;
            }];
            
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        else
        {
            TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.navigationController.parentViewController;
            UINavigationController *modalController = (UINavigationController*)splitViewContainer.modalController;
            TWEpisodeViewController *episodeController = (TWEpisodeViewController*)modalController.topViewController;
            
            Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
            episodeController.episode = episode;
            
            if(splitViewContainer.modalContainer.hidden)
            {
                splitViewContainer.modalBlackground.alpha = 0;
                splitViewContainer.modalContainer.hidden = NO;
                
                CGRect frame = splitViewContainer.modalFlyout.frame;
                frame.origin.x += frame.size.width;
                
                [UIView animateWithDuration:0.3f animations:^{
                    splitViewContainer.modalBlackground.alpha = 1;
                    splitViewContainer.modalFlyout.frame = frame;
                }];
            }
            
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        return nil;
    }
    
    return indexPath;
}

- (void)tableView:(UITableView*)tableView didSelectColumn:(int)column AtIndexPath:(NSIndexPath*)indexPath
{
    TWShowsCell *showCell = (TWShowsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    int index = indexPath.row*showCell.columns + column;
    NSIndexPath *showIndexPath = [NSIndexPath indexPathForRow:index inSection:indexPath.section];
 
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self performSegueWithIdentifier:@"showDetail" sender:showIndexPath];
    }
    else
    {
        TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.view.window.rootViewController;
        UINavigationController *masterController = (UINavigationController*)splitViewContainer.masterController;
        
        if(masterController.viewControllers.count > 1)
        {
            TWShowViewController *showController = (TWShowViewController*)masterController.topViewController;
            Show *currentShow = showController.show;
            Show *selectedShow = [self.fetchedShowsController objectAtIndexPath:showIndexPath];
            
            if(currentShow == selectedShow)
                [masterController popToRootViewControllerAnimated:YES];
            else
            {
                [selectedShow updateEpisodes];
                showController.show = selectedShow;
            }
        }
        else
        {
            TWMainViewController *episodesController = (TWMainViewController*)masterController.topViewController;
            [episodesController performSegueWithIdentifier:@"showDetail" sender:showIndexPath];
        }
    }
}

#pragma mark - Notifications

- (void)reloadSchedule:(NSNotification*)notification
{
    if(self.channel.schedule != notification.object)
        return;
    
    Event *currentShow = self.channel.schedule.currentShow;
    self.liveTimeLabel.text = currentShow.until;
    self.liveTitleLabel.text = currentShow.title;
    
    Show *show = currentShow.show ?: self.channel.shows.anyObject;
    self.livePosterView.image = show.poster.image;
    self.liveAlbumArtView.image = show.albumArt.image;
    
    if(currentShow.start.isBeforeNow && currentShow.end.isAfterNow)
    {
        NSTimeInterval secondsElasped = currentShow.start.timeIntervalSinceNow;
        NSTimeInterval secondsDuration = [currentShow.start timeIntervalSinceDate:currentShow.end];
        self.playButton.percentage = (secondsDuration != 0) ? secondsElasped/secondsDuration : 0;
    }
    
    [self.scheduleTable reloadData];
}

- (void)updateProgress:(NSNotification*)notification
{
    if(self.sectionVisible != TWSectionEpisodes)
        return;
    
    Enclosure *enclosure = notification.object;
    Episode *episode = enclosure.episode;
    NSIndexPath *indexPath = [self.fetchedEpisodesController indexPathForObject:episode];
    TWEpisodeCell *cell = (TWEpisodeCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if([notification.name isEqualToString:@"enclosureDownloadDidReceiveData"])
        cell.progress = (enclosure.expectedLength != 0)? enclosure.downloadedLength/(float)enclosure.expectedLength : 0;
    else if([notification.name isEqualToString:@"enclosureDownloadDidFinish"]
    || [notification.name isEqualToString:@"enclosureDownloadDidFail"])
        cell.progress = 1;
}

#pragma mark - Table View

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    CGPoint newPoint = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
    float headerHeight = self.tableView.tableHeaderView.frame.size.height;
    
    if(self.headerView && object == self.tableView)
    {
        CGRect frame = self.headerView.frame;
        float sectionHeaderHeight = (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 28 : 0;
        
        if(newPoint.y < 0)
        {
            frame.origin.y = newPoint.y;
            frame.size.height = ceilf(headerHeight-newPoint.y+sectionHeaderHeight);
        }
        else
        {
            frame.origin.y = 0;
            frame.size.height = headerHeight+sectionHeaderHeight;
        }
        
        if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            float offest = self.tableView.contentOffset.y-headerHeight;
            self.sectionHeader.layer.shadowOpacity = offest < 0 ? 0 : offest/20;
        }
        
        self.headerView.frame = frame;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(frame.size.height, 0, 0, 1);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    if(tableView == self.tableView)
    {
        if(self.sectionVisible == TWSectionEpisodes)
            return self.fetchedEpisodesController.sections.count;
        else if(self.sectionVisible == TWSectionShows)
            return self.fetchedShowsController.sections.count;
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
        
        if(self.sectionVisible == TWSectionEpisodes)
        {
            sectionInfo = self.fetchedEpisodesController.sections[section];
            
            return sectionInfo.numberOfObjects;
        }
        else if(self.sectionVisible == TWSectionShows)
        {
            sectionInfo = self.fetchedShowsController.sections[section];
            int num = sectionInfo.numberOfObjects;
            int columns = 3;

            if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
                columns = (self.tableView.frame.size.width <= 448) ? 3 : 4;
            
            return ceil(num/columns);
        }
    }
    else if(tableView == self.scheduleTable)
    {
        return [self.channel.schedule.days[section] count];
    }
    
    return 0;
}

- (float)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(tableView == self.tableView && section == 0 && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        return (self.sectionVisible == TWSectionShows) ? 28 : 28;
    }
    if(tableView == self.tableView && section == 0 && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        return (self.sectionVisible == TWSectionShows) ? 16 : 0;
    }
    else if(tableView == self.scheduleTable)
    {
        Event *firstShow = self.channel.schedule.days[section][0];
        
        if(firstShow.start.isToday)
            return 0;
        
        return 20;
    }
    
    return 0;
}

- (float)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView == self.tableView)
    {
        if(self.sectionVisible == TWSectionEpisodes)
            return 62;
        else if(self.sectionVisible == TWSectionShows)
        {
            if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
                return 150;
            else
                return 102;
        }
    }
    else if(tableView == self.scheduleTable)
    {
        if(indexPath.section == 0 && indexPath.row == 0)
            return 0;
        
        Event *showEvent = self.channel.schedule.days[indexPath.section][indexPath.row];
        
        if(showEvent.start.isBeforeNow)
            return 0;
        
        if(indexPath.row == 0)
            return 20;
        
        Event *reviousShowEvent = self.channel.schedule.days[indexPath.section][indexPath.row];
            
        if(reviousShowEvent.start.isBeforeNow)
            return 0;
        
        return 20;
    }
    
    return 0;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    float width = tableView.frame.size.width;
    
    if(tableView == self.tableView && section == 0 && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        self.sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 28)];
        self.sectionHeader.backgroundColor = [UIColor colorWithWhite:244/255.0 alpha:1];
        
        UIImage *buttonUpBackground = [[UIImage imageNamed:@"main-header-button-up.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:11];
        UIImage *buttonDownBackground = [[UIImage imageNamed:@"main-header-button.png"] stretchableImageWithLeftCapWidth:4 topCapHeight:11];
        
        UIButton *episodesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        episodesButton.frame = CGRectMake(1, 2, 158, 24);
        [episodesButton setTitle:@"EPISODES" forState:UIControlStateNormal];
        episodesButton.tag = TWSectionEpisodes;
        episodesButton.selected = (self.sectionVisible == episodesButton.tag);
        [episodesButton addTarget:self action:@selector(switchVisibleSection:) forControlEvents:UIControlEventTouchUpInside];
        [episodesButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.25f] forState:UIControlStateSelected];
        [episodesButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.25f] forState:UIControlStateNormal];
        [episodesButton setBackgroundImage:buttonDownBackground forState:UIControlStateHighlighted];
        [episodesButton setBackgroundImage:buttonDownBackground forState:UIControlStateSelected];
        [episodesButton setBackgroundImage:buttonUpBackground forState:UIControlStateNormal];
        episodesButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
        [episodesButton setTitleColor:[UIColor colorWithWhite:132/255.0 alpha:1] forState:UIControlStateNormal];
        [episodesButton setTitleColor:[UIColor colorWithWhite:244/255.0 alpha:1] forState:UIControlStateSelected];
        [episodesButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [self.sectionHeader addSubview:episodesButton];
        
        UIButton *showsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        showsButton.frame = CGRectMake(161, 2, 158, 24);
        [showsButton setTitle:@"SHOWS" forState:UIControlStateNormal];
        showsButton.tag = TWSectionShows;
        showsButton.selected = (self.sectionVisible == showsButton.tag);
        [showsButton addTarget:self action:@selector(switchVisibleSection:) forControlEvents:UIControlEventTouchUpInside];
        [showsButton setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.25f] forState:UIControlStateNormal];
        [showsButton setBackgroundImage:buttonDownBackground forState:UIControlStateHighlighted];
        [showsButton setBackgroundImage:buttonDownBackground forState:UIControlStateSelected];
        [showsButton setBackgroundImage:buttonUpBackground forState:UIControlStateNormal];
        showsButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
        [showsButton setTitleColor:[UIColor colorWithWhite:132/255.0 alpha:1] forState:UIControlStateNormal];
        [showsButton setTitleColor:[UIColor colorWithWhite:244/255.0 alpha:1] forState:UIControlStateSelected];
        [showsButton setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.25f] forState:UIControlStateSelected];
        [showsButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [self.sectionHeader addSubview:showsButton];
        
        UILabel *topLine = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 1)];
        topLine.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        [self.sectionHeader addSubview:topLine];
        
        UILabel *botLine = [[UILabel alloc] initWithFrame:CGRectMake(0, 27, 320, 1)];
        botLine.backgroundColor = [UIColor colorWithWhite:222/255.0 alpha:1];
        [self.sectionHeader addSubview:botLine];
        
        float headerHeight = self.tableView.tableHeaderView.frame.size.height;
        float offest = self.tableView.contentOffset.y-headerHeight;
        self.sectionHeader.layer.shadowOpacity = offest < 0 ? 0 : offest/20;
        self.sectionHeader.layer.shadowColor = [[UIColor colorWithWhite:0 alpha:0.5f] CGColor];
        self.sectionHeader.layer.shadowOffset = CGSizeMake(0, 3);
        self.sectionHeader.layer.shadowRadius = 3;
        
        return self.sectionHeader;
    }
    else if(tableView == self.scheduleTable)
    {
        Event *showEvent = self.channel.schedule.days[section][0];
        
        if(showEvent.start.isToday)
            return nil;
            
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(107, 0, width-107, 20)];
       
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.font = [UIFont systemFontOfSize:12];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEEE"];
        headerLabel.text = [dateFormatter stringFromDate:showEvent.start];
        
        if(showEvent.start.isTomorrow)
            headerLabel.text = @"Tomorrow";
        
        [header addSubview:headerLabel];
        return header;
    }
    
    UIView *header = [[UIView alloc] init];
    return header;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView == self.tableView)
    {
        NSString *identifier = (self.sectionVisible == TWSectionEpisodes) ? @"episodeCell" : @"showsCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

        [self configureCell:cell atIndexPath:indexPath];
        
        return cell;
    }
    else if(tableView == self.scheduleTable)
    {
        NSString *identifier = @"scheduleCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        Event *showEvent = self.channel.schedule.days[indexPath.section][indexPath.row];
        
        cell.textLabel.text = showEvent.time;
        cell.detailTextLabel.text = showEvent.title;
        
        return cell;
    }
    
    return nil;
}

#pragma mark - Configure

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if([cell.reuseIdentifier isEqualToString:@"episodeCell"])
    {
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        TWEpisodeCell *episodeCell = (TWEpisodeCell*)cell;
        episodeCell.episode = episode;
    }
    else if([cell.reuseIdentifier isEqualToString:@"showsCell"])
    {
        TWShowsCell *showsCell = (TWShowsCell*)cell;
        showsCell.delegate = self;
        showsCell.table = self.tableView;
        showsCell.indexPath = indexPath;
        
        // TODO: CACHE THIS MUCHERFUCKER
        
        if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            if(self.tableView.frame.size.width <= 448)
            {
                showsCell.spacing = 26;
                showsCell.size = 114;
                showsCell.columns = 3;
            }
            else
            {
                showsCell.spacing = 48;
                showsCell.size = 114;
                showsCell.columns = 4;
            }
        }
        else
        {
            showsCell.spacing = 14;
            showsCell.size = 88;
            showsCell.columns = 3;
        }
        
        id <NSFetchedResultsSectionInfo>sectionInfo = self.fetchedShowsController.sections[indexPath.section];
        int num = sectionInfo.numberOfObjects;
        int columns = showsCell.columns;
        
        NSMutableArray *shows = [NSMutableArray array];
        for(int column = 0; column < columns; column++)
        {
            int index = indexPath.row*columns + column;
            if(num > index)
            {
                NSIndexPath *columnedIndexPath = [NSIndexPath indexPathForRow:index inSection:indexPath.section];
                Show *show = [self.fetchedShowsController objectAtIndexPath:columnedIndexPath];
                [shows addObject:show];
            }
        }
        [showsCell setShows:shows];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController*)fetchedEpisodesController
{
    if(_fetchedEpisodesController != nil)
        return _fetchedEpisodesController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"watched = NO"];
    
    [fetchRequest setFetchBatchSize:10];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    [fetchRequest setPredicate:predicate];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.managedObjectContext
                                                                                   sectionNameKeyPath:nil cacheName:@"UnwatchedEpisode"];
    controller.delegate = self;
    self.fetchedEpisodesController = controller;
    
	NSError *error = nil;
	if(![self.fetchedEpisodesController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedEpisodesController;
}
- (NSFetchedResultsController*)fetchedShowsController
{
    if(_fetchedShowsController != nil)
        return _fetchedShowsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sort" ascending:YES];
    
    [fetchRequest setFetchBatchSize:15];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.managedObjectContext
                                                                                   sectionNameKeyPath:nil cacheName:@"Shows"];
    controller.delegate = self;
    self.fetchedShowsController = controller;
    
	NSError *error = nil;
	if(![self.fetchedShowsController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedShowsController;
}


- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    if(controller == self.fetchedEpisodesController && self.sectionVisible == TWSectionEpisodes)
        [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if(controller == self.fetchedEpisodesController && self.sectionVisible == TWSectionEpisodes)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
    if(controller == self.fetchedEpisodesController && self.sectionVisible == TWSectionEpisodes)
    {
        UITableView *tableView = self.tableView;
        
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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
    if(controller == self.fetchedEpisodesController && self.sectionVisible == TWSectionEpisodes)
        [self.tableView endUpdates];
    else
        [self.tableView reloadData];
}

#pragma mark - Rotate

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationMaskPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Leave

- (IBAction)transitionToSchedule:(UIButton*)sender
{
    TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.navigationController.parentViewController;
    TWScheduleGridViewController *scheduleController = [self.storyboard instantiateViewControllerWithIdentifier:@"scheduleController"];
    
    [splitViewContainer presentViewController:scheduleController animated:YES completion:^{}];
}

- (IBAction)transitionToPlayer:(UIButton*)sender
{
    TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.navigationController.parentViewController;
    UIViewController *playerController = [self.storyboard instantiateViewControllerWithIdentifier:@"playerController"];
    
    playerController.view.frame = splitViewContainer.view.bounds;
    [splitViewContainer.view addSubview:playerController.view];
    [splitViewContainer.view sendSubviewToBack:playerController.view];
    
    CGRect masterFrameOriginal = splitViewContainer.masterContainer.frame;
    CGRect masterFrameAnimate = masterFrameOriginal;
    masterFrameAnimate.origin.x -= masterFrameAnimate.size.width;
    
    CGRect detailFrameOriginal = splitViewContainer.detailContainer.frame;
    CGRect detailFrameAnimate = detailFrameOriginal;
    detailFrameAnimate.origin.x += detailFrameAnimate.size.width;
    
    [UIView animateWithDuration:0.3f animations:^{
        splitViewContainer.masterContainer.frame = masterFrameAnimate;
        splitViewContainer.detailContainer.frame = detailFrameAnimate;
    } completion:^(BOOL fin){
        [playerController.view removeFromSuperview];
        [splitViewContainer presentViewController:playerController animated:NO completion:^{}];
        splitViewContainer.masterContainer.frame = masterFrameOriginal;
        splitViewContainer.detailContainer.frame = detailFrameOriginal;
        [(UINavigationController*)splitViewContainer.masterController popToRootViewControllerAnimated:NO];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"episodeDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        
        [segue.destinationViewController setEpisode:episode];
    }
    else if([segue.identifier isEqualToString:@"showDetail"])
    {
        NSIndexPath *indexPath = (NSIndexPath*)sender;
        Show *show = [self.fetchedShowsController objectAtIndexPath:indexPath];
        [show updateEpisodes];
        
        [segue.destinationViewController setShow:show];
    }
    else if([segue.identifier isEqualToString:@"scheduleView"])
    {
        [segue.destinationViewController setSchedule:self.channel.schedule];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidReceiveData" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFinish" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFail" object:nil];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    self.fetchedShowsController = nil;
    self.fetchedEpisodesController = nil;
    
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"ScheduleDidUpdate" object:nil];
    
    [super viewDidUnload];
}

@end
