//
//  TWLargeHeaderCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 11/12/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWLargeHeaderCell.h"

@implementation TWLargeHeaderCell

- (void)awakeFromNib
{
    self.blurground.barStyle = UIBarStyleBlack;
    self.blurground.clipsToBounds = YES;
}

@end
