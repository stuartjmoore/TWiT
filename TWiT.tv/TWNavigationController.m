//
//  TWNavigationController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/25/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWNavigationController.h"

@implementation TWNavigationController

#pragma mark - Playbar

- (BOOL)containsPlaybar
{
    return [self.view.subviews containsObject:self.playbarContainer];
}

- (void)showPlaybar
{
    if(self.containsPlaybar)
        return;
    
    self.playbarContainer = self.playbarContainer ?: [[UIView alloc] init];
    self.playbarContainer.backgroundColor = [UIColor redColor];
    
    CGRect testframe = self.view.bounds;
    testframe.origin.x = 4;
    testframe.origin.y = self.view.bounds.size.height-40-4;
    testframe.size.width = 320-4-4;
    testframe.size.height = 40;
    self.playbarContainer.frame = testframe;
    
    
    [self.view addSubview:self.playbarContainer];
}

- (void)hidePlaybar
{
    if(!self.containsPlaybar)
        return;
    
    [self.playbarContainer removeFromSuperview];
}

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

@end
