//
//  TWShowInfoViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/16/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Show;

@interface TWShowInfoViewController : UIViewController

@property (nonatomic, strong) Show *show;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *albumArt;
@property (nonatomic, weak) IBOutlet UILabel *scheduleLabel, *hostsLabel;
@property (nonatomic, weak) IBOutlet UITextView *descLabel;

@property (nonatomic, weak) IBOutlet UIButton *emailButton, *callButton, *websiteButton, *youtubeButton;

- (IBAction)emailShow:(UIButton*)sender;
- (IBAction)callShow:(UIButton*)sender;
- (IBAction)openWebsite:(UIButton*)sender;
- (IBAction)openYouTube:(UIButton*)sender;

- (IBAction)close:(UIButton*)sender;

@end
