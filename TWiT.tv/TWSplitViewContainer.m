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
