//
//  TWMainViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TWMainViewController.h"

#import "TWShowViewController.h"
#import "TWEpisodeViewController.h"
#import "TWEpisodeCell.h"

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
    /* 
     TODO: iPad

     Don't clear selection, and link to episode container view.
     
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        self.clearsSelectionOnViewWillAppear = NO;
    */
    
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // TODO: Save state?
    sectionVisible = TWSectionEpisodes;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(reloadSchedule:)
                                               name:@"ScheduleDidUpdate"
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView addObserver:self forKeyPath:@"contentOffset"
                        options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                        context:NULL];
}

#pragma mark - Actions

// TODO: Use a smaller disclose icon, unrotate schedule icon

- (IBAction)openScheduleView:(UIButton*)sender
{
    if(self.tableView.contentOffset.y <= -self.view.bounds.size.height+headerHeight)
    {
        self.tableView.scrollEnabled = YES;
        [UIView animateWithDuration:0.3f animations:^
         {
             self.tableView.contentOffset = CGPointMake(0, 0);
             sender.transform = CGAffineTransformMakeRotation(0);
             [sender setImage:[UIImage imageNamed:@"toolbar-schedule-arrow"] forState:UIControlStateNormal];
         }];
    }
    else
    {
        self.tableView.scrollEnabled = NO;
        [UIView animateWithDuration:0.3f animations:^
         {
             self.tableView.contentOffset = CGPointMake(0, -self.view.bounds.size.height+headerHeight);
             sender.transform = CGAffineTransformMakeRotation(M_PI);
             [sender setImage:[UIImage imageNamed:@"toolbar-schedule-arrow-up"] forState:UIControlStateNormal];
         }];
    }
}

- (void)switchVisibleSection:(UIButton*)sender
{
    sectionVisible = sender.tag;
    [self.tableView reloadData];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

- (void)tableView:(UITableView*)tableView didSelectColumn:(int)column AtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary *sender = @{@"indexPath":indexPath, @"column":@(column)};
    [self performSegueWithIdentifier:@"showDetail" sender:sender];
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
        NSIndexPath *rowPath = sender[@"indexPath"];
        TWShowsCell *showCell = (TWShowsCell*)[self.tableView cellForRowAtIndexPath:rowPath];
        int index = rowPath.row*showCell.columns + [sender[@"column"] intValue];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:rowPath.section];
        Show *show = [self.fetchedShowsController objectAtIndexPath:indexPath];
        
        [segue.destinationViewController setShow:show];
    }
}

