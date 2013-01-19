//
//  TWQualityCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/19/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWQualityCell.h"

@implementation TWQualityCell

- (void)setEnclosure:(Enclosure*)enclosure
{
    _enclosure = enclosure;
    
    self.titleLabel.text = enclosure.title;
    self.subtitleLabel.text = enclosure.subtitle;
    self.downloadIcon.hidden = !(BOOL)enclosure.path;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if(selected)
    {
        self.checkmarkIcon.image = [UIImage imageNamed:@"quality-view-check-on.png"];
    }
    else
    {
        self.checkmarkIcon.image = [UIImage imageNamed:@"quality-view-check-off.png"];
    }
}

@end
