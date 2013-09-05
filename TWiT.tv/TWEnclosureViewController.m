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

- (void)viewDidLoad
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        int count = self.navigationController.viewControllers.count;
        
        if(count < 2)
            return;
        
        UIViewController *lastViewController = self.navigationController.viewControllers[count-2];
        
        if([lastViewController isKindOfClass:NSClassFromString(@"TWMainViewController")])
        {
            UIImage *buttonIcon = [UIImage imageNamed:@"navbar-back-twit-icon-trans.png"];
            lastViewController.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithImage:buttonIcon
                                                                                                 style:UIBarButtonItemStyleBordered
                                                                                                target:nil action:nil];
        }
    }
    
    MPVolumeView *airplayButton = [[MPVolumeView alloc] init];
    airplayButton.showsVolumeSlider = NO;
    airplayButton.frame = (CGRect){{0, (37-22)/2}, {38, 22}};
    [self.airplayButtonView addSubview:airplayButton];
    self.airplayButtonView.backgroundColor = [UIColor clearColor];
    
    [self.seekbar setMinimumTrackImage:[[UIImage imageNamed:@"video-seekbar-back.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:3] forState:UIControlStateNormal];
	[self.seekbar setMaximumTrackImage:[[UIImage imageNamed:@"video-seekbar-back.png"] stretchableImageWithLeftCapWidth:3 topCapHeight:3] forState:UIControlStateNormal];
	[self.seekbar setThumbImage:[UIImage imageNamed:@"video-seekbar-thumb.png"] forState:UIControlStateNormal];
    
    self.seekbar.value = (self.enclosure.episode.duration != 0) ? (float)self.enclosure.episode.lastTimecode / self.enclosure.episode.duration : 0;
    
    self.titleLabel.font = [UIFont fontWithName:@"Vollkorn-BoldItalic" size:self.titleLabel.font.pointSize];
    self.titleLabel.text = self.enclosure.episode.show.title;
    self.subtitleLabel.text = self.enclosure.episode.title;
    
    self.toasterView.layer.cornerRadius = 6;
    
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
            MPMediaItemPropertyTitle : self.enclosure.episode.title
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
    
    self.infoAlbumArtView.image = (self.enclosure.type == TWTypeAudio) ? self.enclosure.episode.show.albumArt.image : self.enclosure.episode.poster.image;
    
    [self.qualityButton setTitle:self.enclosure.title forState:UIControlStateNormal];
    UIImage *qualityImage = [self.qualityButton backgroundImageForState:UIControlStateNormal];
    qualityImage = [qualityImage resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 5, 4)];
    [self.qualityButton setBackgroundImage:qualityImage forState:UIControlStateNormal];
    
    self.delegate.player.view.frame = self.view.bounds;
    self.delegate.player.view.autoresizingMask = 63;
    [self.view addSubview:self.delegate.player.view];
    [self.view sendSubviewToBack:self.delegate.player.view];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapPlayer:)];
    UIView *tapView = [[UIView alloc] initWithFrame:self.delegate.player.view.bounds];
    [tapView setAutoresizingMask:63];
    [tapView addGestureRecognizer:tap];
    [self.delegate.player.view addSubview:tapView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.splitViewContainer hidePlaybar];
    TWNavigationController *navigationController = (TWNavigationController*)self.navigationController;
    [navigationController.navigationContainer hidePlaybar];

    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
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

#pragma mark - Notifications

