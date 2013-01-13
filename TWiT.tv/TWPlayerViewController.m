//
//  TWPlayerViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWPlayerViewController.h"
#import "TWSplitViewContainer.h"

#import "Episode.h"
#import "Enclosure.h"

@implementation TWPlayerViewController

- (void)viewDidLoad
{
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.wantsFullScreenLayout = YES;
    [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    self.navigationController.navigationBar.tintColor = UIColor.blackColor;
    self.navigationController.navigationBar.translucent = YES;
}

#pragma mark - Rotate

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Leave

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

- (void)viewWillDisappear:(BOOL)animated
{
    self.wantsFullScreenLayout = NO;
    [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.18 green:0.44 blue:0.57 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

@end
