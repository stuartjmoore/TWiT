//
//  TWSegmentedButton.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWSegmentedButton.h"

#import "Enclosure.h"

@implementation TWSegmentedButton

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.backgroundColor = UIColor.clearColor;
        self.isAccessibilityElement = NO;
        
        self.watchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.watchButton.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
        [self.watchButton setTitle:@"Watch" forState:UIControlStateNormal];
        [self.watchButton setBackgroundImage:[[UIImage imageNamed:@"button-blue-left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.watchButton.accessibilityHint = @"Loads the episode video.";
        [self.watchButton addTarget:self action:@selector(watchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.watchButton];
        
        self.listenButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.listenButton.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
        [self.listenButton setTitle:@"Listen" forState:UIControlStateNormal];
        [self.listenButton setBackgroundImage:[[UIImage imageNamed:@"button-blue-mid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.listenButton.accessibilityHint = @"Loads the episode audio.";
        [self.listenButton addTarget:self action:@selector(listenButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.listenButton];
        
        progressBackgroundView = [[UIImageView alloc] init];
        progressBackgroundView.frame = CGRectMake(0, 0, self.frame.size.width-self.frame.size.height, self.frame.size.height);
        progressBackgroundView.autoresizingMask = self.watchButton.autoresizingMask;
        progressBackgroundView.hidden = YES;
        progressBackgroundView.image = [[UIImage imageNamed:@"button-blue-progress-background"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self addSubview:progressBackgroundView];
        
        progressFilledView = [[UIImageView alloc] init];
        progressFilledView.frame = CGRectMake(0, 0, 0, self.frame.size.height);
        progressFilledView.autoresizingMask = self.watchButton.autoresizingMask;
        progressFilledView.hidden = YES;
        progressFilledView.image = [[UIImage imageNamed:@"button-blue-progress-filled"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self addSubview:progressFilledView];
        
        self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.downloadButton.frame = CGRectMake(self.frame.size.width-self.frame.size.height, 0, self.frame.size.height, self.frame.size.height);
        self.downloadButton.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin);
        [self.downloadButton setBackgroundImage:[[UIImage imageNamed:@"button-blue-right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.downloadButton setImage:[[UIImage imageNamed:@"download-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.downloadButton.accessibilityLabel = @"Dowload";
        self.downloadButton.accessibilityHint = @"Dowloads the episode.";
        [self.downloadButton addTarget:self action:@selector(downloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.downloadButton];
        
        downloadingLabel = [[UILabel alloc] init];
        downloadingLabel.frame = CGRectMake(0, 0, self.frame.size.width-self.frame.size.height, self.frame.size.height);
        downloadingLabel.autoresizingMask = self.watchButton.autoresizingMask;
        downloadingLabel.hidden = YES;
        downloadingLabel.text = @"Downloading…";
        //downloadingLabel.font = [UIFont systemFontOfSize:18];
        downloadingLabel.backgroundColor = [UIColor clearColor];
        downloadingLabel.textColor = self.tintColor;
        downloadingLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:downloadingLabel];
    }
    return self;
}

- (void)setListenEnabled:(BOOL)listenEnabled
{
    _listenEnabled = listenEnabled;
    self.listenButton.hidden = !listenEnabled;
    
    if(!_listenEnabled)
    {
        self.watchButton.frame = CGRectMake(0, 0, self.frame.size.width-self.frame.size.height, self.frame.size.height);
    }
    else
    {
        self.watchButton.frame = CGRectMake(0, 0, floorf((self.frame.size.width-self.frame.size.height)/2.0f), self.frame.size.height);
    }
}

- (void)setWatchEnabled:(BOOL)watchEnabled
{
    _watchEnabled = watchEnabled;
    self.watchButton.hidden = !watchEnabled;
    
    if(!_watchEnabled)
    {
        self.listenButton.frame = CGRectMake(0, 0, self.frame.size.width-self.frame.size.height, self.frame.size.height);
        [self.listenButton setBackgroundImage:[[UIImage imageNamed:@"button-blue-left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else
    {
        self.listenButton.frame = CGRectMake(floorf((self.frame.size.width-self.frame.size.height)/2.0f), 0,
                                             ceilf((self.frame.size.width-self.frame.size.height)/2.0f), self.frame.size.height);
        [self.listenButton setBackgroundImage:[[UIImage imageNamed:@"button-blue-mid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
}

- (void)setButtonState:(enum TWButtonSegment)buttonState
{
    _buttonState = buttonState;
    
    if(buttonState == TWButtonSegmentDownload)
    {
        [self.downloadButton setImage:[[UIImage imageNamed:@"download-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                             forState:UIControlStateNormal];
        self.downloadButton.accessibilityLabel = @"Dowload";
        self.downloadButton.accessibilityHint = @"Dowloads the episode.";
        
        self.watchButton.hidden = NO;
        self.listenButton.hidden = NO;
        progressBackgroundView.hidden = YES;
        progressFilledView.hidden = YES;
        downloadingLabel.hidden = YES;
    }
    else if(buttonState == TWButtonSegmentCancel)
    {
        [self.downloadButton setImage:[[UIImage imageNamed:@"download-cancel-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                             forState:UIControlStateNormal];
        self.downloadButton.accessibilityLabel = @"Cancel";
        self.downloadButton.accessibilityHint = @"Cancels the download.";
        
        self.watchButton.hidden = YES;
        self.listenButton.hidden = YES;
        progressBackgroundView.hidden = NO;
        progressFilledView.hidden = NO;
        downloadingLabel.hidden = NO;
    }
    else if(buttonState == TWButtonSegmentDelete)
    {
        [self.downloadButton setImage:[[UIImage imageNamed:@"download-delete-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                             forState:UIControlStateNormal];
        self.downloadButton.accessibilityLabel = @"Delete";
        self.downloadButton.accessibilityHint = @"Deletes the download.";
        
        self.watchButton.hidden = NO;
        self.listenButton.hidden = NO;
        progressBackgroundView.hidden = YES;
        progressFilledView.hidden = YES;
        downloadingLabel.hidden = YES;
    }
}

- (void)addTarget:(id)target action:(SEL)action forButton:(enum TWButtonSegment)buttonType
{
    self.target = target;
    
    if(buttonType == TWButtonSegmentWatch)
        self.watchSelector = action;
    if(buttonType == TWButtonSegmentListen)
        self.listenSelector = action;
    else if(buttonType == TWButtonSegmentDownload)
        self.downloadSelector = action;
    else if(buttonType == TWButtonSegmentCancel)
        self.cancelSelector = action;
    else if(buttonType == TWButtonSegmentDelete)
        self.deleteSelector = action;
}

#pragma mark - Download

- (void)setProgress:(float)progress
{
    _progress = progress;
    
    CGRect frame = CGRectMake(0, 0, self.frame.size.width-self.frame.size.height, self.frame.size.height);
    frame.size.width *= progress;
    progressFilledView.frame = frame;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)watchButtonPressed:(UIButton*)sender
{
    if([self.target respondsToSelector:self.watchSelector])
        [self.target performSelector:self.watchSelector withObject:self];
}

- (void)listenButtonPressed:(UIButton*)sender
{
    if([self.target respondsToSelector:self.listenSelector])
        [self.target performSelector:self.listenSelector withObject:self];
}

- (void)downloadButtonPressed:(UIButton*)sender
{
    if(self.buttonState == TWButtonSegmentDownload)
    {
        if([self.target respondsToSelector:self.downloadSelector])
            [self.target performSelector:self.downloadSelector withObject:self];
    }
    else if(self.buttonState == TWButtonSegmentCancel)
    {
        if([self.target respondsToSelector:self.cancelSelector])
            [self.target performSelector:self.cancelSelector withObject:self];
    }
    else if(self.buttonState == TWButtonSegmentDelete)
    {
        if([self.target respondsToSelector:self.deleteSelector])
            [self.target performSelector:self.deleteSelector withObject:self];
    }
}

#pragma clang diagnostic pop

@end
