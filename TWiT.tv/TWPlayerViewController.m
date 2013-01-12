//
//  TWPlayerViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWPlayerViewController.h"
#import "TWSplitViewContainer.h"

@implementation TWPlayerViewController

- (IBAction)close:(UIBarButtonItem*)sender
{
    TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.presentingViewController;
    
    splitViewContainer.view.frame = self.view.bounds;
    [self.view addSubview:splitViewContainer.view];
    
    CGRect masterFrameOriginal = splitViewContainer.masterContainer.frame;
    CGRect masterFrameAnimate = masterFrameOriginal;
    masterFrameAnimate.origin.x -= masterFrameAnimate.size.width;
    splitViewContainer.masterContainer.frame = masterFrameAnimate;
    
    CGRect detailFrameOriginal = splitViewContainer.detailContainer.frame;
    CGRect detailFrameAnimate = detailFrameOriginal;
    detailFrameAnimate.origin.x += detailFrameAnimate.size.width;
    splitViewContainer.detailContainer.frame = detailFrameAnimate;
    
    [UIView animateWithDuration:0.3f animations:^{
        splitViewContainer.masterContainer.frame = masterFrameOriginal;
        splitViewContainer.detailContainer.frame = detailFrameOriginal;
    } completion:^(BOOL fin){
        [self dismissViewControllerAnimated:NO completion:^{}];
    }];
}

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

@end
