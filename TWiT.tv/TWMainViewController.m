//
//  TWMainViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NSDate+comparisons.h"

#import "TWMainViewController.h"

#import "TWShowViewController.h"
#import "TWEpisodeViewController.h"
#import "TWEpisodeCell.h"

#import "TWScheduleViewController.h"

#import "Channel.h"
#import "Show.h"
#import "AlbumArt.h"
#import "Feed.h"
#import "Episode.h"

@interface TWMainViewController ()
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
@end

@implementation TWMainViewController

- (void)awakeFromNib
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        self.clearsSelectionOnViewWillAppear = NO;
        
        if(self == [self.splitViewController.viewControllers[0] topViewController])
            sectionVisible = TWSectionEpisodes;
        else
            sectionVisible = TWSectionShows;
    }
    else
    {
        // TODO: Save state?
        sectionVisible = TWSectionEpisodes;
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
    
    [self.tableView addObserver:self forKeyPath:@"contentOffset"
                        options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                        context:NULL];
}

#pragma mark - Actions

- (void)switchVisibleSection:(UIButton*)sender
{
    sectionVisible = sender.tag;
    [self.tableView reloadData];
}

- (IBAction)loadLiveDetail:(UIButton*)sender
{
    if(self.episodeViewController && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    
        UINavigationController *detailNavigationController = self.splitViewController.viewControllers[1];
        [detailNavigationController popViewControllerAnimated:YES];
        
        self.episodeViewController = nil;
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(!self.episodeViewController && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        UINavigationController *detailNavigationController = self.splitViewController.viewControllers[1];
        TWMainViewController *showsViewController = (TWMainViewController*)detailNavigationController.topViewController;
        [showsViewController performSegueWithIdentifier:@"episodeDetail" sender:nil];
        
        Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        self.episodeViewController = detailNavigationController.viewControllers.lastObject;
        self.episodeViewController.episode = episode;
    }
}

- (void)tableView:(UITableView*)tableView didSelectColumn:(int)column AtIndexPath:(NSIndexPath*)indexPath
{
    TWShowsCell *showCell = (TWShowsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    int index = indexPath.row*showCell.columns + column;
    NSIndexPath *showIndexPath = [NSIndexPath indexPathForRow:index inSection:indexPath.section];
    Show *show = [self.fetchedShowsController objectAtIndexPath:showIndexPath];
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        NSLog(@"%@", show);
    }
    else
    {
        [self performSegueWithIdentifier:@"showDetail" sender:show];
    }
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
        [segue.destinationViewController setShow:sender];
    }
    else if([segue.identifier isEqualToString:@"scheduleView"])
    {
        [segue.destinationViewController setSchedule:self.channel.schedule];
    }
}

