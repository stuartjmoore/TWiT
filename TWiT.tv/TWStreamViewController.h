//
//  TWStreamViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/15/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWAppDelegate, TWSplitViewContainer, Stream, TWChatViewController;

@interface TWStreamViewController : UIViewController <UIWebViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIBarPositioningDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) TWSplitViewContainer *splitViewContainer;
@property (nonatomic, weak) TWAppDelegate *delegate;
@property (nonatomic, strong) Stream *stream;

@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel, *subtitleLabel;

@property (nonatomic, weak) IBOutlet UIToolbar *toasterView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, weak) IBOutlet UIToolbar *toolbarView;
@property (nonatomic, weak) IBOutlet UIView *airplayButtonView;
@property (nonatomic, weak) IBOutlet UIButton *qualityButton, *chatButton, *playButton;

@property (nonatomic, weak) IBOutlet UIView *infoView;
@property (nonatomic, weak) IBOutlet UIImageView *infoAlbumArtView;

@property (nonatomic, weak) IBOutlet UIView *chatView;
@property (nonatomic, weak) TWChatViewController *chatViewController;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *chatViewBottom;

- (void)playerStateChanged:(NSNotification*)notification;

- (IBAction)play:(UIButton*)sender;
- (IBAction)openChatView:(UIButton*)sender;
- (IBAction)openQualityPopover:(UIButton*)sender;

- (void)hideChatRoom:(BOOL)hide;
- (BOOL)chatRoomIsHidden;
- (void)chatRoomDidHide:(NSNotification*)notification;

@end
