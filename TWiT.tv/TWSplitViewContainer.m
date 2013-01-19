//
//  TWSplitViewContainer.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWSplitViewContainer.h"
#import "TWMainViewController.h"
#import "TWEpisodeViewController.h"

@implementation TWSplitViewContainer

- (void)setMasterController:(UINavigationController*)masterController
{
    _masterController = masterController;
    
    [self addChildViewController:masterController];
    
    masterController.view.frame = self.masterContainer.bounds;
    [self.masterContainer addSubview:masterController.view];
    [self.masterContainer sendSubviewToBack:masterController.view];
}

- (void)setDetailController:(UINavigationController*)detailController
{
    _detailController = detailController;
    
    [self addChildViewController:detailController];
    
    detailController.view.frame = self.detailContainer.bounds;
    [self.detailContainer addSubview:detailController.view];
    [self.detailContainer sendSubviewToBack:detailController.view];
}

- (void)setModalController:(UINavigationController*)modalController
{
    _modalController = modalController;
    
    [self addChildViewController:modalController];
    TWEpisodeViewController *episodeController = (TWEpisodeViewController*)modalController.topViewController;
    episodeController.splitViewContainer = self;
    
    modalController.view.frame = self.modalFlyout.bounds;
    [self.modalFlyout addSubview:modalController.view];
    /*
    self.modalFlyout.layer.shadowRadius = 15;
    self.modalFlyout.layer.shadowOpacity = 0.5f;
    self.modalFlyout.layer.shadowOffset = CGSizeMake(5, 0);
    self.modalFlyout.layer.shadowColor = [[UIColor blackColor] CGColor];
    */
}

#pragma mark - Actions

- (void)hidePlaybar
{
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
    }];
}
- (void)showPlaybar
{
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
