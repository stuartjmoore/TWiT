//
//  TWEpisodeViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWAppDelegate.h"

#import "TWSplitViewContainer.h"
#import "TWNavigationController.h"
#import "TWEpisodeViewController.h"
#import "TWEnclosureViewController.h"

#import "TWSegmentedButton.h"
#import "TWPlayButton.h"

#import "Episode.h"
#import "Enclosure.h"

@implementation TWEpisodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *liveGradient = [CAGradientLayer layer];
    liveGradient.anchorPoint = CGPointMake(0, 0);
    liveGradient.position = CGPointMake(0, 0);
    liveGradient.startPoint = CGPointMake(0, 1);
    liveGradient.endPoint = CGPointMake(0, 0);
    liveGradient.bounds = self.gradientView.bounds;
    liveGradient.colors = [NSArray arrayWithObjects:
                           (id)[UIColor colorWithWhite:0 alpha:1].CGColor,
                           (id)[UIColor colorWithWhite:0 alpha:0.6f].CGColor,
                           (id)[UIColor colorWithWhite:0 alpha:0].CGColor, nil];
    [self.gradientView.layer addSublayer:liveGradient];
    
    [self configureView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.unlockRotation = NO;
    
    self.playButton.percentage = (self.episode.duration != 0) ? (float)self.episode.lastTimecode/self.episode.duration : 0;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidReceiveData"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidFinish"
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(updateProgress:)
                                               name:@"enclosureDownloadDidFail"
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(posterDidChange:)
                                               name:@"posterDidChange"
                                             object:self.episode];
    
    self.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@""
                                                                           style:UIBarButtonItemStyleBordered
                                                                          target:nil
                                                                          action:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //self.unlockRotation = YES;
}

#pragma mark - Episode

- (void)setEpisode:(Episode*)episode
{
    if(_episode != episode)
    {
        _episode = episode;
        [self configureView];
    }
}

- (void)configureView
{
    if(self.episode)
    {
        self.title = self.episode.title;
        self.posterView.image = self.episode.poster.image;
        self.dateLabel.text = self.episode.publishedString;
        self.timeLabel.text = self.episode.durationString;
        self.numberLabel.text = @(self.episode.number).stringValue;
        self.guestsLabel.text = self.episode.guests;
        self.descLabel.text = self.episode.desc;
        
        self.numberLabel.accessibilityLabel = [NSString stringWithFormat:@"Episode number %d", self.episode.number];
        self.guestsLabel.accessibilityLabel = [NSString stringWithFormat:@"With %@", self.episode.guests];
        
        NSInteger hours = self.episode.duration/3600;
        NSInteger minutes = (self.episode.duration/60)%60;
        
        if(hours == 0)
            self.timeLabel.accessibilityLabel = [NSString stringWithFormat:@"Length: %d minutes", minutes];
        else if(hours == 1)
            self.timeLabel.accessibilityLabel = [NSString stringWithFormat:@"Length: one hour and %d minutes", minutes];
        else
            self.timeLabel.accessibilityLabel = [NSString stringWithFormat:@"Length: %d hours and %d minutes", hours, minutes];
        
        self.playButton.percentage = (self.episode.duration != 0) ? (float)self.episode.lastTimecode/(float)self.episode.duration : 0;
   
        
        self.segmentedButton.buttonState = self.episode.downloadedEnclosures ? TWButtonSegmentDelete : TWButtonSegmentDownload;

        if(self.segmentedButton.buttonState == TWButtonSegmentDelete)
        {
            self.segmentedButton.listenEnabled = NO;
            self.segmentedButton.watchEnabled = YES;
            
            NSSet *enclosures = [self.episode downloadedEnclosures];
            Enclosure *enclosure = enclosures.anyObject;
            NSString *watchButtonTitle = [NSString stringWithFormat:@"%@ - %@", enclosure.title, enclosure.subtitle];
            [self.segmentedButton.watchButton setTitle:watchButtonTitle forState:UIControlStateNormal];
        }
        else
        {
            self.segmentedButton.listenEnabled = [self.episode enclosuresForType:TWTypeAudio]? YES:NO;
            self.segmentedButton.watchEnabled = [self.episode enclosuresForType:TWTypeVideo]? YES:NO;
            
            [self.segmentedButton.watchButton setTitle:@"Watch" forState:UIControlStateNormal];
            self.segmentedButton.hidden = !self.segmentedButton.listenEnabled && !self.segmentedButton.watchEnabled;
        }
        
        [self.segmentedButton addTarget:self action:@selector(watchPressed:) forButton:TWButtonSegmentWatch];
        [self.segmentedButton addTarget:self action:@selector(listenPressed:) forButton:TWButtonSegmentListen];
        [self.segmentedButton addTarget:self action:@selector(downloadPressed:) forButton:TWButtonSegmentDownload];
        [self.segmentedButton addTarget:self action:@selector(cancelPressed:) forButton:TWButtonSegmentCancel];
        [self.segmentedButton addTarget:self action:@selector(deletePressed:) forButton:TWButtonSegmentDelete];
    }
}

