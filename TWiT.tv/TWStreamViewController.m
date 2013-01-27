//
//  TWStreamViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/15/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"

#import "TWStreamViewController.h"
#import "TWNavigationContainer.h"
#import "TWNavigationController.h"
#import "TWSplitViewContainer.h"
#import "TWQualityCell.h"

#import "Channel.h"
#import "Stream.h"
#import "Show.h"
#import "Episode.h"
#import "Enclosure.h"

@implementation TWStreamViewController

- (void)viewDidLoad
{
    MPVolumeView *airplayButton = [[MPVolumeView alloc] init];
    airplayButton.showsVolumeSlider = NO;
    airplayButton.frame = (CGRect){{0, (37-22)/2}, {38, 22}};
    [self.airplayButtonView addSubview:airplayButton];
    self.airplayButtonView.backgroundColor = [UIColor clearColor];
    
    self.titleLabel.font = [UIFont fontWithName:@"Vollkorn-BoldItalic" size:self.titleLabel.font.pointSize];
    [self updateTitle];
    
    self.delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    
    if(!self.delegate.nowPlaying || ![self.delegate.nowPlaying isKindOfClass:Stream.class]
    || ([self.delegate.nowPlaying isKindOfClass:Stream.class] && [self.delegate.nowPlaying channel] != self.stream.channel))
    {
        self.delegate.nowPlaying = self.stream;
    }
    
    self.stream = self.delegate.nowPlaying;
    
    self.infoView.hidden = (self.stream.type != TWTypeAudio);
    
    [self.qualityButton setTitle:self.stream.title forState:UIControlStateNormal];
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
    
    self.wantsFullScreenLayout = YES;
    self.navigationController.navigationBar.translucent = YES;
    
    UIImage *navigationBarImage = [UIImage imageNamed:@"video-navbar-back.png"];
    [self.navigationBar setBackgroundImage:navigationBarImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBackgroundImage:navigationBarImage forBarMetrics:UIBarMetricsDefault];
    UIImage *backButtonImage = [[UIImage imageNamed:@"video-navbar-backbutton.png"] stretchableImageWithLeftCapWidth:14 topCapHeight:15];
    [UIBarButtonItem.appearance setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)updateTitle
{
    self.titleLabel.text = self.stream.channel.title;
    
    Event *currentShow = self.stream.channel.schedule.currentShow;
    if(currentShow)
    {
        NSString *untilString = currentShow.until;
        self.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@", untilString, currentShow.title];
        
        if(currentShow.show)
            self.infoAlbumArtView.image = currentShow.show.albumArt.image;
        else
            self.infoAlbumArtView.image = [UIImage imageNamed:@"generic.jpg"];
        
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTitle) object:nil];
        
        if([untilString hasSuffix:@"m"])
            [self performSelector:@selector(updateTitle) withObject:nil afterDelay:60];
        else if([untilString isEqualToString:@"Pre-show"])
            [self performSelector:@selector(updateTitle) withObject:nil afterDelay:currentShow.start.timeIntervalSinceNow];
        else if([untilString isEqualToString:@"Live"])
            [self performSelector:@selector(updateTitle) withObject:nil afterDelay:currentShow.end.timeIntervalSinceNow];
    }
    else
    {
        self.subtitleLabel.text = @"with Leo Laporte";
        self.infoAlbumArtView.image = [UIImage imageNamed:@"generic.jpg"];
    }
    
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = @{
        MPMediaItemPropertyAlbumTitle : self.titleLabel.text,
        MPMediaItemPropertyArtist : @"",
        MPMediaItemPropertyArtwork : [[MPMediaItemArtwork alloc] initWithImage:self.infoAlbumArtView.image],
        MPMediaItemPropertyGenre : @"Live",
        MPMediaItemPropertyTitle : self.subtitleLabel.text
    };
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
    
    if([notification.name isEqualToString:@"MPMoviePlayerPlaybackDidFinishNotification"]
    && [[notification.userInfo objectForKey:@"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"] intValue] != 0)
    {
        TWQuality quality = (TWQuality)(((int)self.stream.quality) - 1);

        if(quality >= 0)
        {
            Stream *stream = [self.stream.channel streamForQuality:quality];
            
            if(stream)
            {
                self.stream = stream;
                self.delegate.nowPlaying = stream;
                
                self.infoView.hidden = (stream.type != TWTypeAudio);
                [self.qualityButton setTitle:stream.title forState:UIControlStateNormal];
                return;
            }
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Unable to load the live stream." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [alert show];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        [self close:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Actions

- (void)userDidTapPlayer:(UIGestureRecognizer*)sender
{
    if(self.stream.type != TWTypeAudio)
        [self hideControls:!self.toolbarView.hidden];
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

- (IBAction)openChatView:(UIButton*)sender
{
    
}

- (IBAction)openQualityPopover:(UIButton*)sender
{
    if(self.qualityView.hidden)
    {
        CGRect frame = self.qualityView.frame;
        frame.size.height = 44*self.stream.channel.streams.count + 4;
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

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [UIView animateWithDuration:0.3f animations:^{
        self.qualityView.alpha = 0;
    } completion:^(BOOL fin) {
        self.qualityView.hidden = YES;
        self.qualityView.alpha = 1;
    }];
    
    TWQualityCell *cell = (TWQualityCell*)[tableView cellForRowAtIndexPath:indexPath];
    Stream *stream = (Stream*)cell.source;
    
    if(stream == self.stream)
        return;
    
    self.stream = stream;
    self.delegate.nowPlaying = stream;
    
    self.infoView.hidden = (stream.type != TWTypeAudio);
    [self.qualityButton setTitle:stream.title forState:UIControlStateNormal];
}

#pragma mark - Quality Table

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.stream.channel.streams.count;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *identifier = @"qualityCell";
    TWQualityCell *cell = (TWQualityCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"quality" ascending:NO];
    NSArray *sortedStreams = [self.stream.channel.streams sortedArrayUsingDescriptors:@[descriptor]];
    Stream *stream = sortedStreams[indexPath.row];
    
    cell.source = stream;
    
    cell.topLine.hidden = (indexPath.row == 0);
    cell.bottomLine.hidden = (indexPath.row == sortedStreams.count-1);
    
    if(stream == self.stream)
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    return cell;
}

#pragma mark - Rotate

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    if(self.stream.type != TWTypeAudio)
        [self hideControls:!UIInterfaceOrientationIsPortrait(orientation)];
}

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
    self.wantsFullScreenLayout = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    UIImage *navigationBarImage = [UIImage imageNamed:@"navbar-background.png"];
    [self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBackgroundImage:navigationBarImage forBarMetrics:UIBarMetricsDefault];
    UIImage *backButtonImage = [[UIImage imageNamed:@"navbar-back.png"] stretchableImageWithLeftCapWidth:14 topCapHeight:15];
    [UIBarButtonItem.appearance setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        [UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIApplication.sharedApplication setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    // when self.player.loadState == MPMovieLoadStateUnknown, observers are not removed
    //   nonForcedSubtitleDisplayEnabled
    //   presentationSize
    //   AVPlayerItem
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                object:self.delegate.player];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification
                                                object:self.delegate.player];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification
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
