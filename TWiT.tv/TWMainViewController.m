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
#import "TWNavigationController.h"

#import "TWMainViewController.h"
#import "TWStreamViewController.h"
#import "TWEnclosureViewController.h"

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

#define NAVBAR_INSET 64

@interface TWMainViewController ()
- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath;
@end

@implementation TWMainViewController

- (void)awakeFromNib
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        self.sectionVisible = TWSectionEpisodes;
    
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *liveGradient = [CAGradientLayer layer];
    liveGradient.anchorPoint = CGPointMake(0, 0);
    liveGradient.position = CGPointMake(0, 0);
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        liveGradient.startPoint = CGPointMake(0, 0);
        liveGradient.endPoint = CGPointMake(1, 0);
    }
    else
    {
        liveGradient.startPoint = CGPointMake(0, 1);
        liveGradient.endPoint = CGPointMake(0, 0);
    }
    
    liveGradient.bounds = self.gradientView.bounds;
    liveGradient.colors = [NSArray arrayWithObjects:
                            (id)[UIColor colorWithWhite:0 alpha:1].CGColor,
                            (id)[UIColor colorWithWhite:0 alpha:0.6f].CGColor,
                            (id)[UIColor colorWithWhite:0 alpha:0].CGColor, nil];
    [self.gradientView.layer addSublayer:liveGradient];

    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(albumArtDidChange:)
                                               name:@"albumArtDidChange"
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(redrawSchedule:)
                                               name:@"ScheduleDidUpdate"
                                             object:self.channel.schedule];
    
    self.headerView.translatesAutoresizingMaskIntoConstraints = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self redrawSchedule:nil];
    
    if(self.sectionVisible == TWSectionShows && self.presentedViewController)
        [self.tableView reloadData];
    
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

#pragma mark - Actions

- (void)switchVisibleSection:(UIButton*)sender
{
    self.sectionVisible = sender.tag;
    
    if(self.sectionVisible == TWSectionEpisodes)
    {
        self.tableView.tableFooterView = nil;
    }
    else
    {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 2)];
        footer.backgroundColor = [UIColor clearColor];
        self.tableView.tableFooterView = footer;
    }
    
    [self.tableView reloadData];
}

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
    if(self.sectionVisible != TWSectionEpisodes)
        return;
    
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

