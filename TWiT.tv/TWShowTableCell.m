//
//  TWShowTableCell.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWShowTableCell.h"

@implementation TWShowTableCell

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        _size = 88;
        _spacing = 14;
        _columns = 3;
        _visibleColumns = 0;
    }
    return self;
}

- (void)selectColumn:(UIButton*)sender
{
    [self.delegate tableView:self.table didSelectColumn:sender.tag AtIndexPath:self.indexPath];
}

@end
