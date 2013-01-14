//
//  TWPlayerViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"

#import "TWPlayerViewController.h"
#import "TWSplitViewContainer.h"

#import "Show.h"
#import "Episode.h"
#import "Enclosure.h"

#define fastSpeed 1.5

@implementation TWPlayerViewController

- (void)viewDidLoad
{
    [self.qualityButton setTitle:self.enclosure.title forState:UIControlStateNormal];
    [self.qualityButton setBackgroundImage:[[self.qualityButton backgroundImageForState:UIControlStateNormal] stretchableImageWithLeftCapWidth:4 topCapHeight:4] forState:UIControlStateNormal];
    
    MPVolumeView *airplayButton = [[MPVolumeView alloc] init];
    airplayButton.frame = CGRectMake(-7, -2, 37, 37);
    airplayButton.showsVolumeSlider = NO;
    [self.airplayButtonView addSubview:airplayButton];
    self.airplayButtonView.backgroundColor = [UIColor clearColor];
    
    
    self.delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if(self.delegate.nowPlaying != self.enclosure)
    {
        if(self.delegate.player)
            [self.delegate stop];
        
        self.delegate.player = [[MPMoviePlayerController alloc] init];
        self.delegate.player.contentURL = [NSURL URLWithString:self.enclosure.url];
        self.delegate.player.initialPlaybackTime = self.enclosure.episode.lastTimecode;
        self.delegate.player.controlStyle = MPMovieControlStyleNone;
        self.delegate.player.shouldAutoplay = YES;
        self.delegate.player.allowsAirPlay = YES;
        self.delegate.player.scalingMode = MPMovieScalingModeAspectFit;
        
        if([MPNowPlayingInfoCenter class])
        {
            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.enclosure.episode.show.albumArt.image];
            NSDictionary *trackInfo = @{
                MPMediaItemPropertyAlbumTitle : self.enclosure.episode.show.title,
                MPMediaItemPropertyArtist : self.enclosure.episode.show.hosts,
                MPMediaItemPropertyArtwork : artwork,
                MPMediaItemPropertyGenre : @"Podcast",
                MPMediaItemPropertyTitle : self.enclosure.title
            };
            MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = trackInfo;
        }
        
        [self.delegate play];
    }
    
    self.delegate.nowPlaying = self.enclosure;
    
    self.delegate.player.view.frame = self.view.bounds;
    self.delegate.player.view.autoresizingMask = 63;
    [self.view addSubview:self.delegate.player.view];
    [self.view sendSubviewToBack:self.delegate.player.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.wantsFullScreenLayout = YES;
    [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    self.navigationController.navigationBar.tintColor = UIColor.blackColor;
    self.navigationController.navigationBar.translucent = YES;
    
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
        if(self.delegate.player.playbackState == MPMoviePlaybackStatePlaying)
        {
            self.playButton.selected = YES;
        }
        else
        {
            self.playButton.selected = NO;
        }
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

- (IBAction)rewind:(UIButton*)sender
{
    self.delegate.player.currentPlaybackTime -= 30;
}

- (IBAction)toggleSpeed:(UIButton*)sender
{
    if(!self.speedButton.selected)
    {
        self.delegate.player.currentPlaybackRate = fastSpeed;
        self.speedButton.selected = YES;
    }
    else
    {
        self.delegate.player.currentPlaybackRate = 1;
        self.speedButton.selected = NO;
    }
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
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

@end
