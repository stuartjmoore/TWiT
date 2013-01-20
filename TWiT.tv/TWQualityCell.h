//
//  TWQualityCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/19/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Enclosure.h"

@interface TWQualityCell : UITableViewCell

@property (nonatomic, strong) NSObject *source;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel, *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *checkmarkIcon, *downloadIcon;
@property (nonatomic, weak) IBOutlet UIView *topLine, *bottomLine;

@end
