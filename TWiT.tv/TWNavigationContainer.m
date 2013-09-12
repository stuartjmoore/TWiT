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
        self.masterContainer.backgroundColor = [UIColor clearColor];
    }
    else if([segue.identifier isEqualToString:@"barEmbed"])
    {
        _playbarController = segue.destinationViewController;
        self.playbarContainer.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - Playbar

- (void)showPlaybar
{
    if(!self.playbarContainer.hidden)
        return;
    
    [self.playbarController updateView];
    float height = self.playbarContainer.frame.size.height;
    
    CGRect masterFrame = self.masterContainer.frame;
    masterFrame.size.height = self.view.frame.size.height - height;
    self.masterContainer.frame = masterFrame;
    
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
    
    CGRect masterFrame = self.masterContainer.frame;
    masterFrame.size.height = self.view.frame.size.height;
    self.masterContainer.frame = masterFrame;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.playbarContainer.alpha = 0;
    } completion:^(BOOL fin){
        self.playbarContainer.hidden = YES;
        self.playbarContainer.alpha = 1;
    }];
    
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    [NSNotificationCenter.defaultCenter removeObserver:self.playbarController
                                                  name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                object:delegate.player];
}

#pragma mark - Rotate

- (BOOL)shouldAutorotate;
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
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
