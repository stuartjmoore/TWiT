//
//  TWScheduleGridViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWScheduleGridViewController.h"

#import "Schedule.h"
#import "Show.h"

@implementation TWScheduleGridViewController

#pragma mark - Rotate

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationMaskPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Leave

- (IBAction)close:(UIBarButtonItem*)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end