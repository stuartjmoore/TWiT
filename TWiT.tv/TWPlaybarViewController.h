//
//  TWPlaybarViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/19/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWSplitViewContainer, TWNavigationContainer;

@interface TWPlaybarViewController : UIViewController

@property (nonatomic, weak) TWSplitViewContainer *splitViewContainer;
@property (nonatomic, weak) TWNavigationContainer *navigationContainer;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel, *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *albumArt;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

- (void)updateView;

- (IBAction)play:(UIButton*)sender;
- (IBAction)stop:(UIButton*)sender;
- (IBAction)openPlayer:(UIButton*)sender;

@end
