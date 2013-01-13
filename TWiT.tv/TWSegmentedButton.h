//
//  TWSegmentedButton.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_OPTIONS(NSInteger, TWButtonSegment) {
    TWButtonSegmentWatch,
    TWButtonSegmentListen,
    TWButtonSegmentDownload,
    TWButtonSegmentCancel,
    TWButtonSegmentDelete
};

@class Episode;

@interface TWSegmentedButton : UIButton
{
    UILabel *downloadingLabel;
    UIImageView *progressBackgroundView, *progressFilledView;
}

@property (nonatomic, strong) Episode *episode;

@property (nonatomic) UIButton *watchButton, *listenButton, *downloadButton;

@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic) SEL watchSelector, listenSelector, downloadSelector, cancelSelector, deleteSelector;

@property (nonatomic) enum TWButtonSegment buttonState;
@property (nonatomic) float progress;
@property (nonatomic) BOOL watchEnabled, listenEnabled;
- (void)addTarget:(id)target action:(SEL)action forButton:(enum TWButtonSegment)buttonType;

- (void)watchButtonPressed:(UIButton*)sender;
- (void)listenButtonPressed:(UIButton*)sender;
- (void)downloadButtonPressed:(UIButton*)sender;

- (void)updateProgress:(NSNotification*)notification;

@end