#pragma mark - Table View

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    
    CGPoint newPoint = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
    
    if(object == self.tableView)
    {
        if(newPoint.y < 0)
        {
            CGRect frame = self.headerView.frame;
            frame.origin.y = newPoint.y;
            frame.size.height = ceilf(headerHeight-newPoint.y);
            self.headerView.frame = frame;
            
            float sectionHeaderHeight = [self.tableView.delegate tableView:self.tableView heightForHeaderInSection:0];
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(frame.size.height+sectionHeaderHeight, 0, 0, 0);
            self.sectionHeader.layer.shadowOpacity = 0;
        }
        else
        {
            CGRect frame = self.headerView.frame;
            frame.origin.y = 0;
            frame.size.height = headerHeight;
            self.headerView.frame = frame;
            
            float sectionHeaderHeight = [self.tableView.delegate tableView:self.tableView heightForHeaderInSection:0];
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(headerHeight+sectionHeaderHeight, 0, 0, 0);
            self.sectionHeader.layer.shadowOpacity = newPoint.y-headerHeight < 0 ? 0 : (newPoint.y-headerHeight)/20;
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
        
        //NSArray *today = self.channel.schedule[0];
        int count = self.channel.schedule.count;
        /*
        for(NSDictionary *show in today)
        {
            if([show[@"startDate"] timeIntervalSinceNow] < 0
            && [show[@"endDate"] timeIntervalSinceNow] > 0)
            {
                if(today.lastObject == show)
                    count--;
                break;
            }
            
            if([show[@"startDate"] timeIntervalSinceNow] > 0
            && [show[@"endDate"] timeIntervalSinceNow] > 0)
            {
                if(today.lastObject == show)
                    count--;
                break;
            }
        }
        */
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
    if(tableView == self.tableView)
    {
        if(section == 0)
            return 28;
    }
    else if(tableView == self.scheduleTable)
    {
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
            return 102;
    }
    else if(tableView == self.scheduleTable)
    {
        return 20;
    }
    
    return 0;
}

// TODO: Add white line to top of shows section, bottom of episodes section

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    float width = tableView.frame.size.width;
    
    if(tableView == self.tableView && section == 0)
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
        
        float offest = self.tableView.contentOffset.y-headerHeight;
        self.sectionHeader.layer.shadowOpacity = offest < 0 ? 0 : offest/20;
        self.sectionHeader.layer.shadowColor = [[UIColor colorWithWhite:0 alpha:0.5f] CGColor];
        self.sectionHeader.layer.shadowOffset = CGSizeMake(0, 3);
        self.sectionHeader.layer.shadowRadius = 3;
        
        return self.sectionHeader;
    }
    else if(tableView == self.scheduleTable)
    {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(107, 0, width-107, 20)];
       
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textColor = [UIColor whiteColor];
        headerLabel.font = [UIFont systemFontOfSize:12];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEEE"];
        NSDate *startTime = self.channel.schedule[section][0][@"startDate"];
        headerLabel.text = [dateFormatter stringFromDate:startTime];
        
        if(section == 0)
            headerLabel.text = @"Today";
        else if(section == 1)
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
        
        int section = indexPath.section;// + (self.channel.schedule.count-tableView.numberOfSections);
        NSDictionary *show = self.channel.schedule[section][indexPath.row];
        
        NSDateFormatter *dateFormatterLocal = [[NSDateFormatter alloc] init];
        [dateFormatterLocal setTimeZone:[NSTimeZone localTimeZone]];
        [dateFormatterLocal setDateFormat:@"h:mm a"];
        cell.textLabel.text = [dateFormatterLocal stringFromDate:show[@"startDate"]];
        
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
        TWShowTableCell *showsCell = (TWShowTableCell*)cell;
        id <NSFetchedResultsSectionInfo>sectionInfo = self.fetchedShowsController.sections[indexPath.section];
        int num = sectionInfo.numberOfObjects;
        int columns = showsCell.columns;
        
        for(int column = 0; column < columns; column++)
        {
            int index = indexPath.row*columns + column;
            if(num > index)
            {
                NSIndexPath *columnedIndexPath = [NSIndexPath indexPathForRow:index inSection:indexPath.section];
                __block Show *show = [self.fetchedShowsController objectAtIndexPath:columnedIndexPath];
                NSString *albumArtPath = show.albumArt.path;
                
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
                
                dispatch_async(queue, ^{
                    UIImage *albumArt = [UIImage imageWithContentsOfFile:albumArtPath] ?: [UIImage imageNamed:@"generic.jpg"];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if(column == 0)
                            [showsCell.showOneButton setImage:albumArt forState:UIControlStateNormal];
                        if(column == 1)
                            [showsCell.showTwoButton setImage:albumArt forState:UIControlStateNormal];
                        if(column == 2)
                            [showsCell.showThreeButton setImage:albumArt forState:UIControlStateNormal];
                    });
                    
                });
            }
        }
        
        /*
        // TODO: CACHE THIS MUCHERFUCKER!
        TWShowsCell *showsCell = (TWShowsCell*)cell;
        
        showsCell.spacing = 14;
        showsCell.size = 88;
        showsCell.columns = 3;
        showsCell.delegate = self;
        showsCell.table = self.tableView;
        showsCell.indexPath = indexPath;
        
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
         */
    }
}

- (void)reloadSchedule:(NSNotification*)notification
{
    NSArray *schedule = notification.object;
    NSArray *today = schedule[0];
    
    for(NSDictionary *show in today)
    {
        if([show[@"startDate"] timeIntervalSinceNow] < 0
        && [show[@"endDate"] timeIntervalSinceNow] > 0)
        {
            self.liveTimeLabel.text = @"LIVE";
            self.liveTitleLabel.text = show[@"title"];
            
            break;
        }
        
        if([show[@"startDate"] timeIntervalSinceNow] > 0
        && [show[@"endDate"] timeIntervalSinceNow] > 0)
        {
            NSInteger interval = [show[@"startDate"] timeIntervalSinceNow];
            NSInteger minutes = (interval / 60) % 60;
            NSInteger hours = (interval / 3600);
            
            if(interval > 10*60)
                self.liveTimeLabel.text = [NSString stringWithFormat:@"%ih %02im", hours, minutes];
            else
                self.liveTimeLabel.text = @"Pre-show";
            
            self.liveTitleLabel.text = show[@"title"];
            
            break;
        }
    }
    
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
