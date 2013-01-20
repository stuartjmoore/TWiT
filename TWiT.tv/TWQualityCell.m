//
//  TWQualityCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/19/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWQualityCell.h"

@implementation TWQualityCell

- (void)setSource:(id)source
{
    _source = source;
    
    self.titleLabel.text = [source title];
    self.subtitleLabel.text = [source subtitle];
    
    if([source isKindOfClass:Enclosure.class])
        self.downloadIcon.hidden = !(BOOL)[source path];
    else
        self.downloadIcon.hidden = YES;
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
