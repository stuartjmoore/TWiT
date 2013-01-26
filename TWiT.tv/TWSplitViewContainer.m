//
//  TWSplitViewContainer.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWAppDelegate.h"
#import "TWSplitViewContainer.h"
#import "TWMainViewController.h"
#import "TWEpisodeViewController.h"
#import "TWPlaybarViewController.h"

@implementation TWSplitViewContainer

- (void)setMasterController:(UINavigationController*)masterController
{
    _masterController = masterController;
    
    [self addChildViewController:masterController];
    
    masterController.view.frame = self.masterContainer.bounds;
    [self.masterContainer addSubview:masterController.view];
    [self.masterContainer sendSubviewToBack:masterController.view];
    self.masterContainer.backgroundColor = [UIColor clearColor];
}

- (void)setDetailController:(UINavigationController*)detailController
{
    _detailController = detailController;
    
    [self addChildViewController:detailController];
    
    detailController.view.frame = self.detailContainer.bounds;
    [self.detailContainer addSubview:detailController.view];
    [self.detailContainer sendSubviewToBack:detailController.view];
    self.detailContainer.backgroundColor = [UIColor clearColor];
}

- (void)setModalController:(UINavigationController*)modalController
{
    _modalController = modalController;
    
    [self addChildViewController:modalController];
    TWEpisodeViewController *episodeController = (TWEpisodeViewController*)modalController.topViewController;
    episodeController.splitViewContainer = self;
    
    modalController.view.frame = self.modalFlyout.bounds;
    [self.modalFlyout addSubview:modalController.view];
    self.modalFlyout.backgroundColor = [UIColor clearColor];
}

- (void)setPlaybarController:(UIViewController*)playbarController
{
    _playbarController = playbarController;
    
    [self addChildViewController:playbarController];
    
    playbarController.view.frame = self.playbarContainer.bounds;
    [self.playbarContainer addSubview:playbarController.view];
    [self.playbarContainer sendSubviewToBack:playbarController.view];
    self.playbarContainer.backgroundColor = [UIColor clearColor];
}

#pragma mark - Actions


- (void)showPlaybar
{
    if(!self.playbarContainer.hidden)
        return;
    
    [(TWPlaybarViewController*)self.playbarController updateView];
    float height = self.playbarContainer.frame.size.height + 4 + 4;
    
    UITableViewController *episodesTableViewController = (UITableViewController*)self.masterController.topViewController;
    UITableViewController *showsTableViewController = (UITableViewController*)self.detailController.topViewController;
    
    
    UIEdgeInsets insets = episodesTableViewController.tableView.contentInset;
    insets.bottom = height;
    episodesTableViewController.tableView.contentInset = insets;
    
    insets = episodesTableViewController.tableView.scrollIndicatorInsets;
    insets.bottom = height;
    episodesTableViewController.tableView.scrollIndicatorInsets = insets;
    
    
    insets = showsTableViewController.tableView.contentInset;
    insets.bottom = height;
    showsTableViewController.tableView.contentInset = insets;
    
    insets = showsTableViewController.tableView.scrollIndicatorInsets;
    insets.bottom = height;
    showsTableViewController.tableView.scrollIndicatorInsets = insets;
    
    CGRect modalFrame = self.modalFlyout.frame;
    modalFrame.size.height = self.modalContainer.bounds.size.height-height;
    self.modalFlyout.frame = modalFrame;
    
    self.playbarContainer.alpha = 0;
    self.playbarContainer.hidden = NO;
    [UIView animateWithDuration:0.3f animations:^{
        self.playbarContainer.alpha = 1;
    } completion:^(BOOL fin){
    }];
    
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    [NSNotificationCenter.defaultCenter addObserver:self.playbarController
                                           selector:@selector(playerStateChanged:)
                                               name:MPMoviePlayerPlaybackStateDidChangeNotification
                                             object:delegate.player];
}
- (void)hidePlaybar
{
    if(self.playbarContainer.hidden)
        return;
    
    float height = 0;
    
    UITableViewController *episodesTableViewController = (UITableViewController*)self.masterController.topViewController;
    UITableViewController *showsTableViewController = (UITableViewController*)self.detailController.topViewController;
    
    
    UIEdgeInsets insets = episodesTableViewController.tableView.contentInset;
    insets.bottom = height;
    episodesTableViewController.tableView.contentInset = insets;
    
    insets = episodesTableViewController.tableView.scrollIndicatorInsets;
    insets.bottom = height;
    episodesTableViewController.tableView.scrollIndicatorInsets = insets;
    
    
    insets = showsTableViewController.tableView.contentInset;
    insets.bottom = height;
    showsTableViewController.tableView.contentInset = insets;
    
    insets = showsTableViewController.tableView.scrollIndicatorInsets;
    insets.bottom = height;
    showsTableViewController.tableView.scrollIndicatorInsets = insets;
    
    CGRect modalFrame = self.modalFlyout.frame;
    modalFrame.size.height = self.modalContainer.bounds.size.height;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.playbarContainer.alpha = 0;
    } completion:^(BOOL fin){
        self.playbarContainer.hidden = YES;
        self.playbarContainer.alpha = 1;
        self.modalFlyout.frame = modalFrame;
        // TODO: move insets setting to here?
    }];
    
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    [NSNotificationCenter.defaultCenter removeObserver:self.playbarController
                                                  name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                object:delegate.player];
}

#pragma mark - Settings

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
