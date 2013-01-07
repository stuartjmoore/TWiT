//
//  TWShowTableCell.h
//  TWiT.tv
//
//  Created by Stuart Moore on 1/7/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWShowTableCell : UITableViewCell

@property (nonatomic) NSInteger spacing, size, columns, visibleColumns;

@property (nonatomic, weak) IBOutlet UIButton *showOneButton, *showTwoButton, *showThreeButton;

@end
