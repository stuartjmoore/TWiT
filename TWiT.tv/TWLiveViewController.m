//
//  TWLiveViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/15/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"

#import "TWLiveViewController.h"
#import "TWSplitViewContainer.h"

#import "Channel.h"
#import "Stream.h"

@implementation TWLiveViewController

- (void)viewDidLoad
{
    [self.qualityButton setTitle:self.stream.title forState:UIControlStateNormal];
    [self.qualityButton setBackgroundImage:[[self.qualityButton backgroundImageForState:UIControlStateNormal] stretchableImageWithLeftCapWidth:4 topCapHeight:4] forState:UIControlStateNormal];
    
    MPVolumeView *airplayButton = [[MPVolumeView alloc] init];
    airplayButton.frame = CGRectMake(-7, -2, 37, 37);
    airplayButton.showsVolumeSlider = NO;
    [self.airplayButtonView addSubview:airplayButton];
    self.airplayButtonView.backgroundColor = [UIColor clearColor];
    
    self.titleLabel.font = [UIFont fontWithName:@"Vollkorn-BoldItalic" size:self.titleLabel.font.pointSize];
    self.titleLabel.text = self.stream.channel.title;
    
    Event *currentShow = self.stream.channel.schedule.currentShow;
    if(currentShow)
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@", currentShow.until, currentShow.title];
    else
        self.subtitleLabel.text = @"with Leo Laporte";
    
    self.delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if(self.delegate.nowPlaying != self.stream)
    {
        if(self.delegate.player)
            [self.delegate stop];
        
        self.delegate.player = [[MPMoviePlayerController alloc] init];
        self.delegate.player.contentURL = [NSURL URLWithString:self.stream.url];
        self.delegate.player.controlStyle = MPMovieControlStyleNone;
        self.delegate.player.shouldAutoplay = YES;
        self.delegate.player.allowsAirPlay = YES;
        self.delegate.player.scalingMode = MPMovieScalingModeAspectFit;
        /*
        if([MPNowPlayingInfoCenter class])
        {
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"generic.png"]];
            NSDictionary *trackInfo = @{
            MPMediaItemPropertyAlbumTitle : self.stream.channel.title,
            //MPMediaItemPropertyArtist : self.stream.channel.hosts,
            MPMediaItemPropertyArtwork : artwork,
            MPMediaItemPropertyGenre : @"Podcast",
            MPMediaItemPropertyTitle : self.stream.channel.schedule.currentShow.title
            };
            MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = trackInfo;
        }
        */
        [self.delegate play];
    }
    
    self.delegate.nowPlaying = self.stream;
    
    self.delegate.player.view.frame = self.view.bounds;
    self.delegate.player.view.autoresizingMask = 63;
    [self.view addSubview:self.delegate.player.view];
    [self.view sendSubviewToBack:self.delegate.player.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.wantsFullScreenLayout = YES;
    self.navigationController.navigationBar.tintColor = UIColor.blackColor;
    self.navigationController.navigationBar.translucent = YES;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(playerStateChanged:)
                                               name:MPMoviePlayerPlaybackStateDidChangeNotification
                                             object:self.delegate.player];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(playerStateChanged:)
                                               name:MPMoviePlayerLoadStateDidChangeNotification
                                             object:self.delegate.player];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(playerStateChanged:)
                                               name:MPMoviePlayerPlaybackDidFinishNotification
                                             object:self.delegate.player];
}

#pragma mark - Notifications

- (void)playerStateChanged:(NSNotification*)notification
{
    if([notification.name isEqualToString:@"MPMoviePlayerLoadStateDidChangeNotification"])
    {
        if(self.delegate.player.loadState != MPMovieLoadStateUnknown)
        {
        }
    }
    
    if([notification.name isEqualToString:@"MPMoviePlayerPlaybackStateDidChangeNotification"])
    {
        self.playButton.selected = (self.delegate.player.playbackState == MPMoviePlaybackStatePlaying);
    }
    
    if([notification.name isEqualToString:@"MPMoviePlayerPlaybackDidFinishNotification"])
    {
        if([[notification.userInfo objectForKey:@"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"] intValue] == 0)
            return;
    }
}

#pragma mark - Actions

- (IBAction)play:(UIButton*)sender
{
    if(self.delegate.player.playbackState == MPMoviePlaybackStatePlaying)
    {
        [self.delegate pause];
    }
    else
    {
        [self.delegate play];
    }
}

- (IBAction)openChatView:(UIButton*)sender
{
    
}

- (IBAction)openQualityPopover:(UIButton*)sender
{
    
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
    CGRect masterFrameOriginal = self.splitViewContainer.masterContainer.frame;
    CGRect masterFrameAnimate = masterFrameOriginal;
    masterFrameAnimate.origin.x -= masterFrameAnimate.size.width;
    self.splitViewContainer.masterContainer.frame = masterFrameAnimate;
    
    CGRect detailFrameOriginal = self.splitViewContainer.detailContainer.frame;
    CGRect detailFrameAnimate = detailFrameOriginal;
    detailFrameAnimate.origin.x += detailFrameAnimate.size.width;
    self.splitViewContainer.detailContainer.frame = detailFrameAnimate;
    
    CGRect modalFrameOriginal = self.splitViewContainer.modalContainer.frame;
    CGRect modalFrameAnimate = modalFrameOriginal;
    modalFrameAnimate.origin.x += modalFrameAnimate.size.width;
    if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
        self.splitViewContainer.modalContainer.frame = modalFrameAnimate;
    
    [self.splitViewContainer.view sendSubviewToBack:self.view];
    
    self.splitViewContainer.masterContainer.hidden = NO;
    self.splitViewContainer.detailContainer.hidden = NO;
    
    if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
        self.splitViewContainer.modalContainer.hidden = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.splitViewContainer.masterContainer.frame = masterFrameOriginal;
        self.splitViewContainer.detailContainer.frame = detailFrameOriginal;
        
        if(self.splitViewContainer.modalFlyout.frame.origin.x == 0)
            self.splitViewContainer.modalContainer.frame = modalFrameOriginal;
    } completion:^(BOOL fin){
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if(self.delegate.player.playbackState != MPMoviePlaybackStatePlaying)
        [self.delegate stop];
    
    //[self.enclosure.managedObjectContext save:nil];
    
    self.wantsFullScreenLayout = NO;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.18 green:0.44 blue:0.57 alpha:1.0];
    self.navigationController.navigationBar.translucent = NO;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [super viewWillDisappear:animated];
}

@end
