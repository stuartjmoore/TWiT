//
//  TWShowsCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWShowsCell : UITableViewCell

@property (nonatomic, strong) UIImage *icons;
@property (nonatomic) NSInteger spacing, size, columns, visibleColumns;

- (void)setShows:(NSArray*)shows;

@end