- (void)posterDidChange:(NSNotification*)notification
{
    if(notification.object == self.episode)
        self.posterView.image = self.episode.poster.image;
}

#pragma mark - Actions

- (void)watchPressed:(TWSegmentedButton*)sender
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [self performSegueWithIdentifier:@"playerDetail" sender:sender.watchButton];
    else
        [self transitionToPlayer:sender.watchButton];
}
- (void)listenPressed:(TWSegmentedButton*)sender
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [self performSegueWithIdentifier:@"playerDetail" sender:sender.listenButton];
    else
    {
        //[self transitionToPlayer:sender.listenButton];
        
        Enclosure *enclosure = [self.episode enclosureForType:TWTypeAudio andQuality:TWQualityAudio];
        TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
        delegate.nowPlaying = enclosure;
        [self.splitViewContainer showPlaybar];
    }
}

- (void)downloadPressed:(TWSegmentedButton*)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Download Quality"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"quality" ascending:NO];
    NSArray *enclosures = [self.episode.enclosures sortedArrayUsingDescriptors:@[descriptor]];
    
    for(Enclosure *enclosure in enclosures)
       [sheet addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@", enclosure.title, enclosure.subtitle]];
    
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    
    [sheet showFromRect:CGRectMake(self.segmentedButton.frame.size.width-22, 22, 1, 22)
                 inView:self.segmentedButton animated:YES];
}
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == -1 || buttonIndex >= actionSheet.numberOfButtons-1)
        return;
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"quality" ascending:NO];
    NSArray *enclosures = [self.episode.enclosures sortedArrayUsingDescriptors:@[descriptor]];
    Enclosure *enclosure = enclosures[buttonIndex];
    [self.episode downloadEnclosure:enclosure];
    
    self.segmentedButton.progress = 0;
    self.segmentedButton.buttonState = TWButtonSegmentCancel;
}

- (void)updateProgress:(NSNotification*)notification
{
    Enclosure *enclosure = notification.object;
    
    if(enclosure.episode != self.episode)
        return;
    
    if([notification.name isEqualToString:@"enclosureDownloadDidReceiveData"])
    {
        if(self.segmentedButton.buttonState != TWButtonSegmentCancel)
            self.segmentedButton.buttonState = TWButtonSegmentCancel;
        
        self.segmentedButton.progress = (enclosure.expectedLength != 0)? enclosure.downloadedLength/(float)enclosure.expectedLength : 0;
    }
    else if([notification.name isEqualToString:@"enclosureDownloadDidFinish"])
    {
        [self configureView];
    }
    else if([notification.name isEqualToString:@"enclosureDownloadDidFail"])
    {
        [self configureView];
    }
}

- (void)cancelPressed:(TWSegmentedButton*)sender
{
    [self.episode cancelDownloads];
}

