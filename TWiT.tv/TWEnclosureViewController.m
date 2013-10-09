//
//  TWEnclosureViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWAppDelegate.h"

#import "TWEnclosureViewController.h"
#import "TWSplitViewContainer.h"
#import "TWNavigationContainer.h"
#import "TWNavigationController.h"
#import "TWEpisodeViewController.h"

#import "Show.h"
#import "Episode.h"
#import "Enclosure.h"

#import "TWQualityCell.h"

#define fastSpeed 1.5

@implementation TWEnclosureViewController
{
    BOOL hideUI;
    UIColor *previousTint;
}

- (void)viewDidLoad
{
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        NSInteger count = self.navigationController.viewControllers.count;
        
        if(count < 2)
            return;
        
        UIViewController *lastViewController = self.navigationController.viewControllers[count-2];
        
        if([lastViewController isKindOfClass:NSClassFromString(@"TWMainViewController")])
        {
            UIImage *backIcon = [[UIImage imageNamed:@"navbar-back-twit-icon-trans"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            lastViewController.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithImage:backIcon
                                                                                                 style:UIBarButtonItemStyleBordered
                                                                                                target:nil action:nil];
        }
    }
    
    hideUI = NO;
    self.toolbarView.barStyle = UIBarStyleBlack;
    self.toasterView.barStyle = UIBarStyleBlack;
    self.toasterView.clipsToBounds = YES;
    self.toasterView.layer.cornerRadius = 7;
    self.timePopupView.barStyle = UIBarStyleBlack;
    self.timePopupView.clipsToBounds = YES;
    self.timePopupView.layer.cornerRadius = 7;
    
    MPVolumeView *airplayButton = [[MPVolumeView alloc] init];
    airplayButton.showsVolumeSlider = NO;
    airplayButton.frame = (CGRect){{0, (37-22)/2}, {38, 22}};
    [self.airplayButtonView addSubview:airplayButton];
    self.airplayButtonView.backgroundColor = [UIColor clearColor];
    
    [self.seekbar setMinimumTrackImage:[UIImage imageNamed:@"video-seekbar-back"] forState:UIControlStateNormal];
	[self.seekbar setMaximumTrackImage:[UIImage imageNamed:@"video-seekbar-back"] forState:UIControlStateNormal];
	[self.seekbar setThumbImage:[UIImage imageNamed:@"video-seekbar-thumb"] forState:UIControlStateNormal];
    
    self.seekbar.value = (self.enclosure.episode.duration != 0) ? (CGFloat)self.enclosure.episode.lastTimecode / self.enclosure.episode.duration : 0;
    
    self.titleLabel.font = [UIFont fontWithName:@"Vollkorn-BoldItalic" size:self.titleLabel.font.pointSize];
    self.titleLabel.text = self.enclosure.episode.show.title;
    self.subtitleLabel.text = self.enclosure.episode.title;
    
    self.delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if(!self.delegate.nowPlaying || ![self.delegate.nowPlaying isKindOfClass:Enclosure.class]
    || ([self.delegate.nowPlaying isKindOfClass:Enclosure.class] && [self.delegate.nowPlaying episode] != self.enclosure.episode))
    {
        self.delegate.nowPlaying = self.enclosure;
        
        MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = @{
            MPMediaItemPropertyAlbumTitle : self.enclosure.episode.show.title,
            MPMediaItemPropertyArtist : self.enclosure.episode.show.hosts,
            MPMediaItemPropertyArtwork : [[MPMediaItemArtwork alloc] initWithImage:self.enclosure.episode.show.albumArt.image],
            MPMediaItemPropertyGenre : @"Podcast",
            MPMediaItemPropertyTitle : self.enclosure.episode.title,
            MPMediaItemPropertyMediaType : self.enclosure.type == TWTypeAudio ? @(MPMediaTypePodcast) : @(MPMediaTypeVideoPodcast)
        };
    }
    else
    {
        [self updateSeekbar];
        self.toasterView.hidden = YES;
        [self.spinner stopAnimating];
        self.infoView.hidden = self.delegate.player.airPlayVideoActive ? NO : (self.enclosure.type == TWTypeVideo);
    }
    
    self.enclosure = self.delegate.nowPlaying;
    
    [self drawLabelsWithTime:self.enclosure.episode.lastTimecode andDuration:self.enclosure.episode.duration];
    
    self.infoAlbumArtView.image = self.enclosure.type == TWTypeAudio
                                ? self.enclosure.episode.show.albumArt.image
                                : self.enclosure.episode.poster.image;
    
    [self.qualityButton setTitle:self.enclosure.title forState:UIControlStateNormal];
    
    
    [self.view addSubview:self.delegate.player.view];
    [self.view sendSubviewToBack:self.delegate.player.view];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.delegate.player.view
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1
                                                                   constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.delegate.player.view
                                                                  attribute:NSLayoutAttributeRight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeRight
                                                                 multiplier:1
                                                                 constant:0];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.delegate.player.view
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1
                                                                 constant:0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.delegate.player.view
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1
                                                                 constant:0];
    
    [self.view addConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapPlayer:)];
    tap.delegate = self;
    [self.delegate.player.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.splitViewContainer hidePlaybar];
    TWNavigationController *navigationController = (TWNavigationController*)self.navigationController;
    [navigationController.navigationContainer hidePlaybar];

    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        previousTint = self.navigationController.navigationBar.tintColor;
        self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
        self.navigationController.navigationBar.tintColor = UIColor.whiteColor;
    }
    
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
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(playerStateChanged:)
                                               name:MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification
                                             object:self.delegate.player];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return hideUI;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

