//
//  TWShowsCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/1/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Show;

@protocol TWiTShowGridCellDelegate <NSObject>
- (void)tableView:(UITableView*)tableView didSelectColumn:(int)column AtIndexPath:(NSIndexPath*)indexPath;
@end

@interface TWShowsCell : UITableViewCell

@property (nonatomic, weak) id<TWiTShowGridCellDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, weak) UITableView *table;

@property (nonatomic, strong) UIImage *icons;
@property (nonatomic) NSInteger spacing, size, columns, visibleColumns;

@property (nonatomic, strong) NSArray *shows;

@end