- (void)deletePressed:(TWSegmentedButton*)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete"
                                                    message:@"Are you sure you want to delete this download?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Delete", nil];
    [alert show];
}
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1 && [alertView.title isEqualToString:@"Delete"])
    {
        [self.episode deleteDownloads];
        [self configureView];
    }
}

#pragma mark - Leave

- (void)prepareForTransitionToPlayer:(TWEnclosureViewController*)playerController sender:(id)sender
{
    if(sender == self.playButton || sender == self.segmentedButton.watchButton)
    {
        NSSet *enclosures = [self.episode downloadedEnclosures];
        Enclosure *enclosure = enclosures.anyObject ?: [self.episode enclosureForType:TWTypeVideo andQuality:TWQualityHigh];
        
        playerController.enclosure = enclosure;
    }
    else if(sender == self.segmentedButton.listenButton)
    {
        Enclosure *enclosure = [self.episode enclosureForType:TWTypeAudio andQuality:TWQualityAudio];
        
        playerController.enclosure = enclosure;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    [self prepareForTransitionToPlayer:segue.destinationViewController sender:sender];
}

- (IBAction)transitionToPlayer:(UIButton*)sender
{
    TWEnclosureViewController *playerController = [self.storyboard instantiateViewControllerWithIdentifier:@"playerController"];
    playerController.splitViewContainer = self.splitViewContainer;
    [self prepareForTransitionToPlayer:playerController sender:sender];
    
    playerController.view.frame = self.splitViewContainer.view.bounds;
    playerController.view.autoresizingMask = 63;
    [self.splitViewContainer.view addSubview:playerController.view];
    [self.splitViewContainer.view sendSubviewToBack:playerController.view];
    [self.splitViewContainer addChildViewController:playerController];
    [self setNeedsStatusBarAppearanceUpdate];
    
    CGRect masterFrameOriginal = self.splitViewContainer.masterContainer.frame;
    CGRect masterFrameAnimate = masterFrameOriginal;
    masterFrameAnimate.origin.x -= masterFrameAnimate.size.width;
    
    CGRect detailFrameOriginal = self.splitViewContainer.detailContainer.frame;
    CGRect detailFrameAnimate = detailFrameOriginal;
    detailFrameAnimate.origin.x += detailFrameAnimate.size.width;
    
    CGRect modalFrameOriginal = self.splitViewContainer.detailContainer.frame;
    CGRect modalFrameAnimate = modalFrameOriginal;
    if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
        modalFrameAnimate.origin.x += modalFrameAnimate.size.width;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.splitViewContainer.masterContainer.frame = masterFrameAnimate;
        self.splitViewContainer.detailContainer.frame = detailFrameAnimate;
        
        if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
            self.splitViewContainer.modalContainer.frame = modalFrameAnimate;
    } completion:^(BOOL fin){
        [self.splitViewContainer.view bringSubviewToFront:playerController.view];
        
        self.splitViewContainer.masterContainer.hidden = YES;
        self.splitViewContainer.detailContainer.hidden = YES;
        
        if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
            self.splitViewContainer.modalContainer.hidden = YES;
        
        self.splitViewContainer.masterContainer.frame = masterFrameOriginal;
        self.splitViewContainer.detailContainer.frame = detailFrameOriginal;
        
        if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
            self.splitViewContainer.modalContainer.frame = modalFrameOriginal;
    }];
}

#pragma mark - Settings

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape(orientation))
    {
        [self performSegueWithIdentifier:@"playerDetail" sender:self.playButton];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
    {
        if(self.unlockRotation)
            return UIInterfaceOrientationMaskAllButUpsideDown;
        else
            return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - Kill

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidReceiveData" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFinish" object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"enclosureDownloadDidFail" object:nil];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"posterDidChange" object:self.episode];
    
    [super viewWillDisappear:animated];
    self.unlockRotation = NO;
}

@end
