//
//  TWNavigationController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/25/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWNavigationController.h"

@implementation TWNavigationController

#pragma mark - Rotate

- (BOOL)shouldAutorotate;
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)])
        return self.topViewController.supportedInterfaceOrientations;
    else
        return super.supportedInterfaceOrientations;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if ([self.topViewController respondsToSelector:@selector(preferredStatusBarStyle)])
        return self.topViewController.preferredStatusBarStyle;
    else
        return super.preferredStatusBarStyle;
}

@end
