//
//  TWLiveViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/15/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWAppDelegate, TWSplitViewContainer, Stream;

@interface TWLiveViewController : UIViewController

@property (nonatomic, weak) TWSplitViewContainer *splitViewContainer;
@property (nonatomic, weak) TWAppDelegate *delegate;

@property (nonatomic, strong) Stream *stream;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel, *subtitleLabel;

@property (nonatomic, weak) IBOutlet UIView *airplayButtonView;
@property (nonatomic, weak) IBOutlet UIButton *qualityButton, *chatButton, *playButton;

- (void)playerStateChanged:(NSNotification*)notification;
- (IBAction)play:(UIButton*)sender;

@end