#pragma mark - Table View

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    
    CGPoint newPoint = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
    float height = 0;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        height = mainHeaderHeight;
    }
    else
    {
        if(sectionVisible == TWSectionEpisodes)
            height = mainHeaderHeight_iPad;
        else
            height = mainHeaderHeight_iPad_shows;
    }
    
    if(object == self.tableView)
    {
        if(newPoint.y < 0)
        {
            CGRect frame = self.headerView.frame;
            frame.origin.y = newPoint.y;
            frame.size.height = ceilf(height-newPoint.y);
            self.headerView.frame = frame;
            
            float sectionHeaderHeight = [self.tableView.delegate tableView:self.tableView heightForHeaderInSection:0];
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(frame.size.height+sectionHeaderHeight, 0, 0, 0);
            self.sectionHeader.layer.shadowOpacity = 0;
        }
        else
        {
            CGRect frame = self.headerView.frame;
            frame.origin.y = 0;
            frame.size.height = height;
            self.headerView.frame = frame;
            
            float sectionHeaderHeight = [self.tableView.delegate tableView:self.tableView heightForHeaderInSection:0];
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(height+sectionHeaderHeight, 0, 0, 0);
            self.sectionHeader.layer.shadowOpacity = newPoint.y-height < 0 ? 0 : (newPoint.y-height)/20;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    if(tableView == self.tableView)
    {
        if(sectionVisible == TWSectionEpisodes)
            return self.fetchedEpisodesController.sections.count;
        else if(sectionVisible == TWSectionShows)
            return self.fetchedShowsController.sections.count;
    }
    else if(tableView == self.scheduleTable)
    {
        if(self.channel.schedule.count == 0)
            return 0;
        
        NSArray *today = self.channel.schedule[0];
        int count = self.channel.schedule.count;
        
        for(NSDictionary *show in today)
        {
            NSDate *startDate = show[@"startDate"];
            NSDate *endDate = show[@"endDate"];
            
            if(startDate.isBeforeNow && endDate.isAfterNow)
            {
                if(today.lastObject == show)
                    count--;
                break;
            }
            else if(startDate.isAfterNow && endDate.isAfterNow)
            {
                if(today.lastObject == show)
                    count--;
                break;
            }
        }
        return count;
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.tableView)
    {
        id <NSFetchedResultsSectionInfo>sectionInfo;
        
        if(sectionVisible == TWSectionEpisodes)
        {
            sectionInfo = self.fetchedEpisodesController.sections[section];
            
            return sectionInfo.numberOfObjects;
        }
        else if(sectionVisible == TWSectionShows)
        {
            sectionInfo = self.fetchedShowsController.sections[section];
            int num = sectionInfo.numberOfObjects;
            
            return ceil(num/3.0);
        }
    }
    else if(tableView == self.scheduleTable)
    {
        return [self.channel.schedule[section] count];
    }
    
    return 0;
}

- (float)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(tableView == self.tableView && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if(section == 0)
            return 28;
    }
    else if(tableView == self.scheduleTable)
    {
        NSDate *startTime = self.channel.schedule[section][0][@"startDate"];
        
        if(startTime.isToday)
            return 0;
        return 20;
    }
    
    return 0;
}

- (float)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView == self.tableView)
    {
        if(sectionVisible == TWSectionEpisodes)
            return 62;
        else if(sectionVisible == TWSectionShows)
        {
            if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
                return 150;
            else
                return 102;
        }
    }
    else if(tableView == self.scheduleTable)
    {
        NSDate *startTime = self.channel.schedule[indexPath.section][indexPath.row][@"startDate"];
        
        if(startTime.isBeforeNow)
            return 0;
        
        if(indexPath.row == 0)
            return 0;
        
        NSDate *previousStartTime = self.channel.schedule[indexPath.section][indexPath.row-1][@"startDate"];
        
        if(previousStartTime.isBeforeNow)
            return 0;
        
        return 20;
    }
    
    return 0;
}