#pragma mark - Notifications

- (void)playerStateChanged:(NSNotification*)notification
{
    if([notification.name isEqualToString:@"MPMoviePlayerLoadStateDidChangeNotification"])
    {
        if(self.delegate.player.loadState == MPMovieLoadStatePlayable || self.delegate.player.loadState == MPMovieLoadStatePlaythroughOK)
        {
            self.toasterView.hidden = YES;
            [self.spinner stopAnimating];
            self.infoView.hidden = self.delegate.player.airPlayVideoActive ? NO : (self.enclosure.type == TWTypeVideo);
        }
    }
    else if([notification.name isEqualToString:@"MPMoviePlayerPlaybackStateDidChangeNotification"])
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
    else if([notification.name isEqualToString:@"MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification"])
    {
        self.infoView.hidden = self.delegate.player.airPlayVideoActive ? NO : (self.enclosure.type == TWTypeVideo);
        self.delegate.player.view.hidden = self.delegate.player.airPlayVideoActive;
    }
    else if([notification.name isEqualToString:@"MPMoviePlayerPlaybackDidFinishNotification"]
    && [[notification.userInfo objectForKey:@"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"] intValue] != 0)
    {
        TWQuality quality = (TWQuality)(((NSInteger)self.enclosure.quality) - 1);
        
        if(quality >= 0)
        {
            Enclosure *enclosure = [self.enclosure.episode enclosureForQuality:quality];
            
            if(enclosure)
            {
                self.enclosure = enclosure;
                self.delegate.nowPlaying = enclosure;
                
                self.infoView.hidden = NO;
                self.infoAlbumArtView.image = (self.enclosure.type == TWTypeAudio) ? self.enclosure.episode.show.albumArt.image : self.enclosure.episode.poster.image;
                [self.qualityButton setTitle:enclosure.title forState:UIControlStateNormal];
                return;
            }
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Unable to load the episode." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [alert show];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self close:nil];
}

- (void)updateSeekbar
{
    if(!self.seekbar.highlighted && self.delegate.player.currentPlaybackTime != NAN
    && self.delegate.player.duration != NAN && self.delegate.player.duration > 0)
    {
        self.seekbar.value = self.delegate.player.currentPlaybackTime / self.delegate.player.duration;
        [self drawLabelsWithTime:self.delegate.player.currentPlaybackTime andDuration:self.delegate.player.duration];
    }
    
    if(self.delegate.player.playbackState == MPMoviePlaybackStatePlaying)
        [self performSelector:@selector(updateSeekbar) withObject:nil afterDelay:1];
}

- (void)drawLabelsWithTime:(NSInteger)time andDuration:(NSInteger)duration
{
    NSInteger seconds = time % 60;
    NSInteger minutes = (time / 60) % 60;
    NSInteger hours = (time / 3600);
    self.timeElapsedLabel.text = [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
    self.timePopupLabel.text = self.timeElapsedLabel.text;
    
    NSInteger remaining = duration-time;
    seconds = remaining % 60;
    minutes = (remaining / 60) % 60;
    hours = (remaining / 3600);
    self.timeRemainingLabel.text = [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
    
    CGFloat rate = self.speedButton.selected ? fastSpeed : 1;
    CGFloat secondsLeft = remaining/rate;
    NSDate *endingTime = [[NSDate date] dateByAddingTimeInterval:secondsLeft];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"h:mma";
    dateFormat.PMSymbol = @"p";
    dateFormat.AMSymbol = @"a";
    NSString *timeString = [dateFormat stringFromDate:endingTime];
    self.timeOfEndLabel.text = [NSString stringWithFormat:@"ends @ %@", timeString];
    
    MPNowPlayingInfoCenter *center = MPNowPlayingInfoCenter.defaultCenter;
    NSMutableDictionary *playingInfo = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo];
    playingInfo[MPMediaItemPropertyPlaybackDuration] = @(self.delegate.player.duration);
    playingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.delegate.player.currentPlaybackTime);
    center.nowPlayingInfo = playingInfo;
}

#pragma mark - gesture delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Actions

- (void)userDidTapPlayer:(UIGestureRecognizer*)sender
{
    if(self.infoView.hidden)
        [self hideControls:!hideUI];
    else
        [self play:nil];
}

- (void)hideControls:(BOOL)hide
{
    if(hide == hideUI)
        return;
    
    if(hide)
    {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.navigationController.navigationBar.alpha = 0;
            
            self.navigationBar.alpha = 0;
            self.toolbarView.alpha = 0;
        } completion:^(BOOL fin){
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            
            [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
                hideUI = hide;
                [self setNeedsStatusBarAppearanceUpdate];
            } completion:nil];
        }];
    }
    else
    {
        hideUI = hide;
        
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:nil];
            
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        self.navigationController.navigationBar.alpha = 0;
        
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.navigationController.navigationBar.alpha = 1;
            
            self.navigationBar.alpha = 1;
            self.toolbarView.alpha = 1;
        } completion:nil];
    }
}

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
    [self updateSeekbar];
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

