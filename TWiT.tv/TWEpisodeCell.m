//
//  TWEpisodeCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWEpisodeCell.h"

@implementation TWEpisodeCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if(selected)
    {
        self.backgroundColor = [UIColor colorWithRed:61/255.0 green:122/255.0 blue:155/255.0 alpha:1];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.subtitleLabel.textColor = [UIColor whiteColor];
        self.numberLabel.textColor = [UIColor whiteColor];
        
        self.titleLabel.shadowColor = [UIColor blackColor];
        self.subtitleLabel.shadowColor = [UIColor blackColor];
        self.numberLabel.shadowColor = [UIColor blackColor];
        
        self.topLine.hidden = YES;
        self.bottomLine.hidden = YES;
    }
    else
    {
        self.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor = [UIColor blackColor];
        self.subtitleLabel.textColor = [UIColor darkGrayColor];
        self.numberLabel.textColor = [UIColor blackColor];
        
        self.titleLabel.shadowColor = [UIColor clearColor];
        self.subtitleLabel.shadowColor = [UIColor clearColor];
        self.numberLabel.shadowColor = [UIColor clearColor];
        
        self.topLine.hidden = NO;
        self.bottomLine.hidden = NO;
    }
}

@end