- (void)playerStateChanged:(NSNotification*)notification
{
    if([notification.name isEqualToString:@"MPMoviePlayerLoadStateDidChangeNotification"])
    {
        if(self.delegate.player.loadState != MPMovieLoadStateUnknown)
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
        TWQuality quality = (TWQuality)(((int)self.enclosure.quality) - 1);
        
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
    
    NSInteger remaining = duration-time;
    seconds = remaining % 60;
    minutes = (remaining / 60) % 60;
    hours = (remaining / 3600);
    self.timeRemainingLabel.text = [NSString stringWithFormat:@"%01i:%02i:%02i", hours, minutes, seconds];
    
    float rate = self.speedButton.selected ? fastSpeed : 1;
    float secondsLeft = remaining/rate;
    NSDate *endingTime = [[NSDate date] dateByAddingTimeInterval:secondsLeft];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"h:mma";
    dateFormat.PMSymbol = @"p";
    dateFormat.AMSymbol = @"a";
    NSString *timeString = [dateFormat stringFromDate:endingTime];
    self.timeOfEndLabel.text = [NSString stringWithFormat:@"ends @ %@", timeString];
}

#pragma mark - Actions

- (void)userDidTapPlayer:(UIGestureRecognizer*)sender
{
    if(self.infoView.hidden)
        [self hideControls:!self.toolbarView.hidden];
    else
        [self play:nil];
}

- (void)hideControls:(BOOL)hide
{
    if(hide == self.toolbarView.hidden)
        return;
    
    [UIApplication.sharedApplication setStatusBarHidden:hide withAnimation:UIStatusBarAnimationFade];
    
    if(!hide)
    {
        self.navigationController.navigationBar.alpha = 0;
        self.navigationBar.alpha = 0;
        self.toolbarView.alpha = 0;
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        self.navigationBar.hidden = NO;
        self.toolbarView.hidden = NO;
        
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0 options:UIViewAnimationCurveEaseIn animations:^{
            
            if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
                self.view.window.rootViewController.view.frame = UIScreen.mainScreen.applicationFrame;
            
            self.navigationController.navigationBar.alpha = 1;
            self.navigationBar.alpha = 1;
            self.toolbarView.alpha = 1;
        } completion:^(BOOL fin){
        }];
    }
    else
    {
        if(!self.qualityView.hidden)
            [self openQualityPopover:nil];
        
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:0 options:UIViewAnimationCurveEaseOut animations:^{
            self.navigationController.navigationBar.alpha = 0;
            self.navigationBar.alpha = 0;
            self.toolbarView.alpha = 0;
        } completion:^(BOOL fin){
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            self.navigationBar.hidden = YES;
            self.toolbarView.hidden = YES;
        }];
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
    if(self.qualityView.hidden)
    {
        CGRect frame = self.qualityView.frame;
        frame.size.height = 44*self.enclosure.episode.enclosures.count + 4;
        CGRect buttonFrame = [sender convertRect:sender.frame toView:self.qualityView.superview];
        frame.origin.y = buttonFrame.origin.y - frame.size.height;
        self.qualityView.frame = frame;
        
        self.qualityView.alpha = 0;
        self.qualityView.hidden = NO;
        [UIView animateWithDuration:0.3f animations:^{
            self.qualityView.alpha = 1;
        }];
    }
    else
    {
        [UIView animateWithDuration:0.3f animations:^{
            self.qualityView.alpha = 0;
        } completion:^(BOOL fin){
            self.qualityView.hidden = YES;
            self.qualityView.alpha = 1;
        }];
    }
}


- (IBAction)seekStart:(UISlider*)sender
{
}
- (IBAction)seeking:(UISlider*)sender
{
    NSInteger newPlaybackTime = self.seekbar.value * self.delegate.player.duration;
    [self drawLabelsWithTime:newPlaybackTime andDuration:self.delegate.player.duration];
}
- (IBAction)seekEnd:(UISlider*)sender
{
    self.delegate.player.currentPlaybackTime = self.delegate.player.duration * self.seekbar.value;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    self.toasterView.hidden = NO;
    [self.spinner startAnimating];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.qualityView.alpha = 0;
    } completion:^(BOOL fin) {
        self.qualityView.hidden = YES;
        self.qualityView.alpha = 1;
    }];
    
    TWQualityCell *cell = (TWQualityCell*)[tableView cellForRowAtIndexPath:indexPath];
    Enclosure *enclosure = (Enclosure*)cell.source;
    
    if(enclosure == self.enclosure)
        return;
    
    NSTimeInterval startTime = self.delegate.player.currentPlaybackTime;
    
    self.enclosure = enclosure;
    self.delegate.nowPlaying = enclosure;
    
    self.delegate.player.initialPlaybackTime = startTime;
    
    self.infoView.hidden = NO;
    self.infoAlbumArtView.image = (self.enclosure.type == TWTypeAudio) ? self.enclosure.episode.show.albumArt.image : self.enclosure.episode.poster.image;
    [self.qualityButton setTitle:enclosure.title forState:UIControlStateNormal];
}

#pragma mark - Quality Table

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.enclosure.episode.enclosures.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *identifier = @"qualityCell";
    TWQualityCell *cell = (TWQualityCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"quality" ascending:NO];
    NSArray *sortedEnclosures = [self.enclosure.episode.enclosures sortedArrayUsingDescriptors:@[descriptor]];
    Enclosure *enclosure = sortedEnclosures[indexPath.row];
    
    cell.source = enclosure;
    
    cell.topLine.hidden = (indexPath.row == 0);
    cell.bottomLine.hidden = (indexPath.row == sortedEnclosures.count-1);
    
    if(enclosure == self.enclosure)
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    return cell;
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
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    }
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIApplication.sharedApplication setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
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
        [self.splitViewContainer showPlaybar];
        
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
