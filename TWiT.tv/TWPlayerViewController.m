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
#import "TWEpisodeViewController.h"

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
    
    [self.seekbar setMinimumTrackImage:[[UIImage imageNamed:@"video-seekbar-back.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:3] forState:UIControlStateNormal];
	[self.seekbar setMaximumTrackImage:[[UIImage imageNamed:@"video-seekbar-back.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:3] forState:UIControlStateNormal];
	[self.seekbar setThumbImage:[UIImage imageNamed:@"video-seekbar-thumb.png"] forState:UIControlStateNormal];
    
    self.seekbar.value = (self.enclosure.episode.duration != 0) ? (float)self.enclosure.episode.lastTimecode / self.enclosure.episode.duration : 0;
    
    self.titleLabel.font = [UIFont fontWithName:@"Vollkorn-BoldItalic" size:self.titleLabel.font.pointSize];
    self.titleLabel.text = self.enclosure.episode.show.title;
    self.subtitleLabel.text = self.enclosure.episode.title;
    
    
    self.delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if(self.delegate.nowPlaying != self.enclosure)
    {
        if(self.delegate.player)
            [self.delegate stop];
        
        NSURL *url = self.enclosure.path ? [NSURL fileURLWithPath:self.enclosure.path] : [NSURL URLWithString:self.enclosure.url];
        
        self.delegate.player = [[MPMoviePlayerController alloc] init];
        self.delegate.player.contentURL = url;
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
    else
    {
        [self updateSeekbar];
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
        if(self.delegate.player.playbackState == MPMoviePlaybackStatePlaying)
        {
            self.playButton.selected = YES;
            [self updateSeekbar];
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

- (void)updateSeekbar
{
    if(!self.seekbar.highlighted && self.delegate.player.currentPlaybackTime != NAN
    && self.delegate.player.duration != NAN && self.delegate.player.duration > 0)
    {
        self.seekbar.value = self.delegate.player.currentPlaybackTime / self.delegate.player.duration;
        
        NSInteger playbackTime = self.delegate.player.currentPlaybackTime;
        NSInteger seconds = playbackTime % 60;
        NSInteger minutes = (playbackTime / 60) % 60;
        NSInteger hours = (playbackTime / 3600);
        self.timeElapsedLabel.text = [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
        
        NSInteger remaining = self.delegate.player.duration-playbackTime;
        seconds = remaining % 60;
        minutes = (remaining / 60) % 60;
        hours = (remaining / 3600);
        self.timeRemainingLabel.text = [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
        
        float rate = self.speedButton.selected ? fastSpeed : 1;
        float secondsLeft = (self.delegate.player.duration-self.delegate.player.currentPlaybackTime)/rate;
        NSDate *endingTime = [[NSDate date] dateByAddingTimeInterval:secondsLeft];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"h:mm"];
        [self.timeOfEndLabel setText:[NSString stringWithFormat:@"ends @ %@",[dateFormat stringFromDate:endingTime]]];
    }
    
    if(self.delegate.player.playbackState == MPMoviePlaybackStatePlaying)
        [self performSelector:@selector(updateSeekbar) withObject:nil afterDelay:1];
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


- (IBAction)seekStart:(UISlider*)sender
{
}
- (IBAction)seeking:(UISlider*)sender
{
    NSInteger newPlaybackTime = self.seekbar.value * self.delegate.player.duration;
    
    NSInteger seconds = newPlaybackTime % 60;
    NSInteger minutes = (newPlaybackTime / 60) % 60;
    NSInteger hours = (newPlaybackTime / 3600);
    self.timeElapsedLabel.text = [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
    
    NSInteger remaining = self.delegate.player.duration-newPlaybackTime;
    seconds = remaining % 60;
    minutes = (remaining / 60) % 60;
    hours = (remaining / 3600);
    self.timeRemainingLabel.text = [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
    
    float rate = self.speedButton.selected ? fastSpeed : 1;
    float secondsLeft = (self.delegate.player.duration-newPlaybackTime)/rate;
    NSDate *endingTime = [[NSDate date] dateByAddingTimeInterval:secondsLeft];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"h:mm"];
    self.timeOfEndLabel.text = [NSString stringWithFormat:@"ends @ %@", [dateFormat stringFromDate:endingTime]];
}
- (IBAction)seekEnd:(UISlider*)sender
{
    self.delegate.player.currentPlaybackTime = self.delegate.player.duration * self.seekbar.value;
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
        [(TWEpisodeViewController*)self.splitViewContainer.modalController.topViewController configureView];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.enclosure.episode.lastTimecode = self.delegate.player.currentPlaybackTime;
    
    if(self.delegate.player.currentPlaybackTime / self.delegate.player.duration >= 0.85f)
        self.enclosure.episode.watched = YES;
    
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
