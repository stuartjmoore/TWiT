//
//  TWNavigationContainer.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/26/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"
#import "TWNavigationContainer.h"

#import "TWNavigationController.h"
#import "TWPlaybarViewController.h"

@implementation TWNavigationContainer

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"masterEmbed"])
    {
        _masterController = segue.destinationViewController;
        self.masterController.navigationContainer = self;
    }
    else if([segue.identifier isEqualToString:@"barEmbed"])
    {
        _playbarController = segue.destinationViewController;
        self.playbarController.navigationContainer = self;
    }
}

#pragma mark - Playbar

- (void)showPlaybar
{
    if(!self.playbarContainer.hidden)
        return;
    
    [self.playbarController updateView];
    
    self.masterBottomConstraint.constant = self.playbarContainer.frame.size.height;
    [self.masterContainer setNeedsUpdateConstraints];
    [self.masterContainer updateConstraintsIfNeeded];
    
    self.playbarContainer.hidden = NO;
    self.playbarContainer.alpha = 0;
    
    __weak typeof(self) weak = self;
    
    [UIView animateWithDuration:0.3f animations:^{
        weak.playbarContainer.alpha = 1;
        [weak.masterContainer layoutIfNeeded];
    } completion:nil];
    
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
    
    self.masterBottomConstraint.constant = 0;
    [self.masterContainer setNeedsUpdateConstraints];
    [self.masterContainer updateConstraintsIfNeeded];
    
    __weak typeof(self) weak = self;
    
    [UIView animateWithDuration:0.3f animations:^{
        weak.playbarContainer.alpha = 0;
        [weak.masterContainer layoutIfNeeded];
    } completion:^(BOOL fin){
        weak.playbarContainer.hidden = YES;
        weak.playbarContainer.alpha = 1;
    }];
    
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    [NSNotificationCenter.defaultCenter removeObserver:self.playbarController
                                                  name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                object:delegate.player];
}

#pragma mark - Settings

- (BOOL)shouldAutorotate;
{
    return YES;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if([self.masterController respondsToSelector:@selector(supportedInterfaceOrientations)])
        return self.masterController.supportedInterfaceOrientations;
    else
        return super.supportedInterfaceOrientations;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if([self.masterController respondsToSelector:@selector(preferredStatusBarStyle)])
        return self.masterController.preferredStatusBarStyle;
    else
        return super.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    if([self.masterController respondsToSelector:@selector(prefersStatusBarHidden)])
        return self.masterController.prefersStatusBarHidden;
    else
        return super.prefersStatusBarHidden;
}

@end