// TODO: Add white line to top of shows section, bottom of episodes section

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
        episodesButton.selected = (sectionVisible == episodesButton.tag);
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
        showsButton.selected = (sectionVisible == showsButton.tag);
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
        
        float offest = self.tableView.contentOffset.y-mainHeaderHeight;
        self.sectionHeader.layer.shadowOpacity = offest < 0 ? 0 : offest/20;
        self.sectionHeader.layer.shadowColor = [[UIColor colorWithWhite:0 alpha:0.5f] CGColor];
        self.sectionHeader.layer.shadowOffset = CGSizeMake(0, 3);
        self.sectionHeader.layer.shadowRadius = 3;
        
        return self.sectionHeader;
    }
    else if(tableView == self.scheduleTable)
    {
        NSDate *startTime = self.channel.schedule[section][0][@"startDate"];
        
        if(startTime.isToday)
            return nil;
            
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(107, 0, width-107, 20)];
       
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.font = [UIFont systemFontOfSize:12];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEEE"];
        headerLabel.text = [dateFormatter stringFromDate:startTime];
        
        if(startTime.isTomorrow)
            headerLabel.text = @"Tomorrow";
        
        [header addSubview:headerLabel];
        return header;
    }
    
    return nil;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView == self.tableView)
    {
        NSString *identifier = (sectionVisible == TWSectionEpisodes) ? @"episodeCell" : @"showsCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

        [self configureCell:cell atIndexPath:indexPath];
        
        return cell;
    }
    else if(tableView == self.scheduleTable)
    {
        NSString *identifier = @"scheduleCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        NSDictionary *show = self.channel.schedule[indexPath.section][indexPath.row];
        NSInteger interval = [show[@"startDate"] timeIntervalSinceNow];
        
        if(interval > 5*60*60) // More than 5 hours away
        {
            NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
            [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
            [dateFormatterLocal setDateFormat:@"h:mm a"];
            cell.textLabel.text = [dateFormatterLocal stringFromDate:show[@"startDate"]];
        }
        else if(interval > 10*60) // 5 hours away
        {
            NSInteger minutes = (interval / 60) % 60;
            NSInteger hours = (interval / 3600);
            cell.textLabel.text = [NSString stringWithFormat:@"%ih %02im", hours, minutes];
        }

        cell.detailTextLabel.text = show[@"title"];
        
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

        episodeCell.albumArt.image = episode.show.albumArt.image;
        episodeCell.titleLabel.text = episode.title;
        episodeCell.subtitleLabel.text = episode.show.title;
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
            showsCell.spacing = 26;
            showsCell.size = 114;
            showsCell.columns = 3;
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

- (void)reloadSchedule:(NSNotification*)notification
{
    NSArray *schedule = notification.object;
    
    BOOL tryTomorrow = YES;
    int i = 0;
    do
    {
        NSArray *today = schedule[i];
        for(NSDictionary *show in today)
        {
            NSDate *startDate = show[@"startDate"];
            NSDate *endDate = show[@"endDate"];
            
            if(startDate.isBeforeNow && endDate.isAfterNow)
            {
                self.liveTimeLabel.text = @"LIVE";
                self.liveTitleLabel.text = show[@"title"];
                tryTomorrow = NO;
                break;
            }
            else if(startDate.isAfterNow && endDate.isAfterNow)
            {
                NSInteger interval = startDate.timeIntervalSinceNow;
                
                if(interval > 24*60*60) // More than 24 hours away
                {
                    self.liveTimeLabel.text = @"Tomorrow";
                }
                else if(interval > 5*60*60) // More than 5 hours away
                {
                    NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
                    [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
                    [dateFormatterLocal setDateFormat:@"h:mm a"];
                    self.liveTimeLabel.text = [dateFormatterLocal stringFromDate:startDate];
                }
                else if(interval > 10*60) // 5 hours to 10 minutes away
                {
                    NSInteger minutes = (interval / 60) % 60;
                    NSInteger hours = (interval / 3600);
                    self.liveTimeLabel.text = [NSString stringWithFormat:@"%ih %02im", hours, minutes];
                }
                else // 10 minutes away
                    self.liveTimeLabel.text = @"Pre-show";
                
                self.liveTitleLabel.text = show[@"title"];
                
                tryTomorrow = NO;
                break;
            }
        }
        i++;
    } while(tryTomorrow);

    
    NSPredicate *p = [NSPredicate predicateWithFormat:@"%@ BEGINSWITH title OR %@ BEGINSWITH titleInSchedule",
                      self.liveTitleLabel.text, self.liveTitleLabel.text];
    Show *show = [[self.channel.shows filteredSetUsingPredicate:p] anyObject] ?: self.channel.shows.anyObject;
    self.livePosterView.image = show.poster.image ?: show.albumArt.image;
    self.liveAlbumArtView.image = show.albumArt.image;
    
    [self.scheduleTable reloadData];
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
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"UnwatchedEpisode"];
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
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Shows"];
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
    if(controller == self.fetchedEpisodesController && sectionVisible == TWSectionEpisodes)
        [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if(controller == self.fetchedEpisodesController && sectionVisible == TWSectionEpisodes)
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
    if(controller == self.fetchedEpisodesController && sectionVisible == TWSectionEpisodes)
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
    if(controller == self.fetchedEpisodesController && sectionVisible == TWSectionEpisodes)
        [self.tableView endUpdates];
    else
        [self.tableView reloadData];
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController*)svc shouldHideViewController:(UIViewController*)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}
- (void)splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController*)aViewController invalidatingBarButtonItem:(UIBarButtonItem*)button
{
}

#pragma mark - Kill

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    self.fetchedShowsController = nil;
    self.fetchedEpisodesController = nil;
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"ScheduleDidUpdate" object:nil];
}

@end