- (NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if([tableView.indexPathForSelectedRow isEqual:indexPath])
        {
            CGRect frame = self.splitViewContainer.modalFlyout.frame;
            frame.origin.x = -frame.size.width;
            
            [UIView animateWithDuration:0.3f animations:^{
                self.splitViewContainer.modalFlyout.frame = frame;
                self.splitViewContainer.modalBlackground.alpha = 0;
            } completion:^(BOOL fin){
                self.splitViewContainer.modalContainer.hidden = YES;
                self.splitViewContainer.modalBlackground.alpha = 1;
            }];
            
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
            
            if(self.splitViewContainer.modalContainer.hidden)
            {
                self.splitViewContainer.modalBlackground.alpha = 0;
                self.splitViewContainer.modalContainer.hidden = NO;
                
                CGRect frame = self.splitViewContainer.modalFlyout.frame;
                frame.origin.x = 0;
                
                [UIView animateWithDuration:0.3f animations:^{
                    self.splitViewContainer.modalBlackground.alpha = 1;
                    self.splitViewContainer.modalFlyout.frame = frame;
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
            {
                // TODO: Crashes
                //self.showSelectedView = nil;
                //[masterController popToRootViewControllerAnimated:YES];
            }
            else
            {
                CGRect frame = [showCell frameForColumn:column];
                frame = [showCell convertRect:frame toView:self.tableView];
                frame = CGRectInset(frame, -11, -11);
                frame.origin.y += 1;
                self.showSelectedView.frame = frame;
                self.showSelectedView.tag = index;
                
                [selectedShow updateEpisodes];
                showController.show = selectedShow;
                
                [showController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
            }
        }
        else
        {
            if(!self.showSelectedView)
                self.showSelectedView = [[UIImageView alloc] init];
            
            CGRect frame = [showCell frameForColumn:column];
            frame = [showCell convertRect:frame toView:self.tableView];
            frame = CGRectInset(frame, -11, -11);
            frame.origin.y += 1;
            self.showSelectedView.frame = frame;
            self.showSelectedView.tag = index;
            
            TWMainViewController *episodesController = (TWMainViewController*)masterController.topViewController;
            [episodesController performSegueWithIdentifier:@"showDetail" sender:showIndexPath];
        }
    }
}

- (void)setShowSelectedView:(UIImageView*)showSelectedView
{
    if(showSelectedView == nil)
    {
        [_showSelectedView removeFromSuperview];
        _showSelectedView = showSelectedView;
    }
    else
    {
        _showSelectedView = showSelectedView;
        _showSelectedView.userInteractionEnabled = NO;
        _showSelectedView.image = [[UIImage imageNamed:@"show-selection.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 11, 12, 11)];
        [self.tableView addSubview:_showSelectedView];
    }
}

#pragma mark - Notifications

- (void)redrawSchedule:(NSNotification*)notification
{
    if(!self.channel.schedule || self.channel.schedule.days.count == 0)
        return;
    
    Event *currentShow = self.channel.schedule.currentShow;
    self.liveTimeLabel.text = currentShow.until;
    self.liveTitleLabel.text = currentShow.title;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        Event *nextShow = [self.channel.schedule showAfterShow:currentShow];
        
        if([self.liveTimeLabel.text isEqualToString:@"Live"] || nextShow.start.isTomorrow)
            self.nextTimeLabel.text = nextShow.until;
        else if([self.liveTimeLabel.text isEqualToString:@"Tomorrow"])
            self.nextTimeLabel.text = @"After That";
        else
            self.nextTimeLabel.text = nextShow.time;
        
        self.nextTitleLabel.text = nextShow.title;
    }
    
    Show *show = currentShow.show ?: self.channel.shows.anyObject;
    
    UIImage *livePoster = show.poster.image;
    if(!livePoster)
    {
        NSString *resourceName = [NSString stringWithFormat:@"%@-poster.jpg", show.titleAcronym.lowercaseString];
        NSString *resourcePath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:resourceName];
        
        if([NSFileManager.defaultManager fileExistsAtPath:resourcePath])
            livePoster = [UIImage imageWithContentsOfFile:resourcePath];
        else
            livePoster = show.albumArt.image;
    }
    self.livePosterView.image = livePoster;
    
    self.liveAlbumArtView.image = (currentShow.show) ? show.albumArt.image : [UIImage imageNamed:@"generic.jpg"];
    
    if(currentShow.start.isBeforeNow && currentShow.end.isAfterNow)
    {
        NSTimeInterval secondsElasped = currentShow.start.timeIntervalSinceNow;
        NSTimeInterval secondsDuration = [currentShow.start timeIntervalSinceDate:currentShow.end];
        self.playButton.percentage = (secondsDuration != 0) ? secondsElasped/secondsDuration : 0;
    }
    else
    {
        self.playButton.percentage = 0;
    }
    
    [self.scheduleTable reloadData];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(redrawSchedule:) object:nil];
    
    if([self.liveTimeLabel.text hasSuffix:@"m"] || [self.nextTimeLabel.text hasSuffix:@"m"])
        [self performSelector:@selector(redrawSchedule:) withObject:nil afterDelay:60];
    else if([self.liveTimeLabel.text isEqualToString:@"Pre-show"])
        [self performSelector:@selector(redrawSchedule:) withObject:nil afterDelay:currentShow.start.timeIntervalSinceNow];
    else if([self.liveTimeLabel.text isEqualToString:@"Live"])
        [self performSelector:@selector(redrawSchedule:) withObject:nil afterDelay:currentShow.end.timeIntervalSinceNow];
        // Redraw for iPad progress view?
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
        cell.progress = (enclosure.expectedLength != 0)? enclosure.downloadedLength/(CGFloat)enclosure.expectedLength : 0;
    else if([notification.name isEqualToString:@"enclosureDownloadDidFinish"]
    || [notification.name isEqualToString:@"enclosureDownloadDidFail"])
        cell.progress = 1;
}

- (void)albumArtDidChange:(NSNotification*)notification
{
    self.showsTableCache = nil;
    [self.tableView reloadData];
}

#pragma mark - Table View

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
            frame.origin.y = scrollView.contentOffset.y+NAVBAR_INSET;
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
        
        [[self.tableView viewWithTag:98] removeFromSuperview];
        
        if(self.sectionVisible == TWSectionEpisodes)
        {
            sectionInfo = self.fetchedEpisodesController.sections[section];
            
            if(sectionInfo.numberOfObjects == 0)
            {
                CGFloat headerHeight = self.tableView.tableHeaderView.frame.size.height;
                
                UIImageView *emptyView = [[UIImageView alloc] init];
                emptyView.image = [UIImage imageNamed:@"episodes-table-empty.png"];
                emptyView.contentMode = UIViewContentModeScaleAspectFit;
                emptyView.frame = CGRectMake(0, 0, 320, 88);
                emptyView.center = self.tableView.center;
                
                CGPoint center = emptyView.center;
                center.y += headerHeight/2.0f;
                emptyView.center = center;
                
                emptyView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin);
                emptyView.tag = 98;
                [self.tableView addSubview:emptyView];
            }
            
            return sectionInfo.numberOfObjects;
        }
        else if(self.sectionVisible == TWSectionShows)
        {
            sectionInfo = self.fetchedShowsController.sections[section];
            int num = sectionInfo.numberOfObjects;
            int columns = 3;
            
            if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
                columns = (self.tableView.frame.size.width <= 448) ? 3 : 4;
            
            return ceil((double)num/columns);
        }
    }
    else if(tableView == self.scheduleTable)
    {
        return [self.channel.schedule.days[section] count];
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(tableView == self.tableView && section == 0 && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        return (self.sectionVisible == TWSectionShows) ? 28 : 28;
    }
    if(tableView == self.tableView && section == 0 && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        return (self.sectionVisible == TWSectionShows) ? 6 : 0;
    }
    else if(tableView == self.scheduleTable)
    {
        if(self.channel.schedule.days.count <= section)
            return 0;
        
        if([self.channel.schedule.days[section] count] == 0)
            return 0;
        
        Event *firstShow = self.channel.schedule.days[section][0];
        
        if(firstShow.start.isToday)
            return 0;
        
        return 20;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView == self.tableView)
    {
        if(self.sectionVisible == TWSectionEpisodes)
            return 65;
        else if(self.sectionVisible == TWSectionShows)
        {
            if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
                return (self.tableView.frame.size.width <= 448) ? 146 : 172;
            else
                return 105;
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
    CGFloat width = tableView.frame.size.width;
    
    if(tableView == self.tableView && section == 0 && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        self.sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 28)];
        self.sectionHeader.backgroundColor = [UIColor whiteColor];
        
        UIImage *buttonUpBackground = [[UIImage imageNamed:@"main-header-button-up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage *buttonDownBackground = [[UIImage imageNamed:@"main-header-button.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        UIButton *episodesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        episodesButton.frame = CGRectMake(2, 2, 157, 24);
        [episodesButton setTitle:@"watch list" forState:UIControlStateNormal];
        episodesButton.tag = TWSectionEpisodes;
        episodesButton.selected = (self.sectionVisible == episodesButton.tag);
        [episodesButton addTarget:self action:@selector(switchVisibleSection:) forControlEvents:UIControlEventTouchUpInside];
        [episodesButton setBackgroundImage:buttonDownBackground forState:UIControlStateHighlighted];
        [episodesButton setBackgroundImage:buttonDownBackground forState:UIControlStateSelected];
        [episodesButton setBackgroundImage:buttonUpBackground forState:UIControlStateNormal];
        [episodesButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
        [episodesButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
        [episodesButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [self.sectionHeader addSubview:episodesButton];
        
        UIButton *showsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        showsButton.frame = CGRectMake(161, 2, 157, 24);
        [showsButton setTitle:@"all shows" forState:UIControlStateNormal];
        showsButton.tag = TWSectionShows;
        showsButton.selected = (self.sectionVisible == showsButton.tag);
        [showsButton addTarget:self action:@selector(switchVisibleSection:) forControlEvents:UIControlEventTouchUpInside];
        [showsButton setBackgroundImage:buttonDownBackground forState:UIControlStateHighlighted];
        [showsButton setBackgroundImage:buttonDownBackground forState:UIControlStateSelected];
        [showsButton setBackgroundImage:buttonUpBackground forState:UIControlStateNormal];
        [showsButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
        [showsButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
        [showsButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [self.sectionHeader addSubview:showsButton];
        
        UILabel *botLine = [[UILabel alloc] initWithFrame:CGRectMake(0, 27.5f, 320, 0.5f)];
        botLine.backgroundColor = [UIColor colorWithWhite:178/255.0 alpha:1];
        [self.sectionHeader addSubview:botLine];

        return self.sectionHeader;
    }
    else if(tableView == self.scheduleTable)
    {
        if(self.channel.schedule.days.count <= section)
            return nil;
        
        if([self.channel.schedule.days[section] count] == 0)
            return nil;
        
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

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(tableView != self.tableView || self.sectionVisible != TWSectionEpisodes)
        return NO;
    
    if([indexPath isEqual:[tableView indexPathForSelectedRow]])
        return NO;
    
    Episode *episode = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
    return episode.downloadedEnclosures;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        if(tableView != self.tableView || self.sectionVisible != TWSectionEpisodes)
            return;
        
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
        NSString *identifier = (self.sectionVisible == TWSectionEpisodes) ? @"episodeCell" : @"showsCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        [self configureCell:cell atIndexPath:indexPath];
        
        cell.backgroundColor = UIColor.clearColor;
        
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
        
        if(self.sectionVisible == TWSectionEpisodes && !episode.downloadedEnclosures)
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
    else if([cell.reuseIdentifier isEqualToString:@"showsCell"])
    {
        TWShowsCell *showsCell = (TWShowsCell*)cell;
        showsCell.delegate = self;
        showsCell.table = self.tableView;
        showsCell.indexPath = indexPath;
        
        if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            if(self.tableView.frame.size.width <= 448)
            {
                showsCell.spacing = 8;
                showsCell.size = 138;
                showsCell.columns = 3;
            }
            else
            {
                showsCell.spacing = 15;
                showsCell.size = 157;
                showsCell.columns = 4;
            }
        }
        else
        {
            showsCell.spacing = 5;
            showsCell.size = 100;
            showsCell.columns = 3;
        }
        
        self.showsTableCache = self.showsTableCache ?: [NSMutableDictionary dictionary];
        NSString *cacheKey = [NSString stringWithFormat:@"%f-%d", self.tableView.frame.size.width, indexPath.row];
        NSDictionary *rowCache = self.showsTableCache[cacheKey];
        
        if(!rowCache)
        {
            showsCell.icons = nil;
            id <NSFetchedResultsSectionInfo>sectionInfo = self.fetchedShowsController.sections[indexPath.section];
            NSInteger num = sectionInfo.numberOfObjects;
            NSInteger columns = showsCell.columns;
            
            NSMutableArray *shows = [NSMutableArray array];
            for(NSInteger column = 0; column < columns; column++)
            {
                NSInteger index = indexPath.row*columns + column;
                if(num > index)
                {
                    NSIndexPath *columnedIndexPath = [NSIndexPath indexPathForRow:index inSection:indexPath.section];
                    Show *show = [self.fetchedShowsController objectAtIndexPath:columnedIndexPath];
                    [shows addObject:show];
                }
            }
            showsCell.shows = shows;
        }
        else
        {
            showsCell.icons = [rowCache objectForKey:@"icons"];
            showsCell.shows = [rowCache objectForKey:@"shows"];
            [showsCell setNeedsDisplay];
        }
    }
}

- (void)showsCell:(TWShowsCell*)showsCell didDrawIconsAtIndexPath:(NSIndexPath*)indexPath;
{
    if(!showsCell || !showsCell.icons || !showsCell.shows)
        return;
        
    NSString *cacheKey = [NSString stringWithFormat:@"%f-%d", self.tableView.frame.size.width, showsCell.indexPath.row];
    NSDictionary *rowCache = self.showsTableCache[cacheKey];
    
    rowCache = @{ @"icons" : showsCell.icons, @"shows" : showsCell.shows };
    [self.showsTableCache setObject:rowCache forKey:cacheKey];
    
    [showsCell setNeedsDisplay];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController*)fetchedEpisodesController
{
    if(_fetchedEpisodesController != nil)
        return _fetchedEpisodesController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"published" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"watched = NO OR ANY enclosures.path != nil"]; //AND published != nil
    
    //?  OR ANY enclosures.downloadConnection != nil
    
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
                                                                                   sectionNameKeyPath:nil cacheName:nil];
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
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationTop];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationTop];
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
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
                break;
                
            case NSFetchedResultsChangeDelete:
                
                if([indexPath isEqual:self.tableView.indexPathForSelectedRow])
                {
                    CGRect frame = self.splitViewContainer.modalFlyout.frame;
                    frame.origin.x -= frame.size.width;
                    
                    [UIView animateWithDuration:0.3f animations:^{
                        self.splitViewContainer.modalFlyout.frame = frame;
                        self.splitViewContainer.modalBlackground.alpha = 0;
                    } completion:^(BOOL fin){
                        self.splitViewContainer.modalContainer.hidden = YES;
                        self.splitViewContainer.modalBlackground.alpha = 1;
                    }];
                }
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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
    if(controller == self.fetchedEpisodesController && self.sectionVisible == TWSectionEpisodes)
    {
        [self.tableView endUpdates];
    }
    else if(controller == self.fetchedShowsController && self.sectionVisible == TWSectionShows)
    {
        [self.tableView reloadData];
    }
}

#pragma mark - Rotate

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if(self.sectionVisible == TWSectionShows)
        [self.tableView reloadData];
    
    if(self.showSelectedView)
        self.showSelectedView.hidden = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(self.sectionVisible == TWSectionShows)
        [self.tableView layoutSubviews];
    
    if(self.showSelectedView)
    {
        NSInteger columns = (UIInterfaceOrientationIsLandscape(fromInterfaceOrientation)) ? 3 : 4;
        NSInteger index = self.showSelectedView.tag;
        NSInteger row = index/columns;
        NSInteger column = index%columns;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        TWShowsCell *showCell = (TWShowsCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        
        CGRect frame = [showCell frameForColumn:column];
        frame = [showCell convertRect:frame toView:self.tableView];
        frame = CGRectInset(frame, -11, -11);
        frame.origin.y += 1;
        self.showSelectedView.frame = frame;
        self.showSelectedView.hidden = NO;
    }
}

- (NSUInteger)supportedInterfaceOrientations
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
    else if([segue.identifier isEqualToString:@"showDetail"])
    {
        NSIndexPath *indexPath = (NSIndexPath*)sender;
        Show *show = [self.fetchedShowsController objectAtIndexPath:indexPath];
        [show updateEpisodes];
    
        if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
            [segue.destinationViewController setSplitViewContainer:self.splitViewContainer];
        
        [segue.destinationViewController setShow:show];
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

- (void)didReceiveMemoryWarning
{
    self.showsTableCache = nil;
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidReceiveData" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFinish" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFail" object:nil];
    
    [super viewWillDisappear:animated];
}

@end
