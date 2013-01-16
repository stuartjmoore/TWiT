//
//  TWShowInfoViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/16/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWShowInfoViewController.h"
#import "Show.h"

@implementation TWShowInfoViewController

- (void)viewDidLoad
{
    self.titleLabel.text = self.show.title;
    self.titleLabel.font = [UIFont fontWithName:@"Vollkorn-BoldItalic" size:24];
    self.albumArt.image = self.show.albumArt.image;
    self.hostsLabel.text = self.show.hosts;
    self.scheduleLabel.text = self.show.scheduleString;
    self.descLabel.text = self.show.desc;
}

- (IBAction)emailShow:(UIButton*)sender
{
    
}

- (IBAction)callShow:(UIButton*)sender
{
    
}

- (IBAction)openWebsite:(UIButton*)sender
{
    
}

- (IBAction)openYouTube:(UIButton*)sender
{
    
}

#pragma mark - Rotate

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

- (IBAction)close:(UIButton*)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
