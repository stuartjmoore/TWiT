//
//  TWShowCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 11/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWShowCell.h"
#import "Show.h"

@implementation TWShowCell

- (void)setShow:(Show*)show
{
    _show = show;
    
    self.albumView.image = show.albumArt.image;
    self.accessibilityLabel = show.title;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    // Only iPad
    // TODO: Re-select after rotation
    // TODO: Un-select after show disapears
}

@end
