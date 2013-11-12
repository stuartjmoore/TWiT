//
//  TWLargeHeaderCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 11/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWPlayButton;

@interface TWLargeHeaderCell : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UIToolbar *blurground;
@property (weak, nonatomic) IBOutlet TWPlayButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *liveTimeLabel, *liveTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *nextTimeLabel, *nextTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *livePosterView, *liveAlbumArtView;

@end
