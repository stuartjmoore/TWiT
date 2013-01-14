//
//  TWPlayerViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWAppDelegate, Enclosure;

@interface TWPlayerViewController : UIViewController

@property (nonatomic, weak) TWAppDelegate *delegate;
@property (nonatomic, strong) Enclosure *enclosure;

@property (nonatomic, weak) IBOutlet UIView *airplayButtonView;
@property (nonatomic, weak) IBOutlet UIButton *qualityButton, *speedButton, *rewindButton, *playButton;

- (void)playerStateChanged:(NSNotification*)notification;

- (IBAction)close:(UIBarButtonItem*)sender;

@end
