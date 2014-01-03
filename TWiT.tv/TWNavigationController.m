//
//  TWNavigationController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/25/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWNavigationController.h"

@implementation TWNavigationController

#pragma mark - Settings

//TODO: That semicolon looks wrong
- (BOOL)shouldAutorotate;
{
    return YES;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if([self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)])
        return self.topViewController.supportedInterfaceOrientations;
    else
        return super.supportedInterfaceOrientations;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if([self.topViewController respondsToSelector:@selector(preferredStatusBarStyle)])
        return self.topViewController.preferredStatusBarStyle;
    else
        return super.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    if([self.topViewController respondsToSelector:@selector(prefersStatusBarHidden)])
        return self.topViewController.prefersStatusBarHidden;
    else
        return super.prefersStatusBarHidden;
}

@end