- (IBAction)openQualityPopover:(UIButton*)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Video Quality"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];

    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"quality" ascending:NO];
    NSArray *sortedEnclosures = [self.enclosure.episode.enclosures sortedArrayUsingDescriptors:@[descriptor]];

    for(Enclosure *enclosure in sortedEnclosures)
    {
        NSString *prefix = (enclosure == self.enclosure) ? @"✓" : @"";
        [sheet addButtonWithTitle:[NSString stringWithFormat:@"%@ %@ - %@", prefix, enclosure.title, enclosure.subtitle]];
    }
    
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    
    [sheet showFromRect:CGRectMake(self.qualityButton.frame.size.width/2.0, 0, 1, 1) inView:self.qualityButton animated:YES];
}
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == -1 || buttonIndex >= actionSheet.numberOfButtons-1)
        return;
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"quality" ascending:NO];
    NSArray *enclosures = [self.enclosure.episode.enclosures sortedArrayUsingDescriptors:@[descriptor]];
    Enclosure *enclosure = enclosures[buttonIndex];
    
    if(enclosure == self.enclosure)
        return;
    
    self.toasterView.hidden = NO;
    [self.spinner startAnimating];
    
    NSTimeInterval startTime = self.delegate.player.currentPlaybackTime;
    
    self.enclosure = enclosure;
    self.delegate.nowPlaying = enclosure;
    
    self.delegate.player.initialPlaybackTime = startTime;
    
    self.infoView.hidden = NO;
    self.infoAlbumArtView.image = (self.enclosure.type == TWTypeAudio)
                                ? self.enclosure.episode.show.albumArt.image
                                : self.enclosure.episode.poster.image;
    [self.qualityButton setTitle:enclosure.title forState:UIControlStateNormal];
}

- (IBAction)seekStart:(UISlider*)sender
{
    self.timePopupView.alpha = 0;
    self.timePopupView.hidden = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.timePopupView.alpha = 1;
    }];
}
- (IBAction)seeking:(UISlider*)sender
{
    NSInteger newPlaybackTime = self.seekbar.value * self.delegate.player.duration;
    [self drawLabelsWithTime:newPlaybackTime andDuration:self.delegate.player.duration];
}
- (IBAction)seekEnd:(UISlider*)sender
{
    [UIView animateWithDuration:0.3f animations:^{
        self.timePopupView.alpha = 0;
    } completion:^(BOOL fin){
        self.timePopupView.hidden = YES;
    }];
    
    self.delegate.player.currentPlaybackTime = self.delegate.player.duration * self.seekbar.value;
}

#pragma mark - Rotate

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    if(self.enclosure.type != TWTypeAudio)
        [self hideControls:!UIInterfaceOrientationIsPortrait(orientation)];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - Leave

- (IBAction)close:(UIBarButtonItem*)sender
{
    if([self.presentingViewController isKindOfClass:TWSplitViewContainer.class])
        self.splitViewContainer = (TWSplitViewContainer*)self.presentingViewController;
    
    [self dismissViewControllerAnimated:YES completion:^{
        if(self.delegate.player.playbackState == MPMoviePlaybackStatePlaying)
            [self.splitViewContainer showPlaybar];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    [NSNotificationCenter.defaultCenter addObserver:self.enclosure.episode
                                           selector:@selector(updatePoster:)
                                               name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                             object:nil];
    [self.delegate.player requestThumbnailImagesAtTimes:@[@(self.delegate.player.currentPlaybackTime)] timeOption:MPMovieTimeOptionNearestKeyFrame];
    
    self.enclosure.episode.lastTimecode = self.delegate.player.currentPlaybackTime;
    
    if(self.delegate.player.currentPlaybackTime / self.delegate.player.duration >= 0.85f)
        self.enclosure.episode.watched = YES;

    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.tintColor = previousTint;
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                object:self.delegate.player];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification
                                                object:self.delegate.player];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification
                                                object:self.delegate.player];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification
                                                object:self.delegate.player];
    
    if(self.delegate.player.playbackState == MPMoviePlaybackStatePlaying)
    {
        TWNavigationController *navigationController = (TWNavigationController*)self.navigationController;
        [navigationController.navigationContainer showPlaybar];
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if(self.delegate.player.playbackState != MPMoviePlaybackStatePlaying)
        [self.delegate stop];

    [super viewDidDisappear:animated];
}

@end
