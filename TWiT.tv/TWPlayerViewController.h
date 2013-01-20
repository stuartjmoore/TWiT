//
//  TWPlayerViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWSplitViewContainer, TWAppDelegate, Enclosure;

@interface TWPlayerViewController : UIViewController <UIAlertViewDelegate>

@property (nonatomic, weak) TWSplitViewContainer *splitViewContainer;
@property (nonatomic, weak) TWAppDelegate *delegate;
@property (nonatomic, strong) Enclosure *enclosure;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel, *subtitleLabel;

@property (nonatomic, weak) IBOutlet UIView *toolbarView;
@property (nonatomic, weak) IBOutlet UISlider *seekbar;
@property (nonatomic, weak) IBOutlet UILabel *timeElapsedLabel, *timeRemainingLabel, *timeOfEndLabel;
@property (nonatomic, weak) IBOutlet UIView *airplayButtonView;
@property (nonatomic, weak) IBOutlet UIButton *qualityButton, *speedButton, *rewindButton, *playButton;

@property (nonatomic, weak) IBOutlet UIView *qualityView;

- (void)playerStateChanged:(NSNotification*)notification;

- (IBAction)play:(UIButton*)sender;
- (IBAction)rewind:(UIButton*)sender;
- (IBAction)toggleSpeed:(UIButton*)sender;

- (IBAction)seekStart:(UISlider*)sender;
- (IBAction)seeking:(UISlider*)sender;
- (IBAction)seekEnd:(UISlider*)sender;

- (IBAction)close:(UIBarButtonItem*)sender;

@end
