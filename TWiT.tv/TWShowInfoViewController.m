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
    
    self.emailButton.hidden = !self.show.email;
    self.websiteButton.hidden = !self.show.website;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGRect frame = self.view.superview.bounds;
    frame.size.height = frame.size.width;
    self.view.superview.bounds = frame;
}

- (IBAction)email:(UIButton*)sender
{
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setToRecipients:@[self.show.email]];
    [self presentViewController:controller animated:YES completion:nil];
}
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openWebsite:(UIButton*)sender
{
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:self.show.website]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Rotate

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
