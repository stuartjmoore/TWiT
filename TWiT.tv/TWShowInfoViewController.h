//
//  TWShowInfoViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/16/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@class Show;

@interface TWShowInfoViewController : UIViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) Show *show;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *albumArt;
@property (nonatomic, weak) IBOutlet UILabel *scheduleLabel, *hostsLabel;
@property (nonatomic, weak) IBOutlet UITextView *descLabel;

@property (nonatomic, weak) IBOutlet UIButton *emailButton, *websiteButton;

- (IBAction)email:(UIButton*)sender;
- (IBAction)openWebsite:(UIButton*)sender;

- (IBAction)close:(UIButton*)sender;

@end
