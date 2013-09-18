//
//  TWStreamViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/15/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWAppDelegate.h"
#import "UIAlertView+block.h"

#import "TWStreamViewController.h"
#import "TWChatViewController.h"
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
{
    BOOL hideUI;
    UIColor *previousTint;
}

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
            UIImage *backIcon = [[UIImage imageNamed:@"navbar-back-twit-icon-trans"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            lastViewController.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithImage:backIcon
                                                                                                 style:UIBarButtonItemStyleBordered
                                                                                                target:nil action:nil];
        }
    }
    
    hideUI = NO;
    self.toolbarView.barStyle = UIBarStyleBlack;
    self.toasterView.barStyle = UIBarStyleBlack;
    
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
    else
    {
        self.toasterView.hidden = YES;
        [self.spinner stopAnimating];
    }
    
    self.stream = self.delegate.nowPlaying;
    
    self.infoView.hidden = self.delegate.player.airPlayVideoActive ? NO : (self.stream.type == TWTypeVideo);
    self.delegate.player.view.hidden = self.delegate.player.airPlayVideoActive;
    
    [self.qualityButton setTitle:self.stream.title forState:UIControlStateNormal];
    
    
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
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(chatRoomDidHide:)
                                               name:@"chatRoomDidHide"
                                             object:self.chatViewController];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"chatEmbed"])
    {
        _chatViewController = segue.destinationViewController;
    }
}

#pragma mark - Settings

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden
{
    return hideUI;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

#pragma mark - Update View

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
            self.toasterView.hidden = YES;
            [self.spinner stopAnimating];
        }
    }
    else if([notification.name isEqualToString:@"MPMoviePlayerPlaybackStateDidChangeNotification"])
    {
        self.playButton.selected = (self.delegate.player.playbackState == MPMoviePlaybackStatePlaying);
    }
    else if([notification.name isEqualToString:@"MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification"])
    {
        self.infoView.hidden = self.delegate.player.airPlayVideoActive ? NO : (self.stream.type == TWTypeVideo);
        self.delegate.player.view.hidden = self.delegate.player.airPlayVideoActive;
    }
    else if([notification.name isEqualToString:@"MPMoviePlayerPlaybackDidFinishNotification"]
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
                
                self.infoView.hidden = self.delegate.player.airPlayVideoActive ? NO : (self.stream.type == TWTypeVideo);
                [self.qualityButton setTitle:stream.title forState:UIControlStateNormal];
                return;
            }
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Unable to load the live stream." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [alert show];
    }
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
    
    hideUI = hide;
    
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
        [self.delegate pause];
    else
        [self.delegate play];
}

- (IBAction)openChatView:(UIButton*)sender
{
    [self loadChatRoom];
}

- (IBAction)openQualityPopover:(UIButton*)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Video Quality"
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"quality" ascending:NO];
    NSArray *sortedStreams = [self.stream.channel.streams sortedArrayUsingDescriptors:@[descriptor]];
    
    for(Stream *stream in sortedStreams)
        [sheet addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@", stream.title, stream.subtitle]];
    
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    
    [sheet showFromRect:CGRectMake(self.qualityButton.frame.size.width/2.0, 0, 1, 1) inView:self.qualityButton animated:YES];
}
- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == -1 || buttonIndex >= actionSheet.numberOfButtons-1)
        return;
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"quality" ascending:NO];
    NSArray *streams = [self.stream.channel.streams sortedArrayUsingDescriptors:@[descriptor]];
    Stream *stream = streams[buttonIndex];
    
    if(stream == self.stream)
        return;
    
    self.toasterView.hidden = NO;
    [self.spinner startAnimating];
    
    self.stream = stream;
    self.delegate.nowPlaying = stream;
    
    self.infoView.hidden = self.delegate.player.airPlayVideoActive ? NO : (self.stream.type == TWTypeVideo);
    [self.qualityButton setTitle:stream.title forState:UIControlStateNormal];
    
    if(self.stream.type == TWTypeVideo)
    {
        [NSUserDefaults.standardUserDefaults setInteger:self.stream.quality forKey:@"stream-quality"];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

#pragma mark - Chat Room

- (void)loadChatRoom
{
    if(self.chatRoomIsHidden && !self.chatViewController.isChatLoaded)
    {
        UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:@"TWiT Chat Room"
                                                         message:@""
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:@"Connect", nil];
        
        prompt.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        UITextField *nicknameField = [prompt textFieldAtIndex:0];
        nicknameField.placeholder = @"Nickname";
        nicknameField.keyboardType = UIKeyboardTypeEmailAddress;
        nicknameField.keyboardAppearance = UIKeyboardAppearanceAlert;
        nicknameField.autocorrectionType = UITextAutocorrectionTypeNo;
        nicknameField.returnKeyType = UIReturnKeyNext;
        [nicknameField becomeFirstResponder];

        NSString *chatNickString = [NSUserDefaults.standardUserDefaults stringForKey:@"chat-nick"];
        nicknameField.text = chatNickString;
        
        [prompt show];
    }
    else if(self.chatRoomIsHidden)
    {
        [self hideControls:YES];
        [self hideChatRoom:NO];
    }
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
        return;
    
    NSString *chatNick = @"";
    
    if(![[[alertView textFieldAtIndex:0] text] isEqualToString:@""])
    {
        chatNick = [[alertView textFieldAtIndex:0] text];
        [NSUserDefaults.standardUserDefaults setObject:chatNick forKey:@"chat-nick"];
        [NSUserDefaults.standardUserDefaults synchronize];
    }
    else
    {
        chatNick = [NSString stringWithFormat:@"iOS_%d", arc4random()%9999];
    }
    
    [self hideControls:YES];
    [self.chatViewController loadWithNickname:chatNick];
    [self hideChatRoom:NO];
}

- (void)hideChatRoom:(BOOL)hide
{
    if(hide)
    {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.chatView.alpha = 0;
        } completion:^(BOOL fin){
            self.chatView.hidden = YES;
        }];
    }
    else
    {
        self.chatView.hidden = NO;
        self.chatView.alpha = 0;
        
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            self.chatView.alpha = 1;
        }];
    }
}

- (BOOL)chatRoomIsHidden
{
    return (self.chatView.hidden);
}

- (void)chatRoomDidHide:(NSNotification*)notification
{
    [self hideChatRoom:YES];
    [self hideControls:NO];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
    float duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    float curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] floatValue];
    CGRect frame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.chatViewBottom.constant = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? frame.size.height : frame.size.width;
    
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:duration delay:0 options:curve animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    float duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    float curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] floatValue];
    
    self.chatViewBottom.constant = 0;
    
    [self.view setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:duration delay:0 options:curve animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark - Rotate

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    if(self.infoView.hidden && self.chatRoomIsHidden)
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
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.tintColor = previousTint;
    }
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateTitle) object:nil];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                object:self.delegate.player];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification
                                                object:self.delegate.player];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification
                                                object:self.delegate.player];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MPMoviePlayerIsAirPlayVideoActiveDidChangeNotification
                                                object:self.delegate.player];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:@"chatRoomDidHide" object:self.chatViewController];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
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
