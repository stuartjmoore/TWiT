//
//  TWShowTableCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TWiTShowGridCellDelegate <NSObject>
- (void)tableView:(UITableView*)tableView didSelectColumn:(int)column AtIndexPath:(NSIndexPath*)indexPath;
@end

@interface TWShowTableCell : UITableViewCell

@property (nonatomic, weak) id<TWiTShowGridCellDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, weak) UITableView *table;

@property (nonatomic) NSInteger spacing, size, columns, visibleColumns;

@property (nonatomic, weak) IBOutlet UIButton *showOneButton, *showTwoButton, *showThreeButton;

@end
