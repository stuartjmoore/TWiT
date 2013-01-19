//
//  TWPlaybarViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/19/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWPlaybarViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *titleLabel, *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *albumArt;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

- (void)updateView;

- (IBAction)play:(id)sender;
- (IBAction)openPlayer:(id)sender;

@end
